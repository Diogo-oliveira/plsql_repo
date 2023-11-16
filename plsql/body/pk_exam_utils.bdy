/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/
CREATE OR REPLACE PACKAGE BODY pk_exam_utils IS

    TYPE t_exam_body_structure IS TABLE OF NUMBER INDEX BY VARCHAR2(1000);
    rec_exam_body_structure t_exam_body_structure;

    TYPE t_body_structure_dcs IS TABLE OF NUMBER INDEX BY VARCHAR2(1000);
    rec_body_structure_dcs t_body_structure_dcs;

    TYPE t_co_sign IS TABLE OF t_table_co_sign INDEX BY VARCHAR2(4000 CHAR);
    TYPE t_episode IS TABLE OF t_co_sign INDEX BY VARCHAR2(4000 CHAR);
    TYPE t_soft IS TABLE OF t_episode INDEX BY VARCHAR2(4000 CHAR);
    TYPE t_inst IS TABLE OF t_soft INDEX BY VARCHAR2(4000 CHAR);
    TYPE t_id_prof IS TABLE OF t_inst INDEX BY VARCHAR2(4000 CHAR);
    TYPE t_co_sign_final IS TABLE OF t_id_prof INDEX BY VARCHAR2(4000 CHAR);
    rec_co_sign t_co_sign_final;

    FUNCTION get_exam_request
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_exam      IN table_number,
        o_msg_title OUT VARCHAR2,
        o_msg_req   OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_days_limit sys_config.value%TYPE;
        l_string_req VARCHAR2(1000 CHAR);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        o_button := 'NC';
    
        l_days_limit := pk_sysconfig.get_config('EXAMS_LAST_ORDER', i_prof);
    
        SELECT REPLACE(substr(concatenate(eea.desc_exam || ' - ' ||
                                          pk_date_utils.dt_chr_tsz(i_lang, eea.dt_req, i_prof) || ' (' ||
                                          pk_date_utils.get_elapsed_sysdate_tsz(i_lang, eea.dt_req) || '); '),
                              1,
                              length(concatenate(eea.desc_exam || ' - ' ||
                                                 pk_date_utils.dt_chr_tsz(i_lang, eea.dt_req, i_prof) || ' (' ||
                                                 pk_date_utils.get_elapsed_sysdate_tsz(i_lang, eea.dt_req) || '); ')) - 2),
                       '); ',
                       '); ' || chr(10))
          INTO l_string_req
          FROM (SELECT eea.dt_req,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                       row_number() over(PARTITION BY eea.id_exam ORDER BY eea.dt_req DESC) rn
                  FROM exams_ea eea
                 WHERE eea.id_patient = i_patient
                   AND eea.id_exam IN (SELECT /*+opt_estimate(table t rows=1)*/
                                        *
                                         FROM TABLE(i_exam) t)
                   AND eea.flg_status_det NOT IN (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_draft)
                   AND ((eea.dt_req BETWEEN g_sysdate_tstz - numtodsinterval(l_days_limit, 'DAY') AND g_sysdate_tstz) OR
                       (eea.start_time BETWEEN g_sysdate_tstz - numtodsinterval(l_days_limit, 'DAY') AND g_sysdate_tstz) OR
                       (eea.dt_result BETWEEN g_sysdate_tstz - numtodsinterval(l_days_limit, 'DAY') AND g_sysdate_tstz))
                 ORDER BY 1 DESC) eea
         WHERE eea.rn = 1;
    
        IF l_string_req IS NOT NULL
        THEN
            o_msg_title := pk_message.get_message(i_lang, 'EXAM_M007');
        
            o_msg_req := REPLACE(pk_message.get_message(i_lang, 'EXAM_M004'), '@1', l_string_req);
        
            RETURN pk_exam_constant.g_yes;
        ELSE
        
            RETURN pk_exam_constant.g_no;
        END IF;
    
    END get_exam_request;

    FUNCTION get_exam_id_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN exam.id_exam%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_content analysis_sample_type.id_content%TYPE;
    
    BEGIN
    
        SELECT e.id_content
          INTO l_id_content
          FROM exam e
         WHERE e.id_exam = i_exam
           AND e.flg_available = pk_exam_constant.g_available;
    
        RETURN l_id_content;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_id_content;

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_exam_alias exam_alias.code_exam_alias%TYPE;
        l_desc_mess  pk_translation.t_desc_translation;
    
    BEGIN
    
        l_exam_alias := get_alias_code_translation(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_code_exam     => i_code_exam,
                                                   i_dep_clin_serv => i_dep_clin_serv);
    
        g_error := 'GET TRANSLATION';
        IF l_exam_alias IS NOT NULL
        THEN
            l_desc_mess := pk_translation.get_translation(i_lang, l_exam_alias);
        END IF;
    
        g_error := 'TEST OUTPUT MESSAGE';
        IF l_desc_mess IS NULL
        THEN
            l_desc_mess := pk_translation.get_translation(i_lang, i_code_exam);
        END IF;
    
        RETURN l_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_alias_code_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN exam_alias.code_exam_alias%TYPE IS
    
        c_exam_alias pk_types.cursor_type;
        l_exam_alias exam_alias.code_exam_alias%TYPE;
    
    BEGIN
        g_error := 'FETCH CURSOR';
    
        OPEN c_exam_alias FOR
            SELECT (SELECT code_exam_alias
                      FROM (SELECT code_exam_alias,
                                   row_number() over(PARTITION BY ea.id_exam ORDER BY ea.id_institution DESC, ea.id_software DESC) rn
                              FROM exam_alias ea
                              JOIN exam e
                                ON ea.id_exam = e.id_exam
                             WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                                   nvl(i_prof.institution, 0)
                               AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                               AND decode(nvl(id_professional, 0), 0, nvl(i_prof.id, 0), id_professional) =
                                   nvl(i_prof.id, 0)
                               AND decode(nvl(id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), id_dep_clin_serv) =
                                   nvl(i_dep_clin_serv, 0)
                               AND e.code_exam = i_code_exam)
                     WHERE rn = 1)
              FROM dual;
    
        FETCH c_exam_alias
            INTO l_exam_alias;
        CLOSE c_exam_alias;
    
        RETURN l_exam_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation;

    FUNCTION get_exam_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam          IN exam.id_exam%TYPE,
        i_flg_type      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER IS
    
        l_exam_rank          NUMBER;
        l_prof_dep_clin_serv table_number := table_number();
    
    BEGIN
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
        
            SELECT /*+ result_cache*/
             1
              BULK COLLECT
              INTO l_prof_dep_clin_serv
              FROM prof_dep_clin_serv pdcs
             WHERE pdcs.id_professional = i_prof.id
               AND pdcs.id_dep_clin_serv = i_dep_clin_serv
               AND pdcs.flg_status = pk_exam_constant.g_selected
               AND pdcs.flg_default = pk_exam_constant.g_yes;
        
            IF l_prof_dep_clin_serv.count > 0
            THEN
                g_error := 'GET EXAM RANK 1';
                SELECT edcs.rank
                  INTO l_exam_rank
                  FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_exam = i_exam
                   AND edcs.id_dep_clin_serv = i_dep_clin_serv
                   AND edcs.flg_type = nvl(i_flg_type, pk_exam_constant.g_exam_freq)
                   AND edcs.id_software = i_prof.software;
            ELSE
                g_error := 'GET EXAM RANK 2';
                SELECT coalesce((SELECT MAX(edcs.rank)
                                  FROM exam_dep_clin_serv edcs
                                 WHERE edcs.id_exam = i_exam
                                   AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                   AND edcs.id_software = i_prof.software
                                   AND edcs.id_institution = i_prof.institution),
                                (SELECT MAX(edcs.rank)
                                   FROM exam_dep_clin_serv edcs
                                  WHERE edcs.id_exam = i_exam
                                    AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                    AND edcs.id_institution = i_prof.institution),
                                (SELECT e.rank
                                   FROM exam e
                                  WHERE e.id_exam = i_exam))
                  INTO l_exam_rank
                  FROM dual;
            END IF;
        ELSE
            g_error := 'GET EXAM RANK 3';
            SELECT coalesce((SELECT MAX(edcs.rank)
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_exam = i_exam
                               AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                               AND edcs.id_software = i_prof.software
                               AND edcs.id_institution = i_prof.institution),
                            (SELECT MAX(edcs.rank)
                               FROM exam_dep_clin_serv edcs
                              WHERE edcs.id_exam = i_exam
                                AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                AND edcs.id_institution = i_prof.institution),
                            (SELECT e.rank
                               FROM exam e
                              WHERE e.id_exam = i_exam))
              INTO l_exam_rank
              FROM dual;
        END IF;
    
        RETURN l_exam_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_exam_rank;

    FUNCTION get_exam_group_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_group    IN exam_group.id_exam_group%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER IS
    
        l_exam_group_rank NUMBER;
    
        l_prof_dep_clin_serv NUMBER;
    
    BEGIN
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            BEGIN
                SELECT 1
                  INTO l_prof_dep_clin_serv
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = i_prof.id
                   AND pdcs.id_dep_clin_serv = i_dep_clin_serv
                   AND pdcs.flg_status = pk_exam_constant.g_selected
                   AND pdcs.flg_default = pk_exam_constant.g_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    l_prof_dep_clin_serv := 0;
            END;
        
            IF l_prof_dep_clin_serv = 1
            THEN
                g_error := 'GET EXAM RANK 1';
                SELECT edcs.rank
                  INTO l_exam_group_rank
                  FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_exam_group = i_exam_group
                   AND edcs.id_dep_clin_serv = i_dep_clin_serv
                   AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                   AND edcs.id_software = i_prof.software
                   AND edcs.id_institution = i_prof.institution;
            ELSE
                g_error := 'GET EXAM RANK 2';
                SELECT coalesce((SELECT MAX(edcs.rank)
                                  FROM exam_dep_clin_serv edcs
                                 WHERE edcs.id_exam_group = i_exam_group
                                   AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                   AND edcs.id_software = i_prof.software
                                   AND edcs.id_institution = i_prof.institution),
                                (SELECT MAX(edcs.rank)
                                   FROM exam_dep_clin_serv edcs
                                  WHERE edcs.id_exam_group = i_exam_group
                                    AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                    AND edcs.id_institution = i_prof.institution),
                                (SELECT eg.rank
                                   FROM exam_group eg
                                  WHERE eg.id_exam_group = i_exam_group))
                  INTO l_exam_group_rank
                  FROM dual;
            END IF;
        ELSE
            g_error := 'GET EXAM RANK 3';
            SELECT coalesce((SELECT MAX(edcs.rank)
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_exam_group = i_exam_group
                               AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                               AND edcs.id_software = i_prof.software
                               AND edcs.id_institution = i_prof.institution),
                            (SELECT MAX(edcs.rank)
                               FROM exam_dep_clin_serv edcs
                              WHERE edcs.id_exam_group = i_exam_group
                                AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                AND edcs.id_institution = i_prof.institution),
                            (SELECT eg.rank
                               FROM exam_group eg
                              WHERE eg.id_exam_group = i_exam_group))
              INTO l_exam_group_rank
              FROM dual;
        END IF;
    
        RETURN l_exam_group_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_exam_group_rank;

    FUNCTION get_exam_category_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT EXAM_CAT';
        SELECT ec.rank
          INTO l_rank
          FROM exam_cat ec
         WHERE ec.id_exam_cat = i_exam_cat
           AND ec.flg_available = pk_exam_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_category_rank;

    FUNCTION get_exam_questionnaire_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam          IN exam.id_exam%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN exam_questionnaire.flg_time%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT EXAM_QUESTIONNAIRE';
        SELECT MAX(eq.rank)
          INTO l_rank
          FROM exam_questionnaire eq
         WHERE eq.id_exam = i_exam
           AND eq.id_questionnaire = i_questionnaire
           AND eq.flg_time = i_flg_time
           AND eq.id_institution = i_prof.institution
           AND eq.flg_available = pk_exam_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_questionnaire_rank;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2 IS
    
        l_content VARCHAR2(200 CHAR);
    
    BEGIN
    
        IF i_response IS NOT NULL
        THEN
            g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
            SELECT id_content
              INTO l_content
              FROM questionnaire_response qr
             WHERE qr.id_questionnaire = i_questionnaire
               AND qr.id_response = i_response
               AND qr.flg_available = pk_exam_constant.g_yes;
        ELSE
            g_error := 'SELECT QUESTIONNAIRE';
            SELECT id_content
              INTO l_content
              FROM questionnaire q
             WHERE q.id_questionnaire = i_questionnaire
               AND q.flg_available = pk_exam_constant.g_yes;
        END IF;
    
        RETURN l_content;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_questionnaire_id_content;

    PROCEDURE get_exam_init_parameters
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
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        
                                                        i_context_ids(g_prof_software));
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        g_exam_type CONSTANT VARCHAR2(1 CHAR) := 1;
    
        l_exam_type exam_type.flg_type%TYPE;
    
        l_flg_type      VARCHAR2(2 CHAR);
        l_codification  codification.id_codification%TYPE;
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
    
        CASE i_custom_filter
            WHEN 0 THEN
                l_flg_type := pk_exam_constant.g_exam_can_req;
            WHEN 1 THEN
                l_flg_type := pk_exam_constant.g_exam_freq;
            WHEN 2 THEN
                l_flg_type := pk_exam_constant.g_exam_complaint;
            ELSE
                l_flg_type := pk_exam_constant.g_exam_codification;
            
                IF i_context_vals IS NOT NULL
                   AND i_context_vals.count > 0
                THEN
                    BEGIN
                        BEGIN
                            l_codification := i_context_vals(4);
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_codification := i_context_vals(3);
                        END;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                END IF;
        END CASE;
    
        IF i_filter_name != 'HHCReqExamsList'
        THEN
            l_exam_type := i_context_vals(g_exam_type);
        END IF;
    
        pk_context_api.set_parameter('i_exam_type', l_exam_type);
        pk_context_api.set_parameter('i_flg_type',
                                     CASE WHEN i_filter_name = 'ExamsSearch' THEN pk_exam_constant.g_exam_can_req ELSE
                                     l_flg_type END);
        pk_context_api.set_parameter('i_dep_clin_serv', l_dep_clin_serv);
        pk_context_api.set_parameter('i_codification',
                                     CASE WHEN i_filter_name = 'ExamsSearch' THEN i_context_vals(3) ELSE l_codification END);
        pk_context_api.set_parameter('i_value',
                                     CASE WHEN i_filter_name = 'ExamsSearch' THEN i_context_vals(2) ELSE NULL END);
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_exam_type' THEN
                o_vc2 := l_exam_type;
            WHEN 'g_type_exm' THEN
                o_vc2 := pk_exam_constant.g_type_exm;
            WHEN 'g_type_img' THEN
                o_vc2 := pk_exam_constant.g_type_img;
            WHEN 'g_exam_area_exams' THEN
                o_vc2 := pk_exam_constant.g_exam_area_exams;
            WHEN 'g_exam_area_orders' THEN
                o_vc2 := pk_exam_constant.g_exam_area_orders;
            WHEN 'g_exam_button_ok' THEN
                o_vc2 := pk_exam_constant.g_exam_button_ok;
            WHEN 'g_exam_button_cancel' THEN
                o_vc2 := pk_exam_constant.g_exam_button_cancel;
            WHEN 'g_exam_button_action' THEN
                o_vc2 := pk_exam_constant.g_exam_button_action;
            WHEN 'g_exam_button_edit' THEN
                o_vc2 := pk_exam_constant.g_exam_button_edit;
            WHEN 'g_exam_button_confirmation' THEN
                o_vc2 := pk_exam_constant.g_exam_button_confirmation;
            WHEN 'g_exam_button_read' THEN
                o_vc2 := pk_exam_constant.g_exam_button_read;
            WHEN 'g_exam_pending' THEN
                o_vc2 := pk_exam_constant.g_exam_pending;
            WHEN 'g_exam_req' THEN
                o_vc2 := pk_exam_constant.g_exam_req;
            WHEN 'g_exam_tosched' THEN
                o_vc2 := pk_exam_constant.g_exam_tosched;
            WHEN 'g_exam_result' THEN
                o_vc2 := pk_exam_constant.g_exam_result;
            WHEN 'g_exam_type_req' THEN
                o_vc2 := pk_exam_constant.g_exam_type_req;
            WHEN 'g_flg_time_r' THEN
                o_vc2 := pk_exam_constant.g_flg_time_r;
            WHEN 'g_exam_result_pdf' THEN
                o_vc2 := pk_exam_constant.g_exam_result_pdf;
            WHEN 'g_exam_result_url' THEN
                o_vc2 := pk_exam_constant.g_exam_result_url;
            WHEN 'g_yes' THEN
                o_vc2 := pk_exam_constant.g_yes;
            WHEN 'g_no' THEN
                o_vc2 := pk_exam_constant.g_no;
            WHEN 'g_syn_str_exam' THEN
                o_vc2 := 'EXAM.CODE_EXAM OR EXAM_ALIAS.CODE_EXAM_ALIAS';
            WHEN 'l_msg_order' THEN
                o_vc2 := pk_message.get_message(l_lang, 'EXAMS_T239');
            WHEN 'l_msg_exams_num' THEN
                o_vc2 := pk_message.get_message(l_lang, 'EXAMS_T240');
            WHEN 'l_msg_not_aplicable' THEN
                o_vc2 := pk_message.get_message(l_lang, 'COMMON_M036');
            WHEN 'l_msg_notes' THEN
                o_vc2 := pk_message.get_message(l_lang, 'COMMON_M097');
            WHEN 'l_top_result' THEN
                o_vc2 := pk_sysconfig.get_config('EXAMS_RESULTS_ON_TOP', l_prof);
            WHEN 'l_path' THEN
                o_vc2 := pk_sysconfig.get_config('URL_EXTERNAL_DOC', l_prof);
            WHEN 'l_visit' THEN
                o_id := pk_visit.get_visit(l_episode, l_error);
            WHEN 'l_epis_type' THEN
                SELECT id_epis_type
                  INTO o_id
                  FROM episode
                 WHERE id_episode = l_episode;
        END CASE;
    
    END get_exam_init_parameters;

    FUNCTION get_exam_in_order
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        i_flg_type IN VARCHAR2
    ) RETURN CLOB IS
    
        l_exam_req_det CLOB;
        l_desc_exam    CLOB;
    
    BEGIN
    
        g_error := 'GET L_EXAM_REQ_DET AND L_DESC_EXAM';
        SELECT substr(concatenate_clob(eea.id_exam_req_det || ';'),
                      1,
                      length(concatenate_clob(eea.id_exam_req_det || ';')) - 1) id_exam_req_det,
               substr(concatenate_clob(eea.desc_exam || '@' || eea.status_string || ';'),
                      1,
                      length(concatenate_clob(eea.desc_exam || '@' || eea.status_string || ';')) - 1) desc_exam
          INTO l_exam_req_det, l_desc_exam
          FROM (SELECT eea.id_exam_req_det,
                       pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                       pk_utils.get_status_string(i_lang,
                                                  i_prof,
                                                  eea.status_str,
                                                  eea.status_msg,
                                                  eea.status_icon,
                                                  eea.status_flg) status_string,
                       decode(eea.flg_referral,
                              NULL,
                              pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                              pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral)) rank
                  FROM exams_ea eea
                 WHERE eea.id_exam_req = i_exam_req
                 ORDER BY 4, 2) eea;
    
        IF i_flg_type = 'ID'
        THEN
            RETURN l_exam_req_det;
        ELSE
            RETURN l_desc_exam;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_in_order;

    FUNCTION get_exam_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN VARCHAR2,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_exam_req            IN exam_req.id_exam_req%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_exam_req(l_tbl_co_sign t_table_co_sign) IS
            WITH eea_w AS
             (SELECT id_exam,
                     id_exam_req_det,
                     id_episode,
                     flg_type,
                     id_prof_req,
                     flg_time,
                     flg_status_det,
                     flg_status_req,
                     flg_referral,
                     dt_begin,
                     id_movement
                FROM exams_ea
               WHERE id_exam_req_det = i_exam_req_det
                 AND i_exam_req_det IS NOT NULL
              UNION
              SELECT id_exam,
                     id_exam_req_det,
                     id_episode,
                     flg_type,
                     id_prof_req,
                     flg_time,
                     flg_status_det,
                     flg_status_req,
                     flg_referral,
                     dt_begin,
                     id_movement
                FROM exams_ea
               WHERE id_exam_req = i_exam_req
                 AND i_exam_req IS NOT NULL),
            erd_w AS
             (SELECT id_exam_req_det, id_co_sign_order, id_room
                FROM exam_req_det
               WHERE id_exam_req_det = i_exam_req_det
                 AND i_exam_req_det IS NOT NULL
              UNION
              SELECT id_exam_req_det, id_co_sign_order, id_room
                FROM exam_req_det
               WHERE id_exam_req = i_exam_req
                 AND i_exam_req IS NOT NULL),
            edcs_w AS
             (SELECT /*+ materialized */
               *
                FROM exam_dep_clin_serv
               WHERE flg_type = pk_exam_constant.g_exam_can_req
                 AND id_institution = i_prof.institution
                 AND id_software = i_prof.software)
            SELECT /*+ opt_estimate(table cso rows=1) */
             eea.id_episode exam_episode,
             eea.flg_type,
             eea.id_prof_req,
             cso.desc_prof_ordered_by id_prof_order,
             eea.flg_time,
             decode(i_exam_req, NULL, eea.flg_status_det, eea.flg_status_req) flg_status,
             eea.flg_referral,
             eea.dt_begin,
             decode(eea.id_movement, NULL, edcs.flg_mov_pat, pk_exam_constant.g_no) flg_mov_pat,
             edcs.flg_first_execute,
             edcs.flg_first_result,
             erd.id_room exam_room
              FROM eea_w eea
              JOIN erd_w erd
                ON eea.id_exam_req_det = erd.id_exam_req_det
              LEFT JOIN TABLE (l_tbl_co_sign) cso
                ON erd.id_co_sign_order = cso.id_co_sign_hist
              LEFT JOIN edcs_w edcs
                ON eea.id_exam = edcs.id_exam;
    
        l_permission VARCHAR2(1 CHAR);
    
        l_exam_req     c_exam_req%ROWTYPE;
        l_episode_type episode.id_epis_type%TYPE;
        l_episode_room epis_info.id_room%TYPE;
    
        l_tbl_co_sign t_table_co_sign;
    
        l_edis                       sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof);
        l_care                       sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
        l_imaging                    sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_ITECH', i_prof);
        l_exams                      sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_EXAMS', i_prof);
        l_workflow                   sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_WORKFLOW', i_prof);
        l_ref                        sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
        l_ref_shortcut               sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_MCDT_SHORTCUT', i_prof);
        l_cancel_order               sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_ORDER_CANCEL', i_prof);
        l_canceling_permission       sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_CANCEL_PERMISSION', i_prof);
        l_reading_to_all_permission  sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_READING_PERMISSION_TO_ALL',
                                                                                      i_prof);
        l_reading_permission         sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_READING_PERMISSION_BY_PROFILE_TEMPLATE',
                                                                                      i_prof);
        l_reading_without_permission sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_READING_WITHOUT_PERMISSIONS_BY_PROF_TEMPLATE',
                                                                                      i_prof);
    
        l_prof_cat_type category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
        l_view_only_profile VARCHAR2(1 CHAR) := pk_prof_utils.check_has_functionality(i_lang,
                                                                                      i_prof,
                                                                                      'READ ONLY PROFILE');
    
    BEGIN
    
        BEGIN
            IF rec_co_sign(i_lang) (i_prof.id) (i_prof.institution) (i_prof.software) (i_episode)(1).count > 0
            THEN
                l_tbl_co_sign := rec_co_sign(i_lang) (i_prof.id) (i_prof.institution) (i_prof.software) (i_episode) (1);
            ELSE
                l_tbl_co_sign := pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, i_episode, NULL);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_co_sign := pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, i_episode, NULL);
                IF i_lang IS NOT NULL
                   AND i_prof.id IS NOT NULL
                   AND i_prof.institution IS NOT NULL
                   AND i_prof.software IS NOT NULL
                   AND i_episode IS NOT NULL
                THEN
                    rec_co_sign(i_lang)(i_prof.id)(i_prof.institution)(i_prof.software)(i_episode)(1) := l_tbl_co_sign;
                END IF;
            WHEN OTHERS THEN
                l_tbl_co_sign := pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, i_episode, NULL);
        END;
    
        g_error := 'OPEN C_EXAM_REQ';
        OPEN c_exam_req(l_tbl_co_sign);
        FETCH c_exam_req
            INTO l_exam_req;
        CLOSE c_exam_req;
    
        IF i_episode IS NOT NULL
        THEN
            g_error := 'SELECT EPIS_INFO';
            SELECT ei.id_room
              INTO l_episode_room
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        END IF;
    
        IF i_area = pk_exam_constant.g_exam_area_exams
        THEN
            IF i_button = pk_exam_constant.g_exam_button_ok
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_referral IN (pk_exam_constant.g_flg_referral_r,
                                                   pk_exam_constant.g_flg_referral_s,
                                                   pk_exam_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        IF i_prof.software = l_imaging
                        THEN
                            IF i_flg_current_episode = pk_exam_constant.g_yes
                            THEN
                                IF l_exam_req.flg_status IN (pk_exam_constant.g_exam_exterior,
                                                             pk_exam_constant.g_exam_tosched,
                                                             pk_exam_constant.g_exam_sched,
                                                             pk_exam_constant.g_exam_cancel)
                                THEN
                                    l_permission := pk_exam_constant.g_no;
                                ELSE
                                    IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_n
                                    THEN
                                        IF i_episode = l_exam_req.exam_episode
                                        THEN
                                            IF l_exam_req.flg_status IN
                                               (pk_exam_constant.g_exam_wtg_tde,
                                                pk_exam_constant.g_exam_req,
                                                pk_exam_constant.g_exam_toexec,
                                                pk_exam_constant.g_exam_exec)
                                            THEN
                                                IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                                   OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    l_permission := pk_exam_constant.g_no;
                                                ELSE
                                                    IF l_exam_req.flg_mov_pat = pk_exam_constant.g_yes
                                                    THEN
                                                        IF l_episode_room = l_exam_req.exam_room
                                                        THEN
                                                            l_permission := pk_exam_constant.g_yes;
                                                        ELSE
                                                            IF l_episode_type = 1
                                                            THEN
                                                                l_permission := pk_exam_constant.g_yes;
                                                            ELSE
                                                                l_permission := pk_exam_constant.g_no;
                                                            END IF;
                                                        END IF;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_yes;
                                                    END IF;
                                                END IF;
                                            ELSE
                                                l_permission := pk_exam_constant.g_yes;
                                            END IF;
                                        ELSE
                                            l_permission := pk_exam_constant.g_no;
                                        END IF;
                                    ELSE
                                        IF i_episode = l_exam_req.exam_episode
                                        THEN
                                            IF l_exam_req.flg_status IN
                                               (pk_exam_constant.g_exam_req,
                                                pk_exam_constant.g_exam_toexec,
                                                pk_exam_constant.g_exam_exec)
                                            THEN
                                                IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                                   OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    l_permission := pk_exam_constant.g_no;
                                                ELSE
                                                    IF l_exam_req.flg_mov_pat = pk_exam_constant.g_yes
                                                    THEN
                                                        IF l_episode_room = l_exam_req.exam_room
                                                        THEN
                                                            l_permission := pk_exam_constant.g_yes;
                                                        ELSE
                                                            IF l_episode_type = 1
                                                            THEN
                                                                l_permission := pk_exam_constant.g_yes;
                                                            ELSE
                                                                l_permission := pk_exam_constant.g_no;
                                                            END IF;
                                                        END IF;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_yes;
                                                    END IF;
                                                END IF;
                                            ELSE
                                                l_permission := pk_exam_constant.g_yes;
                                            END IF;
                                        ELSE
                                            IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                               OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                l_permission := pk_exam_constant.g_no;
                                            ELSE
                                                l_permission := pk_exam_constant.g_yes;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                   AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                THEN
                                    l_permission := pk_exam_constant.g_yes;
                                ELSE
                                    l_permission := pk_exam_constant.g_no;
                                END IF;
                            END IF;
                        ELSIF i_prof.software = l_exams
                        THEN
                            IF i_flg_current_episode = pk_exam_constant.g_yes
                            THEN
                                IF i_episode = l_exam_req.exam_episode
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_technician
                                    THEN
                                        IF l_exam_req.flg_type = pk_exam_constant.g_type_img
                                        THEN
                                            l_permission := pk_exam_constant.g_no;
                                        ELSE
                                            IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                               OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                l_permission := pk_exam_constant.g_no;
                                            ELSE
                                                IF l_exam_req.flg_status IN
                                                   (pk_exam_constant.g_exam_exterior, pk_exam_constant.g_exam_cancel)
                                                THEN
                                                    l_permission := pk_exam_constant.g_no;
                                                ELSE
                                                    IF l_exam_req.dt_begin IS NULL
                                                    THEN
                                                        l_permission := pk_exam_constant.g_no;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_yes;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        END IF;
                                    ELSE
                                        l_permission := pk_exam_constant.g_yes;
                                    END IF;
                                ELSE
                                    IF l_exam_req.flg_status IN
                                       (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched)
                                    THEN
                                        l_permission := pk_exam_constant.g_no;
                                    ELSE
                                        IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                           OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                        THEN
                                            l_permission := pk_exam_constant.g_no;
                                        ELSE
                                            l_permission := pk_exam_constant.g_yes;
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                   AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                THEN
                                    l_permission := pk_exam_constant.g_yes;
                                ELSE
                                    l_permission := pk_exam_constant.g_no;
                                END IF;
                            END IF;
                        ELSE
                            IF l_exam_req.flg_status = pk_exam_constant.g_exam_cancel
                            THEN
                                l_permission := pk_exam_constant.g_no;
                            ELSIF l_exam_req.flg_status = pk_exam_constant.g_exam_result
                            THEN
                                IF instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                THEN
                                    l_permission := pk_exam_constant.g_no;
                                ELSE
                                    l_permission := pk_exam_constant.g_yes;
                                END IF;
                            ELSIF l_exam_req.flg_status = pk_exam_constant.g_exam_read
                            THEN
                                IF l_episode_type IN
                                   (pk_exam_constant.g_episode_type_rad, pk_exam_constant.g_episode_type_exm)
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                ELSE
                                    IF i_prof.id IN (l_exam_req.id_prof_req, l_exam_req.id_prof_order)
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        SELECT decode(i_prof.id,
                                                      pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                   i_prof,
                                                                                                   e.id_episode,
                                                                                                   l_prof_cat_type,
                                                                                                   NULL),
                                                      pk_exam_constant.g_yes,
                                                      pk_exam_constant.g_no)
                                          INTO l_permission
                                          FROM episode e
                                         WHERE e.id_episode = i_episode;
                                    END IF;
                                END IF;
                            ELSE
                                IF i_flg_current_episode = pk_exam_constant.g_yes
                                THEN
                                    IF l_exam_req.flg_status = pk_exam_constant.g_exam_exterior
                                    THEN
                                        IF l_ref = pk_exam_constant.g_yes
                                           AND l_ref_shortcut = pk_exam_constant.g_yes
                                           AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                        THEN
                                            l_permission := pk_exam_constant.g_yes;
                                        ELSE
                                            l_permission := pk_exam_constant.g_no;
                                        END IF;
                                    ELSE
                                        IF l_workflow = pk_exam_constant.g_yes
                                        THEN
                                            IF i_prof.software = l_edis
                                               AND l_exam_req.flg_mov_pat = pk_exam_constant.g_yes
                                            THEN
                                                IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                                THEN
                                                    IF l_exam_req.flg_status IN
                                                       (pk_exam_constant.g_exam_pending,
                                                        pk_exam_constant.g_exam_end_transp,
                                                        pk_exam_constant.g_exam_toexec,
                                                        pk_exam_constant.g_exam_exec,
                                                        pk_exam_constant.g_exam_result)
                                                    THEN
                                                        l_permission := pk_exam_constant.g_yes;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_no;
                                                    END IF;
                                                ELSIF l_prof_cat_type = pk_alert_constant.g_cat_type_nurse
                                                THEN
                                                    IF l_exam_req.flg_status = pk_exam_constant.g_exam_pending
                                                    THEN
                                                        l_permission := pk_exam_constant.g_yes;
                                                    ELSIF l_exam_req.flg_status IN
                                                          (pk_exam_constant.g_exam_req,
                                                           pk_exam_constant.g_exam_toexec,
                                                           pk_exam_constant.g_exam_exec)
                                                    THEN
                                                        IF instr(nvl(l_exam_req.flg_first_execute, '#'),
                                                                 l_prof_cat_type) = 0
                                                        THEN
                                                            l_permission := pk_exam_constant.g_yes;
                                                        ELSE
                                                            l_permission := pk_exam_constant.g_no;
                                                        END IF;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_no;
                                                    END IF;
                                                END IF;
                                            ELSE
                                                IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                                THEN
                                                    IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                                    THEN
                                                        IF l_exam_req.flg_status IN
                                                           (pk_exam_constant.g_exam_pending,
                                                            pk_exam_constant.g_exam_result,
                                                            pk_exam_constant.g_exam_read)
                                                        THEN
                                                            l_permission := pk_exam_constant.g_yes;
                                                        ELSE
                                                            l_permission := pk_exam_constant.g_no;
                                                        END IF;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_yes;
                                                    END IF;
                                                ELSIF l_exam_req.flg_time = pk_exam_constant.g_flg_time_n
                                                THEN
                                                    IF i_episode = l_exam_req.exam_episode
                                                    THEN
                                                        IF instr(nvl(l_exam_req.flg_first_execute, '#'),
                                                                 l_prof_cat_type) = 0
                                                        THEN
                                                            IF l_exam_req.flg_status IN
                                                               (pk_exam_constant.g_exam_pending,
                                                                pk_exam_constant.g_exam_result,
                                                                pk_exam_constant.g_exam_read)
                                                            THEN
                                                                l_permission := pk_exam_constant.g_yes;
                                                            ELSE
                                                                l_permission := pk_exam_constant.g_no;
                                                            END IF;
                                                        ELSE
                                                            l_permission := pk_exam_constant.g_yes;
                                                        END IF;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_no;
                                                    END IF;
                                                ELSE
                                                    IF i_prof.software = l_care
                                                    THEN
                                                        IF l_exam_req.flg_status IN
                                                           (pk_exam_constant.g_exam_pending,
                                                            pk_exam_constant.g_exam_req)
                                                        THEN
                                                            IF instr(nvl(l_exam_req.flg_first_execute, '#'),
                                                                     l_prof_cat_type) = 0
                                                            THEN
                                                                l_permission := pk_exam_constant.g_no;
                                                            ELSE
                                                                l_permission := pk_exam_constant.g_yes;
                                                            END IF;
                                                        ELSE
                                                            l_permission := pk_exam_constant.g_no;
                                                        END IF;
                                                    ELSE
                                                        IF l_exam_req.flg_status IN
                                                           (pk_exam_constant.g_exam_sched,
                                                            pk_exam_constant.g_exam_tosched)
                                                        THEN
                                                            l_permission := pk_exam_constant.g_no;
                                                        ELSE
                                                            IF instr(nvl(l_exam_req.flg_first_execute, '#'),
                                                                     l_prof_cat_type) = 0
                                                            THEN
                                                                l_permission := pk_exam_constant.g_no;
                                                            ELSE
                                                                l_permission := pk_exam_constant.g_yes;
                                                            END IF;
                                                        END IF;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        ELSE
                                            IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_n
                                            THEN
                                                IF i_episode = l_exam_req.exam_episode
                                                THEN
                                                    IF instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                    THEN
                                                        l_permission := pk_exam_constant.g_no;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_yes;
                                                    END IF;
                                                ELSE
                                                    l_permission := pk_exam_constant.g_no;
                                                END IF;
                                            ELSIF l_exam_req.flg_time IN
                                                  (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                                            THEN
                                                IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                                THEN
                                                    l_permission := pk_exam_constant.g_yes;
                                                ELSE
                                                    IF instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                    THEN
                                                        l_permission := pk_exam_constant.g_no;
                                                    ELSE
                                                        l_permission := pk_exam_constant.g_yes;
                                                    END IF;
                                                END IF;
                                            ELSE
                                                IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                                   OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                THEN
                                                    l_permission := pk_exam_constant.g_no;
                                                ELSE
                                                    l_permission := pk_exam_constant.g_yes;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                ELSE
                                    IF i_prof.software = l_edis
                                    THEN
                                        l_permission := pk_exam_constant.g_no;
                                    ELSE
                                        IF l_exam_req.flg_status IN
                                           (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched)
                                        THEN
                                            l_permission := pk_exam_constant.g_no;
                                        ELSE
                                            IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                                               OR instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                            THEN
                                                l_permission := pk_exam_constant.g_no;
                                            ELSE
                                                l_permission := pk_exam_constant.g_yes;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_cancel
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_referral IN (pk_exam_constant.g_flg_referral_r,
                                                   pk_exam_constant.g_flg_referral_s,
                                                   pk_exam_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        IF l_exam_req.flg_status IN (pk_exam_constant.g_exam_exec,
                                                     pk_exam_constant.g_exam_result,
                                                     pk_exam_constant.g_exam_read,
                                                     pk_exam_constant.g_exam_cancel)
                        THEN
                            l_permission := pk_exam_constant.g_no;
                        ELSE
                            IF l_cancel_order = pk_exam_constant.g_yes
                            THEN
                                BEGIN
                                    SELECT pk_exam_constant.g_no
                                      INTO l_permission
                                      FROM TABLE(pk_string_utils.str_split(l_canceling_permission, '|'))
                                     WHERE column_value = l_exam_req.flg_status;
                                
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        IF l_prof_cat_type NOT IN
                                           (pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_technician)
                                        THEN
                                            IF pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                                                    i_prof                   => i_prof,
                                                                                    i_episode                => i_episode,
                                                                                    i_task_type              => CASE
                                                                                                                    WHEN l_exam_req.flg_type =
                                                                                                                         pk_exam_constant.g_type_img THEN
                                                                                                                     pk_alert_constant.g_task_imaging_exams
                                                                                                                    ELSE
                                                                                                                     pk_alert_constant.g_task_other_exams
                                                                                                                END,
                                                                                    i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_cancel) =
                                             pk_exam_constant.g_yes
                                            THEN
                                                l_permission := pk_exam_constant.g_yes;
                                            ELSE
                                                IF pk_prof_utils.get_category(i_lang,
                                                                              profissional(l_exam_req.id_prof_req,
                                                                                           i_prof.institution,
                                                                                           i_prof.software)) =
                                                   l_prof_cat_type
                                                THEN
                                                    l_permission := pk_exam_constant.g_yes;
                                                ELSE
                                                    l_permission := pk_exam_constant.g_no;
                                                END IF;
                                            END IF;
                                        ELSE
                                            l_permission := pk_exam_constant.g_yes;
                                        END IF;
                                END;
                            ELSE
                                l_permission := pk_exam_constant.g_no;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_action
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status = pk_exam_constant.g_exam_cancel
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        l_permission := pk_exam_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_edit
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_referral IN (pk_exam_constant.g_flg_referral_r,
                                                   pk_exam_constant.g_flg_referral_s,
                                                   pk_exam_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSIF l_exam_req.flg_status IN (pk_exam_constant.g_exam_sos,
                                                    pk_exam_constant.g_exam_exterior,
                                                    pk_exam_constant.g_exam_tosched,
                                                    pk_exam_constant.g_exam_pending,
                                                    pk_exam_constant.g_exam_req)
                    THEN
                        IF pk_prof_utils.get_category(i_lang,
                                                      profissional(l_exam_req.id_prof_req,
                                                                   i_prof.institution,
                                                                   i_prof.software)) =
                           pk_alert_constant.g_cat_type_nutritionist
                        THEN
                            l_permission := pk_exam_constant.g_no;
                        ELSE
                            l_permission := pk_exam_constant.g_yes;
                        END IF;
                    ELSE
                        l_permission := pk_exam_constant.g_no;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_confirmation
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.exam_episode IS NOT NULL
                    THEN
                        IF l_exam_req.flg_status = pk_exam_constant.g_exam_pending
                        THEN
                            l_permission := pk_exam_constant.g_yes;
                        ELSIF l_exam_req.flg_status = pk_exam_constant.g_exam_exterior
                              AND l_ref = pk_exam_constant.g_yes
                        THEN
                            l_permission := pk_exam_constant.g_yes;
                        ELSE
                            l_permission := pk_exam_constant.g_no;
                        END IF;
                    ELSE
                        IF l_exam_req.flg_status = pk_exam_constant.g_exam_exterior
                           AND l_ref = pk_exam_constant.g_yes
                        THEN
                            l_permission := pk_exam_constant.g_yes;
                        ELSE
                            l_permission := pk_exam_constant.g_no;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_read
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    BEGIN
                        -- Checks if exists any profile that exceptionaly should NOT have reading permissions. --
                        -- If returns, the reading permission should be disabled, otherwise proceeds with validation --
                        -- USA - Tuba City request --
                        SELECT DISTINCT pk_exam_constant.g_no
                          INTO l_permission
                          FROM TABLE(pk_string_utils.str_split(l_reading_without_permission, '|'))
                         WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            IF l_exam_req.flg_status = pk_exam_constant.g_exam_result
                               OR l_exam_req.flg_status = pk_exam_constant.g_exam_read
                            THEN
                                IF l_reading_to_all_permission = pk_exam_constant.g_yes
                                THEN
                                    l_permission := pk_exam_constant.g_yes;
                                ELSE
                                    IF i_prof.software = l_imaging
                                    THEN
                                        IF i_flg_current_episode = pk_exam_constant.g_yes
                                        THEN
                                            IF i_episode = l_exam_req.exam_episode
                                            THEN
                                                IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_n
                                                THEN
                                                    l_permission := pk_exam_constant.g_no;
                                                ELSE
                                                    l_permission := pk_exam_constant.g_yes;
                                                END IF;
                                            ELSE
                                                l_permission := pk_exam_constant.g_no;
                                            END IF;
                                        ELSE
                                            IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                               AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                            THEN
                                                l_permission := pk_exam_constant.g_yes;
                                            ELSE
                                                l_permission := pk_exam_constant.g_no;
                                            END IF;
                                        END IF;
                                    ELSIF i_prof.software = l_exams
                                    THEN
                                        IF i_flg_current_episode = pk_exam_constant.g_yes
                                        THEN
                                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_technician
                                            THEN
                                                IF l_exam_req.flg_type = pk_exam_constant.g_type_img
                                                THEN
                                                    l_permission := pk_exam_constant.g_no;
                                                ELSE
                                                    IF instr(nvl(l_exam_req.flg_first_result, '#'), l_prof_cat_type) = 0
                                                    THEN
                                                        l_permission := pk_exam_constant.g_no;
                                                    ELSE
                                                        IF l_exam_req.dt_begin IS NULL
                                                        THEN
                                                            l_permission := pk_exam_constant.g_no;
                                                        ELSE
                                                            l_permission := pk_exam_constant.g_yes;
                                                        END IF;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        ELSE
                                            IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                               AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                            THEN
                                                l_permission := pk_exam_constant.g_yes;
                                            ELSE
                                                l_permission := pk_exam_constant.g_no;
                                            END IF;
                                        END IF;
                                    ELSE
                                        IF l_episode_type IN
                                           (pk_exam_constant.g_episode_type_rad, pk_exam_constant.g_episode_type_exm)
                                        THEN
                                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                            THEN
                                                l_permission := pk_exam_constant.g_yes;
                                            ELSE
                                                l_permission := pk_exam_constant.g_no;
                                            END IF;
                                        ELSE
                                            BEGIN
                                                -- Checks if exists any profile that shoud have reading permissions. --
                                                -- If returns, it should proceed without any validation, and the reading option will be visible. --
                                                -- UK - Brighton NHS Trust request --           
                                                SELECT DISTINCT pk_exam_constant.g_yes
                                                  INTO l_permission
                                                  FROM TABLE(pk_string_utils.str_split(l_reading_permission, '|'))
                                                 WHERE column_value = pk_prof_utils.get_prof_profile_template(i_prof);
                                            
                                            EXCEPTION
                                                WHEN no_data_found THEN
                                                    IF i_prof.id IN (l_exam_req.id_prof_req, l_exam_req.id_prof_order)
                                                    THEN
                                                        l_permission := pk_exam_constant.g_yes;
                                                    ELSE
                                                        SELECT decode(i_prof.id,
                                                                      pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                                   i_prof,
                                                                                                                   e.id_episode,
                                                                                                                   l_prof_cat_type,
                                                                                                                   NULL),
                                                                      pk_exam_constant.g_yes,
                                                                      pk_exam_constant.g_no)
                                                          INTO l_permission
                                                          FROM episode e
                                                         WHERE e.id_episode = i_episode;
                                                    END IF;
                                            END;
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                l_permission := pk_exam_constant.g_no;
                            END IF;
                    END;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_detail
            THEN
                l_permission := pk_exam_constant.g_yes;
            END IF;
        ELSIF i_area = pk_exam_constant.g_exam_area_orders
        THEN
            IF i_button = pk_exam_constant.g_exam_button_ok
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read)
                    THEN
                        IF l_reading_to_all_permission = pk_exam_constant.g_yes
                        THEN
                            l_permission := pk_exam_constant.g_yes;
                        ELSE
                            IF i_prof.software IN (l_imaging, l_exams)
                            THEN
                                IF i_flg_current_episode = pk_exam_constant.g_yes
                                THEN
                                    IF i_episode = l_exam_req.exam_episode
                                    THEN
                                        IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_n
                                        THEN
                                            l_permission := pk_exam_constant.g_no;
                                        ELSE
                                            l_permission := pk_exam_constant.g_yes;
                                        END IF;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                ELSE
                                    IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                       AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                END IF;
                            ELSE
                                IF l_episode_type IN
                                   (pk_exam_constant.g_episode_type_rad, pk_exam_constant.g_episode_type_exm)
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                ELSE
                                    IF i_prof.id IN (l_exam_req.id_prof_req, l_exam_req.id_prof_order)
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        SELECT decode(i_prof.id,
                                                      pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                   i_prof,
                                                                                                   e.id_episode,
                                                                                                   l_prof_cat_type,
                                                                                                   NULL),
                                                      pk_exam_constant.g_yes,
                                                      pk_exam_constant.g_no)
                                          INTO l_permission
                                          FROM episode e
                                         WHERE e.id_episode = i_episode;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    ELSE
                        l_permission := pk_exam_constant.g_no;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_cancel
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN (pk_exam_constant.g_exam_ongoing,
                                                 pk_exam_constant.g_exam_partial,
                                                 pk_exam_constant.g_exam_result,
                                                 pk_exam_constant.g_exam_read_partial,
                                                 pk_exam_constant.g_exam_read,
                                                 pk_exam_constant.g_exam_cancel)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        IF l_cancel_order = pk_exam_constant.g_yes
                        THEN
                            l_permission := pk_exam_constant.g_yes;
                        ELSE
                            l_permission := pk_exam_constant.g_no;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_edit
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN (pk_exam_constant.g_exam_ongoing,
                                                 pk_exam_constant.g_exam_partial,
                                                 pk_exam_constant.g_exam_result,
                                                 pk_exam_constant.g_exam_read_partial,
                                                 pk_exam_constant.g_exam_read,
                                                 pk_exam_constant.g_exam_cancel)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        l_permission := pk_exam_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_action
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status = pk_exam_constant.g_exam_cancel
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        l_permission := pk_exam_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_read
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read)
                    THEN
                        IF l_reading_to_all_permission = pk_exam_constant.g_yes
                        THEN
                            l_permission := pk_exam_constant.g_yes;
                        ELSE
                            IF i_prof.software IN (l_imaging, l_exams)
                            THEN
                                IF i_flg_current_episode = pk_exam_constant.g_yes
                                THEN
                                    IF i_episode = l_exam_req.exam_episode
                                    THEN
                                        IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_n
                                        THEN
                                            l_permission := pk_exam_constant.g_no;
                                        ELSE
                                            l_permission := pk_exam_constant.g_yes;
                                        END IF;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                ELSE
                                    IF l_exam_req.flg_time = pk_exam_constant.g_flg_time_e
                                       AND l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                END IF;
                            ELSE
                                IF l_episode_type IN
                                   (pk_exam_constant.g_episode_type_rad, pk_exam_constant.g_episode_type_exm)
                                THEN
                                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_doc
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        l_permission := pk_exam_constant.g_no;
                                    END IF;
                                ELSE
                                    IF i_prof.id IN (l_exam_req.id_prof_req, l_exam_req.id_prof_order)
                                    THEN
                                        l_permission := pk_exam_constant.g_yes;
                                    ELSE
                                        SELECT decode(i_prof.id,
                                                      pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                   i_prof,
                                                                                                   e.id_episode,
                                                                                                   l_prof_cat_type,
                                                                                                   NULL),
                                                      pk_exam_constant.g_yes,
                                                      pk_exam_constant.g_no)
                                          INTO l_permission
                                          FROM episode e
                                         WHERE e.id_episode = i_episode;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    ELSE
                        l_permission := pk_exam_constant.g_no;
                    END IF;
                END IF;
            END IF;
        ELSIF i_area = pk_exam_constant.g_exam_area_perform
        THEN
            IF i_button = pk_exam_constant.g_exam_button_ok
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN
                       (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                        THEN
                            l_permission := pk_exam_constant.g_no;
                        ELSE
                            l_permission := pk_exam_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_cancel
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN
                       (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        l_permission := pk_exam_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_edit
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN
                       (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                        THEN
                            l_permission := pk_exam_constant.g_no;
                        ELSE
                            l_permission := pk_exam_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_exam_constant.g_exam_button_action
            THEN
                IF l_view_only_profile = pk_exam_constant.g_yes
                THEN
                    l_permission := pk_exam_constant.g_no;
                ELSE
                    IF l_exam_req.flg_status IN
                       (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
                    THEN
                        l_permission := pk_exam_constant.g_no;
                    ELSE
                        IF instr(nvl(l_exam_req.flg_first_execute, '#'), l_prof_cat_type) = 0
                        THEN
                            l_permission := pk_exam_constant.g_no;
                        ELSE
                            l_permission := pk_exam_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_permission;

    FUNCTION get_exam_timeout
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN exam.id_exam%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_timeout VARCHAR2(1 CHAR);
    
    BEGIN
    
        SELECT nvl(edcs.flg_timeout, pk_exam_constant.g_no)
          INTO l_flg_timeout
          FROM exam_dep_clin_serv edcs
         WHERE edcs.id_exam = i_exam
           AND edcs.flg_type = pk_exam_constant.g_exam_can_req
           AND edcs.id_institution = i_prof.institution
           AND edcs.id_software = i_prof.software;
    
        RETURN l_flg_timeout;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_timeout;

    FUNCTION get_exam_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN exam_req_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_diagnosis_list IS
            SELECT pk_diagnosis.get_mcdt_description(i_lang, i_prof, t.id_diagnosis_list) diagnosis_desc
              FROM (SELECT column_value id_diagnosis_list
                      FROM TABLE(CAST(pk_utils.str_split(i_diagnosis_list, ';') AS table_varchar2))) t;
    
        l_diagnosis_list c_diagnosis_list%ROWTYPE;
    
        l_diagnosis_desc VARCHAR2(4000);
    
    BEGIN
    
        FOR l_diagnosis_list IN c_diagnosis_list
        LOOP
            IF l_diagnosis_desc IS NULL
            THEN
                l_diagnosis_desc := l_diagnosis_list.diagnosis_desc;
            ELSE
                l_diagnosis_desc := l_diagnosis_desc || ', ' || l_diagnosis_list.diagnosis_desc;
            END IF;
        END LOOP;
    
        RETURN l_diagnosis_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_diagnosis;

    FUNCTION get_exam_codification
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_exam_codification IN exam_codification.id_exam_codification%TYPE
    ) RETURN NUMBER IS
    
        l_codification NUMBER;
    
    BEGIN
    
        IF i_exam_codification IS NOT NULL
        THEN
            g_error := 'SELECT EXAM_CODIFICATION';
            SELECT ec.id_codification
              INTO l_codification
              FROM exam_codification ec
             WHERE ec.id_exam_codification = i_exam_codification;
        ELSE
            l_codification := NULL;
        END IF;
    
        RETURN l_codification;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_codification;

    FUNCTION get_exam_with_codification
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN exam.id_exam%TYPE
    ) RETURN VARCHAR2 IS
    
        l_codification VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_exam IS NOT NULL
        THEN
            g_error := 'GET CODIFICATION';
            SELECT ' (' || listagg(desc_codification, ', ') within GROUP(ORDER BY c.desc_codification) || ')'
              INTO l_codification
              FROM (SELECT pk_translation.get_translation(i_lang, c.code_codification) desc_codification
                      FROM exam_codification ec, codification_instit_soft cis, codification c
                     WHERE ec.id_exam = i_exam
                       AND ec.flg_show_codification = pk_exam_constant.g_yes
                       AND ec.flg_available = pk_exam_constant.g_available
                       AND ec.id_codification = cis.id_codification
                       AND cis.id_institution = i_prof.institution
                       AND cis.id_software = i_prof.software
                       AND cis.flg_available = pk_exam_constant.g_available
                       AND cis.id_codification = c.id_codification
                       AND c.flg_available = pk_exam_constant.g_available) c;
        ELSE
            l_codification := NULL;
        END IF;
    
        IF l_codification = ' ()'
        THEN
            l_codification := NULL;
        END IF;
    
        RETURN l_codification;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_with_codification;

    FUNCTION get_exam_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_icon_name VARCHAR2(200 CHAR);
    
    BEGIN
    
        g_error := 'GET ICON';
        SELECT substr(decode(eea.flg_doc,
                             pk_exam_constant.g_yes,
                             pk_sysdomain.get_img(i_lang,
                                                  'EXAM_MEDIA_ARCHIVE.FLG_TYPE',
                                                  pk_exam_constant.g_media_archive_exam_doc) || '|',
                             NULL) || decode(eea.flg_relevant,
                                             pk_exam_constant.g_yes,
                                             pk_sysdomain.get_img(i_lang, 'EXAM_RESULT.FLG_RELEVANT', eea.flg_relevant) || '|',
                                             NULL),
                      1,
                      length(decode(eea.flg_doc,
                                    pk_exam_constant.g_yes,
                                    pk_sysdomain.get_img(i_lang,
                                                         'EXAM_MEDIA_ARCHIVE.FLG_TYPE',
                                                         pk_exam_constant.g_media_archive_exam_doc) || '|',
                                    NULL) ||
                             decode(eea.flg_relevant,
                                    pk_exam_constant.g_yes,
                                    pk_sysdomain.get_img(i_lang, 'EXAM_RESULT.FLG_RELEVANT', eea.flg_relevant) || '|',
                                    NULL)) - 1)
          INTO l_icon_name
          FROM exams_ea eea
         WHERE eea.id_exam_req_det = i_exam_req_det;
    
        RETURN l_icon_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_icon;

    FUNCTION get_exam_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_field      IN table_varchar,
        i_exam_field_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_detail VARCHAR2(1000 CHAR);
    
    BEGIN
    
        -- 'T' - Title
        -- 'F'
        IF i_exam_field_type = 'T'
        THEN
            FOR i IN 2 .. i_exam_field.count
            LOOP
                IF i_exam_field(i) IS NOT NULL
                THEN
                    l_detail := i_exam_field(1);
                END IF;
            END LOOP;
        ELSE
            IF i_exam_field(1) IS NOT NULL
            THEN
                l_detail := chr(9) || chr(32) || chr(32) || i_exam_field(1);
            END IF;
        END IF;
    
        RETURN l_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_detail;

    FUNCTION get_exam_detail_clob
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_field      IN table_clob,
        i_exam_field_type IN VARCHAR2
    ) RETURN CLOB IS
    
        l_detail CLOB;
    
    BEGIN
    
        -- 'T' - Title
        -- 'F'
        IF i_exam_field_type = 'T'
        THEN
            FOR i IN 2 .. i_exam_field.count
            LOOP
                IF i_exam_field(i) IS NOT NULL
                THEN
                    l_detail := i_exam_field(1);
                END IF;
            END LOOP;
        ELSE
            IF i_exam_field(1) IS NOT NULL
            THEN
                l_detail := chr(9) || chr(32) || chr(32) || i_exam_field(1);
            END IF;
        END IF;
    
        RETURN l_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_detail_clob;

    FUNCTION get_exam_question_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam          IN exam.id_exam%TYPE,
        i_flg_time      IN exam_questionnaire.flg_time%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN exam_questionnaire.flg_type%TYPE IS
    
        l_type exam_questionnaire.flg_type%TYPE;
    
    BEGIN
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_exam = ' || coalesce(to_char(i_exam), '<null>');
        g_error := g_error || ' i_questionnaire = ' || coalesce(to_char(i_questionnaire), '<null>');
        g_error := g_error || ' i_response = ' || coalesce(to_char(i_response), '<null>');
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package_name,
                              sub_object_name => 'GET_EXAM_QUESTIONNAIRE_TYPE');
    
        SELECT eq.flg_type
          INTO l_type
          FROM exam_questionnaire eq
         INNER JOIN questionnaire_response qr
            ON eq.id_questionnaire = qr.id_questionnaire
           AND eq.id_response = qr.id_response
         WHERE eq.id_exam = i_exam
           AND eq.flg_time = i_flg_time
           AND eq.id_questionnaire = i_questionnaire
           AND (eq.id_response = i_response OR i_response IS NULL)
           AND eq.id_institution = i_prof.institution
           AND eq.flg_available = pk_exam_constant.g_available
           AND qr.flg_available = pk_exam_constant.g_available
           AND rownum < 2;
    
        RETURN l_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_EXAM_QUESTION_TYPE',
                                                  l_error);
                RETURN NULL;
            END;
    END get_exam_question_type;

    FUNCTION get_exam_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_exam          IN exam.id_exam%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
        SELECT qr.id_response || '|' || qr.desc_response || '|' || qr.flg_free_text
          BULK COLLECT
          INTO l_response
          FROM (SELECT qr.id_response,
                       pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) desc_response,
                       r.flg_free_text,
                       qr.rank
                  FROM questionnaire_response qr, response r
                 WHERE qr.id_questionnaire = i_questionnaire
                   AND qr.flg_available = pk_exam_constant.g_available
                   AND qr.id_response = r.id_response
                   AND r.flg_available = pk_exam_constant.g_available
                   AND EXISTS (SELECT 1
                          FROM exam_questionnaire eq
                         WHERE eq.id_exam = i_exam
                           AND eq.flg_time = i_flg_time
                           AND eq.id_questionnaire = qr.id_questionnaire
                           AND eq.id_response = qr.id_response
                           AND eq.id_institution = i_prof.institution
                           AND eq.flg_available = pk_exam_constant.g_available)
                   AND (((l_patient.gender IS NOT NULL AND
                       coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                       l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                       (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND
                       nvl(r.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0))) qr
         ORDER BY qr.rank, qr.desc_response;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_response;

    FUNCTION get_exam_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN exam_question_response.notes%TYPE
    ) RETURN exam_question_response.notes%TYPE IS
    
        l_ret exam_question_response.notes%TYPE;
    
    BEGIN
        -- Heuristic to minimize attempts to parse an invalid date
        IF dbms_lob.getlength(i_notes) = length('YYYYMMDDHHMMSS') -- This is the size of a stored serialized date, not a mask (HH vs HH24).
        THEN
            -- We try to parse the note as a serialized date 
            l_ret := pk_date_utils.dt_chr_str(i_lang     => i_lang,
                                              i_date     => i_notes,
                                              i_inst     => i_prof.institution,
                                              i_soft     => i_prof.software,
                                              i_timezone => NULL);
        ELSE
            l_ret := i_notes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore parse errors and return original content
            RETURN i_notes;
    END get_exam_response;

    FUNCTION get_exam_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN exam_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2 IS
    
        l_response VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT substr(concatenate(t.id_response || '|'), 1, length(concatenate(t.id_response || '|')) - 1)
          INTO l_response
          FROM (SELECT eqr.id_response,
                       dense_rank() over(PARTITION BY eqr.id_questionnaire ORDER BY eqr.dt_last_update_tstz DESC) rn
                  FROM exam_question_response eqr
                 WHERE eqr.id_episode = i_episode
                   AND eqr.id_questionnaire = i_questionnaire) t
         WHERE t.rn = 1;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_episode_response;

    FUNCTION get_exam_result_url
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_url_type     IN VARCHAR2,
        i_count_img    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_url     VARCHAR2(4000 CHAR);
        l_hashmap pk_ia_external_info.tt_table_varchar;
    
        l_id_pat_pregnancy exam_req_det.id_pat_pregnancy%TYPE;
        l_count            NUMBER;
    
        l_error t_error_out;
    
    BEGIN
    
        IF pk_sysconfig.get_config(i_code_cf => 'IMAGE_INTERFACE', i_prof => i_prof) = pk_exam_constant.g_no
        THEN
            l_url := pk_exam_constant.g_no;
        ELSE
            g_error := 'HASHMAP PARAMETERS';
            l_hashmap('id_exam_req_det') := table_varchar(to_char(i_exam_req_det));
        
            IF i_url_type = pk_exam_constant.g_exam_result_url
            THEN
                g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_RIS_RESULT';
                IF NOT pk_ia_external_info.get_ris_result(i_prof    => i_prof,
                                                          i_hashmap => l_hashmap,
                                                          o_result  => l_url,
                                                          o_error   => l_error)
                THEN
                    l_url := pk_exam_constant.g_no;
                END IF;
            ELSE
                g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_RIS_REPORT';
                IF NOT pk_ia_external_info.get_ris_report(i_prof    => i_prof,
                                                          i_hashmap => l_hashmap,
                                                          o_report  => l_url,
                                                          o_error   => l_error)
                THEN
                    l_url := pk_exam_constant.g_no;
                END IF;
            END IF;
        
            g_error := 'No URL';
            IF nvl(l_url, '#') = '#'
            THEN
                l_url := pk_exam_constant.g_no;
            END IF;
        END IF;
    
        IF l_url = pk_exam_constant.g_no
           AND i_url_type <> pk_exam_constant.g_exam_result_pdf
        THEN
        
            g_error := 'CHECK ID_PAT_PREGNANCY';
            SELECT erd.id_pat_pregnancy
              INTO l_id_pat_pregnancy
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = i_exam_req_det;
        
            IF l_id_pat_pregnancy IS NOT NULL
            THEN
                BEGIN
                    l_url := pk_sysconfig.get_config('URL_DOC_IMAGE', i_prof);
                
                    IF i_count_img = 'U' -- returns URL
                    THEN
                        g_error := 'GET PREGNANCY URL';
                        SELECT REPLACE(REPLACE(REPLACE(l_url, '@1', erbi.id_doc_external), '@2', id_doc_image),
                                       '@3',
                                       '1')
                          INTO l_url
                          FROM exam_res_fetus_biom_img erbi,
                               exam_res_fetus_biom     erb,
                               exam_res_pregn_fetus    erf,
                               exam_result_pregnancy   erp,
                               exam_result             er,
                               doc_image               di,
                               doc_external            de
                         WHERE er.id_exam_req_det = i_exam_req_det
                           AND er.id_exam_result = erp.id_exam_result
                           AND er.flg_status != pk_exam_constant.g_exam_result_cancel
                           AND erp.id_exam_result_pregnancy = erf.id_exam_result_pregnancy
                           AND erf.id_exam_res_pregn_fetus = erb.id_exam_res_pregn_fetus
                           AND erb.id_exam_res_fetus_biom = erbi.id_exam_res_fetus_biom
                           AND erbi.id_doc_external = di.id_doc_external
                           AND de.id_doc_external = di.id_doc_external
                           AND de.flg_status != pk_alert_constant.g_inactive
                           AND rownum < 2
                         ORDER BY erbi.id_exam_res_fetus_biom_img DESC;
                    ELSIF i_count_img IN (pk_alert_constant.g_yes, 'C')
                    THEN
                        g_error := 'GET PREGNANCY IMG COUNT';
                        SELECT COUNT(*)
                          INTO l_count
                          FROM exam_res_fetus_biom_img erbi,
                               exam_res_fetus_biom     erb,
                               exam_res_pregn_fetus    erf,
                               exam_result_pregnancy   erp,
                               exam_result             er,
                               doc_image               di,
                               doc_external            de
                         WHERE er.id_exam_req_det = i_exam_req_det
                           AND er.id_exam_result = erp.id_exam_result
                           AND er.flg_status != pk_exam_constant.g_exam_result_cancel
                           AND erp.id_exam_result_pregnancy = erf.id_exam_result_pregnancy
                           AND erf.id_exam_res_pregn_fetus = erb.id_exam_res_pregn_fetus
                           AND erb.id_exam_res_fetus_biom = erbi.id_exam_res_fetus_biom
                           AND erbi.id_doc_external = di.id_doc_external
                           AND de.id_doc_external = di.id_doc_external
                           AND de.flg_status != pk_alert_constant.g_inactive;
                    END IF;
                
                    IF i_count_img = pk_alert_constant.g_yes
                       AND l_count > 0
                    THEN
                        l_url := 'U'; -- ultrasound has attached images
                    ELSIF i_count_img = 'C'
                          AND l_count > 0
                    THEN
                        l_url := to_char(l_count); -- returns the number of images
                    ELSIF l_count = 0
                    THEN
                        l_url := pk_exam_constant.g_no;
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_url := NULL;
                END;
            END IF;
        END IF;
    
        RETURN l_url;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_url;
    END get_exam_result_url;

    FUNCTION get_exam_result_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
    
        l_result_status NUMBER;
    
    BEGIN
    
        g_error := 'SELECT RESULT_STATUS';
        SELECT rs.id_result_status
          INTO l_result_status
          FROM result_status rs
         WHERE rs.flg_default = pk_exam_constant.g_yes
           AND rs.value = pk_exam_constant.g_exam_result
           AND rs.flg_multichoice = pk_exam_constant.g_yes
           AND rownum = 1;
    
        RETURN l_result_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_exam_result_status;

    FUNCTION get_exam_result_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_message            IN VARCHAR2,
        i_flg_report         IN VARCHAR2 DEFAULT 'N',
        i_epis_documentation IN exam_result.id_epis_documentation%TYPE
    ) RETURN CLOB IS
    
        l_notes                   CLOB;
        l_cur_exam_doc_val_result pk_touch_option_out.t_cur_plain_text_entry;
        l_exam_doc_val_result     pk_touch_option_out.t_rec_plain_text_entry;
    
    BEGIN
    
        g_error := 'CALL PK_TOUCH_OPTION_OUT.GET_PLAIN_TEXT_ENTRIES 2';
        pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                   i_prof                    => i_prof,
                                                   i_epis_documentation_list => table_number(i_epis_documentation),
                                                   i_use_html_format         => CASE
                                                                                    WHEN i_flg_report = pk_exam_constant.g_no THEN
                                                                                     pk_exam_constant.g_yes
                                                                                    ELSE
                                                                                     pk_exam_constant.g_no
                                                                                END,
                                                   o_entries                 => l_cur_exam_doc_val_result);
    
        FETCH l_cur_exam_doc_val_result
            INTO l_exam_doc_val_result;
        CLOSE l_cur_exam_doc_val_result;
    
        l_notes := REPLACE(l_exam_doc_val_result.plain_text_entry, chr(10) || chr(10), chr(10));
        l_notes := REPLACE(l_notes, chr(10), chr(10) || chr(9));
    
        SELECT decode(dbms_lob.getlength(l_notes),
                      NULL,
                      to_clob(''),
                      decode(i_flg_report,
                             pk_exam_constant.g_no,
                             decode(instr(lower(l_notes), '<b>'), 0, to_clob(i_message) || l_notes, l_notes),
                             l_notes)) notes
          INTO l_notes
          FROM dual;
    
        RETURN l_notes;
    
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END;

    FUNCTION create_body_struct_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mcs_concept        IN body_structure_rel.id_mcs_concept%TYPE,
        i_mcs_concept_parent IN body_structure_rel.id_mcs_concept_parent%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_mcs_concept        body_structure_rel.id_mcs_concept%TYPE;
        l_mcs_concept_parent body_structure_rel.id_mcs_concept_parent%TYPE;
    
        CURSOR c_exam_body_structure IS
            SELECT DISTINCT bs.id_mcs_concept, bs.id_body_structure
              FROM body_structure bs,
                   body_structure_dcs bsdcs,
                   exam_body_structure ebs,
                   (SELECT DISTINCT edcs1.id_exam
                      FROM exam_dep_clin_serv edcs1
                     WHERE edcs1.id_institution = i_prof.institution
                       AND edcs1.flg_type = pk_exam_constant.g_exam_can_req) edcs
             WHERE bs.flg_available = pk_exam_constant.g_available
               AND bs.id_body_structure = bsdcs.id_body_structure
               AND bsdcs.id_institution = i_prof.institution
               AND bsdcs.flg_available = pk_exam_constant.g_available
               AND ebs.id_body_structure = bsdcs.id_body_structure
               AND edcs.id_exam = ebs.id_exam;
    
        CURSOR c_body_structure_dcs IS
            SELECT DISTINCT bs.id_mcs_concept, bs.id_body_structure
              FROM body_structure bs, body_structure_dcs bsdcs
             WHERE bs.flg_available = pk_exam_constant.g_available
               AND bs.id_body_structure = bsdcs.id_body_structure
               AND bsdcs.id_institution = i_prof.institution
               AND bsdcs.flg_available = pk_exam_constant.g_available;
    
        TYPE t_c_exam_body_structure IS TABLE OF c_exam_body_structure%ROWTYPE;
        rec_c_exam_body_structure t_c_exam_body_structure;
    
        TYPE t_c_body_structure_dcs IS TABLE OF c_body_structure_dcs%ROWTYPE;
        rec_c_body_structure_dcs t_c_body_structure_dcs;
    
    BEGIN
    
        -- Populate global variables
        g_error             := 'Populate global variables';
        g_relationship_type := pk_sysconfig.get_config('EXAMS_BODY_STRUCTURE_RELATIONSHIP_TYPE', i_prof);
        g_concept_status    := pk_sysconfig.get_config('EXAMS_BODY_STRUCTURE_CONCEPT_STATUS', i_prof);
        g_mcs_source        := pk_sysconfig.get_config('EXAMS_BODY_STRUCTURE_SOURCE', i_prof);
    
        -- Validate configurations
        g_error              := 'Validate input parameters';
        l_mcs_concept        := nvl(i_mcs_concept,
                                    pk_sysconfig.get_config('EXAMS_BODY_STRUCTURE_INITIAL_CONCEPT_ID', i_prof));
        l_mcs_concept_parent := nvl(i_mcs_concept_parent,
                                    pk_sysconfig.get_config('EXAMS_BODY_STRUCTURE_INITIAL_PARENT_CONCEPT_ID', i_prof));
    
        g_error := 'Validate CONCEPT_ID and PARENT_CONCEPT_ID configurations';
        IF l_mcs_concept IS NULL
           OR l_mcs_concept_parent IS NULL
        THEN
            g_error := 'Inexisting configurations (SYS_CONFIG) for EXAMS_BODY_STRUCTURE_INITIAL_CONCEPT_ID 
                        or EXAMS_BODY_STRUCTURE_INITIAL_PARENT_CONCEPT_ID';
            RAISE g_other_exception;
        END IF;
    
        -- Delete data before recreating the body structure relationship tree for the given institution
        g_error := 'Delete data from table BODY_STRUCTURE_REL';
        DELETE FROM body_structure_rel bsr
         WHERE bsr.id_institution = i_prof.institution;
    
        OPEN c_exam_body_structure;
        FETCH c_exam_body_structure BULK COLLECT
            INTO rec_c_exam_body_structure;
        CLOSE c_exam_body_structure;
    
        rec_exam_body_structure.delete;
    
        FOR i IN 1 .. rec_c_exam_body_structure.count
        LOOP
            rec_exam_body_structure(rec_c_exam_body_structure(i).id_mcs_concept) := rec_c_exam_body_structure(i).id_body_structure;
        END LOOP;
    
        OPEN c_body_structure_dcs;
        FETCH c_body_structure_dcs BULK COLLECT
            INTO rec_c_body_structure_dcs;
        CLOSE c_body_structure_dcs;
    
        rec_body_structure_dcs.delete;
    
        FOR i IN 1 .. rec_c_body_structure_dcs.count
        LOOP
            rec_body_structure_dcs(rec_c_body_structure_dcs(i).id_mcs_concept) := rec_c_body_structure_dcs(i).id_body_structure;
        END LOOP;
    
        -- Recreate body struture relationship tree
        g_error := 'Recreate BODY_STRUCTURE_REL table';
        IF NOT pk_exam_utils.recreate_body_struct_rel(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_mcs_concept        => l_mcs_concept,
                                                      i_mcs_concept_parent => l_mcs_concept_parent,
                                                      o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- Delete records that has as parent the first node, 
        -- and that have at least another parent (count > 1)
        g_error := 'Call DEL_1ST_BODY_STRUCTURE_REL';
        IF NOT pk_exam_utils.del_1st_body_structure_rel(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_mcs_concept_parent => l_mcs_concept_parent,
                                                        o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_BODY_STRUCT_REL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_body_struct_rel;

    FUNCTION recreate_body_struct_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mcs_concept        IN body_structure_rel.id_mcs_concept%TYPE,
        i_mcs_concept_parent IN body_structure_rel.id_mcs_concept_parent%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE childs_rec IS TABLE OF VARCHAR2(200 CHAR) INDEX BY PLS_INTEGER;
        childs_cur childs_rec;
    
        l_mcs_concept               body_structure_rel.id_mcs_concept%TYPE;
        l_mcs_concept_parent        body_structure_rel.id_mcs_concept%TYPE;
        l_body_structure            body_structure.id_body_structure%TYPE;
        l_check_exam_body_structure BOOLEAN;
        l_check_body_structure_dcs  BOOLEAN;
    
    BEGIN
        -- Recursive function
        -- Populate local variables
        g_error                     := 'Populate local variables';
        l_mcs_concept_parent        := i_mcs_concept_parent;
        l_check_exam_body_structure := FALSE;
        l_check_body_structure_dcs  := FALSE;
    
        -- Get childs
        g_error := 'Get childs';
        SELECT mc.id_mcs_concept
          BULK COLLECT
          INTO childs_cur
          FROM mcs_relationship mr
          JOIN mcs_concept mc
            ON mc.id_mcs_concept = mr.id_mcs_concept_1
           AND mc.id_mcs_source = mr.id_mcs_source
         WHERE mr.id_mcs_source = g_mcs_source
           AND mr.relationship_type = g_relationship_type
           AND mc.concept_status = g_concept_status
           AND mr.id_mcs_concept_2 = i_mcs_concept;
    
        -- Check if exams exists for this body structure
        g_error                     := 'Check if exam exists for this body structure, CHECK_EXAM_BODY_STRUCTURE';
        l_check_exam_body_structure := pk_exam_utils.check_exam_body_structure(i_lang           => i_lang,
                                                                               i_prof           => i_prof,
                                                                               i_mcs_concept    => i_mcs_concept,
                                                                               o_body_structure => l_body_structure,
                                                                               o_error          => o_error);
    
        -- Check if this body structure is configured to be shown
        IF NOT l_check_exam_body_structure
        THEN
            g_error                    := 'Check if this body structure is parametrized, CHECK_BODY_STRUCTURE_DCS';
            l_check_body_structure_dcs := pk_exam_utils.check_body_structure_dcs(i_lang           => i_lang,
                                                                                 i_prof           => i_prof,
                                                                                 i_mcs_concept    => i_mcs_concept,
                                                                                 o_body_structure => l_body_structure,
                                                                                 o_error          => o_error);
        END IF;
    
        -- if this body structure is configured to be shown, or has exams related to, 
        -- insert the record for this institution
        IF l_check_exam_body_structure
           OR l_check_body_structure_dcs
        THEN
            g_error              := 'New Parent Concept';
            l_mcs_concept_parent := i_mcs_concept;
        
            g_error := 'Insert new relationship';
            BEGIN
                INSERT INTO body_structure_rel bsr
                    (id_body_structure_rel, id_body_structure, id_mcs_concept, id_mcs_concept_parent, id_institution)
                VALUES
                    (seq_body_structure_rel.nextval,
                     l_body_structure,
                     i_mcs_concept,
                     i_mcs_concept_parent,
                     i_prof.institution);
            EXCEPTION
                WHEN dup_val_on_index THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
    
        g_error := 'Loop for each child found';
        FOR i IN 1 .. childs_cur.count
        LOOP
        
            l_mcs_concept := childs_cur(i);
        
            g_error := 'Call RECREATE_BODY_STRUCT_REL';
            IF NOT recreate_body_struct_rel(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_mcs_concept        => l_mcs_concept,
                                            i_mcs_concept_parent => l_mcs_concept_parent,
                                            o_error              => o_error)
            THEN
                RAISE g_other_exception;
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
                                              'RECREATE_BODY_STRUCT_REL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END recreate_body_struct_rel;

    FUNCTION check_exam_body_structure
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mcs_concept    IN body_structure_rel.id_mcs_concept%TYPE,
        o_body_structure OUT body_structure.id_body_structure%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error          := 'Check if BODY_STRUCTURE is parametrized on EXAM_BODY_STRUCTURE';
        o_body_structure := rec_exam_body_structure(i_mcs_concept);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXAM_BODY_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_exam_body_structure;

    FUNCTION check_body_structure_dcs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mcs_concept    IN body_structure_rel.id_mcs_concept%TYPE,
        o_body_structure OUT body_structure.id_body_structure%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error          := 'Check if BODY_STRUCTURE is parametrized on BODY_STRUCTURE_DCS';
        o_body_structure := rec_body_structure_dcs(i_mcs_concept);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BODY_STRUCTURE_DCS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_body_structure_dcs;

    FUNCTION del_1st_body_structure_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mcs_concept_parent IN body_structure_rel.id_mcs_concept_parent%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- Delete records that has as parent the first node,
        -- and that have at least another parent (count > 1)
        g_error := 'Delete first level body structure';
        DELETE FROM body_structure_rel bsr
         WHERE bsr.id_body_structure_rel IN
               (SELECT bsr4.id_body_structure_rel
                  FROM ( -- For those concepts that has as parent the first node, 
                         -- check if the node has another parent's (count records)
                        SELECT bsr2.id_mcs_concept, COUNT(*) records_count
                          FROM body_structure_rel bsr2
                         WHERE bsr2.id_institution = i_prof.institution
                           AND bsr2.id_mcs_concept IN
                              -- Get concepts that has as parent the first node
                               (SELECT bsr1.id_mcs_concept
                                  FROM body_structure_rel bsr1
                                 WHERE bsr1.id_mcs_concept_parent = i_mcs_concept_parent
                                   AND bsr1.id_institution = i_prof.institution)
                         GROUP BY bsr2.id_mcs_concept) bsr3,
                       body_structure_rel bsr4
                 WHERE bsr3.id_mcs_concept = bsr4.id_mcs_concept
                   AND bsr3.records_count > 1
                   AND bsr4.id_mcs_concept_parent = i_mcs_concept_parent
                   AND bsr4.id_institution = i_prof.institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DEL_1ST_BODY_STRUCTURE_REL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END del_1st_body_structure_rel;

    FUNCTION body_structure_has_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_mcs_concept IN body_structure_rel.id_mcs_concept%TYPE
    ) RETURN VARCHAR IS
    
        l_has_exams NUMBER;
    
    BEGIN
    
        -- Check if I_MCS_CONCEPT or any child node has exams
        g_error := 'Check if I_MCS_CONCEPT or any child node has exams';
        SELECT COUNT(*)
          INTO l_has_exams
          FROM (SELECT /*+no_merge*/
                 ebs.id_exam
                  FROM (SELECT bsr1.id_body_structure_rel
                          FROM body_structure_rel bsr1
                         START WITH bsr1.id_mcs_concept = i_mcs_concept
                                AND bsr1.id_institution = i_prof.institution
                        CONNECT BY PRIOR bsr1.id_mcs_concept = bsr1.id_mcs_concept_parent
                               AND bsr1.id_institution = i_prof.institution) bsr2,
                       body_structure_rel bsr,
                       exam_body_structure ebs,
                       body_structure bs
                 WHERE bsr.id_body_structure_rel = bsr2.id_body_structure_rel
                   AND bs.id_mcs_concept = bsr.id_mcs_concept
                   AND bs.flg_available = pk_exam_constant.g_available
                   AND ebs.id_body_structure = bs.id_body_structure
                   AND ebs.flg_available = pk_exam_constant.g_available) t,
               tbl_temp e
         WHERE e.num_1 = t.id_exam;
    
        -- If exist node's with exams, return Y = TRUE
        IF l_has_exams > 0
        THEN
            RETURN pk_exam_constant.g_yes;
        ELSE
            RETURN pk_exam_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_exam_constant.g_no;
    END body_structure_has_exams;

    FUNCTION get_exam_concat_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN VARCHAR2,
        i_delim        IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_tbl_exam_req_det table_number;
    
        l_ret VARCHAR2(4000 CHAR);
    
    BEGIN
        l_tbl_exam_req_det := pk_utils.str_split_n(i_list => i_exam_req_det, i_delim => i_delim);
    
        FOR i IN l_tbl_exam_req_det.first .. l_tbl_exam_req_det.last
        LOOP
            l_ret := l_ret || pk_exam_external.get_exam_description(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_exam_req_det => l_tbl_exam_req_det(i),
                                                                    i_co_sign_hist => NULL) || CASE
                         WHEN i = l_tbl_exam_req_det.last THEN
                          NULL
                         ELSE
                          ' / '
                     END;
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_concat_desc;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    
        l_tbl_id_exam       table_number;
        l_tbl_id_exam_final table_number;
        l_patient           patient%ROWTYPE;
        l_count             NUMBER;
    BEGIN
    
        l_tbl_id_exam := pk_utils.str_split_n(i_list => i_screen_name, i_delim => '|');
    
        IF i_action = 70
        THEN
            FOR i IN l_tbl_id_exam.first .. l_tbl_id_exam.last
            LOOP
                SELECT ipd.id_exam
                  INTO l_tbl_id_exam(i)
                  FROM exam_req_det ipd
                 WHERE ipd.id_exam_req_det = l_tbl_id_exam(i);
            END LOOP;
        ELSE
            SELECT DISTINCT eq.id_exam
              BULK COLLECT
              INTO l_tbl_id_exam_final
              FROM exam_questionnaire eq
             WHERE eq.id_exam IN (SELECT column_value
                                    FROM TABLE(l_tbl_id_exam))
               AND eq.flg_time = pk_exam_constant.g_exam_cq_on_order
               AND eq.id_institution = i_prof.institution
               AND eq.flg_available = pk_exam_constant.g_available;
            IF l_tbl_id_exam_final.count = 0
            THEN
                o_components := t_clin_quest_table();
                o_ds_target  := t_clin_quest_target_table();
                RETURN TRUE;
            END IF;
        END IF;
    
        SELECT t_clin_quest_row(id_ds_cmpt_mkt_rel        => z.id_ds_cmpt_mkt_rel,
                                id_ds_component_parent    => z.id_ds_component_parent,
                                code_alt_desc             => z.code_alt_desc,
                                desc_component            => z.desc_component,
                                internal_name             => z.internal_name,
                                flg_data_type             => z.flg_data_type,
                                internal_sample_text_type => z.internal_sample_text_type,
                                id_ds_component_child     => z.id_ds_component_child,
                                rank                      => z.rank,
                                max_len                   => z.max_len,
                                min_len                   => z.min_len,
                                min_value                 => z.min_value,
                                max_value                 => z.max_value,
                                position                  => z.position,
                                flg_multichoice           => z.flg_multichoice,
                                comp_size                 => z.comp_size,
                                flg_wrap_text             => z.flg_wrap_text,
                                multichoice_code          => z.multichoice_code,
                                service_params            => z.service_params,
                                flg_event_type            => z.flg_event_type,
                                flg_exp_type              => z.flg_exp_type,
                                input_expression          => z.input_expression,
                                input_mask                => z.input_mask,
                                comp_offset               => z.comp_offset,
                                flg_hidden                => z.flg_hidden,
                                placeholder               => z.placeholder,
                                validation_message        => z.validation_message,
                                flg_clearable             => z.flg_clearable,
                                crate_identifier          => z.crate_identifier,
                                rn                        => z.rn,
                                flg_repeatable            => z.flg_repeatable,
                                flg_data_type2            => z.flg_data_type2,
                                text_line_nr              => NULL)
          BULK COLLECT
          INTO o_components
          FROM (SELECT 0 id_ds_cmpt_mkt_rel,
                       NULL id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_message.get_message(i_lang, 'PROCEDURES_T163') desc_component,
                       i_screen_name internal_name,
                       NULL flg_data_type,
                       NULL internal_sample_text_type,
                       --to_number(i_screen_name) id_ds_component_child,
                       0    id_ds_component_child,
                       1    rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       1    position,
                       NULL flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       NULL multichoice_code,
                       NULL service_params,
                       NULL flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       NULL flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       NULL flg_clearable,
                       NULL crate_identifier,
                       1    rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM dual
                UNION ALL
                SELECT to_number(t.column_value) id_ds_cmpt_mkt_rel,
                       0 id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_translation.get_translation(i_lang, 'EXAM.CODE_EXAM.' || to_number(t.column_value)) desc_component,
                       pk_translation.get_translation(i_lang, 'EXAM.CODE_EXAM.' || to_number(t.column_value)) internal_name,
                       NULL flg_data_type,
                       NULL internal_sample_text_type,
                       to_number(t.column_value) id_ds_component_child,
                       rownum rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum position,
                       NULL flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       NULL multichoice_code,
                       NULL service_params,
                       NULL flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       NULL flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       NULL flg_clearable,
                       NULL crate_identifier,
                       rownum rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM TABLE(l_tbl_id_exam_final) t
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_exam) id_ds_cmpt_mkt_rel,
                       q.id_exam id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_mcdt.get_questionnaire_alias(i_lang,
                                                       i_prof,
                                                       'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || q.id_questionnaire) desc_component,
                       to_char('E' || '|' || q.id_exam || '_' || q.id_questionnaire) internal_name,
                       decode(q.flg_type, 'D', 'DT', 'ME', 'MS', 'MI', 'MM', 'N', 'K', NULL) flg_data_type,
                       NULL internal_sample_text_type,
                       q.id_questionnaire id_ds_component_child,
                       q.id_questionnaire rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum + 1000 position,
                       decode(q.flg_type, 'ME', 'SRV', 'MI', 'SRV', NULL) flg_multichoice,
                       NULL comp_size,
                       NULL flg_wrap_text,
                       decode(q.flg_type, 'ME', 'GET_MULTICHOICE_CQ', 'MI', 'GET_MULTICHOICE_CQ', NULL) multichoice_code,
                       (q.id_questionnaire * 10 + q.id_exam) service_params,
                       decode(q.id_questionnaire_parent, NULL, decode(q.flg_mandatory, 'Y', 'M', NULL), 'I') flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       pk_alert_constant.g_no flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       pk_alert_constant.g_yes flg_clearable,
                       NULL crate_identifier,
                       rownum + 100 rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM (SELECT DISTINCT iq.id_exam,
                                        iq.id_questionnaire,
                                        qr.id_questionnaire_parent,
                                        qr.id_response_parent,
                                        iq.flg_type,
                                        iq.flg_mandatory,
                                        iq.flg_copy,
                                        iq.id_unit_measure
                          FROM exam_questionnaire iq,
                               questionnaire_response qr,
                               (SELECT column_value AS id_exam
                                  FROM TABLE(l_tbl_id_exam_final)) p
                         WHERE iq.id_exam = p.id_exam
                           AND iq.flg_time = 'O'
                           AND iq.id_institution = i_prof.institution
                           AND iq.flg_available = pk_exam_constant.g_available
                           AND iq.id_questionnaire = qr.id_questionnaire
                           AND iq.id_response = qr.id_response
                           AND qr.flg_available = pk_exam_constant.g_available
                           AND EXISTS
                         (SELECT 1
                                  FROM questionnaire q
                                 WHERE q.id_questionnaire = iq.id_questionnaire
                                   AND q.flg_available = pk_exam_constant.g_available
                                   AND (((l_patient.gender IS NOT NULL AND
                                       coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                       ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                       l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                       (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                       nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_exam) + 1 id_ds_cmpt_mkt_rel,
                       q.id_exam id_ds_component_parent,
                       NULL code_alt_desc,
                       'Apply to All' desc_component,
                       to_char('E' || '|' || q.id_exam || '_' || q.id_questionnaire) internal_name,
                       'TS' flg_data_type,
                       NULL internal_sample_text_type,
                       q.id_questionnaire id_ds_component_child,
                       q.id_questionnaire rank,
                       NULL max_len,
                       NULL min_len,
                       NULL min_value,
                       NULL max_value,
                       rownum + 1000 + 1 position,
                       decode(q.flg_type, 'ME', 'SRV', 'MI', 'SRV', NULL) flg_multichoice,
                       2 comp_size,
                       NULL flg_wrap_text,
                       decode(q.flg_type, 'ME', 'GET_MULTICHOICE_CQ', 'MI', 'GET_MULTICHOICE_CQ', NULL) multichoice_code,
                       (q.id_questionnaire * 10 + q.id_exam) service_params,
                       decode(q.id_questionnaire_parent, NULL, decode(q.flg_mandatory, 'Y', 'M', NULL), 'I') flg_event_type,
                       NULL flg_exp_type,
                       NULL input_expression,
                       NULL input_mask,
                       NULL comp_offset,
                       pk_alert_constant.g_no flg_hidden,
                       NULL placeholder,
                       NULL validation_message,
                       pk_alert_constant.g_yes flg_clearable,
                       NULL crate_identifier,
                       rownum + 100 + 1 rn,
                       NULL flg_repeatable,
                       NULL flg_data_type2
                  FROM (SELECT DISTINCT iq.id_exam,
                                        iq.id_questionnaire,
                                        qr.id_questionnaire_parent,
                                        qr.id_response_parent,
                                        iq.flg_type,
                                        iq.flg_mandatory,
                                        iq.flg_copy,
                                        iq.id_unit_measure
                          FROM exam_questionnaire iq,
                               questionnaire_response qr,
                               (SELECT column_value AS id_exam
                                  FROM TABLE(l_tbl_id_exam_final)) p
                         WHERE iq.id_exam = p.id_exam
                           AND iq.flg_time = 'O'
                           AND iq.id_institution = i_prof.institution
                           AND iq.flg_available = pk_exam_constant.g_available
                           AND iq.id_questionnaire = qr.id_questionnaire
                           AND iq.id_response = qr.id_response
                           AND iq.flg_copy = 'Y'
                           AND qr.flg_available = pk_exam_constant.g_available
                           AND EXISTS
                         (SELECT 1
                                  FROM questionnaire q
                                 WHERE q.id_questionnaire = iq.id_questionnaire
                                   AND q.flg_available = pk_exam_constant.g_available
                                   AND (((l_patient.gender IS NOT NULL AND
                                       coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                       ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                       l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                       (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                       nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q
                 ORDER BY rank) z;
    
        SELECT t_clin_quest_target_row(id_cmpt_mkt_origin    => z.id_cmpt_mkt_origin,
                                       id_cmpt_origin        => z.id_cmpt_origin,
                                       id_ds_event           => z.id_ds_event,
                                       flg_type              => z.flg_type,
                                       VALUE                 => z.value,
                                       id_cmpt_mkt_dest      => z.id_cmpt_mkt_dest,
                                       id_cmpt_dest          => z.id_cmpt_dest,
                                       field_mask            => z.field_mask,
                                       flg_event_target_type => z.flg_event_target_type,
                                       validation_message    => z.validation_message,
                                       rn                    => z.rn)
          BULK COLLECT
          INTO o_ds_target
          FROM (
                
                SELECT (q.id_questionnaire * 10 + q.id_exam) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        '@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_exam id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'A' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_exam,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM exam_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_exam IN (SELECT *
                                                 FROM TABLE(l_tbl_id_exam_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_exam_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_exam_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_exam_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_exam
                           FROM exam_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_exam IN (SELECT *
                                                 FROM TABLE(l_tbl_id_exam_final))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_exam = q.id_exam
                   AND q.flg_type IN ('ME', 'MI')
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_exam) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        '@1 != ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_exam id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'I' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_exam,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM exam_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_exam IN (SELECT *
                                                 FROM TABLE(l_tbl_id_exam_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_exam_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_exam_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_exam_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_exam
                           FROM exam_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_exam IN (SELECT *
                                                 FROM TABLE(l_tbl_id_exam_final))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_exam = q.id_exam
                   AND q.flg_type IN ('ME', 'MI')
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_exam) + 1 id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'S' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        'A' VALUE,
                        NULL id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'A' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_exam,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM exam_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_exam IN (SELECT *
                                                 FROM TABLE(l_tbl_id_exam_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_exam_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND iq.flg_copy = pk_alert_constant.g_yes
                            AND qr.flg_available = pk_exam_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_exam_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q
                 WHERE q.id_response_parent IS NULL) z;
        --pk_types.open_cursor_if_closed(o_ds_target);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FULL_ITEMS_BY_SCREEN',
                                              o_error);
            RETURN FALSE;
    END get_full_items_by_screen;

    FUNCTION get_response_parent
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_exam          exam.id_exam%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER AS
        l_ret NUMBER(24);
    BEGIN
    
        SELECT DISTINCT qr.id_response_parent
          INTO l_ret
          FROM exam_questionnaire eq
         INNER JOIN questionnaire_response qr
            ON eq.id_questionnaire = qr.id_questionnaire
         WHERE eq.id_exam = i_exam
           AND qr.id_questionnaire_parent = i_questionnaire
           AND eq.id_institution = i_prof.institution;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_response_parent;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_exam_utils;
/
