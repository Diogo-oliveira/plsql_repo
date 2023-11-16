/*-- Last Change Revision: $Rev: 2053793 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-12-21 16:14:16 +0000 (qua, 21 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_external IS

    FUNCTION tf_lab_tests_ea
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_crit_type  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE
        
    ) RETURN t_tbl_lab_tests_ea IS
        l_out_rec        t_tbl_lab_tests_ea := t_tbl_lab_tests_ea(NULL);
        l_type_header    CLOB;
        l_inner_header   CLOB;
        l_inner_header1  CLOB;
        l_inner_header2  CLOB;
        l_sql_inner1     CLOB;
        l_sql_inner2     CLOB;
        l_sql_footer1    CLOB;
        l_sql_footer2    CLOB;
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_LAB_TESTS_EA';
    BEGIN
        l_curid := dbms_sql.open_cursor;
    
        l_type_header := 'SELECT t_lab_tests_ea(id_analysis_req, ' || --
                         '                      id_analysis_req_det, ' || --
                         '                      id_ard_parent, ' || --
                         '                      id_analysis_result, ' || --
                         '                      id_analysis, ' || --
                         '                      dt_req, ' || --
                         '                      dt_target, ' || --
                         '                      dt_pend_req, ' || --
                         '                      dt_harvest, ' || --
                         '                      dt_analysis_result, ' || --
                         '                      status_str_req, ' || --
                         '                      status_msg_req, ' || --
                         '                      status_icon_req, ' || --
                         '                      status_flg_req, ' || --
                         '                      status_str, ' || --
                         '                      status_msg, ' || --
                         '                      status_icon, ' || --
                         '                      status_flg, ' || --
                         '                      id_sample_type, ' || --
                         '                      id_exam_cat, ' || --
                         '                      flg_notes, ' || --
                         '                      flg_doc, ' || --
                         '                      flg_time_harvest, ' || --
                         '                      flg_status_req, ' || --
                         '                      flg_status_det, ' || --
                         '                      flg_status_harvest, ' || --
                         '                      flg_status_result, ' || --
                         '                      flg_referral, ' || --
                         '                      flg_priority, ' || --
                         '                      flg_col_inst, ' || --
                         '                      id_prof_writes, ' || --
                         '                      id_institution, ' || --
                         '                      id_analysis_codification, ' || --
                         '                      id_task_dependency, ' || --
                         '                      id_room_req, ' || --
                         '                      id_exec_institution, ' || --
                         '                      id_movement, ' || --
                         '                      id_prof_order, ' || --
                         '                      dt_order, ' || --
                         '                      id_order_type, ' || --
                         '                      flg_abnormality, ' || --
                         '                      flg_orig_analysis, ' || --
                         '                      notes, ' || --
                         '                      notes_technician, ' || --
                         '                      notes_patient, ' || --
                         '                      notes_cancel, ' || --
                         '                      flg_req_origin_module, ' || --
                         '                      id_patient, ' || --
                         '                      id_visit, ' || --
                         '                      id_episode, ' || --
                         '                      id_episode_origin, ' || --
                         '                      id_episode_destination, ' || --
                         '                      id_prev_episode, ' || --
                         '                      dt_dg_last_update, ' || --
                         '                      notes_scheduler, ' || --
                         '                      id_epis_type, ' || --
                         '                      id_epis) ' || --
                         '  FROM (';
    
        l_inner_header := 'SELECT ltea.id_analysis_req, ' || --
                          '       ltea.id_analysis_req_det, ' || --
                          '       ltea.id_ard_parent, ' || --
                          '       ltea.id_analysis_result, ' || --
                          '       ltea.id_analysis, ' || --
                          '       ltea.dt_req, ' || --
                          '       ltea.dt_target, ' || --
                          '       ltea.dt_pend_req, ' || --
                          '       ltea.dt_harvest, ' || --
                          '       ltea.dt_analysis_result, ' || --
                          '       ltea.status_str_req, ' || --
                          '       ltea.status_msg_req, ' || --
                          '       ltea.status_icon_req, ' || --
                          '       ltea.status_flg_req, ' || --
                          '       ltea.status_str, ' || --
                          '       ltea.status_msg, ' || --
                          '       ltea.status_icon, ' || --
                          '       ltea.status_flg, ' || --
                          '       ltea.id_sample_type, ' || --
                          '       ltea.id_exam_cat, ' || --
                          '       ltea.flg_notes, ' || --
                          '       ltea.flg_doc, ' || --
                          '       ltea.flg_time_harvest, ' || --
                          '       ltea.flg_status_req, ' || --
                          '       ltea.flg_status_det, ' || --
                          '       ltea.flg_status_harvest, ' || --
                          '       ltea.flg_status_result, ' || --
                          '       ltea.flg_referral, ' || --
                          '       ltea.flg_priority, ' || --
                          '       ltea.flg_col_inst, ' || --
                          '       ltea.id_prof_writes, ' || --
                          '       ltea.id_institution, ' || --
                          '       ltea.id_analysis_codification, ' || --
                          '       ltea.id_task_dependency, ' || --
                          '       ltea.id_room_req, ' || --
                          '       ltea.id_exec_institution, ' || --
                          '       ltea.id_movement, ' || --
                          '       ltea.id_prof_order, ' || --
                          '       ltea.dt_order, ' || --
                          '       ltea.id_order_type, ' || --
                          '       ltea.flg_abnormality, ' || --
                          '       ltea.flg_orig_analysis, ' || --
                          '       ltea.notes, ' || --
                          '       ltea.notes_technician, ' || --
                          '       ltea.notes_patient, ' || --
                          '       ltea.notes_cancel, ' || --
                          '       ltea.flg_req_origin_module, ' || --
                          '       ltea.id_patient, ' || --
                          '       ltea.id_visit, ' || --
                          '       ltea.id_episode, ' || --
                          '       ltea.id_episode_origin, ' || --
                          '       ltea.id_episode_destination, ' || --
                          '       ltea.id_prev_episode, ' || --
                          '       ltea.dt_dg_last_update, ' || --
                          '       ltea.notes_scheduler, ' || --
                          '       e.id_epis_type, ' || --
                          '       e.id_episode id_epis ';
    
        l_inner_header1 := l_inner_header ||
                           ' FROM lab_tests_ea ltea JOIN episode e ON ltea.id_episode = e.id_episode ' ||
                           ' --Laboratory tests of infectious diseases
                   LEFT JOIN  (SELECT DISTINCT gar.id_record id_analysis
                        FROM group_access ga
                       INNER JOIN group_access_prof gaf
                          ON gaf.id_group_access = ga.id_group_access
                       INNER JOIN group_access_record gar
                          ON gar.id_group_access = ga.id_group_access
                       WHERE ga.id_institution = ' || i_prof.institution ||
                           ' AND ga.id_software = ' || i_prof.software || ' AND ga.flg_type = ''' ||
                           pk_lab_tests_constant.g_infectious_diseases_orders || '''' || ' AND gar.flg_type = ''A'' ' ||
                           ' AND ga.flg_available = ''' || pk_lab_tests_constant.g_available || '''' ||
                           ' AND gaf.flg_available = ''' || pk_lab_tests_constant.g_available || '''' ||
                           ' AND gar.flg_available = ''' || pk_lab_tests_constant.g_available ||
                           ''') a_infect 
                   ON ltea.id_analysis = a_infect.id_analysis' || ' WHERE 1 = 1 ' ||
                           ' AND (a_infect.id_analysis IS NULL OR EXISTS
                            (SELECT 1
                                FROM group_access ga
                               INNER JOIN group_access_prof gaf
                                  ON gaf.id_group_access = ga.id_group_access
                               INNER JOIN group_access_record gar
                                  ON gar.id_group_access = ga.id_group_access
                               WHERE gaf.id_professional = ' || i_prof.id ||
                           '  AND ga.id_institution = ' || i_prof.institution || '  AND ga.id_software = ' ||
                           i_prof.software || '  AND ga.flg_type = ''' ||
                           pk_lab_tests_constant.g_infectious_diseases_orders || '''' || '  AND gar.flg_type = ''A'' ' ||
                           '  AND ga.flg_available = ''' || pk_lab_tests_constant.g_available || '''' ||
                           '  AND gaf.flg_available = ''' || pk_lab_tests_constant.g_available || '''' ||
                           '  AND gar.flg_available = ''' || pk_lab_tests_constant.g_available || '''))';
    
        --i_patient
        IF i_patient IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND ltea.id_patient = :i_patient ';
        END IF;
    
        --i_visit
        IF i_visit IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND (ltea.id_visit = :i_visit OR pk_episode.get_id_visit(ltea.id_episode_origin) = :i_visit OR pk_episode.get_id_visit(ltea.id_episode_destination) = :i_visit)';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND ltea.id_episode = :i_episode';
        END IF;
    
        l_sql_inner1 := l_sql_inner1 || ' AND ltea.flg_time_harvest != ''' || pk_lab_tests_constant.g_flg_time_r || '''';
    
        IF i_crit_type = 'A'
        THEN
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND coalesce(ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) >= ' || --
                            '     coalesce(:i_start_date, ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) ' || --
                            ' AND coalesce(ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) <= ' || --
                            '     coalesce(:i_end_date, ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) ';
        ELSIF i_crit_type = 'E'
        THEN
            l_sql_inner1 := l_sql_inner1 || --
                            ' AND ltea.dt_harvest >= nvl(:i_start_date, ltea.dt_harvest) ' || -- 
                            ' AND ltea.dt_harvest <= nvl(:i_end_date, ltea.dt_harvest)';
        END IF;
    
        l_sql_footer1 := ' AND (ltea.flg_orig_analysis IS NULL OR ltea.flg_orig_analysis NOT IN (''M'', ''O'', ''S'')) ' || -- 
                         ' UNION ALL ';
    
        l_inner_header2 := l_inner_header ||
                           ' FROM lab_tests_ea ltea join episode e on ltea.id_episode_origin=e.id_episode WHERE 1 = 1 ';
    
        --i_patient
        IF i_patient IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND ltea.id_patient = :i_patient ';
        END IF;
    
        --i_visit
        IF i_visit IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            '  AND (ltea.id_visit = :i_visit OR pk_episode.get_id_visit(ltea.id_episode_origin) = :i_visit OR pk_episode.get_id_visit(ltea.id_episode_destination) = :i_visit)';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND ltea.id_episode_origin = :i_episode';
        END IF;
    
        l_sql_inner2 := l_sql_inner2 || ' AND ltea.flg_time_harvest != ''' || pk_lab_tests_constant.g_flg_time_r || '''';
    
        IF i_crit_type = 'A'
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            ' AND coalesce(ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) >= ' || --
                            '     coalesce(:i_start_date, ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) ' || --
                            ' AND coalesce(ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) <= ' || --
                            '     coalesce(:i_end_date, ltea.dt_analysis_result, ltea.dt_harvest, ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) ';
        ELSIF i_crit_type = 'E'
        THEN
            l_sql_inner2 := l_sql_inner2 || --
                            ' AND ltea.dt_harvest >= nvl(:i_start_date, ltea.dt_harvest) ' || -- 
                            ' AND ltea.dt_harvest <= nvl(:i_end_date, ltea.dt_harvest)';
        END IF;
    
        l_sql_footer2 := ' AND (ltea.flg_orig_analysis IS NULL OR ltea.flg_orig_analysis NOT IN (''M'', ''O'', ''S'')))';
    
        l_sql_stmt := to_clob(l_type_header || l_inner_header1 || l_sql_inner1 || l_sql_footer1 || l_inner_header2 ||
                              l_sql_inner2 || l_sql_footer2);
    
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_db_object_name, text => l_sql_stmt);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        IF i_patient IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_patient', i_patient);
        END IF;
    
        IF i_visit IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_visit', i_visit);
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_episode', i_episode);
        END IF;
    
        IF i_crit_type IN ('A', 'E')
        THEN
            dbms_sql.bind_variable(l_curid, 'i_start_date', i_start_date);
            dbms_sql.bind_variable(l_curid, 'i_end_date', i_end_date);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    
    END tf_lab_tests_ea;

    FUNCTION tf_analysis_result
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            profissional,
        i_id_patient      analysis_result.id_patient%TYPE DEFAULT NULL,
        i_id_episode_orig analysis_result.id_episode_orig%TYPE DEFAULT NULL,
        i_id_visit        analysis_result.id_visit%TYPE DEFAULT NULL
    ) RETURN t_tbl_analysis_result IS
    
        l_out_rec        t_tbl_analysis_result := t_tbl_analysis_result(NULL);
        l_sql_header     VARCHAR2(32767);
        l_sql_inner      VARCHAR2(32767);
        l_sql_footer     VARCHAR2(32767);
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_ANALYSIS_RESULT';
    BEGIN
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_header := 'SELECT t_analysis_result(id_analysis_result,
                                                 id_analysis,
                                                 id_analysis_req_det,
                                                 id_professional,
                                                 id_patient,
                                                 notes,
                                                 flg_type,
                                                 id_institution,
                                                 id_episode,
                                                 loinc_code,
                                                 flg_status,
                                                 dt_analysis_result_tstz,
                                                 dt_sample,
                                                 id_visit,
                                                 id_exam_cat,
                                                 flg_orig_analysis,
                                                 id_episode_orig,
                                                 id_result_status,
                                                 flg_result_origin,
                                                 id_prof_req,
                                                 id_harvest,
                                                 id_sample_type,
                                                 result_origin_notes,
                                                 flg_mult_result)
                          FROM (SELECT id_analysis_result,
                                       id_analysis,
                                       id_analysis_req_det,
                                       id_professional,
                                       id_patient,
                                       notes,
                                       flg_type,
                                       id_institution,
                                       id_episode,
                                       loinc_code,
                                       flg_status,
                                       dt_analysis_result_tstz,
                                       dt_sample,
                                       id_visit,
                                       id_exam_cat,
                                       flg_orig_analysis,
                                       id_episode_orig,
                                       id_result_status,
                                       flg_result_origin,
                                       id_prof_req,
                                       id_harvest,
                                       id_sample_type,
                                       result_origin_notes,
                                       flg_mult_result
                                  FROM analysis_result
                                 WHERE 1 = 1';
    
        IF i_id_patient IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND id_patient = :i_id_patient';
        END IF;
    
        IF i_id_episode_orig IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND id_episode_orig = :i_id_episode_orig';
        
        END IF;
    
        IF i_id_visit IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND (id_visit = :i_id_visit OR (id_visit IS NULL AND EXISTS (SELECT 1
                                                                                          FROM episode e
                                                                                         WHERE e.id_visit = :i_id_visit
                                                                                           AND id_episode_orig = e.id_episode)))';
        END IF;
    
        l_sql_footer := ' )';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer);
    
        pk_alertlog.log_debug(object_name     => g_package_name,
                              sub_object_name => l_db_object_name,
                              text            => dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        IF i_id_patient IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_patient', i_id_patient);
        END IF;
    
        IF i_id_episode_orig IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_episode_orig', i_id_episode_orig);
        END IF;
    
        IF i_id_visit IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_visit', i_id_visit);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    
    END tf_analysis_result;

    PROCEDURE episode___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_for_episode_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_desc VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_episode IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT decode(i_type,
                      'E',
                      substr(concatenate(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                   i_prof,
                                                                                   pk_lab_tests_constant.g_analysis_alias,
                                                                                   'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                   id_analysis,
                                                                                   NULL) || '; '),
                             1,
                             length(concatenate(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                          i_prof,
                                                                                          pk_lab_tests_constant.g_analysis_alias,
                                                                                          'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                          id_analysis,
                                                                                          NULL) || '; ')) - 3),
                      substr(concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_writes) || '; '),
                             1,
                             length(concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_writes) || '; ')) - 2))
          INTO l_desc
          FROM (SELECT lte.id_analysis, lte.id_prof_writes
                  FROM lab_tests_ea lte
                 WHERE lte.id_episode = i_episode) t;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_for_episode_timeline;

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_tests_listview
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient   patient.id_patient%TYPE;
        l_visit     visit.id_visit%TYPE;
        l_episode   episode.id_episode%TYPE;
        l_epis_type episode.id_epis_type%TYPE;
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_top_result sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULTS_ON_TOP', i_prof);
    
        l_msg_notes         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M097');
        l_msg_not_aplicable sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M036');
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
    BEGIN
    
        g_error      := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_start_date';
        l_start_date := CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_start_date)
                            ELSE
                             NULL
                        END;
    
        g_error    := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_end_date';
        l_end_date := CASE
                          WHEN i_end_date IS NOT NULL THEN
                           pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_end_date)
                          ELSE
                           NULL
                      END;
    
        IF i_scope IS NOT NULL
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_SCOPE_VARS';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_flg_scope,
                                                  o_patient    => l_patient,
                                                  o_visit      => l_visit,
                                                  o_episode    => l_episode,
                                                  o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = l_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_type := NULL;
        END;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR -- requisições da visita
            WITH cso_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    pk_alert_constant.g_task_lab_tests))),
            cso_table_cs AS
             (SELECT *
                FROM cso_table)
            SELECT /*+ opt_estimate(table lte rows=1) */
            DISTINCT lte.id_analysis_req,
                     lte.id_analysis_req_det,
                     lte.id_analysis,
                     lte.flg_status_det flg_status,
                     lte.flg_time_harvest flg_time,
                     pk_lab_tests_utils.get_alias_translation(i_lang,
                                                              i_prof,
                                                              pk_lab_tests_constant.g_analysis_alias,
                                                              'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                              'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                              NULL) ||
                     decode(l_epis_type,
                            nvl(t_ti_log.get_epis_type(i_lang,
                                                       i_prof,
                                                       lte.id_epis_type,
                                                       lte.flg_status_req,
                                                       lte.id_analysis_req,
                                                       pk_lab_tests_constant.g_analysis_type_req),
                                lte.id_epis_type),
                            '',
                            ' - (' || pk_message.get_message(i_lang,
                                                             profissional(i_prof.id,
                                                                          i_prof.institution,
                                                                          t_ti_log.get_epis_type_soft(i_lang,
                                                                                                      i_prof,
                                                                                                      lte.id_epis_type,
                                                                                                      lte.flg_status_req,
                                                                                                      lte.id_analysis_req,
                                                                                                      pk_lab_tests_constant.g_analysis_type_req)),
                                                             'IMAGE_T009') || ')') desc_analysis,
                     decode(lte.flg_notes, pk_lab_tests_constant.g_no, '', l_msg_notes) msg_notes,
                     lte.notes notes,
                     dbms_lob.substr(lte.notes_patient, 3800) notes_patient,
                     lte.notes_technician notes_technician,
                     pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ_DET.FLG_REQ_ORIGIN_MODULE', lte.flg_req_origin_module) icon_name,
                     decode(lte.flg_time_harvest,
                            pk_lab_tests_constant.g_flg_time_r,
                            l_msg_not_aplicable,
                            pk_diagnosis.concat_diag(i_lang, NULL, lte.id_analysis_req_det, NULL, i_prof)) desc_diagnosis,
                     pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ_DET.FLG_URGENCY', lte.flg_priority, NULL) priority,
                     decode(lte.flg_time_harvest,
                            pk_lab_tests_constant.g_flg_time_r,
                            NULL,
                            pk_date_utils.date_char_hour_tsz(i_lang, lte.dt_target, i_prof.institution, i_prof.software)) hr_begin,
                     decode(lte.flg_time_harvest,
                            pk_lab_tests_constant.g_flg_time_r,
                            NULL,
                            pk_date_utils.dt_chr_tsz(i_lang, lte.dt_target, i_prof.institution, i_prof.software)) dt_begin,
                     pk_sysdomain.get_domain(i_lang,
                                             i_prof,
                                             'ANALYSIS_REQ_DET.FLG_TIME_HARVEST',
                                             lte.flg_time_harvest,
                                             NULL) to_be_perform,
                     pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                lte.status_str,
                                                lte.status_msg,
                                                lte.status_icon,
                                                lte.status_flg) || '|' ||
                     pk_lab_tests_utils.get_lab_test_result_parameters(i_lang, i_prof, lte.id_analysis_req_det) status_string,
                     pk_lab_tests_utils.get_lab_test_codification(i_lang, i_prof, lte.id_analysis_codification) id_codification,
                     lte.id_task_dependency,
                     pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                pk_lab_tests_constant.g_analysis_button_ok,
                                                                lte.id_epis,
                                                                NULL,
                                                                lte.id_analysis_req_det,
                                                                pk_lab_tests_constant.g_yes) avail_button_ok,
                     pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                pk_lab_tests_constant.g_analysis_button_cancel,
                                                                lte.id_epis,
                                                                NULL,
                                                                lte.id_analysis_req_det,
                                                                pk_lab_tests_constant.g_yes) avail_button_cancel,
                     pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                pk_lab_tests_constant.g_analysis_button_action,
                                                                lte.id_epis,
                                                                NULL,
                                                                lte.id_analysis_req_det,
                                                                pk_lab_tests_constant.g_yes) avail_button_action,
                     pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                pk_lab_tests_constant.g_analysis_button_edit,
                                                                lte.id_epis,
                                                                NULL,
                                                                lte.id_analysis_req_det,
                                                                pk_lab_tests_constant.g_yes) avail_button_edit,
                     pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                pk_lab_tests_constant.g_analysis_button_read,
                                                                lte.id_epis,
                                                                NULL,
                                                                lte.id_analysis_req_det,
                                                                pk_lab_tests_constant.g_yes) avail_button_read,
                     decode(lte.id_analysis_result, NULL, pk_lab_tests_constant.g_no, pk_lab_tests_constant.g_yes) avail_button_det,
                     pk_lab_tests_constant.g_yes flg_current_episode,
                     decode(lte.flg_status_det,
                            pk_lab_tests_constant.g_analysis_result,
                            decode(l_top_result,
                                   pk_lab_tests_constant.g_yes,
                                   0,
                                   row_number()
                                   over(ORDER BY
                                        pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det),
                                        coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req) DESC)),
                            pk_lab_tests_constant.g_analysis_req,
                            row_number()
                            over(ORDER BY
                                 decode(lte.flg_referral,
                                        NULL,
                                        pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det),
                                        pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', lte.flg_referral)),
                                 coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req)),
                            row_number()
                            over(ORDER BY
                                 decode(lte.flg_referral,
                                        NULL,
                                        decode(lte.flg_status_det,
                                               pk_lab_tests_constant.g_analysis_toexec,
                                               pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', lte.flg_status_harvest),
                                               pk_sysdomain.get_rank(i_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     lte.flg_status_det)),
                                        pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', lte.flg_referral)),
                                 coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req) DESC)) rank,
                     pk_date_utils.date_send_tsz(i_lang, nvl(lte.dt_target, lte.dt_req), i_prof) dt_ord,
                     decode(cso.desc_prof_ordered_by, NULL, NULL, cso.desc_prof_ordered_by) prof_order,
                     decode(cso.dt_ordered_by,
                            NULL,
                            NULL,
                            pk_date_utils.date_char_tsz(i_lang, cso.dt_ordered_by, i_prof.institution, i_prof.software)) dt_order,
                     decode(cso.id_order_type, NULL, NULL, cso.desc_order_type) order_type,
                     cso.flg_status co_sign_status,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, cscs.id_prof_co_signed) co_sign_prof,
                     pk_date_utils.date_char_tsz(i_lang, cscs.dt_co_signed, i_prof.institution, i_prof.software) co_sign_date,
                     pk_string_utils.clob_to_varchar2(cscs.co_sign_notes, 1000) co_sign_notes
              FROM TABLE(tf_lab_tests_ea(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_patient    => l_patient,
                                         i_episode    => l_episode,
                                         i_visit      => l_visit,
                                         i_crit_type  => i_crit_type,
                                         i_start_date => l_start_date,
                                         i_end_date   => l_end_date)) lte
             INNER JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = lte.id_analysis_req_det
              LEFT JOIN cso_table cso
                ON ard.id_co_sign_order = cso.id_co_sign_hist
              LEFT JOIN cso_table_cs cscs
                ON ard.id_analysis_req_det = cscs.id_task_group
               AND cscs.flg_status = pk_co_sign_api.g_cosign_flg_status_cs
            
             ORDER BY rank, desc_analysis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TESTS_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_tests_listview;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        i_flg_report       IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_result_list      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list t_tbl_lab_tests_results;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_flg_type         => i_flg_type,
                                                          i_dt_min           => i_dt_min,
                                                          i_dt_max           => i_dt_max,
                                                          i_flg_report       => i_flg_report,
                                                          o_list             => l_list,
                                                          o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        OPEN o_list FOR
            SELECT ar.flg_type               flg_type,
                   ar.id_analysis_req        id_analysis_req,
                   ar.id_analysis_req_det    id_analysis_req_det,
                   ar.id_ard_parent          id_ard_parent,
                   ar.id_analysis_req_par    id_analysis_req_par,
                   ar.id_analysis_result     id_analysis_result,
                   ar.id_analysis_result_par id_analysis_result_par,
                   ar.id_arp_parent          id_arp_parent,
                   ar.id_analysis            id_analysis,
                   ar.id_analysis_parameter  id_analysis_parameter,
                   ar.id_sample_type         id_sample_type,
                   ar.id_exam_cat            id_exam_cat,
                   ar.id_harvest             id_harvest,
                   ar.desc_analysis          desc_analysis,
                   ar.desc_parameter         desc_parameter,
                   ar.desc_sample            desc_sample,
                   ar.desc_category          desc_category,
                   ar.partial_result         partial_result,
                   ar.id_unit_measure        id_unit_measure,
                   ar.desc_unit_measure      desc_unit_measure,
                   ar.prof_harvest           prof_harvest,
                   ar.prof_spec_harvest      prof_spec_harvest,
                   ar.dt_harvest             dt_harvest,
                   ar.dt_harvest_date        dt_harvest_date,
                   ar.dt_harvest_hour        dt_harvest_hour,
                   ar.prof_result            prof_result,
                   ar.prof_spec_result       prof_spec_result,
                   ar.dt_result              dt_result,
                   ar.dt_result_date         dt_result_date,
                   ar.dt_result_hour         dt_result_hour,
                   ar.result                 RESULT,
                   ar.flg_result_type        flg_result_type,
                   ar.flg_status             flg_status,
                   ar.result_status          result_status,
                   ar.result_range           result_range,
                   ar.result_color           result_color,
                   ar.ref_val                ref_val,
                   ar.result_notes           result_notes,
                   ar.parameter_notes        parameter_notes,
                   ar.desc_lab               desc_lab,
                   ar.desc_lab_notes         desc_lab_notes,
                   ar.abnormality            abnormality,
                   ar.desc_abnormality       desc_abnormality,
                   ar.rank_analysis          rank_analysis,
                   ar.rank_parameter         rank_parameter,
                   ar.rank_category          rank_category,
                   ar.dt_harvest_ord         dt_harvest_ord,
                   ar.dt_result_ord          dt_result_ord
              FROM TABLE(l_list) ar
             WHERE ar.rn = 1
               AND ar.flg_type = 'P'
               AND ar.result IS NOT NULL
               AND ((ar.id_visit = i_visit AND i_visit IS NOT NULL) OR i_visit IS NULL)
               AND ((ar.id_episode = i_episode AND i_episode IS NOT NULL) OR i_episode IS NULL)
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      decode(i_flg_type, 'H', ar.dt_harvest_ord, ar.dt_result_ord) DESC,
                      decode(i_flg_type, 'H', ar.id_harvest, ar.id_analysis_result) DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_flg_type         => i_flg_type,
                                                          i_dt_min           => NULL,
                                                          i_dt_max           => NULL,
                                                          i_flg_report       => pk_lab_tests_constant.g_yes,
                                                          o_list             => l_list,
                                                          o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        OPEN o_result_list FOR
            SELECT ar.flg_type               flg_type,
                   ar.id_analysis_req        id_analysis_req,
                   ar.id_analysis_req_det    id_analysis_req_det,
                   ar.id_ard_parent          id_ard_parent,
                   ar.id_analysis_req_par    id_analysis_req_par,
                   ar.id_analysis_result     id_analysis_result,
                   ar.id_analysis_result_par id_analysis_result_par,
                   ar.id_arp_parent          id_arp_parent,
                   ar.id_analysis            id_analysis,
                   ar.id_analysis_parameter  id_analysis_parameter,
                   ar.id_sample_type         id_sample_type,
                   ar.id_exam_cat            id_exam_cat,
                   ar.id_harvest             id_harvest,
                   ar.desc_analysis          desc_analysis,
                   ar.desc_parameter         desc_parameter,
                   ar.desc_sample            desc_sample,
                   ar.desc_category          desc_category,
                   ar.partial_result         partial_result,
                   ar.id_unit_measure        id_unit_measure,
                   ar.desc_unit_measure      desc_unit_measure,
                   ar.prof_harvest           prof_harvest,
                   ar.prof_spec_harvest      prof_spec_harvest,
                   ar.dt_harvest             dt_harvest,
                   ar.dt_harvest_date        dt_harvest_date,
                   ar.dt_harvest_hour        dt_harvest_hour,
                   ar.prof_result            prof_result,
                   ar.prof_spec_result       prof_spec_result,
                   ar.dt_result              dt_result,
                   ar.dt_result_date         dt_result_date,
                   ar.dt_result_hour         dt_result_hour,
                   ar.result                 RESULT,
                   ar.flg_result_type        flg_result_type,
                   ar.flg_status             flg_status,
                   ar.result_status          result_status,
                   ar.result_range           result_range,
                   ar.result_color           result_color,
                   ar.ref_val                ref_val,
                   ar.result_notes           result_notes,
                   ar.parameter_notes        parameter_notes,
                   ar.desc_lab               desc_lab,
                   ar.desc_lab_notes         desc_lab_notes,
                   ar.abnormality            abnormality,
                   ar.desc_abnormality       desc_abnormality,
                   ar.rank_analysis          rank_analysis,
                   ar.rank_parameter         rank_parameter,
                   ar.rank_category          rank_category,
                   ar.dt_harvest_ord         dt_harvest_ord,
                   ar.dt_result_ord          dt_result_ord
              FROM TABLE(l_list) ar
             WHERE ar.rn BETWEEN 2 AND 3
               AND ((ar.dt_harvest_ord < i_dt_min AND i_flg_type = 'H') OR
                   (ar.dt_result_ord < i_dt_min AND i_flg_type = 'R'))
               AND ar.flg_type = 'P'
               AND ar.result IS NOT NULL
               AND ((ar.id_visit = i_visit AND i_visit IS NOT NULL) OR i_visit IS NULL)
               AND ((ar.id_episode = i_episode AND i_episode IS NOT NULL) OR i_episode IS NULL)
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      decode(i_flg_type, 'H', ar.dt_harvest_ord, ar.dt_result_ord) DESC,
                      decode(i_flg_type, 'H', ar.id_harvest, ar.id_analysis_result) DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_RESULTSVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_resultsview;

    FUNCTION get_reports_table1
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_column_number IN NUMBER DEFAULT 10000,
        i_episode       IN episode.id_episode%TYPE,
        i_visit         IN visit.id_visit%TYPE,
        i_crit_type     IN VARCHAR2 DEFAULT 'A',
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        o_list_columns  OUT pk_types.cursor_type,
        o_list_rows     OUT pk_types.cursor_type,
        o_list_values   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cda_default_language sys_config.value%TYPE := pk_sysconfig.get_config('CDA_DEFAULT_LANGUAGE', i_prof);
        l_cda_source_id_alert  sys_config.value%TYPE := pk_sysconfig.get_config('CDA_SOURCE_ID_ALERT', i_prof);
        l_cda_target_snomed_ct sys_config.value%TYPE := pk_sysconfig.get_config('CDA_TARGET_SNOMED_CT', i_prof);
        l_cda_snomed_ct        sys_config.value%TYPE := pk_sysconfig.get_config('CDA_SNOMED_CT', i_prof);
    
        l_lab_res_mult sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_MULTIPLE_RESULTS', i_prof);
    
        l_loinc_code PLS_INTEGER := 4;
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_tbl_analysis_result   t_tbl_analysis_result := t_tbl_analysis_result(NULL);
        l_tbl_analysis_result_p t_tbl_analysis_result := t_tbl_analysis_result(NULL);
    BEGIN
    
        g_error      := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_start_date';
        l_start_date := CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_start_date)
                            ELSE
                             NULL
                        END;
    
        g_error    := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_end_date';
        l_end_date := CASE
                          WHEN i_end_date IS NOT NULL THEN
                           pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_end_date)
                          ELSE
                           NULL
                      END;
    
        -- if no parametrization is found, use the alert default language.
        IF l_cda_default_language IS NULL
        THEN
            l_cda_default_language := i_lang;
        END IF;
    
        --forces default values if no config is found
        IF l_cda_source_id_alert IS NULL
        THEN
            l_cda_source_id_alert := 1;
        END IF;
    
        --forces default values if no config is found
        IF l_cda_target_snomed_ct IS NULL
        THEN
            l_cda_target_snomed_ct := 2;
        END IF;
    
        --forces default values if no config is found
        IF l_cda_snomed_ct IS NULL
        THEN
            l_cda_snomed_ct := 1;
        END IF;
    
        l_tbl_analysis_result   := tf_analysis_result(i_lang, i_prof, i_patient, i_episode, i_visit);
        l_tbl_analysis_result_p := tf_analysis_result(i_lang, i_prof, i_patient, NULL, NULL);
    
        g_error := 'OPEN o_list_columns';
        -- Get columns data
        -- WARNING: changing this cursor will imply also changing get_reports_counter
        OPEN o_list_columns FOR
            SELECT *
              FROM (SELECT t.cat_id        category_id,
                           t.cat_desc      category_desc,
                           t.time_var      column_id,
                           t.hour_read     hour_read,
                           t.short_dt_read short_dt_read,
                           t.header_desc   header_desc,
                           t.date_target,
                           t.hour_target,
                           t.harvest_prof,
                           t.revised_by,
                           t.column_number
                      FROM (SELECT DISTINCT cat_id,
                                            cat_desc,
                                            id_analysis_result_par id_analysis_result_par,
                                            dt_harvest             time_var,
                                            NULL                   dt_periodic_observation_reg,
                                            hour_read,
                                            short_dt_read,
                                            header_desc,
                                            date_target,
                                            hour_target,
                                            harvest_prof,
                                            revised_by,
                                            column_number
                              FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                    DISTINCT CASE
                                                  WHEN ec.parent_id IS NOT NULL THEN
                                                   ec.parent_id
                                                  ELSE
                                                   ec.id_exam_cat
                                              END cat_id,
                                             CASE
                                                  WHEN ec.parent_id IS NOT NULL THEN
                                                   pk_translation.get_translation(i_lang,
                                                                                  'EXAM_CAT.CODE_EXAM_CAT.' || ec.parent_id)
                                                  ELSE
                                                   pk_translation.get_translation(i_lang, ec.code_exam_cat)
                                              END cat_desc,
                                             0 id_analysis_result_par,
                                             pk_date_utils.date_send_tsz(i_lang,
                                                                         nvl(por.dt_periodic_observation_reg, por.dt_result),
                                                                         i_prof) dt_harvest,
                                             NULL dt_sample,
                                             pk_date_utils.date_char_hour_tsz(i_lang,
                                                                              nvl(por.dt_periodic_observation_reg,
                                                                                  por.dt_result),
                                                                              i_prof.institution,
                                                                              i_prof.software) hour_read,
                                             pk_date_utils.date_send_tsz(i_lang,
                                                                         nvl(por.dt_periodic_observation_reg, por.dt_result),
                                                                         i_prof) short_dt_read,
                                             pk_date_utils.get_year(i_lang,
                                                                    i_prof,
                                                                    nvl(por.dt_periodic_observation_reg, por.dt_result)) || '|' ||
                                             pk_date_utils.get_month_day(i_lang,
                                                                         i_prof,
                                                                         nvl(por.dt_periodic_observation_reg, por.dt_result)) || '|' ||
                                             pk_date_utils.date_char_hour_tsz(i_lang,
                                                                              nvl(por.dt_periodic_observation_reg,
                                                                                  por.dt_result),
                                                                              i_prof.institution,
                                                                              i_prof.software) || '|' ||
                                             
                                             decode(por.flg_type_reg,
                                                    pk_lab_tests_constant.g_apf_type_history,
                                                    'M',
                                                    pk_lab_tests_constant.g_apf_type_maternal_health,
                                                    'M',
                                                    pk_periodic_observation.g_flg_type_reg,
                                                    'M',
                                                    'X') || '|' header_desc,
                                             pk_date_utils.dt_chr_tsz(i_lang,
                                                                      nvl(por.dt_periodic_observation_reg, por.dt_result),
                                                                      i_prof) date_target,
                                             pk_date_utils.date_char_hour_tsz(i_lang,
                                                                              nvl(por.dt_periodic_observation_reg,
                                                                                  por.dt_result),
                                                                              i_prof.institution,
                                                                              i_prof.software) hour_target,
                                             pk_prof_utils.get_name_signature(i_lang,
                                                                              i_prof,
                                                                              nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                                              i_prof,
                                                                                                                              ar.id_harvest),
                                                                                  ar.id_professional)) harvest_prof,
                                             pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by) revised_by,
                                             1 column_number
                                      FROM periodic_observation_reg por,
                                           TABLE(l_tbl_analysis_result) ar,
                                           exam_cat ec,
                                           harvest h
                                     WHERE por.flg_type_reg IN
                                           (pk_periodic_observation.g_flg_type_reg,
                                            pk_lab_tests_constant.g_apf_type_history,
                                            pk_lab_tests_constant.g_apf_type_maternal_health)
                                       AND ((por.id_patient = i_patient AND i_patient IS NOT NULL) OR i_patient IS NULL)
                                       AND NOT EXISTS
                                     (SELECT /*+ opt_estimate(table ar rows=1) */
                                             1
                                              FROM TABLE(l_tbl_analysis_result_p) ar
                                             WHERE ar.dt_sample = por.dt_periodic_observation_reg)
                                       AND por.flg_group = pk_periodic_observation.g_analysis
                                       AND por.id_analysis_result = ar.id_analysis_result
                                       AND ar.id_harvest = h.id_harvest(+)
                                       AND ar.id_exam_cat = ec.id_exam_cat
                                       AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                           i_crit_type IS NOT NULL AND
                                           nvl(por.dt_periodic_observation_reg, por.dt_result) >=
                                           nvl(l_start_date, nvl(por.dt_periodic_observation_reg, por.dt_result))) AND
                                           (nvl(por.dt_periodic_observation_reg, por.dt_result) <=
                                           nvl(l_end_date, nvl(por.dt_periodic_observation_reg, por.dt_result)) OR
                                           i_crit_type IS NULL))
                                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                     i_prof,
                                                                                                     ar.id_analysis)
                                              FROM dual) = pk_alert_constant.g_yes
                                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                     i_prof,
                                                                                                     ar.id_analysis,
                                                                                                     pk_lab_tests_constant.g_infectious_diseases_results)
                                              FROM dual) = pk_alert_constant.g_yes
                                    UNION
                                    -- Records without specimen collection (harvest)
                                    -- thus label "Record" should be displayed
                                    SELECT t.*,
                                           row_number() over(PARTITION BY t.dt_sample ORDER BY t.id_analysis_result_par) column_number
                                      FROM (SELECT /*+ opt_estimate(table ar rows=1)*/
                                            DISTINCT CASE
                                                          WHEN ec.parent_id IS NOT NULL THEN
                                                           ec.parent_id
                                                          ELSE
                                                           ec.id_exam_cat
                                                      END cat_id,
                                                     CASE
                                                          WHEN ec.parent_id IS NOT NULL THEN
                                                           pk_translation.get_translation(i_lang,
                                                                                          'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                                          ec.parent_id)
                                                          ELSE
                                                           pk_translation.get_translation(i_lang, ec.code_exam_cat)
                                                      END cat_desc,
                                                     arp.id_analysis_result_par id_analysis_result_par,
                                                     pk_date_utils.date_send_tsz(i_lang,
                                                                                 nvl(ar.dt_sample,
                                                                                     ar.dt_analysis_result_tstz),
                                                                                 i_prof) dt_harvest,
                                                     pk_date_utils.date_send_tsz(i_lang,
                                                                                 nvl(ar.dt_sample,
                                                                                     ar.dt_analysis_result_tstz),
                                                                                 i_prof) dt_sample,
                                                     NULL hour_read,
                                                     pk_date_utils.date_send_tsz(i_lang,
                                                                                 nvl(ar.dt_sample,
                                                                                     ar.dt_analysis_result_tstz),
                                                                                 i_prof) short_dt_read,
                                                     pk_date_utils.get_year(i_lang,
                                                                            i_prof,
                                                                            nvl(ar.dt_sample, ar.dt_analysis_result_tstz)) || '|' ||
                                                     pk_date_utils.get_month_day(i_lang,
                                                                                 i_prof,
                                                                                 nvl(ar.dt_sample,
                                                                                     ar.dt_analysis_result_tstz)) || '|' ||
                                                     pk_message.get_message(i_lang, 'COMMON_M052') || '|' ||
                                                     decode(arp.id_analysis_req_par, NULL, 'M', 'Y') || '|' header_desc,
                                                     pk_date_utils.dt_chr_tsz(i_lang,
                                                                              nvl(ar.dt_sample, ar.dt_analysis_result_tstz),
                                                                              i_prof) date_target,
                                                     pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                      nvl(ar.dt_sample,
                                                                                          ar.dt_analysis_result_tstz),
                                                                                      i_prof.institution,
                                                                                      i_prof.software) hour_target,
                                                     pk_prof_utils.get_name_signature(i_lang,
                                                                                      i_prof,
                                                                                      nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                                                      i_prof,
                                                                                                                                      ar.id_harvest),
                                                                                          ar.id_professional)) harvest_prof,
                                                     pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by) revised_by
                                              FROM lab_tests_ea lte,
                                                   analysis_result_par arp,
                                                   TABLE(tf_analysis_result(i_lang, i_prof, i_patient, i_episode, i_visit)) ar,
                                                   exam_cat ec,
                                                   harvest h
                                             WHERE ar.id_institution = i_prof.institution
                                               AND ar.id_analysis_result = arp.id_analysis_result(+)
                                               AND lte.id_analysis_req_det(+) = ar.id_analysis_req_det
                                               AND (lte.flg_status_harvest = pk_lab_tests_constant.g_harvest_pending OR
                                                   lte.flg_status_harvest IS NULL)
                                               AND lte.dt_harvest IS NULL
                                               AND ar.id_harvest = h.id_harvest(+)
                                               AND ar.id_exam_cat = ec.id_exam_cat
                                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                             i_prof,
                                                                                                             lte.id_analysis)
                                                      FROM dual) = pk_alert_constant.g_yes
                                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                             i_prof,
                                                                                                             lte.id_analysis,
                                                                                                             pk_lab_tests_constant.g_infectious_diseases_results)
                                                      FROM dual) = pk_alert_constant.g_yes
                                               AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                                   i_crit_type IS NOT NULL AND
                                                   nvl(ar.dt_sample, ar.dt_analysis_result_tstz) >=
                                                   nvl(l_start_date, nvl(ar.dt_sample, ar.dt_analysis_result_tstz))) AND
                                                   (nvl(ar.dt_sample, ar.dt_analysis_result_tstz) <=
                                                   nvl(l_end_date, nvl(ar.dt_sample, ar.dt_analysis_result_tstz)) OR
                                                   i_crit_type IS NULL))) t
                                    UNION
                                    -- Records with specimen collection (harvest)
                                    SELECT DISTINCT CASE
                                                        WHEN ec.parent_id IS NOT NULL THEN
                                                         ec.parent_id
                                                        ELSE
                                                         ec.id_exam_cat
                                                    END cat_id,
                                                    CASE
                                                        WHEN ec.parent_id IS NOT NULL THEN
                                                         pk_translation.get_translation(i_lang,
                                                                                        'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                                        ec.parent_id)
                                                        ELSE
                                                         pk_translation.get_translation(i_lang, ec.code_exam_cat)
                                                    END cat_desc,
                                                    aresp.id_analysis_result_par id_analysis_result_par,
                                                    pk_date_utils.date_send_tsz(i_lang,
                                                                                coalesce(lte.dt_harvest_tstz,
                                                                                         aresp.dt_sample,
                                                                                         aresp.dt_analysis_result_tstz),
                                                                                i_prof) dt_harvest,
                                                    NULL dt_sample,
                                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                     coalesce(lte.dt_harvest_tstz,
                                                                                              aresp.dt_sample,
                                                                                              aresp.dt_analysis_result_tstz),
                                                                                     i_prof.institution,
                                                                                     i_prof.software) hour_read,
                                                    pk_date_utils.date_send_tsz(i_lang,
                                                                                coalesce(lte.dt_harvest_tstz,
                                                                                         aresp.dt_sample,
                                                                                         aresp.dt_analysis_result_tstz),
                                                                                i_prof) short_dt_read,
                                                    pk_date_utils.get_year(i_lang,
                                                                           i_prof,
                                                                           coalesce(lte.dt_harvest_tstz,
                                                                                    aresp.dt_sample,
                                                                                    aresp.dt_analysis_result_tstz)) || '|' ||
                                                    pk_date_utils.get_month_day(i_lang,
                                                                                i_prof,
                                                                                coalesce(lte.dt_harvest_tstz,
                                                                                         aresp.dt_sample,
                                                                                         aresp.dt_analysis_result_tstz)) || '|' ||
                                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                     coalesce(lte.dt_harvest_tstz,
                                                                                              aresp.dt_sample,
                                                                                              aresp.dt_analysis_result_tstz),
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || '|' ||
                                                    decode(nvl(aresp.flg_intf_orig, lte.flg_time_harvest),
                                                           decode(aresp.flg_intf_orig,
                                                                  NULL,
                                                                  pk_lab_tests_constant.g_flg_time_r,
                                                                  pk_lab_tests_constant.g_no),
                                                           'M',
                                                           'X') || '|' header_desc,
                                                    pk_date_utils.dt_chr_tsz(i_lang,
                                                                             coalesce(lte.dt_harvest_tstz,
                                                                                      aresp.dt_sample,
                                                                                      aresp.dt_analysis_result_tstz),
                                                                             i_prof) date_target,
                                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                     coalesce(lte.dt_harvest_tstz,
                                                                                              aresp.dt_sample,
                                                                                              aresp.dt_analysis_result_tstz),
                                                                                     i_prof.institution,
                                                                                     i_prof.software) hour_target,
                                                    pk_prof_utils.get_name_signature(i_lang,
                                                                                     i_prof,
                                                                                     nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     lte.id_harvest),
                                                                                         aresp.id_prof_result)) harvest_prof,
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_revised_by) revised_by,
                                                    1 column_number
                                      FROM (SELECT lte.*, h.dt_harvest_tstz, h.id_harvest, h.id_revised_by
                                              FROM lab_tests_ea lte, analysis_harvest ah, harvest h
                                             WHERE ((lte.id_patient = i_patient AND i_patient IS NOT NULL) OR
                                                   i_patient IS NULL)
                                               AND lte.id_analysis_req_det = ah.id_analysis_req_det
                                               AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                                               AND ah.id_harvest = h.id_harvest
                                               AND h.flg_status NOT IN
                                                   (pk_lab_tests_constant.g_harvest_pending,
                                                    pk_lab_tests_constant.g_harvest_waiting,
                                                    pk_lab_tests_constant.g_harvest_cancel,
                                                    pk_lab_tests_constant.g_harvest_suspended)
                                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                             i_prof,
                                                                                                             lte.id_analysis)
                                                      FROM dual) = pk_alert_constant.g_yes
                                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                             i_prof,
                                                                                                             lte.id_analysis,
                                                                                                             pk_lab_tests_constant.g_infectious_diseases_results)
                                                      FROM dual) = pk_alert_constant.g_yes
                                               AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                                   i_crit_type IS NOT NULL AND
                                                   lte.dt_harvest >= nvl(l_start_date, lte.dt_harvest)) AND
                                                   (lte.dt_harvest <= nvl(l_end_date, lte.dt_harvest) OR
                                                   i_crit_type IS NULL))) lte,
                                           (SELECT *
                                              FROM (SELECT /*+ opt_estimate(table ar rows=1)*/
                                                     arp.*,
                                                     ar.id_patient,
                                                     ar.id_analysis,
                                                     ar.id_analysis_req_det,
                                                     ar.id_harvest,
                                                     ar.dt_analysis_result_tstz,
                                                     ar.dt_sample,
                                                     ar.id_professional id_prof_result,
                                                     ar.notes,
                                                     ar.id_exam_cat,
                                                     decode(ar.id_harvest,
                                                            NULL,
                                                            row_number()
                                                            over(PARTITION BY arp.id_analysis_result,
                                                                 arp.id_analysis_parameter ORDER BY arp.dt_ins_result_tstz DESC),
                                                            row_number()
                                                            over(PARTITION BY ar.id_harvest,
                                                                 arp.id_analysis_req_par ORDER BY arp.dt_ins_result_tstz DESC)) rn
                                                      FROM analysis_result_par arp,
                                                           TABLE(tf_analysis_result(i_lang,
                                                                                    i_prof,
                                                                                    i_patient,
                                                                                    i_episode,
                                                                                    i_visit)) ar
                                                     WHERE arp.id_analysis_result = ar.id_analysis_result
                                                       AND ar.id_institution = i_prof.institution) ar
                                             WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                                                OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)) aresp,
                                           exam_cat ec
                                     WHERE lte.id_analysis_req_det(+) = aresp.id_analysis_req_det
                                       AND lte.id_harvest(+) = aresp.id_harvest
                                       AND ec.id_exam_cat(+) = aresp.id_exam_cat)) t
                     GROUP BY cat_id,
                              cat_desc,
                              time_var,
                              hour_read,
                              short_dt_read,
                              header_desc,
                              date_target,
                              hour_target,
                              t.harvest_prof,
                              t.revised_by,
                              column_number
                     ORDER BY t.time_var ASC)
             WHERE rownum <= nvl(i_column_number, 10000);
    
        OPEN o_list_rows FOR
            WITH lab_tests_data AS
             (SELECT ar.id_analysis,
                     ar.id_analysis_parameter,
                     ar.id_sample_type,
                     ar.dt_result,
                     ar.id_analysis_req_det,
                     ar.id_analysis_result,
                     ar.id_analysis_result_par,
                     ar.id_unit_measure,
                     ar.id_exam_cat,
                     ar.code_exam_cat,
                     ar.id_content,
                     ar.rank,
                     ar.parent_id
                FROM (SELECT /*+ opt_estimate(table ar rows=1)*/
                       ar.id_analysis,
                       arp.id_analysis_parameter,
                       ar.id_sample_type,
                       nvl(to_char(ar.id_harvest),
                           pk_date_utils.date_send_tsz(i_lang,
                                                       pk_date_utils.trunc_insttimezone(i_prof,
                                                                                        ar.dt_analysis_result_tstz,
                                                                                        'MI'),
                                                       i_prof)) dt_result,
                       ar.id_analysis_req_det,
                       arp.id_analysis_result,
                       arp.id_analysis_result_par,
                       arp.id_unit_measure,
                       ar.id_exam_cat,
                       ec.code_exam_cat,
                       ec.id_content,
                       ec.rank,
                       ec.parent_id,
                       decode(ar.id_harvest,
                              NULL,
                              row_number() over(PARTITION BY arp.id_analysis_result,
                                   arp.id_analysis_parameter ORDER BY arp.dt_ins_result_tstz DESC),
                              row_number() over(PARTITION BY ar.id_harvest,
                                   arp.id_analysis_req_par ORDER BY arp.dt_ins_result_tstz DESC)) rn
                        FROM TABLE(tf_analysis_result(i_lang, i_prof, i_patient, i_episode, i_visit)) ar
                       INNER JOIN analysis_result_par arp
                          ON arp.id_analysis_result = ar.id_analysis_result
                       INNER JOIN exam_cat ec
                          ON ec.id_exam_cat = ar.id_exam_cat
                         AND ec.flg_lab = 'Y'
                       WHERE arp.id_analysis_result = ar.id_analysis_result
                         AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                             arp.dt_cancel IS NULL)
                         AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, ar.id_analysis)
                                FROM dual) = pk_alert_constant.g_yes
                         AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                       i_prof,
                                                                                       ar.id_analysis,
                                                                                       pk_lab_tests_constant.g_infectious_diseases_results)
                                FROM dual) = pk_alert_constant.g_yes
                         AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                             i_crit_type IS NOT NULL AND
                             nvl(ar.dt_sample, ar.dt_analysis_result_tstz) >=
                             nvl(l_start_date, nvl(ar.dt_sample, ar.dt_analysis_result_tstz))) AND
                             (nvl(ar.dt_sample, ar.dt_analysis_result_tstz) <=
                             nvl(l_end_date, nvl(ar.dt_sample, ar.dt_analysis_result_tstz)) OR i_crit_type IS NULL))) ar
               WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                  OR (l_lab_res_mult = pk_lab_tests_constant.g_yes))
            SELECT id_analysis,
                   id_analysis_req_det,
                   lab_test_desc,
                   id_analysis_parameter,
                   id_analysis_result_par,
                   id_unit_measure,
                   element_desc,
                   cat_id,
                   cat_desc,
                   id_content,
                   flg_has_parent,
                   flg_has_children,
                   rank_lab_test,
                   rank_lab_test_param,
                   rank_exam_cat
              FROM (SELECT ar.id_analysis,
                           ar.id_analysis_req_det,
                           pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     pk_lab_tests_constant.g_analysis_alias,
                                                                     'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ar.id_sample_type,
                                                                     NULL) lab_test_desc,
                           decode(ar.id_analysis_parameter,
                                  0,
                                  NULL,
                                  to_number(ar.id_analysis_parameter || ar.id_sample_type)) id_analysis_parameter,
                           decode(ar.flg_has_parent,
                                  pk_lab_tests_constant.g_no,
                                  pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                            i_prof,
                                                                            pk_lab_tests_constant.g_analysis_alias,
                                                                            'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                            ar.id_sample_type,
                                                                            NULL),
                                  pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                            i_prof,
                                                                            pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                            'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                            ar.id_analysis_parameter,
                                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                            ar.id_sample_type,
                                                                            NULL)) element_desc,
                           CASE
                                WHEN ar.parent_id IS NOT NULL THEN
                                 ar.parent_id
                                ELSE
                                 ar.id_exam_cat
                            END cat_id,
                           CASE
                                WHEN ar.parent_id IS NOT NULL THEN
                                 pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ar.parent_id)
                                ELSE
                                 pk_translation.get_translation(i_lang, ar.code_exam_cat)
                            END cat_desc,
                           CASE
                                WHEN ar.parent_id IS NOT NULL THEN
                                 pk_lab_tests_utils.get_lab_test_cat_id_content(i_lang, i_prof, ar.parent_id)
                                ELSE
                                 ar.id_content
                            END id_content,
                           ar.flg_has_parent,
                           ar.flg_has_children,
                           pk_lab_tests_utils.get_lab_test_rank(i_lang, i_prof, ar.id_analysis, NULL) rank_lab_test,
                           pk_lab_tests_utils.get_lab_test_parameter_rank(i_lang,
                                                                          i_prof,
                                                                          ar.id_analysis,
                                                                          ar.id_sample_type,
                                                                          ar.id_analysis_parameter) rank_lab_test_param,
                           ar.rank rank_exam_cat,
                           decode(ar.id_analysis_parameter, 0, 'A', 'P') flg_type,
                           ar.id_analysis_result_par,
                           CASE
                                WHEN ar.id_unit_measure IS NULL THEN
                                 pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                              i_prof,
                                                                              ar.id_analysis,
                                                                              ar.id_sample_type,
                                                                              ar.id_analysis_parameter)
                                ELSE
                                 ar.id_unit_measure
                            END id_unit_measure
                      FROM (
                            -- Get lab tests with more than one parameter
                            SELECT DISTINCT ltd.id_analysis,
                                             ltd.id_sample_type,
                                             0                           id_analysis_parameter,
                                             0                           id_analysis_result_par,
                                             ltd.id_analysis_req_det,
                                             0                           id_unit_measure,
                                             pk_lab_tests_constant.g_no  flg_has_parent,
                                             pk_lab_tests_constant.g_yes flg_has_children,
                                             ltd.id_exam_cat,
                                             ltd.code_exam_cat,
                                             ltd.id_content,
                                             ltd.parent_id,
                                             ltd.rank
                              FROM (SELECT ltd.*,
                                            COUNT(ltd.id_analysis_parameter) over(PARTITION BY ltd.id_analysis, ltd.id_sample_type) ap_count
                                       FROM lab_tests_data ltd) ltd
                             WHERE ltd.ap_count > 1
                            UNION
                            -- Get lab tests with ONE parameter
                            -- AND
                            -- Get parameters for lab tests with more than one parameter
                            SELECT DISTINCT ltd.id_analysis,
                                             ltd.id_sample_type,
                                             ltd.id_analysis_parameter,
                                             ltd.id_analysis_result_par,
                                             ltd.id_analysis_req_det,
                                             ltd.id_unit_measure,
                                             decode(ltd.ap_count,
                                                    0,
                                                    pk_lab_tests_constant.g_no,
                                                    1,
                                                    pk_lab_tests_constant.g_no,
                                                    pk_lab_tests_constant.g_yes) flg_has_parent,
                                             pk_lab_tests_constant.g_no flg_has_children,
                                             ltd.id_exam_cat,
                                             ltd.code_exam_cat,
                                             ltd.id_content,
                                             ltd.parent_id,
                                             ltd.rank
                              FROM (SELECT ltd.*,
                                            COUNT(ltd.id_analysis_parameter) over(PARTITION BY ltd.id_analysis, ltd.id_sample_type) ap_count
                                       FROM lab_tests_data ltd) ltd) ar)
             ORDER BY rank_exam_cat,
                      cat_desc,
                      rank_lab_test,
                      lab_test_desc,
                      flg_type,
                      rank_lab_test_param,
                      element_desc;
    
        -- get analysis data
        -- warning : also change get_reports_table2 cursor values 
        -- when changing this cursor.
        g_error := 'OPEN o_list_values';
        OPEN o_list_values FOR
            SELECT t.id_analysis,
                   t.id_analysis_parameter,
                   t.column_id,
                   t.harvest_date,
                   t.harvest_prof,
                   t.harvest_prof_spec,
                   t.result_date,
                   t.id_analysis_result_par,
                   t.flg_result_status,
                   t.analysis_result,
                   t.id_unit_measure,
                   t.desc_unit_measure,
                   t.ref_val,
                   t.ref_val_min,
                   t.ref_val_max,
                   t.flg_abnorm,
                   t.abnorm,
                   t.abnorm_color,
                   t.desc_abnormality,
                   t.abbrev_lab,
                   t.desc_lab,
                   t.result_origin,
                   t.flg_param_notes,
                   t.prof_param_notes,
                   t.param_notes,
                   t.flg_result_notes,
                   t.result_notes,
                   t.prof_result_notes,
                   t.flg_cancel_notes,
                   t.cancel_notes,
                   t.prof_cancel_notes,
                   t.flg_interface_notes,
                   t.interface_notes,
                   t.id_content,
                   t.loinc_code,
                   t.snomed_code,
                   t.snomed_desc,
                   t.cda_date,
                   t.flg_abnorm_cda
              FROM (SELECT aresp.id_analysis id_analysis,
                           decode(aresp.id_analysis_parameter,
                                  0,
                                  NULL,
                                  to_number(aresp.id_analysis_parameter || aresp.id_sample_type)) id_analysis_parameter,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       coalesce(lte.dt_harvest_tstz,
                                                                aresp.dt_sample,
                                                                aresp.dt_analysis_result_tstz),
                                                       i_prof) column_id,
                           pk_date_utils.date_time_chr_tsz(i_lang, nvl(lte.dt_harvest_tstz, aresp.dt_sample), i_prof) harvest_date,
                           pk_prof_utils.get_name_signature(i_lang,
                                                            i_prof,
                                                            nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                            i_prof,
                                                                                                            lte.id_harvest),
                                                                aresp.id_prof_result)) harvest_prof,
                           pk_prof_utils.get_desc_category(i_lang,
                                                           i_prof,
                                                           nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                           i_prof,
                                                                                                           lte.id_harvest),
                                                               aresp.id_prof_result),
                                                           nvl(pk_lab_tests_utils.get_harvest_institution(i_lang,
                                                                                                          i_prof,
                                                                                                          lte.id_harvest),
                                                               aresp.id_institution)) harvest_prof_spec,
                           pk_date_utils.date_time_chr_tsz(i_lang, aresp.dt_analysis_result_tstz, i_prof) result_date,
                           aresp.id_analysis_result_par,
                           aresp.flg_status flg_result_status,
                           nvl(TRIM(aresp.desc_analysis_result),
                               (aresp.comparator || aresp.analysis_result_value_1 || aresp.separator ||
                               aresp.analysis_result_value_2)) analysis_result,
                           CASE
                                WHEN aresp.id_unit_measure IS NULL THEN
                                 pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                              i_prof,
                                                                              aresp.id_analysis,
                                                                              aresp.id_sample_type,
                                                                              aresp.id_analysis_parameter)
                                ELSE
                                 aresp.id_unit_measure
                            END id_unit_measure,
                           CASE
                                WHEN nvl(aresp.desc_unit_measure,
                                         pk_translation.get_translation(i_lang,
                                                                        'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                        aresp.id_unit_measure)) IS NULL THEN
                                 pk_translation.get_translation(i_lang,
                                                                'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                                                             i_prof,
                                                                                                             aresp.id_analysis,
                                                                                                             aresp.id_sample_type,
                                                                                                             aresp.id_analysis_parameter))
                                ELSE
                                 nvl(aresp.desc_unit_measure,
                                     pk_translation.get_translation(i_lang,
                                                                    'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                    aresp.id_unit_measure))
                            END desc_unit_measure,
                           TRIM(nvl(aresp.ref_val,
                                    decode((nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min) || ' - ' ||
                                           nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)),
                                           ' - ',
                                           ' ',
                                           nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min) || ' - ' ||
                                           nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)))) ref_val,
                           TRIM(nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min)) ref_val_min,
                           TRIM(nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)) ref_val_max,
                           CASE
                                WHEN pk_utils.is_number(aresp.desc_analysis_result) = pk_lab_tests_constant.g_yes
                                     AND aresp.analysis_result_value_2 IS NULL THEN
                                 CASE
                                     WHEN aresp.analysis_result_value_1 < aresp.ref_val_min THEN
                                      pk_lab_tests_constant.g_yes
                                     WHEN aresp.analysis_result_value_1 > aresp.ref_val_max THEN
                                      pk_lab_tests_constant.g_yes
                                     ELSE
                                      CASE
                                          WHEN aresp.id_abnormality IS NOT NULL THEN
                                           pk_lab_tests_constant.g_yes
                                          ELSE
                                           pk_lab_tests_constant.g_no
                                      END
                                 END
                                ELSE
                                 NULL
                            END flg_abnorm,
                           (SELECT decode(abn.value, 'NA', 'PN', abn.value)
                              FROM abnormality abn
                             WHERE abn.id_abnormality = aresp.id_abnormality) abnorm,
                           (SELECT abn.color_code
                              FROM abnormality abn
                             WHERE abn.id_abnormality = aresp.id_abnormality) abnorm_color,
                           (SELECT pk_translation.get_translation(i_lang, abn.code_abnormality)
                              FROM abnormality abn
                             WHERE abn.id_abnormality = aresp.id_abnormality) desc_abnormality,
                           aresp.laboratory_short_desc abbrev_lab,
                           aresp.laboratory_desc desc_lab,
                           pk_sysdomain.get_domain('ANALYSIS_REQ.FLG_RESULT_ORIGIN', aresp.flg_result_origin, i_lang) result_origin,
                           decode(dbms_lob.getlength(aresp.parameter_notes),
                                  NULL,
                                  pk_lab_tests_constant.g_no,
                                  pk_lab_tests_constant.g_yes) flg_param_notes,
                           decode(aresp.dt_cancel,
                                  NULL,
                                  pk_prof_utils.get_name_signature(i_lang,
                                                                   i_prof,
                                                                   nvl(aresp.id_professional_upd, aresp.id_professional)),
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_professional_cancel)) prof_param_notes,
                           aresp.parameter_notes param_notes,
                           decode(dbms_lob.getlength(aresp.notes),
                                  NULL,
                                  pk_lab_tests_constant.g_no,
                                  pk_lab_tests_constant.g_yes) flg_result_notes,
                           aresp.notes result_notes,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_prof_result) prof_result_notes,
                           decode(aresp.notes_cancel, '', pk_lab_tests_constant.g_no, pk_lab_tests_constant.g_yes) flg_cancel_notes,
                           aresp.notes_cancel cancel_notes,
                           aresp.id_professional_cancel prof_cancel_notes,
                           decode(dbms_lob.getlength(aresp.interface_notes),
                                  NULL,
                                  pk_lab_tests_constant.g_no,
                                  pk_lab_tests_constant.g_yes) flg_interface_notes,
                           aresp.interface_notes interface_notes,
                           ec.id_content id_content,
                           pk_mapping_sets.get_mapping_concept(l_cda_default_language,
                                                               i_prof,
                                                               a.id_content,
                                                               l_cda_source_id_alert,
                                                               l_loinc_code) loinc_code,
                           pk_mapping_sets.get_mapping_concept(l_cda_default_language,
                                                               i_prof,
                                                               a.id_content,
                                                               l_cda_source_id_alert,
                                                               l_cda_target_snomed_ct) snomed_code,
                           pk_mapping_sets.get_mapping_concept_desc(l_cda_default_language,
                                                                    i_prof,
                                                                    a.id_content,
                                                                    l_cda_source_id_alert,
                                                                    l_cda_target_snomed_ct,
                                                                    l_cda_snomed_ct) snomed_desc,
                           pk_date_utils.date_time_chr_tsz(i_lang,
                                                           coalesce(lte.dt_harvest_tstz,
                                                                    aresp.dt_sample,
                                                                    aresp.dt_analysis_result_tstz),
                                                           i_prof) cda_date,
                           CASE
                                WHEN pk_utils.is_number(aresp.desc_analysis_result) = 'Y'
                                     AND analysis_result_value_2 IS NULL THEN
                                 CASE
                                     WHEN aresp.analysis_result_value_1 < aresp.ref_val_min THEN
                                      'L'
                                     WHEN aresp.analysis_result_value_1 > aresp.ref_val_max THEN
                                      'H'
                                     WHEN (aresp.ref_val_max IS NULL AND aresp.ref_val_min IS NULL) THEN
                                      NULL
                                     ELSE
                                      'N'
                                 END
                                ELSE
                                 NULL
                            END flg_abnorm_cda
                      FROM (SELECT lte.*, h.dt_harvest_tstz, h.id_harvest
                              FROM lab_tests_ea lte, analysis_harvest ah, harvest h
                             WHERE ((lte.id_patient = i_patient AND i_patient IS NOT NULL) OR i_patient IS NULL)
                               AND lte.id_analysis_req_det = ah.id_analysis_req_det
                               AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                               AND ah.id_harvest = h.id_harvest
                               AND h.flg_status NOT IN (pk_lab_tests_constant.g_harvest_pending,
                                                        pk_lab_tests_constant.g_harvest_waiting,
                                                        pk_lab_tests_constant.g_harvest_cancel,
                                                        pk_lab_tests_constant.g_harvest_suspended)
                               AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                   i_crit_type IS NOT NULL AND lte.dt_harvest >= nvl(l_start_date, lte.dt_harvest)) AND
                                   (lte.dt_harvest <= nvl(l_end_date, lte.dt_harvest) OR i_crit_type IS NULL))) lte,
                           (SELECT *
                              FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                     arp.*,
                                     ar.id_analysis,
                                     ar.id_sample_type,
                                     ar.id_analysis_req_det,
                                     ar.id_harvest,
                                     ar.id_exam_cat,
                                     ar.dt_analysis_result_tstz,
                                     ar.dt_sample,
                                     ar.id_professional id_prof_result,
                                     ar.flg_status,
                                     ar.notes,
                                     ar.flg_result_origin,
                                     ar.id_institution,
                                     decode(ar.id_harvest,
                                            NULL,
                                            row_number()
                                            over(PARTITION BY arp.id_analysis_result,
                                                 arp.id_analysis_parameter ORDER BY arp.dt_ins_result_tstz DESC),
                                            row_number() over(PARTITION BY ar.id_harvest,
                                                 arp.id_analysis_req_par ORDER BY arp.dt_ins_result_tstz DESC)) rn
                                      FROM analysis_result_par arp
                                      JOIN TABLE(l_tbl_analysis_result) ar
                                        ON arp.id_analysis_result = ar.id_analysis_result
                                     WHERE ar.id_institution = i_prof.institution
                                       AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                           arp.dt_cancel IS NULL)) ar
                             WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                                OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)) aresp,
                           analysis_desc ad,
                           (SELECT t.id_analysis
                              FROM (SELECT al.id_analysis, rownum rn
                                      FROM analysis_loinc al
                                     WHERE al.id_institution IN (0, i_prof.institution)
                                       AND al.id_software IN (0, i_prof.software)
                                       AND al.flg_default = pk_lab_tests_constant.g_yes
                                     ORDER BY al.id_institution DESC, al.id_software DESC) t
                             WHERE t.rn = 1) al,
                           analysis a,
                           exam_cat ec
                     WHERE aresp.id_analysis = a.id_analysis
                       AND aresp.id_analysis_parameter = ad.id_analysis_parameter(+)
                       AND to_char(aresp.desc_analysis_result) = ad.value(+)
                       AND aresp.id_exam_cat = ec.id_exam_cat(+)
                       AND aresp.id_analysis = al.id_analysis(+)
                       AND aresp.id_analysis_req_det = lte.id_analysis_req_det(+)
                       AND aresp.id_harvest = lte.id_harvest(+)
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, aresp.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                     i_prof,
                                                                                     aresp.id_analysis,
                                                                                     pk_lab_tests_constant.g_infectious_diseases_results)
                              FROM dual) = pk_alert_constant.g_yes) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_TABLE1',
                                              o_error);
            pk_types.open_my_cursor(o_list_columns);
            pk_types.open_my_cursor(o_list_rows);
            pk_types.open_my_cursor(o_list_values);
            RETURN FALSE;
    END get_reports_table1;

    FUNCTION get_reports_table2
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_visit              IN visit.id_visit%TYPE,
        i_crit_type          IN VARCHAR2 DEFAULT 'A',
        i_start_date         IN VARCHAR2,
        i_end_date           IN VARCHAR2,
        o_list_columns       OUT pk_types.cursor_type,
        o_list_rows          OUT pk_types.cursor_type,
        o_list_values        OUT pk_types.cursor_type,
        o_list_minmax_values OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_lab_res_mult sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_MULTIPLE_RESULTS', i_prof);
    
        l_tbl_analysis_result t_tbl_analysis_result := t_tbl_analysis_result(NULL);
    BEGIN
    
        g_error      := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_start_date';
        l_start_date := CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_start_date)
                            ELSE
                             NULL
                        END;
    
        g_error    := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_end_date';
        l_end_date := CASE
                          WHEN i_end_date IS NOT NULL THEN
                           pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_end_date)
                          ELSE
                           NULL
                      END;
    
        l_tbl_analysis_result := tf_analysis_result(i_lang, i_prof, i_patient, i_episode, i_visit);
    
        -- display columns
        OPEN o_list_columns FOR
            SELECT pk_message.get_message(i_lang, 'ANALYSIS_M140') first_result,
                   pk_message.get_message(i_lang, 'ANALYSIS_M141') lower_result,
                   pk_message.get_message(i_lang, 'ANALYSIS_M142') higher_result,
                   pk_message.get_message(i_lang, 'ANALYSIS_M143') last_three_results,
                   pk_message.get_message(i_lang, 'ANALYSIS_M144') reference_values
              FROM dual;
    
        OPEN o_list_rows FOR
            WITH lab_tests_data AS
             (SELECT ar.id_analysis,
                     ar.id_analysis_parameter,
                     ar.id_sample_type,
                     ar.dt_result,
                     ar.id_analysis_req_det,
                     ar.id_analysis_result,
                     ar.id_analysis_result_par,
                     ar.id_exam_cat,
                     ar.code_exam_cat,
                     ar.id_content,
                     ar.rank,
                     ar.parent_id
                FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                       ar.id_analysis,
                       arp.id_analysis_parameter,
                       ar.id_sample_type,
                       nvl(to_char(ar.id_harvest),
                           pk_date_utils.date_send_tsz(i_lang,
                                                       pk_date_utils.trunc_insttimezone(i_prof,
                                                                                        ar.dt_analysis_result_tstz,
                                                                                        'MI'),
                                                       i_prof)) dt_result,
                       ar.id_analysis_req_det,
                       arp.id_analysis_result,
                       arp.id_analysis_result_par,
                       ar.id_exam_cat,
                       ec.code_exam_cat,
                       ec.id_content,
                       ec.rank,
                       ec.parent_id,
                       decode(ar.id_harvest,
                              NULL,
                              row_number() over(PARTITION BY arp.id_analysis_result,
                                   arp.id_analysis_parameter ORDER BY arp.dt_ins_result_tstz DESC),
                              row_number() over(PARTITION BY ar.id_harvest,
                                   arp.id_analysis_req_par ORDER BY arp.dt_ins_result_tstz DESC)) rn
                        FROM TABLE(l_tbl_analysis_result) ar
                       INNER JOIN analysis_result_par arp
                          ON arp.id_analysis_result = ar.id_analysis_result
                       INNER JOIN exam_cat ec
                          ON ec.id_exam_cat = ar.id_exam_cat
                         AND ec.flg_lab = 'Y'
                       WHERE (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, ar.id_analysis)
                                FROM dual) = pk_alert_constant.g_yes
                         AND arp.id_analysis_result = ar.id_analysis_result) ar
               WHERE ar.rn = 1)
            SELECT id_analysis,
                   lab_test_desc,
                   id_analysis_parameter,
                   element_desc,
                   cat_id,
                   cat_desc,
                   id_content,
                   flg_has_parent,
                   flg_has_children,
                   rank_lab_test,
                   rank_lab_test_param,
                   rank_exam_cat
              FROM (SELECT ar.id_analysis,
                           pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     pk_lab_tests_constant.g_analysis_alias,
                                                                     'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ar.id_sample_type,
                                                                     NULL) lab_test_desc,
                           decode(ar.id_analysis_parameter,
                                  0,
                                  NULL,
                                  to_number(ar.id_analysis_parameter || ar.id_sample_type)) id_analysis_parameter,
                           decode(ar.flg_has_parent,
                                  pk_lab_tests_constant.g_no,
                                  pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                            i_prof,
                                                                            pk_lab_tests_constant.g_analysis_alias,
                                                                            'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                            ar.id_sample_type,
                                                                            NULL),
                                  pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                            i_prof,
                                                                            pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                            'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                            ar.id_analysis_parameter,
                                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                            ar.id_sample_type,
                                                                            NULL)) element_desc,
                           CASE
                                WHEN ar.parent_id IS NOT NULL THEN
                                 ar.parent_id
                                ELSE
                                 ar.id_exam_cat
                            END cat_id,
                           CASE
                                WHEN ar.parent_id IS NOT NULL THEN
                                 pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ar.parent_id)
                                ELSE
                                 pk_translation.get_translation(i_lang, ar.code_exam_cat)
                            END cat_desc,
                           CASE
                                WHEN ar.parent_id IS NOT NULL THEN
                                 pk_lab_tests_utils.get_lab_test_cat_id_content(i_lang, i_prof, ar.parent_id)
                                ELSE
                                 ar.id_content
                            END id_content,
                           ar.flg_has_parent,
                           ar.flg_has_children,
                           pk_lab_tests_utils.get_lab_test_rank(i_lang, i_prof, ar.id_analysis, NULL) rank_lab_test,
                           pk_lab_tests_utils.get_lab_test_parameter_rank(i_lang,
                                                                          i_prof,
                                                                          ar.id_analysis,
                                                                          ar.id_sample_type,
                                                                          ar.id_analysis_parameter) rank_lab_test_param,
                           ar.rank rank_exam_cat,
                           decode(ar.id_analysis_parameter, 0, 'A', 'P') flg_type
                      FROM (
                            -- Get lab tests with more than one parameter
                            SELECT DISTINCT ltd.id_analysis,
                                             ltd.id_sample_type,
                                             0                           id_analysis_parameter,
                                             pk_lab_tests_constant.g_no  flg_has_parent,
                                             pk_lab_tests_constant.g_yes flg_has_children,
                                             ltd.id_exam_cat,
                                             ltd.code_exam_cat,
                                             ltd.id_content,
                                             ltd.parent_id,
                                             ltd.rank
                              FROM (SELECT ltd.*,
                                            COUNT(ltd.id_analysis_parameter) over(PARTITION BY ltd.id_analysis, ltd.id_sample_type) ap_count
                                       FROM lab_tests_data ltd) ltd
                             WHERE ltd.ap_count > 1
                            UNION
                            -- Get lab tests with ONE parameter
                            -- AND
                            -- Get parameters for lab tests with more than one parameter
                            SELECT DISTINCT ltd.id_analysis,
                                             ltd.id_sample_type,
                                             ltd.id_analysis_parameter,
                                             decode(ltd.ap_count,
                                                    0,
                                                    pk_lab_tests_constant.g_no,
                                                    1,
                                                    pk_lab_tests_constant.g_no,
                                                    pk_lab_tests_constant.g_yes) flg_has_parent,
                                             pk_lab_tests_constant.g_no flg_has_children,
                                             ltd.id_exam_cat,
                                             ltd.code_exam_cat,
                                             ltd.id_content,
                                             ltd.parent_id,
                                             ltd.rank
                              FROM (SELECT ltd.*,
                                            COUNT(ltd.id_analysis_parameter) over(PARTITION BY ltd.id_analysis, ltd.id_sample_type) ap_count
                                       FROM lab_tests_data ltd) ltd) ar)
             ORDER BY rank_exam_cat,
                      cat_desc,
                      rank_lab_test,
                      lab_test_desc,
                      flg_type,
                      rank_lab_test_param,
                      element_desc;
    
        --gets the first result, and the last three results 
        OPEN o_list_values FOR
            SELECT t.rank_order,
                   t.counter analysis_count,
                   t.analysis_category_desc,
                   t.id_patient,
                   t.id_analysis_result,
                   t.id_analysis_parameter,
                   t.harvest_date,
                   t.harvest_date_formated,
                   t.harvest_prof,
                   t.harvest_day,
                   t.harvest_hour,
                   t.result_professional,
                   t.dt_analysis_result_final,
                   t.id_analysis_result_par,
                   to_clob(t.analysis_result) desc_analysis_result,
                   t.id_unit_measure,
                   t.desc_unit_measure,
                   t.ref_val,
                   t.ref_val_min,
                   t.ref_val_max,
                   t.flg_abnorm,
                   t.abnorm,
                   t.abnorm_color,
                   t.desc_abnormality,
                   t.abbrev_lab,
                   t.desc_lab,
                   t.result_origin,
                   t.flg_param_notes,
                   t.prof_param_notes,
                   to_clob(t.param_notes) param_notes,
                   t.flg_result_notes,
                   to_clob(t.result_notes) result_notes,
                   t.prof_result_notes,
                   t.flg_cancel_notes,
                   t.cancel_notes,
                   t.prof_cancel_notes,
                   t.flg_interface_notes,
                   to_clob(t.interface_notes) interface_notes,
                   t.id_content
              FROM (SELECT --counts the total number of results for a given parameter
                     COUNT(*) over(PARTITION BY aresp.id_analysis_parameter, aresp.id_sample_type) counter,
                     -- counts the rownumber for a given parameter
                     row_number() over(PARTITION BY aresp.id_analysis_parameter, aresp.id_sample_type ORDER BY nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz)) rank_order,
                     CASE
                          WHEN ec.parent_id IS NOT NULL THEN
                           pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ec.parent_id)
                          ELSE
                           pk_translation.get_translation(i_lang, ec.code_exam_cat)
                      END analysis_category_desc,
                     aresp.id_patient,
                     aresp.id_analysis_result,
                     decode(aresp.id_analysis_parameter,
                            0,
                            NULL,
                            to_number(aresp.id_analysis_parameter || aresp.id_sample_type)) id_analysis_parameter,
                     pk_date_utils.date_time_chr_tsz(i_lang, nvl(h.dt_harvest_tstz, aresp.dt_sample), i_prof) harvest_date,
                     pk_date_utils.date_send_tsz(i_lang, nvl(h.dt_harvest_tstz, aresp.dt_sample), i_prof) harvest_date_formated,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(h.id_prof_harvest, aresp.id_prof_result)) harvest_prof,
                     -- if there is no harvest, the harvest day is assumed to be register day. 
                     -- The harvest hour will read "Record" . Similiar behaviour happens
                     -- in the analysis timeline               
                     pk_date_utils.dt_chr_tsz(i_lang,
                                              nvl(h.dt_harvest_tstz, aresp.dt_sample),
                                              i_prof.institution,
                                              i_prof.software) harvest_day,
                     nvl(pk_date_utils.date_char_hour_tsz(i_lang, h.dt_harvest_tstz, i_prof.institution, i_prof.software),
                         pk_message.get_message(i_lang, 'COMMON_M052')) harvest_hour,
                     pk_prof_utils.get_name_signature(i_lang,
                                                      i_prof,
                                                      nvl(aresp.id_professional_upd, aresp.id_professional)) result_professional,
                     CASE
                          WHEN aresp.dt_analysis_result_par_tstz < aresp.dt_analysis_result_par_upd THEN
                           aresp.dt_analysis_result_par_upd
                          ELSE
                           aresp.dt_analysis_result_par_tstz
                      END dt_analysis_result_final,
                     aresp.id_analysis_result_par id_analysis_result_par,
                     nvl(TRIM(aresp.desc_analysis_result),
                         (aresp.comparator || aresp.analysis_result_value_1 || aresp.separator ||
                         aresp.analysis_result_value_2)) analysis_result,
                     CASE
                          WHEN aresp.id_unit_measure IS NULL THEN
                           pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                        i_prof,
                                                                        aresp.id_analysis,
                                                                        aresp.id_sample_type,
                                                                        aresp.id_analysis_parameter)
                          ELSE
                           aresp.id_unit_measure
                      END id_unit_measure,
                     CASE
                          WHEN nvl(aresp.desc_unit_measure,
                                   pk_translation.get_translation(i_lang,
                                                                  'UNIT_MEASURE.CODE_UNIT_MEASURE.' || aresp.id_unit_measure)) IS NULL THEN
                           pk_translation.get_translation(i_lang,
                                                          'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                          pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                                                       i_prof,
                                                                                                       aresp.id_analysis,
                                                                                                       aresp.id_sample_type,
                                                                                                       aresp.id_analysis_parameter))
                          ELSE
                           nvl(aresp.desc_unit_measure,
                               pk_translation.get_translation(i_lang,
                                                              'UNIT_MEASURE.CODE_UNIT_MEASURE.' || aresp.id_unit_measure))
                      END desc_unit_measure,
                     TRIM(nvl(aresp.ref_val,
                              decode((nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min) || ' - ' ||
                                     nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)),
                                     ' - ',
                                     ' ',
                                     nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min) || ' - ' ||
                                     nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)))) ref_val,
                     TRIM(nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min)) ref_val_min,
                     TRIM(nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)) ref_val_max,
                     CASE
                          WHEN pk_utils.is_number(aresp.desc_analysis_result) = pk_lab_tests_constant.g_yes
                               AND aresp.analysis_result_value_2 IS NULL THEN
                           CASE
                               WHEN aresp.analysis_result_value_1 < aresp.ref_val_min THEN
                                pk_lab_tests_constant.g_yes
                               WHEN aresp.analysis_result_value_1 > aresp.ref_val_max THEN
                                pk_lab_tests_constant.g_yes
                               ELSE
                                CASE
                                    WHEN aresp.id_abnormality IS NOT NULL THEN
                                     pk_lab_tests_constant.g_yes
                                    ELSE
                                     pk_lab_tests_constant.g_no
                                END
                           END
                          ELSE
                           NULL
                      END flg_abnorm,
                     (SELECT decode(abn.value, 'NA', 'PN', abn.value)
                        FROM abnormality abn
                       WHERE abn.id_abnormality = aresp.id_abnormality) abnorm,
                     (SELECT abn.color_code
                        FROM abnormality abn
                       WHERE abn.id_abnormality = aresp.id_abnormality) abnorm_color,
                     (SELECT pk_translation.get_translation(i_lang, abn.code_abnormality)
                        FROM abnormality abn
                       WHERE abn.id_abnormality = aresp.id_abnormality) desc_abnormality,
                     aresp.laboratory_short_desc abbrev_lab,
                     aresp.laboratory_desc desc_lab,
                     pk_sysdomain.get_domain('ANALYSIS_REQ.FLG_RESULT_ORIGIN', aresp.flg_result_origin, i_lang) result_origin,
                     decode(dbms_lob.getlength(aresp.parameter_notes),
                            NULL,
                            pk_lab_tests_constant.g_no,
                            pk_lab_tests_constant.g_yes) flg_param_notes,
                     decode(aresp.dt_cancel,
                            NULL,
                            pk_prof_utils.get_name_signature(i_lang,
                                                             i_prof,
                                                             nvl(aresp.id_professional_upd, aresp.id_professional)),
                            pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_professional_cancel)) prof_param_notes,
                     aresp.parameter_notes param_notes,
                     decode(dbms_lob.getlength(aresp.notes),
                            NULL,
                            pk_lab_tests_constant.g_no,
                            pk_lab_tests_constant.g_yes) flg_result_notes,
                     aresp.notes result_notes,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_prof_result) prof_result_notes,
                     decode(aresp.notes_cancel, '', pk_lab_tests_constant.g_no, pk_lab_tests_constant.g_yes) flg_cancel_notes,
                     aresp.notes_cancel cancel_notes,
                     aresp.id_professional_cancel prof_cancel_notes,
                     decode(dbms_lob.getlength(aresp.interface_notes),
                            NULL,
                            pk_lab_tests_constant.g_no,
                            pk_lab_tests_constant.g_yes) flg_interface_notes,
                     aresp.interface_notes interface_notes,
                     CASE
                          WHEN ec.parent_id IS NOT NULL THEN
                           pk_lab_tests_utils.get_lab_test_cat_id_content(i_lang, i_prof, ec.parent_id)
                          ELSE
                           ec.id_content
                      END id_content
                      FROM (SELECT DISTINCT t.id_analysis_req_par,
                                            t.id_analysis_result,
                                            t.id_analysis_req_det,
                                            t.id_analysis_parameter,
                                            t.id_patient,
                                            t.id_analysis,
                                            t.id_sample_type,
                                            t.id_exam_cat,
                                            t.dt_analysis_result_par_upd,
                                            t.dt_analysis_result_par_tstz,
                                            t.dt_sample,
                                            t.dt_cancel,
                                            t.id_prof_result,
                                            t.id_professional_upd,
                                            t.id_professional,
                                            t.id_analysis_result_par,
                                            t.desc_analysis_result,
                                            t.comparator,
                                            t.analysis_result_value_1,
                                            t.separator,
                                            t.analysis_result_value_2,
                                            t.id_unit_measure,
                                            t.desc_unit_measure,
                                            t.ref_val,
                                            t.ref_val_min_str,
                                            t.ref_val_min,
                                            t.ref_val_max_str,
                                            t.ref_val_max,
                                            t.id_abnormality,
                                            t.laboratory_short_desc,
                                            t.laboratory_desc,
                                            t.flg_result_origin,
                                            t.parameter_notes,
                                            t.id_professional_cancel,
                                            t.notes,
                                            t.notes_cancel,
                                            t.interface_notes
                              FROM (SELECT ar.id_analysis_result_par,
                                           ar.id_analysis_result,
                                           ar.id_analysis_req_par,
                                           ar.id_professional,
                                           ar.id_analysis_parameter,
                                           ar.ref_val,
                                           ar.id_unit_measure,
                                           ar.id_abnormality,
                                           ar.id_abnormality_nature,
                                           ar.id_prof_validation,
                                           ar.desc_unit_measure,
                                           ar.ref_val_min,
                                           ar.ref_val_max,
                                           ar.dt_analysis_result_par_tstz,
                                           ar.analysis_result_value_1,
                                           ar.analysis_result_value_2,
                                           ar.comparator,
                                           ar.separator,
                                           ar.laboratory_desc,
                                           ar.laboratory_short_desc,
                                           ar.id_professional_cancel,
                                           ar.id_cancel_reason,
                                           ar.dt_cancel,
                                           ar.notes_cancel,
                                           ar.dt_analysis_result_par_upd,
                                           ar.id_professional_upd,
                                           ar.ref_val_min_str,
                                           ar.ref_val_max_str,
                                           ar.id_prof_read,
                                           dbms_lob.substr(ar.desc_analysis_result, 32767, 1) desc_analysis_result,
                                           dbms_lob.substr(ar.interface_notes, 32767, 1) interface_notes,
                                           dbms_lob.substr(ar.parameter_notes, 32767, 1) parameter_notes,
                                           ar.id_analysis_desc,
                                           ar.id_patient,
                                           ar.id_analysis,
                                           ar.id_sample_type,
                                           ar.id_exam_cat,
                                           ar.id_analysis_req_det,
                                           ar.dt_analysis_result_tstz,
                                           ar.dt_sample,
                                           ar.id_prof_result,
                                           dbms_lob.substr(ar.notes, 32767, 1) notes,
                                           ar.flg_result_origin,
                                           ar.rn
                                      FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                             arp.*,
                                             ar.id_patient,
                                             ar.id_analysis,
                                             ar.id_sample_type,
                                             ar.id_exam_cat,
                                             ar.id_analysis_req_det,
                                             ar.dt_analysis_result_tstz,
                                             nvl(ar.dt_sample, ar.dt_analysis_result_tstz) dt_sample,
                                             ar.id_professional id_prof_result,
                                             ar.notes,
                                             ar.flg_result_origin,
                                             row_number() over(PARTITION BY ar.id_analysis, arp.id_analysis_parameter ORDER BY nvl(ar.dt_sample, ar.dt_analysis_result_tstz) ASC) rn
                                              FROM analysis_result_par arp
                                              JOIN TABLE(l_tbl_analysis_result) ar
                                                ON arp.id_analysis_result = ar.id_analysis_result
                                             WHERE ar.id_institution = i_prof.institution
                                               AND ((ar.flg_status = pk_lab_tests_constant.g_active OR
                                                   ar.flg_status IS NULL) AND arp.dt_cancel IS NULL)) ar
                                     WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                                        OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)
                                    UNION ALL
                                    SELECT ar.id_analysis_result_par,
                                           ar.id_analysis_result,
                                           ar.id_analysis_req_par,
                                           ar.id_professional,
                                           ar.id_analysis_parameter,
                                           ar.ref_val,
                                           ar.id_unit_measure,
                                           ar.id_abnormality,
                                           ar.id_abnormality_nature,
                                           ar.id_prof_validation,
                                           ar.desc_unit_measure,
                                           ar.ref_val_min,
                                           ar.ref_val_max,
                                           ar.dt_analysis_result_par_tstz,
                                           ar.analysis_result_value_1,
                                           ar.analysis_result_value_2,
                                           ar.comparator,
                                           ar.separator,
                                           ar.laboratory_desc,
                                           ar.laboratory_short_desc,
                                           ar.id_professional_cancel,
                                           ar.id_cancel_reason,
                                           ar.dt_cancel,
                                           ar.notes_cancel,
                                           ar.dt_analysis_result_par_upd,
                                           ar.id_professional_upd,
                                           ar.ref_val_min_str,
                                           ar.ref_val_max_str,
                                           ar.id_prof_read,
                                           dbms_lob.substr(ar.desc_analysis_result, 32767, 1) desc_analysis_result,
                                           dbms_lob.substr(ar.interface_notes, 32767, 1) interface_notes,
                                           dbms_lob.substr(ar.parameter_notes, 32767, 1) parameter_notes,
                                           ar.id_analysis_desc,
                                           ar.id_patient,
                                           ar.id_analysis,
                                           ar.id_sample_type,
                                           ar.id_exam_cat,
                                           ar.id_analysis_req_det,
                                           ar.dt_analysis_result_tstz,
                                           ar.dt_sample,
                                           ar.id_prof_result,
                                           dbms_lob.substr(ar.notes, 32767, 1) notes,
                                           ar.flg_result_origin,
                                           ar.rn
                                      FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                             arp.*,
                                             ar.id_patient,
                                             ar.id_analysis,
                                             ar.id_sample_type,
                                             ar.id_exam_cat,
                                             ar.id_analysis_req_det,
                                             ar.dt_analysis_result_tstz,
                                             nvl(ar.dt_sample, ar.dt_analysis_result_tstz) dt_sample,
                                             ar.id_professional id_prof_result,
                                             ar.notes,
                                             ar.flg_result_origin,
                                             row_number() over(PARTITION BY ar.id_analysis, arp.id_analysis_parameter ORDER BY nvl(ar.dt_sample, ar.dt_analysis_result_tstz) DESC) rn
                                              FROM analysis_result_par arp
                                              JOIN TABLE(l_tbl_analysis_result) ar
                                                ON arp.id_analysis_result = ar.id_analysis_result
                                             WHERE ar.id_institution = i_prof.institution
                                               AND ((ar.flg_status = pk_lab_tests_constant.g_active OR
                                                   ar.flg_status IS NULL) AND arp.dt_cancel IS NULL)) ar
                                     WHERE ar.rn BETWEEN 1 AND 3) t) aresp,
                           analysis_harvest ah,
                           harvest h,
                           exam_cat ec
                    --because results can be inserted without an associated harvest
                    -- join between analysis_harvest and analysis_req_par must be made by request_detail
                    -- otherwise no harvest results will be returned
                     WHERE aresp.id_analysis_req_det = ah.id_analysis_req_det(+)
                       AND ah.id_harvest = h.id_harvest(+)
                       AND aresp.id_exam_cat = ec.id_exam_cat
                       AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                           i_crit_type IS NOT NULL AND nvl(h.dt_harvest_tstz, aresp.dt_sample) >=
                           nvl(l_start_date, nvl(h.dt_harvest_tstz, aresp.dt_sample))) AND
                           (nvl(h.dt_harvest_tstz, aresp.dt_sample) <=
                           nvl(l_end_date, nvl(h.dt_harvest_tstz, aresp.dt_sample)) OR i_crit_type IS NULL))
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, aresp.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                     i_prof,
                                                                                     aresp.id_analysis,
                                                                                     pk_lab_tests_constant.g_infectious_diseases_results)
                              FROM dual) = pk_alert_constant.g_yes) t
            --ensures only the first inserted result and the three most recent results are displayed
            --edited values are also being taken into account, since an updated value, replaces an old
            --inserted value          
             WHERE (t.rank_order = 1 OR t.counter - 3 < t.rank_order);
    
        OPEN o_list_minmax_values FOR
        --filters the inner query for the most recent min result registred
            SELECT t_min.rank_order,
                   'Min' columm_type,
                   t_min.id_patient,
                   t_min.id_analysis_result,
                   t_min.id_analysis_parameter,
                   t_min.harvest_date,
                   t_min.harvest_date_formated,
                   t_min.harvest_day,
                   t_min.harvest_hour,
                   t_min.harvest_prof,
                   t_min.result_professional,
                   t_min.dt_analysis_result_final,
                   t_min.id_analysis_result_par,
                   t_min.analysis_result,
                   t_min.id_unit_measure,
                   t_min.desc_unit_measure,
                   t_min.flg_abnorm,
                   t_min.abnorm,
                   t_min.abnorm_color,
                   t_min.desc_abnormality,
                   t_min.abbrev_lab,
                   t_min.desc_lab,
                   t_min.result_origin,
                   t_min.flg_param_notes,
                   t_min.prof_param_notes,
                   t_min.param_notes,
                   t_min.flg_result_notes,
                   t_min.result_notes,
                   t_min.prof_result_notes,
                   t_min.flg_cancel_notes,
                   t_min.cancel_notes,
                   t_min.prof_cancel_notes,
                   t_min.flg_interface_notes,
                   t_min.interface_notes
              FROM ( --gathers info about the min results , and orders them by most recent min result registred
                    -- if more than one minimum is registred, returns only the most recent
                    SELECT row_number() over(PARTITION BY aresp.id_analysis_parameter ORDER BY aresp.id_analysis_parameter, aresp.dt_analysis_result_tstz DESC) rank_order,
                            aresp.id_patient,
                            aresp.id_analysis_result,
                            decode(aresp.id_analysis_parameter,
                                   0,
                                   NULL,
                                   to_number(aresp.id_analysis_parameter || aresp.id_sample_type)) id_analysis_parameter,
                            pk_date_utils.date_time_chr_tsz(i_lang, h.dt_harvest_tstz, i_prof) harvest_date,
                            pk_date_utils.date_send_tsz(i_lang, h.dt_harvest_tstz, i_prof) harvest_date_formated,
                            pk_date_utils.dt_chr_tsz(i_lang,
                                                     nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz),
                                                     i_prof.institution,
                                                     i_prof.software) harvest_day,
                            nvl(pk_date_utils.date_char_hour_tsz(i_lang,
                                                                 h.dt_harvest_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software),
                                pk_message.get_message(i_lang, 'COMMON_M052')) harvest_hour,
                            
                            pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_harvest) harvest_prof,
                            pk_prof_utils.get_name_signature(i_lang,
                                                             i_prof,
                                                             nvl(aresp.id_professional_upd, aresp.id_professional)) result_professional,
                            CASE
                                 WHEN aresp.dt_analysis_result_par_tstz < aresp.dt_analysis_result_par_upd THEN
                                  aresp.dt_analysis_result_par_upd
                                 ELSE
                                  aresp.dt_analysis_result_par_tstz
                             END dt_analysis_result_final,
                            aresp.id_analysis_result_par id_analysis_result_par,
                            decode(pk_utils.is_number(aresp.desc_analysis_result),
                                   pk_lab_tests_constant.g_no,
                                   TRIM(REPLACE(aresp.analysis_result_value, '.', ',')),
                                   aresp.desc_analysis_result) analysis_result,
                            CASE
                                 WHEN aresp.id_unit_measure IS NULL THEN
                                  pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                               i_prof,
                                                                               aresp.id_analysis,
                                                                               aresp.id_sample_type,
                                                                               aresp.id_analysis_parameter)
                                 ELSE
                                  aresp.id_unit_measure
                             END id_unit_measure,
                            CASE
                                 WHEN nvl(aresp.desc_unit_measure,
                                          pk_translation.get_translation(i_lang,
                                                                         'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                         aresp.id_unit_measure)) IS NULL THEN
                                  pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                 pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                                                              i_prof,
                                                                                                              aresp.id_analysis,
                                                                                                              aresp.id_sample_type,
                                                                                                              aresp.id_analysis_parameter))
                                 ELSE
                                  nvl(aresp.desc_unit_measure,
                                      pk_translation.get_translation(i_lang,
                                                                     'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                     aresp.id_unit_measure))
                             END desc_unit_measure,
                            CASE
                                 WHEN pk_utils.is_number(aresp.desc_analysis_result) = pk_lab_tests_constant.g_yes THEN
                                  CASE
                                      WHEN aresp.analysis_result_value < aresp.ref_val_min THEN
                                       pk_lab_tests_constant.g_yes
                                      WHEN aresp.analysis_result_value > aresp.ref_val_max THEN
                                       pk_lab_tests_constant.g_yes
                                      ELSE
                                       CASE
                                           WHEN aresp.id_abnormality IS NOT NULL THEN
                                            pk_lab_tests_constant.g_yes
                                           ELSE
                                            pk_lab_tests_constant.g_no
                                       END
                                  END
                                 ELSE
                                  NULL
                             END flg_abnorm,
                            (SELECT decode(abn.value, 'NA', 'PN', abn.value)
                               FROM abnormality abn
                              WHERE abn.id_abnormality = aresp.id_abnormality) abnorm,
                            (SELECT abn.color_code
                               FROM abnormality abn
                              WHERE abn.id_abnormality = aresp.id_abnormality) abnorm_color,
                            (SELECT pk_translation.get_translation(i_lang, abn.code_abnormality)
                               FROM abnormality abn
                              WHERE abn.id_abnormality = aresp.id_abnormality) desc_abnormality,
                            aresp.laboratory_short_desc abbrev_lab,
                            aresp.laboratory_desc desc_lab,
                            pk_sysdomain.get_domain('ANALYSIS_REQ.FLG_RESULT_ORIGIN', aresp.flg_result_origin, i_lang) result_origin,
                            decode(dbms_lob.getlength(aresp.parameter_notes),
                                   NULL,
                                   pk_lab_tests_constant.g_no,
                                   pk_lab_tests_constant.g_yes) flg_param_notes,
                            decode(aresp.dt_cancel,
                                   NULL,
                                   pk_prof_utils.get_name_signature(i_lang,
                                                                    i_prof,
                                                                    nvl(aresp.id_professional_upd, aresp.id_professional)),
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_professional_cancel)) prof_param_notes,
                            aresp.parameter_notes param_notes,
                            decode(dbms_lob.getlength(aresp.notes),
                                   NULL,
                                   pk_lab_tests_constant.g_no,
                                   pk_lab_tests_constant.g_yes) flg_result_notes,
                            aresp.notes result_notes,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_prof_result) prof_result_notes,
                            decode(aresp.notes_cancel, '', pk_lab_tests_constant.g_no, pk_lab_tests_constant.g_yes) flg_cancel_notes,
                            aresp.notes_cancel cancel_notes,
                            aresp.id_professional_cancel prof_cancel_notes,
                            decode(dbms_lob.getlength(aresp.interface_notes),
                                   NULL,
                                   pk_lab_tests_constant.g_no,
                                   pk_lab_tests_constant.g_yes) flg_interface_notes,
                            aresp.interface_notes interface_notes
                      FROM ( --returns the min result, registred for a given parameter
                             -- and excludes the cases when there is only one result.
                             -- when this happens there is no way to tell if a result
                             -- is a minimum or a maximum
                             SELECT MIN(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                   pk_lab_tests_constant.g_format_mask,
                                                   'NLS_NUMERIC_CHARACTERS='', ''')) min_value,
                                     arp.id_analysis_parameter
                               FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                       arp.*
                                        FROM analysis_result_par arp
                                        JOIN TABLE(l_tbl_analysis_result) ar
                                          ON arp.id_analysis_result = ar.id_analysis_result
                                       WHERE ar.id_institution = i_prof.institution
                                         AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                             arp.dt_cancel IS NULL)
                                         AND pk_utils.is_number(arp.desc_analysis_result) = pk_lab_tests_constant.g_yes) arp
                              GROUP BY arp.id_analysis_parameter
                             MINUS
                             SELECT MAX(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                   pk_lab_tests_constant.g_format_mask,
                                                   'NLS_NUMERIC_CHARACTERS='', ''')) min_value,
                                     arp.id_analysis_parameter
                               FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                       arp.*
                                        FROM analysis_result_par arp
                                        JOIN TABLE(l_tbl_analysis_result) ar
                                          ON arp.id_analysis_result = ar.id_analysis_result
                                       WHERE ar.id_institution = i_prof.institution
                                         AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                             arp.dt_cancel IS NULL)
                                         AND pk_utils.is_number(arp.desc_analysis_result) = pk_lab_tests_constant.g_yes) arp
                              GROUP BY arp.id_analysis_parameter) t,
                            (SELECT *
                               FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                      arp.*,
                                      ar.id_patient,
                                      ar.id_analysis,
                                      ar.id_sample_type,
                                      ar.id_analysis_req_det,
                                      ar.id_harvest,
                                      ar.dt_analysis_result_tstz,
                                      ar.dt_sample,
                                      ar.id_professional id_prof_result,
                                      ar.notes,
                                      ar.flg_result_origin,
                                      row_number() over(PARTITION BY ar.id_analysis, arp.id_analysis_parameter ORDER BY arp.analysis_result_value ASC) rn
                                       FROM analysis_result_par arp
                                       JOIN TABLE(l_tbl_analysis_result) ar
                                         ON arp.id_analysis_result = ar.id_analysis_result
                                      WHERE ar.id_institution = i_prof.institution
                                        AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                            arp.dt_cancel IS NULL)) ar
                              WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                                 OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)) aresp,
                            analysis_harvest ah,
                            harvest h
                     WHERE to_number(TRIM(REPLACE(decode(pk_utils.is_number(aresp.desc_analysis_result),
                                                         pk_lab_tests_constant.g_no,
                                                         TRIM(REPLACE(aresp.analysis_result_value, '.', ',')),
                                                         aresp.desc_analysis_result),
                                                  '.',
                                                  ',')),
                                     pk_lab_tests_constant.g_format_mask,
                                     'NLS_NUMERIC_CHARACTERS='', ''') = t.min_value
                       AND aresp.id_analysis_parameter = t.id_analysis_parameter
                          --because results can be inserted without an associated harvest
                          -- join between analysis_harvest and analysis_req_par must be made by request_detail
                          -- otherwise no harvest results will be returned
                       AND ah.id_analysis_req_det(+) = aresp.id_analysis_req_det
                       AND h.id_harvest(+) = ah.id_harvest
                       AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                            i_crit_type IS NOT NULL AND
                            nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz) >=
                            nvl(l_start_date, nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz))))
                       AND (nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz) <=
                            nvl(l_end_date, nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz)) OR
                            i_crit_type IS NULL)
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, aresp.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                     i_prof,
                                                                                     aresp.id_analysis,
                                                                                     pk_lab_tests_constant.g_infectious_diseases_results)
                              FROM dual) = pk_alert_constant.g_yes) t_min
             WHERE (t_min.rank_order = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)
            UNION ALL
            --union with the max value
            SELECT t_max.rank_order,
                   'Max' columm_type,
                   t_max.id_patient,
                   t_max.id_analysis_result,
                   t_max.id_analysis_parameter,
                   t_max.harvest_date,
                   t_max.harvest_date_formated,
                   t_max.harvest_day,
                   t_max.harvest_hour,
                   t_max.harvest_prof,
                   t_max.result_professional,
                   t_max.dt_analysis_result_final,
                   t_max.id_analysis_result_par,
                   t_max.analysis_result,
                   t_max.id_unit_measure,
                   t_max.desc_unit_measure,
                   t_max.flg_abnorm,
                   t_max.abnorm,
                   t_max.abnorm_color,
                   t_max.desc_abnormality,
                   t_max.abbrev_lab,
                   t_max.desc_lab,
                   t_max.result_origin,
                   t_max.flg_param_notes,
                   t_max.prof_param_notes,
                   t_max.param_notes,
                   t_max.flg_result_notes,
                   t_max.result_notes,
                   t_max.prof_result_notes,
                   t_max.flg_cancel_notes,
                   t_max.cancel_notes,
                   t_max.prof_cancel_notes,
                   t_max.flg_interface_notes,
                   t_max.interface_notes
              FROM ( --gathers info about the max results, and orders them by most recent max result registred
                    -- if more than one maximum is returned, uses only the most recent
                    SELECT row_number() over(PARTITION BY aresp.id_analysis_parameter ORDER BY aresp.id_analysis_parameter, aresp.dt_analysis_result_tstz DESC) rank_order,
                            aresp.id_patient,
                            aresp.id_analysis_result,
                            decode(aresp.id_analysis_parameter,
                                   0,
                                   NULL,
                                   to_number(aresp.id_analysis_parameter || aresp.id_sample_type)) id_analysis_parameter,
                            pk_date_utils.date_time_chr_tsz(i_lang, h.dt_harvest_tstz, i_prof) harvest_date,
                            pk_date_utils.date_send_tsz(i_lang, h.dt_harvest_tstz, i_prof) harvest_date_formated,
                            pk_date_utils.dt_chr_tsz(i_lang,
                                                     nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz),
                                                     i_prof.institution,
                                                     i_prof.software) harvest_day,
                            nvl(pk_date_utils.date_char_hour_tsz(i_lang,
                                                                 h.dt_harvest_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software),
                                pk_message.get_message(i_lang, 'COMMON_M052')) harvest_hour,
                            
                            pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_harvest) harvest_prof,
                            pk_prof_utils.get_name_signature(i_lang,
                                                             i_prof,
                                                             nvl(aresp.id_professional_upd, aresp.id_professional)) result_professional,
                            CASE
                                 WHEN aresp.dt_analysis_result_par_tstz < aresp.dt_analysis_result_par_upd THEN
                                  aresp.dt_analysis_result_par_upd
                                 ELSE
                                  aresp.dt_analysis_result_par_tstz
                             END dt_analysis_result_final,
                            aresp.id_analysis_result_par id_analysis_result_par,
                            decode(pk_utils.is_number(aresp.desc_analysis_result),
                                   pk_lab_tests_constant.g_no,
                                   TRIM(REPLACE(aresp.analysis_result_value, '.', ',')),
                                   aresp.desc_analysis_result) analysis_result,
                            CASE
                                 WHEN aresp.id_unit_measure IS NULL THEN
                                  pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                               i_prof,
                                                                               aresp.id_analysis,
                                                                               aresp.id_sample_type,
                                                                               aresp.id_analysis_parameter)
                                 ELSE
                                  aresp.id_unit_measure
                             END id_unit_measure,
                            CASE
                                 WHEN nvl(aresp.desc_unit_measure,
                                          pk_translation.get_translation(i_lang,
                                                                         'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                         aresp.id_unit_measure)) IS NULL THEN
                                  pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                 pk_lab_tests_utils.get_lab_test_unit_measure(i_lang,
                                                                                                              i_prof,
                                                                                                              aresp.id_analysis,
                                                                                                              aresp.id_sample_type,
                                                                                                              aresp.id_analysis_parameter))
                                 ELSE
                                  nvl(aresp.desc_unit_measure,
                                      pk_translation.get_translation(i_lang,
                                                                     'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                     aresp.id_unit_measure))
                             END desc_unit_measure,
                            CASE
                                 WHEN pk_utils.is_number(aresp.desc_analysis_result) = pk_lab_tests_constant.g_yes THEN
                                  CASE
                                      WHEN aresp.analysis_result_value < aresp.ref_val_min THEN
                                       pk_lab_tests_constant.g_yes
                                      WHEN aresp.analysis_result_value > aresp.ref_val_max THEN
                                       pk_lab_tests_constant.g_yes
                                      ELSE
                                       CASE
                                           WHEN aresp.id_abnormality IS NOT NULL THEN
                                            pk_lab_tests_constant.g_yes
                                           ELSE
                                            pk_lab_tests_constant.g_no
                                       END
                                  END
                                 ELSE
                                  NULL
                             END flg_abnorm,
                            (SELECT decode(abn.value, 'NA', 'PN', abn.value)
                               FROM abnormality abn
                              WHERE abn.id_abnormality = aresp.id_abnormality) abnorm,
                            (SELECT abn.color_code
                               FROM abnormality abn
                              WHERE abn.id_abnormality = aresp.id_abnormality) abnorm_color,
                            (SELECT pk_translation.get_translation(i_lang, abn.code_abnormality)
                               FROM abnormality abn
                              WHERE abn.id_abnormality = aresp.id_abnormality) desc_abnormality,
                            aresp.laboratory_short_desc abbrev_lab,
                            aresp.laboratory_desc desc_lab,
                            pk_sysdomain.get_domain('ANALYSIS_REQ.FLG_RESULT_ORIGIN', aresp.flg_result_origin, i_lang) result_origin,
                            decode(dbms_lob.getlength(aresp.parameter_notes),
                                   NULL,
                                   pk_lab_tests_constant.g_no,
                                   pk_lab_tests_constant.g_yes) flg_param_notes,
                            decode(aresp.dt_cancel,
                                   NULL,
                                   pk_prof_utils.get_name_signature(i_lang,
                                                                    i_prof,
                                                                    nvl(aresp.id_professional_upd, aresp.id_professional)),
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_professional_cancel)) prof_param_notes,
                            aresp.parameter_notes param_notes,
                            decode(dbms_lob.getlength(aresp.notes),
                                   NULL,
                                   pk_lab_tests_constant.g_no,
                                   pk_lab_tests_constant.g_yes) flg_result_notes,
                            aresp.notes result_notes,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, aresp.id_prof_result) prof_result_notes,
                            decode(aresp.notes_cancel, '', pk_lab_tests_constant.g_no, pk_lab_tests_constant.g_yes) flg_cancel_notes,
                            aresp.notes_cancel cancel_notes,
                            aresp.id_professional_cancel prof_cancel_notes,
                            decode(dbms_lob.getlength(aresp.interface_notes),
                                   NULL,
                                   pk_lab_tests_constant.g_no,
                                   pk_lab_tests_constant.g_yes) flg_interface_notes,
                            aresp.interface_notes interface_notes
                      FROM ( --returns the max result, registred for a given parameter
                             -- and excludes the cases when there is only one result.
                             -- when this happens there is no way to tell if a result
                             -- is a minimum or a maximum
                             SELECT MAX(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                   pk_lab_tests_constant.g_format_mask,
                                                   'NLS_NUMERIC_CHARACTERS='', ''')) max_value,
                                     arp.id_analysis_parameter
                               FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                       arp.*
                                        FROM analysis_result_par arp
                                        JOIN TABLE(l_tbl_analysis_result) ar
                                          ON arp.id_analysis_result = ar.id_analysis_result
                                       WHERE ar.id_institution = i_prof.institution
                                         AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                             arp.dt_cancel IS NULL)
                                         AND pk_utils.is_number(arp.desc_analysis_result) = pk_lab_tests_constant.g_yes) arp
                              GROUP BY arp.id_analysis_parameter
                             MINUS
                             SELECT MIN(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                   pk_lab_tests_constant.g_format_mask,
                                                   'NLS_NUMERIC_CHARACTERS='', ''')) max_value,
                                     arp.id_analysis_parameter
                               FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                       arp.*
                                        FROM analysis_result_par arp
                                        JOIN TABLE(l_tbl_analysis_result) ar
                                          ON arp.id_analysis_result = ar.id_analysis_result
                                       WHERE ar.id_institution = i_prof.institution
                                         AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                             arp.dt_cancel IS NULL)
                                         AND pk_utils.is_number(arp.desc_analysis_result) = pk_lab_tests_constant.g_yes) arp
                              GROUP BY arp.id_analysis_parameter) t,
                            (SELECT *
                               FROM (SELECT /*+ opt_estimate(table ar rows=1) */
                                      arp.*,
                                      ar.id_patient,
                                      ar.id_analysis,
                                      ar.id_sample_type,
                                      ar.id_analysis_req_det,
                                      ar.id_harvest,
                                      ar.dt_analysis_result_tstz,
                                      ar.dt_sample,
                                      ar.id_professional id_prof_result,
                                      ar.notes,
                                      ar.flg_result_origin,
                                      row_number() over(PARTITION BY ar.id_analysis, arp.id_analysis_parameter ORDER BY arp.analysis_result_value DESC) rn
                                       FROM analysis_result_par arp
                                       JOIN TABLE(l_tbl_analysis_result) ar
                                         ON arp.id_analysis_result = ar.id_analysis_result
                                      WHERE ar.id_institution = i_prof.institution
                                        AND ((ar.flg_status = pk_lab_tests_constant.g_active OR ar.flg_status IS NULL) AND
                                            arp.dt_cancel IS NULL)) ar
                              WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                                 OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)) aresp,
                            analysis_harvest ah,
                            harvest h
                     WHERE to_number(TRIM(REPLACE(decode(pk_utils.is_number(aresp.desc_analysis_result),
                                                         pk_lab_tests_constant.g_no,
                                                         TRIM(REPLACE(aresp.analysis_result_value, '.', ',')),
                                                         aresp.desc_analysis_result),
                                                  '.',
                                                  ',')),
                                     pk_lab_tests_constant.g_format_mask,
                                     'NLS_NUMERIC_CHARACTERS='', ''') = t.max_value
                       AND aresp.id_analysis_parameter = t.id_analysis_parameter
                          --because results can be inserted without an associated harvest
                          -- join between analysis_harvest and analysis_req_par must be made by request_detail
                          -- otherwise no harvest results will be returned
                       AND ah.id_analysis_req_det(+) = aresp.id_analysis_req_det
                       AND h.id_harvest(+) = ah.id_harvest
                       AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                            i_crit_type IS NOT NULL AND
                            nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz) >=
                            nvl(l_start_date, nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz))))
                       AND (nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz) <=
                            nvl(l_end_date, nvl(h.dt_harvest_tstz, aresp.dt_analysis_result_par_tstz)) OR
                            i_crit_type IS NULL)
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, aresp.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                     i_prof,
                                                                                     aresp.id_analysis,
                                                                                     pk_lab_tests_constant.g_infectious_diseases_results)
                              FROM dual) = pk_alert_constant.g_yes) t_max
             WHERE (t_max.rank_order = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                OR (l_lab_res_mult = pk_lab_tests_constant.g_yes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_TABLE2',
                                              o_error);
            pk_types.open_my_cursor(o_list_columns);
            pk_types.open_my_cursor(o_list_rows);
            pk_types.open_my_cursor(o_list_values);
            pk_types.open_my_cursor(o_list_minmax_values);
            RETURN FALSE;
    END get_reports_table2;

    FUNCTION get_reports_counter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_crit_type  IN VARCHAR2 DEFAULT 'A',
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        o_counter    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_lab_res_mult sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_MULTIPLE_RESULTS', i_prof);
    
    BEGIN
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_start_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'counting number of columns';
        SELECT nvl(MAX(col_number), 0)
          INTO o_counter
          FROM (SELECT ar.cat_id category_id, COUNT(ar.cat_id) col_number
                  FROM (SELECT DISTINCT cat_id,
                                        cat_desc,
                                        id_analysis_result_par id_analysis_result_par,
                                        dt_harvest             time_var,
                                        NULL                   dt_periodic_observation_reg,
                                        hour_read,
                                        short_dt_read,
                                        header_desc,
                                        date_target,
                                        hour_target,
                                        harvest_prof,
                                        revised_by,
                                        column_number
                          FROM (SELECT DISTINCT -- specific reports requirement. must show parent cat
                                                -- or child cat otherwise
                                                 CASE
                                                     WHEN ec.parent_id IS NOT NULL THEN
                                                      ec.parent_id
                                                     ELSE
                                                      ec.id_exam_cat
                                                 END cat_id,
                                                CASE
                                                     WHEN ec.parent_id IS NOT NULL THEN
                                                      pk_translation.get_translation(i_lang,
                                                                                     'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                                     ec.parent_id)
                                                     ELSE
                                                      pk_translation.get_translation(i_lang, ec.code_exam_cat)
                                                 END cat_desc,
                                                0 id_analysis_result_par,
                                                pk_date_utils.date_send_tsz(i_lang,
                                                                            nvl(por.dt_periodic_observation_reg,
                                                                                por.dt_result),
                                                                            i_prof) dt_harvest,
                                                NULL dt_sample,
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 nvl(por.dt_periodic_observation_reg,
                                                                                     por.dt_result),
                                                                                 i_prof.institution,
                                                                                 i_prof.software) hour_read,
                                                pk_date_utils.date_send_tsz(i_lang,
                                                                            nvl(por.dt_periodic_observation_reg,
                                                                                por.dt_result),
                                                                            i_prof) short_dt_read,
                                                pk_date_utils.get_year(i_lang,
                                                                       i_prof,
                                                                       nvl(por.dt_periodic_observation_reg, por.dt_result)) || '|' ||
                                                pk_date_utils.get_month_day(i_lang,
                                                                            i_prof,
                                                                            nvl(por.dt_periodic_observation_reg,
                                                                                por.dt_result)) || '|' ||
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 nvl(por.dt_periodic_observation_reg,
                                                                                     por.dt_result),
                                                                                 i_prof.institution,
                                                                                 i_prof.software) || '|' ||
                                                
                                                decode(por.flg_type_reg,
                                                       pk_lab_tests_constant.g_apf_type_history,
                                                       'M',
                                                       pk_lab_tests_constant.g_apf_type_maternal_health,
                                                       'M',
                                                       pk_periodic_observation.g_flg_type_reg,
                                                       'M',
                                                       'X') || '|' header_desc,
                                                pk_date_utils.dt_chr_tsz(i_lang,
                                                                         nvl(por.dt_periodic_observation_reg, por.dt_result),
                                                                         i_prof) date_target,
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 nvl(por.dt_periodic_observation_reg,
                                                                                     por.dt_result),
                                                                                 i_prof.institution,
                                                                                 i_prof.software) hour_target,
                                                pk_prof_utils.get_name_signature(i_lang,
                                                                                 i_prof,
                                                                                 nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 ar.id_harvest),
                                                                                     ar.id_professional)) harvest_prof,
                                                pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by) revised_by,
                                                1 column_number
                                  FROM periodic_observation_reg por, analysis_result ar, exam_cat ec, harvest h
                                 WHERE por.flg_type_reg IN
                                       (pk_periodic_observation.g_flg_type_reg,
                                        pk_lab_tests_constant.g_apf_type_history,
                                        pk_lab_tests_constant.g_apf_type_maternal_health)
                                   AND ((por.id_patient = i_patient AND i_patient IS NOT NULL) OR i_patient IS NULL)
                                   AND ((ar.id_episode_orig = i_episode AND i_episode IS NOT NULL) OR i_episode IS NULL)
                                   AND (((ar.id_visit = i_visit OR
                                       (ar.id_visit IS NULL AND EXISTS
                                        (SELECT 1
                                              FROM episode e
                                             WHERE e.id_visit = i_visit
                                               AND ar.id_episode_orig = e.id_episode))) AND i_visit IS NOT NULL) OR
                                       i_visit IS NULL)
                                      --situacao de criacao de nova coluna
                                   AND NOT EXISTS
                                 (SELECT 1
                                          FROM analysis_result ar
                                         WHERE ar.dt_sample = por.dt_periodic_observation_reg
                                           AND ar.id_patient = por.id_patient)
                                   AND por.flg_group = pk_periodic_observation.g_analysis
                                   AND por.id_analysis_result = ar.id_analysis_result
                                   AND ar.id_harvest = h.id_harvest(+)
                                   AND ar.id_exam_cat = ec.id_exam_cat
                                      -- only results
                                   AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                       i_crit_type IS NOT NULL AND
                                       nvl(por.dt_periodic_observation_reg, por.dt_result) >=
                                       nvl(l_start_date, nvl(por.dt_periodic_observation_reg, por.dt_result))) AND
                                       (nvl(por.dt_periodic_observation_reg, por.dt_result) <=
                                       nvl(l_end_date, nvl(por.dt_periodic_observation_reg, por.dt_result)) OR
                                       i_crit_type IS NULL))
                                UNION
                                -- Records without specimen collection (harvest)
                                -- thus label "Record" should be displayed
                                SELECT t.*,
                                       row_number() over(PARTITION BY t.dt_sample ORDER BY t.id_analysis_result_par) column_number
                                  FROM (SELECT DISTINCT CASE
                                                             WHEN ec.parent_id IS NOT NULL THEN
                                                              ec.parent_id
                                                             ELSE
                                                              ec.id_exam_cat
                                                         END cat_id,
                                                        CASE
                                                             WHEN ec.parent_id IS NOT NULL THEN
                                                              pk_translation.get_translation(i_lang,
                                                                                             'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                                             ec.parent_id)
                                                             ELSE
                                                              pk_translation.get_translation(i_lang, ec.code_exam_cat)
                                                         END cat_desc,
                                                        arp.id_analysis_result_par id_analysis_result_par,
                                                        pk_date_utils.date_send_tsz(i_lang,
                                                                                    nvl(ar.dt_sample,
                                                                                        ar.dt_analysis_result_tstz),
                                                                                    i_prof) dt_harvest,
                                                        pk_date_utils.date_send_tsz(i_lang,
                                                                                    nvl(ar.dt_sample,
                                                                                        ar.dt_analysis_result_tstz),
                                                                                    i_prof) dt_sample,
                                                        NULL hour_read,
                                                        pk_date_utils.date_send_tsz(i_lang,
                                                                                    nvl(ar.dt_sample,
                                                                                        ar.dt_analysis_result_tstz),
                                                                                    i_prof) short_dt_read,
                                                        pk_date_utils.get_year(i_lang,
                                                                               i_prof,
                                                                               nvl(ar.dt_sample, ar.dt_analysis_result_tstz)) || '|' ||
                                                        pk_date_utils.get_month_day(i_lang,
                                                                                    i_prof,
                                                                                    nvl(ar.dt_sample,
                                                                                        ar.dt_analysis_result_tstz)) || '|' ||
                                                        pk_message.get_message(i_lang, 'COMMON_M052') || '|' ||
                                                        decode(arp.id_analysis_req_par, NULL, 'M', 'Y') || '|' header_desc,
                                                        pk_date_utils.dt_chr_tsz(i_lang,
                                                                                 nvl(ar.dt_sample,
                                                                                     ar.dt_analysis_result_tstz),
                                                                                 i_prof) date_target,
                                                        pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                         nvl(ar.dt_sample,
                                                                                             ar.dt_analysis_result_tstz),
                                                                                         i_prof.institution,
                                                                                         i_prof.software) hour_target,
                                                        pk_prof_utils.get_name_signature(i_lang,
                                                                                         i_prof,
                                                                                         nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         ar.id_harvest),
                                                                                             ar.id_professional)) harvest_prof,
                                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by) revised_by
                                          FROM lab_tests_ea        lte,
                                               analysis_result_par arp,
                                               analysis_result     ar,
                                               exam_cat            ec,
                                               harvest             h
                                         WHERE ((ar.id_patient = i_patient AND i_patient IS NOT NULL) OR i_patient IS NULL)
                                           AND ((ar.id_episode_orig = i_episode AND i_episode IS NOT NULL) OR
                                               i_episode IS NULL)
                                           AND (((ar.id_visit = i_visit OR
                                               (ar.id_visit IS NULL AND EXISTS
                                                (SELECT 1
                                                      FROM episode e
                                                     WHERE e.id_visit = i_visit
                                                       AND ar.id_episode_orig = e.id_episode))) AND i_visit IS NOT NULL) OR
                                               i_visit IS NULL)
                                           AND ar.id_institution = i_prof.institution
                                           AND ar.id_harvest = h.id_harvest(+)
                                           AND ar.id_analysis_result = arp.id_analysis_result(+)
                                           AND lte.id_analysis_req_det(+) = ar.id_analysis_req_det
                                           AND (lte.flg_status_harvest = pk_lab_tests_constant.g_harvest_pending OR
                                               lte.flg_status_harvest IS NULL)
                                           AND lte.dt_harvest IS NULL
                                           AND ar.id_exam_cat = ec.id_exam_cat
                                              -- no collections
                                           AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                               i_crit_type IS NOT NULL AND
                                               nvl(ar.dt_sample, ar.dt_analysis_result_tstz) >=
                                               nvl(l_start_date, nvl(ar.dt_sample, ar.dt_analysis_result_tstz))) AND
                                               (nvl(ar.dt_sample, ar.dt_analysis_result_tstz) <=
                                               nvl(l_end_date, nvl(ar.dt_sample, ar.dt_analysis_result_tstz)) OR
                                               i_crit_type IS NULL))) t
                                UNION
                                -- Records with specimen collection (harvest)
                                SELECT DISTINCT -- specific reports requirement. must show parent cat
                                                -- or child cat otherwise
                                                 CASE
                                                     WHEN ec.parent_id IS NOT NULL THEN
                                                      ec.parent_id
                                                     ELSE
                                                      ec.id_exam_cat
                                                 END cat_id,
                                                CASE
                                                    WHEN ec.parent_id IS NOT NULL THEN
                                                     pk_translation.get_translation(i_lang,
                                                                                    'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                                    ec.parent_id)
                                                    ELSE
                                                     pk_translation.get_translation(i_lang, ec.code_exam_cat)
                                                END cat_desc,
                                                aresp.id_analysis_result_par id_analysis_result_par,
                                                pk_date_utils.date_send_tsz(i_lang,
                                                                            coalesce(lte.dt_harvest,
                                                                                     aresp.dt_sample,
                                                                                     aresp.dt_analysis_result_tstz),
                                                                            i_prof) dt_harvest,
                                                NULL dt_sample,
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 coalesce(lte.dt_harvest,
                                                                                          aresp.dt_sample,
                                                                                          aresp.dt_analysis_result_tstz),
                                                                                 i_prof.institution,
                                                                                 i_prof.software) hour_read,
                                                pk_date_utils.date_send_tsz(i_lang,
                                                                            coalesce(lte.dt_harvest,
                                                                                     aresp.dt_sample,
                                                                                     aresp.dt_analysis_result_tstz),
                                                                            i_prof) short_dt_read,
                                                pk_date_utils.get_year(i_lang,
                                                                       i_prof,
                                                                       coalesce(lte.dt_harvest,
                                                                                aresp.dt_sample,
                                                                                aresp.dt_analysis_result_tstz)) || '|' ||
                                                pk_date_utils.get_month_day(i_lang,
                                                                            i_prof,
                                                                            coalesce(lte.dt_harvest,
                                                                                     aresp.dt_sample,
                                                                                     aresp.dt_analysis_result_tstz)) || '|' ||
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 coalesce(lte.dt_harvest,
                                                                                          aresp.dt_sample,
                                                                                          aresp.dt_analysis_result_tstz),
                                                                                 i_prof.institution,
                                                                                 i_prof.software) || '|' ||
                                                decode(nvl(aresp.flg_intf_orig, lte.flg_time_harvest),
                                                       decode(aresp.flg_intf_orig,
                                                              NULL,
                                                              pk_lab_tests_constant.g_flg_time_r,
                                                              pk_lab_tests_constant.g_no),
                                                       'M',
                                                       'X') || '|' header_desc,
                                                pk_date_utils.dt_chr_tsz(i_lang,
                                                                         coalesce(lte.dt_harvest,
                                                                                  aresp.dt_sample,
                                                                                  aresp.dt_analysis_result_tstz),
                                                                         i_prof) date_target,
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 coalesce(lte.dt_harvest,
                                                                                          aresp.dt_sample,
                                                                                          aresp.dt_analysis_result_tstz),
                                                                                 i_prof.institution,
                                                                                 i_prof.software) hour_target,
                                                pk_prof_utils.get_name_signature(i_lang,
                                                                                 i_prof,
                                                                                 nvl(pk_lab_tests_utils.get_harvest_professional(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 lte.id_harvest),
                                                                                     aresp.id_prof_result)) harvest_prof,
                                                pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_revised_by) revised_by,
                                                
                                                1 column_number
                                  FROM (SELECT lte.*, h.dt_harvest_tstz, h.id_harvest, h.id_revised_by
                                          FROM lab_tests_ea lte, analysis_harvest ah, harvest h
                                         WHERE lte.id_patient = i_patient
                                           AND lte.id_analysis_req_det = ah.id_analysis_req_det
                                           AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                                           AND ah.id_harvest = h.id_harvest
                                           AND h.flg_status NOT IN
                                               (pk_lab_tests_constant.g_harvest_pending,
                                                pk_lab_tests_constant.g_harvest_waiting,
                                                pk_lab_tests_constant.g_harvest_cancel,
                                                pk_lab_tests_constant.g_harvest_suspended)) lte,
                                       (SELECT *
                                          FROM (SELECT arp.*,
                                                       ar.id_patient,
                                                       ar.id_analysis,
                                                       ar.id_analysis_req_det,
                                                       ar.id_harvest,
                                                       ar.dt_analysis_result_tstz,
                                                       ar.dt_sample,
                                                       ar.id_exam_cat,
                                                       ar.id_professional id_prof_result,
                                                       ar.notes,
                                                       ar.flg_result_origin,
                                                       decode(id_harvest,
                                                              NULL,
                                                              row_number()
                                                              over(PARTITION BY arp.id_analysis_result,
                                                                   id_analysis_req_par ORDER BY dt_ins_result_tstz DESC),
                                                              row_number()
                                                              over(PARTITION BY id_harvest,
                                                                   id_analysis_req_par ORDER BY dt_ins_result_tstz DESC)) rn
                                                  FROM analysis_result_par arp, analysis_result ar
                                                 WHERE arp.id_analysis_result = ar.id_analysis_result
                                                   AND ar.id_patient = i_patient
                                                   AND ((ar.id_episode_orig = i_episode AND i_episode IS NOT NULL) OR
                                                       i_episode IS NULL)
                                                   AND (((ar.id_visit = i_visit OR
                                                       (ar.id_visit IS NULL AND EXISTS
                                                        (SELECT 1
                                                              FROM episode e
                                                             WHERE e.id_visit = i_visit
                                                               AND ar.id_episode_orig = e.id_episode))) AND
                                                       i_visit IS NOT NULL) OR i_visit IS NULL)
                                                   AND ar.id_institution = i_prof.institution) ar
                                         WHERE (ar.rn = 1 AND l_lab_res_mult = pk_lab_tests_constant.g_no)
                                            OR (l_lab_res_mult = pk_lab_tests_constant.g_yes)) aresp,
                                       exam_cat ec
                                 WHERE lte.id_analysis_req_det = aresp.id_analysis_req_det
                                   AND lte.id_harvest = aresp.id_harvest
                                   AND aresp.id_exam_cat = ec.id_exam_cat
                                   AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                 i_prof,
                                                                                                 lte.id_analysis)
                                          FROM dual) = pk_alert_constant.g_yes
                                   AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                 i_prof,
                                                                                                 lte.id_analysis,
                                                                                                 pk_lab_tests_constant.g_infectious_diseases_results)
                                          FROM dual) = pk_alert_constant.g_yes
                                   AND ((i_crit_type IN (pk_reports.g_crit_type_e, pk_reports.g_crit_type_a) AND
                                       i_crit_type IS NOT NULL AND lte.dt_harvest >= nvl(l_start_date, lte.dt_harvest)) AND
                                       (lte.dt_harvest <= nvl(l_end_date, lte.dt_harvest) OR i_crit_type IS NULL)))) ar
                 GROUP BY cat_id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_COUNTER',
                                              o_error);
            RETURN FALSE;
    END get_reports_counter;

    FUNCTION get_lab_tests_orders
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_location          IN VARCHAR2,
        i_flg_reports           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list                  OUT pk_types.cursor_type,
        o_lt_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_list pk_types.cursor_type;
    
        l_tbl_lab_tests_order t_tbl_lab_test_order;
        l_tbl_req_hash        t_tbl_analysis_req_hash;
        l_tbl_req_groups      t_tbl_analysis_req_hash;
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE e.id_episode = i_episode
               AND v.id_visit = e.id_visit;
    
        l_visit c_visit%ROWTYPE;
    
        l_status sys_config.value%TYPE;
    
        l_sql VARCHAR2(4000);
    
        l_flg_report VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        l_group_criteria sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        IF i_flg_location = 'I'
        THEN
            l_status := pk_sysconfig.get_config('REPORT_LAB_TESTS_STATUS_INT', i_prof);
        
            l_sql := 'SELECT ard.id_analysis_req, ard.id_analysis_req_det, ard.flg_time_harvest, NULL id_req_group ' || --
                     ' FROM analysis_req ar, analysis_req_det ard, episode e ' || --
                     ' WHERE e.id_visit = ' || l_visit.id_visit || --
                     ' AND (ar.id_episode = e.id_episode OR ard.id_episode_origin = e.id_episode) ' || --
                     ' AND ard.flg_time_harvest != ''' || pk_lab_tests_constant.g_flg_time_r || '''' || --
                     ' AND ard.flg_status IN (' || l_status || ') ' || --
                     ' AND (ard.id_exec_institution IS NULL OR ard.id_exec_institution = ' || i_prof.institution || ')' || --
                     ' AND ard.id_analysis_req = ar.id_analysis_req';
        ELSE
            l_status := pk_sysconfig.get_config('REPORT_LAB_TESTS_STATUS_EXT', i_prof);
        
            l_sql := 'SELECT ard.id_analysis_req, ard.id_analysis_req_det, ard.flg_time_harvest, NULL id_req_group ' || --
                     ' FROM analysis_req ar, analysis_req_det ard, episode e ' || --
                     ' WHERE e.id_visit = ' || l_visit.id_visit || --
                     ' AND (ar.id_episode = e.id_episode OR ard.id_episode_origin = e.id_episode) ' || --
                     ' AND ard.flg_time_harvest != ''' || pk_lab_tests_constant.g_flg_time_r || '''' || --
                     ' AND ard.flg_status IN (' || l_status || ') ' || --
                     ' AND (ard.id_exec_institution IS NOT NULL AND ard.id_exec_institution != ' || i_prof.institution || ')' || --
                     ' AND ard.id_analysis_req = ar.id_analysis_req';
        END IF;
    
        g_error := 'OPEN O_LIST';
        IF i_flg_reports = pk_alert_constant.g_no
        THEN
            OPEN o_list FOR l_sql;
        ELSE
        
            OPEN c_list FOR l_sql;
        
            FETCH c_list BULK COLLECT
                INTO l_tbl_lab_tests_order;
        
            l_group_criteria := pk_sysconfig.get_config('LAB_TEST_REP_AGGREGATION_CRITERIA', i_prof);
        
            SELECT t_analysis_req_hash(id_analysis_req           => id_analysis_req,
                                       id_analysis_req_det       => id_analysis_req_det,
                                       flg_time_harvest          => flg_time_harvest,
                                       id_analysis_group         => id_analysis_group,
                                       clinical_indication_hash  => clinical_indication_hash,
                                       instructions_hash         => instructions_hash,
                                       patient_instructions_hash => patient_instructions_hash,
                                       execution_hash            => execution_hash,
                                       health_plan_hash          => health_plan_hash,
                                       id_req_group              => NULL)
              BULK COLLECT
              INTO l_tbl_req_hash
              FROM (SELECT decode(instr(l_group_criteria, pk_lab_tests_constant.g_group_by_requisition),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  t.id_analysis_req) id_analysis_req,
                           t.id_analysis_req_det,
                           t.id_analysis_group,
                           t.flg_time_harvest,
                           decode(instr(l_group_criteria, pk_lab_tests_constant.g_group_by_clin_indication),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.diagnosis_notes || '|' || t.desc_diagnosis || '|' || t.clinical_purpose,
                                                'MD5')) clinical_indication_hash,
                           decode(instr(l_group_criteria, pk_lab_tests_constant.g_group_by_instructions),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.flg_urgency || '|' || t.flg_time_harvest || '|' || t.lab_time || '|' ||
                                                t.flg_prn || '|' || t.notes_prn || '|' || t.order_recurrence,
                                                'MD5')) instructions_hash,
                           decode(instr(l_group_criteria, pk_lab_tests_constant.g_group_by_patient_instructions),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.flg_fasting || '|' || t.notes_patient, 'MD5')) patient_instructions_hash,
                           decode(instr(l_group_criteria, pk_lab_tests_constant.g_group_by_execution_instructions),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.perform_location || '|' || t.notes_tech || '|' || t.notes, 'MD5')) execution_hash,
                           decode(instr(l_group_criteria, pk_lab_tests_constant.g_group_by_health_plan),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.id_pat_health_plan || '|' || t.id_pat_exemption, 'MD5')) health_plan_hash
                      FROM (SELECT ard.id_analysis_req,
                                   ard.id_analysis_req_det,
                                   ard.id_analysis_group,
                                   ard.diagnosis_notes,
                                   pk_diagnosis.concat_diag(i_lang, NULL, ard.id_analysis_req_det, NULL, i_prof) desc_diagnosis,
                                   decode(ard.id_clinical_purpose, 0, ard.clinical_purpose_notes, ard.id_clinical_purpose) clinical_purpose,
                                   ard.flg_urgency,
                                   ard.flg_time_harvest,
                                   decode(ard.dt_target_tstz,
                                          NULL,
                                          decode(ard.dt_schedule,
                                                 NULL,
                                                 NULL,
                                                 pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                       ard.dt_schedule,
                                                                                       i_prof.institution,
                                                                                       i_prof.software)),
                                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                ard.dt_target_tstz,
                                                                                i_prof.institution,
                                                                                i_prof.software)) lab_time,
                                   ard.flg_prn,
                                   to_char(ard.notes_prn) notes_prn,
                                   decode(ard.id_order_recurrence,
                                          NULL,
                                          NULL,
                                          (SELECT pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                                        i_prof,
                                                                                                        ard.id_order_recurrence)
                                             FROM dual)) order_recurrence,
                                   ard.flg_fasting,
                                   to_char(ard.notes_patient) notes_patient,
                                   to_char(ard.notes_scheduler) notes_scheduler,
                                   decode(ard.id_room,
                                          NULL,
                                          decode(ard.flg_col_inst, NULL, NULL, ard.flg_col_inst),
                                          nvl((SELECT r.desc_room
                                                FROM room r
                                               WHERE r.id_room = ard.id_room),
                                              ard.id_room)) collection_location,
                                   decode(ard.id_exec_institution,
                                          NULL,
                                          decode(ard.id_room_req,
                                                 NULL,
                                                 NULL,
                                                 nvl((SELECT r.desc_room
                                                       FROM room r
                                                      WHERE r.id_room = ard.id_room_req),
                                                     ard.id_room_req)),
                                          ard.id_exec_institution) perform_location,
                                   ard.notes_tech,
                                   to_char(ard.notes) notes,
                                   ard.id_pat_health_plan,
                                   ard.id_pat_exemption
                              FROM analysis_req_det ard
                             WHERE ard.id_analysis_req_det IN
                                   (SELECT t_req.id_analysis_req_det
                                      FROM TABLE(l_tbl_lab_tests_order) t_req)) t);
        
            SELECT t_analysis_req_hash(id_analysis_req           => tt.id_analysis_req,
                                       id_analysis_req_det       => NULL,
                                       flg_time_harvest          => NULL,
                                       id_analysis_group         => NULL,
                                       clinical_indication_hash  => tt.clinical_indication_hash,
                                       instructions_hash         => tt.instructions_hash,
                                       patient_instructions_hash => tt.patient_instructions_hash,
                                       execution_hash            => tt.execution_hash,
                                       health_plan_hash          => tt.health_plan_hash,
                                       id_req_group              => tt.rn)
              BULK COLLECT
              INTO l_tbl_req_groups
              FROM (SELECT t.*, rownum rn
                      FROM (SELECT t_req.id_analysis_req,
                                   t_req.clinical_indication_hash,
                                   t_req.instructions_hash,
                                   t_req.patient_instructions_hash,
                                   t_req.execution_hash,
                                   t_req.health_plan_hash
                              FROM TABLE(l_tbl_req_hash) t_req
                             GROUP BY t_req.id_analysis_req,
                                      t_req.clinical_indication_hash,
                                      t_req.instructions_hash,
                                      t_req.patient_instructions_hash,
                                      t_req.execution_hash,
                                      t_req.health_plan_hash) t) tt;
        
            OPEN o_list FOR
                SELECT coalesce(t_req.id_analysis_req,
                                (SELECT ard.id_analysis_req
                                   FROM analysis_req_det ard
                                  WHERE ard.id_analysis_req_det = t_req.id_analysis_req_det)) id_analysis_req,
                       t_req.id_analysis_req_det,
                       t_req.flg_time_harvest,
                       t_req.id_analysis_group,
                       --REMOVER (APENAS PARA DEBUG)
                       t_req.clinical_indication_hash,
                       t_req.instructions_hash,
                       t_req.patient_instructions_hash,
                       t_req.execution_hash,
                       t_req_groups.health_plan_hash,
                       --FIM REMOVER
                       t_req_groups.id_req_group
                  FROM TABLE(l_tbl_req_hash) t_req
                  LEFT JOIN TABLE(l_tbl_req_groups) t_req_groups
                    ON (t_req.id_analysis_req = t_req_groups.id_analysis_req OR t_req.id_analysis_req IS NULL)
                   AND (t_req.clinical_indication_hash = t_req_groups.clinical_indication_hash OR
                       t_req.clinical_indication_hash IS NULL)
                   AND (t_req.instructions_hash = t_req_groups.instructions_hash OR t_req.instructions_hash IS NULL)
                   AND (t_req.patient_instructions_hash = t_req_groups.patient_instructions_hash OR
                       t_req.patient_instructions_hash IS NULL)
                   AND (t_req.execution_hash = t_req_groups.execution_hash OR t_req.execution_hash IS NULL)
                   AND (t_req.health_plan_hash = t_req_groups.health_plan_hash OR t_req.health_plan_hash IS NULL)
                   AND l_group_criteria IS NOT NULL;
        END IF;
    
        OPEN o_lt_clinical_questions FOR
            SELECT id_analysis_req_det,
                   id_content,
                   flg_time,
                   decode(l_flg_report,
                          pk_lab_tests_constant.g_no,
                          decode(rownum, 1, pk_message.get_message(i_lang, 'LAB_TESTS_T228') || chr(10), NULL) || chr(9) ||
                          chr(32) || chr(32) || desc_clinical_question || desc_response,
                          desc_clinical_question) desc_clinical_question,
                   decode(l_flg_report, pk_lab_tests_constant.g_no, to_clob(''), to_clob(desc_response)) desc_response
              FROM (SELECT id_analysis_req_det, id_content, flg_time, desc_clinical_question, desc_response
                      FROM (SELECT DISTINCT aqr1.id_analysis_req_det,
                                            aqr1.id_content,
                                            aqr1.flg_time,
                                            decode(l_flg_report,
                                                   pk_lab_tests_constant.g_no,
                                                   '<b>' ||
                                                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                   i_prof,
                                                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                   aqr1.id_questionnaire) || ':</b> ',
                                                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                   i_prof,
                                                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                   aqr1.id_questionnaire)) desc_clinical_question,
                                            decode(aqr.notes,
                                                   NULL,
                                                   decode(aqr1.desc_response, NULL, '---', aqr1.desc_response),
                                                   pk_lab_tests_utils.get_lab_test_response(i_lang, i_prof, aqr.notes)) desc_response,
                                            pk_lab_tests_utils.get_lab_test_question_rank(i_lang,
                                                                                          i_prof,
                                                                                          ard.id_analysis,
                                                                                          ard.id_sample_type,
                                                                                          aqr1.id_questionnaire,
                                                                                          aqr1.flg_time) rank
                              FROM (SELECT aqr.id_analysis_req_det,
                                           aqr.id_questionnaire,
                                           listagg(pk_lab_tests_utils.get_questionnaire_id_content(i_lang,
                                                                                                   i_prof,
                                                                                                   aqr.id_questionnaire,
                                                                                                   aqr.id_response),
                                                   '; ') within GROUP(ORDER BY aqr.id_response) id_content,
                                           decode(aqr.id_harvest,
                                                  NULL,
                                                  pk_lab_tests_constant.g_analysis_cq_on_order,
                                                  pk_lab_tests_constant.g_analysis_cq_on_harvest) flg_time,
                                           listagg(pk_mcdt.get_response_alias(i_lang,
                                                                              i_prof,
                                                                              'RESPONSE.CODE_RESPONSE.' || aqr.id_response),
                                                   '; ') within GROUP(ORDER BY aqr.id_response) desc_response
                                      FROM analysis_question_response aqr
                                     WHERE aqr.id_episode = i_episode
                                     GROUP BY aqr.id_analysis_req_det, aqr.id_harvest, aqr.id_questionnaire) aqr1,
                                   (SELECT aqr.*,
                                           decode(aqr.id_harvest,
                                                  NULL,
                                                  pk_lab_tests_constant.g_analysis_cq_on_order,
                                                  pk_lab_tests_constant.g_analysis_cq_on_harvest) flg_time
                                      FROM analysis_question_response aqr) aqr,
                                   analysis_req_det ard
                             WHERE aqr.id_analysis_req_det = aqr1.id_analysis_req_det
                               AND aqr.id_questionnaire = aqr1.id_questionnaire
                               AND aqr.flg_time = aqr1.flg_time
                               AND aqr.id_analysis_req_det = ard.id_analysis_req_det)
                     ORDER BY flg_time, rank);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TESTS_ORDERS',
                                              o_error);
            RETURN FALSE;
    END get_lab_tests_orders;

    FUNCTION get_lab_test_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_co_sign OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_CO_SIGN';
        IF NOT pk_lab_tests_core.get_lab_test_co_sign(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_episode          => i_episode,
                                                      i_analysis_req_det => i_analysis_req_det,
                                                      i_flg_report       => i_flg_report,
                                                      o_lab_test_co_sign => o_lab_test_co_sign,
                                                      o_error            => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'GET_LAB_TEST_CO_SIGN',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_co_sign;

    FUNCTION get_lab_test_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
        l_lab_test_order              t_tbl_lab_tests_detail;
        l_lab_test_clinical_questions t_tbl_lab_tests_cq;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_core.get_lab_test_detail(i_lang                        => i_lang,
                                                     i_prof                        => i_prof,
                                                     i_episode                     => i_episode,
                                                     i_analysis_req_det            => i_analysis_req_det,
                                                     i_flg_report                  => i_flg_report,
                                                     o_lab_test_order              => l_lab_test_order,
                                                     o_lab_test_co_sign            => o_lab_test_co_sign,
                                                     o_lab_test_clinical_questions => l_lab_test_clinical_questions,
                                                     o_lab_test_harvest            => o_lab_test_harvest,
                                                     o_lab_test_result             => o_lab_test_result,
                                                     o_lab_test_doc                => o_lab_test_doc,
                                                     o_lab_test_review             => o_lab_test_review,
                                                     o_error                       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_LAB_TEST_ORDER';
        OPEN o_lab_test_order FOR
            SELECT t.id_analysis_req_det id_analysis_req_det,
                   t.registry registry,
                   lte.flg_status_det flg_status,
                   t.desc_analysis desc_analysis,
                   t.num_order num_order,
                   ard.barcode barcode,
                   lte.id_exam_cat id_category,
                   pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || lte.id_exam_cat) desc_category,
                   ecp.parent_id category_parent_id,
                   pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ecp.parent_id) desc_category_parent,
                   lte.id_prof_writes id_prof_order,
                   t.diagnosis_notes diagnosis_notes,
                   t.desc_diagnosis desc_diagnosis,
                   t.clinical_purpose clinical_purpose,
                   t.priority priority,
                   t.desc_status desc_status,
                   t.title_order_set title_order_set,
                   t.task_depend task_depend,
                   ar.flg_time,
                   t.desc_time desc_time,
                   t.desc_time_limit desc_time_limit,
                   t.order_recurrence order_recurrence,
                   t.prn prn,
                   t.notes_prn notes_prn,
                   t.fasting fasting,
                   t.notes_patient notes_patient,
                   CASE
                        WHEN ard.id_exec_institution IS NULL
                             OR ard.id_exec_institution = i_prof.institution THEN
                         'I'
                        ELSE
                         'E'
                    END flg_location,
                   t.perform_location perform_location,
                   t.notes_scheduler notes_scheduler,
                   t.notes_technician notes_technician,
                   t.notes notes,
                   t.prof_cc prof_cc,
                   t.prof_bcc prof_bcc,
                   hp.id_health_plan id_health_plan,
                   ard.id_pat_health_plan id_pat_health_plan,
                   t.financial_entity financial_entity,
                   t.health_plan health_plan,
                   t.insurance_number insurance_number,
                   t.exemption exemption,
                   t.order_type order_type,
                   t.prof_order prof_order,
                   t.dt_order dt_order,
                   t.cancel_reason cancel_reason,
                   t.cancel_notes cancel_notes,
                   t.cancel_order_type cancel_order_type,
                   t.cancel_prof_order cancel_prof_order,
                   t.cancel_dt_order cancel_dt_order,
                   t.dt_ord dt_ord,
                   t.co_sign_status,
                   CASE i_flg_report
                       WHEN pk_alert_constant.g_no THEN
                        NULL
                       ELSE
                        l_msg_reg || ' ' ||
                        pk_prof_utils.get_name_signature(i_lang,
                                                         i_prof,
                                                         coalesce(ard.id_prof_cancel,
                                                                  ard.id_prof_last_update,
                                                                  ar.id_prof_writes)) ||
                        decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                coalesce(ard.id_prof_cancel,
                                                                         ard.id_prof_last_update,
                                                                         ar.id_prof_writes),
                                                                coalesce(ard.dt_cancel_tstz,
                                                                         ard.dt_last_update_tstz,
                                                                         ar.dt_req_tstz),
                                                                ar.id_episode),
                               NULL,
                               '; ',
                               ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                        i_prof,
                                                                        coalesce(ard.id_prof_cancel,
                                                                                 ard.id_prof_last_update,
                                                                                 ar.id_prof_writes),
                                                                        coalesce(ard.dt_cancel_tstz,
                                                                                 ard.dt_last_update_tstz,
                                                                                 ar.dt_req_tstz),
                                                                        ar.id_episode) || '); ') ||
                        pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                              coalesce(ard.dt_cancel_tstz,
                                                                       ard.dt_last_update_tstz,
                                                                       ar.dt_req_tstz),
                                                              i_prof.institution,
                                                              i_prof.software)
                   END registry_reports
            
              FROM TABLE(l_lab_test_order) t
              JOIN lab_tests_ea lte
                ON lte.id_analysis_req_det = t.id_analysis_req_det
              JOIN analysis_req ar
                ON ar.id_analysis_req = lte.id_analysis_req
              JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = lte.id_analysis_req_det
              LEFT JOIN exam_cat ecp
                ON ecp.id_exam_cat = lte.id_exam_cat
              LEFT JOIN pat_health_plan php
                ON php.id_pat_health_plan = ard.id_pat_health_plan
              LEFT JOIN health_plan hp
                ON hp.id_health_plan = php.id_health_plan
             WHERE lte.id_analysis_req_det = i_analysis_req_det;
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT t.id_analysis_req_det    id_analysis_req_det,
                   t.id_content             id_content,
                   t.flg_time               flg_time,
                   t.desc_clinical_question desc_clinical_question,
                   t.desc_response          desc_response
              FROM TABLE(l_lab_test_clinical_questions) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_result);
            pk_types.open_my_cursor(o_lab_test_doc);
            pk_types.open_my_cursor(o_lab_test_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_detail;

    FUNCTION get_lab_test_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lab_test_order              t_tbl_lab_tests_detail;
        l_lab_test_clinical_questions t_tbl_lab_tests_cq;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_DETAIL_HISTORY';
        IF NOT pk_lab_tests_core.get_lab_test_detail_history(i_lang                        => i_lang,
                                                             i_prof                        => i_prof,
                                                             i_episode                     => i_episode,
                                                             i_analysis_req_det            => i_analysis_req_det,
                                                             i_flg_report                  => i_flg_report,
                                                             o_lab_test_order              => l_lab_test_order,
                                                             o_lab_test_co_sign            => o_lab_test_co_sign,
                                                             o_lab_test_clinical_questions => l_lab_test_clinical_questions,
                                                             o_lab_test_harvest            => o_lab_test_harvest,
                                                             o_lab_test_result             => o_lab_test_result,
                                                             o_lab_test_doc                => o_lab_test_doc,
                                                             o_lab_test_review             => o_lab_test_review,
                                                             o_error                       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_LAB_TEST_ORDER';
        OPEN o_lab_test_order FOR
            SELECT t.id_analysis_req_det id_analysis_req_det,
                   t.registry            registry,
                   t.desc_analysis       desc_analysis,
                   t.num_order           num_order,
                   t.diagnosis_notes     diagnosis_notes,
                   t.desc_diagnosis      desc_diagnosis,
                   t.clinical_purpose    clinical_purpose,
                   t.priority            priority,
                   t.desc_status         desc_status,
                   t.title_order_set     title_order_set,
                   t.task_depend         task_depend,
                   t.desc_time           desc_time,
                   t.desc_time_limit     desc_time_limit,
                   t.order_recurrence    order_recurrence,
                   t.prn                 prn,
                   t.notes_prn           notes_prn,
                   t.fasting             fasting,
                   t.notes_patient       notes_patient,
                   t.collection_location collection_location,
                   t.notes_scheduler     notes_scheduler,
                   t.perform_location    perform_location,
                   t.notes_technician    notes_technician,
                   t.notes               notes,
                   t.prof_cc             prof_cc,
                   t.prof_bcc            prof_bcc,
                   t.order_type          order_type,
                   t.prof_order          prof_order,
                   t.dt_order            dt_order,
                   t.financial_entity    financial_entity,
                   t.health_plan         health_plan,
                   t.insurance_number    insurance_number,
                   t.exemption           exemption,
                   t.cancel_reason       cancel_reason,
                   t.cancel_notes        cancel_notes,
                   t.cancel_order_type   cancel_order_type,
                   t.cancel_prof_order   cancel_prof_order,
                   t.cancel_dt_order     cancel_dt_order,
                   t.dt_ord              dt_ord
              FROM TABLE(l_lab_test_order) t;
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT t.id_analysis_req_det    id_analysis_req_det,
                   t.id_content             id_content,
                   t.flg_time               flg_time,
                   t.desc_clinical_question desc_clinical_question,
                   t.desc_response          desc_response
              FROM TABLE(l_lab_test_clinical_questions) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_result);
            pk_types.open_my_cursor(o_lab_test_doc);
            pk_types.open_my_cursor(o_lab_test_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_detail_history;

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN VARCHAR2 IS
    
        l_printer      VARCHAR2(4000 CHAR);
        l_barcode_type VARCHAR2(4000 CHAR);
        l_barcode      VARCHAR2(4000 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_BARCODE_FOR_PRINT';
        IF NOT pk_lab_tests_harvest_core.get_harvest_barcode_for_print(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_harvest           => table_number(i_harvest),
                                                                       o_printer           => l_printer,
                                                                       o_codification_type => l_barcode_type,
                                                                       o_barcode           => l_barcode,
                                                                       o_error             => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN l_barcode;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_barcode_for_print;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
    
        l_result t_rec_print_list_job := t_rec_print_list_job();
    
        l_print_list_area print_list_job.id_print_list_area%TYPE;
        l_count           NUMBER(24);
    
        l_analysis_req_det     CLOB := NULL;
        l_tbl_analysis_req_det table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'GETTING CONTEXT DATA AND AREA OF THIS PRINT LIST JOB';
        WITH t AS
         (SELECT v.context_data, v.id_print_list_area
            FROM v_print_list_context_data v
           WHERE v.id_print_list_job = i_id_print_list_job)
        SELECT id_print_list_area, context_data
          INTO l_print_list_area, l_analysis_req_det
          FROM t;
    
        --CHECK IF THE USER HAS PERMISSION TO SEE THE LAB TESTS
        l_tbl_analysis_req_det := pk_string_utils.str_split(i_list => l_analysis_req_det, i_delim => '|');
    
        SELECT COUNT(*)
          INTO l_count
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            column_value
                                             FROM TABLE(l_tbl_analysis_req_det) t)
           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                  FROM dual) = pk_alert_constant.g_yes;
        --    
        IF l_count > 0
        THEN
            l_result.id_print_list_job := i_id_print_list_job;
            l_result.title_desc        := pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T002');
        
            IF l_count = 1
            THEN
                l_result.subtitle_desc := l_count || ' ' ||
                                          lower(pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T115'));
            ELSE
                l_result.subtitle_desc := l_count || ' ' ||
                                          lower(pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T002'));
            END IF;
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_get_print_job_info;

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number IS
    
        l_result table_number := table_number();
    
    BEGIN
    
        g_error := 'GETTING SIMMILAR PRINTING LIST JOBS | PRINT_JOB_CONTEXT_DATA - ' || i_print_job_context_data;
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v.id_print_list_job
                  FROM v_print_list_context_data v
                  JOIN TABLE(CAST(i_tbl_print_list_jobs AS table_number)) t
                    ON t.column_value = v.id_print_list_job
                 WHERE dbms_lob.instr(v.context_data, i_print_job_context_data) > 0) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_compare_print_jobs;

    FUNCTION get_lab_test_in_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN print_list_job.context_data%TYPE IS
    
        l_context_data print_list_job.context_data%TYPE;
    
    BEGIN
    
        SELECT v.context_data
          INTO l_context_data
          FROM v_print_list_context_data v
         WHERE v.id_print_list_job = i_print_list_job;
    
        RETURN l_context_data;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_in_print_list;

    FUNCTION add_print_list_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_print_arguments  IN table_varchar,
        o_print_list_job   OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_context_data     table_clob;
        l_print_list_areas table_number;
    
    BEGIN
    
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
    
        l_context_data.extend;
        l_print_list_areas.extend;
    
        IF i_analysis_req_det IS NULL
           OR i_analysis_req_det.count = 0
        THEN
            g_error_code := 'REP_EXCEPTION_018';
            g_error      := pk_message.get_message(i_lang, 'REP_EXCEPTION_018');
            RAISE g_user_exception;
        END IF;
    
        SELECT table_clob(concatenate(ard.id_analysis_req_det || '|'))
          INTO l_context_data
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            *
                                             FROM TABLE(i_analysis_req_det) t);
    
        l_print_list_areas(1) := pk_print_list_db.g_print_list_area_lab_test;
    
        -- call function to add job to the print list
        g_error := 'CALL PK_PRINT_LIST_DB.ADD_PRINT_JOBS';
        IF NOT pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_episode          => i_episode,
                                               i_print_list_areas => l_print_list_areas,
                                               i_context_data     => l_context_data,
                                               i_print_arguments  => i_print_arguments,
                                               o_print_list_jobs  => o_print_list_job,
                                               o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error_code,
                                              g_error,
                                              '',
                                              g_package_owner,
                                              g_package_name,
                                              'ADD_PRINT_LIST_JOBS',
                                              'U',
                                              '',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ADD_PRINT_LIST_JOBS',
                                              o_error);
            RETURN FALSE;
    END add_print_list_jobs;

    FUNCTION get_lab_test_print_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_default_save sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_DEFAULT_COMPLETION_OPTION_SAVE',
                                                                        i_prof);
    
        l_can_add     VARCHAR2(1 CHAR);
        l_save_option sys_list.internal_name%TYPE;
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_LIST_DB.CHECK_FUNC_CAN_ADD';
        IF NOT pk_print_list_db.check_func_can_add(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   o_flg_can_add => l_can_add,
                                                   o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --gets printing list configurations
        IF l_default_save = pk_lab_tests_constant.g_no
        THEN
            g_error := 'CALL PK_PRINT_LIST_DB.GET_PRINT_LIST_DEF_OPTION';
            IF NOT pk_print_list_db.get_print_list_def_option(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_print_list_area => pk_print_list_db.g_print_list_area_lab_test,
                                                              o_default_option  => l_save_option,
                                                              o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            l_save_option := 'SAVE';
        END IF;
    
        g_error := 'OPEN O_OPTIONS';
        OPEN o_options FOR
            SELECT tbl_opt.flg_context val_option,
                   tbl_opt.desc_list desc_option,
                   decode(tbl_opt.sys_list_internal_name,
                          'SAVE',
                          NULL,
                          pk_print_tool.get_id_report(i_lang,
                                                      i_prof,
                                                      decode(tbl_opt.sys_list_internal_name, 'SAVE_PRINT_LIST', 'PL', 'P'),
                                                      'LabTestsOrdersList.swf')) id_report,
                   decode(tbl_opt.sys_list_internal_name,
                          l_save_option,
                          pk_lab_tests_constant.g_yes,
                          pk_lab_tests_constant.g_no) flg_default,
                   tbl_opt.rank rank,
                   decode(tbl_opt.sys_list_internal_name,
                          'SAVE_PRINT_LIST',
                          decode(l_can_add,
                                 pk_lab_tests_constant.g_yes,
                                 pk_lab_tests_constant.g_yes,
                                 pk_lab_tests_constant.g_no),
                          pk_lab_tests_constant.g_yes) flg_available
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, 'LAB_TESTS_COMPLETION_OPTIONS')) tbl_opt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_PRINT_LIST',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_print_list;

    FUNCTION tf_get_lab_test_to_print
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_varchar
    ) RETURN table_varchar IS
    
        l_status_int sys_config.value%TYPE := pk_sysconfig.get_config('REPORT_LAB_TESTS_STATUS_INT', i_prof);
        l_status_ext sys_config.value%TYPE := pk_sysconfig.get_config('REPORT_LAB_TESTS_STATUS_EXT', i_prof);
    
        l_sql   VARCHAR2(4000);
        l_count NUMBER;
    
    BEGIN
    
        g_error := 'GET COUNT';
        l_sql   := 'SELECT COUNT(*) ' || --
                   '  FROM (SELECT ard.id_analysis_req_det ' || --
                   '          FROM analysis_req_det ard ' || --
                   '         WHERE ard.id_analysis_req_det IN (SELECT t.column_value /*+opt_estimate (table t rows=1)*/ ' || --
                   '                                             FROM TABLE(:i_analysis_req_det) t) ' || --
                   '           AND ard.flg_status IN (' || l_status_int || ') ' || --
                   '           AND (ard.id_exec_institution IS NULL OR ard.id_exec_institution = ' ||
                   i_prof.institution || ')' || --
                   '        UNION ALL ' || --
                   '        SELECT ard.id_analysis_req_det ' || --
                   '          FROM analysis_req_det ard ' || --
                   '         WHERE ard.id_analysis_req_det IN (SELECT t.column_value /*+opt_estimate (table t rows=1)*/ ' || --
                   '                                             FROM TABLE(:i_analysis_req_det) t) ' || --
                   '           AND ard.flg_status IN (' || l_status_ext || ') ' || --
                   '           AND (ard.id_exec_institution IS NOT NULL OR ard.id_exec_institution != ' ||
                   i_prof.institution || ')) ';
    
        g_error := 'GET EXECUTE IMMEDIATE COUNT';
        EXECUTE IMMEDIATE l_sql
            INTO l_count
            USING i_analysis_req_det, i_analysis_req_det;
    
        IF l_count != i_analysis_req_det.count
        THEN
            RETURN table_varchar();
        ELSE
            RETURN i_analysis_req_det;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_get_lab_test_to_print;

    FUNCTION get_lab_tests_allowed
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_context IN CLOB
    ) RETURN NUMBER IS
    
        l_tbl_analysis_req_det table_varchar := table_varchar();
        l_count                NUMBER := 0;
    
    BEGIN
    
        --CHECK IF THE USER HAS PERMISSION TO SEE THE LAB TESTS
        l_tbl_analysis_req_det := pk_string_utils.str_split(i_list => i_context, i_delim => '|');
    
        SELECT COUNT(*)
          INTO l_count
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            column_value
                                             FROM TABLE(l_tbl_analysis_req_det) t)
           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                  FROM dual) = pk_alert_constant.g_yes;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_lab_tests_allowed;

    FUNCTION get_lab_test_infect_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_context IN CLOB
    ) RETURN VARCHAR2 IS
    
        l_tbl_analysis_req_det table_varchar := table_varchar();
        l_count                NUMBER := 0;
    
    BEGIN
    
        --CHECKS IF THERE ARE LABORATORIAL TESTS FOR INFECTIOUS DISEASES TO BE SHOWN ON THE PRINTING LIST
        --AND CHECKS IF THE USER HAS PERMISSION TO SEE THEM
        l_tbl_analysis_req_det := pk_string_utils.str_split(i_list => i_context, i_delim => '|');
    
        SELECT COUNT(*)
          INTO l_count
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            column_value
                                             FROM TABLE(l_tbl_analysis_req_det) t)
           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                  FROM dual) = pk_alert_constant.g_yes;
    
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_lab_test_infect_pl;

    PROCEDURE pdms_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_pdmsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        o_result_gridview  OUT pk_types.cursor_type,
        o_result_graphview OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_design_mode     sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_TABLE_DESIGN', i_prof);
        l_flg_info_button sys_config.value%TYPE := pk_info_button.get_show_info_button(i_lang,
                                                                                       i_prof,
                                                                                       pk_alert_constant.g_task_lab_tests);
    
        l_dt_min TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_max TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_list t_tbl_lab_tests_results;
    
    BEGIN
    
        l_dt_min := CASE
                        WHEN i_dt_min IS NOT NULL THEN
                         pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_dt_min || '000000', 'YYYYMMDDHH24MISSFF')
                        ELSE
                         NULL
                    END;
    
        l_dt_max := CASE
                        WHEN i_dt_max IS NOT NULL THEN
                         pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_dt_max || '999999', 'YYYYMMDDHH24MISSFF') +
                         INTERVAL '59' SECOND
                        ELSE
                         NULL
                    END;
    
        g_error := 'CALL GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_flg_type         => i_flg_type,
                                                          i_dt_min           => i_dt_min,
                                                          i_dt_max           => i_dt_max,
                                                          i_flg_report       => pk_lab_tests_constant.g_no,
                                                          o_list             => l_list,
                                                          o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_result_gridview FOR
            SELECT ar.*
              FROM TABLE(l_list) ar
             WHERE ((ar.id_visit = i_visit AND i_visit IS NOT NULL) OR i_visit IS NULL)
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      decode(i_flg_type, 'H', ar.dt_harvest_ord, ar.dt_result_ord) DESC,
                      decode(i_flg_type, 'H', ar.id_harvest, ar.id_analysis_result) DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        SELECT t_lab_tests_results(flg_type,
                                   id_analysis_req,
                                   id_analysis_req_det,
                                   id_ard_parent,
                                   id_analysis_req_par,
                                   id_analysis_result,
                                   id_analysis_result_par,
                                   id_arp_parent,
                                   id_analysis,
                                   id_analysis_parameter,
                                   id_sample_type,
                                   id_exam_cat,
                                   id_harvest,
                                   id_visit,
                                   id_episode,
                                   desc_analysis,
                                   desc_parameter,
                                   desc_sample,
                                   desc_category,
                                   partial_result,
                                   id_unit_measure,
                                   desc_unit_measure,
                                   prof_harvest,
                                   prof_spec_harvest,
                                   dt_harvest,
                                   dt_harvest_date,
                                   dt_harvest_hour,
                                   prof_result,
                                   prof_spec_result,
                                   dt_result,
                                   dt_result_date,
                                   dt_result_hour,
                                   RESULT,
                                   flg_multiple_result,
                                   flg_result_type,
                                   flg_status,
                                   flg_result_status,
                                   flg_relevant,
                                   result_status,
                                   result_range,
                                   result_color,
                                   ref_val,
                                   abnormality,
                                   desc_abnormality,
                                   prof_req,
                                   dt_req,
                                   result_notes,
                                   parameter_notes,
                                   desc_lab,
                                   desc_lab_notes,
                                   avail_button_create,
                                   avail_button_edit,
                                   avail_button_cancel,
                                   avail_button_read,
                                   avail_button_info,
                                   rank_analysis,
                                   rank_parameter,
                                   rank_category,
                                   dt_harvest_ord,
                                   dt_result_ord,
                                   rn)
          BULK COLLECT
          INTO l_list
          FROM (SELECT flg_type,
                       id_analysis_req,
                       table_number(id_analysis_req_det) id_analysis_req_det,
                       NULL id_ard_parent,
                       id_analysis_req_par,
                       id_analysis_result,
                       id_analysis_result_par,
                       NULL id_arp_parent,
                       id_analysis,
                       id_analysis_parameter,
                       id_sample_type,
                       id_exam_cat,
                       id_harvest,
                       id_visit,
                       id_episode,
                       desc_analysis,
                       desc_parameter,
                       desc_sample,
                       desc_category,
                       partial_result,
                       NULL id_unit_measure,
                       desc_unit_measure,
                       NULL prof_harvest,
                       NULL prof_spec_harvest,
                       dt_harvest,
                       NULL dt_harvest_date,
                       NULL dt_harvest_hour,
                       NULL prof_result,
                       NULL prof_spec_result,
                       dt_result,
                       NULL dt_result_date,
                       NULL dt_result_hour,
                       RESULT,
                       flg_multiple_result,
                       flg_result_type,
                       flg_status,
                       flg_result_status,
                       flg_relevant,
                       result_status,
                       result_range,
                       result_color,
                       ref_val,
                       NULL abnormality,
                       NULL desc_abnormality,
                       prof_req,
                       dt_req,
                       result_notes,
                       parameter_notes,
                       desc_lab,
                       desc_lab_notes,
                       avail_button_create,
                       avail_button_edit,
                       avail_button_cancel,
                       avail_button_read,
                       avail_button_info,
                       rank_analysis,
                       rank_parameter,
                       rank_category,
                       pk_date_utils.trunc_insttimezone_str(i_prof, dt_harvest_ord, 'MI') dt_harvest_ord,
                       pk_date_utils.trunc_insttimezone_str(i_prof, dt_result_ord, 'MI') dt_result_ord,
                       CASE
                        -- when different harvest for the same id_analysis_req_det (diferent recipients for the same lab_test)
                            WHEN COUNT(DISTINCT id_harvest)
                             over(PARTITION BY id_analysis_req_det, id_analysis, id_sample_type) > 1 THEN
                             decode(i_flg_type,
                                    'H',
                                    rank() over(PARTITION BY id_analysis_req,
                                         id_analysis,
                                         id_sample_type,
                                         id_harvest ORDER BY dt_harvest_ord DESC,
                                         id_harvest DESC NULLS FIRST),
                                    rank() over(PARTITION BY id_analysis_req,
                                         id_analysis,
                                         id_sample_type,
                                         id_harvest ORDER BY id_analysis_result DESC NULLS FIRST,
                                         id_analysis_result DESC NULLS FIRST))
                            ELSE
                             decode(i_flg_type,
                                    'H',
                                    rank() over(PARTITION BY id_analysis_req,
                                         id_analysis,
                                         id_sample_type ORDER BY dt_harvest_ord DESC,
                                         id_harvest DESC NULLS FIRST),
                                    rank() over(PARTITION BY id_analysis_req,
                                         id_analysis,
                                         id_sample_type ORDER BY dt_result_ord DESC,
                                         id_analysis_result DESC NULLS FIRST))
                        END rn
                  FROM (SELECT 'A' flg_type,
                               decode(lte.id_analysis_req, NULL, 0, lte.id_analysis_req) id_analysis_req,
                               lte.id_analysis_req_det,
                               NULL id_analysis_req_par,
                               ar.id_analysis_result,
                               NULL id_analysis_result_par,
                               ar.id_analysis,
                               NULL id_analysis_parameter,
                               ar.id_sample_type,
                               ar.id_exam_cat,
                               ar.id_harvest,
                               lte.id_visit,
                               lte.id_episode,
                               (SELECT pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                i_prof,
                                                                                pk_lab_tests_constant.g_analysis_alias,
                                                                                'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                ar.id_sample_type,
                                                                                NULL)
                                  FROM dual) desc_analysis,
                               NULL desc_parameter,
                               (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                 i_prof,
                                                                                 pk_lab_tests_constant.g_analysis_sample_alias,
                                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                 ar.id_sample_type,
                                                                                 NULL)
                                  FROM dual) desc_sample,
                               decode((SELECT pk_lab_tests_utils.get_lab_test_category(i_lang, i_prof, ar.id_exam_cat)
                                        FROM dual),
                                      NULL,
                                      NULL,
                                      (SELECT pk_translation.get_translation(i_lang,
                                                                             'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                             pk_lab_tests_utils.get_lab_test_category(i_lang,
                                                                                                                      i_prof,
                                                                                                                      ar.id_exam_cat))
                                         FROM dual) || ', ') ||
                               (SELECT pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ar.id_exam_cat)
                                  FROM dual) desc_category,
                               (SELECT pk_lab_tests_utils.get_lab_test_result_parameters(i_lang,
                                                                                         i_prof,
                                                                                         lte.id_analysis_req_det)
                                  FROM dual) partial_result,
                               NULL desc_unit_measure,
                               NULL ref_val,
                               NULL dt_harvest,
                               NULL dt_result,
                               NULL RESULT,
                               NULL flg_multiple_result,
                               NULL flg_result_type,
                               NULL flg_status,
                               NULL flg_result_status,
                               NULL flg_relevant,
                               NULL result_status,
                               NULL result_range,
                               NULL result_color,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) prof_req,
                               pk_date_utils.date_char_tsz(i_lang, lte.dt_req, i_prof.institution, i_prof.software) dt_req,
                               NULL result_notes,
                               NULL parameter_notes,
                               NULL desc_lab,
                               NULL desc_lab_notes,
                               NULL avail_button_create,
                               NULL avail_button_edit,
                               NULL avail_button_cancel,
                               NULL avail_button_read,
                               NULL avail_button_info,
                               (SELECT pk_lab_tests_utils.get_lab_test_rank(i_lang, i_prof, ar.id_analysis, NULL)
                                  FROM dual) rank_analysis,
                               NULL rank_parameter,
                               (SELECT pk_lab_tests_utils.get_lab_test_category_rank(i_lang, i_prof, ar.id_exam_cat)
                                  FROM dual) rank_category,
                               ar.dt_harvest_tstz dt_harvest_ord,
                               ar.dt_analysis_result_tstz dt_result_ord
                          FROM (SELECT *
                                  FROM (SELECT ar.*,
                                               h.dt_harvest_tstz,
                                               decode(ar.id_harvest,
                                                      NULL,
                                                      row_number() over(PARTITION BY ar.id_analysis_result ORDER BY
                                                           ar.dt_analysis_result_tstz DESC),
                                                      row_number()
                                                      over(PARTITION BY ar.id_analysis_req_det,
                                                           h.id_harvest_group ORDER BY h.dt_harvest_tstz DESC NULLS LAST)) rn
                                          FROM analysis_result ar, harvest h
                                         WHERE ar.id_patient = i_patient
                                           AND ((i_dt_min IS NULL AND i_dt_max IS NULL) OR
                                               ((h.dt_harvest_tstz BETWEEN l_dt_min AND l_dt_max AND i_flg_type = 'H') OR
                                               (ar.dt_analysis_result_tstz BETWEEN l_dt_min AND l_dt_max AND
                                               i_flg_type = 'R')))
                                           AND ar.id_harvest = h.id_harvest(+)
                                           AND ((h.flg_status NOT IN
                                               (pk_lab_tests_constant.g_harvest_pending,
                                                  pk_lab_tests_constant.g_harvest_waiting,
                                                  pk_lab_tests_constant.g_harvest_cancel,
                                                  pk_lab_tests_constant.g_harvest_suspended) AND i_flg_type = 'H') OR
                                               (i_flg_type = 'R'))
                                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                         i_prof,
                                                                                                         ar.id_analysis)
                                                  FROM dual) = pk_alert_constant.g_yes
                                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                         i_prof,
                                                                                                         ar.id_analysis,
                                                                                                         pk_lab_tests_constant.g_infectious_diseases_results)
                                                  FROM dual) = pk_alert_constant.g_yes)
                                 WHERE rn = 1) ar,
                               lab_tests_ea lte
                         WHERE ar.id_analysis_req_det = lte.id_analysis_req_det(+)
                        UNION ALL
                        SELECT 'P' flg_type,
                               decode(lte.id_analysis_req, NULL, 0, lte.id_analysis_req) id_analysis_req,
                               lte.id_analysis_req_det,
                               aresp.id_analysis_req_par,
                               aresp.id_analysis_result,
                               aresp.id_analysis_result_par,
                               aresp.id_analysis,
                               aresp.id_analysis_parameter,
                               aresp.id_sample_type,
                               aresp.id_exam_cat,
                               aresp.id_harvest,
                               lte.id_visit,
                               lte.id_episode,
                               (SELECT pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                i_prof,
                                                                                pk_lab_tests_constant.g_analysis_alias,
                                                                                'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                aresp.id_analysis,
                                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                aresp.id_sample_type,
                                                                                NULL)
                                  FROM dual) desc_analysis,
                               (SELECT pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                i_prof,
                                                                                pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                                'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                                aresp.id_analysis_parameter,
                                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                aresp.id_sample_type,
                                                                                NULL)
                                  FROM dual) desc_parameter,
                               (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                 i_prof,
                                                                                 pk_lab_tests_constant.g_analysis_sample_alias,
                                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                 aresp.id_sample_type,
                                                                                 NULL)
                                  FROM dual) desc_sample,
                               decode((SELECT pk_lab_tests_utils.get_lab_test_category(i_lang, i_prof, aresp.id_exam_cat)
                                        FROM dual),
                                      NULL,
                                      NULL,
                                      (SELECT pk_translation.get_translation(i_lang,
                                                                             'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                                             pk_lab_tests_utils.get_lab_test_category(i_lang,
                                                                                                                      i_prof,
                                                                                                                      aresp.id_exam_cat))
                                         FROM dual) || ', ') ||
                               (SELECT pk_translation.get_translation(i_lang,
                                                                      'EXAM_CAT.CODE_EXAM_CAT.' || aresp.id_exam_cat)
                                  FROM dual) desc_category,
                               NULL partial_result,
                               nvl(aresp.desc_unit_measure,
                                   (SELECT pk_translation.get_translation(i_lang,
                                                                          'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                          aresp.id_unit_measure)
                                      FROM dual)) desc_unit_measure,
                               nvl(aresp.ref_val,
                                   decode((nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min) || ' - ' ||
                                          nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max)),
                                          ' - ',
                                          NULL,
                                          nvl(TRIM(aresp.ref_val_min_str), aresp.ref_val_min) || ' - ' ||
                                          nvl(TRIM(aresp.ref_val_max_str), aresp.ref_val_max))) ref_val,
                               (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                   aresp.dt_harvest_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)
                                  FROM dual) dt_harvest,
                               (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                   aresp.dt_analysis_result_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)
                                  FROM dual) dt_result,
                               decode(l_design_mode,
                                      'D',
                                      decode(aresp.id_analysis_desc,
                                             NULL,
                                             decode(aresp.analysis_result_value_2,
                                                    NULL,
                                                    aresp.desc_analysis_result,
                                                    to_clob(aresp.comparator || aresp.analysis_result_value_1 ||
                                                            aresp.separator || aresp.analysis_result_value_2)),
                                             (SELECT decode(ad.icon,
                                                            NULL,
                                                            (SELECT pk_translation.get_translation(i_lang,
                                                                                                   ad.code_analysis_desc)
                                                               FROM dual),
                                                            ad.icon || '|' || (SELECT pk_translation.get_translation(i_lang,
                                                                                                                     ad.code_analysis_desc)
                                                                                 FROM dual))
                                                FROM analysis_desc ad
                                               WHERE ad.id_analysis_desc = aresp.id_analysis_desc)) ||
                                      decode(a.value, NULL, NULL, ' ' || a.value),
                                      decode(aresp.id_professional_cancel,
                                             NULL,
                                             decode(aresp.id_analysis_desc,
                                                    NULL,
                                                    decode(aresp.analysis_result_value_2,
                                                           NULL,
                                                           aresp.desc_analysis_result,
                                                           to_clob(aresp.comparator || aresp.analysis_result_value_1 ||
                                                                   aresp.separator || aresp.analysis_result_value_2)),
                                                    (SELECT decode(ad.icon,
                                                                   NULL,
                                                                   (SELECT pk_translation.get_translation(i_lang,
                                                                                                          ad.code_analysis_desc)
                                                                      FROM dual),
                                                                   ad.icon || '|' || (SELECT pk_translation.get_translation(i_lang,
                                                                                                                            ad.code_analysis_desc)
                                                                                        FROM dual))
                                                       FROM analysis_desc ad
                                                      WHERE ad.id_analysis_desc = aresp.id_analysis_desc)) ||
                                             decode(a.value, NULL, NULL, ' ' || a.value),
                                             'CancelIcon|' ||
                                             decode(aresp.id_analysis_desc,
                                                    NULL,
                                                    decode(aresp.analysis_result_value_2,
                                                           NULL,
                                                           aresp.desc_analysis_result,
                                                           to_clob(aresp.comparator || aresp.analysis_result_value_1 ||
                                                                   aresp.separator || aresp.analysis_result_value_2)),
                                                    (SELECT pk_translation.get_translation(i_lang,
                                                                                           'ANALYSIS_DESC.CODE_ANALYSIS_DESC.' ||
                                                                                           aresp.id_analysis_desc)
                                                       FROM dual) || decode(a.value, NULL, NULL, ' ' || a.value)))) RESULT,
                               aresp.flg_mult_result flg_multiple_result,
                               decode(l_design_mode,
                                      'D',
                                      decode(pk_utils.is_number(dbms_lob.substr(aresp.desc_analysis_result, 3800)),
                                             pk_lab_tests_constant.g_yes,
                                             pk_lab_tests_constant.g_analysis_result_number,
                                             decode(aresp.id_analysis_desc,
                                                    NULL,
                                                    pk_lab_tests_constant.g_analysis_result_text,
                                                    (SELECT decode(ad.icon,
                                                                   NULL,
                                                                   pk_lab_tests_constant.g_analysis_result_text,
                                                                   pk_lab_tests_constant.g_analysis_result_icon)
                                                       FROM analysis_desc ad
                                                      WHERE ad.id_analysis_desc = aresp.id_analysis_desc))),
                                      decode(aresp.id_professional_cancel,
                                             NULL,
                                             decode(pk_utils.is_number(dbms_lob.substr(aresp.desc_analysis_result, 3800)),
                                                    pk_lab_tests_constant.g_yes,
                                                    pk_lab_tests_constant.g_analysis_result_number,
                                                    decode(aresp.id_analysis_desc,
                                                           NULL,
                                                           pk_lab_tests_constant.g_analysis_result_text,
                                                           (SELECT decode(ad.icon,
                                                                          NULL,
                                                                          pk_lab_tests_constant.g_analysis_result_text,
                                                                          pk_lab_tests_constant.g_analysis_result_icon)
                                                              FROM analysis_desc ad
                                                             WHERE ad.id_analysis_desc = aresp.id_analysis_desc))),
                                             pk_lab_tests_constant.g_analysis_result_icon)) flg_result_type,
                               decode(aresp.id_professional_cancel,
                                      NULL,
                                      decode(lte.flg_status_det,
                                             pk_lab_tests_constant.g_analysis_result,
                                             NULL,
                                             pk_lab_tests_constant.g_analysis_read),
                                      pk_lab_tests_constant.g_analysis_cancel) flg_status,
                               decode(l_design_mode,
                                      'D',
                                      rs.value,
                                      decode(aresp.dt_analysis_result_par_upd,
                                             aresp.dt_analysis_result_par_tstz,
                                             decode(aresp.id_professional_cancel, NULL, rs.value, NULL),
                                             decode(aresp.id_professional_cancel, NULL, rs.value || 'E', NULL))) flg_result_status,
                               aresp.flg_relevant,
                               (SELECT pk_translation.get_translation(i_lang,
                                                                      'RESULT_STATUS.SHORT_CODE_RESULT_STATUS.' ||
                                                                      rs.id_result_status)
                                  FROM dual) result_status,
                               CASE
                                   WHEN pk_utils.is_number(dbms_lob.substr(aresp.desc_analysis_result, 3800)) =
                                        pk_lab_tests_constant.g_yes
                                        AND analysis_result_value_2 IS NULL THEN
                                    CASE
                                        WHEN aresp.analysis_result_value < aresp.ref_val_min THEN
                                         pk_lab_tests_constant.g_analysis_result_below
                                        WHEN aresp.analysis_result_value > aresp.ref_val_max THEN
                                         pk_lab_tests_constant.g_analysis_result_above
                                        ELSE
                                         NULL
                                    END
                                   ELSE
                                    NULL
                               END result_range,
                               CASE
                                   WHEN pk_utils.is_number(dbms_lob.substr(aresp.desc_analysis_result, 3800)) =
                                        pk_lab_tests_constant.g_yes
                                        AND analysis_result_value_2 IS NULL THEN
                                    CASE
                                        WHEN aresp.analysis_result_value < aresp.ref_val_min THEN
                                         '0xC3000A'
                                        WHEN aresp.analysis_result_value > aresp.ref_val_max THEN
                                         '0xC3000A'
                                        ELSE
                                         CASE
                                             WHEN aresp.id_abnormality IS NOT NULL THEN
                                              a.color_code
                                             ELSE
                                              NULL
                                         END
                                    END
                                   ELSE
                                    NULL
                               END result_color,
                               NULL prof_req,
                               NULL dt_req,
                               aresp.notes result_notes,
                               decode(dbms_lob.getlength(aresp.parameter_notes),
                                      NULL,
                                      decode(dbms_lob.getlength(aresp.interface_notes),
                                             NULL,
                                             to_clob(''),
                                             aresp.interface_notes),
                                      aresp.parameter_notes) parameter_notes,
                               aresp.laboratory_short_desc desc_lab,
                               aresp.laboratory_desc desc_lab_notes,
                               pk_lab_tests_constant.g_no avail_button_create,
                               pk_lab_tests_constant.g_no avail_button_edit,
                               pk_lab_tests_constant.g_no avail_button_cancel,
                               (SELECT pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                                  i_prof,
                                                                                  pk_lab_tests_constant.g_analysis_area_results,
                                                                                  pk_lab_tests_constant.g_analysis_button_read,
                                                                                  lte.id_episode,
                                                                                  NULL,
                                                                                  lte.id_analysis_req_det,
                                                                                  NULL)
                                  FROM dual) avail_button_read,
                               l_flg_info_button avail_button_info,
                               (SELECT pk_lab_tests_utils.get_lab_test_rank(i_lang, i_prof, aresp.id_analysis, NULL)
                                  FROM dual) rank_analysis,
                               (SELECT pk_lab_tests_utils.get_lab_test_parameter_rank(i_lang,
                                                                                      i_prof,
                                                                                      aresp.id_analysis,
                                                                                      aresp.id_sample_type,
                                                                                      aresp.id_analysis_parameter)
                                  FROM dual) rank_parameter,
                               (SELECT pk_lab_tests_utils.get_lab_test_category_rank(i_lang, i_prof, aresp.id_exam_cat)
                                  FROM dual) rank_category,
                               aresp.dt_harvest_tstz dt_harvest_ord,
                               aresp.dt_analysis_result_tstz dt_result_ord
                          FROM (SELECT *
                                  FROM (SELECT arp.*,
                                               ar.id_analysis_req_det,
                                               ar.id_analysis,
                                               ar.id_sample_type,
                                               ar.id_exam_cat,
                                               h.id_harvest,
                                               h.dt_harvest_tstz,
                                               ar.dt_analysis_result_tstz,
                                               ar.notes,
                                               ar.flg_mult_result,
                                               decode(ar.id_harvest,
                                                      NULL,
                                                      row_number()
                                                      over(PARTITION BY arp.id_analysis_result,
                                                           arp.id_analysis_parameter ORDER BY arp.dt_ins_result_tstz DESC),
                                                      row_number()
                                                      over(PARTITION BY ar.id_harvest,
                                                           arp.id_analysis_req_par ORDER BY arp.dt_ins_result_tstz DESC)) rn
                                          FROM analysis_result ar, analysis_result_par arp, harvest h
                                         WHERE ar.id_patient = i_patient
                                           AND ((i_dt_min IS NULL AND i_dt_max IS NULL) OR
                                               ((h.dt_harvest_tstz BETWEEN l_dt_min AND l_dt_max AND i_flg_type = 'H') OR
                                               (ar.dt_analysis_result_tstz BETWEEN l_dt_min AND l_dt_max AND
                                               i_flg_type = 'R')))
                                           AND arp.id_analysis_result = ar.id_analysis_result
                                           AND coalesce(to_char(dbms_lob.substr(arp.desc_analysis_result, 3800)),
                                                        to_char(arp.analysis_result_value),
                                                        '0') != 'DNR'
                                           AND ar.id_harvest = h.id_harvest(+)
                                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                         i_prof,
                                                                                                         ar.id_analysis)
                                                  FROM dual) = pk_alert_constant.g_yes
                                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                                         i_prof,
                                                                                                         ar.id_analysis,
                                                                                                         pk_lab_tests_constant.g_infectious_diseases_results)
                                                  FROM dual) = pk_alert_constant.g_yes
                                           AND ((h.flg_status NOT IN
                                               (pk_lab_tests_constant.g_harvest_pending,
                                                  pk_lab_tests_constant.g_harvest_waiting,
                                                  pk_lab_tests_constant.g_harvest_cancel,
                                                  pk_lab_tests_constant.g_harvest_suspended) AND i_flg_type = 'H') OR
                                               (i_flg_type = 'R'))) ar
                                 WHERE (ar.rn = 1 AND ar.flg_mult_result IS NULL)
                                    OR (ar.flg_mult_result = pk_lab_tests_constant.g_yes)) aresp,
                               (SELECT lte.id_analysis_req,
                                       lte.id_analysis_req_det,
                                       lte.flg_status_det,
                                       lte.id_episode,
                                       lte.id_visit
                                  FROM lab_tests_ea lte
                                 WHERE lte.id_patient = i_patient) lte,
                               (SELECT *
                                  FROM abnormality
                                 WHERE flg_visible = pk_lab_tests_constant.g_yes) a,
                               result_status rs
                         WHERE aresp.id_analysis_req_det = lte.id_analysis_req_det(+)
                           AND aresp.id_result_status = rs.id_result_status(+)
                           AND aresp.id_abnormality = a.id_abnormality(+)) t
                 WHERE (t.dt_result_ord IS NOT NULL AND i_flg_type = 'R')
                    OR (t.dt_harvest_ord IS NOT NULL AND i_flg_type = 'H'));
    
        g_error := 'OPEN CURSOR';
        OPEN o_result_graphview FOR
            SELECT ar.*
              FROM TABLE(l_list) ar
             WHERE ((ar.id_visit = i_visit AND i_visit IS NOT NULL) OR i_visit IS NULL)
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      decode(i_flg_type, 'H', ar.dt_harvest_ord, ar.dt_result_ord) DESC,
                      decode(i_flg_type, 'H', ar.id_harvest, ar.id_analysis_result) DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_PDMSVIEW',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_pdmsview;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_labtest_desc     VARCHAR2(1000 CHAR);
        l_task_status_desc VARCHAR2(1000 CHAR);
    
        l_desc CLOB;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_analysis_req_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_DESCRIPTION';
        IF NOT pk_lab_tests_external.get_lab_test_task_description(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_analysis_req_det => i_analysis_req_det,
                                                                   o_labtest_desc     => l_labtest_desc,
                                                                   o_task_status_desc => l_task_status_desc,
                                                                   o_error            => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_desc := CASE
                      WHEN l_labtest_desc IS NOT NULL THEN
                       l_labtest_desc
                      ELSE
                       NULL
                  END;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_description;

    FUNCTION get_lab_test_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_task_instructions VARCHAR2(1000 CHAR);
    
        l_instructions CLOB;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_analysis_req_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_INSTRUCTIONS';
        IF NOT pk_lab_tests_external.get_lab_test_task_instructions(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_task_request      => NULL,
                                                                    i_task_request_det  => i_analysis_req_det,
                                                                    o_task_instructions => l_task_instructions,
                                                                    o_error             => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_instructions := CASE
                              WHEN l_task_instructions IS NOT NULL THEN
                               l_task_instructions
                              ELSE
                               NULL
                          END;
    
        RETURN l_instructions;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_instructions;

    FUNCTION get_lab_test_action_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_action           IN co_sign.id_action%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_cosign_action_order  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M146');
        l_msg_cosign_action_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M147');
        l_msg_action               sys_message.desc_message%TYPE;
    
    BEGIN
    
        SELECT CASE
                   WHEN ard.id_co_sign_order = i_co_sign_hist THEN
                    l_msg_cosign_action_order
                   WHEN ard.id_co_sign_cancel = i_co_sign_hist THEN
                    l_msg_cosign_action_cancel
                   ELSE
                    NULL
               END
          INTO l_msg_action
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det = i_analysis_req_det;
    
        RETURN l_msg_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_action_desc;

    FUNCTION get_lab_test_date_to_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_analysis_req_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req)
          INTO l_date
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det = i_analysis_req_det;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_date_to_order;

    PROCEDURE cdr_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_aux table_varchar2;
    
        l_analysis    analysis.id_analysis%TYPE;
        l_sample_type sample_type.id_sample_type%TYPE;
    
    BEGIN
        l_aux := pk_utils.str_split(i_analysis, '|');
    
        FOR i IN 1 .. l_aux.count
        LOOP
            IF i = 1
            THEN
                l_analysis := l_aux(i);
            ELSIF i = 2
            THEN
                l_sample_type := l_aux(i);
            END IF;
        END LOOP;
    
        RETURN pk_lab_tests_utils.get_lab_test_id_content(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_analysis    => l_analysis,
                                                          i_sample_type => l_sample_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_id_content;

    FUNCTION get_lab_test_param_id_content
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_parameter IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_aux table_varchar2;
    
        l_analysis           analysis.id_analysis%TYPE;
        l_sample_type        sample_type.id_sample_type%TYPE;
        l_analysis_parameter analysis_parameter.id_analysis_parameter%TYPE;
    
    BEGIN
        l_aux := pk_utils.str_split(i_analysis_parameter, '|');
    
        FOR i IN 1 .. l_aux.count
        LOOP
            IF i = 1
            THEN
                l_analysis := l_aux(i);
            ELSIF i = 2
            THEN
                l_sample_type := l_aux(i);
            ELSIF i = 3
            THEN
                l_analysis_parameter := l_aux(i);
            END IF;
        END LOOP;
    
        RETURN pk_lab_tests_utils.get_lab_test_param_id_content(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_analysis           => l_analysis,
                                                                i_sample_type        => l_sample_type,
                                                                i_analysis_parameter => l_analysis_parameter);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_lab_test_param_id_content;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_type      IN VARCHAR2 DEFAULT 'A',
        i_content       IN VARCHAR2,
        i_dep_clin_serv IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_aux                    table_varchar2;
        l_analysis_cnt           analysis_sample_type.id_content%TYPE;
        l_analysis_parameter_cnt analysis_parameter.id_content%TYPE;
    
        l_analysis           analysis.id_analysis%TYPE;
        l_sample_type        sample_type.id_sample_type%TYPE;
        l_analysis_parameter analysis_parameter.id_analysis_parameter%TYPE;
    
        l_desc_mess pk_translation.t_desc_translation;
    
    BEGIN
    
        IF i_flg_type = pk_lab_tests_constant.g_analysis_alias
        THEN
            IF instr(i_content, '|') = 0
            THEN
                SELECT ast.id_analysis, ast.id_sample_type
                  INTO l_analysis, l_sample_type
                  FROM analysis_sample_type ast
                 WHERE ast.id_content = i_content
                   AND ast.flg_available = pk_lab_tests_constant.g_available;
            ELSE
                l_aux := pk_utils.str_split(i_content, '|');
            
                FOR i IN 1 .. l_aux.count
                LOOP
                    IF i = 1
                    THEN
                        l_analysis_cnt := l_aux(i);
                    ELSIF i = 2
                    THEN
                        l_analysis_parameter_cnt := l_aux(i);
                    END IF;
                END LOOP;
            
                SELECT ast.id_analysis, ast.id_sample_type
                  INTO l_analysis, l_sample_type
                  FROM analysis_sample_type ast
                 WHERE ast.id_content = l_analysis_cnt
                   AND ast.flg_available = pk_lab_tests_constant.g_available;
            END IF;
        
            l_desc_mess := pk_lab_tests_utils.get_alias_translation(i_lang                      => i_lang,
                                                                    i_prof                      => i_prof,
                                                                    i_flg_type                  => i_flg_type,
                                                                    i_analysis_code_translation => 'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                                   l_analysis,
                                                                    i_sample_code_translation   => 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                                   l_sample_type,
                                                                    i_dep_clin_serv             => i_dep_clin_serv);
        
        ELSE
        
            l_aux := pk_utils.str_split(i_content, '|');
        
            FOR i IN 1 .. l_aux.count
            LOOP
                IF i = 1
                THEN
                    l_analysis_cnt := l_aux(i);
                ELSIF i = 2
                THEN
                    l_analysis_parameter_cnt := l_aux(i);
                END IF;
            END LOOP;
        
            SELECT ast.id_analysis, ast.id_sample_type, ap.id_analysis_parameter
              INTO l_analysis, l_sample_type, l_analysis_parameter
              FROM analysis_sample_type ast, analysis_param ap, analysis_parameter apar
             WHERE ast.id_content = l_analysis_cnt
               AND ast.id_analysis = ap.id_analysis
               AND ast.id_sample_type = ap.id_sample_type
               AND ap.id_institution = i_prof.institution
               AND ap.id_software = i_prof.software
               AND ap.flg_available = pk_lab_tests_constant.g_available
               AND ap.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_content = l_analysis_parameter_cnt
               AND apar.flg_available = pk_lab_tests_constant.g_available;
        
            l_desc_mess := pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     i_flg_type,
                                                                     'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                     l_analysis_parameter,
                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || l_sample_type,
                                                                     NULL);
        
        END IF;
    
        RETURN l_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_lab_test_parameter_for_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_param     IN table_number,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_analysis_parameter FOR
            SELECT ap.id_analysis_parameter
              FROM analysis_param ap
             WHERE ap.id_analysis_param IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(i_analysis_param) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_PARAMETER_FOR_CDR',
                                              o_error);
            pk_types.open_my_cursor(o_analysis_parameter);
            RETURN FALSE;
    END get_lab_test_parameter_for_cdr;

    FUNCTION get_lab_test_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN VARCHAR2,
        i_date               IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_aux                    table_varchar2;
        l_analysis_cnt           analysis_sample_type.id_content%TYPE;
        l_analysis_parameter_cnt analysis_parameter.id_content%TYPE;
    
        l_analysis           table_number;
        l_sample_type        table_number;
        l_analysis_parameter table_number;
    
    BEGIN
    
        l_aux := pk_utils.str_split(i_analysis_parameter, '|');
    
        FOR i IN 1 .. l_aux.count
        LOOP
            IF i = 1
            THEN
                l_analysis_cnt := l_aux(i);
            ELSIF i = 2
            THEN
                l_analysis_parameter_cnt := l_aux(i);
            END IF;
        END LOOP;
    
        SELECT ast.id_analysis, ast.id_sample_type, ap.id_analysis_parameter
          BULK COLLECT
          INTO l_analysis, l_sample_type, l_analysis_parameter
          FROM analysis_sample_type ast, analysis_param ap, analysis_parameter apar
         WHERE ast.id_content = l_analysis_cnt
           AND ast.id_analysis = ap.id_analysis
           AND ast.id_sample_type = ap.id_sample_type
           AND ap.id_analysis_parameter = apar.id_analysis_parameter
           AND apar.id_content = l_analysis_parameter_cnt;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT *
              FROM (SELECT t.analysis_result_value_1 result_val,
                           t.id_unit_measure         id_unit_measure,
                           t.id_analysis_desc,
                           t.result_date
                      FROM (SELECT aresp.analysis_result_value_1,
                                   nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz) result_date,
                                   aresp.id_unit_measure,
                                   aresp.id_analysis_desc
                              FROM lab_tests_ea ltea
                              LEFT JOIN analysis_result_par aresp
                                ON aresp.id_analysis_result = ltea.id_analysis_result
                             WHERE ltea.flg_status_det != pk_lab_tests_constant.g_analysis_cancel
                               AND (ltea.flg_status_harvest IS NULL OR
                                   ltea.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                               AND aresp.id_analysis_parameter IN
                                   (SELECT /*+opt_estimate (table t rows=1)*/
                                     *
                                      FROM TABLE(l_analysis_parameter) t)
                               AND ltea.id_patient = i_patient
                               AND ltea.id_analysis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                         *
                                                          FROM TABLE(l_analysis) t)
                               AND ltea.id_sample_type IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                            *
                                                             FROM TABLE(l_sample_type) t)
                               AND (i_date IS NULL OR (ltea.dt_analysis_result >= i_date))
                            UNION ALL
                            SELECT aresp.analysis_result_value_1,
                                   nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz) result_date,
                                   aresp.id_unit_measure,
                                   aresp.id_analysis_desc
                              FROM analysis_result ar
                              JOIN analysis_result_par aresp
                                ON aresp.id_analysis_result = ar.id_analysis_result
                             WHERE ar.id_patient = i_patient
                               AND aresp.id_analysis_parameter IN
                                   (SELECT /*+opt_estimate (table t rows=1)*/
                                     *
                                      FROM TABLE(l_analysis_parameter) t)
                               AND ar.id_analysis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                       *
                                                        FROM TABLE(l_analysis) t)
                               AND ar.id_sample_type IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                          *
                                                           FROM TABLE(l_sample_type) t)
                               AND NOT EXISTS
                             (SELECT 0
                                      FROM lab_tests_ea ltea
                                     WHERE ltea.id_analysis_result = aresp.id_analysis_result
                                       AND (ltea.flg_status_harvest IS NULL OR
                                           ltea.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                                       AND ltea.id_patient = i_patient
                                       AND (i_date IS NULL OR ar.dt_analysis_result_tstz >= i_date))) t
                     ORDER BY t.result_date DESC)
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_CDR',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_cdr;

    FUNCTION check_lab_test_cdr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis         IN VARCHAR2,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_analysis_req_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_aux                    table_varchar2;
        l_analysis_cnt           analysis_sample_type.id_content%TYPE;
        l_analysis_parameter_cnt analysis_parameter.id_content%TYPE;
    
        l_analysis    analysis.id_analysis%TYPE;
        l_sample_type sample_type.id_sample_type%TYPE;
    
    BEGIN
    
        IF instr(i_analysis, '|') = 0
        THEN
            SELECT ast.id_analysis, ast.id_sample_type
              INTO l_analysis, l_sample_type
              FROM analysis_sample_type ast
             WHERE ast.id_content = i_analysis;
        ELSE
            l_aux := pk_utils.str_split(i_analysis, '|');
        
            FOR i IN 1 .. l_aux.count
            LOOP
                IF i = 1
                THEN
                    l_analysis_cnt := l_aux(i);
                ELSIF i = 2
                THEN
                    l_analysis_parameter_cnt := l_aux(i);
                END IF;
            END LOOP;
        
            SELECT ast.id_analysis, ast.id_sample_type
              INTO l_analysis, l_sample_type
              FROM analysis_sample_type ast
             WHERE ast.id_content = l_analysis_cnt;
        END IF;
    
        g_error := 'SELECT';
        SELECT ltea.id_analysis_req_det
          BULK COLLECT
          INTO o_analysis_req_det
          FROM lab_tests_ea ltea
         WHERE ltea.id_analysis = l_analysis
           AND ltea.id_sample_type = l_sample_type
           AND ltea.id_patient = i_patient
           AND (i_date IS NULL OR ltea.dt_req >= i_date)
           AND ltea.flg_status_det != pk_lab_tests_constant.g_analysis_cancel;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_CDR',
                                              o_error);
        
            RETURN FALSE;
    END check_lab_test_cdr;

    PROCEDURE referral___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION update_lab_test_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_exec_institution IN analysis_req_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'UPDATE ANALYSIS_REQ_DET';
        ts_analysis_req_det.upd(id_analysis_req_det_in => i_analysis_req_det,
                                id_exec_institution_in => i_exec_institution,
                                rows_out               => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_LAB_TEST_EXEC_INSTITUTION',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_institution;

    FUNCTION update_lab_test_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_referral     IN analysis_req_det.flg_referral%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status_req lab_tests_ea.flg_status_req%TYPE;
        l_flg_col_inst   lab_tests_ea.flg_col_inst%TYPE;
        l_id_req         lab_tests_ea.id_analysis_req_det%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_HISTORY';
        /*  IF NOT pk_lab_tests_core.set_lab_test_history(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_analysis_req     => NULL,
                                                      i_analysis_req_det => table_number(i_analysis_req_det),
                                                      o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;*/
    
        g_error := 'UPDATE ANALYSIS_REQ_DET';
        ts_analysis_req_det.upd(id_analysis_req_det_in => i_analysis_req_det,
                                flg_referral_in        => i_flg_referral,
                                rows_out               => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        -- Update analysis request flag status, if harvest is to be performed
        -- on this institution
        g_error := 'GET FLG_STATUS_REQ';
        BEGIN
            SELECT lte.flg_col_inst, lte.flg_status_req
              INTO l_flg_col_inst, l_flg_status_req
              FROM lab_tests_ea lte
             WHERE lte.id_analysis_req_det = i_analysis_req_det;
        
            IF l_flg_col_inst = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO PK_LAB_TESTS_CORE.SET_LAB_TEST_STATUS';
                IF NOT pk_lab_tests_core.set_lab_test_status(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_analysis_req_det => table_number(i_analysis_req_det),
                                                             i_status           => l_flg_status_req,
                                                             o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                SELECT lte.flg_col_inst, lte.flg_status_req, lte.id_analysis_req_det
                  INTO l_flg_col_inst, l_flg_status_req, l_id_req
                  FROM lab_tests_ea lte
                 WHERE lte.id_analysis_req = i_analysis_req_det;
            
                IF l_flg_col_inst = pk_alert_constant.g_yes
                THEN
                    g_error := 'CALL TO PK_LAB_TESTS_CORE.SET_LAB_TEST_STATUS';
                    IF NOT pk_lab_tests_core.set_lab_test_status(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_analysis_req_det => table_number(i_analysis_req_det),
                                                                 i_status           => l_flg_status_req,
                                                                 o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_LAB_TEST_REFERRAL',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_referral;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_lab_tests_external.t_cur_lab_test_result,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
        l_list t_tbl_lab_tests_results;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_flg_type         => 'R',
                                                          i_dt_min           => NULL,
                                                          i_dt_max           => NULL,
                                                          i_flg_report       => pk_lab_tests_constant.g_no,
                                                          o_list             => l_list,
                                                          o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        OPEN o_list FOR
            SELECT ar.flg_type            flg_type,
                   ar.id_analysis_req_det id_analysis_req_det,
                   ar.id_analysis         id_analysis,
                   ar.desc_analysis       desc_analysis,
                   ar.desc_parameter      desc_parameter,
                   ar.result              RESULT,
                   ar.flg_result_type     flg_result_type,
                   ar.desc_unit_measure   desc_unit_measure,
                   ar.ref_val             ref_val,
                   ar.abnormality         abnormality,
                   ar.dt_req              dt_req
              FROM TABLE(l_list) ar
             WHERE ar.rn = 1
               AND ar.id_visit = l_visit
               AND ar.result IS NOT NULL
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      ar.dt_result_ord      DESC,
                      ar.id_analysis_result DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_RESULTSVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_resultsview;

    FUNCTION check_lab_test_workflow_end
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT ard.id_analysis_req_det,
                   CASE
                        WHEN ard.flg_col_inst = pk_lab_tests_constant.g_yes
                             AND ard.id_exec_institution IS NOT NULL
                             AND (ard.flg_status = pk_lab_tests_constant.g_analysis_exterior OR
                             ard.flg_status = pk_lab_tests_constant.g_analysis_req OR
                             ard.flg_status = pk_lab_tests_constant.g_analysis_pending) THEN
                         pk_lab_tests_constant.g_no
                        ELSE
                         pk_lab_tests_constant.g_yes
                    END end_of_ext_workflow
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                *
                                                 FROM TABLE(i_analysis_req_det) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_WORKFLOW_END',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_lab_test_workflow_end;

    PROCEDURE cpoe______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION copy_lab_test_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req     analysis_req%ROWTYPE;
        l_analysis_req_det analysis_req_det%ROWTYPE;
    
        l_harvest       table_number := table_number();
        l_body_location table_number := table_number();
        l_laterality    table_varchar := table_varchar();
    
        l_dt_begin_tstz analysis_req_det.dt_begin_harvest%TYPE;
    
        l_diagnosis      table_number := table_number();
        l_diagnosis_desc table_varchar := table_varchar();
    
        l_codification codification.id_codification%TYPE;
    
        l_clinical_question       table_number;
        l_response                table_varchar;
        l_clinical_question_notes table_varchar;
    
        o_analysis_req analysis_req.id_analysis_req%TYPE;
    
        o_analysis_req_par table_number;
    
        CURSOR c_diagnosis_list(l_analysis_req_det analysis_req_det.id_analysis_req_det%TYPE) IS
            SELECT mrd.id_diagnosis, ed.desc_epis_diagnosis desc_diagnosis
              FROM mcdt_req_diagnosis mrd, epis_diagnosis ed
             WHERE mrd.id_interv_presc_det = l_analysis_req_det
               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
               AND mrd.id_epis_diagnosis = ed.id_epis_diagnosis;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
    BEGIN
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        IF l_diagnosis IS NULL
           OR l_diagnosis.count = 0
        THEN
            FOR l_diagnosis_list IN c_diagnosis_list(i_task_request)
            LOOP
                l_diagnosis.extend;
                l_diagnosis(l_diagnosis.count) := l_diagnosis_list.id_diagnosis;
            
                l_diagnosis_desc.extend;
                l_diagnosis_desc(l_diagnosis.count) := l_diagnosis_list.desc_diagnosis;
            END LOOP;
        END IF;
    
        g_error := 'GET ANALYSIS_REQ_DET';
        SELECT *
          INTO l_analysis_req_det
          FROM analysis_req_det
         WHERE id_analysis_req_det = i_task_request;
    
        g_error := 'GET ANALYSIS_REQ';
        SELECT *
          INTO l_analysis_req
          FROM analysis_req
         WHERE id_analysis_req = l_analysis_req_det.id_analysis_req;
    
        g_error := 'GET ANALYSIS_HARVEST';
        SELECT id_harvest
          BULK COLLECT
          INTO l_harvest
          FROM analysis_harvest
         WHERE id_analysis_req_det = i_task_request
           AND flg_status != pk_lab_tests_constant.g_harvest_inactive;
    
        g_error := 'GET ANALYSIS_CODIFICATION';
        BEGIN
            SELECT ic.id_codification
              INTO l_codification
              FROM analysis_codification ic
             WHERE ic.id_analysis_codification = l_analysis_req_det.id_analysis_codification;
        EXCEPTION
            WHEN no_data_found THEN
                l_codification := NULL;
        END;
    
        g_error := 'GET HARVEST';
        SELECT id_body_part, flg_laterality
          BULK COLLECT
          INTO l_body_location, l_laterality
          FROM harvest
         WHERE id_harvest IN (SELECT /*+opt_estimate(table t rows=1)*/
                               *
                                FROM TABLE(l_harvest) t);
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_dt_begin_tstz := i_task_start_timestamp;
        ELSIF pk_date_utils.trunc_insttimezone(i_prof, l_analysis_req_det.dt_final_target_tstz) >
              pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
        THEN
            l_dt_begin_tstz := g_sysdate_tstz;
        END IF;
    
        l_clinical_question       := table_number();
        l_response                := table_varchar();
        l_clinical_question_notes := table_varchar();
    
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_REQUEST';
        IF NOT pk_lab_tests_core.create_lab_test_request(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_patient                 => l_analysis_req.id_patient,
                                                         i_episode                 => i_episode,
                                                         i_analysis_req            => NULL,
                                                         i_analysis_req_det        => NULL,
                                                         i_analysis_req_det_parent => NULL,
                                                         i_harvest                 => NULL,
                                                         i_analysis                => l_analysis_req_det.id_analysis,
                                                         i_analysis_group          => l_analysis_req_det.id_analysis_group,
                                                         i_dt_req                  => NULL,
                                                         i_flg_time                => l_analysis_req_det.flg_time_harvest,
                                                         i_dt_begin                => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                  l_dt_begin_tstz,
                                                                                                                  i_prof),
                                                         i_dt_begin_limit          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                  l_analysis_req_det.dt_final_target_tstz,
                                                                                                                  i_prof),
                                                         i_episode_destination     => l_analysis_req.id_episode_destination,
                                                         i_order_recurrence        => NULL,
                                                         i_priority                => l_analysis_req.flg_priority,
                                                         i_flg_prn                 => l_analysis_req_det.flg_prn,
                                                         i_notes_prn               => l_analysis_req_det.notes_prn,
                                                         i_specimen                => l_analysis_req_det.id_sample_type,
                                                         i_body_location           => l_body_location,
                                                         i_laterality              => l_laterality,
                                                         i_collection_room         => l_analysis_req_det.id_room,
                                                         i_notes                   => l_analysis_req.notes,
                                                         i_notes_scheduler         => l_analysis_req_det.notes_scheduler,
                                                         i_notes_technician        => l_analysis_req_det.notes_tech,
                                                         i_notes_patient           => l_analysis_req_det.notes_patient,
                                                         i_diagnosis_notes         => l_analysis_req_det.diagnosis_notes,
                                                         i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                                                                                i_prof      => i_prof,
                                                                                                                i_patient   => l_analysis_req.id_patient,
                                                                                                                i_episode   => i_episode,
                                                                                                                i_diagnosis => l_diagnosis,
                                                                                                                i_desc_diag => l_diagnosis_desc),
                                                         i_exec_institution        => l_analysis_req_det.id_exec_institution,
                                                         i_clinical_purpose        => l_analysis_req_det.id_clinical_purpose,
                                                         i_clinical_purpose_notes  => l_analysis_req_det.clinical_purpose_notes,
                                                         i_flg_col_inst            => l_analysis_req_det.flg_col_inst,
                                                         i_flg_fasting             => l_analysis_req_det.flg_fasting,
                                                         i_lab_req                 => l_analysis_req_det.id_room_req,
                                                         i_prof_cc                 => table_varchar(),
                                                         i_prof_bcc                => table_varchar(),
                                                         i_codification            => l_codification,
                                                         i_health_plan             => l_analysis_req_det.id_pat_health_plan,
                                                         i_exemption               => l_analysis_req_det.id_pat_exemption,
                                                         i_prof_order              => NULL,
                                                         i_dt_order                => NULL,
                                                         i_order_type              => NULL,
                                                         i_clinical_question       => l_clinical_question,
                                                         i_response                => l_response,
                                                         i_clinical_question_notes => l_clinical_question_notes,
                                                         i_clinical_decision_rule  => NULL,
                                                         i_flg_origin_req          => pk_alert_constant.g_task_origin_cpoe,
                                                         i_task_dependency         => NULL,
                                                         i_flg_task_depending      => 'N',
                                                         i_episode_followup_app    => NULL,
                                                         i_schedule_followup_app   => NULL,
                                                         i_event_followup_app      => NULL,
                                                         o_analysis_req            => o_analysis_req,
                                                         o_analysis_req_det        => o_draft,
                                                         o_analysis_req_par        => o_analysis_req_par,
                                                         o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := l_analysis_req.id_patient;
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_other_exception;
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
                                              'COPY_LAB_TEST_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_lab_test_to_draft;

    FUNCTION check_lab_test_mandatory_field
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_clinical_indication sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_CLINICAL_INDICATION_MANDATORY',
                                                                               i_prof);
        l_notes_tech          sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_NOTES_TECH_MANDATORY', i_prof);
    
        l_flg_prof_need_cosign VARCHAR(1 CHAR);
    
        l_check VARCHAR(1 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL PK_CO_SIGN_API.CHECK_PROF_NEEDS_COSIGN';
        IF NOT pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_episode                => i_episode,
                                                      i_task_type              => pk_alert_constant.g_task_lab_tests,
                                                      i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_add,
                                                      o_flg_prof_need_cosign   => l_flg_prof_need_cosign,
                                                      o_error                  => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_clinical_indication = pk_lab_tests_constant.g_yes
        THEN
            BEGIN
                SELECT pk_lab_tests_constant.g_yes
                  INTO l_check
                  FROM mcdt_req_diagnosis mrd
                 WHERE mrd.id_analysis_req_det = i_analysis_req_det
                   AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_lab_tests_constant.g_no;
            END;
        END IF;
    
        IF l_flg_prof_need_cosign = pk_lab_tests_constant.g_yes
        THEN
            BEGIN
                SELECT pk_lab_tests_constant.g_yes
                  INTO l_check
                  FROM analysis_req_det ard
                 WHERE ard.id_analysis_req_det = i_analysis_req_det
                   AND ard.id_co_sign_order IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_lab_tests_constant.g_no;
            END;
        END IF;
    
        g_error := 'Fetch instructions for id_analysis_req_det: ' || i_analysis_req_det;
        SELECT decode(ard.flg_urgency,
                      NULL,
                      pk_lab_tests_constant.g_no,
                      decode(ard.flg_time_harvest,
                             NULL,
                             pk_lab_tests_constant.g_no,
                             decode(ard.flg_col_inst,
                                    NULL,
                                    pk_lab_tests_constant.g_no,
                                    decode(l_notes_tech,
                                           pk_lab_tests_constant.g_yes,
                                           decode(ard.notes_tech,
                                                  NULL,
                                                  pk_lab_tests_constant.g_no,
                                                  pk_lab_tests_constant.g_yes),
                                           pk_lab_tests_constant.g_yes))))
          INTO l_check
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det = i_analysis_req_det;
    
        -- check if there's no req dets with mandatory fields empty
    
        IF l_check = pk_lab_tests_constant.g_no
        THEN
            RETURN pk_lab_tests_constant.g_no;
        END IF;
    
        -- all mandatory fields have a value
    
        RETURN pk_lab_tests_constant.g_yes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_MANDATORY_FIELD',
                                              l_error);
            RETURN pk_lab_tests_constant.g_no;
    END check_lab_test_mandatory_field;

    FUNCTION check_lab_test_draft_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient          patient.id_patient%TYPE;
        l_flg_conflict     table_varchar := table_varchar();
        l_msg_title        table_varchar := table_varchar();
        l_msg_body         table_varchar := table_varchar();
        l_msg_template     table_varchar := table_varchar();
        l_analysis_desc    table_varchar;
        l_analysis         table_number;
        l_dt_begin         table_timestamp_tz;
        l_tmp_flg_conflict VARCHAR2(4000);
        l_tmp_msg_title    VARCHAR2(4000);
        l_tmp_msg_text     VARCHAR2(4000);
        l_button           VARCHAR2(4000);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error   := 'GET ID_PATIENT';
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        SELECT ard.id_analysis, ard.dt_begin_harvest, pk_translation.get_translation(i_lang, a.code_analysis)
          BULK COLLECT
          INTO l_analysis, l_dt_begin, l_analysis_desc
          FROM analysis_req_det ard
          JOIN analysis a
            ON a.id_analysis = ard.id_analysis
          JOIN TABLE(i_draft) t
            ON t.column_value = ard.id_analysis_req_det;
    
        g_error := 'CHECK FOR CONFLICTS';
    
        l_flg_conflict.extend;
        l_flg_conflict(l_flg_conflict.count) := pk_lab_tests_utils.get_lab_test_request(i_lang     => i_lang,
                                                                                        i_prof     => i_prof,
                                                                                        i_patient  => l_patient,
                                                                                        i_analysis => l_analysis,
                                                                                        o_msg_req  => l_tmp_msg_text,
                                                                                        o_button   => l_button);
    
        l_flg_conflict(l_flg_conflict.count) := l_tmp_flg_conflict;
        l_msg_template.extend;
        l_msg_template(l_msg_template.count) := pk_alert_constant.g_modal_win_warning_confirm;
        l_msg_title.extend;
        l_msg_title(l_msg_title.count) := l_tmp_msg_title;
        l_msg_body.extend;
        l_msg_body(l_msg_body.count) := l_tmp_msg_text;
    
        o_flg_conflict := l_flg_conflict;
        o_msg_title    := l_msg_title;
        o_msg_body     := l_msg_body;
        o_msg_template := l_msg_template;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_DRAFT_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_draft_conflict;

    FUNCTION check_lab_test_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM analysis_req ar
         WHERE ar.id_episode_destination = i_episode
           AND ar.flg_status = pk_lab_tests_constant.g_analysis_draft;
    
        IF l_count > 0
        THEN
            o_has_draft := pk_lab_tests_constant.g_yes;
        ELSE
            o_has_draft := pk_alert_constant.g_no;
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
                                              'CHECK_LAB_TEST_DRAFT',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_draft;

    FUNCTION set_lab_test_draft_activation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        i_id_cdr_call   IN cdr_call.id_cdr_call%TYPE,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_draft IS
            SELECT ar.id_analysis_req,
                   ard.id_analysis_req_det,
                   ard.id_analysis,
                   ard.id_sample_type,
                   ar.id_episode,
                   decode(pk_date_utils.compare_dates_tsz(i_prof, ar.dt_begin_tstz, g_sysdate_tstz),
                          pk_alert_constant.g_date_lower,
                          g_sysdate_tstz,
                          ar.dt_begin_tstz) dt_begin,
                   ard.flg_time_harvest flg_time,
                   ard.flg_prn,
                   ard.flg_col_inst,
                   ard.id_exec_institution,
                   ard.id_co_sign_order
              FROM analysis_req_det ard
              JOIN analysis_req ar
                ON ar.id_analysis_req = ard.id_analysis_req
             WHERE ard.id_analysis_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                *
                                                 FROM TABLE(i_draft) t);
    
        l_status      analysis_req.flg_status%TYPE;
        l_status_det  analysis_req_det.flg_status%TYPE;
        l_dt_begin    analysis_req.dt_begin_tstz%TYPE;
        l_dt_schedule analysis_req_det.dt_schedule%TYPE;
    
        l_flg_execute analysis_instit_soft.flg_execute%TYPE;
        l_flg_harvest analysis_instit_soft.flg_harvest%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_created_tasks := i_draft;
    
        FOR rec IN c_analysis_draft
        LOOP
            IF rec.flg_time != pk_lab_tests_constant.g_flg_time_e
            THEN
                -- realização futura
                l_status     := pk_lab_tests_constant.g_analysis_pending;
                l_status_det := pk_lab_tests_constant.g_analysis_pending;
                l_dt_begin   := NULL;
            
                IF rec.flg_time IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
                THEN
                    IF i_prof.software != pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof)
                    THEN
                        -- realização entre consultas
                        l_status     := pk_lab_tests_constant.g_analysis_tosched;
                        l_status_det := pk_lab_tests_constant.g_analysis_tosched;
                        IF rec.dt_begin IS NOT NULL
                        THEN
                            -- sugestão do agendamento
                            l_dt_begin    := NULL;
                            l_dt_schedule := rec.dt_begin;
                        ELSE
                            l_dt_begin    := NULL;
                            l_dt_schedule := NULL;
                        END IF;
                    ELSE
                        l_status     := pk_lab_tests_constant.g_analysis_tosched;
                        l_status_det := pk_lab_tests_constant.g_analysis_tosched;
                        l_dt_begin   := NULL;
                    END IF;
                END IF;
            ELSE
                -- realização neste epis.
                IF rec.id_episode IS NOT NULL
                THEN
                    IF pk_sysconfig.get_config('REQ_NEXT_DAY', i_prof) = pk_lab_tests_constant.g_no
                    THEN
                        IF pk_date_utils.trunc_insttimezone(i_prof, nvl(l_dt_begin, g_sysdate_tstz), 'DD') !=
                           pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'DD')
                        THEN
                            g_error_code := 'ANALYSIS_M012';
                            g_error      := pk_message.get_message(i_lang, 'ANALYSIS_M012');
                            RAISE g_user_exception;
                        END IF;
                    END IF;
                END IF;
            
                l_dt_begin := rec.dt_begin;
            
                IF nvl(l_dt_begin, g_sysdate_tstz) > g_sysdate_tstz
                THEN
                    -- pendente
                    l_status     := pk_lab_tests_constant.g_analysis_pending;
                    l_status_det := pk_lab_tests_constant.g_analysis_pending;
                ELSE
                    l_dt_begin   := g_sysdate_tstz;
                    l_status     := pk_lab_tests_constant.g_analysis_req;
                    l_status_det := pk_lab_tests_constant.g_analysis_req;
                END IF;
            END IF;
        
            SELECT ais.flg_execute, ais.flg_harvest
              INTO l_flg_execute, l_flg_harvest
              FROM analysis_instit_soft ais
             WHERE ais.id_analysis = rec.id_analysis
               AND ais.id_sample_type = rec.id_sample_type
               AND ais.id_software = i_prof.software
               AND ais.id_institution = i_prof.institution
               AND ais.flg_available = pk_lab_tests_constant.g_available;
        
            IF (l_flg_execute = pk_lab_tests_constant.g_no AND
               (l_flg_harvest = pk_lab_tests_constant.g_no OR rec.flg_col_inst = pk_lab_tests_constant.g_no))
               OR (rec.id_exec_institution IS NOT NULL AND rec.flg_col_inst = pk_lab_tests_constant.g_no)
            THEN
                l_status     := pk_lab_tests_constant.g_analysis_exterior;
                l_status_det := pk_lab_tests_constant.g_analysis_exterior;
            END IF;
        
            IF rec.flg_prn = pk_lab_tests_constant.g_yes
            THEN
                IF (l_flg_execute = pk_lab_tests_constant.g_no AND
                   (l_flg_harvest = pk_lab_tests_constant.g_no OR rec.flg_col_inst = pk_lab_tests_constant.g_no))
                   OR (rec.id_exec_institution IS NOT NULL AND rec.flg_col_inst = pk_lab_tests_constant.g_no)
                THEN
                    l_status     := pk_lab_tests_constant.g_analysis_exterior;
                    l_status_det := pk_lab_tests_constant.g_analysis_exterior;
                ELSE
                    l_status     := pk_lab_tests_constant.g_analysis_sos;
                    l_status_det := pk_lab_tests_constant.g_analysis_sos;
                END IF;
            END IF;
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_analysis_req_in     => rec.id_analysis_req,
                                flg_status_in          => l_status,
                                dt_begin_tstz_in       => l_dt_begin,
                                id_prof_last_update_in => i_prof.id,
                                dt_last_update_tstz_in => g_sysdate_tstz,
                                rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_REQ_DET';
            ts_analysis_req_det.upd(id_analysis_req_det_in => rec.id_analysis_req_det,
                                    flg_status_in          => l_status_det,
                                    dt_target_tstz_in      => l_dt_begin,
                                    id_prof_last_update_in => i_prof.id,
                                    dt_last_update_tstz_in => g_sysdate_tstz,
                                    rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_REQ_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.CREATE_HARVEST_SUSPENDED';
            IF NOT pk_lab_tests_harvest_core.create_harvest_suspended(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_analysis_req_det => rec.id_analysis_req_det,
                                                                      o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_CPOE.SYNC_TASK';
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_episode              => i_episode,
                                     i_task_type            => pk_alert_constant.g_task_type_analysis,
                                     i_task_request         => rec.id_analysis_req_det,
                                     i_task_start_timestamp => rec.dt_begin,
                                     o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        IF i_flg_commit = pk_lab_tests_constant.g_yes
        THEN
            COMMIT;
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
                                              'SET_LAB_TEST_DRAFT_ACTIVATION',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_draft_activation;

    FUNCTION cancel_lab_test_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req       analysis_req.id_analysis_req%TYPE;
        l_count_analysis_req NUMBER;
    
    BEGIN
    
        FOR i IN 1 .. i_draft.count
        LOOP
            BEGIN
                SELECT id_analysis_req
                  INTO l_analysis_req
                  FROM analysis_req_det
                 WHERE id_analysis_req_det = i_draft(i);
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE g_other_exception;
            END;
        
            -- delete analysis_result
            DELETE FROM analysis_result
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete co_sign
            DELETE FROM co_sign
             WHERE id_task = l_analysis_req;
        
            -- delete grid_task_lab
            DELETE FROM grid_task_lab
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete analysis_req_par
            DELETE FROM analysis_req_par
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete analysis_harvest
            DELETE FROM analysis_harvest
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete analysis_question_response
            DELETE FROM analysis_question_response
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete lab_tests_ea
            DELETE FROM lab_tests_ea
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete analysis_req_det
            DELETE FROM lab_tests_ea
             WHERE id_analysis_req_det = i_draft(i);
        
            -- delete analysis_req
        
            SELECT COUNT(*)
              INTO l_count_analysis_req
              FROM analysis_req_det
             WHERE id_analysis_req_det = i_draft(i);
        
            IF l_count_analysis_req = 0
            THEN
                DELETE FROM lab_tests_ea
                 WHERE id_analysis_req = l_analysis_req;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EXAM_DRAFT',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_draft;

    FUNCTION cancel_lab_test_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_drafts table_number;
    
    BEGIN
        g_error := 'Get episode''s draft tasks';
        SELECT pea.id_analysis_req_det
          BULK COLLECT
          INTO l_drafts
          FROM lab_tests_ea pea
         WHERE pea.id_episode IN (SELECT id_episode
                                    FROM episode
                                   WHERE id_visit = pk_episode.get_id_visit(i_episode))
           AND pea.flg_status_det = pk_lab_tests_constant.g_analysis_draft;
        -- TODO id_episode_origin ??
    
        IF l_drafts IS NOT NULL
           AND l_drafts.count > 0
        THEN
            IF NOT pk_lab_tests_external.cancel_lab_test_draft(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_episode => i_episode,
                                                               i_draft   => l_drafts,
                                                               o_error   => o_error)
            THEN
                RAISE g_other_exception;
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
                                              'CANCEL_LAB_TEST_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_all_drafts;

    FUNCTION get_lab_test_task_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        i_cpoe_tab        IN VARCHAR2 DEFAULT 'A',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER := 0;
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
    
        IF i_task_request IS NOT NULL
        THEN
            l_count := i_task_request.count;
        END IF;
        OPEN o_task_list FOR
            WITH cso_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    pk_alert_constant.g_task_lab_tests)))
            SELECT task_type,
                   t_ti_log.get_desc_with_origin(i_lang,
                                                 i_prof,
                                                 task_description,
                                                 pk_episode.get_epis_type(i_lang, i_episode),
                                                 flg_status,
                                                 id_request,
                                                 pk_lab_tests_constant.g_analysis_req) AS task_description,
                   id_professional,
                   icon_warning,
                   status_string,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   create_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflict,
                   id_task,
                   task_title,
                   task_instructions,
                   task_notes,
                   drug_dose,
                   drug_route,
                   drug_take_in_case,
                   task_status,
                   NULL AS instr_bg_color,
                   NULL AS instr_bg_alpha,
                   NULL AS task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   pk_alert_constant.g_task_lab_tests AS id_task_type_source,
                   id_task_dependency AS id_task_dependency,
                   decode(flg_status,
                          pk_lab_tests_constant.g_analysis_cancel,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_rep_cancel,
                   flg_prn flg_prn_conditional
              FROM (SELECT pk_alert_constant.g_task_type_analysis task_type,
                           pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     'A',
                                                                     'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                     lte.id_sample_type,
                                                                     NULL) task_description,
                           ard.id_prof_last_update id_professional,
                           NULL icon_warning,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      lte.status_str,
                                                      lte.status_msg,
                                                      lte.status_icon,
                                                      lte.status_flg) status_string,
                           lte.id_analysis_req_det id_request,
                           nvl(lte.dt_order, lte.dt_target) start_date_tstz,
                           NULL end_date_tstz,
                           ard.dt_last_update_tstz AS create_date_tstz,
                           lte.flg_status_det flg_status,
                           decode(lte.id_prof_order,
                                  i_prof.id,
                                  pk_lab_tests_constant.g_yes,
                                  pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                                             i_prof,
                                                                             pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                             pk_lab_tests_constant.g_analysis_button_cancel,
                                                                             nvl(lte.id_episode, lte.id_episode_origin),
                                                                             NULL,
                                                                             lte.id_analysis_req_det,
                                                                             decode(lte.id_episode,
                                                                                    i_episode,
                                                                                    pk_lab_tests_constant.g_yes,
                                                                                    pk_lab_tests_constant.g_no))) flg_cancel,
                           CASE
                                WHEN (lte.flg_status_det = pk_lab_tests_constant.g_analysis_draft AND
                                     pk_lab_tests_external.check_lab_test_mandatory_field(i_lang,
                                                                                           i_prof,
                                                                                           i_episode,
                                                                                           lte.id_analysis_req_det) =
                                     pk_alert_constant.g_no) THEN
                                 pk_alert_constant.g_yes
                                WHEN (lte.flg_status_det = pk_lab_tests_constant.g_analysis_draft AND
                                     ard.dt_final_target_tstz IS NOT NULL) THEN
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, ard.dt_final_target_tstz, g_sysdate_tstz),
                                        pk_alert_constant.g_date_lower,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_no)
                                ELSE
                                 pk_alert_constant.g_no
                            END AS flg_conflict,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                            i_prof,
                                                                            'A',
                                                                            'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                            lte.id_sample_type,
                                                                            NULL)) task_title,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  decode(ard.flg_prn,
                                         pk_alert_constant.g_yes,
                                         pk_message.get_message(i_lang, 'COMMON_M112'),
                                         nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                                   i_prof,
                                                                                                   ard.id_order_recurrence),
                                             pk_translation.get_translation(i_lang,
                                                                            'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')))) task_instructions,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  decode(ard.notes_cancel,
                                         NULL,
                                         decode(ard.flg_prn,
                                                pk_alert_constant.g_yes,
                                                pk_string_utils.clob_to_varchar2(ard.notes_prn, 1000),
                                                ard.notes_tech),
                                         ard.notes_cancel)) task_notes,
                           NULL drug_dose,
                           NULL drug_route,
                           NULL drug_take_in_case,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', lte.flg_status_det, i_lang)) task_status,
                           nvl(lte.dt_target, lte.dt_order) TIMESTAMP,
                           decode(lte.flg_status_det,
                                  pk_lab_tests_constant.g_analysis_req,
                                  row_number() over(ORDER BY decode(lte.flg_referral,
                                              NULL,
                                              pk_sysdomain.get_rank(i_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                    lte.flg_status_det),
                                              pk_sysdomain.get_rank(i_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                    lte.flg_referral)),
                                       coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req)),
                                  pk_lab_tests_constant.g_analysis_pending,
                                  row_number() over(ORDER BY decode(lte.flg_referral,
                                              NULL,
                                              pk_sysdomain.get_rank(i_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                    lte.flg_status_det),
                                              pk_sysdomain.get_rank(i_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                    lte.flg_referral)),
                                       coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req)),
                                  row_number() over(ORDER BY decode(lte.flg_referral,
                                              NULL,
                                              decode(lte.flg_status_det,
                                                     pk_lab_tests_constant.g_analysis_toexec,
                                                     pk_sysdomain.get_rank(i_lang,
                                                                           'HARVEST.FLG_STATUS',
                                                                           lte.flg_status_harvest),
                                                     pk_sysdomain.get_rank(i_lang,
                                                                           'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                           lte.flg_status_det)),
                                              pk_sysdomain.get_rank(i_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                    lte.flg_referral)),
                                       coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req) DESC)) rank,
                           nvl(lte.id_episode, lte.id_episode_origin) AS id_episode,
                           lte.id_analysis id_task,
                           ard.id_task_dependency,
                           ard.flg_prn
                      FROM lab_tests_ea lte
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = lte.id_analysis_req_det
                      LEFT JOIN cso_table tcs
                        ON ard.id_co_sign_order = tcs.id_co_sign_hist
                     WHERE lte.id_patient = i_patient
                       AND (lte.id_episode IN (SELECT id_episode
                                                 FROM episode
                                                WHERE id_visit = pk_episode.get_id_visit(i_episode)) OR
                           lte.id_episode_origin IN
                           (SELECT id_episode
                               FROM episode
                              WHERE id_visit = pk_episode.get_id_visit(i_episode)))
                       AND ((i_flg_report = pk_alert_constant.g_yes AND
                           lte.flg_status_req != pk_lab_tests_constant.g_analysis_exterior) OR
                           i_flg_report = pk_alert_constant.g_no)
                       AND (((i_flg_out_of_cpoe = pk_alert_constant.g_yes AND i_flg_print_items = pk_alert_constant.g_no AND
                           (((ard.flg_status IN
                           (pk_lab_tests_constant.g_analysis_pending, pk_lab_tests_constant.g_analysis_req)) OR
                           (ard.flg_status NOT IN
                           (pk_lab_tests_constant.g_analysis_pending, pk_lab_tests_constant.g_analysis_req) AND
                           coalesce(lte.dt_analysis_result, lte.dt_harvest) BETWEEN i_dt_begin AND i_dt_end)))) OR
                           i_flg_report = pk_alert_constant.g_yes) AND
                           ((l_count = 0) OR
                           (lte.id_analysis_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_task_request) t))) AND
                           (lte.flg_status_det NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                         column_value
                                                          FROM TABLE(i_filter_status) t) OR
                           ((ard.flg_status NOT IN
                           (pk_lab_tests_constant.g_analysis_normal, pk_lab_tests_constant.g_analysis_cancel) AND
                           coalesce(lte.dt_analysis_result, ard.dt_final_target_tstz) >= i_filter_tstz) OR
                           (ard.flg_status = pk_lab_tests_constant.g_analysis_normal AND
                           ard.dt_target_tstz >= i_filter_tstz) OR
                           (ard.flg_status = pk_lab_tests_constant.g_analysis_cancel AND
                           ard.dt_cancel_tstz >= l_cancelled_task_filter_tstz))))
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes)
             ORDER BY rank;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE g_other_exception;
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
                                              'GET_LAB_TEST_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_lab_test_task_list;

    FUNCTION get_lab_test_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status          exam_req_det.flg_status%TYPE;
        l_flg_referral        exam_req_det.flg_referral%TYPE;
        l_button_cancel       VARCHAR(1 CHAR);
        l_button_confirmation VARCHAR(1 CHAR);
        l_button_edit         VARCHAR(1 CHAR);
        l_button_ok           VARCHAR(1 CHAR);
        l_button_read         VARCHAR(1 CHAR);
    
    BEGIN
    
        SELECT ard.flg_status, ard.flg_referral
          INTO l_flg_status, l_flg_referral
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det = i_task_request;
    
        g_error := 'GET EXAMS_EA';
        SELECT decode(lte.flg_referral,
                      pk_lab_tests_constant.g_flg_referral_r,
                      pk_lab_tests_constant.g_analysis_cancel,
                      pk_lab_tests_constant.g_flg_referral_s,
                      pk_lab_tests_constant.g_analysis_cancel,
                      pk_lab_tests_constant.g_flg_referral_i,
                      pk_lab_tests_constant.g_analysis_cancel,
                      lte.flg_status_det) flg_status,
               pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                          i_prof,
                                                          pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                          pk_lab_tests_constant.g_analysis_button_ok,
                                                          lte.id_episode,
                                                          NULL,
                                                          lte.id_analysis_req_det,
                                                          decode(lte.id_episode,
                                                                 i_episode,
                                                                 pk_lab_tests_constant.g_yes,
                                                                 pk_lab_tests_constant.g_no)) avail_button_ok,
               pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                          i_prof,
                                                          pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                          pk_lab_tests_constant.g_analysis_button_cancel,
                                                          lte.id_episode,
                                                          NULL,
                                                          lte.id_analysis_req_det,
                                                          decode(lte.id_episode,
                                                                 i_episode,
                                                                 pk_lab_tests_constant.g_yes,
                                                                 pk_lab_tests_constant.g_no)) avail_button_cancel,
               pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                          i_prof,
                                                          pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                          pk_lab_tests_constant.g_analysis_button_edit,
                                                          lte.id_episode,
                                                          NULL,
                                                          lte.id_analysis_req_det,
                                                          decode(lte.id_episode,
                                                                 i_episode,
                                                                 pk_lab_tests_constant.g_yes,
                                                                 pk_lab_tests_constant.g_no)) avail_button_edit,
               pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                          i_prof,
                                                          pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                          pk_lab_tests_constant.g_analysis_button_confirmation,
                                                          lte.id_episode,
                                                          NULL,
                                                          lte.id_analysis_req_det,
                                                          decode(lte.id_episode,
                                                                 i_episode,
                                                                 pk_lab_tests_constant.g_yes,
                                                                 pk_lab_tests_constant.g_no)) avail_button_confirmation,
               pk_lab_tests_utils.get_lab_test_permission(i_lang,
                                                          i_prof,
                                                          pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                          pk_lab_tests_constant.g_analysis_button_read,
                                                          lte.id_episode,
                                                          NULL,
                                                          lte.id_analysis_req_det,
                                                          decode(lte.id_episode,
                                                                 i_episode,
                                                                 pk_lab_tests_constant.g_yes,
                                                                 pk_lab_tests_constant.g_no)) avail_button_read
          INTO l_flg_status, l_button_ok, l_button_cancel, l_button_edit, l_button_confirmation, l_button_read
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det = i_task_request;
    
        g_error := 'OPEN O_ACTION';
        OPEN o_action FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr "level",
                   a.from_state,
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   decode(a.flg_active,
                          pk_lab_tests_constant.g_active,
                          decode(a.action,
                                 'EDIT',
                                 decode(l_button_edit,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_active,
                                        pk_lab_tests_constant.g_inactive),
                                 'CONFIRM_REQ',
                                 decode(l_button_confirmation,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_active,
                                        pk_lab_tests_constant.g_inactive),
                                 'PERFORM',
                                 decode(l_button_ok,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_active,
                                        pk_lab_tests_constant.g_inactive),
                                 'INS_RESULT',
                                 decode(l_button_ok,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_active,
                                        pk_lab_tests_constant.g_inactive),
                                 'MARK_AS_READ',
                                 decode(l_button_read,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_active,
                                        pk_lab_tests_constant.g_inactive),
                                 'CANCEL',
                                 decode(l_button_cancel,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_active,
                                        pk_lab_tests_constant.g_inactive),
                                 a.flg_active),
                          a.flg_active) flg_status,
                   a.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'ANALYSIS_CPOE', l_flg_status)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_action);
            RETURN FALSE;
    END get_lab_test_actions;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_plan_rep       t_tbl_order_recurr_plan;
        l_order_plan_rep_union t_tbl_order_recurr_plan := t_tbl_order_recurr_plan();
        l_tbl_interv_presc_det table_number;
        l_tbl_ipd_dt_begin     table_timestamp_tstz;
        l_last_reached         VARCHAR2(20 CHAR);
        l_order_recurrence     order_recurr_plan.id_order_recurr_plan%TYPE;
        l_t_order_recurr       table_number;
        l_cp_begin             TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end               TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_interv_presc_plan_last interv_presc_plan.id_interv_presc_plan%TYPE;
        l_interv_presc_plan_next interv_presc_plan.id_interv_presc_plan%TYPE;
    
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := i_cpoe_dt_end;
        END IF;
    
        OPEN o_plan_rep FOR
            SELECT t.id_analysis_req_det id_prescription,
                   decode(t.flg_prn,
                          pk_alert_constant.g_yes,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, t.dt_begin_tstz, i_prof)) planned_date,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_harvest_tstz, i_prof) exec_date,
                   t.notes exec_notes,
                   'N' out_of_period
              FROM (SELECT ard.id_analysis_req_det, ard.flg_prn, ar.dt_begin_tstz, h.dt_harvest_tstz, h.notes
                      FROM analysis_req ar
                     INNER JOIN analysis_req_det ard
                        ON ar.id_analysis_req = ard.id_analysis_req
                      LEFT JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      LEFT JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_episode = i_episode
                       AND ar.dt_begin_tstz BETWEEN CAST(l_cp_begin AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                           CAST(l_cp_end AS TIMESTAMP WITH LOCAL TIME ZONE)
                       AND ar.flg_status NOT IN
                           (pk_lab_tests_constant.g_analysis_cancel, pk_lab_tests_constant.g_analysis_draft)
                    UNION
                    SELECT ard.id_analysis_req_det, ard.flg_prn, ar.dt_begin_tstz, h.dt_harvest_tstz, h.notes
                      FROM analysis_req ar
                     INNER JOIN analysis_req_det ard
                        ON ar.id_analysis_req = ard.id_analysis_req
                      LEFT JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      LEFT JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_episode_origin = i_episode
                       AND ar.dt_begin_tstz BETWEEN CAST(l_cp_begin AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                           CAST(l_cp_end AS TIMESTAMP WITH LOCAL TIME ZONE)
                       AND ar.flg_status NOT IN
                           (pk_lab_tests_constant.g_analysis_cancel, pk_lab_tests_constant.g_analysis_draft)) t
             ORDER BY planned_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_PLAN_REPORT',
                                              o_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
    END get_order_plan_report;

    PROCEDURE order_sets_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN table_number,
        o_analysis_req_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_analysis_req_det FOR
            SELECT /*+opt_estimate(table req rows=1)*/
             d.id_analysis_req, d.id_analysis_req_det
              FROM analysis_req_det d
              JOIN TABLE(i_task_request) req
                ON d.id_analysis_req = req.column_value
             WHERE (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, d.id_analysis)
                      FROM dual) = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_REQ_DET',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_req_det;

    FUNCTION get_lab_test_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch alias_translation for id_analysis_req: ' || i_task_request;
        BEGIN
            SELECT CASE
                       WHEN (i_task_request_det IS NULL AND ard.id_analysis_group IS NULL)
                            OR i_task_request_det IS NOT NULL THEN
                        substr(concatenate(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                     i_prof,
                                                                                     pk_lab_tests_constant.g_analysis_alias,
                                                                                     'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                     ard.id_analysis,
                                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                     ard.id_sample_type,
                                                                                     NULL) || '; '),
                               1,
                               length(concatenate(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                            i_prof,
                                                                                            pk_lab_tests_constant.g_analysis_alias,
                                                                                            'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                            ard.id_analysis,
                                                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                            ard.id_sample_type,
                                                                                            NULL) || '; ')) - 2)
                       ELSE
                        pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  pk_lab_tests_constant.g_analysis_group_alias,
                                                                  'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' ||
                                                                  ard.id_analysis_group,
                                                                  NULL)
                   END
              INTO o_task_desc
              FROM analysis_req_det ard
             WHERE ((ard.id_analysis_req = i_task_request AND i_task_request_det IS NULL) OR
                   (ard.id_analysis_req_det = i_task_request_det AND i_task_request IS NULL))
             GROUP BY ard.id_analysis_group;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_title;

    FUNCTION get_lab_test_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT 'Y',
        i_flg_group_type    IN VARCHAR2 DEFAULT NULL,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER := 0;
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('LAB_TESTS_T048',
                                                        'LAB_TESTS_T168',
                                                        'LAB_TESTS_T017',
                                                        'LAB_TESTS_T022',
                                                        'LAB_TESTS_T025',
                                                        'LAB_TESTS_T028',
                                                        'LAB_TESTS_T030',
                                                        'COMMON_M112');
    
        l_msg_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAM_REQ_M002');
        l_urgency    pk_translation.t_desc_translation;
        l_lab_date   pk_translation.t_desc_translation;
        l_recurrence pk_translation.t_desc_translation;
        l_prn        pk_translation.t_desc_translation;
        l_flg_prn    VARCHAR2(1 CHAR);
        l_fasting    pk_translation.t_desc_translation;
        l_room       pk_translation.t_desc_translation;
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i)) || ' ';
        END LOOP;
    
        SELECT COUNT(ard.id_analysis_req_det)
          INTO l_count
          FROM analysis_req_det ard
         WHERE ((ard.id_analysis_req = i_task_request AND i_task_request_det IS NULL) OR
               (ard.id_analysis_req_det = i_task_request_det AND i_task_request IS NULL));
    
        g_error := 'Fetch instructions for id_analysis_req: ' || i_task_request;
        BEGIN
            SELECT DISTINCT decode(ard.flg_urgency,
                                   NULL,
                                   NULL,
                                   aa_code_messages('LAB_TESTS_T048') ||
                                   pk_sysdomain.get_domain(i_lang,
                                                           i_prof,
                                                           'ANALYSIS_REQ_DET.FLG_URGENCY',
                                                           ard.flg_urgency,
                                                           NULL) || '; ') urgency,
                            decode(i_flg_showdate,
                                   pk_alert_constant.g_yes,
                                   aa_code_messages('LAB_TESTS_T168') ||
                                   decode(ard.flg_time_harvest,
                                          pk_lab_tests_constant.g_flg_time_e,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'ANALYSIS_REQ_DET.FLG_TIME_HARVEST',
                                                                  ard.flg_time_harvest,
                                                                  NULL) ||
                                          decode(ard.dt_target_tstz,
                                                 NULL,
                                                 '',
                                                 ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                     ard.dt_target_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || ')'),
                                          pk_lab_tests_constant.g_flg_time_b,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'ANALYSIS_REQ_DET.FLG_TIME_HARVEST',
                                                                  ard.flg_time_harvest,
                                                                  NULL) ||
                                          decode(ard.dt_target_tstz,
                                                 NULL,
                                                 decode(ard.dt_schedule,
                                                        NULL,
                                                        '',
                                                        '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                            ard.dt_schedule,
                                                                                            i_prof.institution,
                                                                                            i_prof.software) || ' ' ||
                                                        l_msg_date),
                                                 ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                     ard.dt_target_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || ')'),
                                          pk_lab_tests_constant.g_flg_time_d,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'ANALYSIS_REQ_DET.FLG_TIME_HARVEST',
                                                                  ard.flg_time_harvest,
                                                                  NULL) ||
                                          decode(ard.dt_target_tstz,
                                                 NULL,
                                                 decode(ard.dt_schedule,
                                                        NULL,
                                                        '',
                                                        '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                            ard.dt_schedule,
                                                                                            i_prof.institution,
                                                                                            i_prof.software) || ' ' ||
                                                        l_msg_date),
                                                 ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                     ard.dt_target_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || ')'),
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'ANALYSIS_REQ_DET.FLG_TIME_HARVEST',
                                                                  ard.flg_time_harvest,
                                                                  NULL)) || '; ') lab_date,
                            decode(ard.id_order_recurrence,
                                   NULL,
                                   NULL,
                                   aa_code_messages('LAB_TESTS_T017') ||
                                   pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                         i_prof,
                                                                                         ard.id_order_recurrence,
                                                                                         pk_alert_constant.g_no) || '; ') recurrence,
                            decode(ard.flg_prn,
                                   NULL,
                                   NULL,
                                   aa_code_messages('LAB_TESTS_T022') ||
                                   pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_PRN', ard.flg_prn, i_lang) || '; ') pnr_desc,
                            ard.flg_prn,
                            decode(ard.flg_fasting,
                                   NULL,
                                   NULL,
                                   aa_code_messages('LAB_TESTS_T025') ||
                                   pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_FASTING', ard.flg_fasting, i_lang) || '; ') fasting,
                            decode(l_count,
                                   1,
                                   decode(ard.id_room,
                                          NULL,
                                          aa_code_messages('LAB_TESTS_T030') ||
                                          pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_COL_INST',
                                                                  ard.flg_col_inst,
                                                                  i_lang),
                                          aa_code_messages('LAB_TESTS_T030') ||
                                          nvl((SELECT r.desc_room
                                                FROM room r
                                               WHERE r.id_room = ard.id_room),
                                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || ard.id_room))),
                                   NULL) room
              INTO l_urgency, l_lab_date, l_recurrence, l_prn, l_flg_prn, l_fasting, l_room
              FROM analysis_req_det ard
             WHERE ((ard.id_analysis_req = i_task_request AND i_task_request_det IS NULL) OR
                   (ard.id_analysis_req_det = i_task_request_det AND i_task_request IS NULL));
        
            IF i_flg_group_type = 'I'
            THEN
                o_task_instructions := l_urgency || l_lab_date || l_recurrence;
                IF l_flg_prn = pk_alert_constant.g_yes
                THEN
                    o_task_instructions := o_task_instructions || aa_code_messages('COMMON_M112');
                END IF;
            ELSE
                o_task_instructions := l_urgency || l_lab_date || l_recurrence || l_prn || l_fasting || l_room;
            END IF;
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_instructions;

    FUNCTION get_lab_test_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_labtest_desc     OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch alias_translation for id_analysis_req_det: ' || i_analysis_req_det;
        SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         pk_lab_tests_constant.g_analysis_alias,
                                                         'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type,
                                                         NULL),
               pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ_DET.FLG_STATUS', ard.flg_status, NULL)
          INTO o_labtest_desc, o_task_status_desc
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det = i_analysis_req_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_TASK_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_description;

    FUNCTION get_lab_test_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        SELECT lte.flg_status_det flg_status,
               pk_utils.get_status_string(i_lang,
                                          i_prof,
                                          lte.status_str,
                                          lte.status_msg,
                                          lte.status_icon,
                                          lte.status_flg) status_string
          INTO o_flg_status, o_status_string
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det = i_task_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_status;

    FUNCTION get_lab_test_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_analysis    analysis_req_det.id_analysis%TYPE;
        l_id_sample_type analysis_req_det.id_sample_type%TYPE;
        l_id_room        analysis_req_det.id_room%TYPE;
        l_flg_type       VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'GET PREDEFINED LAB TEST INFO';
        SELECT coalesce(ar.id_analysis_group, ard.id_analysis) AS id_analysis,
               nvl2(ar.id_analysis_group, NULL, ard.id_sample_type) AS id_sample_type,
               nvl2(ar.id_analysis_group, NULL, ard.id_room) AS id_room,
               nvl2(ar.id_analysis_group, 'G', 'A') AS flg_type
          INTO l_id_analysis, l_id_sample_type, l_id_room, l_flg_type
          FROM analysis_req ar, analysis_req_det ard
         WHERE ar.id_analysis_req = i_task_request
           AND ar.id_analysis_req = ard.id_analysis_req
           AND rownum = 1;
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_QUESTIONNAIRE';
        IF NOT pk_lab_tests_core.get_lab_test_questionnaire(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_patient     => i_patient,
                                                            i_episode     => i_episode,
                                                            i_analysis    => l_id_analysis,
                                                            i_sample_type => l_id_sample_type,
                                                            i_room        => l_id_room,
                                                            i_flg_type    => l_flg_type,
                                                            i_flg_time    => pk_lab_tests_constant.g_analysis_cq_on_order,
                                                            o_list        => o_list,
                                                            o_error       => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'GET_LAB_TEST_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_questionnaire;

    FUNCTION get_lab_test_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT ard.id_analysis_req, ard.dt_target_tstz, NULL dt_end
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            *
                                             FROM TABLE(i_task_request) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_DATE_LIMITS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_date_limits;

    FUNCTION get_lab_test_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_id      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Fetch lab test id for id_analysis_req: ' || i_task_request;
        SELECT ard.id_analysis || '|' || ard.id_sample_type
          INTO o_lab_test_id
          FROM analysis_req_det ard
         WHERE ((ard.id_analysis_req = i_task_request AND i_task_request_det IS NULL) OR
               (ard.id_analysis_req_det = i_task_request_det AND i_task_request IS NULL));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_TASK_ID',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_id;

    FUNCTION set_lab_test_request_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_task_request            IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN analysis_req_det.id_cdr%TYPE,
        i_task_dependency         IN table_number,
        i_flg_task_dependency     IN table_varchar,
        o_analysis_req            OUT table_number,
        o_analysis_req_det        OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_req IS
            SELECT ar.*
              FROM analysis_req ar
             WHERE ar.id_analysis_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           *
                                            FROM TABLE(i_task_request) t);
    
        CURSOR c_analysis_req_det(in_analysis_req analysis_req.id_analysis_req%TYPE) IS
            SELECT ard.*
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req = in_analysis_req;
    
        TYPE t_analysis_req IS TABLE OF c_analysis_req%ROWTYPE;
        t_tbl_analysis_req t_analysis_req;
    
        TYPE t_analysis_req_det IS TABLE OF c_analysis_req_det%ROWTYPE;
        t_tbl_analysis_req_det t_analysis_req_det;
    
        l_order_criteria        sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_ORDER_CRITERIA', i_prof);
        l_order_limit           sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_ORDER_LIMIT', i_prof);
        l_order_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_ORDER_FILTER_INTERVAL',
                                                                                 i_prof);
        l_order_aggregate       sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_ORDER_AGGREGATE', i_prof);
        l_order_exam_cat_parent sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_ORDER_EXAM_CAT_PARENT',
                                                                                 i_prof);
    
        l_analysis_req_array table_number := table_number();
        l_analysis_det_array table_number := table_number();
    
        l_analysis_order analysis_req.id_analysis_req%TYPE;
        l_dt_begin       VARCHAR2(100 CHAR);
        l_exam_cat       exam_cat.id_exam_cat%TYPE;
    
        l_codification codification.id_codification%TYPE;
    
        l_analysis_req     analysis_req.id_analysis_req%TYPE;
        l_analysis_req_det analysis_req_det.id_analysis_req_det%TYPE;
        l_analysis_req_par table_number := table_number();
    
        l_count_out_reqs NUMBER := 0;
        l_req_det_idx    NUMBER;
    
        TYPE t_record_analysis_req_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_analysis_req_map t_record_analysis_req_map;
    
        l_all_analysis_req_det table_number := table_number();
    
        l_order_recurrence_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        l_order_recurr_final_array table_number := table_number();
        l_order_plan               t_tbl_order_recurr_plan;
        l_order_plan_aux           t_tbl_order_recurr_plan;
        l_exec_to_process          t_tbl_order_recurr_plan_sts;
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_analysis            analysis_req_det.id_analysis%TYPE;
        l_sample_type         analysis_req_det.id_sample_type%TYPE;
        l_flg_time            analysis_req.flg_time%TYPE;
        l_flg_priority        analysis_req.flg_priority%TYPE;
        l_flg_prn             analysis_req_det.flg_prn%TYPE;
        l_room                analysis_req_det.id_room%TYPE;
        l_id_exec_institution analysis_req.id_exec_institution%TYPE;
        l_flg_col_inst        analysis_req_det.flg_col_inst%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        o_analysis_req     := table_number();
        o_analysis_req_det := table_table_number();
    
        g_error := 'OPEN C_ANALYSIS_REQ';
        OPEN c_analysis_req;
        FETCH c_analysis_req BULK COLLECT
            INTO t_tbl_analysis_req;
        CLOSE c_analysis_req;
    
        FOR i IN 1 .. t_tbl_analysis_req.count
        LOOP
            OPEN c_analysis_req_det(t_tbl_analysis_req(i).id_analysis_req);
            FETCH c_analysis_req_det BULK COLLECT
                INTO t_tbl_analysis_req_det;
            CLOSE c_analysis_req_det;
        
            o_analysis_req_det.extend;
            o_analysis_req_det(o_analysis_req_det.count) := table_number();
        
            -- creating analysis_req_det
            FOR j IN 1 .. t_tbl_analysis_req_det.count
            LOOP
                -- check if this analysis_req_det has an order recurrence plan
                IF t_tbl_analysis_req_det(j).id_order_recurrence IS NOT NULL
                THEN
                
                    -- get order recurrence option
                    IF NOT pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                    i_prof                => i_prof,
                                                                                    i_order_plan          => t_tbl_analysis_req_det(j).id_order_recurrence,
                                                                                    o_order_recurr_desc   => l_order_recurr_desc,
                                                                                    o_order_recurr_option => l_order_recurr_option,
                                                                                    o_start_date          => l_start_date,
                                                                                    o_occurrences         => l_occurrences,
                                                                                    o_duration            => l_duration,
                                                                                    o_unit_meas_duration  => l_unit_meas_duration,
                                                                                    o_duration_desc       => l_duration_desc,
                                                                                    o_end_date            => l_end_date,
                                                                                    o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                    o_error               => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- if recurrence option is once ou schedule, then delete reference
                    IF l_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_once
                       OR l_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
                    THEN
                        g_error := 'UPDATE ANALYSIS_REQ_DET';
                        ts_analysis_req_det.upd(id_analysis_req_det_in  => t_tbl_analysis_req_det(j).id_analysis_req_det,
                                                id_order_recurrence_in  => NULL,
                                                id_order_recurrence_nin => FALSE,
                                                rows_out                => l_rows_out);
                    END IF;
                
                    g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                    IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                            i_prof                    => i_prof,
                                                                            i_order_recurr_plan       => t_tbl_analysis_req_det(j).id_order_recurrence,
                                                                            o_order_recurr_option     => l_order_recurrence_option,
                                                                            o_final_order_recurr_plan => t_tbl_analysis_req_det(j).id_order_recurrence,
                                                                            o_error                   => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF t_tbl_analysis_req_det(j).id_order_recurrence IS NOT NULL
                    THEN
                    
                        l_order_recurr_final_array.extend;
                        l_order_recurr_final_array(l_order_recurr_final_array.count) := t_tbl_analysis_req_det(j).id_order_recurrence;
                    END IF;
                END IF;
            
                IF l_analysis_req IS NULL
                THEN
                    IF l_order_aggregate = pk_lab_tests_constant.g_yes
                    THEN
                        g_error := 'Selects available requests';
                        SELECT ar.id_analysis_req, ard.id_analysis_req_det
                          BULK COLLECT
                          INTO l_analysis_req_array, l_analysis_det_array
                          FROM analysis_req ar, analysis_req_det ard
                         WHERE ar.id_patient = t_tbl_analysis_req(i).id_patient
                           AND ar.id_visit = t_tbl_analysis_req(i).id_visit
                           AND ard.id_analysis_req = ar.id_analysis_req
                           AND ar.flg_time != pk_lab_tests_constant.g_flg_time_r
                           AND ar.flg_status IN (pk_lab_tests_constant.g_analysis_sched,
                                                 pk_lab_tests_constant.g_analysis_pending,
                                                 pk_lab_tests_constant.g_analysis_tosched,
                                                 pk_lab_tests_constant.g_analysis_req,
                                                 pk_lab_tests_constant.g_analysis_sos,
                                                 pk_lab_tests_constant.g_analysis_exterior)
                           AND ((instr(l_order_criteria, 'D') != 0 AND
                               pk_date_utils.compare_dates_tsz(i_prof,
                                                                 pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                  nvl(pk_date_utils.add_days_to_tstz(ar.dt_begin_tstz,
                                                                                                                                     l_order_filter_interval),
                                                                                                      g_sysdate_tstz),
                                                                                                  'MI'),
                                                                 pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                  t_tbl_analysis_req_det(j).dt_target_tstz,
                                                                                                  'MI')) IN
                               (pk_alert_constant.g_date_greater, pk_alert_constant.g_date_equal)) OR
                               (instr(l_order_criteria, 'D') = 0 AND pk_date_utils.compare_dates_tsz(i_prof,
                                                                                                      pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                                       nvl(ar.dt_begin_tstz,
                                                                                                                                           g_sysdate_tstz),
                                                                                                                                       'MI'),
                                                                                                      pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                                       t_tbl_analysis_req_det(j).dt_target_tstz,
                                                                                                                                       'MI')) =
                               pk_alert_constant.g_date_equal));
                    END IF;
                
                    IF l_analysis_det_array.count > 0
                    THEN
                        l_analysis_req := -1;
                    END IF;
                END IF;
            
                g_error := 'COMPARE DATES';
                IF pk_date_utils.compare_dates_tsz(i_prof,
                                                   pk_date_utils.trunc_insttimezone(i_prof,
                                                                                    t_tbl_analysis_req_det(j).dt_target_tstz,
                                                                                    'MI'),
                                                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'MI')) =
                   pk_alert_constant.g_date_lower
                THEN
                    l_dt_begin := g_sysdate_char;
                ELSE
                    l_dt_begin := pk_date_utils.date_send_tsz(i_lang, t_tbl_analysis_req_det(j).dt_target_tstz, i_prof);
                END IF;
            
                IF l_analysis_req IS NULL
                THEN
                    l_analysis_req := ts_analysis_req.next_key();
                ELSE
                    g_error := 'SELECT ANALYSIS_INSTIT_SOFT';
                    SELECT decode(l_order_exam_cat_parent,
                                  pk_lab_tests_constant.g_yes,
                                  (SELECT pk_lab_tests_utils.get_lab_test_category(i_lang, i_prof, ais.id_exam_cat)
                                     FROM dual),
                                  ais.id_exam_cat) id_exam_cat
                      INTO l_exam_cat
                      FROM analysis_instit_soft ais
                     WHERE ais.id_analysis = t_tbl_analysis_req_det(j).id_analysis
                       AND ais.id_sample_type = t_tbl_analysis_req_det(j).id_sample_type
                       AND ais.id_institution = i_prof.institution
                       AND ais.id_software = i_prof.software
                       AND ais.flg_available = pk_lab_tests_constant.g_yes;
                
                    BEGIN
                        g_error := 'GET L_ANALYSIS_ORDER 1';
                        SELECT a.id_analysis_req
                          INTO l_analysis_order
                          FROM (SELECT ard.id_analysis_req,
                                       CASE
                                            WHEN pk_date_utils.compare_dates_tsz(i_prof,
                                                                                 ard.dt_begin,
                                                                                 pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                  g_sysdate_tstz,
                                                                                                                  'MI')) =
                                                 pk_alert_constant.g_date_lower THEN
                                             g_sysdate_tstz
                                            ELSE
                                             ard.dt_begin
                                        END dt_begin
                                  FROM (SELECT ard.id_analysis_req,
                                               pk_date_utils.trunc_insttimezone(i_prof, ard.dt_target_tstz, 'MI') dt_begin
                                          FROM analysis_req_det ard
                                         WHERE ard.id_analysis_req_det IN
                                               (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(l_all_analysis_req_det) t
                                                UNION
                                                SELECT /*+opt_estimate (table t1 rows=2)*/
                                                 *
                                                  FROM TABLE(l_analysis_det_array) t1)) ard,
                                       (SELECT first_value(ard.id_analysis_req) over(ORDER BY ard.id_analysis_req DESC) id_analysis_req
                                          FROM analysis_req_det ard
                                         WHERE ard.id_analysis_req IN
                                               (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(o_analysis_req) t
                                                UNION
                                                SELECT /*+opt_estimate (table t1 rows=2)*/
                                                 *
                                                  FROM TABLE(l_analysis_req_array) t1)
                                           AND ard.flg_time_harvest = t_tbl_analysis_req_det(j).flg_time_harvest
                                           AND ard.flg_urgency = t_tbl_analysis_req_det(j).flg_urgency
                                           AND (ard.id_exec_institution = t_tbl_analysis_req_det(j).id_exec_institution OR
                                               (ard.id_exec_institution IS NULL AND t_tbl_analysis_req_det(j).id_exec_institution IS NULL))
                                           AND ((ard.flg_prn = pk_lab_tests_constant.g_yes AND t_tbl_analysis_req_det(j)
                                               .flg_prn = pk_lab_tests_constant.g_yes) OR
                                               (ard.flg_prn = pk_lab_tests_constant.g_no AND t_tbl_analysis_req_det(j)
                                               .flg_prn = pk_lab_tests_constant.g_no))
                                           AND ((ard.id_sample_type = t_tbl_analysis_req_det(j).id_sample_type AND
                                               instr(l_order_criteria, 'S') != 0) OR instr(l_order_criteria, 'S') = 0)
                                           AND ((decode(l_order_exam_cat_parent,
                                                        pk_lab_tests_constant.g_yes,
                                                        (SELECT pk_lab_tests_utils.get_lab_test_category(i_lang,
                                                                                                         i_prof,
                                                                                                         ard.id_exam_cat)
                                                           FROM dual),
                                                        ard.id_exam_cat) = l_exam_cat AND
                                               instr(l_order_criteria, 'C') != 0) OR instr(l_order_criteria, 'C') = 0)
                                           AND ((t_tbl_analysis_req_det(j)
                                               .id_room IS NOT NULL AND ard.id_room = t_tbl_analysis_req_det(j).id_room AND
                                                instr(l_order_criteria, 'R') != 0) OR
                                               (t_tbl_analysis_req_det(j).id_room IS NULL AND
                                                ard.flg_col_inst = t_tbl_analysis_req_det(j).flg_col_inst AND
                                                instr(l_order_criteria, 'R') != 0) OR instr(l_order_criteria, 'R') = 0)
                                         HAVING l_order_limit = 0
                                            OR COUNT(*) < l_order_limit
                                         GROUP BY ard.id_analysis_req) ar
                                 WHERE ard.id_analysis_req = ar.id_analysis_req) a
                         WHERE ((l_dt_begin IS NOT NULL AND l_order_aggregate = pk_alert_constant.g_no AND
                               pk_date_utils.compare_dates_tsz(i_prof,
                                                                 a.dt_begin,
                                                                 pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                  pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                i_prof,
                                                                                                                                l_dt_begin,
                                                                                                                                NULL),
                                                                                                  'MI')) =
                               pk_alert_constant.g_date_equal) OR
                               (l_dt_begin IS NOT NULL AND l_order_aggregate = pk_alert_constant.g_yes) OR
                               (l_dt_begin IS NULL AND t_tbl_analysis_req_det(j)
                               .flg_time_harvest != pk_lab_tests_constant.g_flg_time_e))
                           AND rownum = 1;
                    
                        l_analysis_req := l_analysis_order;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            IF t_tbl_analysis_req_det(j).id_analysis_group IS NULL
                            THEN
                                l_analysis_req := ts_analysis_req.next_key();
                            ELSE
                                BEGIN
                                    g_error := 'GET L_ANALYSIS_ORDER 2';
                                    SELECT id_analysis_req
                                      INTO l_analysis_order
                                      FROM (SELECT first_value(ard.id_analysis_req) over(ORDER BY ard.id_analysis_req DESC) id_analysis_req
                                              FROM analysis_req_det ard
                                             WHERE ard.id_analysis_req_det IN
                                                   (SELECT /*+opt_estimate (table t rows=1)*/
                                                     *
                                                      FROM TABLE(l_all_analysis_req_det) t)
                                               AND ard.id_analysis_group = t_tbl_analysis_req_det(j).id_analysis_group
                                             HAVING l_order_limit = 0
                                                OR COUNT(*) < l_order_limit
                                             GROUP BY ard.id_analysis_req)
                                     WHERE rownum = 1;
                                
                                    l_analysis_req := l_analysis_order;
                                
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_analysis_req := ts_analysis_req.next_key();
                                END;
                            END IF;
                    END;
                END IF;
            
                BEGIN
                    SELECT ac.id_codification
                      INTO l_codification
                      FROM analysis_codification ac
                     WHERE ac.id_analysis_codification = t_tbl_analysis_req_det(j).id_analysis_codification;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_codification := NULL;
                END;
            
                g_error := 'CALL CREATE_LAB_TEST_REQUEST';
                IF NOT pk_lab_tests_core.create_lab_test_request(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_patient                 => t_tbl_analysis_req(i).id_patient,
                                                                 i_episode                 => t_tbl_analysis_req(i).id_episode,
                                                                 i_analysis_req            => l_analysis_req,
                                                                 i_analysis_req_det        => NULL,
                                                                 i_analysis_req_det_parent => NULL,
                                                                 i_harvest                 => NULL,
                                                                 i_analysis                => t_tbl_analysis_req_det(j).id_analysis,
                                                                 i_analysis_group          => t_tbl_analysis_req_det(j).id_analysis_group,
                                                                 i_dt_req                  => NULL,
                                                                 i_flg_time                => t_tbl_analysis_req_det(j).flg_time_harvest,
                                                                 i_dt_begin                => l_dt_begin,
                                                                 i_dt_begin_limit          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                          t_tbl_analysis_req_det(j).dt_final_target_tstz,
                                                                                                                          i_prof),
                                                                 i_episode_destination     => t_tbl_analysis_req(i).id_episode_destination,
                                                                 i_order_recurrence        => t_tbl_analysis_req_det(j).id_order_recurrence,
                                                                 i_priority                => t_tbl_analysis_req_det(j).flg_urgency,
                                                                 i_flg_prn                 => t_tbl_analysis_req_det(j).flg_prn,
                                                                 i_notes_prn               => t_tbl_analysis_req_det(j).notes_prn,
                                                                 i_specimen                => t_tbl_analysis_req_det(j).id_sample_type,
                                                                 i_body_location           => table_number(NULL),
                                                                 i_laterality              => table_varchar(NULL),
                                                                 i_collection_room         => t_tbl_analysis_req_det(j).id_room,
                                                                 i_notes                   => t_tbl_analysis_req_det(j).notes,
                                                                 i_notes_scheduler         => t_tbl_analysis_req_det(j).notes_scheduler,
                                                                 i_notes_technician        => t_tbl_analysis_req_det(j).notes_tech,
                                                                 i_notes_patient           => t_tbl_analysis_req_det(j).notes_patient,
                                                                 i_diagnosis_notes         => t_tbl_analysis_req_det(j).diagnosis_notes,
                                                                 i_diagnosis               => NULL,
                                                                 i_exec_institution        => t_tbl_analysis_req_det(j).id_exec_institution,
                                                                 i_clinical_purpose        => t_tbl_analysis_req_det(j).id_clinical_purpose,
                                                                 i_clinical_purpose_notes  => t_tbl_analysis_req_det(j).clinical_purpose_notes,
                                                                 i_flg_col_inst            => t_tbl_analysis_req_det(j).flg_col_inst,
                                                                 i_flg_fasting             => t_tbl_analysis_req_det(j).flg_fasting,
                                                                 i_lab_req                 => t_tbl_analysis_req_det(j).id_room_req,
                                                                 i_prof_cc                 => table_varchar(NULL),
                                                                 i_prof_bcc                => table_varchar(NULL),
                                                                 i_codification            => l_codification,
                                                                 i_health_plan             => t_tbl_analysis_req_det(j).id_pat_health_plan,
                                                                 i_exemption               => t_tbl_analysis_req_det(j).id_pat_exemption,
                                                                 i_prof_order              => i_prof_order(i),
                                                                 i_dt_order                => i_dt_order(i),
                                                                 i_order_type              => i_order_type(i),
                                                                 i_clinical_question       => i_clinical_question(i),
                                                                 i_response                => i_response(i),
                                                                 i_clinical_question_notes => i_clinical_question_notes(i),
                                                                 i_clinical_decision_rule  => t_tbl_analysis_req_det(j).id_cdr,
                                                                 --i_flg_origin_req          => null,
                                                                 i_task_dependency       => i_task_dependency(i),
                                                                 i_flg_task_depending    => i_flg_task_dependency(i),
                                                                 i_episode_followup_app  => NULL,
                                                                 i_schedule_followup_app => NULL,
                                                                 i_event_followup_app    => NULL,
                                                                 o_analysis_req          => l_analysis_req,
                                                                 o_analysis_req_det      => l_analysis_req_det,
                                                                 o_analysis_req_par      => l_analysis_req_par,
                                                                 o_error                 => o_error)
                THEN
                    IF o_error.err_desc IS NOT NULL
                    THEN
                        g_error_code := o_error.ora_sqlcode;
                        g_error      := o_error.ora_sqlerrm;
                    
                        RAISE g_user_exception;
                    ELSE
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                -- check if analysis_req not exists
                IF NOT ibt_analysis_req_map.exists(to_char(l_analysis_req))
                THEN
                    o_analysis_req.extend;
                    l_count_out_reqs := l_count_out_reqs + 1;
                
                    -- set mapping between analysis_req and its position in the output array
                    ibt_analysis_req_map(to_char(l_analysis_req)) := l_count_out_reqs;
                
                    -- set analysis_req output 
                    o_analysis_req(l_count_out_reqs) := l_analysis_req;
                
                END IF;
            
                -- append req det of this lab test request to all req dets array
                l_all_analysis_req_det.extend;
                l_all_analysis_req_det(l_all_analysis_req_det.count) := l_analysis_req_det;
            
                l_req_det_idx := o_analysis_req_det.count;
                o_analysis_req_det(l_req_det_idx).extend;
                o_analysis_req_det(l_req_det_idx)(o_analysis_req_det(l_req_det_idx).count) := l_analysis_req_det;
            
            END LOOP;
        END LOOP;
    
        FOR i IN 1 .. l_all_analysis_req_det.count
        LOOP
            g_error := 'UPDATE ANALYSIS_REQ_DET';
            ts_analysis_req_det.upd(id_analysis_req_det_in   => l_all_analysis_req_det(i),
                                    flg_req_origin_module_in => pk_alert_constant.g_task_origin_order_set,
                                    rows_out                 => l_rows_out);
        END LOOP;
    
        g_error := 'CALL TO PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_DELETE_TASK';
        IF NOT pk_lab_tests_external.set_lab_test_delete_task(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_task_request => i_task_request,
                                                              o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- create recurrence labs
        IF l_order_recurr_final_array IS NOT NULL
           OR l_order_recurr_final_array.count > 0
        THEN
            g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
            IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_order_plan      => l_order_recurr_final_array,
                                                                        o_order_plan_exec => l_order_plan,
                                                                        o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- removing first element (first req was already created)
            SELECT t_rec_order_recurr_plan(t.id_order_recurrence_plan, t.exec_number, t.exec_timestamp)
              BULK COLLECT
              INTO l_order_plan_aux
              FROM TABLE(CAST(l_order_plan AS t_tbl_order_recurr_plan)) t
             WHERE t.exec_number > 1;
        
            IF l_order_plan_aux.count > 0
            THEN
            
                g_error := 'CALL PK_LAB_TESTS_CORE.CREATE_LAB_TEST_RECURRENCE';
                IF NOT pk_lab_tests_core.create_lab_test_recurrence(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_exec_tab        => l_order_plan_aux,
                                                                    o_exec_to_process => l_exec_to_process,
                                                                    o_error           => o_error)
                THEN
                    IF o_error.err_desc IS NOT NULL
                    THEN
                        g_error_code := o_error.ora_sqlcode;
                        g_error      := o_error.ora_sqlerrm;
                    
                        RAISE g_user_exception;
                    ELSE
                        RAISE g_other_exception;
                    END IF;
                END IF;
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
                                              'SET_LAB_TEST_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_request_task;

    FUNCTION set_lab_test_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_analysis_req OUT analysis_req.id_analysis_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req     analysis_req%ROWTYPE;
        l_analysis_req_det analysis_req_det%ROWTYPE;
    
        l_analysis_harvest analysis_harvest%ROWTYPE;
        l_harvest          harvest%ROWTYPE;
    
        l_rows_out     table_varchar := table_varchar();
        l_rows_req_out table_varchar := table_varchar();
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_flg_time VARCHAR2(1 CHAR);
        error_unexpected EXCEPTION;
    
        -- function that returns the default value for "to be performed" field
        FUNCTION get_default_flg_time
        (
            i_lang  IN language.id_language%TYPE,
            i_prof  IN profissional,
            o_error OUT t_error_out
        ) RETURN VARCHAR2 IS
        
            l_epis_type   epis_type.id_epis_type%TYPE := pk_episode.get_epis_type(i_lang    => i_lang,
                                                                                  i_id_epis => i_episode);
            c_data        pk_types.cursor_type;
            l_val         sys_domain.val%TYPE;
            l_rank        NUMBER;
            l_desc_val    sys_domain.desc_val%TYPE;
            l_flg_default VARCHAR2(1 CHAR);
        
        BEGIN
            -- gets default value for "to be performed" field
            g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_TIME_LIST';
            IF NOT pk_lab_tests_core.get_lab_test_time_list(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_epis_type => l_epis_type,
                                                            o_list      => c_data,
                                                            o_error     => o_error)
            THEN
                RAISE error_unexpected;
            END IF;
        
            -- loop until fetch default value
            LOOP
                FETCH c_data
                    INTO l_val, l_rank, l_desc_val, l_flg_default;
            
                EXIT WHEN l_flg_default = pk_lab_tests_constant.g_yes OR c_data%NOTFOUND;
            
            END LOOP;
            CLOSE c_data;
        
            RETURN l_val;
        END;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET ANALYSIS_REQ';
        SELECT ar.*
          INTO l_analysis_req
          FROM analysis_req ar
         WHERE ar.id_analysis_req = i_task_request;
    
        l_analysis_req.id_analysis_req := ts_analysis_req.next_key();
    
        -- gets default value for "to be performed" field
        l_flg_time := get_default_flg_time(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
        --Duplicate row to analysis_req
        g_error := 'INSERT ANALYSIS_REQ';
        ts_analysis_req.ins(rec_in => l_analysis_req, gen_pky_in => FALSE, rows_out => l_rows_req_out);
    
        IF i_patient IS NOT NULL
           AND i_episode IS NOT NULL
        THEN
            ts_analysis_req.upd(id_analysis_req_in => l_analysis_req.id_analysis_req,
                                id_patient_in      => i_patient,
                                id_episode_in      => i_episode,
                                flg_time_in        => l_flg_time,
                                id_visit_in        => pk_visit.get_visit(i_episode, o_error),
                                rows_out           => l_rows_req_out);
        END IF;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_REQ',
                                      i_rowids     => l_rows_req_out,
                                      o_error      => o_error);
    
        l_rows_req_out := NULL;
    
        FOR rec_ard IN (SELECT ard.id_analysis_req_det
                          FROM analysis_req_det ard
                         WHERE ard.id_analysis_req = i_task_request)
        LOOP
            l_rows_out := NULL;
        
            g_error := 'GET ANALYSIS_REQ_DET';
            SELECT ard.*
              INTO l_analysis_req_det
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = rec_ard.id_analysis_req_det;
        
            -- check if this analysis_req_det has an order recurrence plan
            IF l_analysis_req_det.id_order_recurrence IS NOT NULL
            THEN
            
                -- copy order recurrence plan
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.COPY_FROM_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                              i_prof                   => i_prof,
                                                                              i_order_recurr_area      => NULL,
                                                                              i_order_recurr_plan_from => l_analysis_req_det.id_order_recurrence,
                                                                              i_flg_force_temp_plan    => pk_alert_constant.g_no,
                                                                              o_order_recurr_desc      => l_order_recurr_desc,
                                                                              o_order_recurr_option    => l_order_recurr_option,
                                                                              o_start_date             => l_start_date,
                                                                              o_occurrences            => l_occurrences,
                                                                              o_duration               => l_duration,
                                                                              o_unit_meas_duration     => l_unit_meas_duration,
                                                                              o_duration_desc          => l_duration_desc,
                                                                              o_end_date               => l_end_date,
                                                                              o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                              o_order_recurr_plan      => l_analysis_req_det.id_order_recurrence,
                                                                              o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                l_start_date := g_sysdate_tstz;
            END IF;
        
            -- update start dates (according to order recurr plan)            
            l_analysis_req.dt_begin_tstz := l_start_date;
        
            ts_analysis_req.upd(id_analysis_req_in => l_analysis_req.id_analysis_req,
                                dt_begin_tstz_in   => l_analysis_req.dt_begin_tstz,
                                rows_out           => l_rows_req_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_REQ',
                                          i_rowids     => l_rows_req_out,
                                          o_error      => o_error);
        
            l_analysis_req_det.id_analysis_req_det := ts_analysis_req_det.next_key();
        
            l_analysis_req_det.id_analysis_req  := l_analysis_req.id_analysis_req;
            l_analysis_req_det.dt_target_tstz   := l_start_date;
            l_analysis_req_det.flg_time_harvest := l_flg_time;
        
            --Duplicate row to analysis_req_det
            g_error := 'INSERT ANALYSIS_REQ_DET';
            ts_analysis_req_det.ins(rec_in => l_analysis_req_det, gen_pky_in => FALSE, rows_out => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_REQ_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            FOR rec_h IN (SELECT ah.id_harvest
                            FROM analysis_harvest ah
                           WHERE ah.id_analysis_req_det = rec_ard.id_analysis_req_det)
            LOOP
                l_rows_out := NULL;
            
                g_error := 'GET HARVEST';
                SELECT h.*
                  INTO l_harvest
                  FROM harvest h
                 WHERE h.id_harvest = rec_h.id_harvest;
            
                l_harvest.id_harvest := ts_harvest.next_key();
            
                --Duplicate row to harvest
                g_error := 'INSERT HARVEST';
                ts_harvest.ins(rec_in => l_harvest, gen_pky_in => FALSE, rows_out => l_rows_out);
            
                IF i_patient IS NOT NULL
                   AND i_episode IS NOT NULL
                THEN
                    ts_harvest.upd(id_harvest_in => l_harvest.id_harvest,
                                   id_patient_in => i_patient,
                                   id_episode_in => i_episode,
                                   id_visit_in   => pk_visit.get_visit(i_episode, o_error),
                                   rows_out      => l_rows_out);
                END IF;
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                l_rows_out := NULL;
            
                g_error := 'GET ANALYSIS_HARVEST';
                SELECT ah.*
                  INTO l_analysis_harvest
                  FROM analysis_harvest ah
                 WHERE ah.id_harvest = rec_h.id_harvest;
            
                l_analysis_harvest.id_analysis_harvest := ts_analysis_harvest.next_key();
            
                l_analysis_harvest.id_analysis_req_det := l_analysis_req_det.id_analysis_req_det;
                l_analysis_harvest.id_harvest          := l_harvest.id_harvest;
            
                --Duplicate row to analysis_harvest
                g_error := 'INSERT ANALYSIS_HARVEST';
                ts_analysis_harvest.ins(rec_in => l_analysis_harvest, gen_pky_in => FALSE, rows_out => l_rows_out);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
            END LOOP;
        END LOOP;
    
        o_analysis_req := l_analysis_req.id_analysis_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LAB_TEST_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_copy_task;

    FUNCTION set_lab_test_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req_det table_number;
        l_harvest          table_number;
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
        
            SELECT ard.id_analysis_req_det
              BULK COLLECT
              INTO l_analysis_req_det
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req = i_task_request(i);
        
            FOR j IN 1 .. l_analysis_req_det.count
            LOOP
                SELECT ah.id_harvest
                  BULK COLLECT
                  INTO l_harvest
                  FROM analysis_harvest ah
                 WHERE ah.id_analysis_req_det = l_analysis_req_det(j);
            
                FOR k IN 1 .. l_harvest.count
                LOOP
                    g_error := 'DELETE ANALYSIS_HARVEST';
                    ts_analysis_harvest.del_by(where_clause_in => 'id_harvest = ' || l_harvest(k) ||
                                                                  ' AND id_analysis_req_det = ' ||
                                                                  l_analysis_req_det(j));
                
                    g_error := 'DELETE HARVEST';
                    ts_harvest.del(id_harvest_in => l_harvest(k));
                END LOOP;
            END LOOP;
        
            g_error := 'DELETE ANALYSIS_REQ_PAR';
            DELETE FROM analysis_req_par
             WHERE id_analysis_req_det IN (SELECT id_analysis_req_det
                                             FROM analysis_req_det
                                            WHERE id_analysis_req = i_task_request(i));
        
            g_error := 'DELETE ANALYSIS_REQ_DET';
            ts_analysis_req_det.del_by(where_clause_in => 'id_analysis_req = ' || i_task_request(i));
        
            g_error := 'DELETE ANALYSIS_REQ';
            ts_analysis_req.del(id_analysis_req_in => i_task_request(i));
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LAB_TEST_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_delete_task;

    FUNCTION set_lab_test_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req_det table_number;
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            SELECT ard.id_analysis_req_det
              BULK COLLECT
              INTO l_analysis_req_det
              FROM analysis_req_det ard
             WHERE ard.id_order_recurrence IN (SELECT ard.id_order_recurrence
                                                 FROM analysis_req_det ard
                                                WHERE ard.id_analysis_req = i_task_request(i)
                                                  AND ard.id_order_recurrence IS NOT NULL);
        
            -- bulk collect not launch exception
            IF l_analysis_req_det IS NULL
               OR l_analysis_req_det.count = 0
            THEN
                SELECT ard.id_analysis_req_det
                  BULK COLLECT
                  INTO l_analysis_req_det
                  FROM analysis_req_det ard
                 WHERE ard.id_analysis_req = i_task_request(i);
            END IF;
        
            -- loop through all req dets
            FOR j IN 1 .. l_analysis_req_det.count
            LOOP
                g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAG_NO_COMMIT';
                IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_epis             => i_episode,
                                                                i_diag             => i_diagnosis,
                                                                i_exam_req         => NULL,
                                                                i_analysis_req     => i_task_request(i),
                                                                i_interv_presc     => NULL,
                                                                i_exam_req_det     => NULL,
                                                                i_analysis_req_det => l_analysis_req_det(j),
                                                                i_interv_presc_det => NULL,
                                                                o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LAB_TEST_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_diagnosis;

    FUNCTION set_lab_test_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LAB_TEST_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_execute_time;

    FUNCTION check_lab_test_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_notes_tech sys_config.value%TYPE := pk_sysconfig.get_config('LAB_NOTES_TECH_REQUIRED', i_prof);
        l_tbl_check  table_varchar;
    
    BEGIN
    
        g_error := 'Fetch instructions for id_analysis_req: ' || i_task_request;
        SELECT decode(ard.flg_urgency,
                      NULL,
                      'N',
                      decode(ard.flg_time_harvest,
                             NULL,
                             'N',
                             decode(ard.flg_col_inst,
                                    NULL,
                                    'N',
                                    decode(l_notes_tech, 'Y', decode(ard.notes_tech, NULL, 'N', 'Y'), 'Y'))))
          BULK COLLECT
          INTO l_tbl_check
          FROM analysis_req ar, analysis_req_det ard
         WHERE ar.id_analysis_req = i_task_request
           AND ar.id_analysis_req = ard.id_analysis_req;
    
        -- check if there's no req dets with mandatory fields empty
        FOR i IN 1 .. l_tbl_check.count
        LOOP
            IF l_tbl_check(i) = 'N'
            THEN
                o_check := 'N';
                RETURN TRUE;
            
            END IF;
        END LOOP;
    
        -- all mandatory fields have a value
        o_check := 'Y';
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_MANDATORY_FIELD',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_mandatory_field;

    FUNCTION check_lab_test_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat c_pat%ROWTYPE;
    
        l_prof_access PLS_INTEGER;
    
        l_count          NUMBER := 0;
        l_analysis       analysis.id_analysis%TYPE;
        l_sample_type    sample_type.id_sample_type%TYPE;
        l_analysis_group analysis_req.id_analysis_group%TYPE;
    
    BEGIN
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        g_error := 'GET PROF ACCESS';
        BEGIN
            SELECT COUNT(1)
              INTO l_prof_access
              FROM group_access_prof gaf
             INNER JOIN group_access ga
                ON gaf.id_group_access = ga.id_group_access
             WHERE gaf.id_professional = i_prof.id
               AND gaf.flg_available = pk_lab_tests_constant.g_available
               AND ga.id_institution IN (i_prof.institution, 0)
               AND ga.id_software IN (i_prof.software, 0)
               AND ga.flg_available = pk_lab_tests_constant.g_available
               AND ga.flg_type = 'A';
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_access := 0;
        END;
    
        BEGIN
            SELECT ar.id_analysis_group
              INTO l_analysis_group
              FROM analysis_req ar
             WHERE ar.id_analysis_req = i_task_request
               AND ar.id_analysis_group IS NOT NULL;
        
            g_error := 'TEST ID_GROUP_ANALYSIS';
            SELECT COUNT(ag.id_analysis_group)
              INTO l_count
              FROM analysis_group ag,
                   analysis_agp aa,
                   (SELECT *
                      FROM analysis_instit_soft
                     WHERE flg_type IN (pk_lab_tests_constant.g_analysis_can_req, pk_lab_tests_constant.g_analysis_exec)
                       AND id_software = i_prof.software
                       AND id_institution = i_prof.institution
                       AND flg_available = pk_lab_tests_constant.g_available) ais
             WHERE ag.id_analysis_group = l_analysis_group
               AND ag.id_analysis_group = aa.id_analysis_group
               AND ag.flg_available = pk_lab_tests_constant.g_available
               AND aa.flg_available = pk_lab_tests_constant.g_available
               AND ag.id_analysis_group = ais.id_analysis_group
               AND EXISTS
             (SELECT 1
                      FROM analysis a,
                           (SELECT *
                              FROM analysis_sample_type
                             WHERE flg_available = pk_lab_tests_constant.g_available) ast,
                           (SELECT *
                              FROM analysis_instit_soft
                             WHERE flg_type = pk_lab_tests_constant.g_analysis_can_req
                               AND id_software = i_prof.software
                               AND id_institution = i_prof.institution
                               AND flg_available = pk_lab_tests_constant.g_available) ais,
                           analysis_instit_recipient air,
                           (SELECT *
                              FROM analysis_room
                             WHERE flg_type = pk_lab_tests_constant.g_arm_flg_type_room_tube
                               AND id_institution = i_prof.institution
                               AND flg_available = pk_lab_tests_constant.g_yes
                               AND flg_default = pk_lab_tests_constant.g_yes) ar
                     WHERE a.flg_available = pk_lab_tests_constant.g_available
                       AND a.id_analysis = ast.id_analysis
                       AND ast.id_analysis = ais.id_analysis
                       AND ast.id_sample_type = ais.id_sample_type
                       AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                       AND a.id_analysis = ar.id_analysis
                       AND EXISTS (SELECT 1
                              FROM analysis_param ap
                             WHERE ap.id_software = i_prof.software
                               AND ap.id_institution = i_prof.institution
                               AND ap.flg_available = pk_lab_tests_constant.g_available
                               AND ap.id_analysis = a.id_analysis)
                       AND ast.id_analysis = aa.id_analysis
                       AND ast.id_sample_type = aa.id_sample_type)
               AND (l_prof_access = 0 OR (l_prof_access != 0 AND EXISTS
                    (SELECT 1
                                             FROM analysis_group agroup,
                                                  analysis_agp agp,
                                                  (SELECT DISTINCT gar.id_record id_analysis
                                                     FROM group_access ga
                                                    INNER JOIN group_access_prof gaf
                                                       ON gaf.id_group_access = ga.id_group_access
                                                    INNER JOIN group_access_record gar
                                                       ON gar.id_group_access = ga.id_group_access
                                                    WHERE gaf.id_professional = i_prof.id
                                                      AND ga.id_institution IN (i_prof.institution, 0)
                                                      AND ga.id_software IN (i_prof.software, 0)
                                                      AND ga.flg_type = 'A'
                                                      AND gar.flg_type = 'A'
                                                      AND ga.flg_available = pk_lab_tests_constant.g_available
                                                      AND gaf.flg_available = pk_lab_tests_constant.g_available
                                                      AND gar.flg_available = pk_lab_tests_constant.g_available) acs
                                            WHERE agroup.id_analysis_group = ag.id_analysis_group
                                              AND agp.id_analysis_group = agroup.id_analysis_group
                                              AND agp.id_analysis = acs.id_analysis
                                              AND agp.id_analysis = aa.id_analysis)))
               AND (((l_pat.gender IS NOT NULL AND nvl(ag.gender, 'I') IN ('I', l_pat.gender)) OR l_pat.gender IS NULL OR
                   l_pat.gender = 'I') AND (nvl(l_pat.age, 0) BETWEEN nvl(ag.age_min, 0) AND
                   nvl(ag.age_max, nvl(l_pat.age, 0)) OR nvl(l_pat.age, 0) = 0));
        
        EXCEPTION
            WHEN no_data_found THEN
                FOR i IN (SELECT ard.id_analysis, ard.id_sample_type
                            FROM analysis_req ar, analysis_req_det ard
                           WHERE ar.id_analysis_req = i_task_request
                             AND ar.id_analysis_req = ard.id_analysis_req
                             AND ar.id_analysis_group IS NULL)
                LOOP
                
                    l_analysis    := i.id_analysis;
                    l_sample_type := i.id_sample_type;
                
                    IF l_analysis IS NOT NULL
                       AND l_sample_type IS NOT NULL
                    THEN
                        g_error := 'TEST ID_ANALYSIS';
                        SELECT COUNT(a.id_analysis)
                          INTO l_count
                          FROM analysis a,
                               sample_type st,
                               (SELECT *
                                  FROM analysis_sample_type
                                 WHERE flg_available = pk_lab_tests_constant.g_available) ast,
                               (SELECT *
                                  FROM analysis_instit_soft
                                 WHERE flg_type = pk_lab_tests_constant.g_analysis_can_req
                                   AND id_software = i_prof.software
                                   AND id_institution = i_prof.institution
                                   AND flg_available = pk_lab_tests_constant.g_available) ais,
                               analysis_instit_recipient air,
                               (SELECT *
                                  FROM analysis_room
                                 WHERE flg_type = pk_lab_tests_constant.g_arm_flg_type_room_tube
                                   AND id_institution = i_prof.institution
                                   AND flg_available = pk_lab_tests_constant.g_yes
                                   AND flg_default = pk_lab_tests_constant.g_yes) ar,
                               (SELECT DISTINCT gar.id_record id_analysis
                                  FROM group_access ga
                                 INNER JOIN group_access_prof gaf
                                    ON gaf.id_group_access = ga.id_group_access
                                 INNER JOIN group_access_record gar
                                    ON gar.id_group_access = ga.id_group_access
                                 WHERE gaf.id_professional = i_prof.id
                                   AND ga.id_institution IN (i_prof.institution, 0)
                                   AND ga.id_software IN (i_prof.software, 0)
                                   AND ga.flg_type = 'A'
                                   AND gar.flg_type = 'A'
                                   AND ga.flg_available = pk_lab_tests_constant.g_available
                                   AND gaf.flg_available = pk_lab_tests_constant.g_available
                                   AND gar.flg_available = pk_lab_tests_constant.g_available) acs
                         WHERE a.id_analysis = l_analysis
                           AND a.flg_available = pk_lab_tests_constant.g_available
                           AND st.id_sample_type = l_sample_type
                           AND st.flg_available = pk_lab_tests_constant.g_available
                           AND a.id_analysis = ast.id_analysis
                           AND st.id_sample_type = ast.id_sample_type
                           AND ast.id_analysis = ais.id_analysis
                           AND ast.id_sample_type = ais.id_sample_type
                           AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                           AND a.id_analysis = ar.id_analysis
                           AND a.id_analysis = acs.id_analysis(+)
                           AND EXISTS (SELECT 1
                                  FROM analysis_param ap
                                 WHERE ap.id_software = i_prof.software
                                   AND ap.id_institution = i_prof.institution
                                   AND ap.flg_available = pk_lab_tests_constant.g_available
                                   AND ap.id_analysis = a.id_analysis)
                           AND (l_prof_access = 0 OR (l_prof_access != 0 AND acs.id_analysis IS NOT NULL))
                           AND (((l_pat.gender IS NOT NULL AND nvl(a.gender, 'I') IN ('I', l_pat.gender)) OR
                               l_pat.gender IS NULL OR l_pat.gender = 'I') AND
                               (nvl(l_pat.age, 0) BETWEEN nvl(a.age_min, 0) AND
                               nvl(a.age_max, nvl(l_pat.age, 0)) OR nvl(l_pat.age, 0) = 0));
                    END IF;
                END LOOP;
        END;
    
        IF (l_count = 0)
        THEN
            o_flg_conflict := pk_lab_tests_constant.g_yes;
        
            RETURN TRUE;
        ELSE
            o_flg_conflict := pk_lab_tests_constant.g_no;
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
                                              'CHECK_LAB_TEST_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_conflict;

    FUNCTION check_lab_test_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error      := 'CALL pk_lab_tests_utils.get_lab_test_permission';
        o_flg_cancel := pk_lab_tests_utils.get_lab_test_permission(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_area                => pk_lab_tests_constant.g_analysis_area_lab_tests,
                                                                   i_button              => pk_lab_tests_constant.g_analysis_button_cancel,
                                                                   i_episode             => i_episode,
                                                                   i_analysis_req        => NULL,
                                                                   i_analysis_req_det    => i_task_request,
                                                                   i_flg_current_episode => pk_lab_tests_constant.g_yes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_cancel;

    PROCEDURE medication_______________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_analysis_result_par IN analysis_result_par.dt_analysis_result_par_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_colon CONSTANT VARCHAR2(24 CHAR) := ': ';
        l_comma CONSTANT VARCHAR2(24 CHAR) := ', ';
        l_space CONSTANT VARCHAR2(1 CHAR) := ' ';
    
        l_desc_high_low           pk_translation.t_desc_translation;
        l_desc_analysis_parameter pk_translation.t_desc_translation;
        l_result_value            CLOB;
        l_desc_unit_measure       pk_translation.t_desc_translation;
        l_notes_doctor_registry   analysis_result_par.notes_doctor_registry%TYPE;
        l_result_date             VARCHAR2(1000 CHAR);
    
        l_description VARCHAR2(1000 CHAR);
    
    BEGIN
    
        g_error := 'GET DATA INTO VARS: ' || i_id_analysis_result_par;
        SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         pk_lab_tests_constant.g_analysis_parameter_alias,
                                                         'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                         t.id_analysis_parameter,
                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                         NULL) ||
               decode(t.id_body_part,
                      NULL,
                      NULL,
                      l_comma ||
                      pk_translation.get_translation(i_lang, 'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' || t.id_body_part)) desc_analysis_parameter,
               nvl(t.desc_analysis_result,
                   (t.comparator || t.analysis_result_value_1 || t.separator || t.analysis_result_value_2)),
               nvl(t.desc_unit_measure,
                   pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || t.id_unit_measure)),
               CASE
                   WHEN dbms_lob.getlength(t.desc_analysis_result) < 4000
                        AND pk_utils.is_number(t.desc_analysis_result) = pk_lab_tests_constant.g_yes
                        AND t.analysis_result_value_2 IS NULL THEN
                    CASE
                        WHEN is_lab_result_outside_params(i_lang,
                                                          i_prof,
                                                          'I',
                                                          t.desc_analysis_result,
                                                          t.analysis_result_value_1,
                                                          t.ref_val_min) = pk_alert_constant.g_yes THEN
                         l_space || pk_string_utils.surround(pk_message.get_message(i_lang, 'PN_T057'),
                                                             pk_string_utils.g_pattern_parenthesis)
                        WHEN is_lab_result_outside_params(i_lang,
                                                          i_prof,
                                                          'A',
                                                          t.desc_analysis_result,
                                                          t.analysis_result_value_1,
                                                          t.ref_val_max) = pk_alert_constant.g_yes THEN
                         l_space || pk_string_utils.surround(pk_message.get_message(i_lang, 'PN_T058'),
                                                             pk_string_utils.g_pattern_parenthesis)
                        ELSE
                         decode(t.value, NULL, NULL, l_space || t.value)
                    END
                   ELSE
                    decode(t.value, NULL, NULL, l_space || t.value)
               END,
               CASE
                   WHEN t.notes_doctor_registry IS NOT NULL
                        AND dbms_lob.compare(t.notes_doctor_registry, empty_clob()) != 0 THEN
                    chr(10) || pk_message.get_message(i_lang => i_lang, i_code_mess => 'ANALYSIS_M065') || ' ' ||
                    t.notes_doctor_registry
                   ELSE
                    NULL
               END,
               pk_date_utils.date_char_tsz(i_lang, t.dt_analysis_result_par_tstz, i_prof.institution, i_prof.software)
          INTO l_desc_analysis_parameter,
               l_result_value,
               l_desc_unit_measure,
               l_desc_high_low,
               l_notes_doctor_registry,
               l_result_date
          FROM (SELECT z.id_analysis_parameter,
                       z.desc_analysis_result,
                       z.analysis_result_value_1,
                       z.analysis_result_value_2,
                       z.dt_analysis_result_par_tstz,
                       z.comparator,
                       z.separator,
                       z.id_unit_measure,
                       z.desc_unit_measure,
                       z.dt_analysis_result_tstz,
                       z.id_professional,
                       z.id_analysis_result,
                       z.flg_status_det,
                       z.dt_pend_req,
                       z.dt_target,
                       z.dt_req,
                       z.dt_harvest,
                       z.id_exam_cat,
                       z.ref_val_min,
                       z.ref_val_max,
                       z.id_analysis,
                       z.id_sample_type,
                       z.value,
                       z.notes_doctor_registry,
                       z.id_body_part
                  FROM (SELECT aresp.id_analysis_parameter,
                               aresp.desc_analysis_result,
                               aresp.analysis_result_value_1,
                               aresp.analysis_result_value_2,
                               nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz) dt_analysis_result_par_tstz,
                               aresp.comparator,
                               aresp.separator,
                               aresp.id_unit_measure,
                               aresp.desc_unit_measure,
                               ar.dt_analysis_result_tstz,
                               aresp.id_professional,
                               ar.id_analysis_result,
                               ltea.flg_status_det,
                               ltea.dt_pend_req,
                               ltea.dt_target,
                               ltea.dt_req,
                               h.dt_harvest_tstz dt_harvest,
                               ltea.id_exam_cat,
                               aresp.ref_val_min,
                               aresp.ref_val_max,
                               ltea.id_analysis,
                               ltea.id_sample_type,
                               a.value,
                               aresp.notes_doctor_registry,
                               h.id_body_part
                          FROM lab_tests_ea ltea
                          JOIN analysis_result ar
                            ON ar.id_analysis_req_det = ltea.id_analysis_req_det
                          JOIN analysis_result_par aresp
                            ON aresp.id_analysis_result = ar.id_analysis_result
                          JOIN harvest h
                            ON ar.id_harvest = h.id_harvest
                          LEFT JOIN abnormality a
                            ON a.id_abnormality = aresp.id_abnormality
                           AND a.flg_visible = pk_lab_tests_constant.g_yes
                         WHERE (ltea.flg_status_harvest IS NULL OR
                               ltea.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                           AND aresp.id_analysis_result_par = i_id_analysis_result_par
                           AND nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz) <=
                               i_dt_analysis_result_par
                        UNION ALL
                        --case when there is no request
                        SELECT aresp.id_analysis_parameter,
                               aresp.desc_analysis_result,
                               aresp.analysis_result_value_1,
                               aresp.analysis_result_value_2,
                               nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz) dt_analysis_result_par_tstz,
                               aresp.comparator,
                               aresp.separator,
                               aresp.id_unit_measure,
                               aresp.desc_unit_measure,
                               ar.dt_analysis_result_tstz,
                               aresp.id_professional,
                               ar.id_analysis_result,
                               NULL flg_status_det,
                               NULL dt_pend_req,
                               NULL dt_target,
                               NULL dt_req,
                               h.dt_harvest_tstz dt_harvest,
                               ar.id_exam_cat,
                               aresp.ref_val_min,
                               aresp.ref_val_max,
                               ar.id_analysis,
                               ar.id_sample_type,
                               NULL VALUE,
                               aresp.notes_doctor_registry,
                               NULL id_body_part
                          FROM analysis_result ar
                          JOIN analysis_result_par aresp
                            ON aresp.id_analysis_result = ar.id_analysis_result
                          LEFT JOIN harvest h
                            ON h.id_harvest = ar.id_harvest
                         WHERE aresp.id_analysis_result_par = i_id_analysis_result_par
                           AND nvl(aresp.dt_analysis_result_par_upd, aresp.dt_analysis_result_par_tstz) <=
                               i_dt_analysis_result_par
                           AND NOT EXISTS (SELECT 0
                                  FROM lab_tests_ea ltea
                                 INNER JOIN analysis_result ar1
                                    ON ltea.id_analysis_req_det = ar1.id_analysis_req_det
                                 WHERE ar1.id_analysis_result = ar.id_analysis_result)
                        UNION ALL
                        SELECT aresp.id_analysis_parameter,
                               aresp.desc_analysis_result,
                               aresp.analysis_result_value_1,
                               aresp.analysis_result_value_2,
                               aresp.dt_analysis_result_par_tstz dt_analysis_result_par_tstz,
                               aresp.comparator,
                               aresp.separator,
                               aresp.id_unit_measure,
                               aresp.desc_unit_measure,
                               ar.dt_analysis_result_tstz,
                               aresp.id_professional,
                               ar.id_analysis_result,
                               ltea.flg_status_det,
                               ltea.dt_pend_req,
                               ltea.dt_target,
                               ltea.dt_req,
                               h.dt_harvest_tstz                 dt_harvest,
                               ltea.id_exam_cat,
                               aresp.ref_val_min,
                               aresp.ref_val_max,
                               ltea.id_analysis,
                               ltea.id_sample_type,
                               a.value,
                               aresp.notes_doctor_registry,
                               h.id_body_part
                          FROM lab_tests_ea ltea
                          JOIN analysis_result ar
                            ON ar.id_analysis_req_det = ltea.id_analysis_req_det
                          JOIN analysis_result_par_hist aresp
                            ON aresp.id_analysis_result = ar.id_analysis_result
                          JOIN harvest h
                            ON ar.id_harvest = h.id_harvest
                          LEFT JOIN abnormality a
                            ON a.id_abnormality = aresp.id_abnormality
                           AND a.flg_visible = pk_lab_tests_constant.g_yes
                         WHERE (ltea.flg_status_harvest IS NULL OR
                               ltea.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                           AND aresp.id_analysis_result_par = i_id_analysis_result_par
                           AND aresp.dt_analysis_result_par_tstz <= i_dt_analysis_result_par) z
                 ORDER BY z.dt_analysis_result_par_tstz DESC NULLS LAST) t
         WHERE rownum = 1;
    
        l_description := l_desc_analysis_parameter || l_colon || l_result_value || --
                         CASE
                             WHEN l_desc_unit_measure IS NOT NULL THEN
                              l_space || l_desc_unit_measure
                         END --
                         || ' (' || l_result_date || ')';
    
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result_desc;

    PROCEDURE tde_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_lab_test_conflict
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_analysis       IN analysis.id_analysis%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        o_flg_reason_msg OUT VARCHAR2,
        o_flg_conflict   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        CURSOR c_epis IS
            SELECT epis.id_patient
              FROM episode epis
             WHERE epis.id_episode = i_episode;
    
        r_pat          c_pat%ROWTYPE;
        l_count        NUMBER := 0;
        l_analysis_tab table_number;
        l_id_patient   patient.id_patient%TYPE;
    
        o_flg_show   VARCHAR2(1);
        o_msg_req    VARCHAR2(4000);
        o_msg_result VARCHAR2(4000);
        o_button     VARCHAR2(200);
    
    BEGIN
        l_id_patient := i_patient;
    
        IF (i_patient IS NULL AND i_episode IS NOT NULL)
        THEN
            g_error := 'OPEN C_EPIS';
            OPEN c_epis;
            FETCH c_epis
                INTO l_id_patient;
            CLOSE c_epis;
        END IF;
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        IF (i_analysis IS NOT NULL)
        THEN
            g_error          := 'TEST ID_ANALYSIS';
            o_flg_reason_msg := '1';
        
            SELECT COUNT(a.id_analysis)
              INTO l_count
              FROM analysis a
             INNER JOIN analysis_instit_soft ais
                ON a.id_analysis = ais.id_analysis
             INNER JOIN analysis_room ar
                ON ar.id_analysis = a.id_analysis
             WHERE a.id_analysis = i_analysis
               AND a.flg_available = pk_alert_constant.g_available
               AND ais.flg_available = pk_alert_constant.g_available
               AND ais.id_software = i_prof.software
               AND ais.id_institution = i_prof.institution
               AND ais.flg_type = pk_lab_tests_constant.g_analysis_can_req
               AND ((r_pat.gender IS NOT NULL AND nvl(a.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
                   r_pat.gender = 'I')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(a.age_min, 0) AND nvl(a.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
               AND ar.flg_available = pk_alert_constant.g_yes
               AND ar.flg_type = pk_lab_tests_constant.g_arm_flg_type_room_tube
               AND ar.id_institution = i_prof.institution
               AND ar.flg_default = pk_alert_constant.g_yes;
        ELSIF (i_analysis_group IS NOT NULL)
        THEN
            g_error          := 'TEST ID_GROUP_ANALYSIS';
            o_flg_reason_msg := '2';
        
            SELECT COUNT(ag.id_analysis_group)
              INTO l_count
              FROM analysis_group ag
             INNER JOIN analysis_instit_soft ais
                ON ais.id_analysis_group = ag.id_analysis_group
             INNER JOIN analysis_agp aa
                ON aa.id_analysis_group = ag.id_analysis_group
             INNER JOIN analysis a
                ON a.id_analysis = aa.id_analysis
             INNER JOIN analysis_room ar
                ON ar.id_analysis = a.id_analysis
             WHERE ag.id_analysis_group = i_analysis_group
               AND ag.flg_available = pk_alert_constant.g_available
               AND aa.flg_available = pk_alert_constant.g_available
               AND a.flg_available = pk_alert_constant.g_available
               AND ais.flg_available = pk_alert_constant.g_available
               AND ais.id_software = i_prof.software
               AND ais.id_institution = i_prof.institution
               AND ais.flg_type = pk_lab_tests_constant.g_analysis_can_req
               AND ((r_pat.gender IS NOT NULL AND nvl(ag.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
                   r_pat.gender = 'I')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(ag.age_min, 0) AND nvl(ag.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
               AND ar.flg_available = pk_alert_constant.g_yes
               AND ar.flg_type = pk_lab_tests_constant.g_arm_flg_type_room_tube
               AND ar.id_institution = i_prof.institution
               AND ar.flg_default = pk_alert_constant.g_yes;
        ELSE
            g_error := 'NO ID ANALYSIS';
            RAISE g_other_exception;
        END IF;
    
        IF (l_count = 0)
        THEN
            o_flg_conflict := pk_lab_tests_constant.g_yes;
            RETURN TRUE;
        END IF;
    
        IF i_analysis_group IS NOT NULL
           AND (i_analysis IS NULL)
        THEN
            g_error := 'FETCH ANALYSIS FROM GROUP';
            IF pk_lab_tests_core.get_lab_test_in_group(i_lang, i_analysis_group, l_analysis_tab, o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            l_analysis_tab := table_number(i_analysis);
        END IF;
    
        g_error    := 'TEST RECENT REQUISITION';
        o_flg_show := pk_lab_tests_utils.get_lab_test_request(i_lang     => i_lang,
                                                              i_prof     => i_prof,
                                                              i_patient  => i_patient,
                                                              i_analysis => l_analysis_tab,
                                                              o_msg_req  => o_msg_req,
                                                              o_button   => o_button);
    
        IF o_flg_show = pk_lab_tests_constant.g_yes
        THEN
            o_flg_reason_msg := '3';
            o_flg_conflict   := pk_lab_tests_constant.g_yes;
        
            RETURN TRUE;
        END IF;
    
        o_flg_conflict := pk_lab_tests_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LAB_TEST_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_conflict;

    FUNCTION get_lab_test_cancel_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_cancel_in_exec sys_config.value%TYPE;
    
        l_id_sys_button table_number := table_number(6701, 57);
    
    BEGIN
        g_error              := 'Fetch sys_config';
        l_flg_cancel_in_exec := nvl(pk_sysconfig.get_config('LABTEST_EXECUTION_CANCEL', i_prof),
                                    pk_alert_constant.g_yes);
    
        g_error := 'Fetch workflow cancel permission';
        SELECT decode(lte.flg_referral,
                      pk_lab_tests_constant.g_flg_referral_r,
                      pk_alert_constant.g_no,
                      pk_lab_tests_constant.g_flg_referral_s,
                      pk_alert_constant.g_no,
                      pk_lab_tests_constant.g_flg_referral_i,
                      pk_alert_constant.g_no,
                      decode(lte.flg_status_det,
                             pk_lab_tests_constant.g_analysis_cancel,
                             pk_alert_constant.g_no,
                             pk_lab_tests_constant.g_analysis_result,
                             pk_alert_constant.g_no,
                             pk_lab_tests_constant.g_analysis_read,
                             pk_alert_constant.g_no,
                             pk_lab_tests_constant.g_analysis_exec,
                             l_flg_cancel_in_exec,
                             pk_alert_constant.g_yes)) flg_cancel
          INTO o_flg_cancel
          FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det = i_analysis_req_det;
    
        IF o_flg_cancel = pk_alert_constant.g_yes
        THEN
            g_error      := 'Check access cancel permission';
            o_flg_cancel := pk_mcdt.check_prof_cancel_permissions(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_id_sys_button => l_id_sys_button);
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
                                              'GET_LAB_TEST_CANCEL_PERMISSION',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_cancel_permission;

    FUNCTION start_lab_test_task_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN tde_task_dependency.id_task_request%TYPE,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_req(i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE) IS
            SELECT ar.id_analysis_req,
                   ard.flg_time_harvest flg_time,
                   ard.flg_status,
                   ar.id_exec_institution,
                   ard.id_room,
                   ar.id_episode,
                   ar.id_patient
              FROM analysis_req_det ard, analysis_req ar
             WHERE ard.id_analysis_req_det = i_analysis_req_det
               AND ard.id_analysis_req = ar.id_analysis_req;
    
        l_analysis_req c_analysis_req%ROWTYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_status   analysis_req.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INIT L_START_TSTZ';
        IF i_start_tstz IS NOT NULL
        THEN
            l_dt_begin := i_start_tstz;
        ELSE
            l_dt_begin := NULL;
        END IF;
    
        g_error := 'OPEN C_ANALYSIS_REQ';
        OPEN c_analysis_req(i_task_request);
        FETCH c_analysis_req
            INTO l_analysis_req;
        CLOSE c_analysis_req;
    
        g_error := 'GET STATUS';
        IF l_analysis_req.flg_status = pk_lab_tests_constant.g_analysis_wtg_tde
        THEN
            IF l_analysis_req.id_exec_institution != i_prof.institution
            THEN
                l_status := pk_lab_tests_constant.g_analysis_exterior;
            ELSE
                IF l_status = pk_lab_tests_constant.g_analysis_wtg_tde
                   AND nvl(l_dt_begin, g_sysdate_tstz) > g_sysdate_tstz
                THEN
                    l_status := pk_lab_tests_constant.g_analysis_pending;
                ELSE
                    l_status := pk_lab_tests_constant.g_analysis_req;
                END IF;
            END IF;
        
            g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_STATUS';
            IF NOT pk_lab_tests_core.set_lab_test_status(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_analysis_req_det => table_number(i_task_request),
                                                         i_status           => l_status,
                                                         o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_analysis_req_in => l_analysis_req.id_analysis_req,
                                dt_begin_tstz_in   => CASE l_analysis_req.flg_time
                                                          WHEN pk_lab_tests_constant.g_flg_time_n THEN
                                                           g_sysdate_tstz
                                                          ELSE
                                                           l_dt_begin
                                                      END,
                                rows_out           => l_rows_out);
        
            ts_analysis_req_det.upd(id_analysis_req_det_in => i_task_request,
                                    dt_target_tstz_in      => nvl(l_dt_begin, g_sysdate_tstz),
                                    dt_pend_req_tstz_in    => nvl(l_dt_begin, g_sysdate_tstz),
                                    rows_out               => l_rows_out);
        
            IF NOT pk_lab_tests_harvest_core.create_harvest_pending(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_patient          => l_analysis_req.id_patient,
                                                                    i_episode          => l_analysis_req.id_episode,
                                                                    i_analysis_req     => l_analysis_req.id_analysis_req,
                                                                    i_analysis_req_det => i_task_request,
                                                                    i_body_location    => NULL,
                                                                    i_laterality       => NULL,
                                                                    o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ANALYSIS_REQ_DET',
                                      i_rowids       => l_rows_out,
                                      i_list_columns => table_varchar('DT_TARGET_TSTZ', 'DT_PEND_REQ_TSTZ'),
                                      o_error        => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'START_LAB_TEST_TASK_REQ',
                                              o_error);
            RETURN FALSE;
    END start_lab_test_task_req;

    FUNCTION cancel_lab_test_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req_det.id_analysis_req_det%TYPE,
        i_reason           IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes     IN VARCHAR2,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req_det table_number;
    
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(ard.id_analysis_req_det)
          INTO l_count
          FROM analysis_req_det ard
         WHERE ard.id_order_recurrence IN (SELECT ard.id_order_recurrence
                                             FROM analysis_req_det ard
                                            WHERE ard.id_analysis_req_det = i_task_request
                                              AND ard.id_order_recurrence IS NOT NULL)
           AND ard.flg_status != 'C';
    
        IF l_count = 0
        THEN
            l_analysis_req_det := table_number(i_task_request);
        ELSE
            SELECT ard.id_analysis_req_det
              BULK COLLECT
              INTO l_analysis_req_det
              FROM analysis_req_det ard
             WHERE ard.id_order_recurrence IN (SELECT ard.id_order_recurrence
                                                 FROM analysis_req_det ard
                                                WHERE ard.id_analysis_req_det = i_task_request
                                                  AND ard.id_order_recurrence IS NOT NULL)
               AND ard.flg_status != 'C';
        END IF;
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_REQUEST';
        IF NOT pk_lab_tests_core.cancel_lab_test_request(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_analysis_req_det => l_analysis_req_det,
                                                         i_dt_cancel        => NULL,
                                                         i_cancel_reason    => i_reason,
                                                         i_cancel_notes     => i_reason_notes,
                                                         i_prof_order       => i_prof_order,
                                                         i_dt_order         => i_dt_order,
                                                         i_order_type       => i_order_type,
                                                         i_flg_cancel_event => i_flg_cancel_event,
                                                         o_error            => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'CANCEL_LAB_TEST_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_task;

    FUNCTION get_lab_test_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE v.id_patient = i_patient
               AND v.id_visit = e.id_visit
               AND e.flg_status = pk_alert_constant.g_flg_status_a;
    
        l_visit c_visit%ROWTYPE;
    
        o_error       t_error_out := t_error_out(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        o_tasks_list  tf_tasks_list := tf_tasks_list();
        l_tasks_lists tf_tasks_list := tf_tasks_list();
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
    
        LOOP
            FETCH c_visit
                INTO l_visit;
            EXIT WHEN c_visit%NOTFOUND;
        
            g_error := 'Selecting tasks lists...';
            SELECT tr_tasks_list(analysis_list.id_analysis_req_det,
                                 analysis_list.desc_exam,
                                 analysis_list.to_be_perform,
                                 analysis_list.dt_ord)
              BULK COLLECT
              INTO l_tasks_lists
              FROM (SELECT ltea.id_analysis_req_det id_analysis_req_det,
                           pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     pk_lab_tests_constant.g_analysis_alias,
                                                                     'ANALYSIS.CODE_ANALYSIS.' || ltea.id_analysis,
                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                     ltea.id_sample_type,
                                                                     NULL) ||
                           decode(l_visit.id_epis_type,
                                  nvl(t_ti_log.get_epis_type(i_lang,
                                                             i_prof,
                                                             e.id_epis_type,
                                                             ltea.flg_status_det,
                                                             ltea.id_analysis_req_det,
                                                             pk_alert_constant.g_analysis_type_req_det),
                                      e.id_epis_type),
                                  '',
                                  ' - (' || pk_message.get_message(i_lang,
                                                                   profissional(i_prof.id,
                                                                                i_prof.institution,
                                                                                t_ti_log.get_epis_type_soft(i_lang,
                                                                                                            i_prof,
                                                                                                            e.id_epis_type,
                                                                                                            ltea.flg_status_det,
                                                                                                            ltea.id_analysis_req_det,
                                                                                                            pk_alert_constant.g_analysis_type_req_det)),
                                                                   'IMAGE_T009') || ')') desc_exam,
                           pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || e.id_epis_type) to_be_perform,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, ltea.dt_req, i_prof) dt_ord
                      FROM lab_tests_ea ltea, episode e
                     WHERE ltea.id_patient = i_patient
                       AND (ltea.id_episode = e.id_episode OR ltea.id_episode_origin = e.id_episode)
                       AND e.id_visit = l_visit.id_visit
                       AND ltea.flg_status_det NOT IN (pk_alert_constant.g_flg_status_f,
                                                       pk_alert_constant.g_flg_status_l,
                                                       pk_alert_constant.g_flg_status_c)
                       AND (ltea.flg_referral IS NULL OR ltea.flg_referral = 'A')
                     ORDER BY dt_ord DESC) analysis_list;
        
            FOR i IN 1 .. l_tasks_lists.count
            LOOP
                IF l_tasks_lists(i).id_task IS NOT NULL
                THEN
                    o_tasks_list.extend;
                    o_tasks_list(o_tasks_list.count) := tr_tasks_list(l_tasks_lists(i).id_task,
                                                                      l_tasks_lists(i).desc_task,
                                                                      l_tasks_lists(i).epis_type,
                                                                      l_tasks_lists(i).dt_task);
                END IF;
            END LOOP;
        END LOOP;
    
        CLOSE c_visit;
    
        RETURN o_tasks_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_ONGOING_TASKS',
                                              o_error);
        
            RETURN o_tasks_list;
    END get_lab_test_ongoing_tasks;

    FUNCTION suspend_lab_test_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_analysis   analysis.id_analysis%TYPE;
        l_analysis_desc pk_translation.t_desc_translation;
    
        l_cancel_reason cancel_reason.id_cancel_reason%TYPE;
    
        l_cancel_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                               pk_death_registry.c_code_msg_death);
        l_mess_error   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ANALYSIS_M139');
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_reason = pk_death_registry.c_flg_reason_death
        THEN
            l_cancel_reason := pk_cancel_reason.c_reason_patient_death;
        END IF;
    
        BEGIN
            SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                             i_prof,
                                                             pk_lab_tests_constant.g_analysis_alias,
                                                             'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type,
                                                             NULL),
                   ard.id_analysis
              INTO l_analysis_desc, l_id_analysis
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = i_id_task;
        EXCEPTION
            WHEN no_data_found THEN
                l_analysis_desc := '';
        END;
    
        -- if no translation is found then return the analysis id 
        IF l_analysis_desc IS NULL
        THEN
            l_analysis_desc := l_id_analysis;
        END IF;
    
        g_error := 'CALL TO PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_REQUEST';
        IF NOT pk_lab_tests_core.cancel_lab_test_request(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_analysis_req_det => table_number(i_id_task),
                                                         i_dt_cancel        => g_sysdate_tstz,
                                                         i_cancel_reason    => l_cancel_reason,
                                                         i_cancel_notes     => l_cancel_notes,
                                                         i_prof_order       => NULL,
                                                         i_dt_order         => NULL,
                                                         i_order_type       => NULL,
                                                         o_error            => o_error)
        THEN
            o_msg_error := REPLACE(l_mess_error, '@1', l_analysis_desc);
            RETURN FALSE;
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
                                              'SUSPEND_LAB_TEST_TASK',
                                              o_error);
            o_msg_error := REPLACE(l_mess_error, '@1', l_analysis_desc);
            RETURN FALSE;
    END suspend_lab_test_task;

    FUNCTION reactivate_lab_test_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN NUMBER,
        o_msg_error OUT VARCHAR,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_data pk_translation.t_desc_translation;
        l_id_analysis   analysis.id_analysis%TYPE;
        l_mess_error CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ANALYSIS_M137');
    
    BEGIN
    
        BEGIN
        
            SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                             i_prof,
                                                             pk_lab_tests_constant.g_analysis_alias,
                                                             'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type,
                                                             NULL),
                   ard.id_analysis
              INTO l_analysis_data, l_id_analysis
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = i_id_task;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_analysis_data := '';
            
        END;
    
        -- if no translation is found then return the analysis id 
        IF l_analysis_data IS NULL
        THEN
            l_analysis_data := l_id_analysis;
        END IF;
    
        o_msg_error := REPLACE(l_mess_error, '@1', l_analysis_data);
    
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REACTIVATE_LAB_TEST_TASK',
                                              o_error);
            RETURN FALSE;
        
    END reactivate_lab_test_task;

    FUNCTION get_lab_test_task_execute_time
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_time         OUT VARCHAR2,
        o_flg_time_desc    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'get task execute time';
        SELECT ltea.flg_time_harvest,
               pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_TIME_HARVEST', ltea.flg_time_harvest, i_lang)
          INTO o_flg_time, o_flg_time_desc
          FROM lab_tests_ea ltea
         WHERE ltea.id_analysis_req_det = i_analysis_req_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_TASK_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_execute_time;

    FUNCTION update_tde_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_lab_test_req    IN analysis_req.id_analysis_req%TYPE,
        i_flg_action      IN VARCHAR2,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_reason_notes    IN VARCHAR2 DEFAULT NULL,
        i_transaction_id  IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_task_dependency analysis_req_det.id_task_dependency%TYPE;
    
    BEGIN
    
        IF i_task_dependency IS NOT NULL
        THEN
            l_task_dependency := i_task_dependency;
        ELSE
            g_error := 'Fetch id_task_dependency';
            SELECT ard.id_task_dependency
              INTO l_task_dependency
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = i_lab_test_req;
        END IF;
    
        IF l_task_dependency IS NOT NULL
        THEN
            IF i_flg_action = pk_alert_constant.g_analysis_det_canc
            THEN
                g_error := 'Call pk_tde_db.update_task_state_cancel';
                IF NOT pk_tde_db.update_task_state_cancel(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_task_dependency => l_task_dependency,
                                                          i_reason          => NULL,
                                                          i_reason_notes    => NULL,
                                                          i_transaction_id  => NULL,
                                                          o_error           => o_error)
                THEN
                    RAISE g_user_exception;
                END IF;
            ELSIF i_flg_action = pk_alert_constant.g_analysis_det_exec
            THEN
                g_error := 'Call pk_tde_db.update_task_state_execute';
                IF NOT pk_tde_db.update_task_state_execute(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_task_dependency => l_task_dependency,
                                                           o_error           => o_error)
                THEN
                    RAISE g_user_exception;
                END IF;
            
            ELSIF i_flg_action IN (pk_alert_constant.g_analysis_det_result, pk_alert_constant.g_analysis_det_read)
            THEN
                g_error := 'Call pk_tde_db.update_task_state_finish';
                IF NOT pk_tde_db.update_task_state_finish(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_task_dependency => l_task_dependency,
                                                          o_error           => o_error)
                THEN
                    RAISE g_user_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TDE_TASK_STATE',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TDE_TASK_STATE',
                                              o_error);
            RETURN FALSE;
    END update_tde_task_state;

    PROCEDURE pregnancy_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_count_lab_test_results
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_id_content        IN table_varchar,
        i_dt_min_lab_result IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
    
        l_count_results NUMBER;
    
    BEGIN
    
        g_error := 'COUNT RESULTS';
        SELECT COUNT(*)
          INTO l_count_results
          FROM analysis_result ar
         INNER JOIN analysis_result_par arp
            ON arp.id_analysis_result = ar.id_analysis_result
         INNER JOIN analysis a
            ON a.id_analysis = ar.id_analysis
         WHERE ar.id_patient = i_patient
           AND a.id_content IN (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(i_id_content) t)
           AND arp.dt_analysis_result_par_tstz > i_dt_min_lab_result
           AND arp.analysis_result_value_1 IS NOT NULL;
    
        RETURN l_count_results;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_lab_test_results;

    PROCEDURE single_page________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_req_det_by_id_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN analysis_req_det.id_order_recurrence%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE DEFAULT NULL,
        o_analysis_req_det OUT analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_dt_req IS NOT NULL
        THEN
            SELECT id_analysis_req_det
              INTO o_analysis_req_det
              FROM (SELECT ard.id_analysis_req_det,
                           row_number() over(PARTITION BY ard.id_order_recurrence ORDER BY ard.dt_last_update_tstz) rn
                      FROM analysis_req_det ard
                      JOIN analysis_req ar
                        ON ard.id_analysis_req = ar.id_analysis_req
                     WHERE ard.id_order_recurrence = i_order_recurrence
                       AND ar.dt_req_tstz = i_dt_req)
             WHERE rn = 1;
        ELSE
            SELECT id_analysis_req_det
              INTO o_analysis_req_det
              FROM (SELECT ard.id_analysis_req_det,
                           row_number() over(PARTITION BY ard.id_order_recurrence ORDER BY ard.dt_last_update_tstz) rn
                      FROM analysis_req_det ard
                     WHERE ard.id_order_recurrence = i_order_recurrence)
             WHERE rn = 1;
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
                                              'GET_LAB_REQ_DET_BY_ID_RECURR',
                                              o_error);
            RETURN FALSE;
    END get_lab_req_det_by_id_recurr;

    FUNCTION get_lab_test_result_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_varchar IS
        l_sep    CONSTANT VARCHAR2(2 CHAR) := ': ';
        l_indent CONSTANT VARCHAR2(2 CHAR) := '  ';
        l_ret            table_varchar;
        l_decimal_symbol sys_config.value%TYPE;
    
        CURSOR c_lab_result IS
            SELECT a.desc_lab_test,
                   a.desc_param,
                   a.desc_result,
                   a.param_count,
                   row_number() over(PARTITION BY a.id_analysis_result ORDER BY a.desc_lab_test, a.desc_param) param_number
              FROM (SELECT a.id_analysis_result,
                           (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                             i_prof,
                                                                             pk_lab_tests_constant.g_analysis_alias,
                                                                             'ANALYSIS.CODE_ANALYSIS.' || a.id_analysis,
                                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                             a.id_sample_type,
                                                                             NULL)
                              FROM dual) desc_lab_test,
                           pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                     'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                     a.id_analysis_parameter,
                                                                     'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || a.id_sample_type,
                                                                     NULL) desc_param,
                           TRIM(nvl(a.desc_analysis_result, pk_utils.to_str(a.analysis_result_value, l_decimal_symbol)) || ' ' ||
                                nvl(a.desc_unit_measure,
                                    (SELECT pk_unit_measure.get_unit_measure_description(i_lang, i_prof, a.id_unit_measure)
                                       FROM dual))) desc_result,
                           (SELECT pk_lab_tests_external.get_lab_test_param_count(i_prof, a.id_analysis, a.id_sample_type)
                              FROM dual) param_count
                      FROM (SELECT ar.id_analysis_result,
                                   ar.id_analysis,
                                   ar.id_sample_type,
                                   arp.id_analysis_parameter,
                                   arp.desc_analysis_result,
                                   arp.analysis_result_value_1 analysis_result_value,
                                   arp.desc_unit_measure,
                                   arp.id_unit_measure,
                                   row_number() over(PARTITION BY arp.id_analysis_result, arp.id_analysis_parameter --
                                   ORDER BY nvl(arp.dt_analysis_result_par_upd, arp.dt_analysis_result_par_tstz) DESC) rn
                              FROM analysis_result ar
                              JOIN analysis_result_par arp
                                ON ar.id_analysis_result = arp.id_analysis_result
                             WHERE ar.id_episode_orig = i_episode
                               AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) a
                     WHERE a.rn = 1) a
             ORDER BY a.desc_lab_test, a.desc_param;
    
        TYPE t_coll_lab_result IS TABLE OF c_lab_result%ROWTYPE;
        l_lab_results t_coll_lab_result;
    BEGIN
        IF i_episode IS NULL
        THEN
            l_ret := NULL;
        ELSE
            l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
        
            -- get lab test results
            OPEN c_lab_result;
            FETCH c_lab_result BULK COLLECT
                INTO l_lab_results;
            CLOSE c_lab_result;
        
            l_ret := table_varchar();
        
            IF l_lab_results IS NOT NULL
               AND l_lab_results.count > 0
            THEN
                FOR i IN l_lab_results.first .. l_lab_results.last
                LOOP
                    -- single parameter lab tests:
                    -- <desc_lab_test>: <desc_result>
                    -- multiple parameter lab tests:
                    -- <desc_lab_test>
                    --   <desc_parameter_n>: <desc_result_n>
                    IF l_lab_results(i).param_count = 1
                    THEN
                        l_ret.extend;
                        l_ret(l_ret.last) := l_lab_results(i).desc_lab_test || l_sep || l_lab_results(i).desc_result;
                    ELSE
                        IF l_lab_results(i).param_number = 1
                        THEN
                            l_ret.extend;
                            l_ret(l_ret.last) := l_lab_results(i).desc_lab_test;
                        END IF;
                    
                        l_ret.extend;
                        l_ret(l_ret.last) := l_indent || l_lab_results(i).desc_param || l_sep || l_lab_results(i).desc_result;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_lab_test_result_list;

    /*
    * Get Description of Lab Order Result
    *
    * @param     i_lang                       Language id
    * @param     i_prof                       Professional
    * @param     i_id_analysis_result_par     Analysis Result Identifier
    * @param     i_description_condition      String that will dictate how the description should be built
    * @param     i_flg_desc_for_dblock        Is a datablock description?    
    * @param     o_description                Description for the Analysis Result
    * @param     o_error                      Error message
    
    * @return    true on success, otherwise false
    *
    * @author    Antonio Neto
    * @version   v2.6.2
    * @since     31-Jan-2012
    */
    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock    IN pk_types.t_flg_char DEFAULT NULL,
        o_description            OUT CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_colon CONSTANT VARCHAR2(24 CHAR) := ': ';
        l_comma CONSTANT VARCHAR2(24 CHAR) := ', ';
        l_space CONSTANT VARCHAR2(1 CHAR) := ' ';
    
        l_desc_high_low           pk_translation.t_desc_translation;
        l_desc_analysis_parameter pk_translation.t_desc_translation;
        l_result_value            CLOB;
        l_desc_unit_measure       pk_translation.t_desc_translation;
        l_notes_doctor_registry   analysis_result_par.notes_doctor_registry%TYPE;
        l_result_date             analysis_result.dt_analysis_result_tstz%TYPE;
        l_ref_val                 VARCHAR2(200 CHAR);
    
    BEGIN
    
        IF i_description_condition IS NOT NULL
        THEN
            IF NOT pk_lab_tests_external.get_lab_test_result_cond_desc(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_id_analysis_result_par => i_id_analysis_result_par,
                                                                       i_description_condition  => i_description_condition,
                                                                       i_flg_desc_for_dblock    => i_flg_desc_for_dblock,
                                                                       o_description            => o_description,
                                                                       o_error                  => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            g_error := 'GET DATA INTO VARS: ' || i_id_analysis_result_par;
            SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                             i_prof,
                                                             pk_lab_tests_constant.g_analysis_parameter_alias,
                                                             'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                             t.id_analysis_parameter,
                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                             NULL) ||
                   decode(t.id_body_part,
                          NULL,
                          NULL,
                          l_comma ||
                          pk_translation.get_translation(i_lang, 'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' || t.id_body_part)) desc_analysis_parameter,
                   nvl(t.desc_analysis_result,
                       (t.comparator || t.analysis_result_value_1 || t.separator || t.analysis_result_value_2)),
                   nvl(t.desc_unit_measure,
                       pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || t.id_unit_measure)),
                   CASE
                       WHEN dbms_lob.getlength(t.desc_analysis_result) < 4000
                            AND pk_utils.is_number(t.desc_analysis_result) = pk_lab_tests_constant.g_yes
                            AND t.analysis_result_value_2 IS NULL THEN
                        CASE
                            WHEN is_lab_result_outside_params(i_lang,
                                                              i_prof,
                                                              'I',
                                                              t.desc_analysis_result,
                                                              t.analysis_result_value_1,
                                                              t.ref_val_min) = pk_alert_constant.g_yes THEN
                             l_space || pk_string_utils.surround(pk_message.get_message(i_lang, 'PN_T057'),
                                                                 pk_string_utils.g_pattern_parenthesis)
                            WHEN is_lab_result_outside_params(i_lang,
                                                              i_prof,
                                                              'A',
                                                              t.desc_analysis_result,
                                                              t.analysis_result_value_1,
                                                              t.ref_val_max) = pk_alert_constant.g_yes THEN
                             l_space || pk_string_utils.surround(pk_message.get_message(i_lang, 'PN_T058'),
                                                                 pk_string_utils.g_pattern_parenthesis)
                            ELSE
                             decode(t.value, NULL, NULL, l_space || t.value)
                        END
                       ELSE
                        decode(t.value, NULL, NULL, l_space || t.value)
                   END,
                   CASE
                       WHEN t.notes_doctor_registry IS NOT NULL
                            AND dbms_lob.compare(t.notes_doctor_registry, empty_clob()) != 0 THEN
                        chr(10) || pk_message.get_message(i_lang => i_lang, i_code_mess => 'ANALYSIS_M065') || ' ' ||
                        t.notes_doctor_registry
                       ELSE
                        NULL
                   END,
                   t.dt_analysis_result_tstz,
                   CASE
                        WHEN t.ref_val IS NOT NULL THEN
                         t.ref_val
                        WHEN t.ref_val_min_str IS NOT NULL
                             AND t.ref_val_max_str IS NOT NULL THEN
                         t.ref_val_min_str || '-' || t.ref_val_max_str
                        WHEN t.ref_val_min_str IS NOT NULL THEN
                         t.ref_val_min_str
                        WHEN t.ref_val_max_str IS NOT NULL THEN
                         t.ref_val_max_str
                        ELSE
                         NULL
                    END AS ref_val
              INTO l_desc_analysis_parameter,
                   l_result_value,
                   l_desc_unit_measure,
                   l_desc_high_low,
                   l_notes_doctor_registry,
                   l_result_date,
                   l_ref_val
              FROM (SELECT aresp.id_analysis_parameter,
                           aresp.desc_analysis_result,
                           aresp.analysis_result_value_1,
                           aresp.analysis_result_value_2,
                           aresp.comparator,
                           aresp.separator,
                           aresp.id_unit_measure,
                           aresp.desc_unit_measure,
                           ar.dt_analysis_result_tstz,
                           aresp.id_professional,
                           ar.id_analysis_result,
                           ltea.flg_status_det,
                           ltea.dt_pend_req,
                           ltea.dt_target,
                           ltea.dt_req,
                           h.dt_harvest_tstz dt_harvest,
                           ltea.id_exam_cat,
                           aresp.ref_val,
                           aresp.ref_val_min_str,
                           aresp.ref_val_max_str,
                           aresp.ref_val_min,
                           aresp.ref_val_max,
                           ltea.id_analysis,
                           ltea.id_sample_type,
                           a.value,
                           aresp.notes_doctor_registry,
                           h.id_body_part
                      FROM lab_tests_ea ltea
                      JOIN analysis_result ar
                        ON ar.id_analysis_req_det = ltea.id_analysis_req_det
                      JOIN analysis_result_par aresp
                        ON aresp.id_analysis_result = ar.id_analysis_result
                      JOIN harvest h
                        ON ar.id_harvest = h.id_harvest
                      LEFT JOIN abnormality a
                        ON a.id_abnormality = aresp.id_abnormality
                       AND a.flg_visible = pk_lab_tests_constant.g_yes
                     WHERE (ltea.flg_status_harvest IS NULL OR
                           ltea.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                       AND aresp.id_analysis_result_par = i_id_analysis_result_par
                    UNION ALL
                    --case when there is no request
                    SELECT aresp.id_analysis_parameter,
                           aresp.desc_analysis_result,
                           aresp.analysis_result_value_1,
                           aresp.analysis_result_value_2,
                           aresp.comparator,
                           aresp.separator,
                           aresp.id_unit_measure,
                           aresp.desc_unit_measure,
                           ar.dt_analysis_result_tstz,
                           aresp.id_professional,
                           ar.id_analysis_result,
                           NULL                          flg_status_det,
                           NULL                          dt_pend_req,
                           NULL                          dt_target,
                           NULL                          dt_req,
                           h.dt_harvest_tstz             dt_harvest,
                           ar.id_exam_cat,
                           aresp.ref_val,
                           aresp.ref_val_min_str,
                           aresp.ref_val_max_str,
                           
                           aresp.ref_val_min,
                           aresp.ref_val_max,
                           ar.id_analysis,
                           ar.id_sample_type,
                           NULL                        VALUE,
                           aresp.notes_doctor_registry,
                           NULL                        id_body_part
                      FROM analysis_result ar
                      JOIN analysis_result_par aresp
                        ON aresp.id_analysis_result = ar.id_analysis_result
                      LEFT JOIN harvest h
                        ON h.id_harvest = ar.id_harvest
                     WHERE aresp.id_analysis_result_par = i_id_analysis_result_par
                       AND NOT EXISTS (SELECT 0
                              FROM lab_tests_ea ltea
                             INNER JOIN analysis_result ar1
                                ON ltea.id_analysis_req_det = ar1.id_analysis_req_det
                             WHERE ar1.id_analysis_result = ar.id_analysis_result)) t;
        
            o_description := l_desc_analysis_parameter || l_colon || l_result_value || --
                             CASE
                                 WHEN l_desc_unit_measure IS NOT NULL THEN
                                  l_space || l_desc_unit_measure
                             END --
                             || l_desc_high_low || --
                             CASE
                                 WHEN l_ref_val IS NOT NULL THEN
                                  l_space || pk_string_utils.surround(pk_message.get_message(i_lang, 'LAB_TESTS_T129') ||
                                                                      l_space || l_ref_val,
                                                                      pk_string_utils.g_pattern_parenthesis)
                             END --
                             || l_notes_doctor_registry;
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
                                              'GET_LAB_TEST_RESULT_DESC',
                                              o_error);
            o_description := NULL;
            RETURN FALSE;
    END get_lab_test_result_desc;

    FUNCTION get_lab_test_order_cond_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_analysis_req_det   IN analysis_req_det.id_analysis_req_det%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char DEFAULT NULL,
        o_description           OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_desc_condition  table_varchar;
        l_tbl_final_desc_cond table_varchar;
    
        l_final_desc_cond pk_types.t_huge_byte;
    
        l_order_date         pk_types.t_low_char;
        l_lab_test           pk_types.t_med_char;
        l_lab_test_descr     pk_types.t_med_char;
        l_branch_hospital    pk_types.t_low_char;
        l_specimen           pk_types.t_low_char;
        l_id_branch_hospital institution.id_institution%TYPE;
    BEGIN
    
        l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => ';'); -- first split (if it has different desc cond for data block and import screen)
    
        IF i_flg_desc_for_dblock = pk_alert_constant.g_yes
           OR i_flg_desc_for_dblock IS NULL
        THEN
            l_final_desc_cond := l_tbl_desc_condition(1);
        ELSIF l_tbl_desc_condition.exists(2)
        THEN
            l_final_desc_cond := l_tbl_desc_condition(2);
        END IF;
    
        l_tbl_final_desc_cond := pk_string_utils.str_split(i_list => l_final_desc_cond, i_delim => '|');
    
        o_description := '';
    
        SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         NULL,
                                                         'ANALYSIS.CODE_ANALYSIS.' || t.id_analysis,
                                                         NULL),
               pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         NULL,
                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                         NULL),
               pk_date_utils.date_char_tsz(i_lang, t.dt_target_tstz, i_prof.institution, i_prof.software),
               t.id_institution,
               pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         pk_lab_tests_constant.g_analysis_alias,
                                                         'ANALYSIS.CODE_ANALYSIS.' || t.id_analysis,
                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                         NULL) lab_test_desc
          INTO l_lab_test, l_specimen, l_order_date, l_id_branch_hospital, l_lab_test_descr
          FROM (SELECT ltea.id_analysis, ltea.id_sample_type, ard.dt_target_tstz, ltea.id_institution
                  FROM lab_tests_ea ltea
                  JOIN analysis_req_det ard
                    ON ard.id_analysis_req_det = ltea.id_analysis_req_det
                 WHERE ltea.flg_status_req <> pk_lab_tests_constant.g_analysis_cancel
                   AND ltea.id_analysis_req_det = i_id_analysis_req_det) t;
    
        IF l_id_branch_hospital IS NOT NULL
        THEN
            IF NOT pk_utils.get_institution_name(i_lang           => i_lang,
                                                 i_id_institution => l_id_branch_hospital,
                                                 o_instit_name    => l_branch_hospital,
                                                 o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        FOR i IN l_tbl_final_desc_cond.first .. l_tbl_final_desc_cond.last
        LOOP
        
            IF l_tbl_final_desc_cond(i) = 'LAB-TEST'
            THEN
                IF l_lab_test IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_space || l_lab_test;
                    ELSE
                        o_description := o_description || l_lab_test;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'SPECIMEN'
            THEN
                IF l_specimen IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_specimen;
                    ELSE
                        o_description := o_description || l_specimen;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'LAB_NAME'
            THEN
                IF l_lab_test_descr IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_lab_test_descr;
                    ELSE
                        o_description := o_description || l_lab_test_descr;
                    END IF;
                END IF;
            ELSIF l_tbl_final_desc_cond(i) = 'CATEGORY'
            THEN
                IF o_description IS NOT NULL
                THEN
                    o_description := o_description || pk_prog_notes_constants.g_space ||
                                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T183');
                ELSE
                    o_description := o_description ||
                                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T183');
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'ORDER-DATE'
            THEN
                IF l_order_date IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_order_date;
                    ELSE
                        o_description := o_description || l_order_date;
                    END IF;
                END IF;
            END IF;
        END LOOP;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_description := NULL;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_LAB_TEST_ORDER_COND_DESC',
                                                     o_error);
    END get_lab_test_order_cond_desc;

    FUNCTION get_analysis_status_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_status              OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET status. i_id_analysis_req_det: ' || i_id_analysis_req_det;
        SELECT decode(ard.flg_referral,
                      pk_lab_tests_constant.g_flg_referral_r,
                      pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_REFERRAL', ard.flg_referral, i_lang),
                      pk_lab_tests_constant.g_flg_referral_s,
                      pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_REFERRAL', ard.flg_referral, i_lang),
                      pk_lab_tests_constant.g_flg_referral_i,
                      pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_REFERRAL', ard.flg_referral, i_lang),
                      decode(ard.flg_status,
                             pk_lab_tests_constant.g_analysis_sos,
                             pk_sysdomain.get_domain(i_lang,
                                                     i_prof,
                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                     pk_lab_tests_constant.g_analysis_req,
                                                     NULL),
                             pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ_DET.FLG_STATUS', ard.flg_status, NULL)))
          INTO o_status
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det = i_id_analysis_req_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_STATUS_DESC',
                                              o_error);
            RETURN FALSE;
    END get_analysis_status_desc;

    FUNCTION get_lab_test_result_param
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_param IN table_number,
        i_dt_result      IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_result analysis_result_par.dt_analysis_result_par_tstz%TYPE;
    
    BEGIN
    
        l_dt_result := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_result, NULL);
    
        IF l_dt_result IS NULL
        THEN
            l_dt_result := current_timestamp;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT DISTINCT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                      'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                      arp.id_analysis_parameter,
                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                      ar.id_sample_type,
                                                                      NULL) || ': ' ||
                            (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                             arp.analysis_result_value_2) || ' ' ||
                            nvl(arp.desc_unit_measure,
                                pk_translation.get_translation(i_lang,
                                                               'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure)) || ' (' ||
                            pk_date_utils.date_char_tsz(i_lang,
                                                        ar.dt_analysis_result_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) || ')' param_result,
                            arp.id_analysis_result_par
              FROM analysis_result_par arp
             INNER JOIN analysis_result ar
                ON ar.id_analysis_result = arp.id_analysis_result
             INNER JOIN analysis_param ap
                ON ap.id_analysis_parameter = arp.id_analysis_parameter
             WHERE ap.id_analysis_param IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(i_analysis_param) t)
               AND ar.id_patient = i_patient
               AND ap.id_analysis = ar.id_analysis
               AND ap.id_sample_type = ar.id_sample_type
               AND arp.dt_analysis_result_par_tstz =
                   (SELECT MAX(arp2.dt_analysis_result_par_tstz)
                      FROM analysis_result_par arp2
                     INNER JOIN analysis_result ar2
                        ON ar2.id_analysis_result = arp2.id_analysis_result
                     INNER JOIN analysis_param ap2
                        ON ap2.id_analysis_parameter = arp2.id_analysis_parameter
                     WHERE ar2.id_patient = ar.id_patient
                       AND ap2.id_analysis = ar2.id_analysis
                       AND ap2.id_sample_type = ar2.id_sample_type
                       AND arp2.dt_analysis_result_par_tstz <= l_dt_result
                       AND ap2.id_analysis_param = ap.id_analysis_param
                       AND arp2.analysis_result_value_1 IS NOT NULL)
               AND arp.analysis_result_value_1 IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_RESULT_PARAM',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_result_param;

    FUNCTION get_lab_test_parameters
    (
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN table_number IS
        l_ret table_number;
    
        CURSOR c_apr IS
            SELECT apr.id_analysis_parameter
              FROM analysis_parameter apr
              JOIN analysis_param apm
                ON apr.id_analysis_parameter = apm.id_analysis_parameter
             WHERE apm.id_analysis = i_analysis
               AND apm.id_sample_type = i_sample_type
               AND apm.id_institution = i_prof.institution
               AND apm.id_software = i_prof.software
               AND apm.flg_available = pk_alert_constant.g_yes
               AND apr.flg_available = pk_alert_constant.g_yes;
    BEGIN
    
        OPEN c_apr;
        FETCH c_apr BULK COLLECT
            INTO l_ret;
        CLOSE c_apr;
    
        RETURN l_ret;
    END get_lab_test_parameters;

    FUNCTION get_lab_test_param_count
    (
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN NUMBER IS
        l_ret    NUMBER;
        l_params table_number;
    BEGIN
    
        l_params := get_lab_test_parameters(i_prof => i_prof, i_analysis => i_analysis, i_sample_type => i_sample_type);
    
        IF l_params IS NULL
        THEN
            l_ret := NULL;
        ELSE
            l_ret := l_params.count;
        END IF;
    
        RETURN l_ret;
    END get_lab_test_param_count;

    FUNCTION is_lab_test_recurr_finished
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN analysis_req_det.id_order_recurrence%TYPE
    ) RETURN VARCHAR2 IS
    
        l_found VARCHAR2(1 CHAR);
    
    BEGIN
    
        SELECT DISTINCT 'N'
          INTO l_found
          FROM analysis_req_det ard
         WHERE ard.id_order_recurrence = i_order_recurrence
           AND ard.flg_status NOT IN (pk_lab_tests_constant.g_analysis_result,
                                      pk_lab_tests_constant.g_analysis_read,
                                      pk_lab_tests_constant.g_analysis_cancel);
    
        RETURN l_found;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 'Y';
        
    END is_lab_test_recurr_finished;

    FUNCTION is_lab_result_outside_params
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_type_comparison   IN VARCHAR2,
        i_desc_analysis_result  IN analysis_result_par.desc_analysis_result%TYPE,
        i_analysis_result_value IN analysis_result_par.analysis_result_value_1%TYPE,
        i_ref_val               IN analysis_result_par.ref_val_min%TYPE
    ) RETURN VARCHAR2 IS
        l_val_to_compare NUMBER(24, 3);
    
        l_flg_type_comparison_min_i CONSTANT VARCHAR2(1 CHAR) := 'I';
        l_flg_type_comparison_max_a CONSTANT VARCHAR2(1 CHAR) := 'A';
    
        l_ret VARCHAR2(1 CHAR);
    BEGIN
    
        CASE
        --if lesser than the min value
            WHEN i_flg_type_comparison = l_flg_type_comparison_min_i THEN
                IF i_ref_val IS NOT NULL
                THEN
                    l_val_to_compare := nvl(to_number(TRIM(REPLACE(i_desc_analysis_result, '.', ',')),
                                                      pk_lab_tests_constant.g_format_mask,
                                                      'NLS_NUMERIC_CHARACTERS='', '''),
                                            i_analysis_result_value);
                    IF l_val_to_compare < i_ref_val
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    ELSE
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
                --if greater than the max value
            WHEN i_flg_type_comparison = l_flg_type_comparison_max_a THEN
                IF i_ref_val IS NOT NULL
                THEN
                
                    l_val_to_compare := nvl(to_number(TRIM(REPLACE(i_desc_analysis_result, '.', ',')),
                                                      pk_lab_tests_constant.g_format_mask,
                                                      'NLS_NUMERIC_CHARACTERS='', '''),
                                            i_analysis_result_value);
                
                    IF l_val_to_compare > i_ref_val
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    ELSE
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
                --otherwise
            ELSE
                l_ret := pk_alert_constant.g_no;
        END CASE;
    
        RETURN l_ret;
    END is_lab_result_outside_params;

    FUNCTION get_lab_test_result_cond_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock    IN pk_types.t_flg_char,
        o_description            OUT CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_desc_condition  table_varchar;
        l_tbl_final_desc_cond table_varchar;
    
        l_final_desc_cond    pk_types.t_huge_byte;
        l_result_date        pk_types.t_low_char;
        l_lab_test           pk_translation.t_desc_translation;
        l_test_result        CLOB;
        l_test_unit          pk_translation.t_desc_translation;
        l_branch_hospital    pk_types.t_low_char;
        l_specimen           pk_translation.t_desc_translation;
        l_reference_values   pk_types.t_low_char;
        l_ref_val            VARCHAR2(200 CHAR);
        l_id_branch_hospital institution.id_institution%TYPE;
        l_parameter          pk_translation.t_desc_translation;
        l_parameter_notes    analysis_result_par.parameter_notes%TYPE;
    
    BEGIN
    
        l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => ';');
    
        IF i_flg_desc_for_dblock = pk_alert_constant.g_yes
           OR i_flg_desc_for_dblock IS NULL
        THEN
            l_final_desc_cond := l_tbl_desc_condition(1);
        ELSIF l_tbl_desc_condition.exists(2)
        THEN
            l_final_desc_cond := l_tbl_desc_condition(2);
        END IF;
    
        l_tbl_final_desc_cond := pk_string_utils.str_split(i_list => l_final_desc_cond, i_delim => '|');
    
        o_description := '';
    
        SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         pk_lab_tests_constant.g_analysis_parameter_alias,
                                                         'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                         t.id_analysis_parameter,
                                                         NULL),
               pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         NULL,
                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                         NULL),
               (nvl(t.desc_analysis_result,
                    to_clob(t.comparator || t.analysis_result_value_1 || t.separator || t.analysis_result_value_2))),
               (nvl(t.desc_unit_measure,
                    pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || t.id_unit_measure))),
               CASE
                   WHEN dbms_lob.getlength(t.desc_analysis_result) < 4000
                        AND pk_utils.is_number(t.desc_analysis_result) = pk_lab_tests_constant.g_yes
                        AND t.analysis_result_value_2 IS NULL THEN
                    CASE
                        WHEN is_lab_result_outside_params(i_lang,
                                                          i_prof,
                                                          'I',
                                                          t.desc_analysis_result,
                                                          t.analysis_result_value_1,
                                                          t.ref_val_min) = pk_alert_constant.g_yes THEN
                         ' ' || pk_string_utils.surround(pk_message.get_message(i_lang, 'PN_T057'),
                                                         pk_string_utils.g_pattern_parenthesis)
                        WHEN is_lab_result_outside_params(i_lang,
                                                          i_prof,
                                                          'A',
                                                          t.desc_analysis_result,
                                                          t.analysis_result_value_1,
                                                          t.ref_val_max) = pk_alert_constant.g_yes THEN
                         ' ' || pk_string_utils.surround(pk_message.get_message(i_lang, 'PN_T058'),
                                                         pk_string_utils.g_pattern_parenthesis)
                        ELSE
                         decode(t.value, NULL, NULL, ' ' || t.value)
                    END
                   ELSE
                    decode(t.value, NULL, NULL, ' ' || t.value)
               END,
               pk_date_utils.date_char_tsz(i_lang, t.dt_analysis_result_tstz, i_prof.institution, i_prof.software),
               t.id_institution,
               ref_val,
               pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                         i_prof,
                                                         NULL,
                                                         'ANALYSIS.CODE_ANALYSIS.' || t.id_analysis,
                                                         NULL),
               parameter_notes
          INTO l_parameter,
               l_specimen,
               l_test_result,
               l_test_unit,
               l_reference_values,
               l_result_date,
               l_id_branch_hospital,
               l_ref_val,
               l_lab_test,
               l_parameter_notes
          FROM (SELECT aresp.id_analysis_parameter,
                       aresp.desc_analysis_result,
                       aresp.analysis_result_value_1,
                       aresp.analysis_result_value_2,
                       aresp.comparator,
                       aresp.separator,
                       aresp.id_unit_measure,
                       aresp.desc_unit_measure,
                       coalesce(aresp.dt_analysis_result_par_upd,
                                aresp.dt_analysis_result_par_tstz,
                                ar.dt_analysis_result_tstz) dt_analysis_result_tstz,
                       aresp.ref_val_min,
                       aresp.ref_val_max,
                       ltea.id_sample_type,
                       a.value,
                       h.id_body_part,
                       ltea.id_institution,
                       CASE
                            WHEN aresp.ref_val IS NOT NULL THEN
                             aresp.ref_val
                            WHEN aresp.ref_val_min_str IS NOT NULL
                                 AND aresp.ref_val_max_str IS NOT NULL THEN
                             aresp.ref_val_min_str || '-' || aresp.ref_val_max_str
                            WHEN aresp.ref_val_min_str IS NOT NULL THEN
                             aresp.ref_val_min_str
                            WHEN aresp.ref_val_max_str IS NOT NULL THEN
                             aresp.ref_val_max_str
                            ELSE
                             NULL
                        END AS ref_val,
                       ltea.id_analysis,
                       aresp.parameter_notes
                  FROM lab_tests_ea ltea
                  JOIN analysis_result ar
                    ON ar.id_analysis_req_det = ltea.id_analysis_req_det
                  JOIN analysis_result_par aresp
                    ON aresp.id_analysis_result = ar.id_analysis_result
                  JOIN harvest h
                    ON ar.id_harvest = h.id_harvest
                  LEFT JOIN abnormality a
                    ON a.id_abnormality = aresp.id_abnormality
                   AND a.flg_visible = pk_lab_tests_constant.g_yes
                 WHERE (ltea.flg_status_harvest IS NULL OR
                       ltea.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                   AND aresp.id_analysis_result_par = i_id_analysis_result_par
                UNION ALL
                --case when there is no request
                SELECT aresp.id_analysis_parameter,
                       aresp.desc_analysis_result,
                       aresp.analysis_result_value_1,
                       aresp.analysis_result_value_2,
                       aresp.comparator,
                       aresp.separator,
                       aresp.id_unit_measure,
                       aresp.desc_unit_measure,
                       coalesce(aresp.dt_analysis_result_par_upd,
                                aresp.dt_analysis_result_par_tstz,
                                ar.dt_analysis_result_tstz) dt_analysis_result_tstz,
                       aresp.ref_val_min,
                       aresp.ref_val_max,
                       ar.id_sample_type,
                       NULL VALUE,
                       NULL id_body_part,
                       ar.id_institution,
                       aresp.ref_val,
                       ar.id_analysis,
                       aresp.parameter_notes
                  FROM analysis_result ar
                  JOIN analysis_result_par aresp
                    ON aresp.id_analysis_result = ar.id_analysis_result
                  LEFT JOIN harvest h
                    ON h.id_harvest = ar.id_harvest
                 WHERE aresp.id_analysis_result_par = i_id_analysis_result_par
                   AND NOT EXISTS (SELECT 0
                          FROM lab_tests_ea ltea
                         INNER JOIN analysis_result ar1
                            ON ltea.id_analysis_req_det = ar1.id_analysis_req_det
                         WHERE ar1.id_analysis_result = ar.id_analysis_result)) t;
    
        IF l_id_branch_hospital IS NOT NULL
        THEN
            IF NOT pk_utils.get_institution_name(i_lang           => i_lang,
                                                 i_id_institution => l_id_branch_hospital,
                                                 o_instit_name    => l_branch_hospital,
                                                 o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        FOR i IN l_tbl_final_desc_cond.first .. l_tbl_final_desc_cond.last
        LOOP
            IF l_tbl_final_desc_cond(i) = 'RESULT-DATE'
            THEN
                IF l_result_date IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_result_date;
                    ELSE
                        o_description := o_description || l_result_date;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'BRANCH-HOSPITAL'
            THEN
                IF l_branch_hospital IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_branch_hospital;
                    ELSE
                        o_description := o_description || l_branch_hospital;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'LAB-TEST'
            THEN
                IF l_lab_test IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_lab_test;
                    ELSE
                        o_description := o_description || l_lab_test;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'PARAMETER'
            THEN
                IF l_lab_test IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_parameter;
                    ELSE
                        o_description := o_description || l_parameter;
                    END IF;
                END IF;
            ELSIF l_tbl_final_desc_cond(i) = 'RESULT'
            THEN
                IF l_test_result IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_test_result;
                    ELSE
                        o_description := o_description || l_test_result;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'UNIT'
            THEN
                IF l_test_unit IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_test_unit;
                    ELSE
                        o_description := o_description || l_test_unit;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'SPECIMEN'
            THEN
                IF l_specimen IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_specimen;
                    ELSE
                        o_description := o_description || l_specimen;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'REFERENCE-VALUES'
            THEN
            
                IF l_ref_val IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma ||
                                         pk_message.get_message(i_lang, 'LAB_TESTS_T129') ||
                                         pk_prog_notes_constants.g_colon || l_ref_val;
                    ELSE
                        o_description := o_description || pk_message.get_message(i_lang, 'LAB_TESTS_T129') ||
                                         pk_prog_notes_constants.g_colon || l_ref_val;
                    END IF;
                END IF;
            
            ELSIF l_tbl_final_desc_cond(i) = 'REFERENCE-VALUES-DESC'
            THEN
                IF l_reference_values IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_reference_values;
                    ELSE
                        o_description := o_description || l_reference_values;
                    END IF;
                END IF;
            ELSIF l_tbl_final_desc_cond(i) = 'PARAMETER-NOTES'
            THEN
                IF l_parameter_notes IS NOT NULL
                THEN
                    IF o_description IS NOT NULL
                    THEN
                        o_description := o_description || pk_prog_notes_constants.g_comma || l_parameter_notes;
                    ELSE
                        o_description := o_description || l_parameter_notes;
                    END IF;
                END IF;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_RESULT_COND_DESC',
                                              o_error);
            o_description := NULL;
            RETURN FALSE;
    END get_lab_test_result_cond_desc;

    PROCEDURE hand_off__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_tests_by_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_analysis OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        g_error := 'OPEN O_ANALYSIS';
        OPEN o_analysis FOR
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_analysis) AS table_varchar), '; ') desc_analysis,
                   t.flg_status
              FROM (SELECT pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                    i_prof,
                                                                    pk_lab_tests_constant.g_analysis_alias,
                                                                    'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                    'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                                    NULL) desc_analysis,
                           decode(lte.flg_status_det,
                                  pk_lab_tests_constant.g_analysis_pending,
                                  pk_lab_tests_constant.g_analysis_req,
                                  lte.flg_status_det) flg_status,
                           pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det) rank
                      FROM lab_tests_ea lte
                     WHERE lte.id_visit = l_visit
                       AND lte.flg_status_det IN
                           (pk_lab_tests_constant.g_analysis_pending, pk_lab_tests_constant.g_analysis_req)) t
             GROUP BY flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TESTS_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            RETURN FALSE;
    END get_lab_tests_by_status;

    PROCEDURE sev_score_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_result
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_analysis_parameter IN table_varchar,
        i_flg_parameter      IN VARCHAR2,
        i_dt_min             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_result_value       OUT NUMBER,
        o_result_um          OUT unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
    
        l_analysis_parameter table_number := table_number();
        l_result_value       NUMBER(24, 3);
        l_result_um          unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        SELECT ap.id_analysis_parameter
          BULK COLLECT
          INTO l_analysis_parameter
          FROM analysis_parameter ap
         WHERE ap.id_content IN (SELECT /*+opt_estimate(table t rows=1)*/
                                  *
                                   FROM TABLE(i_analysis_parameter) t);
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF i_flg_parameter = pk_sev_scores_constant.g_condition_max
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_min
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 ASC)
             WHERE rownum = 1;
        
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_max_harvest
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = ar.id_analysis_req_det
                      JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_patient = l_id_patient
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND h.dt_harvest_tstz >= i_dt_min
                       AND h.dt_harvest_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_min_harvest
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = ar.id_analysis_req_det
                      JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_patient = l_id_patient
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND h.dt_harvest_tstz >= i_dt_min
                       AND h.dt_harvest_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 ASC)
             WHERE rownum = 1;
        END IF;
    
        o_result_value := l_result_value;
        o_result_um    := l_result_um;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_result_value := NULL;
            o_result_um    := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            o_result_value := NULL;
            o_result_um    := NULL;
            RETURN FALSE;
    END get_lab_test_result;

    FUNCTION get_lab_test_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_result_value       NUMBER(24, 3);
        l_result_um          unit_measure.id_unit_measure%TYPE;
        l_analysis_parameter table_number := table_number();
        l_index              INTEGER := NULL;
        l_result             VARCHAR2(100);
        l_id_patient         patient.id_patient%TYPE;
    
    BEGIN
    
        SELECT ap.id_analysis_parameter
          BULK COLLECT
          INTO l_analysis_parameter
          FROM analysis_parameter ap
         WHERE ap.id_content IN
               (SELECT mpt.id_content_param_task
                  FROM mtos_param_task mpt
                 WHERE mpt.id_mtos_param = i_id_mtos_param
                   AND mpt.flg_param_task_type = pk_sev_scores_constant.g_task_analysis_parameter);
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF i_flg_parameter = pk_sev_scores_constant.g_condition_max
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_min
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 ASC)
             WHERE rownum = 1;
        ELSIF i_flg_parameter = 'L'
        THEN
        
            SELECT mm.multiplier_value
              INTO l_index
              FROM mtos_multiplier mm
             WHERE mm.id_mtos_param = i_id_mtos_param
               AND mm.flg_param_task_type = 'L';
        
            SELECT RESULT
              INTO l_result_value
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT,
                           row_number() over(PARTITION BY ar.id_patient ORDER BY ar.dt_analysis_result_tstz DESC) AS rn
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t))
             WHERE rn = l_index;
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_max_harvest
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = ar.id_analysis_req_det
                      JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_patient = l_id_patient
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND h.dt_harvest_tstz >= i_dt_min
                       AND h.dt_harvest_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_min_harvest
        THEN
            SELECT *
              INTO l_result_value, l_result_um
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT, arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = ar.id_analysis_req_det
                      JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_patient = l_id_patient
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND h.dt_harvest_tstz >= i_dt_min
                       AND h.dt_harvest_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 ASC)
             WHERE rownum = 1;
        ELSIF i_flg_parameter = pk_sev_scores_constant.g_flg_latest_harvest
        THEN
            SELECT mm.multiplier_value
              INTO l_index
              FROM mtos_multiplier mm
             WHERE mm.id_mtos_param = i_id_mtos_param
               AND mm.flg_param_task_type = 'L';
        
            SELECT RESULT
              INTO l_result_value
              FROM (SELECT nvl(arp.analysis_result_value_1, arp.analysis_result_value_2) AS RESULT,
                           row_number() over(PARTITION BY ar.id_patient ORDER BY ar.dt_analysis_result_tstz DESC) AS rn
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = ar.id_analysis_req_det
                      JOIN analysis_harvest ah
                        ON ah.id_analysis_req_det = ard.id_analysis_req_det
                      JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE ar.id_patient = l_id_patient
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND h.dt_harvest_tstz >= i_dt_min
                       AND h.dt_harvest_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t))
             WHERE rn = l_index;
        END IF;
    
        IF l_result_value < 1
        THEN
            l_result := to_char(l_result_value, 'FM9990d999');
        ELSE
            l_result := to_char(l_result_value);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result;

    FUNCTION get_lab_test_result_um
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
    
        l_analysis_parameter table_number := table_number();
        l_result_um          unit_measure.id_unit_measure%TYPE;
    
        l_index INTEGER := NULL;
    
    BEGIN
    
        SELECT ap.id_analysis_parameter
          BULK COLLECT
          INTO l_analysis_parameter
          FROM analysis_parameter ap
         WHERE ap.id_content IN
               (SELECT mpt.id_content_param_task
                  FROM mtos_param_task mpt
                 WHERE mpt.id_mtos_param = i_id_mtos_param
                   AND mpt.flg_param_task_type = pk_sev_scores_constant.g_task_analysis_parameter);
    
        IF i_flg_parameter = 'MAX'
        THEN
            SELECT *
              INTO l_result_um
              FROM (SELECT arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        
        ELSIF i_flg_parameter = 'MIN'
        THEN
            SELECT *
              INTO l_result_um
              FROM (SELECT arp.id_unit_measure
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t)
                     ORDER BY 1 ASC)
             WHERE rownum = 1;
        
        ELSIF i_flg_parameter = 'L'
        THEN
        
            SELECT mm.multiplier_value
              INTO l_index
              FROM mtos_multiplier mm
             WHERE mm.id_mtos_param = i_id_mtos_param
               AND mm.flg_param_task_type = 'L';
        
            SELECT id_unit_measure
              INTO l_result_um
              FROM (SELECT arp.id_unit_measure,
                           row_number() over(PARTITION BY ar.id_patient ORDER BY ar.dt_analysis_result_tstz DESC) AS rn
                      FROM analysis_result ar
                      JOIN analysis_result_par arp
                        ON ar.id_analysis_result = arp.id_analysis_result
                     WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
                       AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
                       AND arp.dt_analysis_result_par_tstz >= i_dt_min
                       AND arp.dt_analysis_result_par_tstz <= i_dt_max
                       AND arp.id_analysis_parameter IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_analysis_parameter) t))
             WHERE rn = l_index;
        END IF;
    
        RETURN l_result_um;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result_um;

    FUNCTION get_results_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_analysis_parameter IN table_varchar,
        i_flg_parameter      IN VARCHAR2,
        i_dt_min             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max             IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN INTEGER IS
    
        l_analysis_parameter table_number := table_number();
        l_count              INTEGER := 0;
    
    BEGIN
    
        SELECT ap.id_analysis_parameter
          BULK COLLECT
          INTO l_analysis_parameter
          FROM analysis_parameter ap
         WHERE ap.id_content IN (SELECT /*+opt_estimate(table t rows=1)*/
                                  *
                                   FROM TABLE(i_analysis_parameter) t);
    
        IF i_flg_parameter = pk_sev_scores_constant.g_condition_min_harvest
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM analysis_result ar
              JOIN analysis_result_par arp
                ON ar.id_analysis_result = arp.id_analysis_result
              JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = ar.id_analysis_req_det
              JOIN analysis_harvest ah
                ON ah.id_analysis_req_det = ard.id_analysis_req_det
              JOIN harvest h
                ON h.id_harvest = ah.id_harvest
             WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
               AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
               AND h.dt_harvest_tstz >= i_dt_min
               AND h.dt_harvest_tstz <= i_dt_max
               AND arp.id_analysis_parameter IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  *
                                                   FROM TABLE(l_analysis_parameter) t);
        ELSE
        
            SELECT COUNT(*)
              INTO l_count
              FROM analysis_result ar
              JOIN analysis_result_par arp
                ON ar.id_analysis_result = arp.id_analysis_result
             WHERE (ar.id_episode = i_episode OR ar.id_episode_orig = i_episode)
               AND nvl(ar.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active
               AND arp.dt_analysis_result_par_tstz >= i_dt_min
               AND arp.dt_analysis_result_par_tstz <= i_dt_max
               AND arp.id_analysis_parameter IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  *
                                                   FROM TABLE(l_analysis_parameter) t);
        
        END IF;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_results_count;

    PROCEDURE viewer___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_ordered_list_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2,
        i_flg_all_rows IN BOOLEAN,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_records t_table_rec_gen_area_rank_tmp;
    
        l_viewer_lim_tasktime_lab sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_LAB', i_prof);
        l_viewer_lab_limit        sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LAB_LIMIT', i_prof);
    
        l_msg_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M097');
    
        l_episode table_number;
    
        l_flg_all_rows VARCHAR2(1) := pk_alert_constant.g_no;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T200');
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_all_rows
        THEN
            l_flg_all_rows := pk_alert_constant.g_yes;
        END IF;
    
        OPEN c_episode;
        FETCH c_episode BULK COLLECT
            INTO l_episode;
    
        --Gather data
        g_error := 'INSERT ON TEMP TABLE';
        SELECT t_rec_gen_area_rank_tmp(tt.flg_status,
                                       tt.flg_time,
                                       tt.code_lab,
                                       tt.flg_referral,
                                       tt.status_str,
                                       tt.status_msg,
                                       tt.status_icon,
                                       tt.status_flg,
                                       tt.msg_notes,
                                       tt.tooltip_title_notes_tech,
                                       tt.tooltip_text_notes_tech,
                                       tt.tooltip_title_notes_pat,
                                       tt.tooltip_text_notes_pat,
                                       tt.tooltip_title_lab_test,
                                       tt.code_sample,
                                       tt.id_episode_origin,
                                       tt.id_analysis_req_det,
                                       tt.numb3,
                                       tt.numb4,
                                       tt.numb5,
                                       tt.numb6,
                                       tt.numb7,
                                       tt.numb8,
                                       tt.numb9,
                                       tt.numb10,
                                       tt.numb11,
                                       tt.numb12,
                                       tt.numb13,
                                       tt.numb14,
                                       tt.numb15,
                                       tt.dt_begin,
                                       tt.dt_req,
                                       tt.currdate,
                                       tt.dt_analysis_result,
                                       tt.dt_tstz5,
                                       tt.dt_tstz6,
                                       tt.dt_tstz7,
                                       tt.dt_tstz8,
                                       tt.dt_tstz9,
                                       tt.dt_tstz10,
                                       tt.dt_tstz11,
                                       tt.dt_tstz12,
                                       tt.dt_tstz13,
                                       tt.dt_tstz14,
                                       tt.dt_tstz15,
                                       tt.rank)
          BULK COLLECT
          INTO l_records
          FROM (SELECT t.*, row_number() over(ORDER BY t.rank) AS rn
                  FROM (SELECT lta.status_flg flg_status, --VARCH1
                               lta.flg_time_harvest flg_time, --VARCH2
                               'ANALYSIS.CODE_ANALYSIS.' || lta.id_analysis code_lab, --VARCH3
                               lta.flg_referral flg_referral, --VARCH4
                               lta.status_str status_str, --VARCH5
                               lta.status_msg status_msg, --VARCH6
                               lta.status_icon status_icon, --VARCH7
                               lta.status_flg status_flg, --VARCH8
                               decode(lta.flg_notes, pk_lab_tests_constant.g_no, '', l_msg_notes) msg_notes, --VARCH9                      
                               (SELECT pk_message.get_message(i_lang, 'LAB_TESTS_T113')
                                  FROM dual) || ':' tooltip_title_notes_tech, --VARCH10
                               ard.notes_tech tooltip_text_notes_tech, --VARCH11                      
                               (SELECT pk_message.get_message(i_lang, 'LAB_TESTS_T114')
                                  FROM dual) || ':' tooltip_title_notes_pat, --VARCH12
                               ard.notes_patient tooltip_text_notes_pat, --VARCH13                                           
                               (SELECT pk_message.get_message(i_lang, 'LAB_TESTS_T115')
                                  FROM dual) || ':' tooltip_title_lab_test, --VARCH14                                                 
                               'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lta.id_sample_type code_sample, --VARCH15                                            
                               lta.id_prev_episode id_episode_origin, --NUMB1
                               lta.id_analysis_req_det id_analysis_req_det, --NUMB2
                               NULL numb3, --NUMB3
                               NULL numb4, --NUMB4
                               NULL numb5, --NUMB5
                               NULL numb6, --NUMB6
                               NULL numb7, --NUMB7
                               NULL numb8, --NUMB8
                               NULL numb9, --NUMB9                     
                               NULL numb10, --NUMB10
                               NULL numb11, --NUMB11
                               NULL numb12, --NUMB12
                               NULL numb13, --NUMB13
                               NULL numb14, --NUMB14                     
                               NULL numb15, --NUMB15                       
                               nvl(lta.dt_pend_req, lta.dt_target) dt_begin, --DT_TSTZ1
                               lta.dt_req dt_req, --DT_TSTZ2
                               g_sysdate_tstz currdate, --DT_TSTZ3                     
                               lta.dt_analysis_result, --DT_TSTZ4
                               NULL dt_tstz5, --DT_TSTZ5
                               NULL dt_tstz6, --DT_TSTZ6
                               NULL dt_tstz7, --DT_TSTZ7
                               NULL dt_tstz8, --DT_TSTZ8
                               NULL dt_tstz9, --DT_TSTZ9
                               NULL dt_tstz10, --DT_TSTZ10
                               NULL dt_tstz11, --DT_TSTZ11
                               NULL dt_tstz12, --DT_TSTZ12                     
                               NULL dt_tstz13, --DT_TSTZ13
                               NULL dt_tstz14, --DT_TSTZ14
                               NULL dt_tstz15, --DT_TSTZ15                                             
                               decode(lta.flg_status_det,
                                      pk_lab_tests_constant.g_analysis_result,
                                      0,
                                      pk_lab_tests_constant.g_analysis_req,
                                      row_number() over(ORDER BY decode(lta.flg_referral,
                                                  NULL,
                                                  pk_sysdomain.get_rank(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        lta.flg_status_det),
                                                  pk_sysdomain.get_rank(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                        lta.flg_referral)),
                                           coalesce(lta.dt_pend_req, lta.dt_target, lta.dt_req)),
                                      pk_lab_tests_constant.g_analysis_pending,
                                      row_number() over(ORDER BY decode(lta.flg_referral,
                                                  NULL,
                                                  pk_sysdomain.get_rank(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        lta.flg_status_det),
                                                  pk_sysdomain.get_rank(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                        lta.flg_referral)),
                                           coalesce(lta.dt_pend_req, lta.dt_target, lta.dt_req)),
                                      row_number() over(ORDER BY decode(lta.flg_referral,
                                                  NULL,
                                                  decode(lta.flg_status_det,
                                                         pk_lab_tests_constant.g_analysis_toexec,
                                                         pk_sysdomain.get_rank(i_lang,
                                                                               'HARVEST.FLG_STATUS',
                                                                               lta.flg_status_harvest),
                                                         pk_sysdomain.get_rank(i_lang,
                                                                               'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                               lta.flg_status_det)),
                                                  pk_sysdomain.get_rank(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                        lta.flg_referral)),
                                           coalesce(lta.dt_pend_req, lta.dt_target, lta.dt_req) DESC)) rank --RANK
                          FROM lab_tests_ea lta,
                               analysis_req_det ard,
                               (SELECT DISTINCT gar.id_record id_analysis
                                  FROM group_access ga
                                 INNER JOIN group_access_prof gaf
                                    ON gaf.id_group_access = ga.id_group_access
                                 INNER JOIN group_access_record gar
                                    ON gar.id_group_access = ga.id_group_access
                                 WHERE ga.id_institution IN (i_prof.institution)
                                   AND ga.id_software IN (i_prof.software)
                                   AND ga.flg_type = pk_lab_tests_constant.g_infectious_diseases_orders
                                   AND gar.flg_type = 'A'
                                   AND ga.flg_available = pk_lab_tests_constant.g_available
                                   AND gaf.flg_available = pk_lab_tests_constant.g_available
                                   AND gar.flg_available = pk_lab_tests_constant.g_available) a_infect
                         WHERE lta.id_patient = i_patient
                           AND lta.flg_status_det NOT IN
                               (pk_lab_tests_constant.g_analysis_draft, pk_lab_tests_constant.g_analysis_cancel)
                           AND lta.id_analysis_req_det = ard.id_analysis_req_det
                           AND lta.id_analysis = a_infect.id_analysis(+)
                           AND ((a_infect.id_analysis IS NULL) OR (l_flg_all_rows = pk_alert_constant.g_yes))
                           AND ((i_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                               lta.flg_status_det IN
                               (pk_lab_tests_constant.g_analysis_result, pk_lab_tests_constant.g_analysis_read)) OR
                               (i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                               lta.flg_status_det NOT IN
                               (pk_lab_tests_constant.g_analysis_read, pk_lab_tests_constant.g_analysis_cancel) AND
                               (lta.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                      *
                                                       FROM TABLE(l_episode) t) OR lta.id_episode IS NULL)))
                           AND trunc(months_between(SYSDATE, lta.dt_req) / 12) <= l_viewer_lim_tasktime_lab
                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lta.id_analysis)
                                  FROM dual) = pk_alert_constant.g_yes) t) tt
         WHERE (l_viewer_lab_limit = 0 OR tt.rn <= l_viewer_lab_limit);
    
        IF (i_flg_all_rows)
        THEN
            g_error := 'OPEN O_ORDERED_LIST ALL ROWS';
            OPEN o_ordered_list FOR
                SELECT numb2 id,
                       varch3 || '|' || varch15 code_description,
                       decode(i_translate,
                              pk_lab_tests_constant.g_no,
                              NULL,
                              pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                       i_prof,
                                                                       pk_lab_tests_constant.g_analysis_alias,
                                                                       varch3,
                                                                       varch15,
                                                                       NULL)) description,
                       nvl(dt_tstz4, nvl(dt_tstz1, dt_tstz2)) dt_req_tstz,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(dt_tstz4, nvl(dt_tstz1, dt_tstz2)), i_prof) dt_req,
                       varch1 flg_status,
                       varch9 msg_notes,
                       varch10 tooltip_title_notes_tech,
                       varch11 tooltip_text_notes_tech,
                       varch12 tooltip_title_notes_pat,
                       varch13 tooltip_text_notes_pat,
                       varch14 tooltip_title_lab_test,
                       decode(i_translate,
                              pk_lab_tests_constant.g_no,
                              NULL,
                              pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                       i_prof,
                                                                       pk_lab_tests_constant.g_analysis_alias,
                                                                       varch3,
                                                                       varch15,
                                                                       NULL)) tooltip_text_lab_test,
                       decode(varch1,
                              pk_alert_constant.g_analysis_det_result,
                              pk_alert_constant.g_flg_type_viewer_analysis_res,
                              pk_alert_constant.g_analysis_det_read,
                              pk_alert_constant.g_flg_type_viewer_analysis_res,
                              pk_alert_constant.g_flg_type_viewer_analysis) flg_type,
                       pk_utils.get_status_string(i_lang, i_prof, varch5, varch6, varch7, varch8) desc_status,
                       rank,
                       numb4 rank_order,
                       l_task_title task_title
                  FROM TABLE(l_records)
                 ORDER BY rank, description;
        ELSE
            g_error := 'OPEN O_ORDERED_LIST ONE ROW';
            OPEN o_ordered_list FOR
                SELECT code_description, description, dt_req_tstz, rows_count
                  FROM (SELECT NULL id,
                               varch3 || '|' || varch15 code_description,
                               decode(i_translate,
                                      pk_lab_tests_constant.g_no,
                                      NULL,
                                      pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                               i_prof,
                                                                               pk_lab_tests_constant.g_analysis_alias,
                                                                               varch3,
                                                                               varch15,
                                                                               NULL)) description,
                               nvl(dt_tstz4, nvl(dt_tstz1, dt_tstz2)) dt_req_tstz,
                               NULL flg_status,
                               NULL msg_notes,
                               NULL tooltip_title_notes_tech,
                               NULL tooltip_text_notes_tech,
                               NULL tooltip_title_notes_pat,
                               NULL tooltip_text_notes_pat,
                               NULL tooltip_title_lab_test,
                               NULL tooltip_title_lab_test,
                               NULL flg_type,
                               NULL desc_status,
                               NULL rank,
                               NULL rank_order,
                               COUNT(numb2) over() rows_count,
                               row_number() over(ORDER BY rank) srlno,
                               pk_message.get_message(i_lang, 'EHR_VIEWER_T200') task_title
                          FROM TABLE(l_records))
                 WHERE srlno = 1;
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
                                              'GET_ORDERED_LIST_INTERNAL',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list_internal;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL, --se ‘N?os código não serão traduzidos
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_ORDERED_LIST_INTERNAL';
        IF NOT get_ordered_list_internal(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_patient      => i_patient,
                                         i_translate    => i_translate,
                                         i_flg_all_rows => TRUE,
                                         i_viewer_area  => i_viewer_area,
                                         i_episode      => i_episode,
                                         o_ordered_list => o_ordered_list,
                                         o_error        => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'GET_ORDERED_LIST',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list;

    FUNCTION get_ordered_list_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_ORDERED_LIST_DET';
        OPEN o_ordered_list_det FOR
            SELECT nvl(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                i_prof,
                                                                pk_lab_tests_constant.g_analysis_alias,
                                                                'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                                NULL),
                       'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis || '|' || 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                       lte.id_sample_type) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, lte.id_prof_writes, lte.dt_req, lte.id_episode) prof_spec_reg,
                   lte.flg_time_harvest flg_time,
                   lte.dt_req dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, lte.dt_req, i_prof) dt_req,
                   lte.dt_target dt_begin_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, lte.dt_target, i_prof) dt_begin,
                   lte.dt_pend_req dt_pend_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, lte.dt_pend_req, i_prof) dt_pend_req,
                   lte.dt_harvest dt_harvest_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, lte.dt_harvest, i_prof) dt_harvest,
                   lte.flg_status_det flg_status,
                   lte.flg_referral,
                   lte.flg_status_harvest,
                   decode(lte.flg_referral,
                          pk_lab_tests_constant.g_flg_referral_s,
                          pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', lte.flg_referral),
                          pk_lab_tests_constant.g_flg_referral_r,
                          pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', lte.flg_referral),
                          pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det)) icon_name,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || lte.id_institution) institution,
                   lte.id_episode_origin
              FROM lab_tests_ea lte
             WHERE lte.id_analysis_req_det = i_analysis_req_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST_DET',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list_det;

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'GET ORDERED LIST';
        IF get_ordered_list_internal(i_lang,
                                     i_prof,
                                     i_patient,
                                     pk_lab_tests_constant.g_no,
                                     FALSE,
                                     i_viewer_area,
                                     i_episode,
                                     l_list,
                                     o_error)
        THEN
            FETCH l_list
                INTO o_code_first, o_desc_first, o_dt_first, o_num_occur;
        
            RETURN TRUE;
        ELSE
        
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            RAISE g_user_exception;
        
        END IF;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              'U',
                                              g_error,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_count_and_first;

    FUNCTION get_lab_test_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM lab_tests_ea lte
         WHERE lte.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e
           AND lte.flg_status_det NOT IN (pk_lab_tests_constant.g_analysis_exterior,
                                          pk_lab_tests_constant.g_analysis_cancel,
                                          pk_lab_tests_constant.g_analysis_predefined,
                                          pk_lab_tests_constant.g_analysis_draft)
           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                  FROM dual) = pk_alert_constant.g_yes;
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM lab_tests_ea lte
             WHERE lte.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e
               AND lte.flg_status_det NOT IN (pk_lab_tests_constant.g_analysis_result,
                                              pk_lab_tests_constant.g_analysis_read,
                                              pk_lab_tests_constant.g_analysis_exterior,
                                              pk_lab_tests_constant.g_analysis_cancel,
                                              pk_lab_tests_constant.g_analysis_predefined,
                                              pk_lab_tests_constant.g_analysis_draft)
               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                      FROM dual) = pk_alert_constant.g_yes;
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            RETURN pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_lab_test_viewer_checklist;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
        l_patients table_number;
        l_error    t_error_out;
    
    BEGIN
    
        SELECT id_patient
          BULK COLLECT
          INTO l_patients
          FROM viewer_ehr_ea vee;
    
        IF NOT upd_viewer_ehr_ea_pat(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_table_id_patients => l_patients,
                                     o_error             => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
    END upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_occur  table_number := table_number();
        l_desc_first table_varchar := table_varchar();
        l_code_first table_varchar := table_varchar();
        l_dt_first   table_varchar := table_varchar();
        l_episode    table_number := table_number();
    
    BEGIN
    
        g_error := 'START UPD_VIEWER_EHR_EA_PAT';
        l_num_occur.extend(i_table_id_patients.count);
        l_desc_first.extend(i_table_id_patients.count);
        l_code_first.extend(i_table_id_patients.count);
        l_dt_first.extend(i_table_id_patients.count);
        l_episode.extend(i_table_id_patients.count);
    
        FOR i IN i_table_id_patients.first .. i_table_id_patients.last
        LOOP
            g_error := 'CALL GET_COUNT_AND_FIRST ' || i_table_id_patients(i);
            IF NOT get_count_and_first(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_patient     => i_table_id_patients(i),
                                       i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                       i_episode     => l_episode(i),
                                       o_num_occur   => l_num_occur(i),
                                       o_desc_first  => l_desc_first(i),
                                       o_code_first  => l_code_first(i),
                                       o_dt_first    => l_dt_first(i),
                                       o_error       => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        g_error := 'FORALL';
        FORALL i IN i_table_id_patients.first .. i_table_id_patients.last
            UPDATE viewer_ehr_ea
               SET num_lab  = l_num_occur(i),
                   desc_lab = l_desc_first(i),
                   dt_lab   = l_dt_first(i),
                   code_lab = l_code_first(i)
             WHERE id_patient = i_table_id_patients(i) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject
             LIMIT unlimited;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    PROCEDURE crisis_machine_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION tf_cm_lab_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
        l_tbl_cm_episodes t_tbl_cm_episodes;
    
        l_show_inactive   sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('LAB_TECH_SHOW_INACTIVE', i_prof);
        l_collect_pending sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('HARVEST_PENDING_REQ', i_prof);
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + i_search_interval;
    
        SELECT t_rec_cm_episodes(t.id_episode,
                                 t.id_patient,
                                 t.id_schedule,
                                 MAX(t.dt_target),
                                 t.dt_last_interaction_tstz,
                                 t.id_software)
          BULK COLLECT
          INTO l_tbl_cm_episodes
          FROM (SELECT gtl.id_episode,
                       gtl.id_patient,
                       NULL                             id_schedule,
                       gtl.dt_target_tstz               dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_labtech id_software
                  FROM grid_task_lab gtl, epis_info ei, announced_arrival aa
                 WHERE gtl.id_institution = i_prof.institution
                   AND ((gtl.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e AND
                       (((gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_req,
                                                   pk_lab_tests_constant.g_analysis_result,
                                                   pk_lab_tests_constant.g_analysis_read) OR
                       (gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_pending AND
                       nvl(l_collect_pending, pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes)) AND
                       gtl.flg_status_epis = pk_alert_constant.g_epis_status_active) OR
                       gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_toexec OR
                       nvl(l_show_inactive, pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes)) OR
                       (gtl.flg_time_harvest IN
                       (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) AND
                       gtl.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end) OR
                       (gtl.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND
                       (((gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_req,
                                                   pk_lab_tests_constant.g_analysis_result,
                                                   pk_lab_tests_constant.g_analysis_read) OR
                       (gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_pending AND
                       nvl(l_collect_pending, pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes)) AND
                       gtl.flg_status_epis = pk_alert_constant.g_epis_status_active) OR
                       gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_toexec OR
                       nvl(l_show_inactive, pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes)))
                   AND ei.id_episode = gtl.id_episode
                   AND aa.id_episode(+) = gtl.id_episode
                   AND pk_announced_arrival.get_ann_arrival_id(gtl.id_institution,
                                                               ei.id_software,
                                                               gtl.id_episode,
                                                               ei.flg_unknown,
                                                               aa.id_announced_arrival,
                                                               aa.flg_status) IS NOT NULL
                UNION
                SELECT gtl.id_episode,
                       gtl.id_patient,
                       NULL                             id_schedule,
                       gtl.dt_target_tstz               dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_labtech id_software
                  FROM grid_task_lab gtl, epis_info ei
                 WHERE gtl.id_institution = i_prof.institution
                   AND gtl.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                   AND (gtl.flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) OR
                       (gtl.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e AND
                       (gtl.id_episode IS NULL OR gtl.id_epis_type = pk_lab_tests_constant.g_episode_type_lab)))
                   AND gtl.id_episode = ei.id_episode(+)) t
         GROUP BY t.id_episode, t.id_patient, t.id_schedule, t.dt_last_interaction_tstz, t.id_software;
    
        RETURN l_tbl_cm_episodes;
    
    END tf_cm_lab_episodes;

    FUNCTION tf_cm_lab_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_lab_episodes IS
    
        l_tbl_lab_episodes t_tbl_lab_episodes;
    
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
        SELECT t_rec_lab_episodes(id_episode,
                                  id_schedule,
                                  origin,
                                  origin_desc,
                                  pat_name,
                                  pat_name_sort,
                                  pat_age,
                                  pat_gender,
                                  photo,
                                  num_clin_record,
                                  name_prof_resp,
                                  name_prof_req,
                                  desc_analysis,
                                  flg_lab_status,
                                  flg_status,
                                  flg_status_desc,
                                  flg_status_icon,
                                  dt_target,
                                  dt_target_tstz,
                                  dt_admission_tstz,
                                  epis_duration,
                                  epis_duration_desc,
                                  rank_acuity,
                                  acuity)
          BULK COLLECT
          INTO l_tbl_lab_episodes
          FROM (SELECT id_episode,
                       NULL id_schedule,
                       id_epis_type origin,
                       pk_message.get_message(i_lang,
                                              profissional(i_prof.id, i_prof.institution, id_software),
                                              'IMAGE_T009') origin_desc,
                       pk_patient.get_patient_name(i_lang, id_patient) pat_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, id_patient, id_episode, NULL) pat_name_sort,
                       pat_age,
                       pk_patient.get_gender(i_lang, gender) pat_gender,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, id_patient, id_episode, NULL) photo,
                       num_clin_record,
                       NULL name_prof_resp,
                       substr(concatenate_clob(pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || '; '),
                              1,
                              length(concatenate_clob(pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || '; ')) - 2) name_prof_req,
                       substr(concatenate_clob(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                         i_prof,
                                                                                         pk_lab_tests_constant.g_analysis_alias,
                                                                                         'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                         id_analysis,
                                                                                         NULL) || ' / '),
                              1,
                              length(concatenate_clob(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                                i_prof,
                                                                                                pk_lab_tests_constant.g_analysis_alias,
                                                                                                'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                                id_analysis,
                                                                                                NULL) || ' / ')) - 3) desc_analysis,
                       flg_lab_status,
                       NULL flg_status,
                       NULL flg_status_desc,
                       NULL flg_status_icon,
                       pk_date_utils.date_time_chr_tsz(i_lang, MAX(dt_target_tstz), i_prof) dt_target,
                       pk_date_utils.date_send_tsz(i_lang, MAX(dt_target_tstz), i_prof) dt_target_tstz,
                       pk_date_utils.date_send_tsz(i_lang, MAX(dt_target_tstz), i_prof) dt_admission_tstz,
                       decode(flg_lab_status,
                              'S',
                              decode(id_episode,
                                     NULL,
                                     decode(MAX(flg_status_ard),
                                            pk_lab_tests_constant.g_analysis_cancel,
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_lab_tests_constant.g_analysis_nr),
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_lab_tests_constant.g_analysis_sched)),
                                     decode(MAX(dt_pend_req_tstz),
                                            NULL,
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_exam_constant.g_waiting_technician),
                                            decode(flg_status_epis,
                                                   pk_lab_tests_constant.g_active,
                                                   pk_sysdomain.get_rank(i_lang,
                                                                         'ADMIN_SCH_EXAM',
                                                                         pk_exam_constant.g_in_technician),
                                                   pk_sysdomain.get_rank(i_lang,
                                                                         'ADMIN_SCH_EXAM',
                                                                         pk_exam_constant.g_end_technician)))),
                              pk_date_utils.date_send_tsz(i_lang, MAX(dt_target_tstz), i_prof)) epis_duration,
                       decode(flg_lab_status,
                              'S',
                              decode(id_episode,
                                     NULL,
                                     decode(MAX(flg_status_ard),
                                            pk_lab_tests_constant.g_analysis_cancel,
                                            pk_sysdomain.get_img(i_lang,
                                                                 'ADMIN_SCH_EXAM',
                                                                 pk_lab_tests_constant.g_analysis_nr),
                                            pk_sysdomain.get_img(i_lang,
                                                                 'ADMIN_SCH_EXAM',
                                                                 pk_lab_tests_constant.g_analysis_sched)),
                                     decode(MAX(dt_pend_req_tstz),
                                            NULL,
                                            pk_sysdomain.get_img(i_lang,
                                                                 'ADMIN_SCH_EXAM',
                                                                 pk_exam_constant.g_waiting_technician),
                                            decode(flg_status_epis,
                                                   pk_lab_tests_constant.g_active,
                                                   pk_sysdomain.get_img(i_lang,
                                                                        'ADMIN_SCH_EXAM',
                                                                        pk_exam_constant.g_in_technician),
                                                   pk_sysdomain.get_img(i_lang,
                                                                        'ADMIN_SCH_EXAM',
                                                                        pk_exam_constant.g_end_technician)))),
                              pk_date_utils.get_elapsed_time_tsz(i_lang, MAX(dt_target_tstz))) epis_duration_desc,
                       rank_acuity,
                       acuity
                  FROM (SELECT DISTINCT decode(gtl.flg_time_harvest,
                                               pk_lab_tests_constant.g_flg_time_b,
                                               'S',
                                               pk_lab_tests_constant.g_flg_time_d,
                                               'S',
                                               'NS') flg_lab_status,
                                        gtl.id_patient,
                                        gtl.id_episode,
                                        gtl.id_epis_type,
                                        gtl.id_software,
                                        gtl.pat_age,
                                        gtl.gender,
                                        gtl.num_clin_record,
                                        ard.id_analysis,
                                        gtl.id_professional,
                                        gtl.dt_target_tstz,
                                        gtl.dt_pend_req_tstz,
                                        gtl.flg_status_ard,
                                        gtl.flg_status_epis,
                                        gtl.rank_acuity,
                                        gtl.acuity
                          FROM grid_task_lab gtl, analysis_req_det ard
                         WHERE gtl.id_episode = nvl(i_episode,
                                                    (SELECT MAX(id_episode)
                                                       FROM epis_info e
                                                      WHERE e.id_schedule = i_schedule))
                           AND gtl.id_analysis_req_det = ard.id_analysis_req_det)
                 GROUP BY flg_lab_status,
                          id_patient,
                          id_episode,
                          id_epis_type,
                          id_software,
                          gender,
                          pat_age,
                          num_clin_record,
                          id_professional,
                          flg_status_epis,
                          rank_acuity,
                          acuity);
    
        RETURN l_tbl_lab_episodes;
    
    END tf_cm_lab_episode_detail;

    PROCEDURE context_help__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_context_help
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis            IN table_varchar,
        i_analysis_result_par IN table_number,
        o_content             OUT table_varchar,
        o_map_target_code     OUT table_varchar,
        o_id_map_set          OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_analysis           table_varchar;
        l_id_sample_type        table_varchar;
        l_id_analysis_parameter table_varchar;
        l_id_map_set_target     xmap_set.id_map_set%TYPE;
        l_id_map_set_source     xmap_set.id_map_set%TYPE;
    
        l_cnt_concat VARCHAR2(2000);
    
        l_map_target_code VARCHAR2(2000);
        l_id_map_set      VARCHAR2(100 CHAR) := '2.16.840.1.113883.6.1';
    
    BEGIN
    
        o_content := table_varchar();
        o_content.extend(i_analysis_result_par.count);
        o_map_target_code := table_varchar();
        o_map_target_code.extend(i_analysis_result_par.count);
        o_id_map_set := table_varchar();
        o_id_map_set.extend(i_analysis_result_par.count);
    
        IF i_analysis_result_par.count > 0
        THEN
            SELECT ar.id_analysis, ar.id_sample_type, arp.id_analysis_parameter
              BULK COLLECT
              INTO l_id_analysis, l_id_sample_type, l_id_analysis_parameter
              FROM analysis_result_par arp, analysis_result ar
             WHERE arp.id_analysis_result = ar.id_analysis_result
               AND arp.id_analysis_result_par IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                   *
                                                    FROM TABLE(i_analysis_result_par) t);
        
        ELSE
            BEGIN
                SELECT xs.id_map_set
                  INTO l_id_map_set_source
                  FROM xmap_set xs
                 WHERE xs.map_set_name = 'ALERT Content';
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'No id_map_set configured to ALERT Content';
                    RAISE g_other_exception;
            END;
        
            BEGIN
                SELECT xs.id_map_set
                  INTO l_id_map_set_target
                  FROM xmap_set xs
                 WHERE xs.map_set_name = 'LOINC';
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'No id_map_set configured to LOINC';
                    RAISE g_other_exception;
            END;
        
            FOR i IN 1 .. i_analysis.count
            LOOP
                l_map_target_code := pk_mapping_sets.get_mapping_concept(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_source_concept => l_cnt_concat,
                                                                         i_source_map_set => l_id_map_set_source,
                                                                         i_target_map_set => l_id_map_set_target);
            
                o_content(i) := l_cnt_concat;
                o_map_target_code(i) := l_map_target_code;
                o_id_map_set(i) := l_id_map_set;
            END LOOP;
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
                                              'GET_LAB_TEST_CONTEXT_HELP',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_context_help;

    PROCEDURE cda______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_cda
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type_scope   IN VARCHAR2,
        i_id_scope     IN NUMBER,
        o_lab_test_cda OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_type_scope = ' || coalesce(to_char(i_type_scope), '<null>');
        g_error := g_error || ' i_id_scope = ' || coalesce(to_char(i_id_scope), '<null>');
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Call pk_touch_option.get_scope_vars';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' o_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' o_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' o_episode = ' || coalesce(to_char(l_id_episode), '<null>');
    
        OPEN o_lab_test_cda FOR
            SELECT t.id,
                   t.id_content || decode(t.id_content_par, NULL, '', '|' || t.id_content_par) id_content,
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || t.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                            NULL) description,
                   t.flg_status,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ_DET.FLG_STATUS', t.flg_status, NULL) flg_status_desc,
                   t.dt_value,
                   t.notes
              FROM (SELECT *
                      FROM (SELECT lea.id_analysis_req id,
                                   ast.id_content,
                                   apr.id_content id_content_par,
                                   lea.id_analysis,
                                   lea.id_sample_type,
                                   lea.flg_status_det flg_status,
                                   coalesce(lea.dt_pend_req, lea.dt_target, lea.dt_req) dt_value,
                                   lea.notes,
                                   nvl(lea.id_episode, lea.id_episode_origin) id_episode,
                                   pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', lea.flg_status_det) rank
                              FROM lab_tests_ea lea
                             INNER JOIN analysis_req ar
                                ON ar.id_analysis_req = lea.id_analysis_req
                             INNER JOIN analysis_req_det ard
                                ON ard.id_analysis_req_det = lea.id_analysis_req_det
                             INNER JOIN analysis a
                                ON a.id_analysis = lea.id_analysis
                             INNER JOIN analysis_sample_type ast
                                ON ast.id_analysis = lea.id_analysis
                               AND ast.id_sample_type = lea.id_sample_type
                              JOIN (SELECT ap.*,
                                          COUNT(ap.id_analysis_parameter) over(PARTITION BY ap.id_analysis, ap.id_sample_type, ap.id_institution, ap.id_software) ap_count
                                     FROM analysis_param ap
                                    WHERE ap.flg_available = pk_lab_tests_constant.g_available
                                      AND ap.id_software = i_prof.software
                                      AND ap.id_institution = i_prof.institution) ap
                                ON ap.id_analysis = lea.id_analysis
                               AND ap.id_sample_type = lea.id_sample_type
                              JOIN analysis_parameter apr
                                ON (ap.id_analysis_parameter = apr.id_analysis_parameter)
                             WHERE lea.flg_status_det IN (pk_lab_tests_constant.g_analysis_pending,
                                                          pk_lab_tests_constant.g_analysis_req,
                                                          pk_lab_tests_constant.g_analysis_tosched,
                                                          pk_lab_tests_constant.g_analysis_wtg_tde,
                                                          pk_lab_tests_constant.g_analysis_sched)) labs
                     INNER JOIN (SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_episode = l_id_episode
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_episode
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_patient
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_visit = l_id_visit
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_visit) epi
                        ON epi.id_episode = labs.id_episode
                     ORDER BY rank, dt_value DESC) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_CDA',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_cda);
            RETURN FALSE;
    END get_lab_test_cda;

    PROCEDURE scheduler__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_req_to_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN table_number,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_department IN room.id_department%TYPE DEFAULT NULL,
        i_pat_age_min   IN patient.age%TYPE DEFAULT NULL,
        i_pat_age_max   IN patient.age%TYPE DEFAULT NULL,
        i_pat_gender    IN patient.gender%TYPE DEFAULT NULL,
        i_start         IN NUMBER DEFAULT NULL,
        i_offset        IN NUMBER DEFAULT NULL,
        o_list          OUT pk_lab_tests_external.t_cur_lab_test_to_schedule,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start NUMBER(24) := 1;
        l_end   NUMBER(24) := 99999999999999999999;
    
        l_pat_age_min patient.age%TYPE;
        l_pat_age_max patient.age%TYPE;
    
    BEGIN
        IF i_institution IS NULL
           OR i_institution.count = 0
        THEN
            g_error := 'Institution list is null';
            RAISE g_other_exception;
        END IF;
    
        IF i_start IS NOT NULL
           AND i_offset IS NOT NULL
        THEN
            l_end   := i_start * i_offset;
            l_start := l_end - i_offset + 1;
        END IF;
    
        l_pat_age_min := nvl(i_pat_age_min, 0);
        l_pat_age_max := nvl(i_pat_age_max, 99999);
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT lab.id_patient,
                   NULL                                           id_dep_clin_serv,
                   lab.id_service,
                   NULL                                           id_speciality,
                   NULL                                           id_content,
                   pk_schedule_api_downstream.g_proc_req_type_req flg_type,
                   lab.id_requisition,
                   lab.dt_creation,
                   lab.id_user_creation,
                   lab.id_institution,
                   lab.id_resource,
                   pk_schedule_api_downstream.g_proc_req_type_req type_resource,
                   lab.dt_sugested,
                   NULL                                           dt_begin_min,
                   NULL                                           dt_begin_max,
                   NULL                                           flg_contact_type,
                   NULL                                           priority,
                   NULL                                           id_language,
                   NULL                                           id_motive,
                   NULL                                           type_motive,
                   NULL                                           motive_desc,
                   NULL                                           dayly_number_days,
                   NULL                                           flg_weekly_friday,
                   NULL                                           flg_weekly_monday,
                   NULL                                           flg_weekly_saturday,
                   NULL                                           flg_weekly_sunday,
                   NULL                                           flg_weekly_thursday,
                   NULL                                           flg_weekly_tuesday,
                   NULL                                           flg_weekly_wednesday,
                   NULL                                           weekly_number_weeks,
                   NULL                                           monthly_number_months,
                   NULL                                           monthly_day_number,
                   NULL                                           monthly_week_day,
                   NULL                                           monthly_week_number,
                   NULL                                           yearly_year_number,
                   NULL                                           yearly_month_day_number,
                   NULL                                           yearly_month_number,
                   NULL                                           yearly_week_day,
                   NULL                                           yearly_week_number,
                   NULL                                           yearly_week_day_month_number,
                   NULL                                           flg_reccurence_pattern,
                   NULL                                           recurrence_begin_date,
                   NULL                                           recurrence_end_date,
                   NULL                                           recurrence_end_number,
                   NULL                                           session_number,
                   NULL                                           frequency_unit,
                   NULL                                           frequency,
                   lab.total
              FROM (SELECT aux.*, rownum rn, COUNT(*) over() total
                      FROM (SELECT DISTINCT ar.id_patient,
                                            r.id_department id_service,
                                            ard.id_analysis_req id_requisition,
                                            ar.dt_req_tstz dt_creation,
                                            ar.id_prof_writes id_user_creation,
                                            ar.id_institution,
                                            ard.id_room id_resource,
                                            ard.dt_schedule dt_sugested,
                                            nvl(pk_patient.get_pat_age(i_age         => p.age,
                                                                       i_age_format  => 'YEARS',
                                                                       i_dt_birth    => p.dt_birth,
                                                                       i_dt_deceased => p.dt_deceased,
                                                                       i_lang        => i_lang,
                                                                       i_patient     => p.id_patient),
                                                0) age,
                                            p.gender
                              FROM analysis_req_det ard
                             INNER JOIN analysis_req ar
                                ON ard.id_analysis_req = ar.id_analysis_req
                             INNER JOIN patient p
                                ON p.id_patient = ar.id_patient
                              LEFT OUTER JOIN room r
                                ON r.id_room = ard.id_room
                             WHERE ar.dt_begin_tstz IS NULL
                               AND ar.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                          column_value
                                                           FROM TABLE(i_institution) t)
                               AND ard.flg_status = pk_lab_tests_constant.g_analysis_tosched
                               AND (r.id_department = i_id_department OR i_id_department IS NULL)) aux
                     WHERE CASE
                               WHEN i_patient IS NOT NULL
                                    AND aux.id_patient = i_patient THEN
                                1
                               WHEN i_patient IS NULL
                                    AND (aux.gender = i_pat_gender OR i_pat_gender IS NULL)
                                    AND aux.age BETWEEN l_pat_age_min AND l_pat_age_max THEN
                                1
                               ELSE
                                0
                           END = 1
                     ORDER BY aux.dt_creation ASC) lab
             WHERE lab.rn BETWEEN l_start AND l_end;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_REQ_TO_SCHEDULE',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_req_to_schedule;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_lab_test_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_episode(i_episode episode.id_episode%TYPE) IS
            SELECT e.id_patient, e.id_visit
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        IF i_patient IS NULL
        THEN
            g_error := 'OPEN C_EPISODE - i_episode: ' || i_episode;
            OPEN c_episode(i_episode);
            FETCH c_episode
                INTO l_patient, l_visit;
            CLOSE c_episode;
        
            l_episode := i_episode;
        
            IF l_patient IS NULL
               OR l_visit IS NULL
               OR l_episode IS NULL
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE ANALYSIS_QUESTION_RESPONSE';
            UPDATE analysis_question_response aqr
               SET aqr.id_episode = i_episode
             WHERE aqr.id_episode = i_episode_temp;
        
            g_error := 'UPDATE ANALYSIS_QUESTION_RESP_HIST';
            UPDATE analysis_question_resp_hist aqr
               SET aqr.id_episode = i_episode
             WHERE aqr.id_episode = i_episode_temp;
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_episode_in  => i_episode,
                                id_episode_nin => FALSE,
                                id_visit_in    => l_visit,
                                id_visit_nin   => FALSE,
                                where_in       => 'id_episode = ' || i_episode_temp,
                                rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ (id_episode_origin)';
            ts_analysis_req.upd(id_episode_origin_in  => i_episode,
                                id_episode_origin_nin => FALSE,
                                where_in              => 'id_episode_origin = ' || i_episode_temp,
                                rows_out              => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ (id_episode_destination)';
            ts_analysis_req.upd(id_episode_destination_in  => i_episode,
                                id_episode_destination_nin => FALSE,
                                where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                rows_out                   => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ (id_prev_episode) ';
            ts_analysis_req.upd(id_prev_episode_in  => i_episode,
                                id_prev_episode_nin => FALSE,
                                where_in            => 'id_prev_episode = ' || i_episode_temp,
                                rows_out            => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_REQ',
                                          i_list_columns => table_varchar('ID_EPISODE',
                                                                          'ID_VISIT',
                                                                          'ID_EPISODE_ORIGIN',
                                                                          'ID_EPISODE_DESTINATION',
                                                                          'ID_PREV_EPISODE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_REQ_HIST';
            ts_analysis_req_hist.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     id_visit_in    => l_visit,
                                     id_visit_nin   => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ_HIST (id_episode_origin)';
            ts_analysis_req_hist.upd(id_episode_origin_in  => i_episode,
                                     id_episode_origin_nin => FALSE,
                                     where_in              => 'id_episode_origin = ' || i_episode_temp,
                                     rows_out              => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ_HIST (id_episode_destination)';
            ts_analysis_req_hist.upd(id_episode_destination_in  => i_episode,
                                     id_episode_destination_nin => FALSE,
                                     where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                     rows_out                   => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ_HIST (id_prev_episode)';
            ts_analysis_req_hist.upd(id_prev_episode_in  => i_episode,
                                     id_prev_episode_nin => FALSE,
                                     where_in            => 'id_prev_episode = ' || i_episode_temp,
                                     rows_out            => l_rows_out);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_REQ_DET (id_episode_origin)';
            ts_analysis_req_det.upd(id_episode_origin_in  => i_episode,
                                    id_episode_origin_nin => FALSE,
                                    where_in              => 'id_episode_origin = ' || i_episode_temp,
                                    rows_out              => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ_DET (id_episode_destination)';
            ts_analysis_req_det.upd(id_episode_destination_in  => i_episode,
                                    id_episode_destination_nin => FALSE,
                                    where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                    rows_out                   => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_REQ_DET';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_REQ_DET',
                                          i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_DESTINATION'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE ANALYSIS_REQ_DET_HIST';
            ts_analysis_req_det_hist.upd(id_episode_origin_in  => i_episode,
                                         id_episode_origin_nin => FALSE,
                                         where_in              => 'id_episode_origin = ' || i_episode_temp,
                                         rows_out              => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ_DET_HIST (id_episode_destination)';
            ts_analysis_req_det_hist.upd(id_episode_destination_in  => i_episode,
                                         id_episode_destination_nin => FALSE,
                                         where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                         rows_out                   => l_rows_out);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE HARVEST';
            ts_harvest.upd(id_episode_in  => i_episode,
                           id_episode_nin => FALSE,
                           id_visit_in    => l_visit,
                           id_visit_nin   => FALSE,
                           where_in       => 'id_episode = ' || i_episode_temp,
                           rows_out       => l_rows_out);
        
            g_error := 'UPDATE HARVEST (id_episode_write)';
            ts_harvest.upd(id_episode_write_in => i_episode,
                           id_episode_nin      => FALSE,
                           where_in            => 'id_episode_write = ' || i_episode_temp,
                           rows_out            => l_rows_out);
        
            g_error := 'PROCESS UPDATE HARVEST';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'HARVEST',
                                          i_list_columns => table_varchar('ID_EPISODE', 'ID_VISIT', 'ID_EPISODE_WRITE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE HARVEST_HIST';
            UPDATE harvest_hist
               SET id_episode = i_episode, id_visit = l_visit
             WHERE id_episode = i_episode_temp;
        
            g_error := 'UPDATE HARVEST_HIST (id_episode_write)';
            UPDATE harvest_hist
               SET id_episode_write = i_episode
             WHERE id_episode_write = i_episode_temp;
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_RESULT';
            ts_analysis_result.upd(id_episode_in  => i_episode,
                                   id_episode_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_episode_temp,
                                   rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_RESULT (id_episode_orig)';
            ts_analysis_result.upd(id_episode_orig_in  => i_episode,
                                   id_episode_orig_nin => FALSE,
                                   id_visit_in         => l_visit,
                                   id_visit_nin        => FALSE,
                                   where_in            => 'id_episode_orig = ' || i_episode_temp,
                                   rows_out            => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_RESULT';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_RESULT',
                                          i_list_columns => table_varchar('ID_EPISODE', 'ID_VISIT', 'ID_EPISODE_ORIG'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_RESULT_HIST';
            ts_analysis_result_hist.upd(id_episode_in  => i_episode,
                                        id_episode_nin => FALSE,
                                        where_in       => 'id_episode = ' || i_episode_temp,
                                        rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_RESULT_HIST (id_episode_orig)';
            ts_analysis_result_hist.upd(id_episode_orig_in  => i_episode,
                                        id_episode_orig_nin => FALSE,
                                        id_visit_in         => l_visit,
                                        id_visit_nin        => FALSE,
                                        where_in            => 'id_episode_orig = ' || i_episode_temp,
                                        rows_out            => l_rows_out);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_RESULT_PAR';
            ts_analysis_result_par.upd(id_episode_in => i_episode,
                                       where_in      => 'id_episode = ' || i_episode_temp,
                                       rows_out      => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_RESULT_PAR';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_RESULT_PAR',
                                          i_list_columns => table_varchar('ID_EPISODE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_RESULT_PAR_HIST';
            ts_analysis_result_par_hist.upd(id_episode_in => i_episode,
                                            where_in      => 'id_episode = ' || i_episode_temp,
                                            rows_out      => l_rows_out);
        
            g_error := 'UPDATE GRID_TASK_LAB';
            UPDATE grid_task_lab
               SET id_episode = i_episode
             WHERE id_episode = i_episode_temp;
        
            DELETE FROM lab_tests_ea lte
             WHERE lte.id_visit IN (SELECT e.id_visit
                                      FROM episode e
                                     WHERE e.id_episode = i_episode_temp);
        ELSE
            g_error := 'OPEN C_EPISODE - i_episode_temp: ' || i_episode_temp;
            OPEN c_episode(i_episode_temp);
            FETCH c_episode
                INTO l_patient, l_visit;
            CLOSE c_episode;
        
            l_episode := i_episode_temp;
        
            IF l_patient IS NULL
               OR l_visit IS NULL
               OR l_episode IS NULL
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode = ' || i_episode_temp,
                                rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_prev_episode = ' || i_episode_temp,
                                rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode_origin = ' || i_episode_temp,
                                rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode_destination = ' || i_episode_temp,
                                rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_patient_in => i_patient,
                                where_in      => 'id_visit = ' || l_visit,
                                rows_out      => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_REQ',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE HARVEST';
            ts_harvest.upd(id_patient_in  => i_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_episode = ' || i_episode_temp,
                           rows_out       => l_rows_out);
        
            g_error := 'UPDATE HARVEST';
            ts_harvest.upd(id_patient_in  => i_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_episode_write = ' || i_episode_temp,
                           rows_out       => l_rows_out);
        
            g_error := 'UPDATE HARVEST';
            ts_harvest.upd(id_patient_in  => i_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_visit = ' || l_visit,
                           rows_out       => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'HARVEST',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE ANALYSIS_RESULT';
            ts_analysis_result.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_episode_temp,
                                   rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_RESULT';
            ts_analysis_result.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode_orig = ' || i_episode_temp,
                                   rows_out       => l_rows_out);
        
            g_error := 'UPDATE ANALYSIS_RESULT';
            ts_analysis_result.upd(id_patient_in => i_patient,
                                   where_in      => 'id_visit = ' || l_visit,
                                   rows_out      => l_rows_out);
        
            g_error := 'PROCESS UPDATE ANALYSIS_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_RESULT',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE GRID_TASK_LAB';
            IF l_patient IS NOT NULL
            THEN
                UPDATE grid_task_lab gtl
                   SET gtl.id_patient = i_patient
                 WHERE gtl.id_episode = i_episode_temp;
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
                                              'SET_LAB_TEST_MATCH',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_match;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req_det      table_number;
        l_episode               table_number;
        l_patient_id            table_number;
        l_analysis_harvest      table_number;
        l_analysis_result       table_number;
        l_analysis_req          table_number;
        l_schedule_analysis     table_number;
        l_tab_sch_not_cancelled table_number;
        l_movement_results      table_table_varchar;
        l_sys_alert_event       sys_alert_event%ROWTYPE;
        l_sys_alert_event_row   sys_alert_event%ROWTYPE;
    
        l_error t_error_out;
    
        l_patient_count NUMBER;
        l_episode_count NUMBER;
        l_results       NUMBER;
        l_log_data      VARCHAR2(32767);
    
        l_rows table_varchar;
    BEGIN
    
        l_patient_count := i_patient.count;
        l_episode_count := i_episode.count;
    
        -- checks if the delete process can be executed
        IF l_patient_count = 0
           AND l_episode_count = 0
        THEN
            g_error := 'EMPTY ARRAYS FOR I_PATIENT AND I_EPISODE';
            RETURN FALSE;
        END IF;
    
        -- selects the lists of all analysis_req_det ids to be removed
        g_error := 'ANALYSIS_REQ_DET BULK COLLECT ERROR';
        SELECT DISTINCT ar.id_episode, ard.id_analysis_req_det, ar.id_patient
          BULK COLLECT
          INTO l_episode, l_analysis_req_det, l_patient_id
          FROM analysis_req_det ard
          JOIN analysis_req ar
            ON ar.id_analysis_req = ard.id_analysis_req
         WHERE ((ar.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                     FROM TABLE(i_episode) t)) OR
               (ar.id_episode_origin IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(i_episode) t)))
            OR ((ar.id_episode IS NULL OR ar.id_episode_origin IS NULL) AND
               ar.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_patient) t));
    
        -- check if there were movements associated with the analysis request
        g_error := 'MOVEMENT BULK COLLECT ERROR';
        SELECT table_varchar(ard.id_movement, nvl(ar.id_episode, ar.id_episode_origin), mov.flg_status)
          BULK COLLECT
          INTO l_movement_results
          FROM analysis_req_det ard, analysis_req ar, movement mov, analysis_harvest ah
         WHERE ard.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t)
           AND ar.id_analysis_req = ard.id_analysis_req
           AND ah.id_analysis_req_det(+) = ard.id_analysis_req_det
           AND mov.id_movement(+) = ard.id_movement;
    
        g_error := 'ERROR SELECTING ID_ANALYSIS_RESULT';
        SELECT DISTINCT ar.id_analysis_result
          BULK COLLECT
          INTO l_analysis_result
          FROM analysis_result ar
         WHERE (ar.id_episode_orig IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(i_episode) t))
            OR (ar.id_episode IS NULL AND
               ar.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_patient) t))
            OR ar.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_analysis_req_det) t);
    
        g_error := 'ID_HARVEST BULK COLLECT ERROR';
        SELECT DISTINCT ah.id_harvest
          BULK COLLECT
          INTO l_analysis_harvest
          FROM analysis_harvest ah
         WHERE ah.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_analysis_req_det) t)
           AND NOT EXISTS
         (SELECT 1
                  FROM analysis_harvest ah1
                 WHERE ah1.id_harvest = ah.id_harvest
                   AND ah.id_analysis_req_det NOT IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                                        FROM TABLE(l_analysis_req_det) t));
    
        -- ## deletes the requisition process
    
        -- remove data from lab_tests_ea
        g_error := 'LAB_TESTS_EA DELETE ERROR';
        DELETE FROM lab_tests_ea lte
         WHERE lte.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t)
            OR lte.id_analysis_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_analysis_result) t);
    
        g_error := 'ANALYSIS_MEDIA_ARCHIVE DELETE ERROR';
        DELETE FROM analysis_media_archive ama
         WHERE ama.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t)
            OR ama.id_analysis_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_analysis_result) t);
    
        --removal of analysis from the grid task
        g_error := 'GRID_TASK_LAB DELETE ERROR';
        DELETE FROM grid_task_lab gtl
         WHERE gtl.id_analysis_req_det IN (SELECT *
                                             FROM TABLE(l_analysis_req_det) t);
    
        -- deletes print related data
        g_error := 'ANALYSIS_ABN_PRINT DELETE ERROR';
        DELETE FROM analysis_abn_print aap
         WHERE aap.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        -- ## deletes from the result process
    
        g_error := 'ANALYSIS_RESULT_PAR_HIST DELETE ERROR';
        DELETE FROM analysis_result_par_hist arph
         WHERE arph.id_analysis_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_result) t);
    
        l_rows := NULL;
    
        g_error := 'ANALYSIS_RESUT_PAR DELETE ERROR';
        DELETE FROM analysis_result_par arp
         WHERE arp.id_analysis_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_analysis_result) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_RESULT_PAR',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'ANALYSIS_RESULT_SEND DELETE ERROR';
        DELETE FROM analysis_result_send ars
         WHERE ars.id_analysis_req_det IN (SELECT *
                                             FROM TABLE(l_analysis_req_det) t);
    
        g_error := 'ANALYSIS_RESULT_HIST DELETE ERROR';
        DELETE FROM analysis_result_hist arh
         WHERE arh.id_analysis_result IN (SELECT *
                                            FROM TABLE(l_analysis_result) t);
    
        l_rows := NULL;
    
        g_error := 'ANALYSIS_RESULT DELETE ERROR';
        DELETE FROM analysis_result ar
         WHERE ar.id_analysis_result IN (SELECT *
                                           FROM TABLE(l_analysis_result) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_RESULT',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'ANALYSIS_REQ_PAR DELETE ERROR';
        DELETE FROM analysis_req_par arp
         WHERE arp.id_analysis_req_det IN (SELECT *
                                             FROM TABLE(l_analysis_req_det) t);
    
        -- removal of the associated diagnosis
        g_error := 'ANALYSIS_QUESTION_RESP_HIST DELETE ERROR';
        DELETE FROM analysis_question_resp_hist aqrh
         WHERE aqrh.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                              FROM TABLE(l_analysis_req_det) t);
    
        -- removal of the associated diagnosis
        g_error := 'ANALYSIS_QUESTION_RESPONSE DELETE ERROR';
        DELETE FROM analysis_question_response aqr
         WHERE aqr.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        -- ## deletes from analysis_harvest_comb_div
        g_error := 'ANALYSIS_HARVEST_COMB_DIV';
        DELETE FROM analysis_harv_comb_div ahcb
         WHERE ahcb.id_analysis_harv_orig IN
               (SELECT ah.id_analysis_harvest
                  FROM analysis_harvest ah
                 WHERE ah.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                                    FROM TABLE(l_analysis_req_det) t));
    
        -- ## deletes from the harvest process
        g_error := 'ANALYSIS_HARVEST_HIST DELETE ERROR';
        DELETE FROM analysis_harvest_hist ahh
         WHERE ahh.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        l_rows := NULL;
    
        g_error := 'ANALYSIS_HARVEST DELETE ERROR';
        DELETE FROM analysis_harvest ah
         WHERE ah.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_analysis_req_det) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
        -- ## end        
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_HARVEST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'HARVEST_HIST DELETE ERROR';
        DELETE FROM harvest_hist hh
         WHERE hh.id_harvest IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                   FROM TABLE(l_analysis_harvest) t);
    
        l_rows := NULL;
    
        g_error := 'HARVEST DELETE ERROR';
        DELETE FROM harvest h
         WHERE h.id_harvest IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                  FROM TABLE(l_analysis_harvest) t)
           AND NOT EXISTS (SELECT 1
                  FROM analysis_harvest ah
                 WHERE ah.id_harvest = h.id_harvest)
        RETURNING ROWID BULK COLLECT INTO l_rows;
        -- ## end        
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'HARVEST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        g_error := 'P1_EXR_ANALYSIS UPDATE ERROR';
        UPDATE p1_exr_analysis pet
           SET pet.id_analysis_req_det = NULL
         WHERE pet.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        g_error := 'P1_EXR_TEMP UPDATE ERROR';
        UPDATE p1_exr_temp pet
           SET pet.id_analysis_req_det = NULL
         WHERE pet.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        --removal of suspended lab tasks
        g_error := 'SUSP_TASK_LAB DELETE ERROR';
        DELETE FROM susp_task_lab stl
         WHERE stl.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t);
    
        -- removal of analysis request detail history
        g_error := 'ANALYSIS_REQ_DET_HIST DELETE ERROR';
        DELETE FROM analysis_req_det_hist ardh
         WHERE ardh.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                              FROM TABLE(l_analysis_req_det) t);
    
        l_rows := NULL;
    
        -- removal of analysis request details
        g_error := 'ANALYSIS_REQ_DET DELETE ERROR';
        DELETE FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                             FROM TABLE(l_analysis_req_det) t)
        RETURNING to_number(ard.id_analysis_req), ROWID BULK COLLECT INTO l_analysis_req, l_rows;
    
        -- ## end        
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_REQ_DET',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- removal of patient periodical observations history                                    
        g_error := 'PAT_PERIODIC_OBS_HIST DELETE ERROR';
        DELETE FROM pat_periodic_obs_hist ppoh
         WHERE (ppoh.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                      FROM TABLE(i_episode) t))
            OR (ppoh.id_episode IS NULL AND
               ppoh.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                      FROM TABLE(i_patient) t));
    
        g_error := 'SCHEDULE_ANALYSIS_HIST UPDATE ERROR';
        DELETE schedule_analysis_hist sah
         WHERE sah.id_analysis_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_analysis_req) t);
    
        g_error := 'SCHEDULE_ANALYSIS UPDATE ERROR';
        DELETE schedule_analysis sa
         WHERE sa.id_analysis_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_analysis_req) t)
        RETURNING to_number(sa.id_schedule) BULK COLLECT INTO l_schedule_analysis;
    
        IF l_schedule_analysis.count > 0
        THEN
            SELECT s.id_schedule
              BULK COLLECT
              INTO l_tab_sch_not_cancelled
              FROM schedule s
              JOIN TABLE(l_schedule_analysis) t
                ON t.column_value = s.id_schedule
             WHERE s.flg_status NOT IN (pk_alert_constant.g_cancelled);
        
            IF l_tab_sch_not_cancelled.count > 0
            THEN
                io_transaction := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id => io_transaction,
                                                                                 i_prof           => i_prof);
            
                -- fazer chamada à função de cancelamento;
                g_error := 'CALL pk_schedule_api_upstream.cancel_schedules';
                IF NOT pk_schedule_api_upstream.cancel_schedules(i_lang                 => i_lang,
                                                                 i_prof                 => i_prof,
                                                                 i_transaction_id       => io_transaction,
                                                                 i_ids_schedule         => l_tab_sch_not_cancelled,
                                                                 i_id_sch_cancel_reason => 9,
                                                                 o_error                => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        -- last delete from analysis request table
        g_error := 'ANALYSIS_REQ_HIST DELETE ERROR';
        DELETE FROM analysis_req_hist arh
         WHERE arh.id_analysis_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_analysis_req) t);
    
        l_rows := NULL;
    
        -- last delete from analysis request table
        g_error := 'ANALYSIS_REQ DELETE ERROR';
        DELETE FROM analysis_req ar
         WHERE ar.id_analysis_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_analysis_req) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
        -- ## end        
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        --removes periodic_observation if it is an analysis
        DELETE FROM periodic_observation_reg por
         WHERE por.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(l_episode) t)
           AND por.flg_group = 'A';
    
        -- removal of movement alerts
        FOR i IN 1 .. l_movement_results.count
        LOOP
        
            IF l_movement_results(i) (3) IN (pk_alert_constant.g_mov_status_pend, pk_alert_constant.g_mov_status_req)
            THEN
                -- Mov está só requisitado ou pendente
                l_sys_alert_event_row.id_sys_alert := 9;
                l_sys_alert_event_row.id_record    := l_movement_results(i) (1); --id_movement
                l_sys_alert_event_row.id_episode   := l_movement_results(i) (2); --id_episode
            
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        o_error           => l_error)
                THEN
                
                    o_error := l_error;
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
        FOR counter IN 1 .. l_episode.count
        LOOP
        
            IF l_episode(counter) IS NOT NULL
            THEN
                -- update of lab test request date   
                g_error := 'UPDATE EPIS_INFO LAB TEST REQUEST DATES';
                ts_epis_info.upd(id_episode_in                  => l_episode(counter),
                                 dt_first_analysis_req_tstz_in  => NULL,
                                 dt_first_analysis_req_tstz_nin => NULL);
            
                -- removes analysis from the grid task lab
                g_error := 'UPDATE GRID_TASK';
                UPDATE grid_task gt
                   SET gt.analysis_d = NULL, gt.analysis_n = NULL
                 WHERE gt.id_episode = l_episode(counter);
            
                l_sys_alert_event.id_sys_alert := 4;
                l_sys_alert_event.id_episode   := l_episode(counter);
                l_sys_alert_event.id_record    := l_analysis_req_det(counter);
            
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_sys_alert_event.id_sys_alert := 5;
                l_sys_alert_event.id_episode   := l_episode(counter);
                l_sys_alert_event.id_record    := l_analysis_req_det(counter);
            
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_sys_alert_event.id_sys_alert := 15;
                l_sys_alert_event.id_episode   := l_episode(counter);
                l_sys_alert_event.id_record    := l_analysis_req_det(counter);
            
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_sys_alert_event.id_sys_alert := 40;
                l_sys_alert_event.id_episode   := l_episode(counter);
                l_sys_alert_event.id_record    := l_analysis_req_det(counter);
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESET_LAB_TESTS',
                                              o_error);
            --pk_schedule_api_upstream.do_rollback(l_transaction_id);
            RETURN FALSE;
    END reset_lab_tests;

    PROCEDURE system___________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE process_lab_test_pending IS
    
        CURSOR c_analysis_req_det IS
            SELECT ard.id_analysis_req_det, ar.id_institution, ei.id_software
              FROM analysis_req ar, analysis_req_det ard, epis_info ei
             WHERE ard.dt_target_tstz < current_timestamp
               AND ard.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e
               AND ard.flg_status = pk_lab_tests_constant.g_analysis_pending
               AND ard.id_analysis_req = ar.id_analysis_req
               AND ar.id_episode_origin IS NULL
               AND ar.id_episode = ei.id_episode
               AND pk_sysconfig.get_config('LABTEST_PROCESS_PEND_JOB',
                                           profissional(0, ar.id_institution, ei.id_software)) =
                   pk_alert_constant.g_yes;
    
        CURSOR c_lang
        (
            l_prof        NUMBER,
            l_institution NUMBER
        ) IS
            SELECT p.id_language
              FROM prof_preferences p
             WHERE p.id_professional = l_prof
               AND p.id_institution = l_institution;
    
        l_id_prof NUMBER;
        l_lang    NUMBER;
    
        l_count     NUMBER := 0;
        l_count_err NUMBER := 0;
    
        l_error_out t_error_out;
    
    BEGIN
    
        FOR rec IN c_analysis_req_det
        LOOP
            l_id_prof := pk_sysconfig.get_config('ID_PROF_ALERT', profissional(0, rec.id_institution, rec.id_software));
        
            OPEN c_lang(l_id_prof, rec.id_institution);
            FETCH c_lang
                INTO l_lang;
            CLOSE c_lang;
        
            IF NOT pk_lab_tests_core.set_lab_test_status(i_lang             => l_lang,
                                                         i_prof             => profissional(l_id_prof,
                                                                                            rec.id_institution,
                                                                                            rec.id_software),
                                                         i_analysis_req_det => table_number(rec.id_analysis_req_det),
                                                         i_status           => pk_lab_tests_constant.g_analysis_pending,
                                                         o_error            => l_error_out)
            THEN
                l_count_err := l_count_err + 1;
            ELSE
                l_count := l_count + 1;
            END IF;
        END LOOP;
    
        pk_alertlog.log_info(text            => 'Processed ' || l_count || ' requests. Number of requests in error : ' ||
                                                l_count_err,
                             object_name     => g_package_name,
                             sub_object_name => 'PROCESS_LAB_TEST_PENDING');
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PROCESS_LAB_TEST_PENDING',
                                              l_error_out);
    END process_lab_test_pending;

    FUNCTION inactivate_lab_tests_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config('INACTIVATE_CANCEL_REASON', i_prof);
        l_read_cfg   sys_config.value%TYPE := pk_sysconfig.get_config('READ_CANCEL_REASON', i_prof);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config('INACTIVATE_TASKS_MAX_NUMBER_ROWS', i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(NULL,
                                                                                    profissional(0, i_inst, 0),
                                                                                    'LABS_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
        l_read_id   cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_read_cfg);
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_analysis_req_det    table_number;
        l_final_status        table_varchar;
        l_analysis_result_par table_number;
    
        l_error t_error_out;
    
        l_tbl_error_ids table_number := table_number();
    
        CURSOR c_analysis_req_det(ids_exclude IN table_number) IS
            SELECT /*+opt_estimate(table cfg rows=1)*/
             ard.id_analysis_req_det, cfg.field_04 final_status, arp.id_analysis_result_par
              FROM analysis_req ar
             INNER JOIN analysis_req_det ard
                ON ar.id_analysis_req = ard.id_analysis_req
              LEFT JOIN analysis_result ares
                ON ares.id_analysis_req_det = ard.id_analysis_req_det
              LEFT JOIN analysis_result_par arp
                ON arp.id_analysis_result = ares.id_analysis_result
              LEFT JOIN episode e
                ON e.id_episode = ar.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = ard.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = ard.id_analysis_req_det
             WHERE ar.id_institution = i_inst
               AND ((e.dt_end_tstz IS NOT NULL AND
                   (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                      pk_date_utils.add_to_ltstz(e.dt_end_tstz,
                                                                                 cfg.field_02,
                                                                                 cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                   (e.id_episode IS NULL AND ard.flg_status = pk_lab_tests_constant.g_analysis_sched AND
                   ar.dt_begin_tstz IS NOT NULL AND pk_date_utils.trunc_insttimezone(i_prof,
                                                                                       pk_date_utils.add_to_ltstz(ar.dt_begin_tstz,
                                                                                                                  cfg.field_02,
                                                                                                                  cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                   (e.id_episode IS NULL AND ard.flg_status = pk_lab_tests_constant.g_analysis_tosched AND
                   ar.dt_req_tstz IS NOT NULL AND pk_date_utils.trunc_insttimezone(i_prof,
                                                                                     pk_date_utils.add_to_ltstz(ar.dt_req_tstz,
                                                                                                                cfg.field_02,
                                                                                                                cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                   (e.dt_end_tstz IS NULL AND e.id_episode IS NOT NULL AND
                   e.id_epis_type = pk_alert_constant.g_epis_type_lab AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                      pk_date_utils.add_to_ltstz(ar.dt_begin_tstz,
                                                                                 cfg.field_02,
                                                                                 cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)))
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
    BEGIN
    
        OPEN c_analysis_req_det(i_ids_exclude);
        FETCH c_analysis_req_det BULK COLLECT
            INTO l_analysis_req_det, l_final_status, l_analysis_result_par;
        CLOSE c_analysis_req_det;
    
        o_has_error := FALSE;
    
        IF l_analysis_req_det.count > 0
        THEN
            FOR i IN 1 .. l_analysis_req_det.count
            LOOP
                CASE l_final_status(i)
                    WHEN pk_lab_tests_constant.g_analysis_cancel THEN
                        SAVEPOINT init_cancel;
                        IF NOT pk_lab_tests_external.cancel_lab_test_task(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_task_request     => l_analysis_req_det(i),
                                                                          i_reason           => l_cancel_id,
                                                                          i_reason_notes     => NULL,
                                                                          i_prof_order       => NULL,
                                                                          i_dt_order         => NULL,
                                                                          i_order_type       => NULL,
                                                                          i_flg_cancel_event => l_send_cancel_event,
                                                                          o_error            => l_error)
                        THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_analysis_req_det, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_analysis_req_det that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_LAB_TESTS_EXTERNAL.CANCEL_LAB_TEST_TASK FOR RECORD ' ||
                                       l_analysis_req_det(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_EXAMS_TASKS',
                                                              o_error);
                        
                            --The array for the ids (id_exam_req_det) that raised the error is incremented
                            l_tbl_error_ids.extend();
                            l_tbl_error_ids(l_tbl_error_ids.count) := l_analysis_req_det(i);
                        
                            CONTINUE;
                        END IF;
                    ELSE
                        SAVEPOINT init_cancel;
                        IF NOT pk_lab_tests_api_db.set_lab_test_status_read(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_analysis_result_par => table_number(l_analysis_result_par(i)),
                                                                            i_flg_relevant        => NULL,
                                                                            i_notes               => NULL,
                                                                            i_cancel_reason       => l_read_id,
                                                                            o_error               => l_error)
                        THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_analysis_req_det, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_analysis_req_det that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_LAB_TESTS_API_DB.SET_LAB_TEST_STATUS_READ FOR RECORD ' ||
                                       l_analysis_req_det(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_LAB_TESTS_TASKS',
                                                              o_error);
                        
                            --The array for the ids (id_exam_req_det) that raised the error is incremented
                            l_tbl_error_ids.extend();
                            l_tbl_error_ids(l_tbl_error_ids.count) := l_analysis_req_det(i);
                        
                            CONTINUE;
                        END IF;
                END CASE;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_analysis_req_det has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_exam_req_det) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_lab_tests_external.inactivate_lab_tests_tasks(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_inst        => i_inst,
                                                                        i_ids_exclude => i_ids_exclude,
                                                                        o_has_error   => o_has_error,
                                                                        o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
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
                                              'INACTIVATE_LAB_TESTS_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_lab_tests_tasks;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_external;
/
