/*-- Last Change Revision: $Rev: 2027349 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_medical_decision AS
    --
    /********************************************************************************************
    * Get the last doctor note associated with an episode.
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_prof_cat               Professional category
    * @param o_interv_notes           Cursor containing all interval notes for the episode
    * @param o_error                  Error message
    *                        
    * @return                         TRUE if successfull, FALSE otherwise
    * 
    * @author                         Filipe Silva (based on GET_EPIS_INTERVAL_NOTES by José Brito)
    * @version                        1.0
    * @since                          200/08/25
    **********************************************************************************************/
    FUNCTION get_epis_last_doctor_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_prof_cat     IN category.flg_type%TYPE,
        o_doctor_notes OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        function_call_excep EXCEPTION;
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        l_function_name CONSTANT VARCHAR2(30) := 'get_epis_last_doctor_notes';
    BEGIN
        g_error := 'pk_touch_option.get_last_doc_area';
        IF NOT pk_touch_option.get_last_doc_area(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_episode            => i_epis,
                                                 i_doc_area           => pk_summary_page.g_doc_area_prg_notes_phy,
                                                 o_last_epis_doc      => l_last_epis_doc,
                                                 o_last_date_epis_doc => l_last_date_epis_doc,
                                                 o_error              => o_error)
        THEN
            RAISE function_call_excep;
        END IF;
    
        g_error := 'OPEN o_doctor_notes';
        OPEN o_doctor_notes FOR
            SELECT ed.notes desc_interval_notes
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = l_last_epis_doc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            g_error := 'The call to function ' || g_error || ' returned an error ';
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'Error calling internal function',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_doctor_notes);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_doctor_notes);
            RETURN FALSE;
    END get_epis_last_doctor_notes;
    /********************************************************************************************
    * Get the last nurse note associated with an episode.
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_prof_cat               Professional category
    * @param o_interv_notes           Cursor containing all interval notes for the episode
    * @param o_error                  Error message
    *                        
    * @return                         TRUE if successfull, FALSE otherwise
    * 
    * @author                         Filipe Silva (based on GET_EPIS_INTERVAL_NOTES by José Brito)
    * @version                        1.0
    * @since                          200/08/25
    **********************************************************************************************/
    FUNCTION get_epis_last_nurse_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        o_nursing_notes OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        function_call_excep EXCEPTION;
        l_last_desc_epis_recomend_clob epis_recomend.desc_epis_recomend_clob%TYPE;
        l_last_date_epis_recomend      epis_recomend.dt_epis_recomend_tstz%TYPE;
        l_last_id_touch_option         epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option       epis_documentation.dt_creation_tstz%TYPE;
        l_function_name CONSTANT VARCHAR2(30) := 'get_epis_last_nurse_notes';
    BEGIN
        g_error := 'pk_touch_option.get_last_doc_area';
        IF NOT pk_touch_option.get_last_doc_area(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_episode            => i_epis,
                                                 i_doc_area           => pk_summary_page.g_doc_area_nursing_notes,
                                                 o_last_epis_doc      => l_last_id_touch_option,
                                                 o_last_date_epis_doc => l_last_date_touch_option,
                                                 o_error              => o_error)
        THEN
            RAISE function_call_excep;
        END IF;
    
        --We need this because old data wasn't migrated
        BEGIN
            g_error := 'Find last epis_recomend';
            SELECT t.desc_epis_recomend_clob, t.dt_epis_recomend_tstz
              INTO l_last_desc_epis_recomend_clob, l_last_date_epis_recomend
              FROM (SELECT er.desc_epis_recomend_clob,
                           er.dt_epis_recomend_tstz,
                           rank() over(ORDER BY er.dt_epis_recomend_tstz DESC) rn
                      FROM epis_recomend er
                     WHERE er.id_episode = i_epis
                       AND er.flg_type = g_flg_nursing_notes) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_last_date_epis_recomend > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            g_error := 'OPEN o_nursing_notes - Old model';
            OPEN o_nursing_notes FOR
                SELECT l_last_desc_epis_recomend_clob desc_interval_notes
                  FROM dual;
        
        ELSIF l_last_date_touch_option > l_last_date_epis_recomend
              OR l_last_date_epis_recomend IS NULL
        THEN
            g_error := 'OPEN o_nursing_notes';
            OPEN o_nursing_notes FOR
                SELECT ed.notes desc_interval_notes
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation = l_last_id_touch_option;
        
        ELSE
            pk_types.open_my_cursor(o_nursing_notes);
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            g_error := 'The call to function ' || g_error || ' returned an error ';
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'Error calling internal function',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_nursing_notes);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_nursing_notes);
            RETURN FALSE;
    END get_epis_last_nurse_notes;

    /********************************************************************************************
    * Registar as revisões associadas ás análises e exames de um episódio   
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_request_review         request review
    * @param i_flg_type               Tipo de revisão sobre: A - Analysis ; E - Exam 
    * @param i_desc_test_review       Notas de revisão        
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_tests_review
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_request_review   IN tests_review.id_request%TYPE,
        i_flg_type         IN tests_review.flg_type%TYPE,
        i_desc_test_review IN tests_review.desc_tests_review%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char VARCHAR2(1);
        l_next tests_review.id_tests_review%TYPE;
        l_exception EXCEPTION;
        l_error_out t_error_out;
        --
        CURSOR c_exam IS
            SELECT 'X'
              FROM exam_req_det
             WHERE id_exam_req_det = i_request_review
               AND flg_status IN (g_exam_status_final, g_exam_status_read);
    
        CURSOR c_analysis IS
            SELECT 'X'
              FROM analysis_req_det
             WHERE id_analysis_req_det = i_request_review
               AND flg_status IN (g_analisys_status_final, g_analisys_status_red);
    
        CURSOR c_analysis_result IS
            SELECT 'X'
              FROM analysis_result
             WHERE id_analysis_result = i_request_review
                  --AND flg_orig_analysis IN ('S', 'O');
               AND flg_orig_analysis IN
                   (g_orig_analysis_periodic_obs, g_orig_analysis_ser_analysis, g_orig_analysis_woman_health);
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        IF i_flg_type = g_tests_type_exam
        THEN
            g_error := 'GET CURSOR C_EXAM';
            OPEN c_exam;
            FETCH c_exam
                INTO l_char;
            g_found := c_exam%FOUND;
            CLOSE c_exam;
        ELSIF i_flg_type = g_tests_type_analisys
        THEN
            g_error := 'GET CURSOR C_ANALYSIS';
            OPEN c_analysis;
            FETCH c_analysis
                INTO l_char;
            g_found := c_analysis%FOUND;
            CLOSE c_analysis;
        ELSE
            g_error := 'GET CURSOR C_ANALYSIS_RESULT';
            OPEN c_analysis_result;
            FETCH c_analysis_result
                INTO l_char;
            g_found := c_analysis_result%FOUND;
            CLOSE c_analysis_result;
        END IF;
        --
        IF g_found
        THEN
            g_error := 'GET SEQ_TESTS_REVIEW';
            SELECT seq_tests_review.nextval
              INTO l_next
              FROM dual;
            --  
            g_error := 'INSERT TESTS_REVIEW';
            INSERT INTO tests_review
                (id_tests_review, id_request, desc_tests_review, flg_type, dt_creation_tstz, id_professional)
            VALUES
                (l_next, i_request_review, i_desc_test_review, i_flg_type, g_sysdate_tstz, i_prof.id);
        END IF;
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_TESTS_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_TESTS_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Obter todas as revisões de exames e/ou análises de um episódio
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param o_tests_review           array with all revisões de exames e/ou análises de um episódio        
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/

    FUNCTION get_tests_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        o_tests_review OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_visit analysis_req.id_visit%TYPE;
    
        CURSOR c_visit IS
            SELECT id_visit
              FROM episode
             WHERE id_episode = i_epis;
    
        --l_task VARCHAR2(120);
    
    BEGIN
        --l_task  := 'AnalysisResultIcon';
        g_error := 'OPEN CURSOR';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        g_error := 'GET CURSOR O_TESTS_REVIEW';
        OPEN o_tests_review FOR
            SELECT DISTINCT eea.id_exam_req_det id_request,
                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                  NULL) desc_test,
                            eea.flg_status_det flg_status,
                            g_tests_type_exam flg_type,
                            (SELECT tr.desc_tests_review
                               FROM tests_review tr
                              WHERE tr.id_request = eea.id_exam_req_det
                                AND tr.flg_type = g_tests_type_exam
                                AND tr.dt_creation_tstz =
                                    (SELECT MAX(tr1.dt_creation_tstz)
                                       FROM tests_review tr1
                                      WHERE tr1.id_request = eea.id_exam_req_det
                                        AND tr1.flg_type = g_tests_type_exam)) desc_tests_review,
                            pk_date_utils.dt_chr_tsz(i_lang, eea.dt_begin, i_prof) date_target,
                            pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_begin, i_prof.institution, i_prof.software) hour_target,
                            -- desnormalização Susana Silva 16-10-08   
                            pk_utils.get_status_string(i_lang,
                                                       i_prof,
                                                       eea.status_str,
                                                       eea.status_msg,
                                                       eea.status_icon,
                                                       eea.status_flg) status_icon_name,
                            -- end                              
                            g_icon_type_exam type_icon_name
            
              FROM exams_ea eea, episode e
             WHERE (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode)
                  --RS 20080226 TI
                  --AND e.id_episode = i_epis
               AND e.id_visit = l_visit
               AND eea.flg_status_det IN (g_exam_status_final, g_exam_status_read)
            UNION ALL
            -- < DESNORM LMAIA 29-10-2008>
            SELECT DISTINCT lte.id_analysis_req_det id_request,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                      lte.id_sample_type,
                                                                      NULL) desc_test,
                            lte.flg_status_det,
                            g_tests_type_analisys flg_type,
                            (SELECT tr.desc_tests_review
                               FROM tests_review tr
                              WHERE tr.id_request = lte.id_analysis_req_det
                                AND tr.flg_type = g_tests_type_analisys
                                AND tr.dt_creation_tstz =
                                    (SELECT MAX(tr1.dt_creation_tstz)
                                       FROM tests_review tr1
                                      WHERE tr1.id_request = lte.id_analysis_req_det)) desc_tests_review,
                            pk_date_utils.dt_chr_tsz(i_lang, ar.dt_begin_tstz, i_prof) date_target,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             ar.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_target,
                            pk_utils.get_status_string(i_lang,
                                                       i_prof,
                                                       lte.status_str,
                                                       lte.status_msg,
                                                       lte.status_icon,
                                                       lte.status_flg) status_icon_name,
                            g_icon_type_analysis type_icon_name
              FROM (SELECT ar.*, e.flg_status flg_status_epis
                      FROM analysis_req ar, analysis_req_det ard, episode e
                     WHERE (ar.id_episode = e.id_episode OR ard.id_episode_origin = e.id_episode)
                       AND e.id_episode = i_epis
                       AND e.id_visit = l_visit
                       AND ar.id_analysis_req = ard.id_analysis_req) ar,
                   lab_tests_ea lte,
                   analysis_result ares
             WHERE ar.id_analysis_req = lte.id_analysis_req
               AND lte.flg_status_det IN (g_analisys_status_final, g_analisys_status_red)
               AND ares.id_analysis_req_det = lte.id_analysis_req_det
                  -- Remover análises seriadas pq são apanhadas no union abaixo
               AND nvl(ares.flg_orig_analysis, 'X') != 'S'
            -- < END DESNORM >
            UNION ALL
            SELECT DISTINCT ar.id_analysis_result id_request,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                      ar.id_sample_type,
                                                                      NULL) desc_test,
                            'L' flg_status,
                            'R' flg_type,
                            (SELECT tr.desc_tests_review
                               FROM tests_review tr
                              WHERE tr.id_request = ar.id_analysis_result
                                AND tr.flg_type = 'R'
                                AND tr.dt_creation_tstz =
                                    (SELECT MAX(tr1.dt_creation_tstz)
                                       FROM tests_review tr1
                                      WHERE tr1.id_request = ar.id_analysis_result)) desc_tests_review,
                            pk_date_utils.dt_chr_tsz(i_lang, ar.dt_analysis_result_tstz, i_prof) date_target,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             ar.dt_analysis_result_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_target,
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_display_type_icon,
                                                                 'F',
                                                                 NULL,
                                                                 NULL,
                                                                 'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                 NULL,
                                                                 NULL,
                                                                 pk_alert_constant.g_color_icon_dark_grey) status_icon_name,
                            g_icon_type_analysis type_icon_name
              FROM analysis_result_par arp
             INNER JOIN analysis_result ar
                ON ar.id_analysis_result = arp.id_analysis_result
              LEFT OUTER JOIN analysis_desc ad
                ON ad.id_analysis_parameter = arp.id_analysis_parameter
               AND ad.value = to_char(arp.desc_analysis_result)
             INNER JOIN analysis_param ap
                ON ap.id_analysis_parameter = arp.id_analysis_parameter
             INNER JOIN analysis_param_funcionality apf
                ON ap.id_analysis_param = apf.id_analysis_param
             WHERE ar.id_visit = l_visit
               AND ar.id_institution = i_prof.institution
               AND ar.dt_sample IS NOT NULL
                  --
               AND apf.flg_type = 'S'
               AND ap.flg_available = g_available
               AND ap.id_software = i_prof.software
               AND ap.id_institution = i_prof.institution
               AND arp.id_analysis_parameter = ap.id_analysis_parameter
             ORDER BY date_target DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_TESTS_REVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_tests_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    --
    /**
    * This function returns a full result description for the exam_result passed in the i_epis_context var
    * 
    * @param i_lang language id
    * @param i_prof user data
    * @param i_episode episode id
    * @param i_epis_context exam_result id
    *
    * @return a string with the full result
    * 
    * @author                         João Eiras
    * @version                        1.0
    * @since                          2007/01/31
    */
    FUNCTION get_exam_result_template_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_context IN epis_documentation.id_epis_context%TYPE
    ) RETURN VARCHAR IS
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_doc_component      doc_component.id_doc_component%TYPE;
        l_id_episode            episode.id_episode%TYPE;
        l_desc_component        VARCHAR2(4000);
        l_desc_element          VARCHAR2(4000);
        l_desc_info             VARCHAR2(4000);
    
        l_res    pk_types.cursor_type;
        l_result VARCHAR2(10000);
        l_notes  epis_documentation.notes%TYPE;
        l_exception EXCEPTION;
        l_error_out t_error_out;
    BEGIN
    
        BEGIN
            g_error := 'GET EPIS_DOCUMENTATION';
            SELECT ed.id_epis_documentation, ed.notes
              INTO l_id_epis_documentation, l_notes
              FROM epis_documentation ed
             WHERE ed.id_episode = i_episode
               AND ed.id_doc_area = g_doc_area_exam
               AND ed.id_epis_context = i_epis_context;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN '';
        END;
    
        IF NOT pk_summary_page.get_summ_last_doc_area(i_lang,
                                                      i_prof,
                                                      l_id_epis_documentation,
                                                      g_doc_area_exam,
                                                      l_res,
                                                      l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        LOOP
            FETCH l_res
                INTO l_id_doc_component, l_id_episode, l_desc_component, l_desc_element, l_desc_info;
            EXIT WHEN l_res%NOTFOUND;
        
            IF l_result IS NULL
               AND (l_desc_component IS NOT NULL OR l_desc_element IS NOT NULL)
            THEN
                l_result := l_desc_component || ' ' || l_desc_element;
            ELSIF (l_desc_component IS NOT NULL OR l_desc_element IS NOT NULL)
            THEN
                l_result := l_result || chr(10) || l_desc_component || ' ' || l_desc_element;
            END IF;
        
        END LOOP;
    
        CLOSE l_res;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_EXAM_RESULT_TEMPLATE_DET',
                                              l_error_out);
            CLOSE l_res;
            RETURN '';
        
    END;

    /********************************************************************************************
    * Obter as revisões e resultados de um exame e/ou análise de um episódio 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_request_review         request review    
    * @param i_flg_type               Tipo de revisão sobre: A - Analysis ;E - Exam     
    * @param o_tests_result           Listar os resultados de análises e exames do episódio         
    * @param o_tests_review           Listar as revisões de exames e análises de um episódio    
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_tests_review_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_request_review IN tests_review.id_request%TYPE,
        i_flg_type       IN tests_review.flg_type%TYPE,
        o_tests_result   OUT pk_types.cursor_type,
        o_tests_review   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_type = g_tests_type_exam
        THEN
            g_error := 'GET CURSOR O_TESTS_RESULT(E)';
            OPEN o_tests_result FOR
                SELECT eea.id_exam_req_det id_request,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_test,
                       eea.desc_result notes_result,
                       NULL unit_measure,
                       pk_date_utils.dt_chr_tsz(i_lang, eea.dt_result, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_result, i_prof.institution, i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) name_prof,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, er.id_professional, eea.dt_result, i_epis) desc_speciality
                  FROM exam_result er, exams_ea eea
                 WHERE eea.id_exam_req_det = er.id_exam_req_det
                   AND eea.id_exam_req_det = i_request_review
                   AND er.flg_status(+) != pk_exam_constant.g_exam_result_cancel;
        ELSIF i_flg_type = g_tests_type_analisys
        THEN
            g_error := 'GET CURSOR O_TESTS_RESULT(A)';
            OPEN o_tests_result FOR
                SELECT ar.id_analysis_req_det id_request,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ar.id_sample_type,
                                                                 NULL) desc_test,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'P',
                                                                 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                 arp.id_analysis_parameter,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ar.id_sample_type,
                                                                 NULL) || chr(10) ||
                       nvl(TRIM(arp.desc_analysis_result),
                           (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                           arp.analysis_result_value_2)) notes_result,
                       pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure) unit_measure,
                       pk_date_utils.dt_chr_tsz(i_lang, ar.dt_analysis_result_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ar.dt_analysis_result_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_professional) name_prof,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        ar.id_professional,
                                                        ar.dt_analysis_result_tstz,
                                                        i_epis) desc_speciality
                  FROM analysis_result ar
                  JOIN analysis_result_par arp
                    ON arp.id_analysis_result = ar.id_analysis_result
                 WHERE ar.id_analysis_req_det = i_request_review
                   AND arp.id_cancel_reason IS NULL;
        ELSE
            g_error := 'GET CURSOR O_TESTS_RESULT(A)';
            OPEN o_tests_result FOR
                SELECT ar.id_analysis_result id_request,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ar.id_sample_type,
                                                                 NULL) desc_test,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'P',
                                                                 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                 arp.id_analysis_parameter,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ar.id_sample_type,
                                                                 NULL) || chr(10) ||
                       nvl(TRIM(arp.desc_analysis_result),
                           (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                           arp.analysis_result_value_2)) notes_result,
                       pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure) unit_measure,
                       pk_date_utils.dt_chr_tsz(i_lang, ar.dt_analysis_result_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ar.dt_analysis_result_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_professional) name_prof,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        ar.id_professional,
                                                        ar.dt_analysis_result_tstz,
                                                        i_epis) desc_speciality
                  FROM analysis_result ar, analysis_result_par arp
                 WHERE ar.id_analysis_result = i_request_review
                   AND arp.id_analysis_result = ar.id_analysis_result
                   AND arp.id_cancel_reason IS NULL;
        END IF;
        --
        g_error := 'GET CURSOR O_TESTS_REVIEW';
        IF i_flg_type = g_tests_type_exam
        THEN
            OPEN o_tests_review FOR
                SELECT eea.id_exam_req_det id_request,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_test,
                       tr.desc_tests_review,
                       pk_date_utils.date_send_tsz(i_lang, tr.dt_creation_tstz, i_prof) dt_tests_review,
                       pk_date_utils.dt_chr_tsz(i_lang, tr.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        tr.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, tr.id_professional) prof_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, tr.id_professional, tr.dt_creation_tstz, i_epis) desc_speciality
                  FROM tests_review tr, exams_ea eea
                 WHERE eea.id_exam_req_det = tr.id_request(+)
                   AND eea.id_exam_req_det = i_request_review
                   AND tr.flg_type(+) = g_tests_type_exam
                 ORDER BY dt_tests_review DESC;
        ELSIF i_flg_type = g_tests_type_analisys
        THEN
            OPEN o_tests_review FOR
                SELECT ard.id_analysis_req_det id_request,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type,
                                                                 NULL) desc_test,
                       tr.desc_tests_review,
                       pk_date_utils.date_send_tsz(i_lang, tr.dt_creation_tstz, i_prof) dt_tests_review,
                       pk_date_utils.dt_chr_tsz(i_lang, tr.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        tr.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, tr.id_professional) prof_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, tr.id_professional, tr.dt_creation_tstz, i_epis) desc_speciality
                  FROM analysis_req_det ard, tests_review tr
                 WHERE ard.id_analysis_req_det = tr.id_request(+)
                   AND ard.id_analysis_req_det = i_request_review
                   AND tr.flg_type(+) = g_tests_type_analisys
                 ORDER BY dt_tests_review DESC;
        ELSE
            OPEN o_tests_review FOR
                SELECT ares.id_analysis_result id_request,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || ares.id_analysis,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ares.id_sample_type,
                                                                 NULL) desc_test,
                       tr.desc_tests_review,
                       pk_date_utils.date_send_tsz(i_lang, tr.dt_creation_tstz, i_prof) dt_tests_review,
                       pk_date_utils.dt_chr_tsz(i_lang, tr.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        tr.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, tr.id_professional) prof_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, tr.id_professional, tr.dt_creation_tstz, i_epis) desc_speciality
                  FROM analysis_result ares, tests_review tr
                 WHERE ares.id_analysis_result = tr.id_request(+)
                   AND ares.id_analysis_result = i_request_review
                   AND tr.flg_type(+) = 'R'
                 ORDER BY dt_tests_review DESC;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_TESTS_REVIEW_DET',
                                              o_error);
            pk_types.open_my_cursor(o_tests_review);
            pk_types.open_my_cursor(o_tests_result);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Obter TODOS os resultados de um exame e/ou análise de um episódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               Tipo de revisão sobre: A - Analysis ;E - Exam     
    * @param i_request_det            request detail id   
    * @param o_tests_result           Listar os resultados dos exames e análises de um episódio  
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_tests_result
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_flg_type     IN tests_review.flg_type%TYPE,
        i_request_det  IN tests_review.id_request%TYPE,
        o_tests_result OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_type = g_tests_type_exam
        THEN
            g_error := 'GET CURSOR O_TESTS_RESULT(E)';
            OPEN o_tests_result FOR
                SELECT eea.id_exam_req_det id_request,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_test,
                       NULL desc_param,
                       er.notes notes_result,
                       pk_date_utils.dt_chr_tsz(i_lang, eea.dt_result, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_result, i_prof.institution, i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, eea.dt_result, i_epis) desc_speciality
                  FROM exam_result er, professional p, exams_ea eea
                 WHERE eea.id_exam_req_det = er.id_exam_req_det
                   AND eea.id_exam_req_det = i_request_det
                   AND er.id_professional(+) = p.id_professional
                   AND er.flg_status(+) != pk_exam_constant.g_exam_result_cancel;
        
        ELSIF i_flg_type = g_tests_type_analisys
        THEN
            g_error := 'GET CURSOR O_TESTS_RESULT(A)';
            OPEN o_tests_result FOR
                SELECT ard.id_analysis_req_det id_request,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 concat('ANALYSIS.CODE_ANALYSIS.', ard.id_analysis),
                                                                 concat('SAMPLE_TYPE.CODE_SAMPLE_TYPE.',
                                                                        ard.id_sample_type),
                                                                 NULL) desc_test,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'P',
                                                                 concat('ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.',
                                                                        param.id_analysis_parameter),
                                                                 concat('SAMPLE_TYPE.CODE_SAMPLE_TYPE.',
                                                                        ard.id_sample_type),
                                                                 NULL) desc_param,
                       nvl(TRIM(arp.desc_analysis_result),
                           (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                           arp.analysis_result_value_2)) ||
                       decode(nvl(arp.desc_unit_measure,
                                  pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure)),
                              NULL,
                              '',
                              ' ' ||
                              nvl(arp.desc_unit_measure,
                                  pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure))) notes_result,
                       pk_date_utils.dt_chr_tsz(i_lang, ar.dt_analysis_result_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ar.dt_analysis_result_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        p.id_professional,
                                                        ar.dt_analysis_result_tstz,
                                                        i_epis) desc_speciality
                  FROM analysis_req_det    ard,
                       analysis_result     ar,
                       analysis_result_par arp,
                       professional        p,
                       analysis_parameter  param
                 WHERE ard.id_analysis_req_det = ar.id_analysis_req_det
                   AND ard.id_analysis_req_det = i_request_det
                   AND arp.id_analysis_result = ar.id_analysis_result
                   AND arp.id_cancel_reason IS NULL
                   AND ar.id_professional(+) = p.id_professional
                   AND arp.id_analysis_parameter = param.id_analysis_parameter;
        ELSE
            g_error := 'GET CURSOR O_TESTS_RESULT(R)';
            OPEN o_tests_result FOR
                SELECT ar.id_analysis_result id_request,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 concat('ANALYSIS.CODE_ANALYSIS.', ar.id_analysis),
                                                                 concat('SAMPLE_TYPE.CODE_SAMPLE_TYPE.',
                                                                        ar.id_sample_type),
                                                                 NULL) desc_test,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'P',
                                                                 concat('ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.',
                                                                        param.id_analysis_parameter),
                                                                 concat('SAMPLE_TYPE.CODE_SAMPLE_TYPE.',
                                                                        ar.id_sample_type),
                                                                 NULL) desc_param,
                       nvl(TRIM(arp.desc_analysis_result),
                           (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                           arp.analysis_result_value_2)) ||
                       decode(nvl(arp.desc_unit_measure,
                                  pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure)),
                              NULL,
                              '',
                              ' ' ||
                              nvl(arp.desc_unit_measure,
                                  pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || arp.id_unit_measure))) notes_result,
                       pk_date_utils.dt_chr_tsz(i_lang, ar.dt_analysis_result_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ar.dt_analysis_result_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        p.id_professional,
                                                        ar.dt_analysis_result_tstz,
                                                        i_epis) desc_speciality
                  FROM analysis_result ar, analysis_result_par arp, professional p, analysis_parameter param
                 WHERE ar.id_analysis_result = i_request_det
                   AND arp.id_analysis_result = ar.id_analysis_result
                   AND arp.id_cancel_reason IS NULL
                   AND ar.id_professional(+) = p.id_professional
                   AND arp.id_analysis_parameter = param.id_analysis_parameter;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_TESTS_RESULT',
                                              o_error);
            pk_types.open_my_cursor(o_tests_result);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Registar as notas de tratamento para a medicação e/ou procedimento de um episódio  
    *
    * @param i_lang                       The language ID
    * @param i_prof                       Object (professional ID, institution ID, software ID)
    * @param i_epis                       the episode ID
    * @param i_treatment                  treatment id
    * @param i_flg_type                   Tipo de revisão sobre: I - Intervention ;D - Drug       
    * @param i_desc_treat_manag           treatment notes
    * @param o_id_treatment_management    treatment management id
    * @param o_error                      Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_treat_management_no_comit
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis                    IN episode.id_episode%TYPE,
        i_treatment               IN treatment_management.id_treatment%TYPE,
        i_flg_type                IN treatment_management.flg_type%TYPE,
        i_desc_treat_manag        IN treatment_management.desc_treatment_management%TYPE,
        o_id_treatment_management OUT treatment_management.id_treatment_management%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char      VARCHAR2(1);
        l_next      treatment_management.id_treatment_management%TYPE;
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_rows table_varchar := table_varchar();
        --
        CURSOR c_interv IS
            SELECT 'X'
              FROM interv_presc_det
             WHERE id_interv_presc_det = i_treatment
               AND flg_status IN (g_interv_status_final, g_interv_status_curso, g_interv_status_inter);
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        IF i_flg_type = g_treat_type_interv
        THEN
            g_error := 'GET CURSOR C_INTERV';
            OPEN c_interv;
            FETCH c_interv
                INTO l_char;
            g_found := c_interv%FOUND;
            CLOSE c_interv;
        ELSE
            g_error := 'CALL TO PK_API_PFH_IN.HAS_ADMINISTRATIONS';
            l_char  := pk_api_pfh_in.has_administrations(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_treatment);
        
            IF l_char = 'Y'
            THEN
                g_found := TRUE;
            ELSE
                g_found := FALSE;
            END IF;
        END IF;
        --
    
        IF g_found
        THEN
            g_error := 'GET SEQ_TREATMENT_MANAGEMENT';
            l_next  := ts_treatment_management.next_key();
            --  
            g_error := 'INSERT TREATMENT_MANAGEMENT';
            ts_treatment_management.ins(id_treatment_management_in   => l_next,
                                        id_treatment_in              => i_treatment,
                                        desc_treatment_management_in => i_desc_treat_manag,
                                        id_professional_in           => i_prof.id,
                                        flg_type_in                  => i_flg_type,
                                        dt_creation_tstz_in          => g_sysdate_tstz,
                                        rows_out                     => l_rows);
        
            g_error := 'PROCESS INSERT treatment_management WITH id_treatment_management: ' || l_next;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => 'SET_TREAT_MANAGEMENT_NO_COMIT');
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TREATMENT_MANAGEMENT',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            o_id_treatment_management := l_next;
        ELSE
            o_id_treatment_management := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_TREAT_MANAGEMENT_NO_COMIT',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_TREAT_MANAGEMENT_NO_COMIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_treat_management_no_comit;
    --
    /********************************************************************************************
    * Registar as notas de tratamento para a medicação e/ou procedimento de um episódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_treatment              treatment id
    * @param i_flg_type               Tipo de revisão sobre: I - Intervention ;D - Drug       
    * @param i_desc_treat_manag       treatment notes
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_treat_management
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_treatment        IN treatment_management.id_treatment%TYPE,
        i_flg_type         IN treatment_management.flg_type%TYPE,
        i_desc_treat_manag IN treatment_management.desc_treatment_management%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_treatment_management treatment_management.id_treatment_management%TYPE;
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_medical_decision.set_treat_management_no_comit(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_epis                    => i_epis,
                                                                 i_treatment               => i_treatment,
                                                                 i_flg_type                => i_flg_type,
                                                                 i_desc_treat_manag        => i_desc_treat_manag,
                                                                 o_id_treatment_management => l_id_treatment_management,
                                                                 o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_TREAT_MANAGEMENT',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_TREAT_MANAGEMENT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar todas as notas de tratamento associadas à medicação e/ou procedimento de um epsisódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param o_treat_manag            Listar para a medicação e/ou procedimento as suas notas de tratamento
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    *
    * UPDATE - ALERT-49015
    * only procedures with at least one execution should appear in grid, despite its status
    * @author  Telmo
    * @version 2.5.0.7
    * @date    30-10-2009
    **********************************************************************************************/
    FUNCTION get_treat_manag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        o_treat_manag OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CURSOR O_TREAT_MANAG';
        OPEN o_treat_manag FOR
        -- medication part
            SELECT treat.id_treat_manag,
                   treat.desc_treat_manag,
                   treat.desc_dosage,
                   --treat.id_status,
                   treat.flg_status,
                   treat.desc_status,
                   treat.flg_type,
                   treat.desc_treatment_management,
                   treat.date_target,
                   treat.hour_target,
                   treat.status_icon_name,
                   treat.type_icon_name,
                   treat.dt_server
              FROM TABLE(pk_api_pfh_in.get_treat_manag(i_lang => i_lang, i_prof => i_prof, i_epis => i_epis)) treat
            UNION ALL
            --procedures part
            SELECT pea.id_interv_presc_det id_treat_manag,
                   pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || pea.id_intervention,
                                                              NULL) desc_treat_manag,
                   NULL desc_dosage,
                   --NULL id_status,
                   pea.flg_status_det flg_status,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang) desc_status,
                   g_treat_type_interv flg_type,
                   (SELECT tm.desc_treatment_management
                      FROM treatment_management tm
                     WHERE tm.id_treatment = pea.id_interv_presc_det
                       AND tm.flg_type = g_treat_type_interv
                       AND tm.dt_creation_tstz = (SELECT MAX(tm1.dt_creation_tstz)
                                                    FROM treatment_management tm1
                                                   WHERE tm1.id_treatment = pea.id_interv_presc_det
                                                     AND tm1.flg_type = g_treat_type_interv)) desc_treatment_management,
                   pk_date_utils.dt_chr_tsz(i_lang, pea.dt_begin_req, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, pea.dt_begin_req, i_prof.institution, i_prof.software) hour_target,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              pea.status_str,
                                              pea.status_msg,
                                              pea.status_icon,
                                              pea.status_flg) status_icon_name,
                   g_icon_type_interv type_icon_name,
                   g_sysdate_char dt_server
              FROM procedures_ea pea,
                   (SELECT ep.id_episode, ep.flg_status
                      FROM episode e
                      JOIN episode ep
                        ON ep.id_visit = e.id_visit
                     WHERE e.id_episode = i_epis) epis
             WHERE pea.flg_status_det IN (g_interv_status_final, g_interv_status_curso, g_interv_status_inter)
               AND (pea.id_episode IS NULL AND epis.id_episode = pea.id_episode_origin OR
                   epis.id_episode = pea.id_episode)
               AND EXISTS (SELECT 1
                      FROM interv_presc_plan ipp
                     WHERE ipp.id_interv_presc_det = pea.id_interv_presc_det)
             ORDER BY date_target DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_TREAT_MANAG',
                                              o_error);
            pk_types.open_my_cursor(o_treat_manag);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar as notas de tratamento associadas a uma medicação e/ou procedimento de um epsisódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               Tipo de revisão sobre: I - Intervention ;D - Drug
    * @param i_treat_manag            treatment management id
    * @param o_treat_manag            Listar para a medicação e/ou procedimento as suas notas de tratamento
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_treat_manag_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_flg_type    IN treatment_management.flg_type%TYPE,
        i_treat_manag IN treatment_management.id_treatment%TYPE,
        o_treat_manag OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_TREAT_MANAG';
        OPEN o_treat_manag FOR
        -- medication
            SELECT treat.id_treat_manag,
                   treat.desc_treat_manag,
                   treat.desc_treatment_management,
                   treat.dt_treat_manag,
                   treat.date_target,
                   treat.hour_target,
                   treat.timestamp_target,
                   treat.prof_name,
                   treat.desc_speciality
              FROM TABLE(pk_api_pfh_in.get_treat_manag_det(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_epis        => i_epis,
                                                           i_flg_type    => i_flg_type,
                                                           i_treat_manag => i_treat_manag)) treat
            UNION ALL
            SELECT DISTINCT ipd.id_interv_presc_det id_treat_manag,
                            pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_treat_manag,
                            tm.desc_treatment_management,
                            pk_date_utils.date_send_tsz(i_lang, tm.dt_creation_tstz, i_prof) dt_treat_manag,
                            pk_date_utils.dt_chr_tsz(i_lang, tm.dt_creation_tstz, i_prof) date_target,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             tm.dt_creation_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_target,
                            pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                               tm.dt_creation_tstz,
                                                               i_prof.institution,
                                                               i_prof.software) timestamp_target,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             p.id_professional,
                                                             tm.dt_creation_tstz,
                                                             i_epis) desc_speciality
              FROM intervention         i,
                   interv_presc_det     ipd,
                   procedures_ea        pea,
                   treatment_management tm,
                   professional         p,
                   speciality           s
             WHERE i.id_intervention = ipd.id_intervention
               AND tm.id_treatment(+) = ipd.id_interv_presc_det
               AND tm.flg_type(+) = i_flg_type
               AND ipd.id_interv_presc_det = i_treat_manag
               AND p.id_professional(+) = tm.id_professional
               AND s.id_speciality(+) = p.id_speciality
               AND (pea.id_episode IS NULL AND pea.id_episode_origin = i_epis OR pea.id_episode = i_epis)
            
             ORDER BY dt_treat_manag DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_TREAT_MANAG_DET',
                                              o_error);
            pk_types.open_my_cursor(o_treat_manag);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Registar as notas de atendimento associadas a um episódio   
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_profile_review         review profile 
    * @param i_prof_review            review professional id
    * @param i_dt_review_str          Data da avaliação 
    * @param i_notes_reviewed         Notas de avaliação
    * @param i_notes_additional       Notas adicionais    
    * @param i_flg_agree                  
    * @param i_flg_type               
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_attending_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_profile_review   IN epis_attending_notes.profile_reviewed%TYPE,
        i_prof_review      IN epis_attending_notes.id_prof_reviewed%TYPE,
        i_dt_review_str    IN VARCHAR2,
        i_notes_reviewed   IN epis_attending_notes.notes_reviewed%TYPE,
        i_notes_additional IN epis_attending_notes.notes_additional%TYPE,
        i_flg_agree        IN epis_attending_notes.flg_agree%TYPE,
        i_flg_type         IN epis_attending_notes.flg_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char      VARCHAR2(1);
        l_next      epis_attending_notes.id_epis_attending_notes%TYPE;
        i_dt_review TIMESTAMP WITH LOCAL TIME ZONE;
        l_exception EXCEPTION;
        l_error_out t_error_out;
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        i_dt_review := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_review_str, NULL);
        --    
        g_error := 'GET CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
        --
        IF g_found
        THEN
            g_error := 'GET SEQ_EPIS_ATTENDING_NOTES';
            SELECT seq_epis_attending_notes.nextval
              INTO l_next
              FROM dual;
            --  
            IF i_flg_type = 'A'
            THEN
                g_error := 'INSERT EPIS_ATTENDING_NOTES (1)';
                INSERT INTO epis_attending_notes
                    (id_epis_attending_notes,
                     id_professional,
                     dt_creation_tstz,
                     profile_reviewed,
                     id_prof_reviewed,
                     id_episode,
                     dt_reviewed_tstz,
                     notes_reviewed,
                     notes_additional,
                     adw_last_update,
                     flg_agree)
                VALUES
                    (l_next,
                     i_prof.id,
                     g_sysdate_tstz,
                     i_profile_review,
                     i_prof_review,
                     i_epis,
                     i_dt_review,
                     i_notes_reviewed,
                     i_notes_additional,
                     g_sysdate,
                     i_flg_agree);
            ELSE
                IF i_flg_type = 'C'
                THEN
                    g_error := 'INSERT EPIS_ATTENDING_NOTES (2)';
                    INSERT INTO epis_attending_notes
                        (id_epis_attending_notes,
                         id_professional,
                         dt_creation_tstz,
                         profile_reviewed,
                         id_prof_reviewed,
                         id_episode,
                         dt_reviewed_tstz,
                         notes_additional,
                         adw_last_update,
                         flg_type)
                    VALUES
                        (l_next,
                         i_prof.id,
                         g_sysdate_tstz,
                         i_profile_review,
                         i_prof_review,
                         i_epis,
                         i_dt_review,
                         i_notes_additional,
                         g_sysdate,
                         i_flg_type);
                END IF;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_ATTENDING_NOTES',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_ATTENDING_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Obter as notas de atendimento associadas a um episódio    
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               
    * @param o_prof_reviewed          Listar o perfil e nome do avaliado
    * @param o_attend_notes           Listar as notas de avaliação
    * @param o_notes_addit            Listar as notas adicionais de avaliação
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_attending_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_flg_type      IN epis_attending_notes.flg_type%TYPE,
        o_prof_reviewed OUT pk_types.cursor_type,
        o_attend_notes  OUT pk_types.cursor_type,
        o_notes_addit   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_type = 'A'
        THEN
            g_error := 'GET CURSOR O_PROF_REVIEWED(1)';
            OPEN o_prof_reviewed FOR
                SELECT ean.id_epis_attending_notes,
                       pk_message.get_message(i_lang, 'ATTENDING_NOTES_M001') desc_prof_reviewed, -- I have reviewed the notes of: 
                       ean.id_prof_reviewed prof_reviewed,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof_reviewed,
                       ean.profile_reviewed
                  FROM epis_attending_notes ean, professional p
                 WHERE ean.id_episode = i_epis
                   AND ean.id_prof_reviewed = p.id_professional(+)
                 ORDER BY ean.dt_creation_tstz DESC;
            --
            g_error := 'GET CURSOR O_ATTEND_NOTES(1)';
            OPEN o_attend_notes FOR
                SELECT ean.id_epis_attending_notes,
                       decode(ean.notes_reviewed,
                              NULL,
                              pk_message.get_message(i_lang, 'ATTENDING_NOTES_M002'), -- I agree with all.
                              pk_message.get_message(i_lang, 'ATTENDING_NOTES_M003')) desc_attend_notes, -- I agree with all except  
                       decode(ean.flg_agree, 'C', ean.notes_reviewed, NULL) notes_reviewed,
                       decode(ean.flg_agree,
                              'C',
                              decode(ean.notes_reviewed,
                                     NULL,
                                     pk_message.get_message(i_lang, 'ATTENDING_NOTES_M007'),
                                     pk_message.get_message(i_lang, 'ATTENDING_NOTES_M009')),
                              'D',
                              pk_message.get_message(i_lang, 'ATTENDING_NOTES_M008')) desc_flg_agree
                  FROM epis_attending_notes ean, professional p, speciality s
                 WHERE ean.id_episode = i_epis
                   AND ean.id_professional = p.id_professional(+)
                   AND p.id_speciality = s.id_speciality(+)
                 ORDER BY ean.dt_creation_tstz DESC;
            --
            g_error := 'GET CURSOR O_NOTES_ADDIT(1)';
            OPEN o_notes_addit FOR
                SELECT ean.id_epis_attending_notes,
                       decode(ean.notes_additional, NULL, NULL, pk_message.get_message(i_lang, 'ATTENDING_NOTES_M004')) desc_notes_addit, --Additionally 
                       ean.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                       ean.notes_additional,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, ean.dt_reviewed_tstz, i_epis) desc_spec,
                       pk_date_utils.dt_chr_tsz(i_lang, ean.dt_reviewed_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ean.dt_reviewed_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_date_utils.date_char_tsz(i_lang, ean.dt_reviewed_tstz, i_prof.institution, i_prof.software) date_hour_target
                  FROM epis_attending_notes ean, professional p, speciality s
                 WHERE ean.id_episode = i_epis
                   AND ean.id_professional = p.id_professional(+)
                   AND p.id_speciality = s.id_speciality(+)
                 ORDER BY ean.dt_creation_tstz DESC;
        ELSE
            IF i_flg_type = 'C'
            THEN
                g_error := 'GET CURSOR O_PROF_REVIEWED(2)';
                OPEN o_prof_reviewed FOR
                    SELECT ean.id_epis_attending_notes,
                           pk_message.get_message(i_lang, 'ATTENDING_NOTES_M001') desc_prof_reviewed, -- I have reviewed the notes of: 
                           ean.id_prof_reviewed prof_reviewed,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof_reviewed,
                           ean.profile_reviewed
                      FROM epis_attending_notes ean, professional p
                     WHERE ean.id_episode = i_epis
                       AND ean.id_prof_reviewed = p.id_professional(+)
                     ORDER BY ean.dt_creation_tstz DESC;
                --
                g_error := 'GET CURSOR O_NOTES_ADDIT(2)';
                pk_types.open_my_cursor(o_attend_notes);
                --            
                g_error := 'GET CURSOR O_NOTES_ADDIT(2)';
                OPEN o_notes_addit FOR
                    SELECT ean.id_epis_attending_notes,
                           decode(ean.notes_additional,
                                  NULL,
                                  NULL,
                                  pk_message.get_message(i_lang, 'ATTENDING_NOTES_M004')) desc_notes_addit, --Additionally 
                           ean.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                           ean.notes_additional,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            ean.dt_reviewed_tstz,
                                                            i_epis) desc_spec,
                           pk_date_utils.dt_chr_tsz(i_lang, ean.dt_reviewed_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            ean.dt_reviewed_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ean.dt_reviewed_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) date_hour_target
                      FROM epis_attending_notes ean, professional p, speciality s
                     WHERE ean.id_episode = i_epis
                       AND ean.id_professional = p.id_professional(+)
                       AND p.id_speciality = s.id_speciality(+)
                     ORDER BY ean.dt_creation_tstz DESC;
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
                                              'PK_MEDICAL_DECISION',
                                              'GET_ATTENDING_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_prof_reviewed);
            pk_types.open_my_cursor(o_attend_notes);
            pk_types.open_my_cursor(o_notes_addit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Obter o detalhe de uma nota de atendimento de um episódio     
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_attending_notes        attending notes id               
    * @param o_attend_notes           Listar o detalhe de uma nota de atendimento 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_attending_notes_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_attending_notes IN epis_attending_notes.id_epis_attending_notes%TYPE,
        o_attend_notes    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_ATTEND_NOTES';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_ATTENDING_NOTES_DET',
                                              o_error);
            pk_types.open_my_cursor(o_attend_notes);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Lista dos perfis disponiveis para a urgência      
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_profile                Lista dos perfis disponiveis
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_profile_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_profile OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market institution.id_market%TYPE;
    BEGIN
    
        g_error := 'GET ID_MARKET';
        SELECT id_market
          INTO l_id_market
          FROM institution
         WHERE id_institution = i_prof.institution;
    
        g_error := 'GET CURSOR O_PROFILE';
        OPEN o_profile FOR
            SELECT DISTINCT pt.id_profile_template,
                            pk_message.get_message(i_lang, pt.code_profile_template) intern_name_templ
              FROM profile_template pt
             INNER JOIN prof_profile_template ppt
                ON (pt.id_profile_template = ppt.id_profile_template)
             INNER JOIN profile_template_market pm
                ON (pt.id_profile_template = pm.id_profile_template)
             WHERE pt.id_software = i_prof.software
               AND nvl(pt.id_institution, i_prof.institution) = i_prof.institution
               AND pt.flg_available = pk_alert_constant.g_yes
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND pt.flg_type IN (g_flg_type_d, g_flg_type_n)
               AND pm.id_market IN (l_id_market, 0)
                  -- only profiles that has professionals with registries in patient record 
               AND EXISTS
             (SELECT /*+no_unnest*/
                     epr.id_professional
                      FROM epis_prof_rec epr
                     INNER JOIN professional p
                        ON (p.id_professional = epr.id_professional)
                     INNER JOIN prof_profile_template ppt
                        ON (ppt.id_professional = p.id_professional)
                     WHERE epr.id_episode = i_episode
                       AND epr.id_professional <> i_prof.id
                       AND ppt.id_profile_template = pt.id_profile_template
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes)
             ORDER BY intern_name_templ;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_PROFILE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_profile);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Listar os profissionais do perfil seleccionado      
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode id
    * @param i_profile                profile id                   
    * @param o_profile_prof            Listar os profissionais do perfil seleccionado
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_profile_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_profile      IN profile_template.id_profile_template%TYPE,
        o_profile_prof OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_PROFILE_PROF';
        OPEN o_profile_prof FOR
            SELECT epr.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof
              FROM epis_prof_rec epr
             INNER JOIN professional p
                ON (p.id_professional = epr.id_professional)
             INNER JOIN prof_profile_template ppt
                ON (ppt.id_professional = p.id_professional)
             WHERE epr.id_episode = i_episode
               AND epr.id_professional <> i_prof.id
               AND ppt.id_profile_template = i_profile
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY name_prof;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_PROFILE_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_profile_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar todas as revisões de registo de um episódio        
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_records_review         Listar todas as revisões de registo de um episódio
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_records_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        o_records_review OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_RECORDS_REVIEW';
        OPEN o_records_review FOR
            SELECT rr.id_records_review,
                   pk_translation.get_translation(i_lang, code_records_review) desc_record,
                   rrr.flg_status
              FROM records_review rr, records_review_read rrr
             WHERE rr.id_records_review = rrr.id_records_review(+)
               AND rrr.id_professional(+) = i_prof.id
               AND rr.flg_available = g_available
               AND rrr.id_episode(+) = i_epis
               AND ((rrr.dt_creation_tstz = (SELECT MAX(rrr1.dt_creation_tstz)
                                               FROM records_review_read rrr1
                                              WHERE rrr1.id_records_review = rr.id_records_review
                                                AND rrr1.id_professional(+) = i_prof.id
                                                AND rrr1.id_episode(+) = i_epis) AND EXISTS
                    (SELECT 0
                        FROM records_review_read rrr1
                       WHERE rrr1.id_records_review = rr.id_records_review
                         AND rrr1.id_professional(+) = i_prof.id
                         AND rrr1.id_episode(+) = i_epis)) OR NOT EXISTS
                    (SELECT 0
                       FROM records_review_read rrr1
                      WHERE rrr1.id_records_review = rr.id_records_review
                        AND rrr1.id_professional(+) = i_prof.id
                        AND rrr1.id_episode(+) = i_epis))
             ORDER BY rr.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_RECORDS_REVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_records_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar todos os profissionais que realizaram revisão de registos,excepto o próprio profissional         
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_all_prof               Listar todos os profissionais que realizaram revisão de registos, excepto o próprio profissional
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2009/10/21 
    **********************************************************************************************/
    FUNCTION get_all_prof_rec_review
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis     IN episode.id_episode%TYPE,
        o_all_prof OUT table_varchar,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_medical_decision.get_all_prof_rec_review_int(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_epis         => i_epis,
                                                               i_ret_all_prof => 'N',
                                                               o_all_prof     => o_all_prof,
                                                               o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_ALL_PROF_REC_REVIEW',
                                              o_error);
            o_all_prof := table_varchar();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_prof_rec_review;
    --
    /********************************************************************************************
    * Listar todos os profissionais que realizaram revisão de registos      
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_ret_all_prof           'N' - Returns all professionals expect the current one; 'Y' - returns all professionals
    * @param o_all_prof               Listar todos os profissionais que realizaram revisão de registos, excepto o próprio profissional
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_all_prof_rec_review_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_ret_all_prof IN VARCHAR2 DEFAULT 'N',
        o_all_prof     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        i               NUMBER := 0;
        cont            NUMBER;
        l_record_review VARCHAR2(9) := 'FALSE';
        l_sep           VARCHAR2(1) := ';';
        l_array_rr      VARCHAR2(4000);
        l_value         VARCHAR2(20);
        --
        CURSOR c_rec_review IS
            SELECT id_records_review
              FROM records_review
             WHERE flg_available = g_available
             ORDER BY rank;
    
        CURSOR c_rreview_read(l_rec_review IN records_review.id_records_review%TYPE) IS
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof
              FROM records_review_read rrr
              JOIN professional p
                ON p.id_professional = rrr.id_professional
             WHERE rrr.id_records_review = l_rec_review
               AND ((rrr.id_professional <> i_prof.id AND i_ret_all_prof = 'N') OR (i_ret_all_prof = 'Y'))
               AND rrr.id_episode = i_epis
               AND rrr.flg_status = pk_alert_constant.g_active
               AND (rrr.dt_creation_tstz = (SELECT MAX(rrr1.dt_creation_tstz)
                                              FROM records_review_read rrr1
                                             WHERE rrr1.id_records_review = rrr.id_records_review
                                               AND rrr1.id_professional = rrr.id_professional
                                               AND rrr1.id_episode = rrr.id_episode))
             ORDER BY rrr.dt_creation_tstz DESC;
    BEGIN
        g_error    := 'INICIALIZAÇÃO DOS ARRAYS';
        o_all_prof := table_varchar();
        --
        g_error := 'OPEN C_REC_REVIEW ';
        FOR x_rrev IN c_rec_review
        LOOP
            l_array_rr := NULL;
            l_value    := 'FALSE';
            cont       := 0;
            --
            FOR x_rread IN c_rreview_read(x_rrev.id_records_review)
            LOOP
                l_value := 'TRUE'; -- Tem valores 
                --
                IF nvl(cont, 0) = 0
                THEN
                    -- 1º contagem de sinal vital, então 1ª posião o ID doo discriminador  
                    IF l_array_rr IS NULL
                    THEN
                        l_array_rr := x_rrev.id_records_review;
                    END IF;
                END IF;
                --
                l_array_rr := l_array_rr || l_sep || x_rread.name_prof;
                cont       := cont + 1;
            END LOOP;
            --
            IF l_value = 'FALSE'
               AND nvl(cont, 0) > 0
            THEN
                l_array_rr := l_array_rr || l_sep || '';
            END IF;
            --
            IF nvl(cont, 0) > 0
            THEN
                i := i + 1;
                o_all_prof.extend; -- o array O_ALL_PROF tem mais uma linha
            END IF;
            --
            l_record_review := 'TRUE';
            --
            IF l_record_review = 'TRUE'
               AND nvl(cont, 0) > 0
            THEN
                o_all_prof(i) := l_array_rr || l_sep;
                l_record_review := 'FALSE';
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_ALL_PROF_REC_REVIEW_INT',
                                              o_error);
            o_all_prof := table_varchar();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_all_prof_rec_review_int;
    --
    /********************************************************************************************
    * Registar todas as leituras de revisões de registos         
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_records_review         record review id
    * @param i_flg_status             Estado da revisão de registo efectuada pelo profissional. A- Activo; C - Cancelada 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION set_records_review_read
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_records_review IN table_varchar,
        i_flg_status     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char VARCHAR2(1);
        l_next records_review_read.id_records_review_read%TYPE;
        l_exception EXCEPTION;
        l_error_out t_error_out;
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        FOR i IN 1 .. i_records_review.count
        LOOP
            -- Verificar se o episódio se encontra activo 
            g_error := 'GET CURSOR C_EPISODE';
            OPEN c_episode;
            FETCH c_episode
                INTO l_char;
            g_found := c_episode%FOUND;
            CLOSE c_episode;
            --
            IF g_found
            THEN
                g_error := 'GET SEQ_RECORDS_REVIEW_READ.NEXTVAL';
                SELECT seq_records_review_read.nextval
                  INTO l_next
                  FROM dual;
                --  
                g_error := 'INSERT RECORDS_REVIEW_READ';
                INSERT INTO records_review_read
                    (id_records_review_read,
                     id_records_review,
                     id_professional,
                     id_episode,
                     dt_creation_tstz,
                     flg_status,
                     adw_last_update)
                VALUES
                    (l_next, i_records_review(i), i_prof.id, i_epis, g_sysdate_tstz, i_flg_status(i), g_sysdate);
            END IF;
            --
            g_error := 'CALL SET_CODING_ELEMENT_MDM';
            IF NOT set_coding_element_mdm(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_epis              => i_epis,
                                          i_id_mdm_evaluation => 19,
                                          o_error             => l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            COMMIT;
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_RECORDS_REVIEW_READ',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_RECORDS_REVIEW_READ',
                                              o_error);
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar o detalhe de uma revisão de registo          
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_records_review         record review id
    * @param o_rec_review_det         Listar o detalhe de uma revisão de registo 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_records_review_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_records_review IN records_review.id_records_review%TYPE,
        o_rec_review_det OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_REC_REVIEW_DET';
        OPEN o_rec_review_det FOR
            SELECT id_records_review,
                   desc_review,
                   id_records_review_read,
                   id_professional,
                   name_prof,
                   desc_spec,
                   date_target,
                   hour_target,
                   desc_rec_review,
                   dt_creation
              FROM (SELECT id_records_review,
                           pk_translation.get_translation(i_lang, code_records_review) || ': ' ||
                           pk_message.get_message(i_lang, 'RECORDS_REVIEW_M003') desc_review,
                           NULL id_records_review_read,
                           NULL id_professional,
                           NULL name_prof,
                           NULL desc_spec,
                           NULL date_target,
                           NULL hour_target,
                           NULL desc_rec_review,
                           NULL dt_creation
                      FROM records_review
                     WHERE id_records_review = i_records_review
                    UNION ALL
                    SELECT rrr.id_records_review,
                           NULL desc_review,
                           rrr.id_records_review_read,
                           rrr.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            rrr.dt_creation_tstz,
                                                            i_epis) desc_spec,
                           pk_date_utils.dt_chr_tsz(i_lang, rrr.dt_creation_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            rrr.dt_creation_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           decode(rrr.flg_status,
                                  g_flg_status_a,
                                  pk_message.get_message(i_lang, 'RECORDS_REVIEW_M002'),
                                  pk_message.get_message(i_lang, 'RECORDS_REVIEW_M001')) desc_rec_review,
                           pk_date_utils.date_send_tsz(i_lang, rrr.dt_creation_tstz, i_prof) dt_creation
                      FROM records_review rr, records_review_read rrr, professional p, speciality s
                     WHERE rr.id_records_review = rrr.id_records_review
                       AND p.id_professional(+) = rrr.id_professional
                       AND rrr.id_records_review = i_records_review
                       AND s.id_speciality(+) = p.id_speciality
                       AND rrr.id_episode = i_epis)
             ORDER BY dt_creation DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_RECORDS_REVIEW_DET',
                                              o_error);
            pk_types.open_my_cursor(o_rec_review_det);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar todas as notas críticas         
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_critical_care          Listar todas as notas críticas 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_critical_care_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        o_critical_care OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_CRITICAL_CARE';
        OPEN o_critical_care FOR
            SELECT id_critical_care, pk_translation.get_translation(i_lang, code_critical_care) desc_c_care, flg_type
              FROM critical_care
             WHERE flg_available = g_available
             ORDER BY rank, desc_c_care;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_CRITICAL_CARE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_critical_care);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Registar as notas críticas do episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_critical_care          critical care id
    * @param i_value                  value
    * @param i_notes                  notes 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION set_critical_care_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_critical_care IN table_varchar,
        i_value         IN table_varchar,
        i_notes         IN critical_care_read.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_critical_care_read critical_care_read.id_critical_care_read%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INSERT CRITICAL_CARE_READ';
        INSERT INTO critical_care_read
            (id_critical_care_read, id_professional, id_episode, dt_creation_tstz, notes, adw_last_update)
        VALUES
            (seq_critical_care_read.nextval, i_prof.id, i_epis, g_sysdate_tstz, i_notes, g_sysdate)
        RETURNING id_critical_care_read INTO l_id_critical_care_read;
        --
        g_error := 'INSERT CRITICAL_CARE_DET';
        FORALL i IN 1 .. i_critical_care.count
            INSERT INTO critical_care_det
                (id_critical_care_det, id_critical_care_read, id_critical_care, VALUE, adw_last_update)
            VALUES
                (seq_critical_care_det.nextval, l_id_critical_care_read, i_critical_care(i), i_value(i), g_sysdate);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_CRITICAL_CARE_READ',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar a última nota crítica de um episódio            
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_crit_care              Listar a última nota crítica de um episódio
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_critical_care
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_crit_care OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_CRIT_CARE';
        OPEN o_crit_care FOR
            SELECT ccd.id_critical_care_read,
                   ccd.id_critical_care_det,
                   ccd.id_critical_care,
                   --DECODE(CC.FLG_TYPE,G_FLG_TYPE_C,Pk_Message.GET_MESSAGE(I_LANG,'CRITICAL_CARE_N_M001')) DESC_CRIT_CARE_C,
                   pk_message.get_message(i_lang, 'CRITICAL_CARE_N_M001') desc_crit_care_c,
                   pk_translation.get_translation(i_lang, cc.code_critical_care) desc_critical_care,
                   ccr.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, ccr.dt_creation_tstz, i_epis) desc_spec,
                   decode(cc.flg_type, g_flg_type_h, pk_medical_decision.get_ccare_hour_min(i_lang, VALUE), VALUE) val,
                   pk_date_utils.dt_chr_tsz(i_lang, ccr.dt_creation_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, ccr.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
                   ccr.notes
              FROM critical_care cc, critical_care_read ccr, critical_care_det ccd, professional p, speciality s
             WHERE cc.id_critical_care = ccd.id_critical_care
               AND ccr.id_critical_care_read = ccd.id_critical_care_read
               AND p.id_professional(+) = ccr.id_professional
               AND s.id_speciality(+) = p.id_speciality
               AND ccr.id_episode = i_epis
               AND ccr.dt_creation_tstz = (SELECT MAX(ccr1.dt_creation_tstz)
                                             FROM critical_care_read ccr1
                                            WHERE ccr1.id_episode = ccr.id_episode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_CRITICAL_CARE',
                                              o_error);
            pk_types.open_my_cursor(o_crit_care);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Listar todas as notas críticas de um episódio                
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_crit_care_det          Listar todas as notas críticas de um episódio
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_critical_care_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        o_crit_care_det OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_CRIT_CARE_DET';
        OPEN o_crit_care_det FOR
            SELECT ccd.id_critical_care_read,
                   ccd.id_critical_care_det,
                   ccd.id_critical_care,
                   pk_translation.get_translation(i_lang, cc.code_critical_care) desc_critical_care,
                   pk_date_utils.date_send_tsz(i_lang, ccr.dt_creation_tstz, i_prof) dt_creation,
                   ccr.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, ccr.dt_creation_tstz, i_epis) desc_spec,
                   pk_message.get_message(i_lang, 'CRITICAL_CARE_N_M001') desc_crit_care_c,
                   decode(cc.flg_type, g_flg_type_h, pk_medical_decision.get_ccare_hour_min(i_lang, VALUE), VALUE) val,
                   pk_date_utils.dt_chr_tsz(i_lang, ccr.dt_creation_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, ccr.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
                   ccr.notes
              FROM critical_care cc, critical_care_read ccr, critical_care_det ccd, professional p, speciality s
             WHERE cc.id_critical_care = ccd.id_critical_care
               AND ccr.id_critical_care_read = ccd.id_critical_care_read
               AND p.id_professional(+) = ccr.id_professional
               AND s.id_speciality(+) = p.id_speciality
               AND ccr.id_episode = i_epis
             ORDER BY ccr.dt_creation_tstz DESC, ccd.id_critical_care;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_CRITICAL_CARE_DET',
                                              o_error);
            pk_types.open_my_cursor(o_crit_care_det);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Definir a label a ser retornada tendo em conta o valor: h - Horas; min. - Minutos           
    *
    * @param i_lang                   The language ID
    * @param i_value                  Valor das notas críticas
    *                        
    * @return                         description
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_ccare_hour_min
    (
        i_lang  IN language.id_language%TYPE,
        i_value IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_value NUMBER;
        l_error t_error_out;
    BEGIN
        l_value := substr(i_value, 1, instr(i_value, ':') - 1);
        --
        IF l_value > 0
        THEN
            RETURN i_value || ' ' || pk_message.get_message(i_lang, 'CRITICAL_CARE_N_M002'); --HORAS
        ELSE
            l_value := substr(i_value, instr(i_value, ':') + 1);
            RETURN l_value || ' ' || pk_message.get_message(i_lang, 'CRITICAL_CARE_N_M003'); --MINUTOS
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_CCARE_HOUR_MIN',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN '';
        
    END;
    --
    /********************************************************************************************
    * Registar o numero de elemntos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_document_area          doc area id
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_coding_element_chart
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_document_area IN doc_area.id_doc_area%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_element_bartchart NUMBER;
        l_cms_area          VARCHAR2(200);
        l_mdm_prof_coding   mdm_prof_coding.id_mdm_prof_coding%TYPE;
        l_next              mdm_prof_coding.id_mdm_prof_coding%TYPE;
        --
        CURSOR c_element_bartchart IS
            SELECT COUNT(edd.id_doc_element) num_ele_bartcart
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             WHERE ed.id_episode = i_epis
               AND ed.flg_status = g_bartchart_status_a
               AND edd.id_professional = i_prof.id
               AND ed.id_doc_area = i_document_area;
    
        CURSOR c_cms_area IS
            SELECT me.flg_coding cms_area
              FROM doc_area da, mdm_evaluation me
             WHERE da.id_doc_area = i_document_area
               AND da.mdm_coding = me.id_mdm_evaluation;
    
        CURSOR c_mdm_prof_coding IS
            SELECT mpc.id_mdm_prof_coding
              FROM mdm_prof_coding mpc
             WHERE mpc.id_episode = i_epis
               AND mpc.id_professional = i_prof.id;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'OPEN C_ELEMENT_BARTCHART';
        OPEN c_element_bartchart;
        FETCH c_element_bartchart
            INTO l_element_bartchart;
        CLOSE c_element_bartchart;
        --
        g_error := 'OPEN C_ELEMENT_BARTCHART';
        OPEN c_cms_area;
        FETCH c_cms_area
            INTO l_cms_area;
        CLOSE c_cms_area;
        --
        g_error := 'GET CURSOR C_MDM_PROF_CODING';
        OPEN c_mdm_prof_coding;
        FETCH c_mdm_prof_coding
            INTO l_mdm_prof_coding;
        g_found := c_mdm_prof_coding%FOUND;
        CLOSE c_mdm_prof_coding;
        --
        IF NOT g_found
        THEN
            g_error := 'GET SEQ_MDM_PROF_CODING.NEXTVAL';
            SELECT seq_mdm_prof_coding.nextval
              INTO l_next
              FROM dual;
            --  
            IF l_cms_area = g_cms_area_hpi
            THEN
                g_error := 'INSERT MDM_PROF_CODING HPI ';
                INSERT INTO mdm_prof_coding
                    (id_mdm_prof_coding, id_episode, id_professional, hpi, dt_creation_tstz, adw_last_update)
                VALUES
                    (l_next, i_epis, i_prof.id, l_element_bartchart, g_sysdate_tstz, g_sysdate);
            
            ELSIF l_cms_area = g_cms_area_ros
            THEN
                g_error := 'INSERT MDM_PROF_CODING ROS ';
                INSERT INTO mdm_prof_coding
                    (id_mdm_prof_coding, id_episode, id_professional, ros, dt_creation_tstz, adw_last_update)
                VALUES
                    (l_next, i_epis, i_prof.id, l_element_bartchart, g_sysdate_tstz, g_sysdate);
            
            ELSIF l_cms_area = g_cms_area_pfsh
            THEN
                g_error := 'INSERT MDM_PROF_CODING PFSH ';
                INSERT INTO mdm_prof_coding
                    (id_mdm_prof_coding, id_episode, id_professional, pfsh, dt_creation_tstz, adw_last_update)
                VALUES
                    (l_next, i_epis, i_prof.id, l_element_bartchart, g_sysdate_tstz, g_sysdate);
            
            ELSIF l_cms_area = g_cms_area_pe
            THEN
                g_error := 'INSERT MDM_PROF_CODING PE ';
                INSERT INTO mdm_prof_coding
                    (id_mdm_prof_coding, id_episode, id_professional, pe, dt_creation_tstz, adw_last_update)
                VALUES
                    (l_next, i_epis, i_prof.id, l_element_bartchart, g_sysdate_tstz, g_sysdate);
            END IF;
        ELSE
            IF l_cms_area = g_cms_area_hpi
            THEN
                g_error := 'UPDATE MDM_PROF_CODING HPI ';
                UPDATE mdm_prof_coding
                   SET hpi = l_element_bartchart, adw_last_update = g_sysdate
                 WHERE id_mdm_prof_coding = l_mdm_prof_coding;
            
            ELSIF l_cms_area = g_cms_area_ros
            THEN
                g_error := 'UPDATE MDM_PROF_CODING ROS ';
                UPDATE mdm_prof_coding
                   SET ros = l_element_bartchart, adw_last_update = g_sysdate
                 WHERE id_mdm_prof_coding = l_mdm_prof_coding;
            
            ELSIF l_cms_area = g_cms_area_pfsh
            THEN
                g_error := 'UPDATE MDM_PROF_CODING PFSH ';
                UPDATE mdm_prof_coding
                   SET pfsh = l_element_bartchart, adw_last_update = g_sysdate
                 WHERE id_mdm_prof_coding = l_mdm_prof_coding;
            
            ELSIF l_cms_area = g_cms_area_pe
            THEN
                g_error := 'UPDATE MDM_PROF_CODING PE ';
                UPDATE mdm_prof_coding
                   SET pe = l_element_bartchart, adw_last_update = g_sysdate
                 WHERE id_mdm_prof_coding = l_mdm_prof_coding;
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
                                              'PK_MEDICAL_DECISION',
                                              'SET_CODING_ELEMENT_CHART',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Registar o numero de elemntos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_id_mdm_evaluation      mdm evaluation
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_cod_elem_mdm_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_id_mdm_evaluation IN doc_area.id_doc_area%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_mdm_prof_coding mdm_prof_coding.id_mdm_prof_coding%TYPE;
        l_next            mdm_prof_coding.id_mdm_prof_coding%TYPE;
        l_mdm             mdm_prof_coding.mdm%TYPE;
        --
        CURSOR c_mdm_evaluation IS
            SELECT me.id_mdm_evaluation, me.flg_origem, me.flg_coding, mc.action, mc.value
              FROM mdm_evaluation me, mdm_coding mc
             WHERE me.id_mdm_evaluation = i_id_mdm_evaluation
               AND me.id_mdm_evaluation = mc.id_mdm_evaluation;
    
        CURSOR c_mdm_prof_coding IS
            SELECT mpc.id_mdm_prof_coding, mpc.mdm
              FROM mdm_prof_coding mpc
             WHERE mpc.id_episode = i_epis
               AND mpc.id_professional = i_prof.id;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET C_MDM_PROF_CODING';
        OPEN c_mdm_prof_coding;
        FETCH c_mdm_prof_coding
            INTO l_mdm_prof_coding, l_mdm;
        g_found := c_mdm_prof_coding%FOUND;
        CLOSE c_mdm_prof_coding;
        --
        l_mdm := nvl(l_mdm, 0) + 1;
        --
        IF NOT g_found
        THEN
            g_error := 'GET SEQ_MDM_PROF_CODING.NEXTVAL';
            SELECT seq_mdm_prof_coding.nextval
              INTO l_next
              FROM dual;
            --  
            g_error := 'INSERT MDM_PROF_CODING HPI ';
            INSERT INTO mdm_prof_coding
                (id_mdm_prof_coding, id_episode, id_professional, mdm, dt_creation_tstz, adw_last_update)
            VALUES
                (l_next, i_epis, i_prof.id, l_mdm, g_sysdate_tstz, g_sysdate);
        ELSE
            g_error := 'UPDATE MDM_PROF_CODING';
            UPDATE mdm_prof_coding
               SET mdm = l_mdm, adw_last_update = g_sysdate
             WHERE id_mdm_prof_coding = l_mdm_prof_coding;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_COD_ELEM_MDM_NO_COMMIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Registar o numero de elemntos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_id_mdm_evaluation      mdm evaluation
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_coding_element_mdm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_id_mdm_evaluation IN doc_area.id_doc_area%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
        IF NOT pk_medical_decision.set_cod_elem_mdm_no_commit(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_epis              => i_epis,
                                                              i_id_mdm_evaluation => i_id_mdm_evaluation,
                                                              o_error             => l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_CODING_ELEMENT_MDM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_CODING_ELEMENT_MDM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /********************************************************************************************
    * Registar o numero de elementos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_origin                 origin id
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_coding_element_mdm_1
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        i_origin IN VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
        IF NOT pk_medical_decision.set_cod_elem_mdm_1_no_commit(i_lang   => i_lang,
                                                                i_prof   => i_prof,
                                                                i_epis   => i_epis,
                                                                i_origin => i_origin,
                                                                o_error  => l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_CODING_ELEMENT_MDM_1',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_CODING_ELEMENT_MDM_1',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Registar o numero de elementos registados por um profissonal para uma àrea da BARTCHART  
    * associada a um episódio  - SEM COMMIT
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_origin                 origin id
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_cod_elem_mdm_1_no_commit
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        i_origin IN VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_mdm_prof_coding mdm_prof_coding.id_mdm_prof_coding%TYPE;
        l_next            mdm_prof_coding.id_mdm_prof_coding%TYPE;
        l_mdm             mdm_prof_coding.mdm%TYPE;
        l_num             NUMBER;
        --   
        CURSOR c_analisys IS
            SELECT COUNT(ard.id_analysis_req_det)
              FROM analysis_req ar, analysis_req_det ard
             WHERE ar.id_episode = i_epis
               AND ar.id_prof_writes = i_prof.id
               AND ard.id_analysis_req = ar.id_analysis_req;
    
        CURSOR c_mdm_prof_coding IS
            SELECT mpc.id_mdm_prof_coding, mpc.mdm
              FROM mdm_prof_coding mpc
             WHERE mpc.id_episode = i_epis
               AND mpc.id_professional = i_prof.id;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET CURSOR C_MDM_PROF_CODING';
        OPEN c_mdm_prof_coding;
        FETCH c_mdm_prof_coding
            INTO l_mdm_prof_coding, l_mdm;
        g_found := c_mdm_prof_coding%FOUND;
        CLOSE c_mdm_prof_coding;
        --
        IF i_origin = 'L'
        THEN
            g_error := 'GET CURSOR C_ANALISYS ';
            OPEN c_analisys;
            FETCH c_analisys
                INTO l_num;
            CLOSE c_analisys;
        
            IF l_num = 1
            THEN
                l_mdm := nvl(l_mdm, 0) + 1;
            ELSIF l_num = 2
            THEN
                l_mdm := nvl(l_mdm, 0);
            ELSIF l_num = 3
            THEN
                l_mdm := nvl(l_mdm, 0) + 1;
            ELSIF l_num > 3
            THEN
                l_mdm := nvl(l_mdm, 0);
            END IF;
        END IF;
        --
        IF NOT g_found
        THEN
            g_error := 'GET SEQ_MDM_PROF_CODING.NEXTVAL';
            SELECT seq_mdm_prof_coding.nextval
              INTO l_next
              FROM dual;
            --  
            g_error := 'INSERT MDM_PROF_CODING HPI ';
            INSERT INTO mdm_prof_coding
                (id_mdm_prof_coding, id_episode, id_professional, mdm, dt_creation_tstz, adw_last_update)
            VALUES
                (l_next, i_epis, i_prof.id, l_mdm, g_sysdate_tstz, g_sysdate);
        ELSE
            g_error := 'UPDATE MDM_PROF_CODING';
            UPDATE mdm_prof_coding
               SET mdm = l_mdm, adw_last_update = g_sysdate
             WHERE id_mdm_prof_coding = l_mdm_prof_coding;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'SET_COD_ELEM_MDM_1_NO_COMMIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --

    /********************************************************************************************
    * List all patient's response to treatment  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_treat                  id_treatment (id prescription)
    * @param o_treat_manag            Patient's response to treatment 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013/06/05 
    *
    **********************************************************************************************/
    FUNCTION get_treat_manag_presc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE,
        o_treat     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR O_TREAT';
        OPEN o_treat FOR
        -- medication             
            SELECT tm.desc_treatment_management, tm.id_professional, tm.dt_creation_tstz, tm.id_treatment_management
              FROM treatment_management tm
             WHERE tm.id_treatment = i_treatment
               AND tm.flg_type = g_treat_type_drug;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MEDICAL_DECISION',
                                              'GET_TREAT_MANAG_PRESC',
                                              o_error);
            pk_types.open_my_cursor(o_treat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
BEGIN
    --
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    --
    g_available   := 'Y';
    g_epis_active := 'A';
    --
    g_flg_status_a := 'A';
    g_flg_status_c := 'C';
    --
    g_exam_status_final := 'F';
    g_exam_status_read  := 'L';
    -- 
    g_analisys_status_final := 'F';
    g_analisys_status_red   := 'L';
    --
    g_tests_type_exam     := 'E';
    g_tests_type_analisys := 'A';
    --
    g_icon               := 'I';
    g_icon_type_analysis := 'LaboratorialAnalysisIcon';
    g_icon_type_exam     := 'ImageExameIcon';
    --
    g_treat_type_interv := 'I';
    g_treat_type_drug   := 'D';
    --
    -- Procedimentos - Intervention 
    g_interv_status_final := 'F';
    g_interv_status_curso := 'E';
    g_interv_status_inter := 'I';
    --
    g_icon_type_drug   := 'TherapeuticIcon';
    g_icon_type_interv := 'InterventionsIcon';
    --
    g_flg_type_c := 'C'; -- Critical care
    g_flg_type_h := 'H';
    --
    g_flg_time_betw := 'B';
    g_flg_time_next := 'N';
    --
    g_presc_take_cont := 'C';
    g_presc_take_sos  := 'S';
    --
    g_presc_fin  := 'F';
    g_presc_req  := 'R';
    g_presc_pend := 'D';
    g_presc_exec := 'E';
    g_presc_act  := 'A';
    g_presc_fin  := 'F';
    g_presc_can  := 'C';
    g_presc_par  := 'P';
    g_presc_intr := 'P';
    --
    g_presc_det_req  := 'R';
    g_presc_det_pend := 'D';
    g_presc_det_exe  := 'E';
    g_presc_det_fin  := 'F';
    g_presc_det_can  := 'C';
    g_presc_det_intr := 'I';
    --
    g_presc_plan_stat_adm  := 'A';
    g_presc_plan_stat_nadm := 'N';
    g_presc_plan_stat_pend := 'D';
    g_presc_plan_stat_req  := 'R';
    g_presc_plan_stat_can  := 'C';

    --
    g_interv_take_sos := 'S';
    --
    g_flg_type_d := 'D';
    g_flg_type_n := 'N';
    --
    g_cms_area_hpi  := 'HPI';
    g_cms_area_ros  := 'ROS';
    g_cms_area_pfsh := 'PFSH';
    g_cms_area_pe   := 'PE';
    g_cms_area_mdm  := 'MDM';

    g_bartchart_status_a := 'A';
    g_label              := 'L';
    g_no_color           := 'X';
    --
    g_exam_type_img := 'I';
    --- 
    g_local := 'LOCAL';
    g_soro  := 'SORO';
    g_drug  := 'M';
    --
    g_flg_nursing_notes := 'N';
    --
    g_cat_doc   := 'D';
    g_cat_nurse := 'N';
    g_cat_tech  := 'T';
    --
    g_orig_analysis_periodic_obs := 'O';
    g_orig_analysis_ser_analysis := 'S';
    g_orig_analysis_woman_health := 'M';

END pk_medical_decision;
/
