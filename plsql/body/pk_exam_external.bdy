/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exam_external IS

    FUNCTION tf_exams_ea
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_cancelled  IN VARCHAR2,
        i_exam_type  IN exam.flg_type%TYPE,
        i_crit_type  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_status IN table_varchar DEFAULT NULL
    ) RETURN t_tbl_exams_ea IS
    
        l_out_rec t_tbl_exams_ea := t_tbl_exams_ea(NULL);
    
        l_type_header   VARCHAR2(4000 CHAR);
        l_inner_header  VARCHAR2(2000 CHAR);
        l_inner_header1 VARCHAR2(2000 CHAR);
        l_inner_header2 VARCHAR2(2000 CHAR);
        l_sql_inner1    VARCHAR2(4000 CHAR);
        l_sql_inner2    VARCHAR2(4000 CHAR);
        l_sql_footer1   VARCHAR2(1000 CHAR);
        l_sql_footer2   VARCHAR2(1000 CHAR);
        l_sql_stmt      CLOB;
        l_curid         INTEGER;
        l_ret           INTEGER;
    
        l_cursor pk_types.cursor_type;
    
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_EXAMS_EA';
        l_flg_status     VARCHAR2(300 CHAR);
    
    BEGIN
    
        l_curid := dbms_sql.open_cursor;
    
        l_type_header := 'SELECT t_exams_ea(id_exam_req, ' || --
                         '                  id_exam_req_det, ' || --
                         '                  id_exam_result, ' || --
                         '                  id_exam, ' || --
                         '                  id_exam_group, ' || --
                         '                  id_exam_cat, ' || --
                         '                  dt_req, ' || --
                         '                  dt_begin, ' || --
                         '                  dt_pend_req, ' || --
                         '                  dt_result, ' || --
                         '                  status_str_req, ' || --
                         '                  status_msg_req, ' || --
                         '                  status_icon_req, ' || --
                         '                  status_flg_req, ' || --
                         '                  status_str, ' || --
                         '                  status_msg, ' || --
                         '                  status_icon, ' || --
                         '                  status_flg, ' || --
                         '                  flg_type, ' || --
                         '                  flg_available, ' || --
                         '                  flg_notes, ' || --
                         '                  flg_doc, ' || --
                         '                  flg_time, ' || --
                         '                  flg_status_req, ' || --
                         '                  flg_status_det, ' || --
                         '                  flg_status_result, ' || --
                         '                  flg_referral, ' || --
                         '                  priority, ' || --
                         '                  id_prof_req, ' || --
                         '                  id_exam_codification, ' || --
                         '                  id_task_dependency, ' || --
                         '                  id_room, ' || --
                         '                  id_movement, ' || --
                         '                  notes, ' || --
                         '                  notes_technician, ' || --
                         '                  notes_patient, ' || --
                         '                  notes_cancel, ' || --
                         '                  id_prof_performed, ' || --
                         '                  start_time, ' || --
                         '                  end_time, ' || --
                         '                  id_epis_doc_perform, ' || --
                         '                  desc_perform_notes, ' || --
                         '                  id_epis_doc_result, ' || --
                         '                  desc_result, ' || --
                         '                  flg_req_origin_module, ' || --
                         '                  id_patient, ' || --
                         '                  id_visit, ' || --
                         '                  id_episode, ' || --
                         '                  id_episode_origin, ' || --
                         '                  id_prev_episode, ' || --
                         '                  dt_dg_last_update, ' || --
                         '                  notes_scheduler, ' || --
                         '                  id_epis_type, ' || --
                         '                  id_epis) ' || --
                         '  FROM ( ';
    
        l_inner_header := 'SELECT eea.id_exam_req, ' || --
                          '       eea.id_exam_req_det, ' || --
                          '       eea.id_exam_result, ' || --
                          '       eea.id_exam, ' || --
                          '       eea.id_exam_group, ' || --
                          '       eea.id_exam_cat, ' || --
                          '       eea.dt_req, ' || --
                          '       eea.dt_begin, ' || --
                          '       eea.dt_pend_req, ' || --
                          '       eea.dt_result, ' || --
                          '       eea.status_str_req, ' || --
                          '       eea.status_msg_req, ' || --
                          '       eea.status_icon_req, ' || --
                          '       eea.status_flg_req, ' || --
                          '       eea.status_str, ' || --
                          '       eea.status_msg, ' || --
                          '       eea.status_icon, ' || --
                          '       eea.status_flg, ' || --
                          '       eea.flg_type, ' || --
                          '       eea.flg_available, ' || --
                          '       eea.flg_notes, ' || --
                          '       eea.flg_doc, ' || --
                          '       eea.flg_time, ' || --
                          '       eea.flg_status_req, ' || --
                          '       eea.flg_status_det, ' || --
                          '       eea.flg_status_result, ' || --
                          '       eea.flg_referral, ' || --
                          '       eea.priority, ' || --
                          '       eea.id_prof_req, ' || --
                          '       eea.id_exam_codification, ' || --
                          '       eea.id_task_dependency, ' || --
                          '       eea.id_room, ' || --
                          '       eea.id_movement, ' || --
                          '       eea.notes, ' || --
                          '       eea.notes_technician, ' || --
                          '       eea.notes_patient, ' || --
                          '       eea.notes_cancel, ' || --
                          '       eea.id_prof_performed, ' || --
                          '       eea.start_time, ' || --
                          '       eea.end_time, ' || --
                          '       eea.id_epis_doc_perform, ' || --
                          '       eea.desc_perform_notes, ' || --
                          '       eea.id_epis_doc_result, ' || --
                          '       eea.desc_result, ' || --
                          '       eea.flg_req_origin_module, ' || --
                          '       eea.id_patient, ' || --
                          '       eea.id_visit, ' || --
                          '       eea.id_episode, ' || --
                          '       eea.id_episode_origin, ' || --
                          '       eea.id_prev_episode, ' || --
                          '       eea.dt_dg_last_update, ' || --
                          '       eea.notes_scheduler, ' || --
                          '       e.id_epis_type, ' || --
                          '       e.id_episode id_epis ';
    
        l_inner_header1 := l_inner_header ||
                           ' FROM exams_ea eea JOIN episode e ON eea.id_episode = e.id_episode WHERE 1 = 1 ';
    
        --i_patient
        IF i_patient IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND eea.id_patient = :i_patient ';
        END IF;
    
        --i_visit
        IF i_visit IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND (eea.id_visit = :i_visit OR pk_episode.get_id_visit(eea.id_episode_origin) = :i_visit)';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND eea.id_episode = :i_episode';
        END IF;
    
        IF i_cancelled = pk_alert_constant.g_no
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND eea.flg_status_det != ''' || pk_exam_constant.g_exam_cancel || '''';
        END IF;
    
        IF i_flg_status IS NOT NULL
           AND i_flg_status.count > 0
        THEN
            FOR i IN 1 .. i_flg_status.count
            LOOP
                IF i = 1
                THEN
                    l_flg_status := '''' || i_flg_status(1) || '''';
                ELSE
                
                    l_flg_status := l_flg_status || ',''' || i_flg_status(i) || '''';
                END IF;
            END LOOP;
        
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND eea.flg_status_det in (SELECT t1.column_value FROM TABLE(table_varchar(' ||
                            l_flg_status || ')) t1)';
        END IF;
    
        IF i_crit_type IS NOT NULL
           AND i_crit_type = 'A'
        THEN
            l_sql_inner1 := l_sql_inner1 ||
                            ' AND coalesce(eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) >= ' || --
                            '     coalesce(:i_start_date, eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) ' || --
                            ' AND coalesce(eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) <= ' || --
                            '     coalesce(:i_end_date, eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) ';
        ELSIF i_crit_type IS NOT NULL
              AND i_crit_type = 'E'
        THEN
            l_sql_inner1 := l_sql_inner1 || ' AND eea.start_time >= nvl(:i_start_date, eea.start_time) ' || --
                            ' AND eea.end_time <= nvl(:i_end_date, eea.end_time)';
        END IF;
    
        l_sql_footer1 := ' AND eea.flg_type = :i_exam_type UNION ALL ';
    
        l_inner_header2 := l_inner_header ||
                           ' FROM exams_ea eea JOIN episode e ON eea.id_episode_origin = e.id_episode WHERE 1 = 1 ';
    
        --i_patient
        IF i_patient IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND eea.id_patient = :i_patient ';
        END IF;
    
        --i_visit
        IF i_visit IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            ' AND (eea.id_visit = :i_visit OR pk_episode.get_id_visit(eea.id_episode_origin) = :i_visit)';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND eea.id_episode_origin = :i_episode';
        END IF;
    
        IF i_cancelled = pk_alert_constant.g_no
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND eea.flg_status_det != ''' || pk_exam_constant.g_exam_cancel || '''';
        END IF;
    
        IF i_flg_status IS NOT NULL
           AND i_flg_status.count > 0
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            ' AND eea.flg_status_det in (SELECT t1.column_value FROM TABLE(table_varchar(' ||
                            l_flg_status || ')) t1)';
        END IF;
    
        IF i_crit_type IS NOT NULL
           AND i_crit_type = 'A'
        THEN
            l_sql_inner2 := l_sql_inner2 ||
                            ' AND coalesce(eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) >= ' || --
                            '     coalesce(:i_start_date, eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) ' || --
                            ' AND coalesce(eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) <= ' || --
                            '     coalesce(:i_end_date, eea.dt_result, eea.dt_pend_req, eea.dt_begin, eea.dt_req) ';
        ELSIF i_crit_type IS NOT NULL
              AND i_crit_type = 'E'
        THEN
            l_sql_inner2 := l_sql_inner2 || ' AND eea.start_time >= nvl(:i_start_date, eea.start_time) ' || --
                            ' AND eea.end_time <= nvl(:i_end_date, eea.end_time)';
        END IF;
    
        l_sql_footer2 := ' AND eea.flg_type = :i_exam_type )';
    
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
    
        dbms_sql.bind_variable(l_curid, 'i_exam_type', i_exam_type);
    
        IF i_crit_type IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_start_date', i_start_date);
            dbms_sql.bind_variable(l_curid, 'i_end_date', i_end_date);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    
    END tf_exams_ea;

    PROCEDURE episode___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_for_episode_timeline
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
                      substr(concatenate(pk_exams_api_db.get_alias_translation(i_lang,
                                                                               i_prof,
                                                                               'EXAM.CODE_EXAM.' || t.id_exam,
                                                                               NULL) || ' / '),
                             1,
                             length(concatenate(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      'EXAM.CODE_EXAM.' || t.id_exam,
                                                                                      NULL) || ' / ')) - 3),
                      substr(concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_req) || '; '),
                             1,
                             length(concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_req) || '; ')) - 2) ||
                      chr(10) ||
                      substr(concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) || '; '),
                             1,
                             length(concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) || '; ')) - 2))
          INTO l_desc
          FROM (SELECT eea.id_exam, eea.id_prof_req, eres.id_professional
                  FROM exams_ea eea, exam_result eres
                 WHERE eea.id_episode = i_episode
                   AND eea.id_exam_result = eres.id_exam_result(+)) t;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_for_episode_timeline;

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_listview
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_flg_all_exam IN VARCHAR2 DEFAULT 'N',
        i_scope        IN NUMBER DEFAULT NULL,
        i_flg_scope    IN VARCHAR2 DEFAULT '',
        i_start_date   IN VARCHAR2 DEFAULT NULL,
        i_end_date     IN VARCHAR2 DEFAULT NULL,
        i_cancelled    IN VARCHAR2 DEFAULT NULL,
        i_crit_type    IN VARCHAR2 DEFAULT 'A',
        i_flg_status   IN table_varchar DEFAULT NULL,
        i_flg_rep      IN VARCHAR2 DEFAULT 'N',
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient   patient.id_patient%TYPE;
        l_cancelled VARCHAR2(1);
        l_visit     visit.id_visit%TYPE;
        l_episode   episode.id_episode%TYPE;
        l_epis_type episode.id_epis_type%TYPE;
    
        l_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_top_result sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_RESULTS_ON_TOP', i_prof);
    
        l_msg_notes         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M097');
        l_msg_not_aplicable sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M036');
    
    BEGIN
    
        IF i_cancelled IS NULL
        THEN
            l_cancelled := pk_alert_constant.g_yes;
        ELSE
            l_cancelled := i_cancelled;
        
        END IF;
    
        g_error      := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_start_date';
        l_start_date := CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL)
                            ELSE
                             NULL
                        END;
    
        g_error    := 'CALL PK_DATE_UTILS.GET_TIMESTAMP_INSTTIMEZONE - l_end_date';
        l_end_date := CASE
                          WHEN i_end_date IS NOT NULL THEN
                           pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL)
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
        OPEN o_list FOR
            WITH cso_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    decode(i_exam_type,
                                                                           pk_exam_constant.g_type_img,
                                                                           pk_alert_constant.g_task_imaging_exams,
                                                                           pk_alert_constant.g_task_other_exams)))
               WHERE i_flg_rep = pk_alert_constant.g_yes),
            cso_table_cs AS
             (SELECT *
                FROM cso_table
               WHERE i_flg_rep = pk_alert_constant.g_yes)
            SELECT /*+ opt_estimate(table eea rows=1)*/
            DISTINCT eea.id_exam_req,
                     eea.id_exam_req_det,
                     eea.id_exam,
                     eea.flg_status_det flg_status,
                     eea.flg_time,
                     pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) ||
                     decode(l_epis_type,
                            nvl(t_ti_log.get_epis_type(i_lang,
                                                       i_prof,
                                                       eea.id_epis_type,
                                                       eea.flg_status_req,
                                                       eea.id_exam_req,
                                                       pk_exam_constant.g_exam_type_req),
                                eea.id_epis_type),
                            '',
                            ' - (' || pk_message.get_message(i_lang,
                                                             profissional(i_prof.id,
                                                                          i_prof.institution,
                                                                          t_ti_log.get_epis_type_soft(i_lang,
                                                                                                      i_prof,
                                                                                                      eea.id_epis_type,
                                                                                                      eea.flg_status_req,
                                                                                                      eea.id_exam_req,
                                                                                                      pk_exam_constant.g_exam_type_req)),
                                                             'IMAGE_T009') || ')') desc_exam,
                     pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || eea.id_exam_cat) exam_cat,
                     decode(eea.flg_notes, pk_exam_constant.g_no, '', l_msg_notes) msg_notes,
                     eea.notes notes,
                     eea.notes_patient notes_patient,
                     eea.notes_technician notes_technician,
                     pk_exam_utils.get_exam_icon(i_lang, i_prof, eea.id_exam_req_det) icon_name,
                     decode(eea.flg_time,
                            pk_exam_constant.g_flg_time_r,
                            l_msg_not_aplicable,
                            pk_diagnosis.concat_diag(i_lang, eea.id_exam_req_det, NULL, NULL, i_prof)) desc_diagnosis,
                     pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.PRIORITY', eea.priority, NULL) priority,
                     decode(eea.flg_time,
                            pk_exam_constant.g_flg_time_r,
                            (SELECT pk_date_utils.dt_chr_hour(i_lang, de.dt_emited, i_prof)
                               FROM doc_external de, exam_media_archive ema
                              WHERE de.id_doc_external = ema.id_doc_external
                                AND ema.id_exam_result = eea.id_exam_result
                                AND rownum = 1),
                            pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_begin, i_prof.institution, i_prof.software)) hr_begin,
                     decode(eea.flg_time,
                            pk_exam_constant.g_flg_time_r,
                            (SELECT pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof)
                               FROM doc_external de, exam_media_archive ema
                              WHERE de.id_doc_external = ema.id_doc_external
                                AND ema.id_exam_result = eea.id_exam_result
                                AND rownum = 1),
                            pk_date_utils.dt_chr_tsz(i_lang, eea.dt_begin, i_prof.institution, i_prof.software)) dt_begin,
                     pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', eea.flg_time, NULL) to_be_perform,
                     pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det, NULL) desc_status,
                     pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                eea.status_str,
                                                eea.status_msg,
                                                eea.status_icon,
                                                eea.status_flg) status_string,
                     pk_exam_utils.get_exam_codification(i_lang, i_prof, eea.id_exam_codification) id_codification,
                     eea.id_task_dependency,
                     pk_exam_utils.get_exam_timeout(i_lang, i_prof, eea.id_exam) flg_timeout,
                     pk_exam_utils.get_exam_permission(i_lang,
                                                       i_prof,
                                                       pk_exam_constant.g_exam_area_exams,
                                                       pk_exam_constant.g_exam_button_ok,
                                                       eea.id_epis,
                                                       NULL,
                                                       eea.id_exam_req_det,
                                                       pk_exam_constant.g_yes) avail_button_ok,
                     pk_exam_utils.get_exam_permission(i_lang,
                                                       i_prof,
                                                       pk_exam_constant.g_exam_area_exams,
                                                       pk_exam_constant.g_exam_button_cancel,
                                                       eea.id_epis,
                                                       NULL,
                                                       eea.id_exam_req_det,
                                                       pk_exam_constant.g_yes) avail_button_cancel,
                     pk_exam_utils.get_exam_permission(i_lang,
                                                       i_prof,
                                                       pk_exam_constant.g_exam_area_exams,
                                                       pk_exam_constant.g_exam_button_action,
                                                       eea.id_epis,
                                                       NULL,
                                                       eea.id_exam_req_det,
                                                       pk_exam_constant.g_yes) avail_button_action,
                     pk_exam_utils.get_exam_permission(i_lang,
                                                       i_prof,
                                                       pk_exam_constant.g_exam_area_exams,
                                                       pk_exam_constant.g_exam_button_read,
                                                       eea.id_epis,
                                                       NULL,
                                                       eea.id_exam_req_det,
                                                       pk_exam_constant.g_yes) avail_button_read,
                     pk_exam_constant.g_yes flg_current_episode,
                     decode(eea.flg_status_det,
                            pk_exam_constant.g_exam_result,
                            decode(l_top_result,
                                   pk_exam_constant.g_yes,
                                   0,
                                   row_number()
                                   over(ORDER BY
                                        pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                                        coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)),
                            pk_exam_constant.g_exam_req,
                            row_number()
                            over(ORDER BY
                                 decode(eea.flg_referral,
                                        NULL,
                                        pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                                        pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral)),
                                 coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                            row_number()
                            over(ORDER BY
                                 decode(eea.flg_referral,
                                        NULL,
                                        pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                                        pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral)),
                                 coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)) rank,
                     pk_date_utils.date_send_tsz(i_lang, nvl(eea.dt_begin, eea.dt_req), i_prof) dt_ord,
                     decode(cso.desc_prof_ordered_by, NULL, NULL, cso.desc_prof_ordered_by) prof_order,
                     decode(cso.dt_ordered_by,
                            NULL,
                            NULL,
                            pk_date_utils.date_char_tsz(i_lang, cso.dt_ordered_by, i_prof.institution, i_prof.software)) dt_order,
                     decode(cso.id_order_type, NULL, NULL, cso.desc_order_type) order_type,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, cscs.id_prof_co_signed) co_sign_prof,
                     pk_date_utils.date_char_tsz(i_lang, cscs.dt_co_signed, i_prof.institution, i_prof.software) co_sign_date,
                     pk_string_utils.clob_to_varchar2(cscs.co_sign_notes, 1000) co_sign_notes
              FROM TABLE(tf_exams_ea(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_patient    => l_patient,
                                     i_episode    => l_episode,
                                     i_visit      => l_visit,
                                     i_cancelled  => l_cancelled,
                                     i_exam_type  => i_exam_type,
                                     i_crit_type  => i_crit_type,
                                     i_start_date => l_start_date,
                                     i_end_date   => l_end_date,
                                     i_flg_status => i_flg_status)) eea
             INNER JOIN exam_req_det erd
                ON erd.id_exam_req_det = eea.id_exam_req_det
              LEFT JOIN cso_table cso
                ON erd.id_co_sign_order = cso.id_co_sign_hist
              LEFT JOIN cso_table_cs cscs
                ON erd.id_exam_req_det = cscs.id_task_group
               AND cscs.flg_status = pk_co_sign_api.g_cosign_flg_status_cs
             ORDER BY rank, desc_exam;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_LISTVIEW',
                                              o_error);
            RETURN FALSE;
    END get_exam_listview;

    FUNCTION get_exam_orders
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_type               IN exam.flg_type%TYPE,
        i_flg_location            IN exam_req_det.flg_location%TYPE,
        i_flg_reports             IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_list pk_types.cursor_type;
    
        l_tbl_exams_order t_tbl_exam_order;
        l_tbl_req_hash    t_tbl_exam_req_hash;
        l_tbl_req_groups  t_tbl_exam_req_hash;
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE e.id_episode = i_episode
               AND v.id_visit = e.id_visit;
    
        l_visit c_visit%ROWTYPE;
    
        l_status       sys_config.value%TYPE;
        l_status_img   sys_config.value%TYPE;
        l_status_other sys_config.value%TYPE;
    
        l_sql VARCHAR2(4000);
    
        l_flg_report VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        l_group_criteria sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        IF i_exam_type = pk_exam_constant.g_type_img
        THEN
            IF i_flg_location = pk_exam_constant.g_exam_location_interior
            THEN
                l_status := pk_sysconfig.get_config('REPORT_IMAGE_EXAM_STATUS_INT', i_prof);
            ELSE
                l_status := pk_sysconfig.get_config('REPORT_IMAGE_EXAM_STATUS_EXT', i_prof);
            END IF;
        ELSIF i_exam_type = pk_exam_constant.g_type_exm
        THEN
            IF i_flg_location = pk_exam_constant.g_exam_location_interior
            THEN
                l_status := pk_sysconfig.get_config('REPORT_OTHER_EXAM_STATUS_INT', i_prof);
            ELSE
                l_status := pk_sysconfig.get_config('REPORT_OTHER_EXAM_STATUS_EXT', i_prof);
            END IF;
        ELSIF i_exam_type IS NULL
        THEN
            IF i_flg_location = pk_exam_constant.g_exam_location_interior
            THEN
                l_status_img   := pk_sysconfig.get_config('REPORT_IMAGE_EXAM_STATUS_INT', i_prof);
                l_status_other := pk_sysconfig.get_config('REPORT_OTHER_EXAM_STATUS_INT', i_prof);
            ELSE
                l_status_img   := pk_sysconfig.get_config('REPORT_IMAGE_EXAM_STATUS_EXT', i_prof);
                l_status_other := pk_sysconfig.get_config('REPORT_OTHER_EXAM_STATUS_EXT', i_prof);
            END IF;
        END IF;
    
        IF i_exam_type IS NOT NULL
        THEN
            l_sql := 'SELECT eea.id_exam_req, eea.id_exam_req_det, eea.flg_time , NULL id_req_group' || --
                     ' FROM exams_ea eea, exam_req_det erd, episode e ' || --
                     ' WHERE e.id_visit = ' || l_visit.id_visit || --
                     ' AND (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode) ' || --
                     ' AND ((eea.flg_type = ''' || pk_exam_constant.g_type_img || '''' || --
                     ' AND ''' || i_exam_type || ''' != ''' || pk_exam_constant.g_type_exm || ''') OR ' || --
                     '     (''' || i_exam_type || ''' = ''' || pk_exam_constant.g_type_exm ||
                     ''' AND eea.flg_type != ''' || pk_exam_constant.g_type_img || ''')) ' || --
                     ' AND eea.flg_time != ''' || pk_exam_constant.g_flg_time_r || '''' || --
                     ' AND eea.flg_status_det IN (' || l_status || ') ' || --
                     ' AND eea.id_exam_req_det = erd.id_exam_req_det ' || --
                     ' AND erd.flg_location = ''' || i_flg_location || '''';
        ELSE
            l_sql := 'SELECT eea.id_exam_req, eea.id_exam_req_det, eea.flg_time , NULL id_req_group' || --
                     ' FROM exams_ea eea, exam_req_det erd, episode e ' || --
                     ' WHERE e.id_visit = ' || l_visit.id_visit || --
                     ' AND (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode) ' || --
                     ' AND eea.flg_time != ''' || pk_exam_constant.g_flg_time_r || '''' || --
                     ' AND ((eea.flg_type = ''' || pk_exam_constant.g_type_img || '''' || --
                     ' AND eea.flg_status_det IN (' || l_status_img || ')) OR ' || --
                     ' (eea.flg_type = ''' || pk_exam_constant.g_type_exm || '''' || --
                     ' AND eea.flg_status_det IN (' || l_status_other || ')))' || --
                     ' AND eea.id_exam_req_det = erd.id_exam_req_det ' || --
                     ' AND erd.flg_location = ''' || i_flg_location || '''';
        
        END IF;
    
        g_error := 'OPEN O_LIST';
    
        IF i_flg_reports = pk_alert_constant.g_no
        THEN
            OPEN o_list FOR l_sql;
        ELSE
            OPEN c_list FOR l_sql;
        
            FETCH c_list BULK COLLECT
                INTO l_tbl_exams_order;
        
            l_group_criteria := pk_sysconfig.get_config('EXAM_REP_AGGREGATION_CRITERIA', i_prof);
        
            SELECT t_exam_req_hash(id_exam_req               => id_exam_req,
                                   id_exam_req_det           => id_exam_req_det,
                                   flg_time                  => flg_time,
                                   clinical_indication_hash  => clinical_indication_hash,
                                   instructions_hash         => instructions_hash,
                                   patient_instructions_hash => patient_instructions_hash,
                                   execution_hash            => execution_hash,
                                   health_plan_hash          => health_plan_hash,
                                   id_req_group              => NULL)
              BULK COLLECT
              INTO l_tbl_req_hash
              FROM (SELECT decode(instr(l_group_criteria, pk_exam_constant.g_group_by_requisition),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  t.id_exam_req) id_exam_req,
                           t.id_exam_req_det,
                           decode(instr(l_group_criteria, pk_exam_constant.g_group_by_clin_indication),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.diagnosis_notes || '|' || t.desc_diagnosis || '|' || t.clinical_purpose || '|' ||
                                                t.flg_laterality,
                                                'MD5')) clinical_indication_hash,
                           decode(instr(l_group_criteria, pk_exam_constant.g_group_by_instructions),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.flg_priority || '|' || t.flg_referral || '|' || t.flg_status || '|' ||
                                                t.exam_time || '|' || t.flg_prn || '|' || t.notes_prn || '|' ||
                                                t.order_recurrence,
                                                'MD5')) instructions_hash,
                           decode(instr(l_group_criteria, pk_exam_constant.g_group_by_patient_instructions),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.flg_fasting || '|' || t.notes_patient, 'MD5')) patient_instructions_hash,
                           decode(instr(l_group_criteria, pk_exam_constant.g_group_by_execution_instructions),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.perform_location || '|' || t.notes_scheduler || '|' || t.notes_tech || '|' ||
                                                t.notes,
                                                'MD5')) execution_hash,
                           decode(instr(l_group_criteria, pk_exam_constant.g_group_by_health_plan),
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  standard_hash(t.id_pat_health_plan || '|' || t.id_pat_exemption, 'MD5')) health_plan_hash,
                           t.flg_time
                      FROM (SELECT erd.id_exam_req,
                                   erd.id_exam_req_det,
                                   upper(erd.diagnosis_notes) diagnosis_notes,
                                   pk_diagnosis.concat_diag(i_lang, erd.id_exam_req_det, NULL, NULL, i_prof) desc_diagnosis,
                                   decode(erd.id_clinical_purpose,
                                          NULL,
                                          NULL,
                                          decode(erd.id_clinical_purpose,
                                                 0,
                                                 upper(erd.clinical_purpose_notes),
                                                 erd.id_clinical_purpose)) clinical_purpose,
                                   erd.flg_laterality,
                                   erd.flg_priority,
                                   erd.flg_referral,
                                   erd.flg_status,
                                   decode(erd.dt_target_tstz,
                                          NULL,
                                          decode(er.dt_schedule_tstz,
                                                 NULL,
                                                 NULL,
                                                 pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                       er.dt_schedule_tstz,
                                                                                       i_prof.institution,
                                                                                       i_prof.software)),
                                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                erd.dt_target_tstz,
                                                                                i_prof.institution,
                                                                                i_prof.software)) exam_time, ------------
                                   erd.flg_prn,
                                   upper(to_char(erd.prn_notes)) notes_prn,
                                   decode(erd.id_order_recurrence,
                                          NULL,
                                          NULL,
                                          pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                                i_prof,
                                                                                                erd.id_order_recurrence)) order_recurrence,
                                   erd.flg_fasting,
                                   upper(to_char(erd.notes_patient)) notes_patient,
                                   decode(erd.flg_location,
                                          NULL,
                                          NULL,
                                          decode(erd.flg_location,
                                                 pk_exam_constant.g_exam_location_interior,
                                                 decode(erd.id_room,
                                                        NULL,
                                                        erd.flg_location,
                                                        erd.flg_location || ' - ' || erd.id_room),
                                                 decode(erd.id_exec_institution,
                                                        NULL,
                                                        erd.flg_location,
                                                        erd.id_exec_institution))) perform_location,
                                   upper(erd.notes_scheduler) notes_scheduler,
                                   upper(erd.notes_tech) notes_tech,
                                   upper(erd.notes) notes,
                                   ea.flg_time,
                                   erd.id_pat_health_plan,
                                   erd.id_pat_exemption
                              FROM exam_req_det erd
                              JOIN exam_req er
                                ON er.id_exam_req = erd.id_exam_req
                              JOIN exams_ea ea
                                ON ea.id_exam_req_det = erd.id_exam_req_det
                             WHERE erd.id_exam_req_det IN (SELECT t_req.id_exam_req_det
                                                             FROM TABLE(l_tbl_exams_order) t_req)) t);
        
            SELECT t_exam_req_hash(id_exam_req               => tt.id_exam_req,
                                   id_exam_req_det           => NULL,
                                   flg_time                  => NULL,
                                   clinical_indication_hash  => tt.clinical_indication_hash,
                                   instructions_hash         => tt.instructions_hash,
                                   patient_instructions_hash => tt.patient_instructions_hash,
                                   execution_hash            => tt.execution_hash,
                                   health_plan_hash          => tt.health_plan_hash,
                                   id_req_group              => tt.rn)
              BULK COLLECT
              INTO l_tbl_req_groups
              FROM (SELECT t.*, rownum rn
                      FROM (SELECT t_req.id_exam_req,
                                   t_req.clinical_indication_hash,
                                   t_req.instructions_hash,
                                   t_req.patient_instructions_hash,
                                   t_req.execution_hash,
                                   t_req.health_plan_hash
                              FROM TABLE(l_tbl_req_hash) t_req
                              JOIN exams_ea eea
                                ON eea.id_exam_req_det = t_req.id_exam_req_det
                             GROUP BY t_req.id_exam_req,
                                      t_req.clinical_indication_hash,
                                      t_req.instructions_hash,
                                      t_req.patient_instructions_hash,
                                      t_req.execution_hash,
                                      t_req.health_plan_hash) t) tt;
        
            OPEN o_list FOR
                SELECT coalesce(t_req.id_exam_req,
                                (SELECT erd.id_exam_req
                                   FROM exam_req_det erd
                                  WHERE erd.id_exam_req_det = t_req.id_exam_req_det)) id_exam_req,
                       t_req.id_exam_req_det,
                       t_req.flg_time,
                       t_req_groups.id_req_group
                  FROM TABLE(l_tbl_req_hash) t_req
                  JOIN TABLE(l_tbl_req_groups) t_req_groups
                    ON (t_req.id_exam_req = t_req_groups.id_exam_req OR t_req.id_exam_req IS NULL)
                   AND (t_req.clinical_indication_hash = t_req_groups.clinical_indication_hash OR
                       t_req.clinical_indication_hash IS NULL)
                   AND (t_req.instructions_hash = t_req_groups.instructions_hash OR t_req.instructions_hash IS NULL)
                   AND (t_req.patient_instructions_hash = t_req_groups.patient_instructions_hash OR
                       t_req.patient_instructions_hash IS NULL)
                   AND (t_req.execution_hash = t_req_groups.execution_hash OR t_req.execution_hash IS NULL)
                   AND (t_req.health_plan_hash = t_req_groups.health_plan_hash OR t_req.health_plan_hash IS NULL)
                   AND l_group_criteria IS NOT NULL;
        END IF;
    
        OPEN o_exam_clinical_questions FOR
            SELECT id_exam_req_det,
                   id_content,
                   flg_time,
                   id_questionnaire,
                   decode(l_flg_report,
                          pk_exam_constant.g_no,
                          decode(rownum, 1, pk_message.get_message(i_lang, 'EXAMS_T251') || chr(10), NULL) || chr(9) ||
                          chr(32) || chr(32) || desc_clinical_question || desc_response,
                          desc_clinical_question) desc_clinical_question,
                   decode(l_flg_report, pk_exam_constant.g_no, to_clob(''), to_clob(desc_response)) desc_response
              FROM (SELECT id_exam_req_det,
                           id_content,
                           flg_time,
                           id_questionnaire,
                           desc_clinical_question,
                           desc_response
                      FROM (SELECT DISTINCT eqr1.id_exam_req_det,
                                            eqr1.id_content,
                                            eqr1.flg_time,
                                            eqr1.id_questionnaire,
                                            decode(l_flg_report,
                                                   pk_exam_constant.g_no,
                                                   '<b>' ||
                                                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                   i_prof,
                                                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                   eqr1.id_questionnaire) || ':</b> ',
                                                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                   i_prof,
                                                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                   eqr1.id_questionnaire)) desc_clinical_question,
                                            dbms_lob.substr(decode(dbms_lob.getlength(eqr.notes),
                                                                   NULL,
                                                                   to_clob(decode(eqr1.desc_response,
                                                                                  NULL,
                                                                                  '---',
                                                                                  eqr1.desc_response)),
                                                                   pk_exam_utils.get_exam_response(i_lang,
                                                                                                   i_prof,
                                                                                                   eqr.notes)),
                                                            3800) desc_response,
                                            pk_exam_utils.get_exam_questionnaire_rank(i_lang,
                                                                                      i_prof,
                                                                                      erd.id_exam,
                                                                                      eqr.id_questionnaire,
                                                                                      eqr.flg_time) rank
                              FROM (SELECT eqr.id_exam_req_det,
                                           eqr.id_questionnaire,
                                           listagg(pk_exam_utils.get_questionnaire_id_content(i_lang,
                                                                                              i_prof,
                                                                                              eqr.id_questionnaire,
                                                                                              eqr.id_response),
                                                   '; ') within GROUP(ORDER BY eqr.id_response) id_content,
                                           eqr.flg_time,
                                           listagg(pk_mcdt.get_response_alias(i_lang,
                                                                              i_prof,
                                                                              'RESPONSE.CODE_RESPONSE.' || eqr.id_response),
                                                   '; ') within GROUP(ORDER BY eqr.id_response) desc_response,
                                           eqr.dt_last_update_tstz,
                                           row_number() over(PARTITION BY eqr.id_questionnaire, eqr.flg_time ORDER BY eqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                      FROM exam_question_response eqr
                                     INNER JOIN exam_req_det erd
                                        ON eqr.id_exam_req_det = erd.id_exam_req_det
                                     INNER JOIN exam_req er
                                        ON er.id_exam_req = erd.id_exam_req
                                     WHERE er.id_episode = i_episode
                                     GROUP BY eqr.id_exam_req_det,
                                              eqr.id_questionnaire,
                                              eqr.flg_time,
                                              eqr.dt_last_update_tstz) eqr1,
                                   exam_question_response eqr,
                                   exam_req_det erd
                             WHERE eqr1.id_exam_req_det = eqr.id_exam_req_det
                               AND eqr1.id_questionnaire = eqr.id_questionnaire
                               AND eqr1.dt_last_update_tstz = eqr.dt_last_update_tstz
                               AND eqr1.flg_time = eqr.flg_time
                               AND eqr.id_exam_req_det = erd.id_exam_req_det)
                     ORDER BY id_exam_req_det, flg_time, rank);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_ORDERS',
                                              o_error);
            RETURN FALSE;
    END get_exam_orders;

    FUNCTION get_exam_result_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN exam_req.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE e.id_episode = i_episode
               AND v.id_visit = e.id_visit;
    
        l_visit c_visit%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN C_INST';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT eea.id_exam_req,
                            eea.id_exam_req_det,
                            eea.id_exam,
                            eea.flg_status_det flg_status,
                            pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                            nvl(eea.desc_result, pk_message.get_message(i_lang, 'IMAGE_T011')) result_notes, -- 'available' label when result isn't free text
                            pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det) rank,
                            pk_date_utils.date_send_tsz(i_lang, eea.dt_req, i_prof) dt_ord
              FROM exams_ea eea
             WHERE eea.id_visit = l_visit.id_visit
               AND eea.id_exam_result IS NOT NULL
             ORDER BY rank, dt_ord DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_RESULT_LIST',
                                              o_error);
            RETURN FALSE;
    END get_exam_result_list;

    FUNCTION get_exam_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report              IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
        aa_code_messages pk_exam_constant.t_tbl_code_messages;
    
        l_exam_order         t_tbl_exams_detail;
        l_exam_co_sign       t_tbl_exam_co_sign;
        l_exam_perform       t_tbl_exam_perform;
        l_exam_result        t_tbl_exam_result;
        l_exam_result_images t_tbl_exam_result_images;
        l_exam_doc           t_tbl_exam_doc;
        l_exam_review        t_tbl_exam_review;
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN pk_exam_constant.ga_code_messages_exam_detail.first .. pk_exam_constant.ga_code_messages_exam_detail.last
        LOOP
            aa_code_messages(pk_exam_constant.ga_code_messages_exam_detail(i)) := '<b>' ||
                                                                                  pk_message.get_message(i_lang,
                                                                                                         i_prof,
                                                                                                         pk_exam_constant.ga_code_messages_exam_detail(i)) ||
                                                                                  '</b> ';
        END LOOP;
    
        g_error      := 'OPEN O_EXAM_ORDER';
        l_exam_order := pk_exam_core.tf_get_exam_order(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_episode          => i_episode,
                                                       i_exam_req_det     => i_exam_req_det,
                                                       i_flg_report       => i_flg_report,
                                                       i_aa_code_messages => aa_code_messages);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            OPEN o_exam_order FOR
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_exam_req_det id_exam_req_det,
                 t.registry registry,
                 eea.flg_status_det flg_status,
                 t.desc_exam desc_exam,
                 t.num_order num_order,
                 erd.barcode barcode,
                 eea.id_exam_cat id_category,
                 pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || eea.id_exam_cat) desc_category,
                 ecp.parent_id id_parent_category,
                 pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ecp.parent_id) desc_parent_category,
                 eea.id_prof_req id_prof_req,
                 t.diagnosis_notes diagnosis_notes,
                 t.desc_diagnosis desc_diagnosis,
                 t.clinical_purpose clinical_purpose,
                 t.laterality laterality,
                 t.priority priority,
                 t.desc_status desc_status,
                 t.title_order_set title_order_set,
                 t.task_depend task_depend,
                 eea.flg_time, --
                 t.desc_time desc_time,
                 t.desc_time_limit desc_time_limit,
                 t.order_recurrence order_recurrence,
                 t.weeks_pregnant weeks_pregnant,
                 t.trimester trimester,
                 t.prn prn,
                 t.notes_prn notes_prn,
                 t.fasting fasting,
                 t.notes_patient notes_patient,
                 erd.flg_location, --
                 t.perform_location perform_location,
                 t.notes_scheduler notes_scheduler,
                 t.notes_technician notes_technician,
                 t.notes notes,
                 t.co_sign_status,
                 t.order_type order_type,
                 t.prof_order prof_order,
                 t.dt_order dt_order,
                 php.id_health_plan,
                 decode(php.id_pat_health_plan, NULL, NULL, erd.id_pat_health_plan) id_pat_health_plan,
                 decode(php.id_pat_health_plan, NULL, NULL, t.financial_entity) financial_entity,
                 decode(php.id_pat_health_plan, NULL, NULL, t.health_plan) health_plan,
                 decode(php.id_pat_health_plan, NULL, NULL, t.insurance_number) insurance_number,
                 t.exemption exemption,
                 t.ref_type ref_type,
                 t.referrer referrer,
                 t.cancel_reason cancel_reason,
                 t.cancel_notes cancel_notes,
                 t.cancel_order_type cancel_order_type,
                 t.cancel_prof_order cancel_prof_order,
                 t.cancel_dt_order cancel_dt_order,
                 t.dt_ord dt_ord,
                 CASE i_flg_report
                     WHEN pk_alert_constant.g_no THEN
                      NULL
                     ELSE
                      l_msg_reg || ' ' ||
                      pk_prof_utils.get_name_signature(i_lang,
                                                       i_prof,
                                                       coalesce(erd.id_prof_cancel,
                                                                erd.id_prof_last_update,
                                                                eea.id_prof_req)) ||
                      decode(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              coalesce(erd.id_prof_cancel,
                                                                       erd.id_prof_last_update,
                                                                       eea.id_prof_req),
                                                              coalesce(erd.dt_cancel_tstz,
                                                                       erd.dt_last_update_tstz,
                                                                       eea.dt_req),
                                                              eea.id_episode),
                             NULL,
                             '; ',
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      coalesce(erd.id_prof_cancel,
                                                                               erd.id_prof_last_update,
                                                                               eea.id_prof_req),
                                                                      coalesce(erd.dt_cancel_tstz,
                                                                               erd.dt_last_update_tstz,
                                                                               eea.dt_req),
                                                                      eea.id_episode) || '); ') ||
                      pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                            coalesce(erd.dt_cancel_tstz,
                                                                     erd.dt_last_update_tstz,
                                                                     eea.dt_req),
                                                            i_prof.institution,
                                                            i_prof.software)
                 END registry_reports
                  FROM exams_ea eea
                  JOIN TABLE(l_exam_order) t
                    ON eea.id_exam_req_det = t.id_exam_req_det
                  JOIN exam_req_det erd
                    ON erd.id_exam_req_det = eea.id_exam_req_det
                  LEFT JOIN exam_cat ecp
                    ON eea.id_exam_cat = ecp.id_exam_cat
                  LEFT JOIN pat_health_plan php
                    ON php.id_pat_health_plan = erd.id_pat_health_plan
                   AND php.flg_status = pk_alert_constant.g_active
                 WHERE eea.id_exam_req_det = i_exam_req_det;
        ELSE
            OPEN o_exam_order FOR
                SELECT id_exam_req_det,
                       registry,
                       desc_exam,
                       num_order,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(clinical_indication,
                                                                   diagnosis_notes,
                                                                   desc_diagnosis,
                                                                   clinical_purpose,
                                                                   laterality),
                                                     'T') clinical_indication,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(diagnosis_notes), 'F') diagnosis_notes,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_diagnosis), 'F') desc_diagnosis,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(clinical_purpose), 'F') clinical_purpose,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(laterality), 'F') laterality,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(instructions,
                                                                   priority,
                                                                   desc_status,
                                                                   title_order_set,
                                                                   task_depend,
                                                                   desc_time,
                                                                   desc_time_limit,
                                                                   order_recurrence,
                                                                   weeks_pregnant,
                                                                   trimester,
                                                                   prn,
                                                                   notes_prn),
                                                     'T') instructions,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(priority), 'F') priority,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_status), 'F') desc_status,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(title_order_set), 'F') title_order_set,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(task_depend), 'F') task_depend,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_time), 'F') desc_time,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_time_limit), 'F') desc_time_limit,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(order_recurrence), 'F') order_recurrence,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(weeks_pregnant), 'F') weeks_pregnant,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(trimester), 'F') trimester,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(prn), 'F') prn,
                       pk_exam_utils.get_exam_detail_clob(i_lang, i_prof, table_clob(notes_prn), 'F') notes_prn,
                       pk_exam_utils.get_exam_detail_clob(i_lang,
                                                          i_prof,
                                                          table_clob(patient_instructions, fasting, notes_patient),
                                                          'T') patient_instructions,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(fasting), 'F') fasting,
                       pk_exam_utils.get_exam_detail_clob(i_lang, i_prof, table_clob(notes_patient), 'F') notes_patient,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(execution,
                                                                   perform_location,
                                                                   notes_scheduler,
                                                                   notes_technician,
                                                                   notes),
                                                     'T') execution,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(perform_location), 'F') perform_location,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(notes_scheduler), 'F') notes_scheduler,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(notes_technician), 'F') notes_technician,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(notes), 'F') notes,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(co_sign, order_type, prof_order, dt_order),
                                                     'T') co_sign,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(order_type), 'F') order_type,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(prof_order), 'F') prof_order,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(dt_order), 'F') dt_order,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(health_insurance,
                                                                   financial_entity,
                                                                   health_plan,
                                                                   insurance_number,
                                                                   exemption),
                                                     'T') health_insurance,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(financial_entity), 'F') financial_entity,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(health_plan), 'F') health_plan,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(insurance_number), 'F') insurance_number,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(exemption), 'F') exemption,
                       ref_type,
                       referrer,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(cancellation,
                                                                   cancel_reason,
                                                                   cancel_notes,
                                                                   cancel_order_type,
                                                                   cancel_prof_order,
                                                                   cancel_dt_order),
                                                     'T') cancellation,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_reason), 'F') cancel_reason,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_notes), 'F') cancel_notes,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_order_type), 'F') cancel_order_type,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_prof_order), 'F') cancel_prof_order,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_dt_order), 'F') cancel_dt_order,
                       dt_ord
                  FROM (SELECT /*+opt_estimate (table t rows=1)*/
                         t.id_exam_req_det      id_exam_req_det,
                         t.registry             registry,
                         t.desc_exam            desc_exam,
                         t.num_order            num_order,
                         t.clinical_indication  clinical_indication,
                         t.diagnosis_notes      diagnosis_notes,
                         t.desc_diagnosis       desc_diagnosis,
                         t.clinical_purpose     clinical_purpose,
                         t.laterality           laterality,
                         t.instructions         instructions,
                         t.priority             priority,
                         t.desc_status          desc_status,
                         t.title_order_set      title_order_set,
                         t.task_depend          task_depend,
                         t.desc_time            desc_time,
                         t.desc_time_limit      desc_time_limit,
                         t.order_recurrence     order_recurrence,
                         t.weeks_pregnant       weeks_pregnant,
                         t.trimester            trimester,
                         t.prn                  prn,
                         t.notes_prn            notes_prn,
                         t.patient_instructions patient_instructions,
                         t.fasting              fasting,
                         t.notes_patient        notes_patient,
                         t.execution            execution,
                         t.perform_location     perform_location,
                         t.notes_scheduler      notes_scheduler,
                         t.notes_technician     notes_technician,
                         t.notes                notes,
                         t.co_sign              co_sign,
                         t.order_type           order_type,
                         t.prof_order           prof_order,
                         t.dt_order             dt_order,
                         t.health_insurance     health_insurance,
                         t.financial_entity     financial_entity,
                         t.health_plan          health_plan,
                         t.insurance_number     insurance_number,
                         t.exemption            exemption,
                         t.ref_type             ref_type,
                         t.referrer             referrer,
                         t.cancellation         cancellation,
                         t.cancel_reason        cancel_reason,
                         t.cancel_notes         cancel_notes,
                         t.cancel_prof_order    cancel_prof_order,
                         t.cancel_dt_order      cancel_dt_order,
                         t.cancel_order_type    cancel_order_type,
                         t.dt_ord               dt_ord
                          FROM TABLE(l_exam_order) t);
        END IF;
    
        g_error := 'OPEN O_EXAM_CLINICAL_QUESTIONS';
        OPEN o_exam_clinical_questions FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_exam_req_det        id_exam_req_det,
             t.flg_time               flg_time,
             t.id_content             id_content,
             t.desc_clinical_question desc_clinical_question,
             t.desc_response          desc_response
              FROM TABLE(pk_exam_core.tf_get_exam_cq(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_exam_req_det => i_exam_req_det,
                                                     i_flg_report   => i_flg_report)) t;
    
        g_error        := 'OPEN O_EXAM_CO_SIGN';
        l_exam_co_sign := pk_exam_core.tf_get_exam_co_sign(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_episode          => i_episode,
                                                           i_exam_req_det     => i_exam_req_det,
                                                           i_flg_report       => i_flg_report,
                                                           i_aa_code_messages => aa_code_messages);
    
        OPEN o_exam_co_sign FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_co_sign) t;
    
        g_error        := 'OPEN O_EXAM_PERFORM';
        l_exam_perform := pk_exam_core.tf_get_exam_perform(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_episode          => i_episode,
                                                           i_exam_req_det     => i_exam_req_det,
                                                           i_flg_report       => i_flg_report,
                                                           i_aa_code_messages => aa_code_messages);
        OPEN o_exam_perform FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_perform) t;
    
        g_error       := 'OPEN O_EXAM_RESULT';
        l_exam_result := pk_exam_core.tf_get_exam_result(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_episode          => i_episode,
                                                         i_exam_req_det     => i_exam_req_det,
                                                         i_flg_report       => i_flg_report,
                                                         i_aa_code_messages => aa_code_messages);
        OPEN o_exam_result FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_result) t;
    
        g_error              := 'OPEN O_EXAM_RESULT_IMAGES';
        l_exam_result_images := pk_exam_core.tf_get_exam_result_images(i_lang             => i_lang,
                                                                       i_prof             => i_prof,
                                                                       i_episode          => i_episode,
                                                                       i_exam_req_det     => i_exam_req_det,
                                                                       i_flg_report       => i_flg_report,
                                                                       i_aa_code_messages => aa_code_messages);
        OPEN o_exam_result_images FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_result_images) t;
    
        g_error    := 'OPEN O_EXAM_DOC';
        l_exam_doc := pk_exam_core.tf_get_exam_doc(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_episode          => i_episode,
                                                   i_exam_req_det     => i_exam_req_det,
                                                   i_flg_report       => i_flg_report,
                                                   i_aa_code_messages => aa_code_messages);
        OPEN o_exam_doc FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_doc) t;
    
        g_error       := 'OPEN O_EXAM_REVIEW';
        l_exam_review := pk_exam_core.tf_get_exam_review(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_episode          => i_episode,
                                                         i_exam_req_det     => i_exam_req_det,
                                                         i_flg_report       => i_flg_report,
                                                         i_aa_code_messages => aa_code_messages);
        OPEN o_exam_review FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_review) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_exam_order);
            pk_types.open_my_cursor(o_exam_co_sign);
            pk_types.open_my_cursor(o_exam_perform);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_result_images);
            pk_types.open_my_cursor(o_exam_doc);
            pk_types.open_my_cursor(o_exam_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_detail;

    FUNCTION get_exam_detail_history
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report              IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_order_hist    t_tbl_exams_detail;
        l_exam_co_sign       t_tbl_exam_co_sign;
        l_exam_perform_hist  t_tbl_exam_perform_history;
        l_exam_result_hist   t_tbl_exam_result;
        l_exam_result_images t_tbl_exam_result_images;
        l_exam_doc           t_tbl_exam_doc;
        l_exam_review        t_tbl_exam_review;
    
        aa_code_messages pk_exam_constant.t_tbl_code_messages;
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN pk_exam_constant.ga_code_messages_exam_detail.first .. pk_exam_constant.ga_code_messages_exam_detail.last
        LOOP
            aa_code_messages(pk_exam_constant.ga_code_messages_exam_detail(i)) := '<b>' ||
                                                                                  pk_message.get_message(i_lang,
                                                                                                         i_prof,
                                                                                                         pk_exam_constant.ga_code_messages_exam_detail(i)) ||
                                                                                  '</b> ';
        END LOOP;
    
        g_error := 'GET MESSAGES UPDATE';
        FOR i IN pk_exam_constant.ga_code_messages_exam_detail_upd.first .. pk_exam_constant.ga_code_messages_exam_detail_upd.last
        LOOP
            aa_code_messages(pk_exam_constant.ga_code_messages_exam_detail_upd(i)) := '<b>' ||
                                                                                      pk_message.get_message(i_lang,
                                                                                                             i_prof,
                                                                                                             pk_exam_constant.ga_code_messages_exam_detail_upd(i)) ||
                                                                                      '</b> ';
        END LOOP;
    
        g_error           := 'OPEN O_EXAM_ORDER';
        l_exam_order_hist := pk_exam_core.tf_get_exam_order_history(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_episode          => i_episode,
                                                                    i_exam_req_det     => i_exam_req_det,
                                                                    i_flg_report       => i_flg_report,
                                                                    i_aa_code_messages => aa_code_messages);
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            OPEN o_exam_order FOR
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_exam_req_det   id_exam_req_det,
                 t.registry          registry,
                 t.desc_exam         desc_exam,
                 t.num_order         num_order,
                 t.diagnosis_notes   diagnosis_notes,
                 t.desc_diagnosis    desc_diagnosis,
                 t.clinical_purpose  clinical_purpose,
                 t.laterality        laterality,
                 t.priority          priority,
                 t.desc_status       desc_status,
                 t.title_order_set   title_order_set,
                 t.task_depend       task_depend,
                 t.desc_time         desc_time,
                 t.desc_time_limit   desc_time_limit,
                 t.order_recurrence  order_recurrence,
                 t.weeks_pregnant    weeks_pregnant,
                 t.trimester         trimester,
                 t.prn               prn,
                 t.notes_prn         notes_prn,
                 t.fasting           fasting,
                 t.notes_patient     notes_patient,
                 t.perform_location  perform_location,
                 t.notes_scheduler   notes_scheduler,
                 t.notes_technician  notes_technician,
                 t.notes             notes,
                 t.order_type        order_type,
                 t.prof_order        prof_order,
                 t.dt_order          dt_order,
                 t.financial_entity  financial_entity,
                 t.health_plan       health_plan,
                 t.insurance_number  insurance_number,
                 t.exemption         exemption,
                 t.ref_type          ref_type,
                 t.referrer          referrer,
                 t.cancel_reason     cancel_reason,
                 t.cancel_notes      cancel_notes,
                 t.cancel_order_type cancel_order_type,
                 t.cancel_prof_order cancel_prof_order,
                 t.cancel_dt_order   cancel_dt_order,
                 t.dt_ord            dt_ord
                  FROM TABLE(l_exam_order_hist) t;
        ELSE
            OPEN o_exam_order FOR
                SELECT id_exam_req_det,
                       registry,
                       desc_exam,
                       num_order,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(clinical_indication,
                                                                   diagnosis_notes,
                                                                   desc_diagnosis,
                                                                   clinical_purpose,
                                                                   laterality),
                                                     'T') clinical_indication,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(diagnosis_notes), 'F') diagnosis_notes,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_diagnosis), 'F') desc_diagnosis,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(clinical_purpose), 'F') clinical_purpose,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(laterality), 'F') laterality,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(instructions,
                                                                   priority,
                                                                   desc_status,
                                                                   title_order_set,
                                                                   task_depend,
                                                                   desc_time,
                                                                   desc_time_limit,
                                                                   order_recurrence,
                                                                   weeks_pregnant,
                                                                   trimester,
                                                                   prn,
                                                                   notes_prn),
                                                     'T') instructions,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(priority), 'F') priority,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_status), 'F') desc_status,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(title_order_set), 'F') title_order_set,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(task_depend), 'F') task_depend,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_time), 'F') desc_time,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(desc_time_limit), 'F') desc_time_limit,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(order_recurrence), 'F') order_recurrence,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(weeks_pregnant), 'F') weeks_pregnant,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(trimester), 'F') trimester,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(prn), 'F') prn,
                       pk_exam_utils.get_exam_detail_clob(i_lang, i_prof, table_clob(notes_prn), 'F') notes_prn,
                       pk_exam_utils.get_exam_detail_clob(i_lang,
                                                          i_prof,
                                                          table_clob(patient_instructions, fasting, notes_patient),
                                                          'T') patient_instructions,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(fasting), 'F') fasting,
                       pk_exam_utils.get_exam_detail_clob(i_lang, i_prof, table_clob(notes_patient), 'F') notes_patient,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(execution,
                                                                   perform_location,
                                                                   notes_scheduler,
                                                                   notes_technician,
                                                                   notes),
                                                     'T') execution,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(perform_location), 'F') perform_location,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(notes_scheduler), 'F') notes_scheduler,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(notes_technician), 'F') notes_technician,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(notes), 'F') notes,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(co_sign, order_type, prof_order, dt_order),
                                                     'T') co_sign,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(order_type), 'F') order_type,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(prof_order), 'F') prof_order,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(dt_order), 'F') dt_order,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(health_insurance,
                                                                   financial_entity,
                                                                   health_plan,
                                                                   insurance_number,
                                                                   exemption),
                                                     'T') health_insurance,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(financial_entity), 'F') financial_entity,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(health_plan), 'F') health_plan,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(insurance_number), 'F') insurance_number,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(exemption), 'F') exemption,
                       ref_type,
                       referrer,
                       pk_exam_utils.get_exam_detail(i_lang,
                                                     i_prof,
                                                     table_varchar(cancellation,
                                                                   cancel_reason,
                                                                   cancel_notes,
                                                                   cancel_order_type,
                                                                   cancel_prof_order,
                                                                   cancel_dt_order),
                                                     'T') cancellation,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_reason), 'F') cancel_reason,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_notes), 'F') cancel_notes,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_order_type), 'F') cancel_order_type,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_prof_order), 'F') cancel_prof_order,
                       pk_exam_utils.get_exam_detail(i_lang, i_prof, table_varchar(cancel_dt_order), 'F') cancel_dt_order,
                       dt_ord,
                       dt_last_update
                  FROM (SELECT /*+opt_estimate (table t rows=1)*/
                         t.id_exam_req_det      id_exam_req_det,
                         t.registry             registry,
                         t.desc_exam            desc_exam,
                         t.num_order            num_order,
                         t.clinical_indication  clinical_indication,
                         t.diagnosis_notes      diagnosis_notes,
                         t.desc_diagnosis       desc_diagnosis,
                         t.clinical_purpose     clinical_purpose,
                         t.laterality           laterality,
                         t.instructions         instructions,
                         t.priority             priority,
                         t.desc_status          desc_status,
                         t.title_order_set      title_order_set,
                         t.task_depend          task_depend,
                         t.desc_time            desc_time,
                         t.desc_time_limit      desc_time_limit,
                         t.order_recurrence     order_recurrence,
                         t.weeks_pregnant       weeks_pregnant,
                         t.trimester            trimester,
                         t.prn                  prn,
                         t.notes_prn            notes_prn,
                         t.patient_instructions patient_instructions,
                         t.fasting              fasting,
                         t.notes_patient        notes_patient,
                         t.execution            execution,
                         t.perform_location     perform_location,
                         t.notes_scheduler      notes_scheduler,
                         t.notes_technician     notes_technician,
                         t.notes                notes,
                         t.co_sign              co_sign,
                         t.order_type           order_type,
                         t.prof_order           prof_order,
                         t.dt_order             dt_order,
                         t.health_insurance     health_insurance,
                         t.financial_entity     financial_entity,
                         t.health_plan          health_plan,
                         t.insurance_number     insurance_number,
                         t.exemption            exemption,
                         t.ref_type             ref_type,
                         t.referrer             referrer,
                         t.cancellation         cancellation,
                         t.cancel_reason        cancel_reason,
                         t.cancel_notes         cancel_notes,
                         t.cancel_order_type    cancel_order_type,
                         t.cancel_prof_order    cancel_prof_order,
                         t.cancel_dt_order      cancel_dt_order,
                         t.dt_ord               dt_ord,
                         t.dt_last_update
                          FROM TABLE(l_exam_order_hist) t);
        END IF;
    
        g_error := 'OPEN O_EXAM_CLINICAL_QUESTIONS';
        OPEN o_exam_clinical_questions FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_exam_req_det        id_exam_req_det,
             t.flg_time               flg_time,
             t.id_content             id_content,
             t.desc_clinical_question desc_clinical_question,
             t.desc_response          desc_response
              FROM TABLE(pk_exam_core.tf_get_exam_cq_history(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_episode      => i_episode,
                                                             i_exam_req_det => i_exam_req_det,
                                                             i_flg_report   => i_flg_report)) t;
    
        g_error        := 'OPEN O_EXAM_CO_SIGN';
        l_exam_co_sign := pk_exam_core.tf_get_exam_co_sign_history(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_episode          => i_episode,
                                                                   i_exam_req_det     => i_exam_req_det,
                                                                   i_flg_report       => i_flg_report,
                                                                   i_aa_code_messages => aa_code_messages);
        OPEN o_exam_co_sign FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_co_sign) t;
    
        g_error             := 'OPEN O_EXAM_PERFORM';
        l_exam_perform_hist := pk_exam_core.tf_get_exam_perform_history(i_lang             => i_lang,
                                                                        i_prof             => i_prof,
                                                                        i_episode          => i_episode,
                                                                        i_exam_req_det     => i_exam_req_det,
                                                                        i_flg_report       => i_flg_report,
                                                                        i_aa_code_messages => aa_code_messages);
        OPEN o_exam_perform FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_perform_hist) t;
    
        g_error            := 'OPEN O_EXAM_RESULT';
        l_exam_result_hist := pk_exam_core.tf_get_exam_result_history(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_episode          => i_episode,
                                                                      i_exam_req_det     => i_exam_req_det,
                                                                      i_flg_report       => i_flg_report,
                                                                      i_aa_code_messages => aa_code_messages);
        OPEN o_exam_result FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_result_hist) t;
    
        g_error              := 'OPEN O_EXAM_RESULT_IMAGES';
        l_exam_result_images := pk_exam_core.tf_get_exam_result_images_history(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_episode          => i_episode,
                                                                               i_exam_req_det     => i_exam_req_det,
                                                                               i_flg_report       => i_flg_report,
                                                                               i_aa_code_messages => aa_code_messages);
        OPEN o_exam_result_images FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_result_images) t;
    
        g_error    := 'OPEN O_EXAM_DOC';
        l_exam_doc := pk_exam_core.tf_get_exam_doc_history(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_episode          => i_episode,
                                                           i_exam_req_det     => i_exam_req_det,
                                                           i_flg_report       => i_flg_report,
                                                           i_aa_code_messages => aa_code_messages);
        OPEN o_exam_doc FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_doc) t;
    
        g_error       := 'OPEN O_EXAM_REVIEW';
        l_exam_review := pk_exam_core.tf_get_exam_review_history(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_episode          => i_episode,
                                                                 i_exam_req_det     => i_exam_req_det,
                                                                 i_flg_report       => i_flg_report,
                                                                 i_aa_code_messages => aa_code_messages);
        OPEN o_exam_review FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_exam_review) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_exam_order);
            pk_types.open_my_cursor(o_exam_co_sign);
            pk_types.open_my_cursor(o_exam_perform);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_result_images);
            pk_types.open_my_cursor(o_exam_doc);
            pk_types.open_my_cursor(o_exam_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_detail_history;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
    
        l_result t_rec_print_list_job := t_rec_print_list_job();
    
        l_print_list_area print_list_job.id_print_list_area%TYPE;
        l_count           NUMBER(24);
    
    BEGIN
    
        g_error := 'GETTING CONTEXT DATA AND AREA OF THIS PRINT LIST JOB';
        WITH t AS
         (SELECT v.context_data, v.id_print_list_area
            FROM v_print_list_context_data v
           WHERE v.id_print_list_job = i_id_print_list_job)
        SELECT length(regexp_replace(context_data, '[^|]')) / length('|') count_context_data, id_print_list_area
          INTO l_count, l_print_list_area
          FROM t;
    
        l_result.id_print_list_job := i_id_print_list_job;
    
        IF l_print_list_area = pk_print_list_db.g_print_list_area_img_exam
        THEN
            l_result.title_desc := pk_message.get_message(i_lang, i_prof, 'EXAMS_T085');
        ELSE
            l_result.title_desc := pk_message.get_message(i_lang, i_prof, 'EXAMS_T087');
        END IF;
    
        IF l_count = 1
        THEN
            l_result.subtitle_desc := l_count || ' ' || lower(pk_message.get_message(i_lang, i_prof, 'EXAMS_T011'));
        ELSE
            l_result.subtitle_desc := l_count || ' ' || lower(pk_message.get_message(i_lang, i_prof, 'EXAMS_T005'));
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

    FUNCTION get_exam_in_print_list
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
    END get_exam_in_print_list;

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_exam_req_det    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type exam.flg_type%TYPE;
    
        l_context_data     table_clob;
        l_print_list_areas table_number;
    
    BEGIN
    
        IF i_episode IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
    
        l_context_data.extend;
        l_print_list_areas.extend;
    
        IF i_exam_req_det IS NULL
           OR i_exam_req_det.count = 0
        THEN
            g_error_code := 'REP_EXCEPTION_018';
            g_error      := pk_message.get_message(i_lang, 'REP_EXCEPTION_018');
            RAISE g_user_exception;
        END IF;
    
        SELECT e.flg_type, table_clob(concatenate(erd.id_exam_req_det || '|'))
          INTO l_flg_type, l_context_data
          FROM exam_req_det erd, exam e
         WHERE erd.id_exam_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                        *
                                         FROM TABLE(i_exam_req_det) t)
           AND erd.id_exam = e.id_exam
         GROUP BY flg_type;
    
        IF l_flg_type = pk_exam_constant.g_type_img
        THEN
            l_print_list_areas(1) := pk_print_list_db.g_print_list_area_img_exam;
        ELSE
            l_print_list_areas(1) := pk_print_list_db.g_print_list_area_other_exam;
        END IF;
    
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

    FUNCTION get_exam_print_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN exam.flg_type%TYPE,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_default_save sys_config.value%TYPE;
    
        l_can_add     VARCHAR2(1 CHAR);
        l_save_option sys_list.internal_name%TYPE;
    
    BEGIN
    
        IF i_flg_type = pk_exam_constant.g_type_img
        THEN
            l_default_save := pk_sysconfig.get_config('IMAGING_EXAMS_DEFAULT_COMPLETION_OPTION_SAVE', i_prof);
        ELSE
            l_default_save := pk_sysconfig.get_config('OTHER_EXAMS_DEFAULT_COMPLETION_OPTION_SAVE', i_prof);
        END IF;
    
        g_error := 'CALL PK_PRINT_LIST_DB.CHECK_FUNC_CAN_ADD';
        IF NOT pk_print_list_db.check_func_can_add(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   o_flg_can_add => l_can_add,
                                                   o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --gets printing list configurations
        IF l_default_save = pk_exam_constant.g_no
        THEN
            g_error := 'CALL PK_PRINT_LIST_DB.GET_PRINT_LIST_DEF_OPTION';
            IF NOT pk_print_list_db.get_print_list_def_option(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_print_list_area => CASE
                                                                                  WHEN i_flg_type = pk_exam_constant.g_type_img THEN
                                                                                   pk_print_list_db.g_print_list_area_img_exam
                                                                                  ELSE
                                                                                   pk_print_list_db.g_print_list_area_other_exam
                                                                              END,
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
                                                      decode(i_flg_type,
                                                             pk_exam_constant.g_type_img,
                                                             'ImageList.swf',
                                                             'ExamList.swf'))) id_report,
                   decode(tbl_opt.sys_list_internal_name, l_save_option, pk_exam_constant.g_yes, pk_exam_constant.g_no) flg_default,
                   tbl_opt.rank rank,
                   decode(tbl_opt.sys_list_internal_name,
                          'SAVE_PRINT_LIST',
                          decode(l_can_add, pk_exam_constant.g_yes, pk_exam_constant.g_yes, pk_exam_constant.g_no),
                          pk_exam_constant.g_yes) flg_available
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang,
                                                         i_prof,
                                                         CASE
                                                             WHEN i_flg_type = pk_exam_constant.g_type_img THEN
                                                              'IMAGING_EXAMS_COMPLETION_OPTIONS'
                                                             ELSE
                                                              'OTHER_EXAMS_COMPLETION_OPTIONS'
                                                         END)) tbl_opt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_PRINT_LIST',
                                              o_error);
            RETURN FALSE;
    END get_exam_print_list;

    FUNCTION tf_get_exam_to_print
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_varchar
    ) RETURN table_varchar IS
    
        l_flg_type exam.flg_type%TYPE;
    
        l_status_int sys_config.value%TYPE;
        l_status_ext sys_config.value%TYPE;
    
        l_sql   VARCHAR2(4000);
        l_count NUMBER;
    
    BEGIN
    
        SELECT e.flg_type
          INTO l_flg_type
          FROM exam_req_det erd, exam e
         WHERE erd.id_exam_req_det = i_exam_req_det(1)
           AND erd.id_exam = e.id_exam;
    
        IF l_flg_type = pk_exam_constant.g_type_img
        THEN
            l_status_int := pk_sysconfig.get_config('REPORT_IMAGE_EXAM_STATUS_INT', i_prof);
            l_status_ext := pk_sysconfig.get_config('REPORT_IMAGE_EXAM_STATUS_EXT', i_prof);
        ELSE
            l_status_int := pk_sysconfig.get_config('REPORT_OTHER_EXAM_STATUS_INT', i_prof);
            l_status_ext := pk_sysconfig.get_config('REPORT_OTHER_EXAM_STATUS_EXT', i_prof);
        END IF;
    
        g_error := 'GET COUNT';
        l_sql   := 'SELECT COUNT(*) ' || --
                   '  FROM (SELECT erd.id_exam_req_det ' || --
                   '          FROM exam_req_det erd ' || --
                   '         WHERE erd.id_exam_req_det IN (SELECT t.column_value  ' || --
                   '                                         FROM TABLE(:i_exam_req_det) t) ' || --
                   '           AND erd.flg_status IN (' || l_status_int || ') ' || --
                   '           AND (erd.id_exec_institution IS NULL OR erd.id_exec_institution = ' ||
                   i_prof.institution || ') ' || --
                   '        UNION ' || --
                   '        SELECT erd.id_exam_req_det ' || --
                   '          FROM exam_req_det erd ' || --
                   '         WHERE erd.id_exam_req_det IN (SELECT t.column_value  ' || --
                   '                                         FROM TABLE(:i_exam_req_det) t) ' || --
                   '           AND erd.flg_status IN (' || l_status_ext || ') ' || --
                   '           AND (erd.id_exec_institution IS NOT NULL OR erd.id_exec_institution != ' ||
                   i_prof.institution || ')) ';
    
        g_error := 'GET EXECUTE IMMEDIATE COUNT';
        EXECUTE IMMEDIATE l_sql
            INTO l_count
            USING i_exam_req_det, i_exam_req_det;
    
        IF l_count != i_exam_req_det.count
        THEN
            RETURN table_varchar();
        ELSE
            RETURN i_exam_req_det;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_get_exam_to_print;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_exams_desc       VARCHAR2(1000 CHAR);
        l_task_status_desc VARCHAR2(1000 CHAR);
    
        l_desc CLOB;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_exam_req_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_DESCRIPTION';
        IF NOT pk_exam_external.get_exam_task_description(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_exam_req_det  => i_exam_req_det,
                                                          o_exams_desc       => l_exams_desc,
                                                          o_task_status_desc => l_task_status_desc,
                                                          o_error            => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_desc := CASE
                      WHEN l_exams_desc IS NOT NULL THEN
                       l_exams_desc
                      ELSE
                       NULL
                  END;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_description;

    FUNCTION get_exam_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_task_instructions VARCHAR2(1000 CHAR);
    
        l_instructions CLOB;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_exam_req_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_INSTRUCTIONS';
        IF NOT pk_exam_external.get_exam_task_instructions(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_task_request      => NULL,
                                                           i_task_request_det  => i_exam_req_det,
                                                           o_task_instructions => l_task_instructions,
                                                           o_error             => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_instructions := CASE
                              WHEN l_task_instructions IS NOT NULL THEN
                               to_clob(l_task_instructions)
                              ELSE
                               NULL
                          END;
    
        RETURN l_instructions;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_instructions;

    FUNCTION get_exam_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_cosign_action_order  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M146');
        l_msg_cosign_action_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M147');
        l_msg_action               sys_message.desc_message%TYPE;
    
    BEGIN
    
        SELECT CASE
                   WHEN erd.id_co_sign_order = i_co_sign_hist THEN
                    l_msg_cosign_action_order
                   WHEN erd.id_co_sign_cancel = i_co_sign_hist THEN
                    l_msg_cosign_action_cancel
                   ELSE
                    NULL
               END
          INTO l_msg_action
          FROM exam_req_det erd
         WHERE erd.id_exam_req_det = i_exam_req_det;
    
        RETURN l_msg_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_action_desc;

    FUNCTION get_exam_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_exam_req_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)
          INTO l_date
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_exam_req_det;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_date_to_order;

    PROCEDURE cdr_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_id_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_exam_utils.get_exam_id_content(i_lang => i_lang, i_prof => i_prof, i_exam => i_exam);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_id_content;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_content       IN VARCHAR2,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_exam exam.id_exam%TYPE;
    
        l_desc_mess pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT e.id_exam
          INTO l_exam
          FROM exam e
         WHERE e.id_content = i_content
           AND e.flg_available = pk_exam_constant.g_available;
    
        l_desc_mess := pk_exam_utils.get_alias_translation(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_code_exam     => 'EXAM.CODE_EXAM.' || l_exam,
                                                           i_dep_clin_serv => i_dep_clin_serv);
    
        RETURN l_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION check_exam_cdr
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam         IN VARCHAR2,
        i_date         IN exam_req.dt_begin_tstz%TYPE,
        o_exam_req_det OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam exam.id_exam%TYPE;
    
    BEGIN
    
        SELECT id_exam
          INTO l_exam
          FROM (SELECT e.id_exam, row_number() over(PARTITION BY e.id_content ORDER BY e.flg_available DESC) rn
                  FROM exam e
                 WHERE e.id_content = i_exam)
         WHERE rn = 1;
    
        SELECT eea.id_exam_req_det
          BULK COLLECT
          INTO o_exam_req_det
          FROM exams_ea eea
         WHERE eea.id_patient = i_patient
           AND eea.id_exam = l_exam
           AND (i_date IS NULL OR eea.dt_req >= i_date)
           AND eea.flg_status_det != pk_exam_constant.g_exam_cancel;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXAM_CDR',
                                              o_error);
            RETURN FALSE;
    END check_exam_cdr;

    PROCEDURE referral___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION update_exam_laterality
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exam_req_det   IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_laterality IN exam_req_det.flg_laterality%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_error := 'UPDATE EXAM_REQ_DET';
        ts_exam_req_det.upd(id_exam_req_det_in => i_exam_req_det,
                            flg_laterality_in  => i_flg_laterality,
                            flg_laterality_nin => FALSE,
                            rows_out           => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
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
                                              'UPDATE_EXAM_LATERALITY',
                                              o_error);
            RETURN FALSE;
    END update_exam_laterality;

    FUNCTION update_exam_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_exec_institution IN exam_req_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_error := 'UPDATE EXAM_REQ_DET';
        ts_exam_req_det.upd(id_exam_req_det_in     => i_exam_req_det,
                            id_exec_institution_in => i_exec_institution,
                            rows_out               => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
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
                                              'UPDATE_EXAM_INSTITUTION',
                                              o_error);
            RETURN FALSE;
    END update_exam_institution;

    FUNCTION update_exam_referral
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_referral IN exam_req_det.flg_referral%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_HISTORY';
        IF NOT pk_exam_core.set_exam_history(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_exam_req     => NULL,
                                             i_exam_req_det => table_number(i_exam_req_det),
                                             o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'UPDATE EXAM_REQ_DET';
        ts_exam_req_det.upd(id_exam_req_det_in => i_exam_req_det,
                            flg_referral_in    => i_flg_referral,
                            rows_out           => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
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
                                              'UPDATE_EXAM_REFERRAL',
                                              o_error);
            RETURN FALSE;
    END update_exam_referral;

    FUNCTION get_exam_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_exam_external.t_cur_exam_result,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        OPEN o_list FOR
            SELECT eea.id_exam_req_det,
                   eea.id_exam,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                   eea.desc_result RESULT,
                   pk_date_utils.date_char_tsz(i_lang, eea.dt_req, i_prof.institution, i_prof.software) dt_req
              FROM exams_ea eea, episode e
             WHERE e.id_visit = l_visit
               AND e.id_episode = eea.id_episode
               AND eea.flg_status_det IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read)
               AND eea.flg_time != pk_exam_constant.g_flg_time_r
            UNION ALL
            SELECT eea.id_exam_req_det,
                   eea.id_exam,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                   eea.desc_result RESULT,
                   pk_date_utils.date_char_tsz(i_lang, eea.dt_req, i_prof.institution, i_prof.software) dt_req
              FROM exams_ea eea, episode e
             WHERE e.id_visit = l_visit
               AND e.id_episode = eea.id_episode_origin
               AND eea.flg_status_det IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read)
               AND eea.flg_time != pk_exam_constant.g_flg_time_r;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_listview;

    PROCEDURE cpoe______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION copy_exam_to_draft
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
    
        l_exam_req     exam_req%ROWTYPE;
        l_exam_req_det exam_req_det%ROWTYPE;
    
        l_clinical_question       table_number;
        l_response                table_varchar;
        l_clinical_question_notes table_varchar;
    
        o_exam_req exam_req.id_exam_req%TYPE;
    
        l_dt_begin_tstz exam_req.dt_begin_tstz%TYPE;
    
        l_diagnosis      table_number := table_number();
        l_diagnosis_desc table_varchar := table_varchar();
    
        l_codification codification.id_codification%TYPE;
    
        CURSOR c_diagnosis_list(l_exam_req_det exam_req_det.id_exam_req_det%TYPE) IS
            SELECT mrd.id_diagnosis, ed.desc_epis_diagnosis desc_diagnosis
              FROM mcdt_req_diagnosis mrd, epis_diagnosis ed
             WHERE mrd.id_interv_presc_det = l_exam_req_det
               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
               AND mrd.id_epis_diagnosis = ed.id_epis_diagnosis;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
    BEGIN
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        SELECT *
          INTO l_exam_req_det
          FROM exam_req_det
         WHERE id_exam_req_det = i_task_request;
    
        SELECT *
          INTO l_exam_req
          FROM exam_req
         WHERE id_exam_req = l_exam_req_det.id_exam_req;
    
        BEGIN
            SELECT ic.id_codification
              INTO l_codification
              FROM exam_codification ic
             WHERE ic.id_exam_codification = l_exam_req_det.id_exam_codification;
        EXCEPTION
            WHEN no_data_found THEN
                l_codification := NULL;
        END;
    
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
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_dt_begin_tstz := i_task_start_timestamp;
        ELSIF pk_date_utils.trunc_insttimezone(i_prof, l_exam_req_det.dt_final_target_tstz) >
              pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
        THEN
            l_dt_begin_tstz := g_sysdate_tstz;
        END IF;
    
        IF NOT pk_exam_core.create_exam_request(i_lang                    => i_lang,
                                                i_prof                    => i_prof,
                                                i_patient                 => l_exam_req.id_patient,
                                                i_episode                 => i_episode,
                                                i_exam_req                => NULL,
                                                i_exam_req_det            => NULL,
                                                i_exam                    => l_exam_req_det.id_exam,
                                                i_exam_group              => l_exam_req_det.id_exam_group,
                                                i_dt_req                  => NULL,
                                                i_flg_time                => l_exam_req.flg_time,
                                                i_dt_begin                => pk_date_utils.date_send_tsz(i_lang,
                                                                                                         l_dt_begin_tstz,
                                                                                                         i_prof),
                                                i_dt_begin_limit          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                         l_exam_req_det.dt_final_target_tstz,
                                                                                                         i_prof),
                                                i_episode_destination     => l_exam_req.id_episode_destination,
                                                i_order_recurrence        => NULL,
                                                i_priority                => l_exam_req.priority,
                                                i_flg_prn                 => l_exam_req_det.flg_prn,
                                                i_notes_prn               => l_exam_req_det.prn_notes,
                                                i_flg_fasting             => l_exam_req_det.flg_fasting,
                                                i_notes                   => l_exam_req_det.notes,
                                                i_notes_scheduler         => l_exam_req_det.notes_scheduler,
                                                i_notes_technician        => l_exam_req_det.notes_tech,
                                                i_notes_patient           => l_exam_req_det.notes_patient,
                                                i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                                                                       i_prof      => i_prof,
                                                                                                       i_patient   => l_exam_req.id_patient,
                                                                                                       i_episode   => i_episode,
                                                                                                       i_diagnosis => l_diagnosis,
                                                                                                       i_desc_diag => l_diagnosis_desc),
                                                i_laterality              => l_exam_req_det.flg_laterality,
                                                i_exec_room               => l_exam_req_det.id_room,
                                                i_exec_institution        => l_exam_req_det.id_exec_institution,
                                                i_clinical_purpose        => l_exam_req_det.id_clinical_purpose,
                                                i_clinical_purpose_notes  => l_exam_req_det.clinical_purpose_notes,
                                                i_codification            => l_codification,
                                                i_health_plan             => l_exam_req_det.id_pat_health_plan,
                                                i_exemption               => l_exam_req_det.id_pat_exemption,
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
                                                o_exam_req                => o_exam_req,
                                                o_exam_req_det            => o_draft,
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
            l_sys_alert_event.id_patient      := l_exam_req.id_patient;
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
                                              'COPY_EXAM_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_exam_to_draft;

    FUNCTION check_exam_mandatory_field
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_exams_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_type exam.flg_type%TYPE;
    
        l_clinical_indication sys_config.value%TYPE;
        l_clinical_purpose    sys_config.value%TYPE;
        l_laterality          sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY',
                                                                               i_prof);
        l_notes_tech          sys_config.value%TYPE;
    
        l_flg_prof_need_cosign VARCHAR(1 CHAR);
    
        l_check VARCHAR(1 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Fetch instructions for id_exam_req_det: ' || i_id_exams_req_det;
        SELECT e.flg_type
          INTO l_flg_type
          FROM exam_req er, exam_req_det erd, exam e
         WHERE erd.id_exam_req_det = i_id_exams_req_det
           AND er.id_exam_req = erd.id_exam_req
           AND erd.id_exam = e.id_exam;
    
        IF l_flg_type = pk_exam_constant.g_type_img
        THEN
            l_clinical_indication := pk_sysconfig.get_config('IMG_CLINICAL_INDICATION_MANDATORY', i_prof);
            l_clinical_purpose    := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_I', i_prof);
            l_notes_tech          := pk_sysconfig.get_config('IMG_NOTES_TECH_MANDATORY', i_prof);
        ELSE
            l_clinical_indication := pk_sysconfig.get_config('EXM_CLINICAL_INDICATION_MANDATORY', i_prof);
            l_clinical_purpose    := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_E', i_prof);
            l_notes_tech          := pk_sysconfig.get_config('EXM_NOTES_TECH_MANDATORY', i_prof);
        END IF;
    
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
    
        IF l_clinical_indication = pk_exam_constant.g_yes
        THEN
            BEGIN
                SELECT pk_exam_constant.g_yes
                  INTO l_check
                  FROM mcdt_req_diagnosis mrd
                 WHERE mrd.id_exam_req_det = i_id_exams_req_det
                   AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_exam_constant.g_no;
            END;
        END IF;
    
        IF l_clinical_purpose = pk_exam_constant.g_yes
        THEN
            BEGIN
                SELECT pk_exam_constant.g_yes
                  INTO l_check
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req_det = i_id_exams_req_det
                   AND erd.id_clinical_purpose IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_exam_constant.g_no;
            END;
        END IF;
    
        IF l_laterality = pk_exam_constant.g_yes
        THEN
            BEGIN
                SELECT pk_exam_constant.g_yes
                  INTO l_check
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req_det = i_id_exams_req_det
                   AND erd.flg_laterality IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_exam_constant.g_no;
            END;
        END IF;
    
        IF l_flg_prof_need_cosign = pk_exam_constant.g_yes
        THEN
            BEGIN
                SELECT pk_exam_constant.g_yes
                  INTO l_check
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req_det = i_id_exams_req_det
                   AND erd.id_co_sign_order IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN pk_exam_constant.g_no;
            END;
        END IF;
    
        g_error := 'Fetch instructions for i_exam_req: ' || i_id_exams_req_det;
        SELECT decode(er.priority,
                      NULL,
                      pk_exam_constant.g_no,
                      decode(er.flg_time,
                             NULL,
                             pk_exam_constant.g_no,
                             decode(l_notes_tech,
                                    pk_exam_constant.g_yes,
                                    decode(erd.notes_tech, NULL, pk_exam_constant.g_no, pk_exam_constant.g_yes),
                                    pk_exam_constant.g_yes)))
          INTO l_check
          FROM exam_req er, exam_req_det erd
         WHERE erd.id_exam_req_det = i_id_exams_req_det
           AND er.id_exam_req = erd.id_exam_req;
    
        -- check if there's no req dets with mandatory fields empty
        IF l_check = pk_exam_constant.g_no
        THEN
            RETURN pk_exam_constant.g_no;
        END IF;
    
        -- all mandatory fields have a value
    
        RETURN pk_exam_constant.g_yes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXAM_MANDATORY_FIELD',
                                              l_error);
            RETURN pk_exam_constant.g_no;
    END check_exam_mandatory_field;

    FUNCTION check_exam_draft_conflict
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
    
        l_patient      patient.id_patient%TYPE;
        l_flg_conflict table_varchar := table_varchar();
        l_msg_title    table_varchar := table_varchar();
        l_msg_body     table_varchar := table_varchar();
        l_msg_template table_varchar := table_varchar();
        l_exams        table_number;
        l_dt_begin     table_timestamp_tz;
    
        l_tmp_msg_title VARCHAR2(4000);
        l_tmp_msg_text  VARCHAR2(4000);
        l_button        VARCHAR2(4000);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error   := 'GET ID_PATIENT';
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        SELECT erd.id_exam, erd.dt_target_tstz
          BULK COLLECT
          INTO l_exams, l_dt_begin
          FROM exam_req_det erd
         WHERE erd.id_exam_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(i_draft) t);
    
        g_error := 'CHECK FOR CONFLICTS';
    
        l_flg_conflict.extend;
        l_flg_conflict(l_flg_conflict.count) := pk_exam_utils.get_exam_request(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_patient   => l_patient,
                                                                               i_exam      => l_exams,
                                                                               o_msg_title => l_tmp_msg_title,
                                                                               o_msg_req   => l_tmp_msg_text,
                                                                               o_button    => l_button);
    
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
                                              'CHECK_EXAM_DRAFT_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_exam_draft_conflict;

    FUNCTION check_exam_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM exam_req er
         WHERE er.id_episode_destination = i_episode
           AND er.flg_status = pk_exam_constant.g_exam_draft;
    
        IF l_count > 0
        THEN
            o_has_draft := pk_exam_constant.g_yes;
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
                                              'CHECK_EXAM_DRAFT',
                                              o_error);
            RETURN FALSE;
    END check_exam_draft;

    FUNCTION set_exam_draft_activation
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
    
        CURSOR c_exam_draft IS
            SELECT er.id_exam_req,
                   erd.id_exam_req_det,
                   er.id_episode,
                   e.flg_type,
                   decode(pk_date_utils.compare_dates_tsz(i_prof, erd.dt_target_tstz, g_sysdate_tstz),
                          pk_alert_constant.g_date_lower,
                          g_sysdate_tstz,
                          erd.dt_target_tstz) dt_begin,
                   er.flg_time,
                   erd.flg_prn,
                   erd.id_exec_institution,
                   erd.id_co_sign_order
              FROM exam_req_det erd
              JOIN exam_req er
                ON er.id_exam_req = erd.id_exam_req
              JOIN exam e
                ON e.id_exam = erd.id_exam
             WHERE erd.id_exam_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            *
                                             FROM TABLE(i_draft) t);
    
        l_status       exam_req.flg_status%TYPE;
        l_status_det   exam_req_det.flg_status%TYPE;
        l_dt_begin     exam_req.dt_begin_tstz%TYPE;
        l_dt_schedule  exam_req.dt_schedule_tstz%TYPE;
        l_flg_location exam_req_det.flg_location%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_created_tasks := i_draft;
    
        FOR rec IN c_exam_draft
        LOOP
            g_error := 'GET STATUS';
            IF rec.flg_time != pk_exam_constant.g_flg_time_e
            THEN
                -- realização futura
                l_status     := pk_exam_constant.g_exam_pending;
                l_status_det := pk_exam_constant.g_exam_pending;
                l_dt_begin   := NULL;
            
                IF rec.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                THEN
                    IF (i_prof.software != pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof) OR
                       (i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof) AND
                       pk_sysconfig.get_config('INSTIT_SCHEDULER_EXISTS', i_prof) = 'N'))
                    THEN
                        -- realização entre consultas
                        l_status     := pk_exam_constant.g_exam_tosched;
                        l_status_det := pk_exam_constant.g_exam_tosched;
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
                        l_status     := pk_exam_constant.g_exam_tosched;
                        l_status_det := pk_exam_constant.g_exam_tosched;
                        l_dt_begin   := NULL;
                    END IF;
                END IF;
            ELSE
                -- realização neste epis.
                IF rec.id_episode IS NOT NULL
                THEN
                    IF pk_sysconfig.get_config('REQ_NEXT_DAY', i_prof) = pk_exam_constant.g_no
                    THEN
                        IF pk_date_utils.trunc_insttimezone(i_prof, nvl(l_dt_begin, g_sysdate_tstz), 'DD') !=
                           pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'DD')
                        THEN
                            g_error_code := 'EXAM_M010';
                            g_error      := pk_message.get_message(i_lang, 'EXAM_M010');
                            RAISE g_user_exception;
                        END IF;
                    END IF;
                END IF;
            
                l_dt_begin := rec.dt_begin;
            
                IF nvl(l_dt_begin, g_sysdate_tstz) > g_sysdate_tstz
                THEN
                    -- pendente
                    l_status     := pk_exam_constant.g_exam_pending;
                    l_status_det := pk_exam_constant.g_exam_pending;
                ELSE
                    l_dt_begin   := g_sysdate_tstz;
                    l_status     := pk_exam_constant.g_exam_req;
                    l_status_det := pk_exam_constant.g_exam_req;
                END IF;
            END IF;
        
            IF rec.id_exec_institution IS NOT NULL
            THEN
                IF rec.id_exec_institution != i_prof.institution
                THEN
                    l_status     := pk_exam_constant.g_exam_exterior;
                    l_status_det := pk_exam_constant.g_exam_exterior;
                
                    l_flg_location := pk_exam_constant.g_exam_location_exterior;
                ELSE
                    IF rec.flg_prn = pk_exam_constant.g_yes
                    THEN
                        l_status     := pk_exam_constant.g_exam_sos;
                        l_status_det := pk_exam_constant.g_exam_sos;
                    END IF;
                
                    l_flg_location := pk_exam_constant.g_exam_location_interior;
                END IF;
            ELSE
                IF rec.flg_time != pk_exam_constant.g_flg_time_r
                THEN
                    IF rec.flg_prn = pk_exam_constant.g_yes
                    THEN
                        l_status     := pk_exam_constant.g_exam_sos;
                        l_status_det := pk_exam_constant.g_exam_sos;
                    END IF;
                
                    l_flg_location := pk_exam_constant.g_exam_location_interior;
                ELSE
                    l_flg_location := pk_exam_constant.g_exam_location_exterior;
                END IF;
            END IF;
        
            g_error := 'UPDATE EXAM_REQ';
            ts_exam_req.upd(id_exam_req_in         => rec.id_exam_req,
                            flg_status_in          => l_status,
                            dt_begin_tstz_in       => l_dt_begin,
                            dt_schedule_tstz_in    => l_dt_schedule,
                            id_prof_last_update_in => i_prof.id,
                            dt_last_update_tstz_in => g_sysdate_tstz,
                            rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE EXAM_REQ_DET';
            ts_exam_req_det.upd(id_exam_req_det_in     => rec.id_exam_req_det,
                                flg_status_in          => l_status_det,
                                dt_target_tstz_in      => l_dt_begin,
                                id_prof_last_update_in => i_prof.id,
                                dt_last_update_tstz_in => g_sysdate_tstz,
                                rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM_REQ_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'CALL PK_CPOE.SYNC_TASK';
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                i_prof                 => i_prof,
                                i_episode              => i_episode,
                                i_task_type            => CASE
                                                              WHEN rec.flg_type = pk_exam_constant.g_type_img THEN
                                                               pk_alert_constant.g_task_type_image_exam
                                                              ELSE
                                                               pk_alert_constant.g_task_type_other_exam
                                                          END,
                                i_task_request         => rec.id_exam_req_det,
                                i_task_start_timestamp => rec.dt_begin,
                                o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END LOOP;
    
        IF i_flg_commit = pk_exam_constant.g_yes
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
                                              'SET_EXAM_DRAFT_ACTIVATION',
                                              o_error);
            RETURN FALSE;
    END set_exam_draft_activation;

    FUNCTION cancel_exam_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_exam_req    exam_req.id_exam_req%TYPE;
        l_count_exam_req NUMBER;
    
    BEGIN
    
        FOR i IN 1 .. i_draft.count
        LOOP
            BEGIN
                SELECT id_exam_req
                  INTO l_id_exam_req
                  FROM exam_req_det
                 WHERE id_exam_req_det = i_draft(i);
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE g_other_exception;
            END;
        
            -- delete co_sign
            DELETE FROM co_sign
             WHERE id_task = l_id_exam_req;
        
            -- delete exam_grid_task        
            DELETE FROM grid_task_img
             WHERE id_exam_req_det = i_draft(i);
        
            DELETE FROM grid_task_oth_exm
             WHERE id_exam_req_det = i_draft(i);
        
            -- delete icnp_suggest_interv
            DELETE FROM icnp_suggest_interv
             WHERE id_req = l_id_exam_req;
        
            -- delete exam_question_response
            DELETE FROM exam_question_response
             WHERE id_exam_req_det = i_draft(i);
        
            -- delete exams_ea
            DELETE FROM exams_ea
             WHERE id_exam_req_det = i_draft(i);
        
            -- delete exam_req_det
            DELETE FROM exam_req_det
             WHERE id_exam_req_det = i_draft(i);
        
            -- delete exam_req
        
            SELECT COUNT(*)
              INTO l_count_exam_req
              FROM exam_req_det
             WHERE id_exam_req_det = i_draft(i);
        
            IF l_count_exam_req = 0
            THEN
                DELETE FROM exam_req
                 WHERE id_exam_req = l_id_exam_req;
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
    END cancel_exam_draft;

    FUNCTION cancel_exam_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_drafts table_number;
    
    BEGIN
    
        g_error := 'Get episode''s draft tasks';
        SELECT pea.id_exam_req_det
          BULK COLLECT
          INTO l_drafts
          FROM exams_ea pea
         WHERE pea.id_episode IN (SELECT id_episode
                                    FROM episode
                                   WHERE id_visit = pk_episode.get_id_visit(i_episode))
           AND pea.flg_status_det = pk_exam_constant.g_exam_draft;
    
        IF l_drafts IS NOT NULL
           AND l_drafts.count > 0
        THEN
            IF NOT pk_exam_external.cancel_exam_draft(i_lang    => i_lang,
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
                                              'CANCEL_EXAM_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_all_drafts;

    FUNCTION get_exam_task_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_type        IN VARCHAR2,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        i_cpoe_tab        IN VARCHAR2 DEFAULT 'A',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
    
        OPEN o_task_list FOR
            WITH tcs_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    decode(i_flg_type,
                                                                           pk_exam_constant.g_type_img,
                                                                           pk_alert_constant.g_task_imaging_exams,
                                                                           pk_alert_constant.g_task_other_exams))))
            SELECT task_type,
                   t_ti_log.get_desc_with_origin(i_lang,
                                                 i_prof,
                                                 task_description,
                                                 pk_episode.get_epis_type(i_lang, i_episode),
                                                 flg_status,
                                                 id_request,
                                                 pk_exam_constant.g_exam_type_req) AS task_description,
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
                   pk_alert_constant.g_task_imaging_exams AS id_task_type_source,
                   id_task_dependency AS id_task_dependency,
                   decode(flg_status, pk_exam_constant.g_exam_cancel, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_rep_cancel,
                   flg_prn flg_prn_conditional
              FROM (SELECT pk_alert_constant.g_task_type_image_exam task_type,
                           pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) task_description,
                           erd.id_prof_last_update id_professional,
                           NULL icon_warning,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      eea.status_str,
                                                      eea.status_msg,
                                                      eea.status_icon,
                                                      eea.status_flg) status_string,
                           eea.id_exam_req_det id_request,
                           nvl(eea.dt_begin, eea.dt_req) start_date_tstz,
                           NULL end_date_tstz,
                           erd.dt_last_update_tstz AS create_date_tstz,
                           eea.flg_status_det flg_status,
                           pk_exam_utils.get_exam_permission(i_lang,
                                                             i_prof,
                                                             pk_exam_constant.g_exam_area_exams,
                                                             pk_exam_constant.g_exam_button_cancel,
                                                             nvl(eea.id_episode, eea.id_episode_origin),
                                                             NULL,
                                                             eea.id_exam_req_det,
                                                             decode(eea.id_episode,
                                                                    i_episode,
                                                                    pk_exam_constant.g_yes,
                                                                    pk_exam_constant.g_no)) flg_cancel,
                           CASE
                                WHEN (eea.flg_status_det = pk_exam_constant.g_exam_draft AND pk_exam_external.check_exam_mandatory_field(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         i_episode,
                                                                                                                                         eea.id_exam_req_det) =
                                     pk_alert_constant.g_no) THEN
                                 pk_alert_constant.g_yes
                                WHEN (eea.flg_status_det = pk_exam_constant.g_exam_draft AND
                                     erd.dt_final_target_tstz IS NOT NULL) THEN
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, erd.dt_final_target_tstz, g_sysdate_tstz),
                                        pk_alert_constant.g_date_lower,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_no)
                                ELSE
                                 pk_alert_constant.g_no
                            END AS flg_conflict,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  pk_exams_api_db.get_alias_translation(i_lang,
                                                                        i_prof,
                                                                        'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                        NULL)) task_title,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  decode(erd.flg_prn,
                                         pk_alert_constant.g_yes,
                                         pk_message.get_message(i_lang, 'COMMON_M112'),
                                         nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                                   i_prof,
                                                                                                   erd.id_order_recurrence),
                                             pk_translation.get_translation(i_lang,
                                                                            'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')))) task_instructions,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  decode(erd.notes_cancel,
                                         NULL,
                                         decode(erd.flg_prn,
                                                pk_alert_constant.g_yes,
                                                pk_string_utils.clob_to_varchar2(erd.prn_notes, 1000),
                                                erd.notes_tech),
                                         erd.notes_cancel)) task_notes,
                           NULL drug_dose,
                           NULL drug_route,
                           NULL drug_take_in_case,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  pk_sysdomain.get_domain(i_lang,
                                                          i_prof,
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          eea.flg_status_det,
                                                          NULL)) task_status,
                           nvl(eea.dt_req, eea.dt_begin) TIMESTAMP,
                           decode(eea.flg_status_det,
                                  pk_exam_constant.g_exam_req,
                                  row_number() over(ORDER BY decode(eea.flg_referral,
                                              NULL,
                                              (SELECT pk_sysdomain.get_rank(i_lang,
                                                                            'EXAM_REQ_DET.FLG_STATUS',
                                                                            eea.flg_status_det)
                                                 FROM dual),
                                              (SELECT pk_sysdomain.get_rank(i_lang,
                                                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                                                            eea.flg_referral)
                                                 FROM dual)),
                                       coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                                  pk_exam_constant.g_exam_pending,
                                  row_number() over(ORDER BY decode(eea.flg_referral,
                                              NULL,
                                              (SELECT pk_sysdomain.get_rank(i_lang,
                                                                            'EXAM_REQ_DET.FLG_STATUS',
                                                                            eea.flg_status_det)
                                                 FROM dual),
                                              (SELECT pk_sysdomain.get_rank(i_lang,
                                                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                                                            eea.flg_referral)
                                                 FROM dual)),
                                       coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                                  row_number() over(ORDER BY decode(eea.flg_referral,
                                              NULL,
                                              (SELECT pk_sysdomain.get_rank(i_lang,
                                                                            'EXAM_REQ_DET.FLG_STATUS',
                                                                            eea.flg_status_det)
                                                 FROM dual),
                                              (SELECT pk_sysdomain.get_rank(i_lang,
                                                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                                                            eea.flg_referral)
                                                 FROM dual)),
                                       coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)) rank,
                           nvl(eea.id_episode, eea.id_episode_origin) AS id_episode,
                           eea.id_exam id_task,
                           erd.id_task_dependency,
                           erd.flg_prn
                      FROM exams_ea eea
                      JOIN exam_req_det erd
                        ON erd.id_exam_req_det = eea.id_exam_req_det
                      LEFT JOIN tcs_table tcs
                        ON erd.id_co_sign_order = tcs.id_co_sign_hist
                     WHERE eea.id_patient = i_patient
                       AND eea.flg_type = i_flg_type
                       AND (eea.id_episode IN (SELECT id_episode
                                                 FROM episode
                                                WHERE id_visit = pk_episode.get_id_visit(i_episode)) OR
                           eea.id_episode_origin IN
                           (SELECT id_episode
                               FROM episode
                              WHERE id_visit = pk_episode.get_id_visit(i_episode)))
                       AND ((i_flg_report = pk_alert_constant.g_yes AND
                           eea.flg_status_req != pk_exam_constant.g_exam_exterior) OR
                           i_flg_report = pk_alert_constant.g_no)
                       AND ((i_flg_out_of_cpoe = pk_alert_constant.g_yes AND i_flg_print_items = pk_alert_constant.g_no AND
                           ((erd.flg_status IN (pk_exam_constant.g_exam_pending, pk_exam_constant.g_exam_req) OR
                           (erd.flg_status NOT IN (pk_exam_constant.g_exam_pending, pk_exam_constant.g_exam_req) AND
                           coalesce(eea.dt_result, erd.dt_final_target_tstz) BETWEEN i_dt_begin AND i_dt_end)))) OR
                           (i_task_request IS NULL OR
                           (eea.id_exam_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_task_request) t))) AND
                           (eea.flg_status_det NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                         column_value
                                                          FROM TABLE(i_filter_status) t) OR
                           ((erd.flg_status NOT IN (pk_exam_constant.g_exam_normal, pk_exam_constant.g_exam_cancel) AND
                           coalesce(eea.dt_result, erd.dt_final_target_tstz) >= i_filter_tstz) OR
                           (erd.flg_status = pk_exam_constant.g_exam_normal AND erd.dt_target_tstz >= i_filter_tstz) OR
                           (erd.flg_status = pk_exam_constant.g_exam_cancel AND
                           erd.dt_cancel_tstz >= l_cancelled_task_filter_tstz)))))
             ORDER BY rank;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_flg_type      => i_flg_type,
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
                                              'GET_EXAM_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_exam_task_list;

    FUNCTION get_exam_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status          exam_req_det.flg_status%TYPE;
        l_button_cancel       VARCHAR(1 CHAR);
        l_button_confirmation VARCHAR(1 CHAR);
        l_button_edit         VARCHAR(1 CHAR);
        l_button_ok           VARCHAR(1 CHAR);
        l_button_read         VARCHAR(1 CHAR);
    
    BEGIN
    
        g_error := 'GET EXAMS_EA';
        SELECT decode(eea.flg_referral,
                      pk_exam_constant.g_flg_referral_r,
                      pk_exam_constant.g_exam_cancel,
                      pk_exam_constant.g_flg_referral_s,
                      pk_exam_constant.g_exam_cancel,
                      pk_exam_constant.g_flg_referral_i,
                      pk_exam_constant.g_exam_cancel,
                      eea.flg_status_det) flg_status,
               pk_exam_utils.get_exam_permission(i_lang,
                                                 i_prof,
                                                 pk_exam_constant.g_exam_area_exams,
                                                 pk_exam_constant.g_exam_button_ok,
                                                 eea.id_episode,
                                                 NULL,
                                                 eea.id_exam_req_det,
                                                 decode(eea.id_episode,
                                                        i_episode,
                                                        pk_exam_constant.g_yes,
                                                        pk_exam_constant.g_no)) avail_button_ok,
               pk_exam_utils.get_exam_permission(i_lang,
                                                 i_prof,
                                                 pk_exam_constant.g_exam_area_exams,
                                                 pk_exam_constant.g_exam_button_cancel,
                                                 eea.id_episode,
                                                 NULL,
                                                 eea.id_exam_req_det,
                                                 decode(eea.id_episode,
                                                        i_episode,
                                                        pk_exam_constant.g_yes,
                                                        pk_exam_constant.g_no)) avail_button_cancel,
               pk_exam_utils.get_exam_permission(i_lang,
                                                 i_prof,
                                                 pk_exam_constant.g_exam_area_exams,
                                                 pk_exam_constant.g_exam_button_edit,
                                                 eea.id_episode,
                                                 NULL,
                                                 eea.id_exam_req_det,
                                                 decode(eea.id_episode,
                                                        i_episode,
                                                        pk_exam_constant.g_yes,
                                                        pk_exam_constant.g_no)) avail_button_edit,
               pk_exam_utils.get_exam_permission(i_lang,
                                                 i_prof,
                                                 pk_exam_constant.g_exam_area_exams,
                                                 pk_exam_constant.g_exam_button_confirmation,
                                                 eea.id_episode,
                                                 NULL,
                                                 eea.id_exam_req_det,
                                                 decode(eea.id_episode,
                                                        i_episode,
                                                        pk_exam_constant.g_yes,
                                                        pk_exam_constant.g_no)) avail_button_confirmation,
               pk_exam_utils.get_exam_permission(i_lang,
                                                 i_prof,
                                                 pk_exam_constant.g_exam_area_exams,
                                                 pk_exam_constant.g_exam_button_read,
                                                 eea.id_episode,
                                                 NULL,
                                                 eea.id_exam_req_det,
                                                 decode(eea.id_episode,
                                                        i_episode,
                                                        pk_exam_constant.g_yes,
                                                        pk_exam_constant.g_no)) avail_button_read
          INTO l_flg_status, l_button_ok, l_button_cancel, l_button_edit, l_button_confirmation, l_button_read
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_task_request;
    
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
                          pk_exam_constant.g_active,
                          decode(a.action,
                                 'EDIT',
                                 decode(l_button_edit,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_active,
                                        pk_exam_constant.g_inactive),
                                 'CONFIRM_REQ',
                                 decode(l_button_confirmation,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_active,
                                        pk_exam_constant.g_inactive),
                                 'PERFORM',
                                 decode(l_button_ok,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_active,
                                        pk_exam_constant.g_inactive),
                                 'INS_RESULT',
                                 decode(l_button_ok,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_active,
                                        pk_exam_constant.g_inactive),
                                 'MARK_AS_READ',
                                 decode(l_button_read,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_active,
                                        pk_exam_constant.g_inactive),
                                 'CANCEL',
                                 decode(l_button_cancel,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_active,
                                        pk_exam_constant.g_inactive),
                                 a.flg_active),
                          a.flg_active) flg_status,
                   a.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'EXAMS_CPOE', l_flg_status)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_action);
            RETURN FALSE;
    END get_exam_actions;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_flg_type      IN VARCHAR2,
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
            SELECT erd.id_exam_req_det id_prescription,
                   decode(erd.flg_prn,
                          pk_alert_constant.g_yes,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, er.dt_begin, i_prof)) planned_date,
                   pk_date_utils.date_send_tsz(i_lang, erd.start_time, i_prof) exec_date,
                   pk_string_utils.clob_to_varchar2(ed.notes, 1000) exec_notes,
                   'N' out_of_period
              FROM exams_ea er
             INNER JOIN exam_req_det erd
                ON erd.id_exam_req = er.id_exam_req
              LEFT JOIN epis_documentation ed
                ON ed.id_epis_documentation = erd.id_epis_doc_perform
             WHERE nvl(er.id_episode, er.id_episode_origin) = i_episode
               AND er.dt_begin BETWEEN l_cp_begin AND l_cp_end
               AND er.flg_type = i_flg_type
               AND er.flg_status_req NOT IN (pk_exam_constant.g_exam_draft, pk_exam_constant.g_exam_cancel);
    
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

    FUNCTION get_exam_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_exam_req_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_exam_req_det FOR
            SELECT /*+opt_estimate(table req rows=1)*/
             d.id_exam_req, d.id_exam_req_det
              FROM exam_req_det d
              JOIN TABLE(i_task_request) req
                ON d.id_exam_req = req.column_value;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_REQ_DET',
                                              o_error);
            RETURN FALSE;
    END get_exam_req_det;

    FUNCTION get_exam_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN exam_req.id_exam_req%TYPE,
        i_task_request_det IN exam_req_det.id_exam_req_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch alias_translation for id_exam_req: ' || i_task_request;
        BEGIN
            SELECT decode(er.id_exam_group,
                          NULL,
                          substr(concatenate(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                   i_prof,
                                                                                   'EXAM.CODE_EXAM.' || erd.id_exam,
                                                                                   NULL) || '; '),
                                 1,
                                 length(concatenate(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                          i_prof,
                                                                                          'EXAM.CODE_EXAM.' || erd.id_exam,
                                                                                          NULL) || '; ')) - 2),
                          pk_translation.get_translation(i_lang, 'EXAM_GROUP.CODE_EXAM_GROUP.' || er.id_exam_group))
              INTO o_task_desc
              FROM exam_req_det erd, exam_req er
             WHERE ((erd.id_exam_req = i_task_request AND i_task_request_det IS NULL) OR
                   (erd.id_exam_req_det = i_task_request_det AND i_task_request IS NULL))
               AND erd.id_exam_req = er.id_exam_req
             GROUP BY er.id_exam_group;
        
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
                                              'GET_EXAM_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_title;

    FUNCTION get_exam_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN exam_req.id_exam_req%TYPE,
        i_task_request_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER := 0;
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('EXAMS_T033',
                                                        'EXAMS_T034',
                                                        'EXAMS_T164',
                                                        'EXAMS_T159',
                                                        'EXAMS_T167',
                                                        'EXAMS_T053');
    
        l_msg_date sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAM_REQ_M002');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i)) || ' ';
        END LOOP;
    
        SELECT COUNT(erd.id_exam_req_det)
          INTO l_count
          FROM exam_req_det erd, exam_req er
         WHERE ((erd.id_exam_req = i_task_request AND i_task_request_det IS NULL) OR
               (erd.id_exam_req_det = i_task_request_det AND i_task_request IS NULL))
           AND erd.id_exam_req = er.id_exam_req;
    
        g_error := 'Fetch instructions for id_exam_req: ' || i_task_request;
        BEGIN
            SELECT DISTINCT decode(erd.flg_priority,
                                   NULL,
                                   NULL,
                                   aa_code_messages('EXAMS_T033') ||
                                   pk_sysdomain.get_domain(i_lang,
                                                           i_prof,
                                                           'EXAM_REQ_DET.FLG_PRIORITY',
                                                           erd.flg_priority,
                                                           NULL) || '; ') ||
                            decode(i_flg_showdate,
                                   pk_alert_constant.g_yes,
                                   aa_code_messages('EXAMS_T034') ||
                                   decode(er.flg_time,
                                          pk_exam_constant.g_flg_time_e,
                                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', er.flg_time, NULL) ||
                                          decode(er.dt_begin_tstz,
                                                 NULL,
                                                 decode(er.dt_schedule_tstz,
                                                        NULL,
                                                        '',
                                                        ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                            er.dt_schedule_tstz,
                                                                                            i_prof.institution,
                                                                                            i_prof.software) || l_msg_date || ')'),
                                                 ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                     er.dt_begin_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || ')'),
                                          pk_exam_constant.g_flg_time_b,
                                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', er.flg_time, NULL) ||
                                          decode(er.dt_begin_tstz,
                                                 NULL,
                                                 decode(er.dt_schedule_tstz,
                                                        NULL,
                                                        '',
                                                        '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                            er.dt_schedule_tstz,
                                                                                            i_prof.institution,
                                                                                            i_prof.software) || ' ' ||
                                                        l_msg_date),
                                                 ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                     er.dt_begin_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || ')'),
                                          pk_exam_constant.g_flg_time_d,
                                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', er.flg_time, NULL) ||
                                          decode(er.dt_begin_tstz,
                                                 NULL,
                                                 decode(er.dt_schedule_tstz,
                                                        NULL,
                                                        '',
                                                        '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                            er.dt_schedule_tstz,
                                                                                            i_prof.institution,
                                                                                            i_prof.software) || ' ' ||
                                                        l_msg_date),
                                                 ' (' || pk_date_utils.date_char_tsz(i_lang,
                                                                                     er.dt_begin_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software) || ')'),
                                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', er.flg_time, NULL)) || '; ') ||
                            decode(erd.id_order_recurrence,
                                   NULL,
                                   NULL,
                                   aa_code_messages('EXAMS_T159') ||
                                   pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                         i_prof,
                                                                                         erd.id_order_recurrence,
                                                                                         pk_alert_constant.g_no) || '; ') ||
                            decode(erd.flg_prn,
                                   NULL,
                                   NULL,
                                   aa_code_messages('EXAMS_T164') ||
                                   pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_PRN', erd.flg_prn, i_lang) || '; ') ||
                            decode(erd.flg_fasting,
                                   NULL,
                                   NULL,
                                   aa_code_messages('EXAMS_T167') ||
                                   pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_FASTING', erd.flg_fasting, i_lang) || '; ') ||
                            decode(l_count,
                                   1,
                                   decode(erd.flg_location,
                                          NULL,
                                          NULL,
                                          decode(erd.flg_location,
                                                 pk_exam_constant.g_exam_location_interior,
                                                 decode(erd.id_room,
                                                        NULL,
                                                        aa_code_messages('EXAMS_T053') ||
                                                        pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LOCATION',
                                                                                erd.flg_location,
                                                                                i_lang),
                                                        aa_code_messages('EXAMS_T053') ||
                                                        pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LOCATION',
                                                                                erd.flg_location,
                                                                                i_lang) || ' - ' ||
                                                        nvl((SELECT r.desc_room
                                                              FROM room r
                                                             WHERE r.id_room = erd.id_room),
                                                            pk_translation.get_translation(i_lang,
                                                                                           'ROOM.CODE_ROOM.' || erd.id_room))),
                                                 decode(erd.id_exec_institution,
                                                        NULL,
                                                        aa_code_messages('EXAMS_T053') ||
                                                        pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LOCATION',
                                                                                erd.flg_location,
                                                                                i_lang),
                                                        aa_code_messages('EXAMS_T053') ||
                                                        pk_translation.get_translation(i_lang,
                                                                                       'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                                       erd.id_exec_institution)))),
                                   NULL) instructions
              INTO o_task_instructions
              FROM exam_req_det erd, exam_req er
             WHERE ((erd.id_exam_req = i_task_request AND i_task_request_det IS NULL) OR
                   (erd.id_exam_req_det = i_task_request_det AND i_task_request IS NULL))
               AND erd.id_exam_req = er.id_exam_req;
        
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
                                              'GET_EXAM_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_instructions;

    FUNCTION get_exam_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        o_exams_desc       OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch pk_exams_api_db.get_alias_translation for i_id_exam_req_det: ' || i_id_exam_req_det;
        SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL),
               pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det, NULL)
          INTO o_exams_desc, o_task_status_desc
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_id_exam_req_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_EXAMS_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_description;

    FUNCTION get_exam_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET STATUS';
        SELECT eea.flg_status_det flg_status,
               pk_utils.get_status_string(i_lang,
                                          i_prof,
                                          eea.status_str,
                                          eea.status_msg,
                                          eea.status_icon,
                                          eea.status_flg) status_string
          INTO o_flg_status, o_status_string
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_task_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_exam_status;

    FUNCTION get_exam_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_exam  exam.id_exam%TYPE;
        l_flg_type VARCHAR2(1 CHAR);
    BEGIN
    
        g_error := 'GET PREDEFINED EXAM INFO';
        SELECT coalesce(er.id_exam_group, erd.id_exam) AS id_exam, nvl2(er.id_exam_group, 'G', 'E') AS flg_type
          INTO l_id_exam, l_flg_type
          FROM exam_req er, exam_req_det erd
         WHERE er.id_exam_req = i_task_request
           AND er.id_exam_req = erd.id_exam_req
           AND rownum = 1;
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_QUESTIONNAIRE';
        IF NOT pk_exam_core.get_exam_questionnaire(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_patient  => i_patient,
                                                   i_episode  => i_episode,
                                                   i_exam     => l_id_exam,
                                                   i_flg_type => l_flg_type,
                                                   i_flg_time => pk_exam_constant.g_exam_cq_on_order,
                                                   o_list     => o_list,
                                                   o_error    => o_error)
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
                                              'GET_EXAM_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_questionnaire;

    FUNCTION get_exam_date_limits
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
            SELECT er.id_exam_req, er.dt_begin_tstz, NULL dt_end
              FROM exam_req er
             WHERE er.id_exam_req IN (SELECT /*+opt_estimate(table t rows=1)*/
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
                                              'GET_EXAM_DATE_LIMITS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_date_limits;

    FUNCTION get_exam_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN exam_req.id_exam_req%TYPE,
        i_task_request_det IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_id          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch exam id for id_exam_req: ' || i_task_request;
        SELECT erd.id_exam
          INTO o_exam_id
          FROM exam_req_det erd, exam_req er
         WHERE ((erd.id_exam_req = i_task_request AND i_task_request_det IS NULL) OR
               (erd.id_exam_req_det = i_task_request_det AND i_task_request IS NULL))
           AND erd.id_exam_req = er.id_exam_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_TASK_ID',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_id;

    FUNCTION set_exam_request_task
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
        i_clinical_decision_rule  IN exam_req_det.id_cdr%TYPE,
        i_task_dependency         IN table_number,
        i_flg_task_dependency     IN table_varchar,
        o_exam_req                OUT table_number,
        o_exam_req_det            OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exam_req IS
            SELECT er.*
              FROM exam_req er
             WHERE er.id_exam_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       *
                                        FROM TABLE(i_task_request) t);
    
        CURSOR c_exam_req_det(in_exam_req exam_req.id_exam_req%TYPE) IS
            SELECT erd.*
              FROM exam_req_det erd
             WHERE erd.id_exam_req = in_exam_req;
    
        TYPE t_exam_req IS TABLE OF c_exam_req%ROWTYPE;
        t_tbl_exam_req t_exam_req;
    
        TYPE t_exam_req_det IS TABLE OF c_exam_req_det%ROWTYPE;
        t_tbl_exam_req_det t_exam_req_det;
    
        l_exam_order   exam_req.id_exam_req%TYPE;
        l_exam_cat     exam_cat.id_exam_cat%TYPE;
        l_dt_begin     VARCHAR2(100 CHAR);
        l_codification codification.id_codification%TYPE;
    
        l_exam_req     exam_req.id_exam_req%TYPE;
        l_exam_req_det exam_req_det.id_exam_req_det%TYPE;
    
        l_count_out_reqs NUMBER := 0;
        l_req_det_idx    NUMBER;
    
        TYPE t_record_exam_req_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_exam_req_map t_record_exam_req_map;
    
        l_all_exam_req_det table_number := table_number();
    
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
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        o_exam_req     := table_number();
        o_exam_req_det := table_table_number();
    
        g_error := 'OPEN C_EXAM_REQ';
        OPEN c_exam_req;
        FETCH c_exam_req BULK COLLECT
            INTO t_tbl_exam_req;
    
        CLOSE c_exam_req;
    
        FOR i IN 1 .. t_tbl_exam_req.count
        LOOP
            OPEN c_exam_req_det(t_tbl_exam_req(i).id_exam_req);
            FETCH c_exam_req_det BULK COLLECT
                INTO t_tbl_exam_req_det;
            CLOSE c_exam_req_det;
        
            o_exam_req_det.extend;
            o_exam_req_det(o_exam_req_det.count) := table_number();
        
            -- creating exam_req_det
            FOR j IN 1 .. t_tbl_exam_req_det.count
            LOOP
            
                -- check if this exam_req_det has an order recurrence plan
                IF t_tbl_exam_req_det(j).id_order_recurrence IS NOT NULL
                THEN
                
                    -- get order recurrence option
                    IF NOT pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                    i_prof                => i_prof,
                                                                                    i_order_plan          => t_tbl_exam_req_det(j).id_order_recurrence,
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
                        g_error := 'UPDATE EXAM_REQ_DET';
                        ts_exam_req_det.upd(id_exam_req_det_in      => t_tbl_exam_req_det(j).id_exam_req_det,
                                            id_order_recurrence_in  => NULL,
                                            id_order_recurrence_nin => FALSE,
                                            rows_out                => l_rows_out);
                    
                    END IF;
                
                    g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                    IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                            i_prof                    => i_prof,
                                                                            i_order_recurr_plan       => t_tbl_exam_req_det(j).id_order_recurrence,
                                                                            o_order_recurr_option     => l_order_recurrence_option,
                                                                            o_final_order_recurr_plan => t_tbl_exam_req_det(j).id_order_recurrence,
                                                                            o_error                   => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF t_tbl_exam_req_det(j).id_order_recurrence IS NOT NULL
                    THEN
                        l_order_recurr_final_array.extend;
                        l_order_recurr_final_array(l_order_recurr_final_array.count) := t_tbl_exam_req_det(j).id_order_recurrence;
                    END IF;
                
                END IF;
            
                IF pk_date_utils.date_send_tsz(i_lang, t_tbl_exam_req(i).dt_begin_tstz, i_prof) < g_sysdate_char
                THEN
                    l_dt_begin := g_sysdate_char;
                ELSE
                    l_dt_begin := pk_date_utils.date_send_tsz(i_lang, t_tbl_exam_req(i).dt_begin_tstz, i_prof);
                END IF;
            
                IF l_exam_req IS NULL
                THEN
                    l_exam_req := ts_exam_req.next_key();
                ELSE
                    SELECT e.id_exam_cat
                      INTO l_exam_cat
                      FROM exam e
                     WHERE e.id_exam = t_tbl_exam_req_det(j).id_exam;
                
                    BEGIN
                        g_error := 'GET L_EXAM_ORDER 1';
                        SELECT e.id_exam_req
                          INTO l_exam_order
                          FROM (SELECT erd.id_exam_req,
                                       CASE
                                            WHEN erd.dt_begin < g_sysdate_char THEN
                                             g_sysdate_char
                                            ELSE
                                             erd.dt_begin
                                        END dt_begin
                                  FROM (SELECT er.id_exam_req,
                                               pk_date_utils.trunc_insttimezone_str(i_prof, er.dt_begin_tstz, 'MI') dt_begin
                                          FROM exam_req_det erd, exam_req er, exam e
                                         WHERE erd.id_exam_req_det IN
                                               (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(l_all_exam_req_det) t)
                                           AND erd.id_exam_req = er.id_exam_req
                                           AND er.flg_time = t_tbl_exam_req(i).flg_time
                                           AND er.priority = t_tbl_exam_req(i).priority
                                           AND (er.id_exec_institution = t_tbl_exam_req(i).id_exec_institution OR
                                               (er.id_exec_institution IS NULL AND t_tbl_exam_req(i).id_exec_institution IS NULL))
                                           AND ((erd.flg_prn = pk_exam_constant.g_yes AND t_tbl_exam_req_det(j)
                                               .flg_prn = pk_exam_constant.g_yes) OR
                                               (erd.flg_prn = pk_exam_constant.g_no AND t_tbl_exam_req_det(j)
                                               .flg_prn = pk_exam_constant.g_no))
                                           AND erd.id_exam = e.id_exam
                                           AND e.id_exam_cat = l_exam_cat) erd) e
                         WHERE (e.dt_begin = l_dt_begin OR
                               (l_dt_begin IS NULL AND t_tbl_exam_req(i)
                               .flg_time NOT IN (pk_exam_constant.g_flg_time_e,
                                                  pk_exam_constant.g_flg_time_b,
                                                  pk_exam_constant.g_flg_time_d)))
                           AND rownum = 1;
                    
                        IF t_tbl_exam_req(i)
                         .flg_time NOT IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                        THEN
                            l_exam_req := l_exam_order;
                        END IF;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            IF t_tbl_exam_req_det(1).id_exam_group IS NULL
                            THEN
                                l_exam_req := ts_exam_req.next_key();
                            ELSE
                                BEGIN
                                    g_error := 'GET L_EXAM_ORDER 2';
                                    SELECT id_exam_req
                                      INTO l_exam_order
                                      FROM (SELECT first_value(erd.id_exam_req) over(ORDER BY erd.id_exam_req DESC) id_exam_req
                                              FROM exam_req_det erd
                                             WHERE erd.id_exam_req_det IN
                                                   (SELECT /*+opt_estimate (table t rows=1)*/
                                                     *
                                                      FROM TABLE(l_all_exam_req_det) t)
                                               AND erd.id_exam_group = t_tbl_exam_req_det(1).id_exam_group)
                                     WHERE rownum = 1;
                                
                                    l_exam_req := l_exam_order;
                                
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_exam_req := ts_exam_req.next_key();
                                END;
                            END IF;
                    END;
                END IF;
            
                BEGIN
                    SELECT ec.id_codification
                      INTO l_codification
                      FROM exam_codification ec
                     WHERE ec.id_exam_codification = t_tbl_exam_req_det(j).id_exam_codification;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_codification := NULL;
                END;
            
                g_error := 'CALL CREATE_EXAM_REQUEST';
                IF NOT pk_exam_core.create_exam_request(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_patient                 => t_tbl_exam_req(i).id_patient,
                                                        i_episode                 => t_tbl_exam_req(i).id_episode,
                                                        i_exam_req                => l_exam_req,
                                                        i_exam_req_det            => NULL,
                                                        i_exam                    => t_tbl_exam_req_det(j).id_exam,
                                                        i_exam_group              => t_tbl_exam_req_det(j).id_exam_group,
                                                        i_dt_req                  => NULL,
                                                        i_flg_time                => t_tbl_exam_req(i).flg_time,
                                                        i_dt_begin                => l_dt_begin,
                                                        i_dt_begin_limit          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                 t_tbl_exam_req_det(j).dt_final_target_tstz,
                                                                                                                 i_prof),
                                                        i_episode_destination     => t_tbl_exam_req(i).id_episode_destination,
                                                        i_order_recurrence        => t_tbl_exam_req_det(j).id_order_recurrence,
                                                        i_priority                => t_tbl_exam_req(i).priority,
                                                        i_flg_prn                 => t_tbl_exam_req_det(j).flg_prn,
                                                        i_notes_prn               => t_tbl_exam_req_det(j).prn_notes,
                                                        i_flg_fasting             => t_tbl_exam_req_det(j).flg_fasting,
                                                        i_notes                   => t_tbl_exam_req_det(j).notes,
                                                        i_notes_scheduler         => t_tbl_exam_req_det(j).notes_scheduler,
                                                        i_notes_technician        => t_tbl_exam_req_det(j).notes_tech,
                                                        i_notes_patient           => t_tbl_exam_req(i).notes_patient,
                                                        i_diagnosis               => NULL,
                                                        i_laterality              => t_tbl_exam_req_det(j).flg_laterality,
                                                        i_exec_room               => t_tbl_exam_req_det(j).id_room,
                                                        i_exec_institution        => t_tbl_exam_req_det(j).id_exec_institution,
                                                        i_clinical_purpose        => t_tbl_exam_req_det(j).id_clinical_purpose,
                                                        i_clinical_purpose_notes  => t_tbl_exam_req_det(j).clinical_purpose_notes,
                                                        i_codification            => l_codification,
                                                        i_health_plan             => t_tbl_exam_req_det(j).id_pat_health_plan,
                                                        i_exemption               => t_tbl_exam_req_det(j).id_pat_exemption,
                                                        i_prof_order              => i_prof_order(i),
                                                        i_dt_order                => i_dt_order(i),
                                                        i_order_type              => i_order_type(i),
                                                        i_clinical_question       => i_clinical_question(i),
                                                        i_response                => i_response(i),
                                                        i_clinical_question_notes => i_clinical_question_notes(i),
                                                        i_clinical_decision_rule  => t_tbl_exam_req_det(j).id_cdr,
                                                        --i_flg_origin_req          => NULL,
                                                        i_task_dependency       => i_task_dependency(i),
                                                        i_flg_task_depending    => i_flg_task_dependency(i),
                                                        i_episode_followup_app  => NULL,
                                                        i_schedule_followup_app => NULL,
                                                        i_event_followup_app    => NULL,
                                                        o_exam_req              => l_exam_req,
                                                        o_exam_req_det          => l_exam_req_det,
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
            
                -- check if exam_req not exists
                IF NOT ibt_exam_req_map.exists(to_char(l_exam_req))
                THEN
                    o_exam_req.extend;
                    l_count_out_reqs := l_count_out_reqs + 1;
                
                    -- set mapping between exam_req and its position in the output array
                    ibt_exam_req_map(to_char(l_exam_req)) := l_count_out_reqs;
                
                    -- set exam_req output 
                    o_exam_req(l_count_out_reqs) := l_exam_req;
                
                    g_error := 'CALL TO PK_IA_EVENT_IMAGE.EXAM_ORDER_NEW';
                    pk_ia_event_image.exam_order_new(i_id_exam_req    => l_exam_req,
                                                     i_id_institution => i_prof.institution);
                END IF;
            
                -- append req det of this exam request to all req dets array
                l_all_exam_req_det.extend;
                l_all_exam_req_det(l_all_exam_req_det.count) := l_exam_req_det;
            
                l_req_det_idx := o_exam_req_det.count;
                o_exam_req_det(l_req_det_idx).extend;
                o_exam_req_det(l_req_det_idx)(o_exam_req_det(l_req_det_idx).count) := l_exam_req_det;
            END LOOP;
        END LOOP;
    
        FOR i IN 1 .. l_all_exam_req_det.count
        LOOP
            g_error := 'UPDATE EXAM_REQ_DET';
            ts_exam_req_det.upd(id_exam_req_det_in       => l_all_exam_req_det(i),
                                flg_req_origin_module_in => pk_alert_constant.g_task_origin_order_set,
                                rows_out                 => l_rows_out);
        END LOOP;
    
        g_error := 'CALL TO PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_DELETE_TASK';
        IF NOT pk_exam_external.set_exam_delete_task(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_task_request => i_task_request,
                                                     o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- create recurrence exams
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
        
            g_error := 'CALL CREATE_EXAM_RECURRENCE / l_order_plan_aux.count=' || l_order_plan_aux.count;
            pk_alertlog.log_info(g_error);
            IF NOT pk_exam_core.create_exam_recurrence(i_lang => i_lang,
                                                       
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
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_request_task;

    FUNCTION set_exam_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_exam_req     OUT exam_req.id_exam_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_req     exam_req%ROWTYPE;
        l_exam_req_det exam_req_det%ROWTYPE;
    
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
    
        l_flg_time      VARCHAR2(1 CHAR);
        l_flg_exam_type exam.flg_type%TYPE;
        error_unexpected EXCEPTION;
    
        -- function that returns the default value for "to be performed" field
        FUNCTION get_default_flg_time
        (
            i_lang          IN language.id_language%TYPE,
            i_prof          IN profissional,
            i_flg_exam_type IN exam.flg_type%TYPE,
            o_error         OUT t_error_out
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
            IF (NOT pk_exam_core.get_exam_time_list(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_epis_type => l_epis_type,
                                                    i_exam_type => i_flg_exam_type,
                                                    o_list      => c_data,
                                                    o_error     => o_error))
            THEN
                RAISE error_unexpected;
            END IF;
        
            -- loop until fetch default value
            LOOP
                FETCH c_data
                    INTO l_val, l_rank, l_desc_val, l_flg_default;
            
                EXIT WHEN l_flg_default = pk_exam_constant.g_yes OR c_data%NOTFOUND;
            
            END LOOP;
            CLOSE c_data;
        
            RETURN l_val;
        END;
    BEGIN
    
        g_error := 'GET EXAM_REQ';
        SELECT er.*
          INTO l_exam_req
          FROM exam_req er
         WHERE er.id_exam_req = i_task_request;
    
        g_error := 'GET EXAM_REQ';
        SELECT e.flg_type
          INTO l_flg_exam_type
          FROM exam_req_det erd
          JOIN exam e
            ON erd.id_exam = e.id_exam
         WHERE erd.id_exam_req = i_task_request
           AND rownum = 1;
    
        l_exam_req.id_exam_req   := ts_exam_req.next_key();
        l_exam_req.dt_begin_tstz := current_timestamp;
    
        -- gets default value for "to be performed" field
        l_flg_time := get_default_flg_time(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_flg_exam_type => l_flg_exam_type,
                                           o_error         => o_error);
    
        --Duplicate row to exam_req
        g_error := 'INSERT EXAM_REQ';
        ts_exam_req.ins(rec_in => l_exam_req, gen_pky_in => FALSE, rows_out => l_rows_req_out);
    
        IF i_patient IS NOT NULL
           AND i_episode IS NOT NULL
        THEN
            ts_exam_req.upd(id_exam_req_in => l_exam_req.id_exam_req,
                            id_patient_in  => i_patient,
                            id_episode_in  => i_episode,
                            flg_time_in    => l_flg_time,
                            id_visit_in    => pk_visit.get_visit(i_episode, o_error),
                            rows_out       => l_rows_req_out);
        END IF;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ',
                                      i_rowids     => l_rows_req_out,
                                      o_error      => o_error);
    
        l_rows_out     := NULL;
        l_rows_req_out := NULL;
    
        FOR rec IN (SELECT erd.id_exam_req_det
                      FROM exam_req_det erd
                     WHERE erd.id_exam_req = i_task_request)
        LOOP
            g_error := 'GET EXAM_REQ_DET';
            SELECT erd.*
              INTO l_exam_req_det
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = rec.id_exam_req_det;
        
            -- check if this exam_req_det has an order recurrence plan
            IF l_exam_req_det.id_order_recurrence IS NOT NULL
            THEN
            
                -- copy order recurrence plan
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.COPY_FROM_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                              i_prof                   => i_prof,
                                                                              i_order_recurr_area      => NULL,
                                                                              i_order_recurr_plan_from => l_exam_req_det.id_order_recurrence,
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
                                                                              o_order_recurr_plan      => l_exam_req_det.id_order_recurrence,
                                                                              o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
            ELSE
                l_start_date := current_timestamp;
            END IF;
        
            -- update start dates (according to order recurr plan)
            l_exam_req.dt_begin_tstz := l_start_date;
        
            ts_exam_req.upd(id_exam_req_in   => l_exam_req.id_exam_req,
                            dt_begin_tstz_in => l_exam_req.dt_begin_tstz,
                            rows_out         => l_rows_req_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM_REQ',
                                          i_rowids     => l_rows_req_out,
                                          o_error      => o_error);
        
            l_exam_req_det.id_exam_req     := l_exam_req.id_exam_req;
            l_exam_req_det.dt_target_tstz  := l_start_date;
            l_exam_req_det.id_exam_req_det := ts_exam_req_det.next_key();
        
            --Duplicate row to exam_req_det
            g_error := 'INSERT EXAM_REQ_DET';
            ts_exam_req_det.ins(rec_in => l_exam_req_det, rows_out => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM_REQ_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END LOOP;
    
        o_exam_req := l_exam_req.id_exam_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_copy_task;

    FUNCTION set_exam_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            g_error := 'DELETE EXAM_REQ_DET';
            ts_exam_req_det.del_by(where_clause_in => 'id_exam_req = ' || i_task_request(i));
        
            g_error := 'DELETE EXAM_REQ';
            ts_exam_req.del(id_exam_req_in => i_task_request(i));
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
                                              'SET_EXAM_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_delete_task;

    FUNCTION set_exam_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_req_det table_number;
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            SELECT erd.id_exam_req_det
              BULK COLLECT
              INTO l_exam_req_det
              FROM exam_req_det erd
             WHERE erd.id_order_recurrence IN (SELECT erd.id_order_recurrence
                                                 FROM exam_req_det erd
                                                WHERE erd.id_exam_req = i_task_request(i)
                                                  AND erd.id_order_recurrence IS NOT NULL);
        
            -- bulk collect not launch exception
            IF l_exam_req_det IS NULL
               OR l_exam_req_det.count = 0
            THEN
                SELECT erd.id_exam_req_det
                  BULK COLLECT
                  INTO l_exam_req_det
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req = i_task_request(i);
            END IF;
        
            -- loop through all req dets
            FOR j IN 1 .. l_exam_req_det.count
            LOOP
                g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAG_NO_COMMIT';
                IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_epis             => i_episode,
                                                                i_diag             => i_diagnosis,
                                                                i_exam_req         => i_task_request(i),
                                                                i_analysis_req     => NULL,
                                                                i_interv_presc     => NULL,
                                                                i_exam_req_det     => l_exam_req_det(j),
                                                                i_analysis_req_det => NULL,
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
                                              'SET_EXAM_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_exam_diagnosis;

    FUNCTION set_exam_execute_time
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
                                              'SET_EXAM_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END set_exam_execute_time;

    FUNCTION check_exam_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type exam.flg_type%TYPE;
    
        l_notes_tech       sys_config.value%TYPE;
        l_clinical_purpose sys_config.value%TYPE;
        l_tbl_check        table_varchar;
    
    BEGIN
    
        g_error := 'Fetch instructions for i_exam_req: ' || i_task_request;
        SELECT e.flg_type
          INTO l_flg_type
          FROM exam_req er, exam_req_det erd, exam e
         WHERE er.id_exam_req = i_task_request
           AND er.id_exam_req = erd.id_exam_req
           AND erd.id_exam = e.id_exam;
    
        IF l_flg_type = pk_exam_constant.g_type_img
        THEN
            l_notes_tech       := pk_sysconfig.get_config('IMG_NOTES_TECH_REQUIRED', i_prof);
            l_clinical_purpose := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_I', i_prof);
        ELSE
            l_notes_tech       := pk_sysconfig.get_config('EXM_NOTES_TECH_REQUIRED', i_prof);
            l_clinical_purpose := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_E', i_prof);
        END IF;
    
        g_error := 'Fetch instructions for i_exam_req: ' || i_task_request;
        SELECT decode(er.priority,
                      NULL,
                      pk_exam_constant.g_no,
                      decode(er.flg_time,
                             NULL,
                             pk_exam_constant.g_no,
                             decode(l_notes_tech,
                                    pk_exam_constant.g_yes,
                                    decode(erd.notes_tech,
                                           NULL,
                                           pk_exam_constant.g_no,
                                           decode(l_clinical_purpose,
                                                  pk_exam_constant.g_yes,
                                                  decode(erd.id_clinical_purpose,
                                                         NULL,
                                                         pk_exam_constant.g_no,
                                                         pk_exam_constant.g_yes),
                                                  pk_exam_constant.g_yes)),
                                    decode(l_clinical_purpose,
                                           pk_exam_constant.g_yes,
                                           decode(erd.id_clinical_purpose,
                                                  NULL,
                                                  pk_exam_constant.g_no,
                                                  pk_exam_constant.g_yes),
                                           pk_exam_constant.g_yes))))
          BULK COLLECT
          INTO l_tbl_check
          FROM exam_req er, exam_req_det erd
         WHERE er.id_exam_req = i_task_request
           AND er.id_exam_req = erd.id_exam_req;
    
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
                                              'CHECK_EXAM_MANDATORY_FIELD',
                                              o_error);
            RETURN FALSE;
    END check_exam_mandatory_field;

    FUNCTION check_exam_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat c_pat%ROWTYPE;
    
        l_prof_access PLS_INTEGER;
    
        l_count      NUMBER := 0;
        l_exam       table_number;
        l_exam_group exam_req.id_exam_group%TYPE;
    
        l_prof_cat_type category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
    BEGIN
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        SELECT erd.id_exam
          BULK COLLECT
          INTO l_exam
          FROM exam_req er, exam_req_det erd
         WHERE er.id_exam_req = i_task_request
           AND er.id_exam_req = erd.id_exam_req
           AND er.id_exam_group IS NULL;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_prof_access
              FROM group_access ga
             INNER JOIN group_access_prof gaf
                ON gaf.id_group_access = ga.id_group_access
             INNER JOIN group_access_record gar
                ON gar.id_group_access = ga.id_group_access
             WHERE gaf.id_professional = i_prof.id
               AND gaf.flg_available = pk_exam_constant.g_available
               AND ga.id_institution IN (i_prof.institution, 0)
               AND ga.id_software IN (i_prof.software, 0)
               AND ga.flg_type = 'E'
               AND ga.flg_available = pk_exam_constant.g_available
               AND gar.flg_type = 'E'
               AND gar.id_record IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      *
                                       FROM TABLE(l_exam) t);
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_access := 0;
        END;
    
        IF l_exam IS NOT NULL
           AND l_exam.count > 0
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM exam e,
                   (SELECT *
                      FROM exam_dep_clin_serv
                     WHERE flg_type = pk_exam_constant.g_exam_can_req
                       AND id_software = i_prof.software
                       AND id_institution = i_prof.institution) edcs,
                   (SELECT DISTINCT gar.id_record id_exam
                      FROM group_access ga
                     INNER JOIN group_access_prof gaf
                        ON gaf.id_group_access = ga.id_group_access
                     INNER JOIN group_access_record gar
                        ON gar.id_group_access = ga.id_group_access
                     WHERE gaf.id_professional = i_prof.id
                       AND ga.id_institution IN (i_prof.institution, 0)
                       AND ga.id_software IN (i_prof.software, 0)
                       AND ga.flg_type = 'E'
                       AND gar.flg_type = 'E'
                       AND ga.flg_available = pk_exam_constant.g_available
                       AND gaf.flg_available = pk_exam_constant.g_available
                       AND gar.flg_available = pk_exam_constant.g_available) ecs
             WHERE e.id_exam IN (SELECT /*+opt_estimate(table t rows=1)*/
                                  *
                                   FROM TABLE(l_exam) t)
               AND e.flg_available = pk_exam_constant.g_available
               AND e.id_exam = edcs.id_exam
               AND e.id_exam = ecs.id_exam(+)
               AND ((EXISTS
                    (SELECT 1
                        FROM prof_dep_clin_serv pdcs, exam_cat_dcs ecd
                       WHERE pdcs.id_professional = i_prof.id
                         AND pdcs.flg_status = pk_exam_constant.g_selected
                         AND pdcs.id_institution = i_prof.institution
                         AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                         AND ecd.id_exam_cat = e.id_exam_cat) AND l_prof_cat_type != pk_alert_constant.g_cat_type_doc) OR
                   l_prof_cat_type = pk_alert_constant.g_cat_type_doc)
               AND (l_prof_access = 0 OR (l_prof_access != 0 AND ecs.id_exam IS NOT NULL))
               AND (((l_pat.gender IS NOT NULL AND nvl(e.gender, 'I') IN ('I', l_pat.gender)) OR l_pat.gender IS NULL OR
                   l_pat.gender = 'I') AND (nvl(l_pat.age, 0) BETWEEN nvl(e.age_min, 0) AND
                   nvl(e.age_max, nvl(l_pat.age, 0)) OR nvl(l_pat.age, 0) = 0));
        
        ELSE
            BEGIN
                SELECT er.id_exam_group
                  INTO l_exam_group
                  FROM exam_req er
                 WHERE er.id_exam_req = i_task_request;
            
                g_error := 'TEST ID_EXAM_GROUP';
                SELECT COUNT(eg.id_exam_group)
                  INTO l_count
                  FROM exam_group eg, exam_egp ee, exam e
                 WHERE eg.id_group_parent = l_exam_group
                   AND eg.id_exam_group = ee.id_exam_group
                   AND ee.id_exam = e.id_exam
                   AND e.flg_available = pk_exam_constant.g_available
                   AND ((EXISTS (SELECT 1
                                   FROM prof_dep_clin_serv pdcs, exam_cat_dcs ecd
                                  WHERE id_professional = i_prof.id
                                    AND pdcs.id_institution = i_prof.institution
                                    AND pdcs.flg_status = pk_exam_constant.g_selected
                                    AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                                    AND ecd.id_exam_cat = e.id_exam_cat) AND
                        l_prof_cat_type != pk_alert_constant.g_cat_type_doc) OR
                       l_prof_cat_type = pk_alert_constant.g_cat_type_doc)
                   AND (l_prof_access = 0 OR
                       (l_prof_access != 0 AND EXISTS (SELECT 1
                                                          FROM exam_group egroup,
                                                               exam_egp egp,
                                                               (SELECT DISTINCT gar.id_record id_exam
                                                                  FROM group_access ga
                                                                 INNER JOIN group_access_prof gaf
                                                                    ON gaf.id_group_access = ga.id_group_access
                                                                 INNER JOIN group_access_record gar
                                                                    ON gar.id_group_access = ga.id_group_access
                                                                 WHERE gaf.id_professional = i_prof.id
                                                                   AND ga.id_institution IN (i_prof.institution, 0)
                                                                   AND ga.id_software IN (i_prof.software, 0)
                                                                   AND ga.flg_type = 'E'
                                                                   AND gar.flg_type = 'E'
                                                                   AND ga.flg_available = pk_exam_constant.g_available
                                                                   AND gaf.flg_available = pk_exam_constant.g_available
                                                                   AND gar.flg_available = pk_exam_constant.g_available) ecs
                                                         WHERE egroup.id_exam_group = eg.id_exam_group
                                                           AND egp.id_exam_group = egroup.id_exam_group
                                                           AND egp.id_exam = ecs.id_exam
                                                           AND egp.id_exam = ee.id_exam)))
                   AND (((l_pat.gender IS NOT NULL AND nvl(eg.gender, 'I') IN ('I', l_pat.gender)) OR
                       l_pat.gender IS NULL OR l_pat.gender = 'I') AND
                       (nvl(l_pat.age, 0) BETWEEN nvl(eg.age_min, 0) AND nvl(eg.age_max, nvl(l_pat.age, 0)) OR
                       nvl(l_pat.age, 0) = 0));
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'NO ID EXAM';
                    RAISE g_other_exception;
            END;
        END IF;
    
        IF (l_count = 0)
        THEN
            o_flg_conflict := pk_exam_constant.g_yes;
        ELSE
            o_flg_conflict := pk_exam_constant.g_no;
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
                                              'CHECK_EXAM_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_exam_conflict;

    FUNCTION check_exam_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error      := 'CALL pk_exam_utils.get_exam_permission';
        o_flg_cancel := pk_exam_utils.get_exam_permission(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_area                => pk_exam_constant.g_exam_area_exams,
                                                          i_button              => pk_exam_constant.g_exam_button_cancel,
                                                          i_episode             => i_episode,
                                                          i_exam_req            => NULL,
                                                          i_exam_req_det        => i_task_request,
                                                          i_flg_current_episode => pk_exam_constant.g_yes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXAM_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_exam_cancel;

    PROCEDURE tde_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_exam_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam         IN exam.id_exam%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat   c_pat%ROWTYPE;
        l_count PLS_INTEGER;
    
        l_prof_cat_type category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
    BEGIN
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        SELECT COUNT(1)
          INTO l_count
          FROM exam e, exam_dep_clin_serv edcs
         WHERE e.id_exam = i_exam
           AND e.flg_available = pk_exam_constant.g_available
           AND ((EXISTS
                (SELECT 1
                    FROM prof_dep_clin_serv pdcs, exam_cat_dcs ecd
                   WHERE pdcs.id_professional = i_prof.id
                     AND pdcs.flg_status = pk_exam_constant.g_selected
                     AND pdcs.id_institution = i_prof.institution
                     AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                     AND ecd.id_exam_cat = e.id_exam_cat) AND l_prof_cat_type != pk_alert_constant.g_cat_type_doc) OR
               l_prof_cat_type = pk_alert_constant.g_cat_type_doc)
           AND e.id_exam = edcs.id_exam
           AND edcs.id_institution = i_prof.institution
           AND edcs.id_software = i_prof.software
           AND edcs.flg_type = pk_exam_constant.g_exam_can_req
           AND ((l_pat.gender IS NOT NULL AND nvl(e.gender, 'I') IN ('I', l_pat.gender)) OR l_pat.gender IS NULL OR
               l_pat.gender = 'I')
           AND (nvl(l_pat.age, 0) BETWEEN nvl(e.age_min, 0) AND nvl(e.age_max, nvl(l_pat.age, 0)) OR
               nvl(l_pat.age, 0) = 0);
    
        IF (l_count > 0)
        THEN
            o_flg_conflict := pk_exam_constant.g_no;
        ELSE
            o_flg_conflict := pk_exam_constant.g_yes;
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
                                              'CHECK_EXAM_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_exam_conflict;

    FUNCTION get_exam_cancel_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_cancel      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type      exams_ea.flg_type%TYPE;
        l_id_sys_button table_number := table_number();
    
    BEGIN
    
        g_error := 'Fetch workflow cancel permission';
        SELECT CASE
                    WHEN eea.flg_status_det IN
                         (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read) THEN
                     pk_alert_constant.g_no
                    ELSE
                     pk_alert_constant.g_yes
                END flg_status,
               eea.flg_type
          INTO o_flg_cancel, l_flg_type
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_id_exam_req_det;
    
        IF o_flg_cancel = pk_alert_constant.g_yes
        THEN
            IF l_flg_type = pk_exam_constant.g_type_img
            THEN
                l_id_sys_button := pk_exam_constant.g_cancel_permissions_img;
            ELSE
                l_id_sys_button := pk_exam_constant.g_cancel_permissions_exm;
            END IF;
        
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
                                              'GET_EXAM_CANCEL_PERMISSION',
                                              o_error);
            RETURN FALSE;
    END get_exam_cancel_permission;

    FUNCTION start_exam_task_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exam_req(i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE) IS
            SELECT er.id_exam_req, erd.flg_status, erd.id_exec_institution, erd.id_room, er.id_episode
              FROM exam_req er, exam_req_det erd
             WHERE erd.id_exam_req_det = i_exam_req_det
               AND erd.id_exam_req = er.id_exam_req;
    
        l_exam_req c_exam_req%ROWTYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_status   exam_req.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            g_error := 'INIT L_START_TSTZ';
            IF i_start_tstz IS NOT NULL
            THEN
                l_dt_begin := i_start_tstz;
            ELSE
                l_dt_begin := NULL;
            END IF;
        
            g_error := 'OPEN C_EXAM_REQ';
            OPEN c_exam_req(i_task_request(i));
            FETCH c_exam_req
                INTO l_exam_req;
            CLOSE c_exam_req;
        
            g_error := 'GET STATUS';
            IF l_exam_req.flg_status = pk_exam_constant.g_exam_wtg_tde
            THEN
                IF l_exam_req.id_exec_institution != i_prof.institution
                THEN
                    l_status := pk_exam_constant.g_exam_exterior;
                ELSE
                    IF l_status = pk_exam_constant.g_exam_wtg_tde
                       AND nvl(l_dt_begin, g_sysdate_tstz) > g_sysdate_tstz
                    THEN
                        l_status := pk_exam_constant.g_exam_pending;
                    ELSE
                        l_status := pk_exam_constant.g_exam_req;
                    END IF;
                END IF;
            
                -- Verifica localização actual do doente
                g_error := 'CALL PK_EXAM_CORE.SET_EXAM_STATUS';
                IF NOT pk_exam_core.set_exam_status(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_exam_req_det    => table_number(i_task_request(i)),
                                                    i_status          => l_status,
                                                    i_notes           => NULL,
                                                    i_notes_scheduler => NULL,
                                                    o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                ts_exam_req.upd(dt_begin_tstz_in => nvl(l_dt_begin, g_sysdate_tstz),
                                where_in         => 'id_exam_req = ' || l_exam_req.id_exam_req ||
                                                    ' AND dt_begin_tstz IS NULL',
                                rows_out         => l_rows_out);
            
                ts_exam_req_det.upd(dt_target_tstz_in => nvl(l_dt_begin, g_sysdate_tstz),
                                    where_in          => 'id_exam_req_det = ' || i_task_request(i),
                                    rows_out          => l_rows_out);
            
            END IF;
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EXAM_REQ',
                                      i_rowids       => l_rows_out,
                                      i_list_columns => table_varchar('DT_BEGIN_TSTZ'),
                                      o_error        => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'START_EXAM_TASK_REQ',
                                              o_error);
            RETURN FALSE;
    END start_exam_task_req;

    FUNCTION cancel_exam_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN tde_task_dependency.id_task_request%TYPE,
        i_reason           IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes     IN VARCHAR2,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_req_det table_number;
    
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(erd.id_exam_req_det)
          INTO l_count
          FROM exam_req_det erd
         WHERE erd.id_order_recurrence IN (SELECT erd.id_order_recurrence
                                             FROM exam_req_det erd
                                            WHERE erd.id_exam_req_det = i_task_request
                                              AND erd.id_order_recurrence IS NOT NULL)
           AND erd.flg_status != 'C';
    
        IF l_count = 0
        THEN
            l_exam_req_det := table_number(i_task_request);
        ELSE
            SELECT erd.id_exam_req_det
              BULK COLLECT
              INTO l_exam_req_det
              FROM exam_req_det erd
             WHERE erd.id_order_recurrence IN (SELECT erd.id_order_recurrence
                                                 FROM exam_req_det erd
                                                WHERE erd.id_exam_req_det = i_task_request
                                                  AND erd.id_order_recurrence IS NOT NULL)
               AND erd.flg_status != 'C';
        END IF;
    
        g_error := 'CALL PK_EXAMS_API_DB.CANCEL_EXAM_REQUEST';
        IF NOT pk_exams_api_db.cancel_exam_request(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_exam_req_det     => l_exam_req_det,
                                                   i_dt_cancel        => NULL,
                                                   i_cancel_reason    => i_reason,
                                                   i_cancel_notes     => i_reason_notes,
                                                   i_prof_order       => i_prof_order,
                                                   i_dt_order         => i_dt_order,
                                                   i_order_type       => i_order_type,
                                                   i_transaction_id   => i_transaction_id,
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
                                              'CANCEL_EXAM_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_task;

    FUNCTION get_exam_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list
    
     IS
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE v.id_patient = i_patient
               AND v.id_visit = e.id_visit
               AND e.flg_status = pk_alert_constant.g_flg_status_a;
    
        l_visit c_visit%ROWTYPE;
    
        o_tasks_list  tf_tasks_list := tf_tasks_list();
        o_error       t_error_out := t_error_out(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        l_tasks_lists tf_tasks_list := tf_tasks_list();
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
    
        LOOP
            FETCH c_visit
                INTO l_visit;
            EXIT WHEN c_visit%NOTFOUND;
        
            g_error := 'Selecting tasks lists...';
            SELECT tr_tasks_list(exam_list.id_exam_req_det,
                                 exam_list.desc_exam,
                                 exam_list.to_be_perform,
                                 exam_list.dt_ord)
              BULK COLLECT
              INTO l_tasks_lists
              FROM (SELECT eea.id_exam_req_det id_exam_req_det,
                           pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) ||
                           decode(l_visit.id_epis_type,
                                  nvl(t_ti_log.get_epis_type(i_lang,
                                                             i_prof,
                                                             e.id_epis_type,
                                                             eea.flg_status_req,
                                                             eea.id_exam_req,
                                                             pk_exam_constant.g_exam_type_req),
                                      e.id_epis_type),
                                  '',
                                  ' - (' || pk_message.get_message(i_lang,
                                                                   profissional(i_prof.id,
                                                                                i_prof.institution,
                                                                                t_ti_log.get_epis_type_soft(i_lang,
                                                                                                            i_prof,
                                                                                                            e.id_epis_type,
                                                                                                            eea.flg_status_req,
                                                                                                            eea.id_exam_req,
                                                                                                            pk_exam_constant.g_exam_type_req)),
                                                                   'IMAGE_T009') || ')') desc_exam,
                           pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || e.id_epis_type) to_be_perform,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, eea.dt_req, i_prof) dt_ord
                      FROM exams_ea eea, episode e
                     WHERE eea.id_patient = i_patient
                       AND (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode)
                       AND e.id_visit = l_visit.id_visit
                       AND eea.flg_status_det NOT IN (pk_exam_constant.g_exam_exec,
                                                      pk_exam_constant.g_exam_result,
                                                      pk_exam_constant.g_exam_read,
                                                      pk_exam_constant.g_exam_cancel)
                       AND (eea.flg_referral IS NULL OR eea.flg_referral = 'A')
                     ORDER BY dt_ord DESC) exam_list;
        
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
                                              'GET_EXAM_ONGOING_TASKS',
                                              o_error);
            RETURN o_tasks_list;
    END get_exam_ongoing_tasks;

    FUNCTION suspend_exam_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_exam   exam.id_exam%TYPE;
        l_exam_desc pk_translation.t_desc_translation;
    
        l_cancel_reason cancel_reason.id_cancel_reason%TYPE;
    
        l_cancel_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                               pk_death_registry.c_code_msg_death);
        l_mess_error   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAM_M014');
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_reason = pk_death_registry.c_flg_reason_death
        THEN
            l_cancel_reason := pk_cancel_reason.c_reason_patient_death;
        END IF;
    
        BEGIN
            SELECT pk_exam_utils.get_alias_translation(i_lang, i_prof, e.code_exam, NULL), e.id_exam
              INTO l_exam_desc, l_id_exam
              FROM exam e, exam_req_det erd
             WHERE erd.id_exam = e.id_exam
               AND erd.id_exam_req_det = i_id_task;
        EXCEPTION
            WHEN no_data_found THEN
                l_exam_desc := '';
        END;
    
        -- if no translation is found then return the exam id 
        IF l_exam_desc IS NULL
        THEN
            l_exam_desc := l_id_exam;
        END IF;
    
        g_error := 'CALL TO PK_EXAM_CORE.CANCEL_EXAM_REQUEST';
        IF NOT
            pk_exam_core.cancel_exam_request(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_exam_req_det  => table_number(i_id_task),
                                             i_dt_cancel     => pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof),
                                             i_cancel_reason => l_cancel_reason,
                                             i_cancel_notes  => l_cancel_notes,
                                             i_prof_order    => NULL,
                                             i_dt_order      => NULL,
                                             i_order_type    => NULL,
                                             o_error         => o_error)
        THEN
            o_msg_error := REPLACE(l_mess_error, '@1', l_exam_desc);
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
                                              'SUSPEND_EXAM_TASK',
                                              o_error);
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_exam_desc);
            RETURN FALSE;
    END suspend_exam_task;

    FUNCTION reactivate_exam_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN NUMBER,
        o_msg_error OUT VARCHAR,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_req_det exam_req_det%ROWTYPE;
    
        l_flg_status       ti_log.flg_status%TYPE;
        l_prof_last_update ti_log.id_professional%TYPE;
        l_dt_last_update   ti_log.dt_creation_tstz%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        SELECT erd.*
          INTO l_exam_req_det
          FROM exam_req_det erd
         WHERE erd.id_exam_req_det = i_id_task;
    
        g_error := 'SELECT TI_LOG ED';
        SELECT flg_status, id_professional, dt_creation_tstz
          INTO l_flg_status, l_prof_last_update, l_dt_last_update
          FROM (SELECT tl.flg_status,
                       tl.id_professional,
                       tl.dt_creation_tstz,
                       row_number() over(ORDER BY tl.dt_creation_tstz DESC) rn
                  FROM ti_log tl
                 WHERE tl.id_record = i_id_task
                   AND tl.flg_status NOT IN (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_nr)
                   AND tl.flg_type = pk_exam_constant.g_exam_type_det)
         WHERE rn = 1;
    
        g_error := 'UPDATE EXAM_REQ_DET';
        ts_exam_req_det.upd(id_exam_req_det_in      => i_id_task,
                            flg_status_in           => l_flg_status,
                            id_prof_cancel_in       => NULL,
                            id_prof_cancel_nin      => FALSE,
                            notes_cancel_in         => NULL,
                            notes_cancel_nin        => FALSE,
                            dt_cancel_tstz_in       => NULL,
                            dt_cancel_tstz_nin      => FALSE,
                            id_cancel_reason_in     => NULL,
                            id_cancel_reason_nin    => FALSE,
                            id_prof_last_update_in  => l_prof_last_update,
                            id_prof_last_update_nin => FALSE,
                            dt_last_update_tstz_in  => l_dt_last_update,
                            dt_last_update_tstz_nin => FALSE,
                            rows_out                => l_rows_out);
    
        g_error := 'PROCESS_UPDATE EXAM_REQ_DET';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'DELETE EXAM_REQ_DET_HIST';
        ts_exam_req_det_hist.del_by(where_clause_in => 'id_exam_req_det = ' || i_id_task || ' AND flg_status = ''' ||
                                                       l_flg_status || '''');
    
        g_error := 'SELECT TI_LOG ER';
        SELECT flg_status, id_professional, dt_creation_tstz
          INTO l_flg_status, l_prof_last_update, l_dt_last_update
          FROM (SELECT tl.flg_status,
                       tl.id_professional,
                       tl.dt_creation_tstz,
                       row_number() over(ORDER BY tl.dt_creation_tstz DESC) rn
                  FROM ti_log tl
                 WHERE tl.id_record = l_exam_req_det.id_exam_req
                   AND tl.flg_status NOT IN (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_nr)
                   AND tl.flg_type = pk_exam_constant.g_exam_type_req)
         WHERE rn = 1;
    
        g_error := 'UPDATE EXAM_REQ';
        ts_exam_req.upd(id_exam_req_in          => l_exam_req_det.id_exam_req,
                        flg_status_in           => l_flg_status,
                        id_prof_cancel_in       => NULL,
                        id_prof_cancel_nin      => FALSE,
                        notes_cancel_in         => NULL,
                        notes_cancel_nin        => FALSE,
                        dt_cancel_tstz_in       => NULL,
                        dt_cancel_tstz_nin      => FALSE,
                        id_cancel_reason_in     => NULL,
                        id_cancel_reason_nin    => FALSE,
                        id_prof_last_update_in  => l_prof_last_update,
                        id_prof_last_update_nin => FALSE,
                        dt_last_update_tstz_in  => l_dt_last_update,
                        dt_last_update_tstz_nin => FALSE,
                        rows_out                => l_rows_out);
    
        g_error := 'PROCESS_UPDATE EXAM_REQ';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ',
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
                                              'REACTIVATE_EXAM_TASK',
                                              o_error);
            o_msg_error := REPLACE(pk_message.get_message(i_lang, 'EXAM_M014'),
                                   '@1',
                                   pk_translation.get_translation(i_lang, 'EXAM.CODE_EXAM.' || l_exam_req_det.id_exam));
            RETURN FALSE;
    END reactivate_exam_task;

    FUNCTION get_exam_task_execute_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req.id_exam_req%TYPE,
        o_flg_time        OUT VARCHAR2,
        o_flg_time_desc   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'get task execute time';
        SELECT eea.flg_time, pk_sysdomain.get_domain('EXAM_REQ.FLG_TIME', eea.flg_time, i_lang)
          INTO o_flg_time, o_flg_time_desc
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_id_exam_req_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_TASK_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_execute_time;

    FUNCTION update_tde_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_action      IN VARCHAR2,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_reason_notes    IN VARCHAR2 DEFAULT NULL,
        i_transaction_id  IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_task_dependency exam_req_det.id_task_dependency%TYPE;
    
    BEGIN
    
        IF i_task_dependency IS NOT NULL
        THEN
            l_task_dependency := i_task_dependency;
        ELSE
            g_error := 'Fetch id_task_dependency';
            SELECT erd.id_task_dependency
              INTO l_task_dependency
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = i_exam_req_det;
        END IF;
    
        IF l_task_dependency IS NOT NULL
        THEN
            IF i_flg_action = pk_exam_constant.g_exam_cancel
            THEN
                g_error := 'CALL PK_TDE_DB.UPDATE_TASK_STATE_CANCEL';
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
            ELSIF i_flg_action IN (pk_exam_constant.g_exam_exec, pk_exam_constant.g_exam_toexec)
            THEN
                g_error := 'CALL PK_TDE_DB.UPDATE_TASK_STATE_EXECUTE';
                IF NOT pk_tde_db.update_task_state_execute(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_task_dependency => l_task_dependency,
                                                           o_error           => o_error)
                THEN
                    RAISE g_user_exception;
                END IF;
            
            ELSIF i_flg_action IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read)
            THEN
                g_error := 'CALL PK_TDE_DB.UPDATE_TASK_STATE_FINISH';
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
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TDE_TASK_STATE',
                                              o_error);
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_tde_task_state;

    PROCEDURE pregnancy_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION tf_exam_pregnancy_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_last_result IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_pregnancy_result IS
    
        l_exams_pregnancy_result t_tbl_exams_pregnancy_result;
    
    BEGIN
    
        SELECT t_exams_pregnancy_result(t.id_exam_req,
                                        t.id_exam_req_det,
                                        t.id_exam,
                                        t.dt_req,
                                        t.id_episode,
                                        t.id_pat_pregnancy,
                                        t.id_exam_result,
                                        t.dt_result,
                                        t.id_professional,
                                        t.notes,
                                        t.result_count)
          BULK COLLECT
          INTO l_exams_pregnancy_result
          FROM (SELECT erd.id_exam_req,
                       erd.id_exam_req_det,
                       erd.id_exam,
                       er.dt_req_tstz dt_req,
                       nvl(er.id_episode, er.id_episode_origin) id_episode,
                       erd.id_pat_pregnancy,
                       eres.id_exam_result,
                       eres.dt_exam_result_tstz dt_result,
                       eres.id_professional,
                       eres.notes,
                       NULL result_count,
                       row_number() over(PARTITION BY erd.id_exam_req_det ORDER BY eres.dt_exam_result_tstz DESC) rn
                  FROM exam_req_det erd, exam_req er, exam_result eres
                 WHERE erd.id_exam_req_det = i_exam_req_det
                   AND erd.id_exam_req = er.id_exam_req
                   AND erd.id_exam_req_det = eres.id_exam_req_det(+)
                   AND eres.flg_status(+) != pk_exam_constant.g_exam_result_cancel) t
         WHERE (rn = 1 AND i_flg_last_result = pk_exam_constant.g_yes)
            OR i_flg_last_result = pk_exam_constant.g_no;
    
        RETURN l_exams_pregnancy_result;
    
    END tf_exam_pregnancy_info;

    FUNCTION tf_exam_pregnancy_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN table_number,
        i_flg_last_result IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_pregnancy_result IS
    
        l_exams_pregnancy_result t_tbl_exams_pregnancy_result;
    
    BEGIN
    
        SELECT t_exams_pregnancy_result(t.id_exam_req,
                                        t.id_exam_req_det,
                                        t.id_exam,
                                        t.dt_req,
                                        t.id_episode,
                                        t.id_pat_pregnancy,
                                        t.id_exam_result,
                                        t.dt_result,
                                        t.id_professional,
                                        t.notes,
                                        t.result_count)
          BULK COLLECT
          INTO l_exams_pregnancy_result
          FROM (SELECT erd.id_exam_req,
                       erd.id_exam_req_det,
                       erd.id_exam,
                       er.dt_req_tstz dt_req,
                       nvl(er.id_episode, er.id_episode_origin) id_episode,
                       erd.id_pat_pregnancy,
                       eres.id_exam_result,
                       eres.dt_exam_result_tstz dt_result,
                       eres.id_professional,
                       eres.notes,
                       NULL result_count,
                       row_number() over(PARTITION BY erd.id_exam_req_det ORDER BY eres.dt_exam_result_tstz DESC) rn
                  FROM exam_req_det erd, exam_req er, exam_result eres, TABLE(i_exam_req_det) ierd
                 WHERE erd.id_exam_req_det = ierd.column_value
                   AND erd.id_exam_req = er.id_exam_req
                   AND erd.id_exam_req_det = eres.id_exam_req_det(+)
                   AND eres.flg_status(+) != pk_exam_constant.g_exam_result_cancel) t
         WHERE (rn = 1 AND i_flg_last_result = pk_exam_constant.g_yes)
            OR i_flg_last_result = pk_exam_constant.g_no;
    
        RETURN l_exams_pregnancy_result;
    
    END tf_exam_pregnancy_info;

    FUNCTION tf_exam_pregnancy_result_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam_result IN exam_result.id_exam_result%TYPE
    ) RETURN t_tbl_exams_pregnancy_result IS
    
        l_exams_pregnancy_result t_tbl_exams_pregnancy_result;
    
    BEGIN
    
        SELECT t_exams_pregnancy_result(t.id_exam_req,
                                        t.id_exam_req_det,
                                        t.id_exam,
                                        t.dt_req,
                                        t.id_episode,
                                        t.id_pat_pregnancy,
                                        t.id_exam_result,
                                        t.dt_result,
                                        t.id_professional,
                                        t.notes,
                                        t.result_count)
          BULK COLLECT
          INTO l_exams_pregnancy_result
          FROM (SELECT erd.id_exam_req,
                       erd.id_exam_req_det,
                       erd.id_exam,
                       er.dt_req_tstz dt_req,
                       nvl(er.id_episode, er.id_episode_origin) id_episode,
                       erd.id_pat_pregnancy,
                       eres.id_exam_result,
                       eres.dt_exam_result_tstz dt_result,
                       eres.id_professional,
                       eres.notes,
                       NULL result_count
                  FROM exam_result eres, exam_req_det erd, exam_req er
                 WHERE eres.id_exam_result = i_exam_result
                   AND eres.flg_status != pk_exam_constant.g_exam_result_cancel
                   AND eres.id_exam_req_det = erd.id_exam_req_det
                   AND erd.id_exam_req = er.id_exam_req) t;
    
        RETURN l_exams_pregnancy_result;
    
    END tf_exam_pregnancy_result_info;

    FUNCTION tf_exam_pregnancy_result_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam_result IN table_number
    ) RETURN t_tbl_exams_pregnancy_result IS
    
        l_exams_pregnancy_result t_tbl_exams_pregnancy_result;
    
    BEGIN
    
        SELECT t_exams_pregnancy_result(t.id_exam_req,
                                        t.id_exam_req_det,
                                        t.id_exam,
                                        t.dt_req,
                                        t.id_episode,
                                        t.id_pat_pregnancy,
                                        t.id_exam_result,
                                        t.dt_result,
                                        t.id_professional,
                                        t.notes,
                                        t.result_count)
          BULK COLLECT
          INTO l_exams_pregnancy_result
          FROM (SELECT erd.id_exam_req,
                       erd.id_exam_req_det,
                       erd.id_exam,
                       er.dt_req_tstz dt_req,
                       nvl(er.id_episode, er.id_episode_origin) id_episode,
                       erd.id_pat_pregnancy,
                       eres.id_exam_result,
                       eres.dt_exam_result_tstz dt_result,
                       eres.id_professional,
                       eres.notes,
                       NULL result_count
                  FROM exam_result eres, exam_req_det erd, exam_req er, TABLE(i_exam_result) ier
                 WHERE eres.id_exam_result = ier.column_value
                   AND eres.flg_status != pk_exam_constant.g_exam_result_cancel
                   AND eres.id_exam_req_det = erd.id_exam_req_det
                   AND erd.id_exam_req = er.id_exam_req) t;
    
        RETURN l_exams_pregnancy_result;
    
    END tf_exam_pregnancy_result_info;

    PROCEDURE single_page________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_req_det_by_id_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN exam_req_det.id_order_recurrence%TYPE,
        o_exam_req_det     OUT exam_req_det.id_exam_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT id_exam_req_det
          INTO o_exam_req_det
          FROM (SELECT erd.id_exam_req_det,
                       row_number() over(PARTITION BY erd.id_order_recurrence ORDER BY dt_last_update_tstz) rn
                  FROM exam_req_det erd
                 WHERE erd.id_order_recurrence = i_order_recurrence)
         WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_REQ_DET_BY_ID_RECURR',
                                              o_error);
            RETURN FALSE;
    END get_exam_req_det_by_id_recurr;

    FUNCTION get_exam_result_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam_result IN exam_result.id_exam_result%TYPE,
        i_flg_image_exam IN pk_types.t_flg_char,
        o_description    OUT CLOB,
        o_notes_result   OUT CLOB,
        o_result_notes   OUT CLOB,
        o_interpretation OUT CLOB,
        o_exec_date      OUT exam_req_det.start_time%TYPE,
        o_result         OUT pk_translation.t_desc_translation,
        o_report_date    OUT exam_req.dt_req_tstz%TYPE,
        o_inst_name      OUT CLOB,
        o_result_date    OUT exam_result.dt_exam_result_tstz%TYPE,
        o_exam_desc      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comma CONSTANT VARCHAR2(2 CHAR) := ', ';
        l_space CONSTANT VARCHAR2(2 CHAR) := ' ';
    
        l_desc_exam      pk_translation.t_desc_translation;
        l_dt_exam_result exam_result.dt_exam_result_tstz%TYPE;
        l_result         pk_translation.t_desc_translation;
        l_exec_date      exam_req_det.start_time%TYPE;
        l_req_date       exam_req.dt_req_tstz%TYPE;
    
        l_intern_desc CLOB;
    
    BEGIN
    
        g_error := 'GET EXAM RESULT DESCRIPTION. i_id_exam_result: ' || i_id_exam_result;
        SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || erd.id_exam, NULL) desc_exam,
               pk_exam_utils.get_exam_result_notes(i_lang,
                                                   i_prof,
                                                   NULL,
                                                   pk_exam_constant.g_yes,
                                                   eres.id_epis_documentation) interpretation,
               eres.dt_exam_result_tstz dt_exam_result,
               pk_translation.get_translation(i_lang,
                                              'RESULT_STATUS.SHORT_CODE_RESULT_STATUS.' || eres.id_result_status) result_status,
               erd.start_time exec_date,
               CASE
                    WHEN eres.notes_result IS NOT NULL
                         AND dbms_lob.compare(eres.notes_result, empty_clob()) != 0 THEN
                     chr(10) || pk_message.get_message(i_lang, 'EXAMS_T228') || ' ' || eres.notes_result
                    ELSE
                     NULL
                END notes_result,
               decode(eres.id_result_notes,
                      NULL,
                      NULL,
                      chr(10) || pk_message.get_message(i_lang, 'EXAMS_T226') || ' ' ||
                      pk_translation.get_translation(i_lang, 'RESULT_NOTES.CODE_RESULT_NOTES.' || eres.id_result_notes)) result_notes,
               er.dt_req_tstz req_date,
               pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || er.id_institution) inst_name
          INTO l_desc_exam,
               o_interpretation,
               l_dt_exam_result,
               l_result,
               l_exec_date,
               o_notes_result,
               o_result_notes,
               l_req_date,
               o_inst_name
          FROM exam_result eres
          JOIN exam_req_det erd
            ON erd.id_exam_req_det = eres.id_exam_req_det
          JOIN exam_req er
            ON er.id_exam_req = erd.id_exam_req
         WHERE eres.id_exam_result = i_id_exam_result;
    
        o_exec_date   := l_exec_date;
        o_report_date := l_req_date;
        o_result      := l_result;
        o_result_date := l_dt_exam_result;
        o_exam_desc   := l_desc_exam;
    
        g_error := 'INTERNAL DESCRIPTIONS';
        IF l_dt_exam_result IS NOT NULL
        THEN
            l_intern_desc := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                         i_date => l_dt_exam_result,
                                                         i_inst => i_prof.institution,
                                                         i_soft => i_prof.software);
        END IF;
    
        IF l_result IS NOT NULL
        THEN
            l_intern_desc := l_intern_desc || CASE
                                 WHEN l_intern_desc IS NOT NULL THEN
                                  l_comma
                             END || l_result;
        END IF;
    
        g_error       := 'CONCAT DESCRIPTIONS';
        o_description := l_desc_exam || CASE
                             WHEN l_intern_desc IS NOT NULL THEN
                              l_comma || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M032') || l_space ||
                              pk_string_utils.surround(i_string  => l_intern_desc,
                                                       i_pattern => pk_string_utils.g_pattern_parenthesis)
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
                                              'GET_EXAM_RESULT_DESC',
                                              o_error);
            RETURN FALSE;
    END get_exam_result_desc;

    FUNCTION get_exam_status_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_status          OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET status. i_id_exam_req_det: ' || i_id_exam_req_det;
        pk_alertlog.log_debug(g_error);
        SELECT decode(erd.flg_referral,
                      pk_exam_constant.g_flg_referral_r,
                      pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_REFERRAL', erd.flg_referral, i_lang),
                      pk_exam_constant.g_flg_referral_s,
                      pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_REFERRAL', erd.flg_referral, i_lang),
                      pk_exam_constant.g_flg_referral_i,
                      pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_REFERRAL', erd.flg_referral, i_lang),
                      decode(erd.flg_status,
                             pk_exam_constant.g_exam_sos,
                             pk_sysdomain.get_domain(i_lang,
                                                     i_prof,
                                                     'EXAM_REQ_DET.FLG_STATUS',
                                                     pk_exam_constant.g_exam_req,
                                                     NULL),
                             pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.FLG_STATUS', erd.flg_status, NULL)))
          INTO o_status
          FROM exam_req_det erd
         WHERE erd.id_exam_req_det = i_id_exam_req_det;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_status := to_clob('');
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_STATUS_DESC',
                                              o_error);
            RETURN FALSE;
    END get_exam_status_desc;

    FUNCTION is_exam_recurr_finished
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN exam_req_det.id_order_recurrence%TYPE
    ) RETURN VARCHAR2 IS
    
        l_found VARCHAR2(1 CHAR);
    
    BEGIN
    
        SELECT DISTINCT 'N'
          INTO l_found
          FROM exam_req_det erd
         WHERE erd.id_order_recurrence = i_order_recurrence
           AND erd.flg_status NOT IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read);
    
        RETURN l_found;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 'Y';
    END is_exam_recurr_finished;

    PROCEDURE hand_off__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_by_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN exam.flg_type%TYPE,
        o_exam     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        g_error := 'OPEN O_EXAM';
        OPEN o_exam FOR
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_exam) AS table_varchar), '; ') desc_exam, t.flg_status
              FROM (SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) ||
                           decode(eea.flg_status_det,
                                  pk_exam_constant.g_exam_req,
                                  NULL,
                                  '(' ||
                                  pk_date_utils.date_char_tsz(i_lang, eea.dt_begin, i_prof.institution, i_prof.software) || ')') desc_exam,
                           eea.flg_status_det flg_status,
                           pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det) rank
                      FROM exams_ea eea
                     WHERE eea.id_visit = l_visit
                       AND eea.flg_type = i_flg_type
                       AND eea.flg_status_det IN (pk_exam_constant.g_exam_pending, pk_exam_constant.g_exam_req)) t
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
                                              'GET_EXAM_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            RETURN FALSE;
    END get_exam_by_status;

    PROCEDURE discharge_summary____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_technical_exam
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_technical exam.flg_technical%TYPE;
    
    BEGIN
    
        SELECT e.flg_technical
          INTO l_flg_technical
          FROM exam e
         INNER JOIN exam_req_det erd
            ON erd.id_exam = e.id_exam
         WHERE erd.id_exam_req_det = i_exam_req_det;
    
        RETURN l_flg_technical;
    
    END check_technical_exam;

    FUNCTION get_exam_exec_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_exec_date VARCHAR2(50);
    
    BEGIN
    
        SELECT pk_date_utils.date_char_tsz(i_lang, erd.dt_performed_reg, i_prof.institution, i_prof.software)
          INTO l_exec_date
          FROM exam_req_det erd
         WHERE erd.id_exam_req_det = i_exam_req_det;
    
        RETURN l_exec_date;
    
    END get_exam_exec_date;

    PROCEDURE flowsheets________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_flowsheets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_coll_mcdt_flowsheets IS
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        l_exam t_coll_mcdt_flowsheets;
    
        l_error t_error_out;
    
    BEGIN
    
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
                                              o_error      => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' l_id_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' l_id_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' l_id_episode = ' || coalesce(to_char(l_id_episode), '<null>');
    
        WITH epis_w AS
         (SELECT e.id_episode
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
             AND i_type_scope = pk_alert_constant.g_scope_type_visit)
        SELECT t_rec_mcdt_flowsheets(t.id,
                                     t.id_content,
                                     pk_exam_utils.get_alias_translation(i_lang,
                                                                         i_prof,
                                                                         'EXAM.CODE_EXAM.' || t.id_exam,
                                                                         NULL),
                                     t.flg_status)
          BULK COLLECT
          INTO l_exam
          FROM (SELECT eea.id_exam id,
                       e.id_content,
                       eea.id_exam,
                       eea.flg_status_det flg_status,
                       coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) dt_value,
                       eea.id_episode id_episode,
                       (SELECT pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det)
                          FROM dual) rank
                  FROM exams_ea eea
                 INNER JOIN exam_req er
                    ON er.id_exam_req = eea.id_exam_req
                 INNER JOIN exam_req_det erd
                    ON erd.id_exam_req_det = eea.id_exam_req_det
                 INNER JOIN exam e
                    ON e.id_exam = eea.id_exam
                  JOIN epis_w epi
                    ON epi.id_episode = eea.id_episode
                 WHERE eea.flg_status_det NOT IN (pk_exam_constant.g_exam_cancel)
                UNION
                SELECT eea.id_exam id,
                       e.id_content,
                       eea.id_exam,
                       eea.flg_status_det flg_status,
                       coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) dt_value,
                       eea.id_episode_origin id_episode,
                       (SELECT pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det)
                          FROM dual) rank
                  FROM exams_ea eea
                 INNER JOIN exam_req er
                    ON er.id_exam_req = eea.id_exam_req
                 INNER JOIN exam_req_det erd
                    ON erd.id_exam_req_det = eea.id_exam_req_det
                 INNER JOIN exam e
                    ON e.id_exam = eea.id_exam
                  JOIN epis_w epi
                    ON epi.id_episode = eea.id_episode_origin
                 WHERE eea.flg_status_det != pk_exam_constant.g_exam_cancel
                 ORDER BY rank, dt_value DESC) t;
    
        RETURN l_exam;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_FLOWSHEETS',
                                              l_error);
            RETURN NULL;
    END get_exam_flowsheets;

    PROCEDURE scheduler_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_exam_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req      IN exam_req.id_exam_req%TYPE,
        i_status        IN exam_req.flg_status%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status exam_req.flg_status%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_status := CASE i_status
                        WHEN pk_exam_constant.g_exam_efectiv THEN
                         pk_exam_constant.g_exam_pending
                        ELSE
                         i_status
                    END;
    
        IF l_status = pk_exam_constant.g_exam_cancel
        THEN
            g_error := 'CALL PK_EXAM_CORE.CANCEL_EXAM_ORDER';
            IF NOT pk_exam_core.cancel_exam_order(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_exam_req      => table_number(i_exam_req),
                                                  i_cancel_reason => i_cancel_reason,
                                                  i_cancel_notes  => NULL,
                                                  i_prof_order    => NULL,
                                                  i_dt_order      => NULL,
                                                  i_order_type    => NULL,
                                                  o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            FOR rec IN (SELECT erd.id_exam_req_det, erd.id_exam
                          FROM exam_req_det erd
                         WHERE erd.id_exam_req = i_exam_req)
            LOOP
                g_error := 'CALL PK_EXAM_CORE.SET_EXAM_STATUS';
                IF NOT pk_exam_core.set_exam_status(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_exam_req_det    => table_number(rec.id_exam_req_det),
                                               i_status          => l_status,
                                               i_notes           => CASE
                                                                        WHEN i_cancel_reason IS NULL THEN
                                                                         NULL
                                                                        ELSE
                                                                         table_varchar(pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                                               i_prof             => i_prof,
                                                                                                                               i_id_cancel_reason => i_cancel_reason))
                                                                    END,
                                               i_notes_scheduler => NULL,
                                               o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF l_status = pk_exam_constant.g_exam_nr
                THEN
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULE';
                    IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang                 => i_lang,
                                                                    i_prof                 => i_prof,
                                                                    i_id_exam              => rec.id_exam,
                                                                    i_id_exam_req          => i_exam_req,
                                                                    i_id_sch_cancel_reason => 9,
                                                                    i_cancel_notes         => NULL,
                                                                    o_error                => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        pk_schedule_api_upstream.do_commit(i_prof => i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_STATUS',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_status;

    FUNCTION get_exam_search
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_market         IN market.id_market%TYPE,
        i_pat_search_values IN pk_utils.hashtable_pls_integer,
        i_ids_content       IN table_varchar,
        i_min_date          IN VARCHAR2,
        i_max_date          IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_ids_prof          IN table_number,
        i_ids_exam_cat      IN table_number,
        i_priorities        IN table_varchar,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_ids_exam NUMBER := CASE
                                       WHEN i_ids_content IS NULL THEN
                                        0
                                       ELSE
                                        i_ids_content.count
                                   END;
        l_count_ids_profs NUMBER := CASE
                                        WHEN i_ids_prof IS NULL THEN
                                         0
                                        ELSE
                                         i_ids_prof.count
                                    END;
        l_count_ids_exam_cat NUMBER := CASE
                                           WHEN i_ids_exam_cat IS NULL THEN
                                            0
                                           ELSE
                                            i_ids_exam_cat.count
                                       END;
        l_count_priorities NUMBER := CASE
                                         WHEN i_priorities IS NULL THEN
                                          0
                                         ELSE
                                          i_priorities.count
                                     END;
        l_min_date           TIMESTAMP WITH TIME ZONE;
        l_max_date           TIMESTAMP WITH TIME ZONE;
        l_all_patients       VARCHAR2(1);
    
    BEGIN
    
        -- SEARCH PATIENTS
        g_error := 'SEARCH PATIENTS';
        IF NOT pk_patient.search_patients(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_id_market     => i_id_market,
                                          i_search_values => i_pat_search_values,
                                          o_all_patients  => l_all_patients,
                                          o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        pk_date_utils.set_dst_time_check_off;
    
        -- converter min date
        g_error := 'CALL GET_STRING_TSTZ FOR I_MIN_DATE';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_min_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_min_date,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RAISE g_other_exception;
        END IF;
    
        -- converter max date
        g_error := 'CALL GET_STRING_TSTZ FOR I_MAX_DATE';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_max_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_max_date,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RAISE g_other_exception;
        END IF;
    
        -- output
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT er.id_exam_req id_req,
                   er.id_patient,
                   er.id_episode,
                   pat.name,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_prof_req) prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, erd.id_prof_performed) prof_performed,
                   er.dt_schedule_tstz date_target,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) exam_name,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          dcs.id_clinical_service)
                      FROM exam_cat_dcs ecd
                      JOIN dep_clin_serv dcs
                        ON ecd.id_dep_clin_serv = dcs.id_dep_clin_serv
                      JOIN department dep
                        ON dcs.id_department = dep.id_department
                     WHERE dep.id_department = dcs.id_department
                       AND ecd.id_exam_cat = e.id_exam_cat
                       AND dep.id_institution = er.id_institution
                       AND rownum = 1) clinical_service_name,
                   er.dt_req_tstz date_requested,
                   erd.notes,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.FLG_STATUS', erd.flg_status, NULL) req_det_status,
                   erd.id_room,
                   nvl((SELECT r.desc_room
                         FROM room r
                        WHERE r.id_room = erd.id_room),
                       pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || erd.id_room)) room_name,
                   er.priority,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.PRIORITY', er.priority, NULL) priority_name,
                   CASE
                        WHEN er.id_cancel_reason IS NOT NULL THEN
                         pk_translation.get_translation(i_lang,
                                                        'CANCEL_REASON.CODE_CANCEL_REASON.' || er.id_cancel_reason)
                        ELSE
                         NULL
                    END cancel_reason_name,
                   pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || e.id_exam_cat) exam_cat_name
              FROM exam_req er
              JOIN exam_req_det erd
                ON er.id_exam_req = erd.id_exam_req
              JOIN patient pat
                ON er.id_patient = pat.id_patient
              JOIN exam e
                ON erd.id_exam = e.id_exam
             WHERE
            -- status. se existe um cancel reason ignora o status. se nao foi entao so' considera reqs por agendar
             ((i_id_cancel_reason IS NOT NULL AND
             (erd.id_cancel_reason = i_id_cancel_reason OR er.id_cancel_reason = i_id_cancel_reason)) OR
             er.flg_status IN (pk_exam_constant.g_exam_req, pk_exam_constant.g_exam_tosched) AND
             erd.flg_status IN (pk_exam_constant.g_exam_req, pk_exam_constant.g_exam_tosched))
            -- so interessa os que sao para agendar 
             AND er.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
            -- pacientes
             AND (l_all_patients = pk_alert_constant.g_yes OR EXISTS
              (SELECT 1
                 FROM pat_tmptab_search tm
                WHERE tm.id_patient = er.id_patient))
            -- exames
             AND (l_count_ids_exam = 0 OR
             e.id_content IN (SELECT column_value
                                 FROM TABLE(i_ids_content)))
            -- prof que requisitou
             AND (l_count_ids_profs = 0 OR
             er.id_prof_req IN (SELECT column_value
                                   FROM TABLE(i_ids_prof)))
            -- exam cats
             AND (l_count_ids_exam_cat = 0 OR
             e.id_exam_cat IN (SELECT column_value
                                  FROM TABLE(i_ids_exam_cat)))
            -- priorities
             AND (l_count_priorities = 0 OR
             er.priority IN (SELECT column_value
                                FROM TABLE(i_priorities)))
            -- datas
             AND (l_min_date IS NULL OR (er.dt_schedule_tstz IS NOT NULL AND er.dt_schedule_tstz >= l_min_date))
             AND (l_max_date IS NULL OR (er.dt_schedule_tstz IS NOT NULL AND er.dt_schedule_tstz <= l_max_date));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_SEARCH',
                                              o_error);
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_search;

    FUNCTION get_exam_request_to_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN table_number,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_flg_type      IN exam.flg_type%TYPE DEFAULT NULL,
        i_id_content    IN exam.id_content%TYPE DEFAULT NULL,
        i_id_department IN room.id_department%TYPE DEFAULT NULL,
        i_pat_age_min   IN patient.age%TYPE DEFAULT NULL,
        i_pat_age_max   IN patient.age%TYPE DEFAULT NULL,
        i_pat_gender    IN patient.gender%TYPE DEFAULT NULL,
        i_start         IN NUMBER DEFAULT NULL,
        i_offset        IN NUMBER DEFAULT NULL,
        o_list          OUT pk_exam_external.t_cur_exam_to_schedule,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start NUMBER(24) := 1;
        l_end   NUMBER(24) := 99999999999999999999;
    
        l_pat_age_min patient.age%TYPE;
        l_pat_age_max patient.age%TYPE;
    
    BEGIN
    
        IF i_flg_type IS NOT NULL
           AND i_flg_type NOT IN ('I', 'E')
        THEN
            g_error := 'UNDEFINED TYPE: ' || i_flg_type;
            RAISE g_other_exception;
        END IF;
    
        IF i_institution.count = 0
        THEN
            g_error := 'INSTITUTION LIST IS NULL';
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
            SELECT exm.id_patient,
                   NULL                                           id_dep_clin_serv,
                   exm.id_service,
                   NULL                                           id_speciality,
                   exm.id_content,
                   pk_schedule_api_downstream.g_proc_req_type_req flg_type,
                   exm.id_requisition,
                   exm.dt_creation,
                   exm.id_user_creation,
                   exm.id_institution,
                   exm.id_resource,
                   pk_schedule_api_downstream.g_proc_req_type_req type_resource,
                   exm.dt_sugested,
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
                   exm.total
              FROM (SELECT aux.*, rownum rn, COUNT(*) over() total
                      FROM (SELECT DISTINCT er.id_patient,
                                            r.id_department id_service,
                                            e.id_content,
                                            erd.id_exam_req_det id_requisition,
                                            er.dt_req_tstz dt_creation,
                                            er.id_prof_req id_user_creation,
                                            er.id_institution,
                                            erd.id_room id_resource,
                                            er.dt_schedule_tstz dt_sugested,
                                            nvl(pk_patient.get_pat_age(i_age         => p.age,
                                                                       i_age_format  => 'YEARS',
                                                                       i_dt_birth    => p.dt_birth,
                                                                       i_dt_deceased => p.dt_deceased,
                                                                       i_lang        => i_lang,
                                                                       i_patient     => p.id_patient),
                                                0) age,
                                            p.gender
                              FROM exam_req_det erd
                             INNER JOIN exam e
                                ON e.id_exam = erd.id_exam
                             INNER JOIN exam_req er
                                ON er.id_exam_req = erd.id_exam_req
                             INNER JOIN patient p
                                ON p.id_patient = er.id_patient
                              LEFT OUTER JOIN room r
                                ON r.id_room = erd.id_room
                             WHERE er.dt_begin_tstz IS NULL
                               AND er.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                          column_value
                                                           FROM TABLE(i_institution) t)
                               AND erd.flg_status = pk_exam_constant.g_exam_tosched
                               AND (r.id_department = i_id_department OR i_id_department IS NULL)
                               AND (e.id_content = i_id_content OR i_id_content IS NULL)
                               AND (e.flg_type = i_flg_type OR i_flg_type IS NULL)) aux
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
                     ORDER BY aux.dt_creation ASC) exm
             WHERE exm.rn BETWEEN l_start AND l_end;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_REQUEST_TO_SCHEDULE',
                                              o_error);
            RETURN FALSE;
    END get_exam_request_to_schedule;

    PROCEDURE viewer___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION e_get_order_rank
    (
        i_flg_status        IN exam_req_det.flg_status%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE,
        i_id_episode_origin IN exam_req.id_episode_origin%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF (i_flg_status = 'L')
        THEN
            --  results read
            l_rank := 12;
        ELSIF (i_flg_status = 'F' OR i_flg_status = 'L')
        THEN
            -- results or read in episode
            l_rank := 1;
        ELSIF (i_flg_status = 'E')
        THEN
            -- executing
            l_rank := 7;
        ELSIF (i_flg_status IN ('PA', 'A', 'EF'))
        THEN
            -- to be scheduled, scheduled and registered
            l_rank := 1;
        ELSIF (i_dt_begin IS NOT NULL)
        THEN
            IF (i_dt_begin > g_sysdate_tstz)
            THEN
                --l_rank ADVANCED
                l_rank := 4;
            ELSE
                -- DELAYED
                l_rank := 2;
            END IF;
        ELSIF (i_id_episode_origin IS NOT NULL)
        THEN
            --we're currently on the "next" episode, but the item is not meant to be performed on this episode
            IF (i_flg_time IS NOT NULL AND i_flg_time != 'E')
            THEN
                --FUTURE SCHEDULED
                l_rank := 5;
            ELSE
                --we're currently on the "next" episode, but the item is meant to be performed on this episode
                -- PAST SCHEDULED
                l_rank := 3;
            END IF;
        ELSE
            -- caso especial do C. Saude, em que um pedido de exame não ?agendado e passa logo a pendente
            IF (i_flg_status = 'D' AND i_flg_time = 'B' AND i_dt_begin IS NULL)
            THEN
                l_rank := 1;
            ELSE
                -- FUTURE SCHEDULED
                l_rank := 5;
            END IF;
        END IF;
    
        RETURN l_rank;
    
    END e_get_order_rank;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_records t_table_rec_gen_area_rank_tmp;
    
        l_viewer_lim_tasktime_exam sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_EXAM', i_prof);
    
        l_episode table_number;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T202');
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_episode;
        FETCH c_episode BULK COLLECT
            INTO l_episode;
    
        --insert in temporary table
        g_error := 'INSERT ON TEMP TABLE';
        SELECT t_rec_gen_area_rank_tmp(t.flg_referral,
                                       t.flg_status,
                                       t.flg_time,
                                       t.code_exam,
                                       t.flg_type,
                                       t.status_str,
                                       t.status_msg,
                                       t.status_icon,
                                       t.status_flg,
                                       t.varch10,
                                       t.varch11,
                                       t.varch12,
                                       t.varch13,
                                       t.varch14,
                                       t.varch15,
                                       t.id_episode_origin,
                                       t.id,
                                       t.numb3,
                                       t.numb4,
                                       t.numb5,
                                       t.numb6,
                                       t.numb7,
                                       t.numb8,
                                       t.numb9,
                                       t.numb10,
                                       t.numb11,
                                       t.numb12,
                                       t.numb13,
                                       t.numb14,
                                       t.numb15,
                                       t.dt_begin,
                                       t.dt_req,
                                       t.currdate,
                                       t.dt_tstz4,
                                       t.dt_tstz5,
                                       t.dt_tstz6,
                                       t.dt_tstz7,
                                       t.dt_tstz8,
                                       t.dt_tstz9,
                                       t.dt_tstz10,
                                       t.dt_tstz11,
                                       t.dt_tstz12,
                                       t.dt_tstz13,
                                       t.dt_tstz14,
                                       t.dt_tstz15,
                                       t.rank)
          BULK COLLECT
          INTO l_records
          FROM (SELECT eea.flg_referral flg_referral,
                       eea.flg_status_det flg_status,
                       eea.flg_time flg_time,
                       'EXAM.CODE_EXAM.' || eea.id_exam code_exam,
                       eea.flg_type flg_type,
                       eea.status_str,
                       eea.status_msg,
                       eea.status_icon,
                       eea.status_flg,
                       NULL varch10,
                       NULL varch11,
                       NULL varch12,
                       NULL varch13,
                       NULL varch14,
                       NULL varch15,
                       eea.id_episode_origin id_episode_origin,
                       eea.id_exam_req_det id,
                       NULL numb3,
                       NULL numb4,
                       NULL numb5,
                       NULL numb6,
                       NULL numb7,
                       NULL numb8,
                       NULL numb9,
                       NULL numb10,
                       NULL numb11,
                       NULL numb12,
                       NULL numb13,
                       NULL numb14,
                       NULL numb15,
                       nvl(eea.dt_pend_req, eea.dt_begin) dt_begin,
                       eea.dt_req dt_req,
                       g_sysdate_tstz currdate,
                       eea.dt_result dt_tstz4,
                       NULL dt_tstz5,
                       NULL dt_tstz6,
                       NULL dt_tstz7,
                       NULL dt_tstz8,
                       NULL dt_tstz9,
                       NULL dt_tstz10,
                       NULL dt_tstz11,
                       NULL dt_tstz12,
                       NULL dt_tstz13,
                       NULL dt_tstz14,
                       NULL dt_tstz15,
                       decode(eea.flg_status_det,
                              pk_exam_constant.g_exam_result,
                              0,
                              pk_exam_constant.g_exam_req,
                              row_number()
                              over(ORDER BY
                                   decode(eea.flg_referral,
                                          NULL,
                                          pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                                          pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral)),
                                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                              pk_exam_constant.g_exam_pending,
                              row_number()
                              over(ORDER BY
                                   decode(eea.flg_referral,
                                          NULL,
                                          pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                                          pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral)),
                                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                              row_number()
                              over(ORDER BY
                                   decode(eea.flg_referral,
                                          NULL,
                                          pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                                          pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral)),
                                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)) rank
                  FROM exams_ea eea
                 WHERE eea.id_patient = i_patient
                   AND eea.flg_status_det NOT IN (pk_exam_constant.g_exam_draft, pk_exam_constant.g_exam_cancel)
                   AND ((i_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                       eea.flg_status_det IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read)) OR
                       (i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                       eea.flg_status_det NOT IN (pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel) AND
                       (eea.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                              *
                                               FROM TABLE(l_episode) t) OR eea.id_episode IS NULL)))
                   AND trunc(months_between(SYSDATE, eea.dt_req) / 12) <= l_viewer_lim_tasktime_exam) t;
    
        g_error := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT /*+opt_estimate(table gart rows=1)*/
             gart.numb2 id,
             gart.varch4 code_description,
             decode(i_translate,
                    pk_exam_constant.g_no,
                    NULL,
                    pk_exams_api_db.get_alias_translation(i_lang, i_prof, gart.varch4, NULL)) description,
             decode(i_translate,
                    pk_exam_constant.g_no,
                    NULL,
                    pk_sysdomain.get_domain('EXAM.FLG_TYPE', gart.varch5, i_lang)) title,
             nvl(gart.dt_tstz4, nvl(gart.dt_tstz1, gart.dt_tstz2)) dt_req_tstz,
             pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(gart.dt_tstz4, nvl(gart.dt_tstz1, gart.dt_tstz2)), i_prof) dt_req,
             gart.varch2 flg_status,
             gart.varch5 flg_type,
             pk_utils.get_status_string(i_lang, i_prof, gart.varch6, gart.varch7, gart.varch8, gart.varch9) desc_status,
             gart.rank rank,
             gart.numb4 rank_order,
             COUNT(0) over() num_count,
             l_task_title task_title
              FROM TABLE(l_records) gart
             ORDER BY rank ASC, (numb3 * numb4) ASC, numb2 DESC;
    
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
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_ORDERED_LIST_DET';
        OPEN o_ordered_list_det FOR
            SELECT nvl(pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL),
                       'EXAM.CODE_EXAM.' || eea.id_exam) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, eea.id_prof_req, eea.dt_req, eea.id_episode) prof_spec_reg,
                   eea.flg_time,
                   eea.dt_req dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eea.dt_req, i_prof) dt_req,
                   eea.dt_begin dt_begin_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eea.dt_begin, i_prof) dt_begin,
                   eea.dt_pend_req dt_pend_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eea.dt_pend_req, i_prof) dt_pend_req,
                   eea.flg_status_det flg_status,
                   eea.flg_referral,
                   decode(eea.flg_referral,
                          pk_lab_tests_constant.g_flg_referral_s,
                          pk_sysdomain.get_img(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                          pk_lab_tests_constant.g_flg_referral_r,
                          pk_sysdomain.get_img(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                          pk_sysdomain.get_img(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det)) icon_name,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || er.id_institution) institution,
                   eea.id_episode_origin
              FROM exams_ea eea, exam_req er
             WHERE eea.id_exam_req_det = i_exam_req_det
               AND eea.id_exam_req = er.id_exam_req;
    
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
    
        l_list  pk_types.cursor_type;
        l_count NUMBER := 0;
        l_str   VARCHAR2(4000);
    
        l_task_title sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'GET ORDERED LIST';
        IF get_ordered_list(i_lang, i_prof, i_patient, pk_exam_constant.g_no, i_viewer_area, i_episode, l_list, o_error)
        THEN
            FETCH l_list
                INTO l_str,
                     o_code_first,
                     o_desc_first,
                     o_dt_first,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_count,
                     l_task_title;
        
            o_num_occur := l_count;
        
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

    /*
    *  Get current state of imaging exams for viewer checlist 
    *             
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope_type   Scope flag: 'P' - Patient; 'E' - Episode; 'V' - Visit
    * @param     i_episode      Episode id
    * @param     i_patient      Patient id
    *
    * @return    String
    * 
    * @author    Ana Matos
    * @version   2.7.0
    * @since     2016/10/27                         
    */

    FUNCTION get_imaging_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_VIEWER_CHECKLIST';
        RETURN pk_exam_external.get_exam_viewer_checklist(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_patient    => i_patient,
                                                          i_episode    => i_episode,
                                                          i_flg_type   => pk_exam_constant.g_type_img,
                                                          i_scope_type => i_scope_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_imaging_viewer_checklist;

    FUNCTION get_exams_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_VIEWER_CHECKLIST';
        RETURN pk_exam_external.get_exam_viewer_checklist(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_patient    => i_patient,
                                                          i_episode    => i_episode,
                                                          i_flg_type   => pk_exam_constant.g_type_exm,
                                                          i_scope_type => i_scope_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_exams_viewer_checklist;

    FUNCTION get_exam_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN exam.flg_type%TYPE,
        i_scope_type IN VARCHAR2
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
          FROM exams_ea eea
         WHERE eea.flg_type = i_flg_type
           AND eea.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND eea.flg_time = pk_exam_constant.g_flg_time_e
           AND eea.flg_status_det NOT IN (pk_exam_constant.g_exam_exterior,
                                          pk_exam_constant.g_exam_cancel,
                                          pk_exam_constant.g_exam_predefined,
                                          pk_exam_constant.g_exam_draft);
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM exams_ea eea
             WHERE eea.flg_type = i_flg_type
               AND eea.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND eea.flg_time = pk_exam_constant.g_flg_time_e
               AND eea.flg_status_det NOT IN (pk_exam_constant.g_exam_result,
                                              pk_exam_constant.g_exam_read,
                                              pk_exam_constant.g_exam_exterior,
                                              pk_exam_constant.g_exam_cancel,
                                              pk_exam_constant.g_exam_predefined,
                                              pk_exam_constant.g_exam_draft);
        
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
    END get_exam_viewer_checklist;

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
               SET num_exam  = l_num_occur(i),
                   desc_exam = l_desc_first(i),
                   dt_exam   = l_dt_first(i),
                   code_exam = l_code_first(i)
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

    PROCEDURE cda______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_exam_cda   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name pk_types.t_internal_name_byte := 'GET_EXAM_CDA';
    
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
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Call pk_touch_option.get_scope_vars';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
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
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        OPEN o_exam_cda FOR
            SELECT t.id,
                   t.id_content,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || t.id_exam, NULL) description,
                   t.flg_status,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.FLG_STATUS', t.flg_status, NULL) flg_status_desc,
                   t.dt_value,
                   t.flg_type,
                   pk_sysdomain.get_domain('EXAM.FLG_TYPE', t.flg_type, i_lang) flg_type_desc,
                   t.notes,
                   t.flg_laterality,
                   pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LATERALITY', t.flg_laterality, i_lang) flg_laterality_desc,
                   t.id_prof_performed,
                   t.id_inst_performed
              FROM (SELECT *
                      FROM (SELECT eea.id_exam_req id,
                                   e.id_content,
                                   eea.id_exam,
                                   eea.flg_status_det flg_status,
                                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) dt_value,
                                   eea.flg_type flg_type,
                                   eea.notes,
                                   erd.flg_laterality,
                                   eea.id_prof_req id_prof_performed,
                                   er.id_institution id_inst_performed,
                                   nvl(eea.id_episode, eea.id_episode_origin) id_episode,
                                   pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det) rank
                              FROM exams_ea eea
                             INNER JOIN exam_req er
                                ON er.id_exam_req = eea.id_exam_req
                             INNER JOIN exam_req_det erd
                                ON erd.id_exam_req_det = eea.id_exam_req_det
                             INNER JOIN exam e
                                ON e.id_exam = eea.id_exam
                             WHERE eea.flg_status_det NOT IN
                                   (pk_exam_constant.g_exam_exec,
                                    pk_exam_constant.g_exam_result,
                                    pk_exam_constant.g_exam_read,
                                    pk_exam_constant.g_exam_cancel,
                                    pk_exam_constant.g_exam_toexec,
                                    pk_exam_constant.g_exam_predefined)) exam
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
                        ON epi.id_episode = exam.id_episode
                     ORDER BY rank, dt_value DESC) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_exam_cda);
            RETURN FALSE;
    END get_exam_cda;

    PROCEDURE crisis_machine_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION tf_cm_imaging_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
        l_tbl_cm_episodes t_tbl_cm_episodes;
    
        l_prof_cat_type category.flg_type%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + i_search_interval;
    
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
    
        SELECT t_rec_cm_episodes(t.id_episode,
                                 t.id_patient,
                                 t.id_schedule,
                                 MAX(t.dt_target),
                                 t.dt_last_interaction_tstz,
                                 t.id_software)
          BULK COLLECT
          INTO l_tbl_cm_episodes
          FROM (SELECT gti.id_episode,
                       gti.id_patient,
                       NULL                             id_schedule,
                       gti.dt_begin_tstz                dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_imgtech id_software
                  FROM grid_task_img gti, epis_info ei
                 WHERE ((gti.flg_time_req = pk_exam_constant.g_flg_time_e AND
                       gti.flg_status_epis NOT IN
                       (pk_alert_constant.g_epis_status_inactive, pk_alert_constant.g_epis_status_cancel)) OR
                       gti.flg_time_req IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d) AND
                       gti.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end AND
                       gti.flg_status_req_det NOT IN (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched) OR
                       (gti.flg_time_req = pk_exam_constant.g_flg_time_n AND gti.id_episode IS NOT NULL AND
                       gti.flg_status_req_det != pk_exam_constant.g_exam_pending))
                   AND (gti.id_institution = i_prof.institution OR
                       (gti.id_institution != i_prof.institution AND EXISTS
                        (SELECT 1
                            FROM transfer_institution ti
                           WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                             AND ti.id_episode = gti.id_episode
                             AND ti.id_institution_dest = i_prof.institution)))
                   AND instr(nvl((SELECT flg_first_result
                                   FROM exam_dep_clin_serv e
                                  WHERE e.id_exam = gti.id_exam
                                    AND e.flg_type = pk_exam_constant.g_exam_can_req
                                    AND e.id_software = gti.id_software
                                    AND e.id_institution = i_prof.institution),
                                 '#'),
                             l_prof_cat_type) != 0
                   AND gti.id_episode = ei.id_episode
                UNION
                SELECT gti.id_episode,
                       gti.id_patient,
                       NULL                             id_schedule,
                       gti.dt_begin_tstz                dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_imgtech id_software
                  FROM grid_task_img gti, episode e, epis_info ei
                 WHERE (gti.flg_time_req = pk_exam_constant.g_flg_time_e AND
                       gti.flg_status_epis = pk_alert_constant.g_epis_status_inactive)
                   AND (gti.id_institution = i_prof.institution OR
                       (gti.id_institution != i_prof.institution AND EXISTS
                        (SELECT 1
                            FROM transfer_institution ti
                           WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                             AND ti.id_episode = gti.id_episode
                             AND ti.id_institution_dest = i_prof.institution)))
                   AND instr(nvl((SELECT flg_first_result
                                   FROM exam_dep_clin_serv e
                                  WHERE e.id_exam = gti.id_exam
                                    AND e.flg_type = pk_exam_constant.g_exam_can_req
                                    AND e.id_software = gti.id_software
                                    AND e.id_institution = i_prof.institution),
                                 '#'),
                             l_prof_cat_type) != 0
                   AND gti.id_episode = e.id_prev_episode
                   AND gti.id_episode = ei.id_episode
                UNION
                SELECT gti.id_episode,
                       gti.id_patient,
                       se.id_schedule,
                       gti.dt_begin_tstz                dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_imgtech id_software
                  FROM grid_task_img gti, schedule_exam se, schedule s, epis_info ei
                 WHERE gti.id_institution = i_prof.institution
                   AND gti.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
                   AND (gti.flg_time_req IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d) OR
                       (gti.flg_time_req = pk_exam_constant.g_flg_time_e AND
                       (gti.id_episode IS NULL OR gti.id_epis_type = pk_exam_constant.g_episode_type_rad)))
                   AND gti.flg_status_req_det != pk_exam_constant.g_exam_wtg_tde
                   AND gti.id_exam_req = se.id_exam_req
                   AND se.id_schedule = s.id_schedule
                   AND s.flg_status != pk_alert_constant.g_flg_status_c
                   AND gti.id_episode = ei.id_episode(+)) t
         GROUP BY t.id_episode, t.id_patient, t.id_schedule, t.dt_last_interaction_tstz, t.id_software;
    
        RETURN l_tbl_cm_episodes;
    
    END tf_cm_imaging_episodes;

    FUNCTION tf_cm_imaging_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_imaging_episodes IS
    
        l_tbl_imaging_episodes t_tbl_imaging_episodes;
    
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
        SELECT t_rec_imaging_episodes(id_episode,
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
                                      desc_exam,
                                      flg_imaging_status,
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
          INTO l_tbl_imaging_episodes
          FROM (SELECT id_episode,
                       id_schedule,
                       id_epis_type origin,
                       pk_message.get_message(i_lang,
                                              profissional(i_prof.id, i_prof.institution, id_software),
                                              'IMAGE_T009') origin_desc,
                       pk_patient.get_patient_name(i_lang, id_patient) pat_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, id_patient, id_episode, NULL) pat_name_sort,
                       pat_age,
                       pk_patient.get_gender(i_lang, pat_gender) pat_gender,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, id_patient, id_episode, NULL) photo,
                       num_clin_record,
                       NULL name_prof_resp,
                       substr(concatenate_clob(pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || '; '),
                              1,
                              length(concatenate_clob(pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || '; ')) - 2) name_prof_req,
                       substr(concatenate_clob(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                     i_prof,
                                                                                     'EXAM.CODE_EXAM.' || id_exam,
                                                                                     NULL) || ' / '),
                              1,
                              length(concatenate_clob(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                            i_prof,
                                                                                            'EXAM.CODE_EXAM.' || id_exam,
                                                                                            NULL) || ' / ')) - 3) desc_exam,
                       flg_imaging_status,
                       NULL flg_status,
                       NULL flg_status_desc,
                       NULL flg_status_icon,
                       pk_date_utils.date_time_chr_tsz(i_lang, MAX(dt_begin_tstz), i_prof) dt_target,
                       pk_date_utils.date_send_tsz(i_lang, MAX(dt_begin_tstz), i_prof) dt_target_tstz,
                       pk_date_utils.date_send_tsz(i_lang, MAX(dt_begin_tstz), i_prof) dt_admission_tstz,
                       decode(flg_imaging_status,
                              'S',
                              decode(MAX(flg_status_req_det),
                                     pk_exam_constant.g_exam_sched,
                                     pk_sysdomain.get_rank(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_nr,
                                     pk_sysdomain.get_rank(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_pending,
                                     pk_sysdomain.get_rank(i_lang, 'ADMIN_SCH_EXAM', pk_exam_constant.g_waiting_technician),
                                     decode(flg_status_epis,
                                            pk_exam_constant.g_active,
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_exam_constant.g_in_technician),
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_exam_constant.g_end_technician))),
                              pk_date_utils.date_send_tsz(i_lang, MAX(dt_begin_tstz), i_prof)) epis_duration,
                       decode(flg_imaging_status,
                              'S',
                              decode(MAX(flg_status_req_det),
                                     pk_exam_constant.g_exam_sched,
                                     pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_nr,
                                     pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_pending,
                                     pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', pk_exam_constant.g_waiting_technician),
                                     decode(flg_status_epis,
                                            pk_exam_constant.g_active,
                                            pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', pk_exam_constant.g_in_technician),
                                            pk_sysdomain.get_img(i_lang,
                                                                 'ADMIN_SCH_EXAM',
                                                                 pk_exam_constant.g_end_technician))),
                              pk_date_utils.get_elapsed_time_tsz(i_lang, MAX(dt_begin_tstz))) epis_duration_desc,
                       rank_acuity,
                       acuity
                  FROM (SELECT DISTINCT decode(se.id_schedule, NULL, 'NS', 'S') flg_imaging_status,
                                        gti.id_patient,
                                        gti.id_episode,
                                        se.id_schedule,
                                        gti.id_epis_type,
                                        gti.id_software,
                                        gti.pat_age,
                                        gti.pat_gender,
                                        gti.num_clin_record,
                                        gti.id_exam,
                                        gti.id_professional,
                                        gti.dt_begin_tstz,
                                        gti.flg_status_req_det,
                                        gti.flg_status_epis,
                                        gti.rank_acuity,
                                        gti.acuity
                          FROM grid_task_img gti, schedule_exam se, schedule s
                         WHERE gti.id_episode = nvl(i_episode,
                                                    (SELECT MAX(id_episode)
                                                       FROM epis_info e
                                                      WHERE e.id_schedule = i_schedule))
                           AND gti.id_exam_req = se.id_exam_req(+)
                           AND se.id_schedule = s.id_schedule(+)
                           AND s.flg_status(+) != pk_alert_constant.g_flg_status_c)
                 GROUP BY flg_imaging_status,
                          id_patient,
                          id_episode,
                          id_schedule,
                          id_epis_type,
                          id_software,
                          pat_gender,
                          pat_age,
                          num_clin_record,
                          id_professional,
                          flg_status_epis,
                          rank_acuity,
                          acuity);
    
        RETURN l_tbl_imaging_episodes;
    
    END tf_cm_imaging_episode_detail;

    FUNCTION tf_cm_exams_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
        l_tbl_cm_episodes t_tbl_cm_episodes;
    
        l_prof_cat_type category.flg_type%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + i_search_interval;
    
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
    
        SELECT t_rec_cm_episodes(t.id_episode,
                                 t.id_patient,
                                 t.id_schedule,
                                 MAX(t.dt_target),
                                 t.dt_last_interaction_tstz,
                                 t.id_software)
          BULK COLLECT
          INTO l_tbl_cm_episodes
          FROM (SELECT gtoe.id_episode,
                       gtoe.id_patient,
                       NULL                            id_schedule,
                       gtoe.dt_begin_tstz              dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_extech id_software
                  FROM grid_task_oth_exm gtoe, exam_cat_dcs ecdcs, epis_info ei
                 WHERE gtoe.id_institution = i_prof.institution
                   AND ((gtoe.flg_time = pk_exam_constant.g_flg_time_e AND
                       pk_date_utils.trunc_insttimezone(i_prof, gtoe.dt_begin_tstz) <= l_dt_begin AND
                       gtoe.flg_status_epis NOT IN
                       (pk_alert_constant.g_epis_status_inactive, pk_alert_constant.g_epis_status_cancel)) OR
                       (gtoe.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d) AND
                       gtoe.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end AND
                       gtoe.flg_status_req_det NOT IN (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched)) OR
                       (gtoe.flg_time = pk_exam_constant.g_flg_time_n AND gtoe.id_episode IS NOT NULL AND
                       gtoe.flg_status_req_det != pk_exam_constant.g_exam_pending))
                   AND gtoe.id_exam_cat = ecdcs.id_exam_cat
                   AND gtoe.flg_status_req_det != pk_exam_constant.g_exam_wtg_tde
                   AND instr(nvl((SELECT flg_first_result
                                   FROM exam_dep_clin_serv e
                                  WHERE e.id_exam = gtoe.id_exam
                                    AND e.flg_type = pk_exam_constant.g_exam_can_req
                                    AND e.id_software = gtoe.id_software
                                    AND e.id_institution = i_prof.institution),
                                 '#'),
                             l_prof_cat_type) != 0
                   AND gtoe.id_episode = ei.id_episode
                   AND gtoe.id_announced_arrival IS NOT NULL
                UNION
                SELECT gtoe.id_episode,
                       gtoe.id_patient,
                       se.id_schedule,
                       gtoe.dt_begin_tstz              dt_target,
                       ei.dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_extech id_software
                  FROM grid_task_oth_exm gtoe, exam_cat_dcs ecdcs, schedule_exam se, schedule s, epis_info ei
                 WHERE gtoe.id_institution = i_prof.institution
                   AND gtoe.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end + INTERVAL '1'
                 DAY
                   AND (gtoe.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d) OR
                       (gtoe.flg_time = pk_exam_constant.g_flg_time_e AND
                       (gtoe.id_episode IS NULL OR gtoe.id_epis_type = pk_exam_constant.g_episode_type_exm)))
                   AND gtoe.id_exam_cat = ecdcs.id_exam_cat
                      -- exams requests with waiting's status don't appear for technician grid  
                   AND gtoe.flg_status_req_det NOT IN (pk_exam_constant.g_exam_wtg_tde)
                   AND gtoe.id_exam_req = se.id_exam_req
                   AND se.id_schedule = s.id_schedule
                   AND s.flg_status != pk_alert_constant.g_flg_status_c
                   AND gtoe.id_episode = ei.id_episode(+)) t
         GROUP BY t.id_episode, t.id_patient, t.id_schedule, t.dt_last_interaction_tstz, t.id_software;
    
        RETURN l_tbl_cm_episodes;
    
    END tf_cm_exams_episodes;

    FUNCTION tf_cm_exams_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_other_exams_episodes IS
    
        l_tbl_other_exams_episodes t_tbl_other_exams_episodes;
    
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
        SELECT t_rec_other_exams_episodes(id_episode,
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
                                          desc_exam,
                                          flg_exam_status,
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
          INTO l_tbl_other_exams_episodes
          FROM (SELECT id_episode,
                       id_schedule,
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
                       substr(concatenate_clob(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                     i_prof,
                                                                                     'EXAM.CODE_EXAM.' || id_exam,
                                                                                     NULL) || ' / '),
                              1,
                              length(concatenate_clob(pk_exams_api_db.get_alias_translation(i_lang,
                                                                                            i_prof,
                                                                                            'EXAM.CODE_EXAM.' || id_exam,
                                                                                            NULL) || ' / ')) - 3) desc_exam,
                       flg_exam_status,
                       NULL flg_status,
                       NULL flg_status_desc,
                       NULL flg_status_icon,
                       pk_date_utils.date_time_chr_tsz(i_lang, MAX(dt_begin_tstz), i_prof) dt_target,
                       pk_date_utils.date_send_tsz(i_lang, MAX(dt_begin_tstz), i_prof) dt_target_tstz,
                       pk_date_utils.date_send_tsz(i_lang, MAX(dt_begin_tstz), i_prof) dt_admission_tstz,
                       decode(flg_exam_status,
                              'S',
                              decode(MAX(flg_status_req_det),
                                     pk_exam_constant.g_exam_sched,
                                     pk_sysdomain.get_rank(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_nr,
                                     pk_sysdomain.get_rank(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_pending,
                                     pk_sysdomain.get_rank(i_lang, 'ADMIN_SCH_EXAM', pk_exam_constant.g_waiting_technician),
                                     decode(flg_status_epis,
                                            pk_exam_constant.g_active,
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_exam_constant.g_in_technician),
                                            pk_sysdomain.get_rank(i_lang,
                                                                  'ADMIN_SCH_EXAM',
                                                                  pk_exam_constant.g_end_technician))),
                              pk_date_utils.date_send_tsz(i_lang, MAX(dt_begin_tstz), i_prof)) epis_duration,
                       decode(flg_exam_status,
                              'S',
                              decode(MAX(flg_status_req_det),
                                     pk_exam_constant.g_exam_sched,
                                     pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_nr,
                                     pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', MAX(flg_status_req_det)),
                                     pk_exam_constant.g_exam_pending,
                                     pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', pk_exam_constant.g_waiting_technician),
                                     decode(flg_status_epis,
                                            pk_exam_constant.g_active,
                                            pk_sysdomain.get_img(i_lang, 'ADMIN_SCH_EXAM', pk_exam_constant.g_in_technician),
                                            pk_sysdomain.get_img(i_lang,
                                                                 'ADMIN_SCH_EXAM',
                                                                 pk_exam_constant.g_end_technician))),
                              pk_date_utils.get_elapsed_time_tsz(i_lang, MAX(dt_begin_tstz))) epis_duration_desc,
                       rank_acuity,
                       acuity
                  FROM (SELECT DISTINCT decode(se.id_schedule, NULL, 'NS', 'S') flg_exam_status,
                                        gtoe.id_patient,
                                        gtoe.id_episode,
                                        se.id_schedule,
                                        gtoe.id_epis_type,
                                        gtoe.id_software,
                                        gtoe.pat_age,
                                        gtoe.gender,
                                        gtoe.num_clin_record,
                                        gtoe.id_exam,
                                        gtoe.id_professional,
                                        gtoe.dt_begin_tstz,
                                        gtoe.flg_status_req_det,
                                        gtoe.flg_status_epis,
                                        gtoe.rank_acuity,
                                        gtoe.acuity
                          FROM grid_task_oth_exm gtoe, schedule_exam se, schedule s
                         WHERE gtoe.id_episode = nvl(i_episode,
                                                     (SELECT MAX(id_episode)
                                                        FROM epis_info e
                                                       WHERE e.id_schedule = i_schedule))
                           AND gtoe.id_exam_req = se.id_exam_req(+)
                           AND se.id_schedule = s.id_schedule(+)
                           AND s.flg_status(+) != pk_alert_constant.g_flg_status_c)
                 GROUP BY flg_exam_status,
                          id_patient,
                          id_episode,
                          id_schedule,
                          id_epis_type,
                          id_software,
                          gender,
                          pat_age,
                          num_clin_record,
                          id_professional,
                          flg_status_epis,
                          rank_acuity,
                          acuity);
    
        RETURN l_tbl_other_exams_episodes;
    
    END tf_cm_exams_episode_detail;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_exam_match
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
        l_episode episode.id_episode%TYPE := i_episode;
    
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
        
            g_error := 'UPDATE EXAM_QUESTION_RESPONSE';
            ts_exam_question_response.upd(id_episode_in  => i_episode,
                                          id_episode_nin => FALSE,
                                          where_in       => 'id_episode = ' || i_episode_temp,
                                          rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_QUESTION_RESPONSE_HIST';
            UPDATE exam_question_response_hist
               SET id_episode = i_episode
             WHERE id_episode = i_episode_temp;
        
            l_rows_out := table_varchar();
        
            g_error := 'UPDATE EXAM_REQ';
            ts_exam_req.upd(id_episode_in  => i_episode,
                            id_episode_nin => FALSE,
                            id_visit_in    => l_visit,
                            id_visit_nin   => FALSE,
                            where_in       => 'id_episode = ' || i_episode_temp,
                            rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ (id_episode_origin)';
            ts_exam_req.upd(id_episode_origin_in  => i_episode,
                            id_episode_origin_nin => FALSE,
                            where_in              => 'id_episode_origin = ' || i_episode_temp,
                            rows_out              => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ (id_episode_destination)';
            ts_exam_req.upd(id_episode_destination_in  => i_episode,
                            id_episode_destination_nin => FALSE,
                            where_in                   => 'id_episode_destination = ' || i_episode_temp,
                            rows_out                   => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ (id_prev_episode)';
            ts_exam_req.upd(id_prev_episode_in  => i_episode,
                            id_prev_episode_nin => FALSE,
                            where_in            => 'id_prev_episode = ' || i_episode_temp,
                            rows_out            => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE EXAM_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EXAM_REQ',
                                          i_list_columns => table_varchar('ID_EPISODE',
                                                                          'ID_VISIT',
                                                                          'ID_EPISODE_ORIGIN',
                                                                          'ID_EPISODE_DESTINATION',
                                                                          'ID_PREV_EPISODE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE EXAM_REQ_HIST';
            ts_exam_req_hist.upd(id_episode_in  => i_episode,
                                 id_episode_nin => FALSE,
                                 id_visit_in    => l_visit,
                                 id_visit_nin   => FALSE,
                                 where_in       => 'id_episode = ' || i_episode_temp,
                                 rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ_HIST (id_episode_origin)';
            ts_exam_req_hist.upd(id_episode_origin_in  => i_episode,
                                 id_episode_origin_nin => FALSE,
                                 where_in              => 'id_episode_origin = ' || i_episode_temp,
                                 rows_out              => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ_HIST (id_episode_destination)';
            ts_exam_req_hist.upd(id_episode_destination_in  => i_episode,
                                 id_episode_destination_nin => FALSE,
                                 where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                 rows_out                   => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ_HIST (id_prev_episode)';
            ts_exam_req_hist.upd(id_prev_episode_in  => i_episode,
                                 id_prev_episode_nin => FALSE,
                                 where_in            => 'id_prev_episode = ' || i_episode_temp,
                                 rows_out            => l_rows_out);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE EXAM_RESULT';
            ts_exam_result.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => 'id_episode = ' || i_episode_temp,
                               rows_out       => l_rows_out);
        
            g_error := ' UPDATE EXAM_RESULT (id_episode_write) ';
            ts_exam_result.upd(id_episode_write_in  => i_episode,
                               id_episode_write_nin => FALSE,
                               where_in             => 'id_episode_write = ' || i_episode_temp,
                               rows_out             => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE EXAM_RESULT';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EXAM_RESULT',
                                          i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_WRITEE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE EXAM_RESULT_HIST';
            ts_exam_result_hist.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rows_out);
        
            g_error := ' UPDATE EXAM_RESULT_HIST (id_episode_write) ';
            ts_exam_result_hist.upd(id_episode_write_in  => i_episode,
                                    id_episode_write_nin => FALSE,
                                    where_in             => 'id_episode_write = ' || i_episode_temp,
                                    rows_out             => l_rows_out);
        
            g_error := 'UPDATE GRID_TASK_IMG';
            UPDATE grid_task_img
               SET id_episode = i_episode
             WHERE id_episode = i_episode_temp;
        
            g_error := 'UPDATE GRID_TASK_OTH_EXM';
            UPDATE grid_task_oth_exm
               SET id_episode = i_episode
             WHERE id_episode = i_episode_temp;
        
            DELETE FROM exams_ea eea
             WHERE eea.id_visit IN (SELECT e.id_visit
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
        
            g_error := 'UPDATE EXAM_REQ';
            ts_exam_req.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_episode = ' || i_episode_temp,
                            rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ (id_prev_episode)';
            ts_exam_req.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_prev_episode = ' || i_episode_temp,
                            rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ (id_episode_origin)';
            ts_exam_req.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_episode_origin = ' || i_episode_temp,
                            rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ (id_episode_destination)';
            ts_exam_req.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_episode_destination = ' || i_episode_temp,
                            rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_REQ';
            ts_exam_req.upd(id_patient_in => i_patient, where_in => 'id_visit = ' || l_visit, rows_out => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EXAM_REQ',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE EXAM_RESULT';
            ts_exam_result.upd(id_patient_in  => i_patient,
                               id_patient_nin => FALSE,
                               where_in       => 'id_episode = ' || i_episode_temp,
                               rows_out       => l_rows_out);
        
            g_error := 'UPDATE EXAM_RESULT';
            ts_exam_result.upd(id_patient_in  => i_patient,
                               id_patient_nin => FALSE,
                               where_in       => 'id_episode_write = ' || i_episode_temp,
                               rows_out       => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EXAM_RESULT',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            g_error := 'UPDATE GRID_TASK_IMG';
            UPDATE grid_task_img gti
               SET gti.id_patient = i_patient
             WHERE gti.id_episode = i_episode_temp;
        
            g_error := 'UPDATE GRID_TASK_OTH_EXM';
            UPDATE grid_task_oth_exm gti
               SET gti.id_patient = i_patient
             WHERE gti.id_episode = i_episode_temp;
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
                                              'SET_EXAM_MATCH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_match;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_exams
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam_req_det          table_number;
        l_exam_req              table_number;
        l_schedule_exams        table_number;
        l_tab_sch_not_cancelled table_number;
        l_episode               table_number;
        l_external_doc          table_number;
        l_exam_result           table_number;
        l_patient_id            table_number;
        l_movement_results      table_table_varchar;
        l_sys_alert_event       sys_alert_event%ROWTYPE;
        l_sys_alert_event_row   sys_alert_event%ROWTYPE;
    
        l_error t_error_out;
    
        l_patient_count NUMBER;
        l_episode_count NUMBER;
        l_results       NUMBER;
        l_log_data      VARCHAR2(32767);
        --l_transaction_id VARCHAR2(4000);
    
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
    
        -- selects the lists of all exam_req_det ids to be removed
        g_error := 'EXAM_REQ_DET BULK COLLECT ERROR';
        SELECT DISTINCT er.id_episode, erd.id_exam_req_det, er.id_patient
          BULK COLLECT
          INTO l_episode, l_exam_req_det, l_patient_id
          FROM exam_req_det erd
          JOIN exam_req er
            ON er.id_exam_req = erd.id_exam_req
         WHERE (er.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_episode) t) OR
               er.id_episode_origin IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                           FROM TABLE(i_episode) t))
            OR ((er.id_episode IS NULL OR er.id_episode_origin IS NULL) AND
               er.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_patient) t));
    
        -- check if there were movements associated with the exam request
        g_error := 'MOVEMENT BULK COLLECT ERROR';
        SELECT table_varchar(erd.id_movement, nvl(er.id_episode, er.id_episode_origin), mov.flg_status)
          BULK COLLECT
          INTO l_movement_results
          FROM exam_req_det erd, exam_req er, movement mov
         WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t)
           AND er.id_exam_req = erd.id_exam_req
           AND mov.id_movement(+) = erd.id_movement;
    
        -- remove data from exams_ea
        g_error := 'EXAMS_EA DELETE ERROR';
        DELETE FROM exams_ea ea
         WHERE ea.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_exam_req_det) t);
    
        --removal of images from the grid task
        g_error := 'GRID_TASK_IMG DELETE ERROR';
        DELETE FROM grid_task_img gti
         WHERE gti.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t);
    
        --removal of other exams from the grid task
        g_error := 'GRID_TASK_OTHER_EXAMS DELETE ERROR';
        DELETE FROM grid_task_oth_exm gtoe
         WHERE gtoe.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                          FROM TABLE(l_exam_req_det) t);
    
        -- ## deletes from the result process
        g_error := 'ERROR SELECTING EXAM_RESULT';
        SELECT DISTINCT er.id_exam_result, er.id_external_doc
          BULK COLLECT
          INTO l_exam_result, l_external_doc
          FROM exam_result er
         WHERE er.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_exam_req_det) t);
    
        -- remove data from external_doc
        g_error := 'EXTERNAL_DOC DELETE ERROR';
        DELETE FROM external_doc ed
         WHERE ed.id_external_doc IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_external_doc) t);
    
        g_error := 'EXAM_RESULT_HIST DELETE ERROR';
        DELETE FROM exam_result_hist erh
         WHERE erh.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_exam_result) t);
    
        -- cleans inconsistent data in exams_ea that wasn't cleaned by exams_requisition
        g_error := 'EXAMS_EA DELETE ERROR';
        DELETE FROM exams_ea ea
         WHERE ea.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                       FROM TABLE(l_exam_result) t);
    
        l_rows := NULL;
    
        g_error := 'EXAM_MEDIA_ARCHIVE DELETE ERROR';
        DELETE FROM exam_media_archive ema
         WHERE ema.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t)
            OR ema.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_exam_result) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_MEDIA_ARCHIVE',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'EXAM_RES_FETUS_BIOM_IMG DELETE ERROR';
        DELETE FROM exam_res_fetus_biom_img erfbi
         WHERE erfbi.id_exam_res_fetus_biom IN
               (SELECT DISTINCT erfb.id_exam_res_fetus_biom
                  FROM exam_res_fetus_biom erfb
                 WHERE erfb.id_exam_res_pregn_fetus IN
                       (SELECT DISTINCT erpf.id_exam_res_pregn_fetus
                          FROM exam_res_pregn_fetus erpf
                         WHERE erpf.id_exam_result_pregnancy IN
                               (SELECT DISTINCT erp.id_exam_result_pregnancy
                                  FROM exam_result_pregnancy erp
                                 WHERE erp.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                                                FROM TABLE(l_exam_result) t))));
    
        g_error := 'EXAM_RES_FETUS_BIOM DELETE ERROR';
        DELETE FROM exam_res_fetus_biom erfb
         WHERE erfb.id_exam_res_pregn_fetus IN
               (SELECT DISTINCT erpf.id_exam_res_pregn_fetus
                  FROM exam_res_pregn_fetus erpf
                 WHERE erpf.id_exam_result_pregnancy IN
                       (SELECT DISTINCT erp.id_exam_result_pregnancy
                          FROM exam_result_pregnancy erp
                         WHERE erp.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                                        FROM TABLE(l_exam_result) t)));
    
        g_error := 'EXAM_RES_PREGN_FETUS DELETE ERROR';
        DELETE FROM exam_res_pregn_fetus erpf
         WHERE erpf.id_exam_result_pregnancy IN
               (SELECT DISTINCT erp.id_exam_result_pregnancy
                  FROM exam_result_pregnancy erp
                 WHERE erp.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                                FROM TABLE(l_exam_result) t));
    
        g_error := 'EXAM_RESULT_PREGNANCY DELETE ERROR';
        DELETE FROM exam_result_pregnancy erp
         WHERE erp.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_exam_result) t);
    
        -- removal of the associated diagnosis
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR by exam_result';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                        FROM TABLE(l_exam_result) t);
    
        l_rows := NULL;
    
        g_error := 'EXAM_RESUT DELETE ERROR';
        DELETE FROM exam_result er
         WHERE er.id_exam_result IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                       FROM TABLE(l_exam_result) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_RESULT',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'EXAM_QUESTION_RESPONSE_HIST DELETE ERROR';
        DELETE FROM exam_question_response_hist eqrh
         WHERE eqrh.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                          FROM TABLE(l_exam_req_det) t);
    
        g_error := 'EXAM_QUESTION_RESPONSE DELETE ERROR';
        DELETE FROM exam_question_response eqr
         WHERE eqr.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t);
    
        g_error := 'EXAM_TIME_OUT DELETE ERROR';
        DELETE FROM exam_time_out eto
         WHERE eto.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t);
    
        -- removal of the associated diagnosis
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t);
    
        g_error := 'P1_EXR_EXAM DELETE ERROR';
        DELETE FROM p1_exr_exam pee
         WHERE pee.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t);
    
        g_error := 'P1_EXR_TEMP UPDATE ERROR';
        UPDATE p1_exr_temp pet
           SET pet.id_exam_req_det = NULL
         WHERE pet.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t);
    
        g_error := 'SUSP_TASK_IMAGE_O_EXAMS DELETE ERROR';
        DELETE FROM susp_task_image_o_exams stioe
         WHERE stioe.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                           FROM TABLE(l_exam_req_det) t);
    
        -- removal of exams request details
        g_error := 'EXAM_REQ_DET_HIST DELETE ERROR';
        DELETE FROM exam_req_det_hist erdh
         WHERE erdh.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                          FROM TABLE(l_exam_req_det) t);
    
        l_rows := NULL;
    
        -- removal of exams request details
        g_error := 'EXAM_REQ_DET DELETE ERROR';
        DELETE FROM exam_req_det erd
         WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                         FROM TABLE(l_exam_req_det) t)
        RETURNING to_number(erd.id_exam_req), ROWID BULK COLLECT INTO l_exam_req, l_rows;
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'SCHEDULE_EXAM_HIST UPDATE ERROR';
        UPDATE schedule_exam_hist seh
           SET seh.id_exam_req = NULL
         WHERE seh.id_exam_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                     FROM TABLE(l_exam_req) t);
    
        g_error := 'SCHEDULE_EXAM UPDATE ERROR';
        UPDATE schedule_exam se
           SET se.id_exam_req = NULL
         WHERE se.id_exam_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(l_exam_req) t)
        RETURNING to_number(se.id_schedule) BULK COLLECT INTO l_schedule_exams;
    
        IF l_schedule_exams.count > 0
        THEN
            SELECT s.id_schedule
              BULK COLLECT
              INTO l_tab_sch_not_cancelled
              FROM schedule s
              JOIN TABLE(l_schedule_exams) t
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
    
        -- last delete from exams request table
        g_error := 'EXAM_REQ_HIST DELETE ERROR';
        DELETE FROM exam_req_hist erh
         WHERE erh.id_exam_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                     FROM TABLE(l_exam_req) t);
    
        l_rows := NULL;
    
        -- last delete from exams request table
        g_error := 'EXAM_REQ DELETE ERROR';
        DELETE FROM exam_req er
         WHERE er.id_exam_req IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(l_exam_req) t)
        RETURNING ROWID BULK COLLECT INTO l_rows;
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
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
    
        -- update of exams request date   
        g_error := 'UPDATE EPIS_INFO EXAM REQUEST DATES';
        UPDATE epis_info ei
           SET ei.dt_first_image_req_tstz = NULL
         WHERE ei.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                   FROM TABLE(l_episode) t);
    
        -- removes exams from the exam grid task
        g_error := 'UPDATE GRID_TASK';
        UPDATE grid_task gt
           SET gt.exam_d     = NULL,
               gt.exam_n     = NULL,
               gt.img_exam_d = NULL,
               gt.img_exam_n = NULL,
               gt.oth_exam_d = NULL,
               gt.oth_exam_n = NULL
         WHERE gt.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                   FROM TABLE(l_episode) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESET_EXAMS',
                                              o_error);
            RETURN FALSE;
    END reset_exams;

    PROCEDURE system__________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE process_exam_pending IS
    
        CURSOR c_exam_req_det IS
            SELECT erd.id_exam_req_det, er.id_institution, ei.id_software
              FROM exam_req er, exam_req_det erd, epis_info ei
             WHERE er.dt_begin_tstz <= current_timestamp
               AND er.flg_time = pk_exam_constant.g_flg_time_e
               AND er.id_episode_origin IS NULL
               AND er.id_exam_req = erd.id_exam_req
               AND erd.flg_status = pk_exam_constant.g_exam_pending
               AND er.id_episode = ei.id_episode
               AND pk_sysconfig.get_config('EXAM_AUTOMATIC_TRANSPORT',
                                           profissional(0, er.id_institution, ei.id_software)) = pk_exam_constant.g_yes;
    
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
    
        l_error t_error_out;
    
    BEGIN
    
        FOR rec IN c_exam_req_det
        LOOP
            l_id_prof := pk_sysconfig.get_config('ID_PROF_ALERT', profissional(0, rec.id_institution, rec.id_software));
        
            OPEN c_lang(l_id_prof, rec.id_institution);
            FETCH c_lang
                INTO l_lang;
            CLOSE c_lang;
        
            IF NOT pk_exam_core.set_exam_status(i_lang            => l_lang,
                                                i_prof            => profissional(l_id_prof,
                                                                                  rec.id_institution,
                                                                                  rec.id_software),
                                                i_exam_req_det    => table_number(rec.id_exam_req_det),
                                                i_status          => pk_exam_constant.g_exam_req,
                                                i_notes           => table_varchar(NULL),
                                                i_notes_scheduler => table_varchar(NULL),
                                                o_error           => l_error)
            THEN
                l_count_err := l_count_err + 1;
            ELSE
                l_count := l_count + 1;
            END IF;
        END LOOP;
    
        pk_alertlog.log_info(text            => 'Processed ' || l_count || ' requests. Number of requests in error : ' ||
                                                l_count_err,
                             object_name     => g_package_name,
                             sub_object_name => 'PROCESS_EXAM_PENDING');
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PROCESS_EXAM_PENDING',
                                              l_error);
        
    END process_exam_pending;

    FUNCTION inactivate_exams_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_flg_type    IN exam.flg_type%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config('INACTIVATE_CANCEL_REASON', i_prof);
        l_read_cfg   sys_config.value%TYPE := pk_sysconfig.get_config('READ_CANCEL_REASON', i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(NULL,
                                                                                    profissional(0, i_inst, 0),
                                                                                    'EXAMS_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
        l_read_id   cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_read_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_exam_req_det table_number;
        l_exam_req     table_number;
        l_exam_result  table_number;
        l_final_status table_varchar;
    
        l_tbl_error_ids table_number := table_number();
    
        l_rows_out table_varchar;
    
        l_error t_error_out;
    
        --The cursor will not fetch the records for the ids (id_exam_req_det) sent in i_ids_exclude
        CURSOR c_exam_req_det(ids_exclude IN table_number) IS
            SELECT erd.id_exam_req_det, erd.id_exam_req, cfg.field_04 final_status, eres.id_exam_result
              FROM exam_req er
             INNER JOIN exam_req_det erd
                ON erd.id_exam_req = er.id_exam_req
              LEFT JOIN exam_result eres
                ON eres.id_exam_req_det = erd.id_exam_req_det
              LEFT JOIN episode e
                ON e.id_episode = er.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = erd.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = erd.id_exam_req_det
             WHERE er.id_institution = i_inst
               AND ((e.dt_end_tstz IS NOT NULL AND
                   (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                      pk_date_utils.add_to_ltstz(e.dt_end_tstz,
                                                                                 cfg.field_02,
                                                                                 cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                   (e.id_episode IS NULL AND erd.flg_status = pk_exam_constant.g_exam_sched AND
                   er.dt_begin_tstz IS NOT NULL AND pk_date_utils.trunc_insttimezone(i_prof,
                                                                                       pk_date_utils.add_to_ltstz(er.dt_begin_tstz,
                                                                                                                  cfg.field_02,
                                                                                                                  cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                   (e.id_episode IS NULL AND erd.flg_status = pk_exam_constant.g_exam_tosched AND
                   er.dt_req_tstz IS NOT NULL AND pk_date_utils.trunc_insttimezone(i_prof,
                                                                                     pk_date_utils.add_to_ltstz(er.dt_req_tstz,
                                                                                                                cfg.field_02,
                                                                                                                cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) OR
                   (e.dt_end_tstz IS NULL AND e.id_episode IS NOT NULL AND
                   e.id_epis_type IN (pk_exam_constant.g_episode_type_rad, pk_exam_constant.g_episode_type_exm) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                      pk_date_utils.add_to_ltstz(er.dt_begin_tstz,
                                                                                 cfg.field_02,
                                                                                 cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)))
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
    BEGIN
    
        OPEN c_exam_req_det(i_ids_exclude);
        FETCH c_exam_req_det BULK COLLECT
            INTO l_exam_req_det, l_exam_req, l_final_status, l_exam_result;
        CLOSE c_exam_req_det;
    
        o_has_error := FALSE;
    
        IF l_exam_req_det.count > 0
        THEN
            FOR i IN 1 .. l_exam_req_det.count
            LOOP
                CASE l_final_status(i)
                    WHEN pk_exam_constant.g_exam_cancel THEN
                        SAVEPOINT init_cancel;
                        IF NOT pk_exam_external.cancel_exam_task(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_task_request     => l_exam_req_det(i),
                                                                 i_reason           => l_cancel_id,
                                                                 i_reason_notes     => NULL,
                                                                 i_prof_order       => NULL,
                                                                 i_dt_order         => NULL,
                                                                 i_order_type       => NULL,
                                                                 i_transaction_id   => NULL,
                                                                 i_flg_cancel_event => l_send_cancel_event,
                                                                 o_error            => l_error)
                        THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_exam_req_det, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_exam_req_det that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_EXAM_EXTERNAL.CANCEL_EXAM_TASK FOR RECORD ' ||
                                       l_exam_req_det(i);
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
                            l_tbl_error_ids(l_tbl_error_ids.count) := l_exam_req_det(i);
                        
                            CONTINUE;
                        END IF;
                    ELSE
                        SAVEPOINT init_cancel;
                        IF NOT pk_exams_api_db.set_exam_status_read(i_lang          => i_lang,
                                                                    i_prof          => i_prof,
                                                                    i_exam_req_det  => table_number(l_exam_req_det(i)),
                                                                    i_exam_result   => table_table_number(NULL),
                                                                    i_flg_relevant  => NULL,
                                                                    i_result_notes  => NULL,
                                                                    i_notes_result  => NULL,
                                                                    i_cancel_reason => l_read_id,
                                                                    o_error         => l_error)
                        THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_EXAMS_API_DB.SET_EXAM_STATUS_READ FOR RECORD ' ||
                                       l_exam_req_det(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_EXAMS_TASKS',
                                                              o_error);
                        
                            l_tbl_error_ids.extend();
                            l_tbl_error_ids(l_tbl_error_ids.count) := l_exam_req_det(i);
                        
                            CONTINUE;
                        END IF;
                END CASE;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_exam_req_det has been inactivated.
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
                IF NOT pk_exam_external.inactivate_exams_tasks(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_inst        => i_inst,
                                                               i_flg_type    => i_flg_type,
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
                                              'INACTIVATE_EXAMS_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_exams_tasks;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_exam_external;
/
