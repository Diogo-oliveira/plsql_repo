/*-- Last Change Revision: $Rev: 2027115 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ehr_visits IS

    /**
    * Gets individual encounter plans by EPISODE identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @param o_plans        The plan description array for the EPISODE identifier.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_indiv_encnt_plans_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        o_plans        OUT table_clob,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_INDIV_ENCNT_PLANS_BY_EPIS';
    BEGIN
        o_plans := get_indiv_encnt_plans_by_epis(i_lang, i_prof, i_id_episode, i_id_epis_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_indiv_encnt_plans_by_epis;

    /**
    * Returns individual encounter plans by EPISODE identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  The plan description array for the EPISODE identifier.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_indiv_encnt_plans_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_clob IS
        l_plans              table_clob;
        l_title              VARCHAR2(100);
        l_value              VARCHAR2(2000);
        l_desc_cancel_reason pk_translation.t_desc_translation;
        l_desc_cancel_notes  pk_translation.t_desc_translation;
    
        l_lbl_create sys_message.desc_message%TYPE;
        l_lbl_edit   sys_message.desc_message%TYPE;
        l_lbl_cancel sys_message.desc_message%TYPE;
        l_colon CONSTANT VARCHAR2(2 CHAR) := ': ';
    
        CURSOR c_cursor IS
            SELECT er.desc_epis_recomend_clob desc_val,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) desc_prof,
                   pk_date_utils.date_char_tsz(i_lang, er.dt_epis_recomend_tstz, i_prof.institution, i_prof.software) desc_date,
                   er.dt_epis_recomend_tstz order_date,
                   'ER' l_type,
                   NULL dt_dictated,
                   NULL dt_transcribed,
                   NULL dt_signoff,
                   NULL report_title,
                   NULL report_information,
                   NULL prof_dictated,
                   NULL prof_transcribed,
                   NULL prof_signoff,
                   er.flg_status,
                   CASE
                        WHEN cid.id_cancel_reason IS NOT NULL THEN
                         pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_id_cancel_reason => cid.id_cancel_reason)
                        ELSE
                         NULL
                    END cancel_reason_desc,
                   cid.notes_cancel_long,
                   decode(er.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_lbl_cancel,
                          decode(er.id_epis_recomend_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                   pk_ehr_visits.get_epis_recommend_parent_dt(i_lang, i_prof, er.id_epis_recomend) dt_to_sort
              FROM epis_recomend er
              LEFT JOIN cancel_info_det cid
                ON er.id_cancel_info_det = cid.id_cancel_info_det
             WHERE er.id_episode = i_id_episode
               AND er.desc_epis_recomend_clob IS NOT NULL
               AND er.flg_type = 'L' --plano
               AND er.flg_temp != pk_clinical_info.g_flg_hist
               AND (er.flg_status IN (pk_alert_constant.g_active) OR er.flg_status IS NULL)
            UNION ALL
            SELECT NULL desc_val,
                   NULL desc_prof,
                   NULL desc_date,
                   dr.last_update_date order_date,
                   'DR' l_type,
                   pk_date_utils.date_char_tsz(i_lang, dr.dictated_date, i_prof.institution, i_prof.software) dt_dictated,
                   pk_date_utils.date_char_tsz(i_lang, dr.transcribed_date, i_prof.institution, i_prof.software) dt_transcribed,
                   pk_date_utils.date_char_tsz(i_lang, dr.signoff_date, i_prof.institution, i_prof.software) dt_signoff,
                   pk_translation.get_translation(i_lang, wt.code_work_type) || g_flg_sep ||
                   pk_sysdomain.get_domain('DICTATION_REPORT.REPORT_STATUS', dr.report_status, i_lang) report_title,
                   dr.report_information report_information,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_dictated) prof_dictated,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_transcribed) prof_transcribed,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_signoff) prof_signoff,
                   NULL flg_status,
                   NULL cancel_reason_desc,
                   NULL notes_cancel_long,
                   NULL status,
                   dr.last_update_date dt_to_sort
              FROM dictation_report dr, work_type wt
             WHERE dr.id_episode = i_id_episode
               AND wt.id_work_type(+) = dr.id_work_type
               AND dr.id_work_type = g_dictation_area_plan
            UNION ALL
            SELECT pk_touch_option_core.get_plain_text_entry(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_epis_documentation => ed.id_epis_documentation) desc_val,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_last_update) desc_prof,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) desc_date,
                   ed.dt_last_update_tstz order_date,
                   'ER' l_type,
                   NULL dt_dictated,
                   NULL dt_transcribed,
                   NULL dt_signoff,
                   NULL report_title,
                   NULL report_information,
                   NULL prof_dictated,
                   NULL prof_transcribed,
                   NULL prof_signoff,
                   NULL flg_status,
                   NULL cancel_reason_desc,
                   NULL notes_cancel_long,
                   NULL status,
                   ed.dt_last_update_tstz dt_to_sort
              FROM epis_documentation ed
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area = pk_summary_page.g_doc_area_plan
               AND ed.flg_status = pk_touch_option.g_active
             ORDER BY dt_to_sort DESC, order_date DESC;
    
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_record  t_cursor_type;
        l_counter NUMBER;
        internal_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_ehr_common.get_visit_type_by_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_episode   => i_id_episode,
                                                    i_id_epis_type => i_id_epis_type,
                                                    i_sep          => '; ',
                                                    o_title        => l_title,
                                                    o_value        => l_value,
                                                    o_error        => l_error)
        THEN
            RAISE internal_exception;
        END IF;
        l_plans := table_clob();
        l_plans.extend(3);
        l_plans(1) := '';
        l_plans(2) := CASE
                          WHEN (l_value IS NOT NULL) THEN
                           l_title
                          ELSE
                           NULL
                      END;
        l_plans(3) := l_value;
    
        l_desc_cancel_reason := pk_message.get_message(i_lang, i_prof, 'COMMON_M072');
        l_desc_cancel_notes  := pk_message.get_message(i_lang, i_prof, 'COMMON_M073');
    
        l_lbl_create := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PROGRESS_NOTES_T113') ||
                        l_colon;
        l_lbl_edit   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PROGRESS_NOTES_T114') ||
                        l_colon;
        l_lbl_cancel := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PROGRESS_NOTES_T115') ||
                        l_colon;
    
        OPEN c_cursor;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_record LIMIT 100;
            FOR i IN 1 .. l_record.count
            LOOP
                IF l_record(i).l_type = 'ER'
                THEN
                    IF (l_record(i).flg_status IN (pk_alert_constant.g_cancelled, pk_alert_constant.g_outdated))
                    THEN
                        l_counter := l_plans.count;
                        l_plans.extend(6);
                        l_plans(l_counter + 1) := pk_alert_constant.g_cancelled;
                        l_plans(l_counter + 2) := NULL; --l_title;
                        l_plans(l_counter + 3) := l_record(i).desc_val || CASE
                                                       WHEN l_record(i).cancel_reason_desc IS NOT NULL THEN
                                                        chr(10) || l_desc_cancel_reason || ': ' || l_record(i).cancel_reason_desc
                                                   END || CASE
                                                       WHEN l_record(i).notes_cancel_long IS NOT NULL
                                                             AND dbms_lob.compare(l_record(i).notes_cancel_long, empty_clob()) != 0 THEN
                                                        chr(10) || l_desc_cancel_notes || ': ' || l_record(i).notes_cancel_long
                                                   END;
                        l_plans(l_counter + 4) := 'IC'; --pk_alert_constant.g_cancelled;
                        l_plans(l_counter + 5) := l_record(i).status || l_record(i).desc_prof;
                        l_plans(l_counter + 6) := l_record(i).desc_date;
                    ELSE
                        l_counter := l_plans.count;
                        l_plans.extend(6);
                        l_plans(l_counter + 1) := '';
                        l_plans(l_counter + 2) := NULL; --l_title;
                        l_plans(l_counter + 3) := l_record(i).desc_val;
                        l_plans(l_counter + 4) := 'I';
                        l_plans(l_counter + 5) := l_record(i).status || l_record(i).desc_prof;
                        l_plans(l_counter + 6) := l_record(i).desc_date;
                    END IF;
                ELSIF l_record(i).l_type = 'DR'
                THEN
                    l_counter := l_plans.count;
                    l_plans.extend(3);
                    l_plans(l_counter + 1) := '';
                    l_plans(l_counter + 2) := l_record(i).report_title || '<br>';
                    l_plans(l_counter + 3) := l_record(i).report_information;
                    IF l_record(i).prof_dictated IS NOT NULL
                    THEN
                        l_counter := l_plans.count;
                        l_plans.extend(3);
                        l_plans(l_counter + 1) := 'I';
                        l_plans(l_counter + 2) := pk_message.get_message(i_lang, i_prof, 'DICTATION_REPORT_001') || ': ' || l_record(i).prof_dictated;
                        l_plans(l_counter + 3) := l_record(i).dt_dictated;
                    END IF;
                    IF l_record(i).prof_transcribed IS NOT NULL
                    THEN
                        l_counter := l_plans.count;
                        l_plans.extend(3);
                        l_plans(l_counter + 1) := 'I';
                        l_plans(l_counter + 2) := pk_message.get_message(i_lang, i_prof, 'DICTATION_REPORT_002') || ': ' || l_record(i).prof_transcribed;
                        l_plans(l_counter + 3) := l_record(i).dt_transcribed;
                    END IF;
                    IF l_record(i).prof_signoff IS NOT NULL
                    THEN
                        l_counter := l_plans.count;
                        l_plans.extend(3);
                        l_plans(l_counter + 1) := 'I';
                        l_plans(l_counter + 2) := pk_message.get_message(i_lang, i_prof, 'DICTATION_REPORT_003') || ': ' || l_record(i).prof_signoff;
                        l_plans(l_counter + 3) := l_record(i).dt_signoff;
                    END IF;
                END IF;
            END LOOP;
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
    
        RETURN l_plans;
    END get_indiv_encnt_plans_by_epis;

    /**
    * Returns EHR individual encounter plans for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with the EHR individual encounter plans for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_individual_encounter_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_INDIVIDUAL_ENCOUNTER_PLANS';
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   get_indiv_encnt_plans_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND ((SELECT COUNT(1)
                       FROM epis_recomend er
                      WHERE er.id_episode = e.id_episode
                        AND er.flg_type = 'L'
                        AND er.flg_temp != pk_clinical_info.g_flg_hist
                           --AND (er.flg_status = pk_alert_constant.g_active OR er.flg_status IS NULL)
                        AND er.desc_epis_recomend_clob IS NOT NULL) > 0 OR
                   (SELECT COUNT(1)
                       FROM dictation_report dr, work_type wt
                      WHERE dr.id_episode = e.id_episode
                        AND wt.id_work_type(+) = dr.id_work_type
                        AND dr.id_work_type = g_dictation_area_plan) > 0 OR
                   (SELECT COUNT(1)
                       FROM epis_documentation ed
                      WHERE ed.id_episode = e.id_episode
                        AND ed.id_doc_area = pk_summary_page.g_doc_area_plan
                        AND ed.flg_status = pk_touch_option.g_active) > 0)
            
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_individual_encounter_plans;

    /**
    * Returns EHR history of past illnesses for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR history of past illnesses for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_history_past_illnesses
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_HISTORY_PAST_ILLNESSES';
        l_id_doc_area doc_area.id_doc_area%TYPE := pk_ehr_common.g_doc_area_hpi;
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   pk_ehr_common.get_doc_area_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, l_id_doc_area) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND ((SELECT COUNT(1)
                       FROM epis_documentation ed
                      WHERE ed.id_episode = e.id_episode
                        AND ed.id_doc_area = l_id_doc_area
                        AND ed.flg_status = 'A') > 0 OR
                   (SELECT COUNT(1)
                       FROM epis_anamnesis ea
                      WHERE ea.id_episode = e.id_episode
                        AND ea.flg_type = 'A'
                        AND ea.flg_temp IN ('H', 'D')) > 0)
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_history_past_illnesses;

    /**
    * Returns EHR reviews of systems for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR reviews of systems for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_reviews_of_systems
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_REVIEWS_OF_SYSTEMS';
        l_id_doc_area doc_area.id_doc_area%TYPE := pk_ehr_common.g_doc_area_ros;
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   pk_ehr_common.get_doc_area_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, l_id_doc_area) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND ((SELECT COUNT(1)
                       FROM epis_documentation ed
                      WHERE ed.id_episode = e.id_episode
                        AND ed.id_doc_area = l_id_doc_area
                        AND ed.flg_status = 'A') > 0 OR
                   (SELECT COUNT(1)
                       FROM epis_review_systems ers
                      WHERE ers.id_episode = e.id_episode
                        AND ers.flg_status = 'A') > 0)
            
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_reviews_of_systems;

    /**
    * Returns EHR physical exams for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR physical exams for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_physical_exams
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_PHYSICAL_EXAMS';
        l_id_doc_area doc_area.id_doc_area%TYPE := pk_ehr_common.g_doc_area_phy;
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   pk_ehr_common.get_doc_area_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, l_id_doc_area) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND ((SELECT COUNT(1)
                       FROM epis_documentation ed
                      WHERE ed.id_episode = e.id_episode
                        AND ed.id_doc_area IN (l_id_doc_area, 1045)
                        AND ed.flg_status = 'A') > 0 OR
                   (SELECT COUNT(1)
                       FROM epis_observation eo
                      WHERE eo.id_episode = e.id_episode
                        AND eo.flg_status = pk_clinical_info.g_epis_active
                        AND eo.flg_type = pk_clinical_info.g_observ_flg_type_e) > 0)
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_physical_exams;

    /**
    * Returns EHR planned visits for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR planned visits for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_planned_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PLANNED_VISITS';
    
        l_date TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        l_date := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);
    
        OPEN o_cursor FOR
            SELECT *
              FROM (SELECT s.id_schedule,
                           e.id_episode id_episode,
                           
                           pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_type,
                           pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, chr(10)) visit_information,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ei.id_professional) desc_prof,
                           
                           pk_date_utils.date_char_tsz(i_lang,
                                                       decode(sr.id_episode,
                                                              NULL,
                                                              decode(s.id_schedule,
                                                                     NULL,
                                                                     e.dt_begin_tstz,
                                                                     so.dt_target_tstz),
                                                              sr.dt_interv_preview_tstz),
                                                       i_prof.institution,
                                                       i_prof.software) desc_date,
                           
                           pk_date_utils.date_send_tsz(i_lang,
                                                       decode(sr.id_episode,
                                                              NULL,
                                                              decode(s.id_schedule,
                                                                     NULL,
                                                                     e.dt_begin_tstz,
                                                                     so.dt_target_tstz),
                                                              sr.dt_interv_preview_tstz),
                                                       i_prof) date_order,
                           s.dt_schedule_tstz
                      FROM episode e, epis_info ei, schedule s, schedule_sr sr, schedule_outp so
                     WHERE e.id_patient = i_id_patient
                       AND ei.id_episode = e.id_episode
                       AND s.id_schedule(+) = ei.id_schedule
                       AND so.id_schedule(+) = ei.id_schedule
                       AND e.id_episode = sr.id_episode(+)
                       AND e.flg_ehr = pk_visit.g_flg_ehr_s
                       AND s.flg_status(+) = pk_alert_constant.g_active
                       AND e.flg_status = pk_visit.g_epis_active
                       AND (pk_wtl_pbl_core.check_episode_in_wtl(i_lang, i_prof, e.id_episode) = pk_alert_constant.g_no OR
                           pk_wtl_pbl_core.check_episode_sched_wtl(i_lang, i_prof, e.id_episode) =
                           pk_alert_constant.g_yes)
                    UNION ALL
                    SELECT s.id_schedule,
                           NULL id_episode,
                           pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, so.id_epis_type) visit_type,
                           (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                              FROM clinical_service cs
                             WHERE cs.id_clinical_service =
                                   (SELECT dcs.id_clinical_service
                                      FROM dep_clin_serv dcs
                                     WHERE dcs.id_dep_clin_serv = s.id_dcs_requested)) visit_information,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, spo.id_professional) desc_prof,
                           
                           pk_date_utils.date_char_tsz(i_lang, so.dt_target_tstz, i_prof.institution, i_prof.software) desc_date,
                           
                           pk_date_utils.date_send_tsz(i_lang, so.dt_target_tstz, i_prof) date_order,
                           
                           s.dt_schedule_tstz
                      FROM schedule s
                      JOIN sch_group sg
                        ON (s.id_schedule = sg.id_schedule)
                      JOIN schedule_outp so
                        ON (s.id_schedule = so.id_schedule)
                      JOIN sch_prof_outp spo
                        ON (spo.id_schedule_outp = so.id_schedule_outp)
                     WHERE sg.id_patient = i_id_patient
                       AND so.dt_target_tstz >= l_date
                       AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporá²©os (SCH 3.0)
                       AND s.flg_status != pk_schedule.g_sched_status_cancelled
                       AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                                   FROM epis_info ei
                                                   JOIN episode e
                                                     ON (ei.id_episode = e.id_episode)
                                                  WHERE e.id_patient = i_id_patient
                                                       --AND e.flg_ehr IN (g_flg_ehr_scheduled)
                                                    AND ei.id_schedule IS NOT NULL))
             ORDER BY nvl(date_order, 0) DESC;
    
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_planned_visits;

    /**
    * Returns EHR other events for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR other events for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_other_events
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_OTHER_EVENTS';
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type, 'Y') event_info,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') event_type,
                   ei.id_software,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT nvl(ei.id_professional, ei.id_first_nurse_resp)
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) desc_prof,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) date_order,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, pk_ehr_access.g_sep_reason) desc_reason
              FROM episode e, epis_info ei
             WHERE e.id_patient = i_id_patient
               AND ei.id_episode = e.id_episode
               AND e.flg_ehr = g_flg_ehr
             ORDER BY epis_date DESC, epis_hour DESC;
    
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_other_events;

    /**
    * Returns EHR diagnoses for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR diagnoses for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_pat_diagnosis_list(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_patient => i_id_patient,
                                                        o_cursor     => o_cursor,
                                                        o_error      => o_error);
    END get_diagnosis;

    /**
    * Returns disposition instruction by EPISODE identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  The disposition instruction array for the EPISODE identifier.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/18
    */
    FUNCTION get_disposition_instr_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar IS
        l_disp  table_varchar;
        l_title VARCHAR2(100);
        l_value VARCHAR2(2000);
    
        CURSOR c_cursor IS
            SELECT pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M004') title1,
                   nvl(dn.epis_complaint, pk_translation.get_translation_trs(dn.code_epis_complaint)) val1,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M005') title2,
                   dn.epis_diagnosis val2,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M019') title3,
                   pk_sysdomain.get_domain('DISCHARGE_NOTES.RELEASE_FROM', dn.release_from, i_lang) val3,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M020') title4,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, dn.dt_from, i_prof.institution, i_prof.software) val4,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M021') title5,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, dn.dt_until, i_prof.institution, i_prof.software) val5,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M023') title6,
                   dn.notes_release val6,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_T006') title7,
                   dn.discharge_instructions val7,
                   -- José Brito ALERT-10317 Disposition Management: refactoring of "Discharge Instructions"
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M024') title8,
                   pk_discharge.get_follow_up_with_list(i_lang, i_prof, dn.id_discharge_notes, i_id_episode) val8,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_M022') title9,
                   pk_discharge.get_dn_discussed_with(i_lang, i_prof, dn.id_discharge_notes) val9,
                   -- Pending issue info
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_T010') || ':' title10,
                   pk_discharge.get_issue_current_assignee(i_lang,
                                                           i_prof,
                                                           dn.id_discharge_notes,
                                                           dn.id_pending_issue,
                                                           dn.flg_issue_assign) val10,
                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_NOTES_T019') || ':' title11,
                   pi.title val11,
                   --
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dn.id_professional) title12,
                   pk_date_utils.date_char_tsz(i_lang, dn.dt_creation_tstz, i_prof.institution, i_prof.software) val12
              FROM discharge_notes dn, follow_up_type fut, pending_issue pi
             WHERE dn.id_episode = i_id_episode
               AND dn.flg_status != pk_discharge.g_disch_notes_c
               AND dn.id_follow_up_type = fut.id_follow_up_type(+)
               AND dn.id_pending_issue = pi.id_pending_issue(+)
             ORDER BY dn.dt_creation_tstz DESC;
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_record t_cursor_type;
        internal_exception EXCEPTION;
        l_error t_error_out;
    
        PROCEDURE add_value
        (
            i_type  IN VARCHAR2 DEFAULT '',
            i_title IN VARCHAR2,
            i_value IN VARCHAR2
        ) IS
        BEGIN
            l_disp.extend(3);
            l_disp(l_disp.count - 2) := i_type;
            l_disp(l_disp.count - 1) := i_title;
            l_disp(l_disp.count) := i_value;
        END add_value;
    BEGIN
    
        IF NOT pk_ehr_common.get_visit_type_by_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_episode   => i_id_episode,
                                                    i_id_epis_type => i_id_epis_type,
                                                    i_sep          => '; ',
                                                    o_title        => l_title,
                                                    o_value        => l_value,
                                                    o_error        => l_error)
        THEN
            RAISE internal_exception;
        END IF;
    
        l_disp := table_varchar();
        add_value(i_title => l_title, i_value => l_value);
    
        --l_title := pk_message.get_message(i_lang, i_prof, 'EHR_PLANS_T001'); -- 'Individual encounter plans';
        OPEN c_cursor;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_record LIMIT 100;
            FOR i IN 1 .. l_record.count
            LOOP
                IF i_prof.software != pk_alert_constant.g_soft_primary_care
                THEN
                    add_value(i_title => l_record(i).title1, i_value => l_record(i).val1);
                    add_value(i_title => l_record(i).title2, i_value => l_record(i).val2);
                    add_value(i_title => l_record(i).title3, i_value => l_record(i).val3);
                    add_value(i_title => l_record(i).title4, i_value => l_record(i).val4);
                    add_value(i_title => l_record(i).title5, i_value => l_record(i).val5);
                    add_value(i_title => l_record(i).title6, i_value => l_record(i).val6);
                END IF;
            
                add_value(i_title => l_record(i).title7, i_value => l_record(i).val7);
            
                IF i_prof.software != pk_alert_constant.g_soft_primary_care
                THEN
                    -- Follow-up with
                    add_value(i_title => l_record(i).title8, i_value => l_record(i).val8);
                    add_value(i_title => l_record(i).title9, i_value => l_record(i).val9);
                    -- Pending issues (title)
                    add_value(i_title => l_record(i).title10, i_value => l_record(i).val10);
                    -- Pending issues (assignee)
                    add_value(i_title => l_record(i).title11, i_value => l_record(i).val11);
                END IF;
            
                add_value(i_type => 'I', i_title => l_record(i).title12, i_value => l_record(i).val12);
            END LOOP;
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
        CLOSE c_cursor;
        RETURN l_disp;
    END get_disposition_instr_by_epis;

    /**
    * Returns EHR disposition instructions for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR disposition instructions for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_disposition_instructions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DISPOSITION_INSTRUCTIONS';
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   get_disposition_instr_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (SELECT COUNT(1)
                      FROM discharge_notes dn
                     WHERE dn.id_episode = e.id_episode
                       AND dn.flg_status != pk_discharge.g_disch_notes_c) > 0
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_disposition_instructions;

    /**
    * Returns reasons for visits for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR reasons for visits for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Rui Batista
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_reasons_for_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_REASONS_FOR_VISITS';
    BEGIN
    
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   pk_ehr_visits.get_reason_for_visit_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND EXISTS (SELECT 0
                      FROM epis_complaint ec
                     WHERE ec.id_episode = e.id_episode
                    UNION
                    SELECT 0
                      FROM epis_anamnesis ea
                     WHERE ea.flg_type = 'C'
                       AND ea.id_episode = e.id_episode
                    UNION
                    SELECT 0
                      FROM epis_info ei
                      LEFT JOIN schedule_outp so
                        ON so.id_schedule_outp = ei.id_schedule_outp
                     WHERE ei.id_episode = e.id_episode
                       AND pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                       i_prof,
                                                                                                       ei.id_episode,
                                                                                                       so.id_schedule),
                                                            4000) IS NOT NULL
                       AND e.flg_status IN (pk_alert_constant.g_epis_status_inactive,
                                            pk_alert_constant.g_epis_status_pendent)
                       AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal)
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_reasons_for_visits;

    /**
    * Returns reason for visit for a specific episode 
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  a table of varchar with the reasons for visits values
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_reason_for_visit_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar IS
        --
        o_table table_varchar;
        l_title VARCHAR2(100);
        l_value VARCHAR2(2000);
        l_error t_error_out;
        --    
        CURSOR c_cursor IS
            SELECT --dt_confirmed_tstz,
             diag_prof,
             substr(concatenate(desc_diagnosis || '; '), 1, length(concatenate(desc_diagnosis || '; ')) - 2) diag
              FROM (SELECT ed.dt_confirmed_tstz,
                           ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_confirmed) || '; ' ||
                           pk_date_utils.date_time_chr_tsz(i_lang, ed.dt_confirmed_tstz, i_prof) || ')' diag_prof,
                           -- ALERT-736 synonyms diagnosis
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis
                      FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
                     WHERE ed.id_episode = i_id_episode
                       AND d.id_diagnosis = ed.id_diagnosis
                       AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                       AND ed.flg_type IN (pk_diagnosis.g_diag_type_d, pk_diagnosis.g_diag_type_b)
                       AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_d,
                                             pk_diagnosis.g_ed_flg_status_co,
                                             pk_diagnosis.g_ed_flg_status_b))
             GROUP BY diag_prof
            UNION
            SELECT --dt_confirmed_tstz,
             diag_prof,
             substr(concatenate(desc_diagnosis || '; '), 1, length(concatenate(desc_diagnosis || '; ')) - 2) diag
              FROM (SELECT ed.dt_confirmed_tstz,
                           ' (' ||
                           pk_prof_utils.get_name_signature(i_lang,
                                                            i_prof,
                                                            nvl(ed.id_prof_confirmed, ed.id_professional_diag)) || '; ' ||
                           pk_date_utils.date_time_chr_tsz(i_lang,
                                                           nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                           i_prof) || ')' diag_prof,
                           -- ALERT-736 synonyms diagnosis
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis
                      FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
                     WHERE ed.id_episode = i_id_episode
                       AND d.id_diagnosis = ed.id_diagnosis
                       AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                       AND ed.flg_type = pk_diagnosis.g_diag_type_p
                       AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co)
                       AND ed.id_diagnosis NOT IN
                           (SELECT id_diagnosis
                              FROM epis_diagnosis ed1
                             WHERE ed1.flg_type = pk_diagnosis.g_diag_type_d
                               AND ed1.flg_status IN (pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_d)
                               AND ed1.id_episode = i_id_episode))
             GROUP BY diag_prof
             ORDER BY 2;
    
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_values    t_cursor_type;
        l_counter   NUMBER;
        l_complaint table_varchar;
    
    BEGIN
    
        IF NOT pk_ehr_common.get_visit_type_by_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_episode   => i_id_episode,
                                                    i_id_epis_type => i_id_epis_type,
                                                    i_sep          => '; ',
                                                    o_title        => l_title,
                                                    o_value        => l_value,
                                                    o_error        => l_error)
        THEN
            RETURN NULL;
        END IF;
        -- The table of varchar to be returned will be composed by a set of records. Each record contains three elements.
        -- The first element can be null or 'I'. If it is 'I', it will be placed in italics font.
        -- The second element will be the title of each record. It should be placed in bold font.
        -- The third element will be description. It should be placed in normal font.
    
        o_table := table_varchar();
    
        IF i_id_epis_type = g_epis_type_oris
        THEN
            o_table.extend(3);
            o_table(1) := '';
            o_table(2) := l_title;
            o_table(3) := l_value;
            --ORIS
            OPEN c_cursor;
            LOOP
                FETCH c_cursor BULK COLLECT
                    INTO l_values LIMIT 100;
                FOR i IN 1 .. l_values.count
                LOOP
                    l_counter := o_table.count;
                    o_table.extend(6);
                    o_table(l_counter + 1) := NULL;
                    o_table(l_counter + 2) := pk_message.get_message(i_lang, i_prof, 'EHR_DOPI_T017');
                    o_table(l_counter + 3) := l_values(i).diag;
                    o_table(l_counter + 4) := 'I';
                    o_table(l_counter + 5) := l_values(i).diag_prof;
                    o_table(l_counter + 6) := NULL;
                END LOOP;
                EXIT WHEN c_cursor%NOTFOUND;
            END LOOP;
        
        ELSE
            --IF i_id_epis_type IN (g_epis_type_outp, g_epis_type_edis, g_epis_type_pp)
            l_complaint := table_varchar();
            l_complaint.extend(3);
            g_error := 'GET_LAST_COMPLAINT';
            --Vai buscar a queixa utilizando as funções já criadas para o efeito.
            l_complaint := pk_ehr_visits.get_last_complaint(i_lang, i_id_episode, i_id_epis_type, i_prof);
            l_counter   := o_table.count;
            --
            o_table.extend(3);
            o_table(l_counter + 1) := NULL;
            SELECT decode(i_id_epis_type,
                          g_epis_type_outp,
                          pk_message.get_message(i_lang, i_prof, 'EHR_DOPI_T014'),
                          g_epis_type_pp,
                          pk_message.get_message(i_lang, i_prof, 'EHR_DOPI_T014'),
                          g_epis_type_inp,
                          pk_message.get_message(i_lang, i_prof, 'EHR_DOPI_T016'),
                          g_epis_type_edis,
                          pk_message.get_message(i_lang, i_prof, 'EHR_DOPI_T015'))
              INTO o_table(l_counter + 2)
              FROM dual;
            o_table(l_counter + 3) := l_complaint(1);
        
            l_counter := o_table.count;
            o_table.extend(3);
            o_table(l_counter + 1) := '';
            o_table(l_counter + 2) := l_title;
            o_table(l_counter + 3) := l_value;
        
            IF l_complaint(2) IS NOT NULL
            THEN
                l_counter := o_table.count;
                o_table.extend(3);
                o_table(l_counter + 1) := '';
                o_table(l_counter + 2) := pk_message.get_message(i_lang, i_prof, 'EHR_DOPI_T018');
                o_table(l_counter + 3) := l_complaint(2);
            END IF;
        
            l_counter := o_table.count;
            o_table.extend(3);
            o_table(l_counter + 1) := 'I';
            o_table(l_counter + 2) := l_complaint(3);
            o_table(l_counter + 3) := NULL;
        END IF;
    
        RETURN o_table;
    
    END get_reason_for_visit_by_epis;

    /**
    * Returns the last complaint of the episode
    *
    * @param i_lang         Language identifier.
    * @param i_episode      EPISODE identifier.
    * @param i_epis_type    Episode type
    * @param i_prof         The professional record.
    *
    * @return  a table of varchar with last complaint
    *
    * @author   Rui Batista
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_last_complaint
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_anamnesis.id_episode%TYPE,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        i_prof      IN profissional
    ) RETURN table_varchar IS
    
        l_complaint          pk_types.cursor_type;
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
        l_complaint_out      table_varchar;
        l_error              t_error_out;
        l_dummy              VARCHAR2(200);
    
    BEGIN
    
        l_complaint_out := table_varchar();
        l_complaint_out.extend(3);
    
        IF i_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_urgent_care)
        THEN
            g_error := 'GET EMERGENCY COMPLAINT';
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => l_error)
            THEN
                RETURN NULL;
            END IF;
        
            g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
            CLOSE l_cur_epis_complaint;
        
            l_complaint_out(1) := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                       i_prof,
                                                                       l_row_epis_complaint.desc_complaint,
                                                                       l_row_epis_complaint.patient_complaint,
                                                                       pk_alert_constant.g_no);
            l_complaint_out(2) := l_row_epis_complaint.desc_template;
            IF l_row_epis_complaint.id_prof_register IS NOT NULL
            THEN
                l_complaint_out(3) := '(' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') ||
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  l_row_epis_complaint.dt_register,
                                                                  i_prof.institution,
                                                                  i_prof.software) || '; ' ||
                                      pk_prof_utils.get_name_signature(i_lang,
                                                                       i_prof,
                                                                       l_row_epis_complaint.id_prof_register) || ')';
            END IF;
        
        ELSE
        
            g_error := 'OPEN c_complaint_triage';
            BEGIN
            
                SELECT desc_complaint, desc_template, desc_prof
                  INTO l_complaint_out(1), l_complaint_out(2), l_complaint_out(3)
                  FROM (SELECT dt_register,
                               substr(concatenate(decode(compl, NULL, '', compl || '; ')),
                                      1,
                                      length(concatenate(decode(compl, NULL, '', compl || '; '))) - 2) desc_complaint,
                               /*                               substr(concatenate(decode(templ, NULL, '', templ || '; ')),
                               1,
                               length(concatenate(decode(templ, NULL, '', templ || '; '))) - 2) desc_template,*/
                               NULL desc_template,
                               '(' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') ||
                               pk_date_utils.date_char_tsz(i_lang, dt_register, i_prof.institution, i_prof.software) || '; ' ||
                               pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_register) || ')' desc_prof
                          FROM (SELECT adw_last_update_tstz dt_register, id_prof_register, compl /*,
                                                                                                                                       substr(concatenate(decode(templ, NULL, '', templ || '; ')),
                                                                                                                                              1,
                                                                                                                                              length(concatenate(decode(templ, NULL, '', templ || '; '))) - 2) templ*/
                                  FROM (SELECT ec.adw_last_update_tstz,
                                               ec.id_professional id_prof_register,
                                               pk_translation.get_translation(i_lang, c.code_complaint) compl --,
                                        --  pk_translation.get_translation(i_lang, dt.code_doc_template) templ
                                          FROM epis_complaint ec
                                         INNER JOIN complaint c
                                            ON ec.id_complaint = c.id_complaint
                                          LEFT JOIN epis_doc_template edoc
                                            ON edoc.id_epis_complaint = ec.id_epis_complaint
                                          LEFT JOIN doc_template dt
                                            ON edoc.id_doc_template = dt.id_doc_template
                                         WHERE ec.id_episode = i_episode
                                           AND ec.flg_status = 'A'
                                        UNION
                                        SELECT ea.dt_epis_anamnesis_tstz adw_last_update_tstz,
                                               ea.id_professional id_prof_register,
                                               pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) compl --,
                                        --    NULL templ
                                          FROM epis_anamnesis ea
                                         WHERE ea.id_episode = i_episode
                                           AND ea.flg_type = 'C'
                                        UNION
                                        SELECT adw_last_update_tstz, id_prof_register, compl --, templ
                                          FROM (SELECT s.dt_schedule_tstz adw_last_update_tstz,
                                                       s.id_prof_schedules id_prof_register,
                                                       pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   ei.id_episode,
                                                                                                                                   so.id_schedule),
                                                                                        4000) compl --,
                                                --  NULL templ
                                                  FROM episode e
                                                  JOIN epis_info ei
                                                    ON ei.id_episode = e.id_episode
                                                  JOIN schedule_outp so
                                                    ON so.id_schedule_outp = ei.id_schedule_outp
                                                  JOIN schedule s
                                                    ON s.id_schedule = so.id_schedule
                                                 WHERE e.id_episode = i_episode
                                                   AND e.flg_status IN
                                                       (pk_alert_constant.g_epis_status_inactive,
                                                        pk_alert_constant.g_epis_status_pendent)
                                                   AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal)
                                         WHERE compl IS NOT NULL)
                                 GROUP BY adw_last_update_tstz, id_prof_register, compl)
                         GROUP BY dt_register, id_prof_register
                         ORDER BY 1 DESC)
                 WHERE rownum < 2;
            EXCEPTION
                WHEN no_data_found THEN
                    l_complaint_out(1) := NULL;
                    l_complaint_out(2) := NULL;
            END;
        
            IF l_complaint_out(1) IS NULL
            THEN
            
                g_error := 'CALL PK_CLINICAL_INFO.GET_SUMM_LAST_ANAMNESIS - ' || g_anam_flg_type_c;
                IF NOT pk_clinical_info.get_summ_last_anamnesis(i_lang      => i_lang,
                                                                i_episode   => i_episode,
                                                                i_prof      => i_prof,
                                                                i_flg_type  => g_anam_flg_type_c,
                                                                o_anamnesis => l_complaint,
                                                                o_error     => l_error)
                THEN
                    RETURN NULL;
                END IF;
                --
            
                g_error := 'FECH L_COMPLAINT';
                FETCH l_complaint
                    INTO l_complaint_out(1), l_dummy, l_complaint_out(3); --o_complaint, l_prof_anam, l_anamnesis_prof;
                CLOSE l_complaint;
                --
            
            END IF;
        END IF;
    
        RETURN l_complaint_out;
    
    END get_last_complaint;

    /**
    * Returns all advanced directives grouped by episode for a patient
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR reasons for visits for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Pedro Teixeira
    * @version  2.4.3
    * @since    2008/05/26
    */
    FUNCTION get_adv_directives_for_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_ADV_DIRECTIVES_FOR_PAT';
    
    BEGIN
        OPEN o_cursor FOR
            SELECT e.id_episode,
                   e.id_epis_type,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) desc_visit_date,
                   pk_ehr_visits.get_adv_directives_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type) val
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND EXISTS
             (SELECT 1
                      FROM epis_documentation ed
                     WHERE ed.id_episode = e.id_episode
                       AND ed.flg_status = pk_alert_constant.g_active
                       AND ed.id_doc_area IN
                           (g_doc_area_adv_directives1, g_doc_area_adv_directives2, g_doc_area_adv_directives3))
             ORDER BY e.dt_begin_tstz DESC;
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
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adv_directives_for_pat;
    ------------------------------------------------------------------------
    /**
    * Returns advanced directives for a certain episode
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  a table of varchar with the advanced directives for a apisode
    *
    * @author   Pedro Teixeira
    * @version  2.4.3
    * @since    2008/05/26
    */
    FUNCTION get_adv_directives_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar IS
        --
        o_table         table_varchar;
        l_title_adv_dir sys_message.desc_message%TYPE;
        l_adv_dir       VARCHAR2(100);
        l_error         t_error_out;
        internal_exception EXCEPTION;
        l_advanced pk_types.cursor_type;
        --
        CURSOR c_directives IS
            SELECT ed.id_epis_documentation,
                   ed.notes,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_last_update_tstz,
                                                    ed.id_episode) desc_speciality
              FROM epis_documentation ed
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area IN
                   (g_doc_area_adv_directives1, g_doc_area_adv_directives2, g_doc_area_adv_directives3)
               AND ed.flg_status = pk_alert_constant.g_active
             ORDER BY ed.id_epis_documentation DESC;
    
        CURSOR c_directive_detail(epis_doc epis_documentation.id_epis_documentation%TYPE) IS
            SELECT pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                   decode(pk_translation.get_translation(i_lang, decr.code_element_close),
                          NULL,
                          edd.value,
                          pk_translation.get_translation(i_lang, decr.code_element_close)) desc_element
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             INNER JOIN doc_element_crit decr
                ON edd.id_doc_element_crit = decr.id_doc_element_crit
             INNER JOIN doc_element de
                ON decr.id_doc_element = de.id_doc_element
             WHERE ed.id_epis_documentation = epis_doc
               AND ed.id_doc_area IN
                   (g_doc_area_adv_directives1, g_doc_area_adv_directives2, g_doc_area_adv_directives3)
               AND ed.flg_status = pk_alert_constant.g_active
             ORDER BY ed.id_epis_documentation, dtad.rank, de.rank;
    
        l_counter NUMBER;
    
    BEGIN
    
        -- The table of varchar to be returned will be composed by a set of records. Each record contains three elements.
        -- The first element can be null or 'I'. If it is 'I', it will be placed in italics font.
        -- The second element will be the title of each record. It should be placed in bold font.
        -- The third element will be description. It should be placed in normal font.
    
        o_table         := table_varchar();
        l_title_adv_dir := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ADVANCE_DIRECTIVES_T004');
    
        FOR r_directives IN c_directives
        LOOP
        
            IF NOT pk_advanced_directives.get_adv_dir_desc(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => NULL,
                                                           i_epis_documentation => r_directives.id_epis_documentation,
                                                           o_desc_pat_adv_dir   => l_adv_dir,
                                                           o_pat_adv_dir        => l_advanced,
                                                           o_error              => l_error)
            THEN
                RAISE internal_exception;
            END IF;
        
            l_counter := o_table.count;
            o_table.extend(3);
            o_table(l_counter + 1) := '';
            o_table(l_counter + 2) := l_title_adv_dir || ':';
            o_table(l_counter + 3) := l_adv_dir;
        
            FOR r_directive_detail IN c_directive_detail(r_directives.id_epis_documentation)
            LOOP
                l_counter := o_table.count;
                o_table.extend(3);
                o_table(l_counter + 1) := '';
                o_table(l_counter + 2) := r_directive_detail.desc_doc_component;
                o_table(l_counter + 3) := r_directive_detail.desc_element;
            END LOOP;
            IF coalesce(dbms_lob.getlength(r_directives.notes), 0) > 0
            THEN
                l_counter := o_table.count;
                o_table.extend(3);
                o_table(l_counter + 1) := '';
                o_table(l_counter + 2) := '';
                o_table(l_counter + 3) := pk_string_utils.clob_to_plsqlvarchar2(r_directives.notes);
            END IF;
            l_counter := o_table.count;
            o_table.extend(3);
            o_table(l_counter + 1) := 'I';
            IF r_directives.desc_speciality IS NOT NULL
            THEN
                o_table(l_counter + 2) := r_directives.nick_name || ' (' || r_directives.desc_speciality || ') ' ||
                                          r_directives.dt_register;
            ELSE
                o_table(l_counter + 2) := r_directives.nick_name || ' ' || r_directives.dt_register;
            END IF;
            o_table(l_counter + 3) := NULL;
        END LOOP;
    
        RETURN o_table;
    
    END get_adv_directives_by_epis;
    --------------------------------

    /**
    * Returns the deepnav path from the first level to the given sbp level
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_sys_button_prop   Target id_sys_button_prop
    * @param o_deepnavs             The deepnav list
    * @param o_error                Error object
    *
    * @return  True if success, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/09/29
    */
    FUNCTION get_deepnav_path_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_deepnavs           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DEEPNAV_PATH_DESC';
        k_lf      CONSTANT VARCHAR2(0010 CHAR) := chr(10);
        k_nothing CONSTANT VARCHAR2(0010 CHAR) := '';
    BEGIN
        OPEN o_deepnavs FOR
            SELECT *
              FROM (SELECT REPLACE(REPLACE(pk_message.get_message(i_lang,
                                                                  i_prof,
                                                                  (SELECT sb.code_button
                                                                     FROM sys_button sb
                                                                    WHERE sb.id_sys_button = sbp.id_sys_button)),
                                           '-',
                                           ''),
                                   k_lf,
                                   k_nothing) sb_desc,
                           decode(LEVEL, 1, pk_alert_constant.g_yes, pk_alert_constant.g_no) LAST
                      FROM sys_button_prop sbp
                     START WITH sbp.id_sys_button_prop = i_id_sys_button_prop
                    CONNECT BY PRIOR sbp.id_btn_prp_parent = sbp.id_sys_button_prop
                     ORDER BY LEVEL DESC) t
             WHERE t.sb_desc IS NOT NULL;
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
            pk_types.open_my_cursor(o_deepnavs);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_deepnav_path_desc;

    /**
    * Returns the creation date of the parent record
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_epis_recommend    Epis recommend ID
    *
    * @return  True if success, false otherwise
    *
    * @author   Sofia Mendes
    * @version  2.6.3
    * @since    16-Dec-2013
    */
    FUNCTION get_epis_recommend_parent_dt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_recommend IN epis_recomend.id_epis_recomend%TYPE
    ) RETURN epis_recomend.dt_epis_recomend_tstz%TYPE IS
        l_func_name VARCHAR2(32) := 'GET_EPIS_RECOMMEND_PARENT_DT';
        l_date      epis_recomend.dt_epis_recomend_tstz%TYPE;
    BEGIN
        SELECT dt_epis_recomend_tstz
          INTO l_date
          FROM (SELECT connect_by_isleaf leaf, er.dt_epis_recomend_tstz
                  FROM epis_recomend er
                CONNECT BY PRIOR er.id_epis_recomend = er.id_epis_recomend_parent
                 START WITH er.id_epis_recomend = i_id_epis_recommend) t
         WHERE t.leaf = 1;
    
        RETURN l_date;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_debug('No data found: ' || i_id_epis_recommend);
        WHEN OTHERS THEN
            pk_alertlog.log_debug('i_id_epis_recommend: ' || i_id_epis_recommend || ' ERRO: ' || SQLERRM);
        
            RETURN NULL;
    END get_epis_recommend_parent_dt;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_ehr_visits;
/
