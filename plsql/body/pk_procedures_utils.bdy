/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_procedures_utils IS

    FUNCTION create_procedure_movement
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE request_movement IS RECORD(
            id_room room.id_room%TYPE,
            id_mov  interv_presc_det.id_movement%TYPE);
    
        TYPE rm IS TABLE OF request_movement INDEX BY BINARY_INTEGER;
        req_mov rm;
        k       NUMBER := 0;
    
        l_intervention intervention.id_intervention%TYPE;
        l_flg_time     interv_prescription.flg_time%TYPE;
        l_flg_status   interv_presc_det.flg_status%TYPE;
        l_dt_begin     interv_presc_det.dt_begin_tstz%TYPE;
    
        l_id_mov      movement.id_movement%TYPE;
        l_req_mov     BOOLEAN;
        l_id_room     epis_info.id_room%TYPE;
        l_new_room    room.id_room%TYPE;
        l_flg_mov_pat intervention.flg_mov_pat%TYPE;
        l_flg_show    VARCHAR2(1 CHAR);
        l_msg_text    VARCHAR2(1000 CHAR);
        l_msg_title   VARCHAR2(1000 CHAR);
        l_button      VARCHAR2(6 CHAR);
    
    BEGIN
        SELECT ipd.id_intervention, ip.flg_time, ipd.flg_status, ipd.dt_begin_tstz
          INTO l_intervention, l_flg_time, l_flg_status, l_dt_begin
          FROM interv_presc_det ipd
          JOIN interv_prescription ip
            ON ip.id_interv_prescription = ipd.id_interv_prescription
         WHERE ipd.id_interv_presc_det = i_interv_presc_det;
    
        IF l_flg_time = pk_procedures_constant.g_flg_time_e
           AND l_flg_status = pk_procedures_constant.g_interv_req
        THEN
            BEGIN
                SELECT nvl(i.flg_mov_pat, pk_procedures_constant.g_yes)
                  INTO l_flg_mov_pat
                  FROM intervention i
                 WHERE i.id_intervention = l_intervention;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_mov_pat := pk_procedures_constant.g_no;
            END;
        
            IF l_flg_mov_pat = pk_procedures_constant.g_yes
            THEN
                BEGIN
                    SELECT ir.id_room
                      INTO l_new_room
                      FROM interv_room ir
                     WHERE ir.id_intervention = l_intervention;
                
                    IF l_id_room != l_new_room
                    THEN
                        -- localização actual do doente ñ é a sala de realização do procedimento
                        -- Verificar se já foi requisitado mov para essa sala, nesta mesma requisição
                        -- (se um detalhe já registado tem é realizado na mm sala)
                        l_req_mov := TRUE;
                        l_id_mov  := NULL;
                        IF k != 0
                        THEN
                            FOR j IN 1 .. k
                            LOOP
                                IF req_mov(j).id_room = l_new_room
                                THEN
                                    l_req_mov := FALSE;
                                    l_id_mov  := req_mov(j).id_mov;
                                    EXIT;
                                END IF;
                            END LOOP;
                        END IF;
                    
                        IF l_req_mov
                        THEN
                            g_error := 'CALL TO PK_MOVEMENT.CREATE_MOVEMENT';
                            IF NOT
                                pk_movement.create_movement(i_lang          => i_lang,
                                                            i_episode       => i_episode,
                                                            i_prof          => i_prof,
                                                            i_room          => l_new_room,
                                                            i_necessity     => NULL,
                                                            i_dt_req_str    => pk_date_utils.date_send_tsz(i_lang,
                                                                                                           l_dt_begin,
                                                                                                           i_prof),
                                                            i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                                            o_id_mov        => l_id_mov,
                                                            o_flg_show      => l_flg_show,
                                                            o_msg           => l_msg_text,
                                                            o_msg_title     => l_msg_title,
                                                            o_button        => l_button,
                                                            o_error         => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            g_error := 'CALL TO PK_MOVEMENT.INSERT_MOVEMENT_TASK';
                            IF NOT pk_movement.insert_movement_task(i_lang          => i_lang,
                                                                    i_episode       => i_episode,
                                                                    i_prof          => i_prof,
                                                                    i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                  i_prof),
                                                                    o_error         => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            g_error := 'SET MOV VECTOR';
                            k := k + 1;
                            req_mov(k).id_room := l_new_room;
                            req_mov(k).id_mov := l_id_mov;
                        END IF;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        RAISE g_user_exception;
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROCEDURE_MOVEMENT',
                                              o_error);
            RETURN FALSE;
    END create_procedure_movement;

    FUNCTION get_procedure_request
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_intervention IN table_number,
        o_msg_title    OUT VARCHAR2,
        o_msg_req      OUT VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_days_limit sys_config.value%TYPE;
        l_string_req VARCHAR2(2000);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_msg_title := pk_message.get_message(i_lang, 'INTERV_M007');
    
        l_days_limit := pk_sysconfig.get_config('PROCEDURES_LAST_ORDER', i_prof);
    
        SELECT REPLACE(substr(concatenate(pea.desc_procedure || ' - ' ||
                                          pk_date_utils.dt_chr_tsz(i_lang, pea.dt_interv_prescription, i_prof) || ' (' ||
                                          pk_date_utils.get_elapsed_sysdate_tsz(i_lang, pea.dt_interv_prescription) ||
                                          '); '),
                              1,
                              length(concatenate(pea.desc_procedure || ' - ' ||
                                                 pk_date_utils.dt_chr_tsz(i_lang, pea.dt_interv_prescription, i_prof) || ' (' ||
                                                 pk_date_utils.get_elapsed_sysdate_tsz(i_lang,
                                                                                       pea.dt_interv_prescription) ||
                                                 '); ')) - 2),
                       '); ',
                       '); ' || chr(10))
          INTO l_string_req
          FROM (SELECT pea.dt_interv_prescription,
                       pk_procedures_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'INTERVENTION.CODE_INTERVENTION.' ||
                                                                  pea.id_intervention,
                                                                  NULL) desc_procedure,
                       row_number() over(PARTITION BY pea.id_intervention ORDER BY pea.dt_interv_prescription DESC) rn
                  FROM procedures_ea pea
                 WHERE pea.id_patient = i_patient
                   AND pea.id_intervention IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                *
                                                 FROM TABLE(i_intervention) t)
                   AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_cancel,
                                                  pk_procedures_constant.g_interv_draft,
                                                  pk_procedures_constant.g_interv_expired,
                                                  pk_procedures_constant.g_interv_not_ordered)
                   AND (pea.dt_interv_prescription BETWEEN g_sysdate_tstz - numtodsinterval(l_days_limit, 'DAY') AND
                       g_sysdate_tstz)
                 ORDER BY 1 DESC) pea
         WHERE pea.rn = 1;
    
        IF l_string_req IS NOT NULL
        THEN
            o_msg_title := pk_message.get_message(i_lang, 'INTERV_M007');
        
            o_msg_req := REPLACE(pk_message.get_message(i_lang, 'INTERV_M008'), '@1', l_string_req);
        
            RETURN pk_procedures_constant.g_yes;
        ELSE
        
            RETURN pk_procedures_constant.g_no;
        END IF;
    
    END get_procedure_request;

    FUNCTION get_procedure_id_content
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_content analysis_sample_type.id_content%TYPE;
    
    BEGIN
    
        SELECT i.id_content
          INTO l_id_content
          FROM intervention i
         WHERE i.id_intervention = i_interv;
    
        RETURN l_id_content;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_id_content;

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_interv_alias exam_alias.code_exam_alias%TYPE;
        l_desc_mess    pk_translation.t_desc_translation;
    
    BEGIN
    
        l_interv_alias := get_alias_code_translation(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_code_interv   => i_code_interv,
                                                     i_dep_clin_serv => i_dep_clin_serv);
    
        g_error := 'GET TRANSLATION';
        IF l_interv_alias IS NOT NULL
        THEN
            l_desc_mess := pk_translation.get_translation(i_lang, l_interv_alias);
        END IF;
    
        g_error := 'TEST OUTPUT MESSAGE';
        IF l_desc_mess IS NULL
        THEN
            l_desc_mess := pk_translation.get_translation(i_lang, i_code_interv);
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
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN intervention_alias.code_intervention_alias%TYPE IS
    
        c_interv_alias pk_types.cursor_type;
        l_interv_alias intervention_alias.code_intervention_alias%TYPE;
    
    BEGIN
    
        g_error := 'FETCH CURSOR';
        OPEN c_interv_alias FOR
            SELECT (SELECT code_intervention_alias
                      FROM (SELECT code_intervention_alias,
                                   row_number() over(PARTITION BY ia.id_intervention ORDER BY ia.id_institution DESC, ia.id_software DESC) rn
                              FROM intervention_alias ia
                              JOIN intervention i
                                ON ia.id_intervention = i.id_intervention
                              JOIN prof_cat pc
                                ON pc.id_category = ia.id_category
                               AND pc.id_professional = i_prof.id
                               AND pc.id_institution = i_prof.institution
                             WHERE decode(ia.id_institution, 0, nvl(i_prof.institution, 0), ia.id_institution) =
                                   nvl(i_prof.institution, 0)
                               AND decode(ia.id_software, 0, nvl(i_prof.software, 0), ia.id_software) =
                                   nvl(i_prof.software, 0)
                               AND decode(nvl(ia.id_professional, 0), 0, nvl(i_prof.id, 0), ia.id_professional) =
                                   nvl(i_prof.id, 0)
                               AND decode(nvl(ia.id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), ia.id_dep_clin_serv) =
                                   nvl(i_dep_clin_serv, 0)
                               AND i.code_intervention = i_code_interv)
                     WHERE rn = 1)
              FROM dual;
    
        FETCH c_interv_alias
            INTO l_interv_alias;
        CLOSE c_interv_alias;
    
        RETURN l_interv_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation;

    FUNCTION get_procedure_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_type      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER IS
    
        l_interv_rank        NUMBER;
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
               AND pdcs.flg_status = pk_procedures_constant.g_selected
               AND pdcs.flg_default = pk_procedures_constant.g_yes;
        
            IF l_prof_dep_clin_serv.count > 0
            THEN
                g_error := 'GET EXAM RANK 1';
                SELECT idcs.rank
                  INTO l_interv_rank
                  FROM interv_dep_clin_serv idcs
                 WHERE idcs.id_intervention = i_intervention
                   AND idcs.id_dep_clin_serv = i_dep_clin_serv
                   AND idcs.flg_type = nvl(i_flg_type, pk_procedures_constant.g_interv_freq)
                   AND idcs.id_software = i_prof.software;
            ELSE
                g_error := 'GET EXAM RANK 2';
                SELECT coalesce((SELECT MAX(idcs.rank)
                                  FROM interv_dep_clin_serv idcs
                                 WHERE idcs.id_intervention = i_intervention
                                   AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                                   AND idcs.id_software = i_prof.software
                                   AND idcs.id_institution = i_prof.institution),
                                (SELECT MAX(idcs.rank)
                                   FROM interv_dep_clin_serv idcs
                                  WHERE idcs.id_intervention = i_intervention
                                    AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                                    AND idcs.id_institution = i_prof.institution),
                                (SELECT i.rank
                                   FROM intervention i
                                  WHERE i.id_intervention = i_intervention))
                  INTO l_interv_rank
                  FROM dual;
            END IF;
        ELSE
            g_error := 'GET EXAM RANK 3';
            SELECT coalesce((SELECT MAX(idcs.rank)
                              FROM interv_dep_clin_serv idcs
                             WHERE idcs.id_intervention = i_intervention
                               AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                               AND idcs.id_software = i_prof.software
                               AND idcs.id_institution = i_prof.institution),
                            (SELECT MAX(idcs.rank)
                               FROM interv_dep_clin_serv idcs
                              WHERE idcs.id_intervention = i_intervention
                                AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                                AND idcs.id_institution = i_prof.institution),
                            (SELECT i.rank
                               FROM intervention i
                              WHERE i.id_intervention = i_intervention))
              INTO l_interv_rank
              FROM dual;
        END IF;
    
        RETURN l_interv_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_procedure_rank;

    FUNCTION get_procedure_question_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT INTERV_QUESTIONNAIRE';
        SELECT MAX(iq.rank)
          INTO l_rank
          FROM interv_questionnaire iq
         WHERE iq.id_intervention = i_intervention
           AND iq.id_questionnaire = i_questionnaire
           AND iq.flg_time = i_flg_time
           AND iq.id_institution = i_prof.institution
           AND iq.flg_available = pk_procedures_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_question_rank;

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
               AND qr.flg_available = pk_procedures_constant.g_yes;
        ELSE
            g_error := 'SELECT QUESTIONNAIRE';
            SELECT id_content
              INTO l_content
              FROM questionnaire q
             WHERE q.id_questionnaire = i_questionnaire
               AND q.flg_available = pk_procedures_constant.g_yes;
        END IF;
    
        RETURN l_content;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_questionnaire_id_content;

    PROCEDURE get_procedure_init_parameters
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
    
        l_procedure_type intervention.flg_type%TYPE := 'P';
        l_flg_type       interv_dep_clin_serv.flg_type%TYPE;
        l_flg_filter     VARCHAR2(10 CHAR);
        l_codification   codification.id_codification%TYPE;
        l_permission     VARCHAR2(1 CHAR);
        l_pat_gender     VARCHAR2(5 CHAR);
        l_pat_age        NUMBER;
    
        l_id_dept dept.id_dept%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
        IF l_episode IS NOT NULL
        THEN
        
            l_id_dept := pk_complaint.get_id_department(l_lang, l_prof, l_episode) (1);
        END IF;
    
        SELECT pk_procedures_utils.get_procedure_permission(l_lang,
                                                            l_prof,
                                                            'PROCEDURES',
                                                            'CREATE',
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL)
          INTO l_permission
          FROM dual;
    
        IF l_patient IS NOT NULL
        THEN
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              INTO l_pat_gender, l_pat_age
              FROM patient
             WHERE id_patient = l_patient;
        END IF;
    
        CASE i_custom_filter
            WHEN 0 THEN
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_can_req;
            WHEN 1 THEN
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_clinical_service;
            WHEN 2 THEN
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_complaint;
            WHEN 3 THEN
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_codification;
            
                IF i_context_vals IS NOT NULL
                   AND i_context_vals.count > 0
                THEN
                    BEGIN
                        l_codification := i_context_vals(3);
                    EXCEPTION
                        WHEN OTHERS THEN
                            BEGIN
                                l_codification := i_context_vals(2);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_codification := NULL;
                            END;
                    END;
                END IF;
            WHEN 4 THEN
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_nursing;
            WHEN 5 THEN
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_medical;
            ELSE
                l_flg_type   := pk_procedures_constant.g_interv_can_req;
                l_flg_filter := pk_procedures_constant.g_interv_can_req;
        END CASE;
    
        pk_context_api.set_parameter('i_department', l_id_dept);
        pk_context_api.set_parameter('i_procedure_type', l_procedure_type);
        pk_context_api.set_parameter('i_flg_type', l_flg_type);
        pk_context_api.set_parameter('i_flg_filter', l_flg_filter);
        pk_context_api.set_parameter('i_dep_clin_serv', NULL);
    
        pk_context_api.set_parameter('i_codification',
                                     CASE WHEN i_filter_name = 'ProceduresSearch' THEN i_context_vals(2) ELSE
                                     l_codification END);
        pk_context_api.set_parameter('i_value',
                                     CASE WHEN i_filter_name = 'ProceduresSearch' THEN i_context_vals(1) ELSE NULL END);
    
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
            WHEN 'g_type_interv' THEN
                o_vc2 := pk_procedures_constant.g_type_interv;
            WHEN 'g_interv_area_procedures' THEN
                o_vc2 := pk_procedures_constant.g_interv_area_procedures;
            WHEN 'g_procedure_button_ok' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_ok;
            WHEN 'g_procedure_button_cancel' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_cancel;
            WHEN 'g_procedure_button_action' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_action;
            WHEN 'g_procedure_button_edit' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_edit;
            WHEN 'g_procedure_button_confirm' THEN
                o_vc2 := pk_procedures_constant.g_interv_button_confirmation;
            WHEN 'g_interv_pending' THEN
                o_vc2 := pk_procedures_constant.g_interv_pending;
            WHEN 'g_interv_req' THEN
                o_vc2 := pk_procedures_constant.g_interv_req;
            WHEN 'g_interv_type_req' THEN
                o_vc2 := pk_procedures_constant.g_interv_type_req;
            WHEN 'g_yes' THEN
                o_vc2 := pk_procedures_constant.g_yes;
            WHEN 'g_no' THEN
                o_vc2 := pk_procedures_constant.g_no;
            WHEN 'l_msg_procedure_with_med' THEN
                o_vc2 := pk_message.get_message(l_lang, 'INTERV_M012');
            WHEN 'l_msg_not_aplicable' THEN
                o_vc2 := pk_message.get_message(l_lang, 'COMMON_M036');
            WHEN 'l_msg_notes' THEN
                o_vc2 := pk_message.get_message(l_lang, 'COMMON_M097');
            WHEN 'l_visit' THEN
                o_id := CASE
                            WHEN l_episode IS NOT NULL THEN
                             pk_visit.get_visit(l_episode, l_error)
                            ELSE
                             NULL
                        END;
            WHEN 'l_epis_type' THEN
                IF l_episode IS NOT NULL
                THEN
                    SELECT id_epis_type
                      INTO o_id
                      FROM episode
                     WHERE id_episode = l_episode;
                END IF;
            WHEN 'l_msg' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, 'PROCEDURES_T066');
            WHEN 'l_rank' THEN
                o_num := 1;
            WHEN 'l_codification' THEN
                o_vc2 := l_codification;
            WHEN 'l_permission' THEN
                o_vc2 := l_permission;
            WHEN 'l_patient' THEN
                o_vc2 := l_patient;
            WHEN 'l_pat_gender' THEN
                o_vc2 := l_pat_gender;
            WHEN 'l_pat_age' THEN
                o_vc2 := l_pat_age;
            WHEN 'l_from_filter' THEN
                o_vc2 := 'N';
            WHEN 'l_interv_translation' THEN
                o_vc2 := 'INTERVENTION.CODE_INTERVENTION OR INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS';
            ELSE
                NULL;
        END CASE;
    
    END get_procedure_init_parameters;

    FUNCTION get_procedure_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN VARCHAR2,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_interv_presc_det    IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan   IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_interv_presc IS
            SELECT pea.id_episode,
                   ipd.id_presc_plan_task,
                   pea.id_professional,
                   pea.id_prof_order,
                   pea.flg_time,
                   pea.flg_status_det flg_status,
                   pea.flg_referral,
                   pea.flg_prn,
                   ipd.id_exec_institution,
                   ipd.dt_cancel_tstz
              FROM procedures_ea pea, interv_presc_det ipd
             WHERE pea.id_interv_presc_det = i_interv_presc_det
               AND pea.id_interv_presc_det = ipd.id_interv_presc_det;
    
        CURSOR c_interv_plan IS
            SELECT ipp.flg_status
              FROM interv_presc_plan ipp
             WHERE ipp.id_interv_presc_plan = i_interv_presc_plan;
    
        l_permission VARCHAR2(1 CHAR);
    
        l_interv_presc c_interv_presc%ROWTYPE;
        l_interv_plan  c_interv_plan%ROWTYPE;
    
        l_count NUMBER;
    
        --l_episode_type episode.id_epis_type%TYPE;
    
        l_cpoe_new_execution sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_EXTRA_TAKE', i_prof);
    
        l_ref          sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
        l_ref_shortcut sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_MCDT_SHORTCUT', i_prof);
    
        l_prof_cat_type category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
        l_view_only_profile VARCHAR2(1 CHAR) := pk_prof_utils.check_has_functionality(i_lang,
                                                                                      i_prof,
                                                                                      'READ ONLY PROFILE');
    
    BEGIN
    
        g_error := 'OPEN C_INTERV_PRESC';
        OPEN c_interv_presc;
        FETCH c_interv_presc
            INTO l_interv_presc;
        CLOSE c_interv_presc;
    
        g_error := 'OPEN C_INTERV_PLAN';
        OPEN c_interv_plan;
        FETCH c_interv_plan
            INTO l_interv_plan;
        CLOSE c_interv_plan;
    
        SELECT COUNT(*)
          INTO l_count
          FROM interv_presc_plan ipp
         WHERE ipp.id_interv_presc_det = i_interv_presc_det
           AND ipp.flg_status = pk_procedures_constant.g_interv_plan_executed
           AND ipp.dt_take_tstz >= l_interv_presc.dt_cancel_tstz;
    
        IF i_area = pk_procedures_constant.g_interv_area_procedures
        THEN
            IF i_button = pk_procedures_constant.g_interv_button_create
            THEN
                IF i_prof.software IN (pk_alert_constant.g_soft_rehab, pk_alert_constant.g_soft_resptherap)
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF l_prof_cat_type = pk_alert_constant.g_cat_type_nurse
                    THEN
                        l_permission := pk_procedures_constant.g_no;
                    ELSE
                        IF l_ref = pk_procedures_constant.g_no
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSE
                            l_permission := pk_procedures_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_procedures_constant.g_interv_button_ok
            THEN
                IF l_view_only_profile = pk_procedures_constant.g_yes
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF i_prof.software IN (pk_alert_constant.g_soft_nutritionist, pk_alert_constant.g_soft_rehab)
                    THEN
                        l_permission := pk_procedures_constant.g_no;
                    ELSIF l_prof_cat_type = pk_alert_constant.g_cat_type_social
                    THEN
                        l_permission := pk_procedures_constant.g_no;
                    ELSE
                        IF l_interv_presc.flg_referral IN
                           (pk_procedures_constant.g_flg_referral_r,
                            pk_procedures_constant.g_flg_referral_s,
                            pk_procedures_constant.g_flg_referral_i)
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSE
                            IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_exterior
                            THEN
                                IF l_ref_shortcut = pk_procedures_constant.g_no
                                THEN
                                    l_permission := pk_procedures_constant.g_no;
                                ELSE
                                    IF l_ref = pk_procedures_constant.g_no
                                    THEN
                                        l_permission := pk_procedures_constant.g_no;
                                    ELSE
                                        IF i_prof.software IN
                                           (pk_alert_constant.g_soft_rehab, pk_alert_constant.g_soft_resptherap)
                                        THEN
                                            l_permission := pk_procedures_constant.g_no;
                                        ELSE
                                            IF l_prof_cat_type = pk_alert_constant.g_cat_type_nurse
                                            THEN
                                                l_permission := pk_procedures_constant.g_no;
                                            ELSE
                                                l_permission := pk_procedures_constant.g_yes;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            ELSE
                                IF l_interv_presc.id_episode IS NULL
                                   AND l_interv_presc.flg_time = pk_procedures_constant.g_flg_time_n
                                THEN
                                    l_permission := pk_procedures_constant.g_no;
                                ELSE
                                    IF l_interv_presc.flg_prn = pk_procedures_constant.g_yes
                                    THEN
                                        IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_interrupted
                                        THEN
                                            l_permission := pk_procedures_constant.g_no;
                                        ELSIF l_interv_presc.flg_status = pk_procedures_constant.g_interv_expired
                                        THEN
                                            IF l_cpoe_new_execution = pk_procedures_constant.g_yes
                                               AND l_interv_presc.id_exec_institution = i_prof.institution
                                               AND l_count = 0
                                            THEN
                                                l_permission := pk_procedures_constant.g_yes;
                                            ELSE
                                                l_permission := pk_procedures_constant.g_no;
                                            END IF;
                                        ELSE
                                            l_permission := pk_procedures_constant.g_yes;
                                        END IF;
                                    ELSE
                                        IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_finished
                                        THEN
                                            IF l_interv_presc.id_presc_plan_task IS NULL
                                            THEN
                                                l_permission := pk_procedures_constant.g_yes;
                                            ELSE
                                                l_permission := pk_procedures_constant.g_no;
                                            END IF;
                                        ELSIF l_interv_presc.flg_status IN
                                              (pk_procedures_constant.g_interv_pending,
                                               pk_procedures_constant.g_interv_exec,
                                               pk_procedures_constant.g_interv_req)
                                        THEN
                                            l_permission := pk_procedures_constant.g_yes;
                                        ELSIF l_interv_presc.flg_status = pk_procedures_constant.g_interv_expired
                                        THEN
                                            IF l_cpoe_new_execution = pk_procedures_constant.g_yes
                                               AND l_interv_presc.id_exec_institution = i_prof.institution
                                               AND l_count = 0
                                            THEN
                                                l_permission := pk_procedures_constant.g_yes;
                                            ELSE
                                                l_permission := pk_procedures_constant.g_no;
                                            END IF;
                                        ELSE
                                            l_permission := pk_procedures_constant.g_no;
                                        END IF;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_procedures_constant.g_interv_button_cancel
            THEN
                IF i_prof.software IN (pk_alert_constant.g_soft_nutritionist, pk_alert_constant.g_soft_rehab)
                THEN
                    IF pk_prof_utils.get_category(i_lang,
                                                  profissional(l_interv_presc.id_professional,
                                                               i_prof.institution,
                                                               i_prof.software)) = l_prof_cat_type
                    THEN
                        l_permission := pk_procedures_constant.g_yes;
                    ELSE
                        l_permission := pk_procedures_constant.g_no;
                    END IF;
                ELSE
                    IF l_interv_presc.flg_referral IN
                       (pk_procedures_constant.g_flg_referral_r,
                        pk_procedures_constant.g_flg_referral_s,
                        pk_procedures_constant.g_flg_referral_i)
                    THEN
                        l_permission := pk_procedures_constant.g_no;
                    ELSE
                        IF l_interv_presc.flg_status IN
                           (pk_procedures_constant.g_interv_cancel,
                            pk_procedures_constant.g_interv_expired,
                            pk_procedures_constant.g_interv_interrupted)
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSIF l_interv_presc.flg_status = pk_procedures_constant.g_interv_finished
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSE
                            l_permission := pk_procedures_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_procedures_constant.g_interv_button_action
            THEN
                l_permission := pk_procedures_constant.g_yes;
            ELSIF i_button = pk_procedures_constant.g_interv_button_edit
            THEN
                IF l_interv_presc.flg_referral IN
                   (pk_procedures_constant.g_flg_referral_r,
                    pk_procedures_constant.g_flg_referral_s,
                    pk_procedures_constant.g_flg_referral_i)
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF l_interv_presc.flg_status IN
                       (pk_procedures_constant.g_interv_cancel,
                        pk_procedures_constant.g_interv_expired,
                        pk_procedures_constant.g_interv_interrupted)
                    THEN
                        l_permission := pk_procedures_constant.g_no;
                    ELSIF l_interv_presc.flg_status IN
                          (pk_procedures_constant.g_interv_exec, pk_procedures_constant.g_interv_finished)
                    THEN
                        l_permission := pk_procedures_constant.g_no;
                    ELSE
                        l_permission := pk_procedures_constant.g_yes;
                    END IF;
                END IF;
            ELSIF i_button = pk_procedures_constant.g_interv_button_confirmation
            THEN
                IF l_view_only_profile = pk_procedures_constant.g_yes
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_exterior
                       AND l_ref = pk_procedures_constant.g_yes
                    THEN
                        l_permission := pk_exam_constant.g_yes;
                    ELSE
                        l_permission := pk_exam_constant.g_no;
                    END IF;
                END IF;
            END IF;
        ELSIF i_area = pk_procedures_constant.g_interv_area_execution
        THEN
            IF i_button = pk_procedures_constant.g_interv_button_create
            THEN
                IF l_interv_presc.id_episode IS NULL
                   AND l_interv_presc.flg_time = pk_procedures_constant.g_flg_time_n
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF l_interv_presc.flg_prn = pk_procedures_constant.g_yes
                    THEN
                        IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_interrupted
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSE
                            IF l_interv_plan.flg_status = pk_procedures_constant.g_interv_plan_cancel
                            THEN
                                l_permission := pk_procedures_constant.g_yes;
                            ELSIF l_interv_plan.flg_status = pk_procedures_constant.g_interv_plan_expired
                            THEN
                                IF l_cpoe_new_execution = pk_procedures_constant.g_yes
                                   AND l_interv_presc.id_exec_institution = i_prof.institution
                                   AND l_count = 0
                                THEN
                                    l_permission := pk_procedures_constant.g_yes;
                                ELSE
                                    l_permission := pk_procedures_constant.g_no;
                                END IF;
                            ELSE
                                l_permission := pk_procedures_constant.g_yes;
                            END IF;
                        END IF;
                    ELSE
                        l_permission := pk_procedures_constant.g_no;
                    END IF;
                END IF;
            ELSIF i_button = pk_procedures_constant.g_interv_button_ok
            THEN
                IF l_interv_plan.flg_status IN
                   (pk_procedures_constant.g_interv_plan_executed, pk_procedures_constant.g_interv_plan_cancel)
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSIF l_interv_presc.flg_prn = pk_procedures_constant.g_yes
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF l_interv_presc.flg_time = pk_procedures_constant.g_flg_time_n
                    THEN
                        l_permission := pk_procedures_constant.g_yes;
                    ELSE
                        IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_finished
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSE
                            l_permission := pk_procedures_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            ELSIF i_button = pk_procedures_constant.g_interv_button_cancel
            THEN
                IF l_interv_plan.flg_status IN
                   (pk_procedures_constant.g_interv_plan_cancel, pk_procedures_constant.g_interv_plan_expired)
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSIF l_interv_presc.flg_prn = pk_procedures_constant.g_yes
                THEN
                    l_permission := pk_procedures_constant.g_no;
                ELSE
                    IF l_interv_presc.flg_time = pk_procedures_constant.g_flg_time_n
                    THEN
                        l_permission := pk_procedures_constant.g_yes;
                    ELSE
                        IF l_interv_presc.flg_status = pk_procedures_constant.g_interv_finished
                        THEN
                            l_permission := pk_procedures_constant.g_no;
                        ELSE
                            l_permission := pk_procedures_constant.g_yes;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_permission;

    FUNCTION get_procedure_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_field      IN table_varchar,
        i_interv_field_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_detail VARCHAR2(1000 CHAR);
    
    BEGIN
    
        -- 'T' - Title
        -- 'F'
        IF i_interv_field_type = 'T'
        THEN
            FOR i IN 2 .. i_interv_field.count
            LOOP
                IF i_interv_field(i) IS NOT NULL
                THEN
                    l_detail := i_interv_field(1);
                END IF;
            END LOOP;
        ELSE
            IF i_interv_field(1) IS NOT NULL
            THEN
                l_detail := chr(9) || chr(32) || chr(32) || i_interv_field(1);
            END IF;
        END IF;
    
        RETURN l_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_detail;

    FUNCTION get_procedure_detail_clob
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_field      IN table_clob,
        i_interv_field_type IN VARCHAR2
    ) RETURN CLOB IS
    
        l_detail CLOB;
    
    BEGIN
    
        -- 'T' - Title
        -- 'F'
        IF i_interv_field_type = 'T'
        THEN
            FOR i IN 2 .. i_interv_field.count
            LOOP
                IF i_interv_field(i) IS NOT NULL
                THEN
                    l_detail := i_interv_field(1);
                END IF;
            END LOOP;
        ELSE
            IF i_interv_field(1) IS NOT NULL
            THEN
                l_detail := chr(9) || chr(32) || chr(32) || i_interv_field(1);
            END IF;
        END IF;
    
        RETURN l_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_detail_clob;

    FUNCTION get_procedure_question_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN interv_questionnaire.flg_type%TYPE IS
    
        l_type interv_questionnaire.flg_type%TYPE;
    
    BEGIN
    
        g_error := 'SELECT INTO L_TYPE';
        SELECT iq.flg_type
          INTO l_type
          FROM interv_questionnaire iq
         INNER JOIN questionnaire_response qr
            ON iq.id_questionnaire = qr.id_questionnaire
           AND iq.id_response = qr.id_response
         WHERE iq.id_intervention = i_intervention
           AND iq.flg_time = i_flg_time
           AND iq.id_questionnaire = i_questionnaire
           AND (iq.id_response = i_response OR i_response IS NULL)
           AND iq.id_institution = i_prof.institution
           AND iq.flg_available = pk_procedures_constant.g_available
           AND qr.flg_available = pk_procedures_constant.g_available
           AND rownum < 2;
    
        RETURN l_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_question_type;

    FUNCTION get_procedure_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE
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
                   AND qr.flg_available = pk_procedures_constant.g_available
                   AND qr.id_response = r.id_response
                   AND r.flg_available = pk_procedures_constant.g_available
                   AND EXISTS (SELECT 1
                          FROM interv_questionnaire iq
                         WHERE iq.id_intervention = i_intervention
                           AND iq.flg_time = i_flg_time
                           AND iq.id_questionnaire = qr.id_questionnaire
                           AND iq.id_response = qr.id_response
                           AND iq.id_institution = nvl(i_inst_dest, i_prof.institution)
                           AND iq.flg_available = pk_procedures_constant.g_available)
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
    END get_procedure_response;

    FUNCTION get_procedure_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN interv_question_response.notes%TYPE
    ) RETURN interv_question_response.notes%TYPE IS
    
        l_ret interv_question_response.notes%TYPE;
    
    BEGIN
        -- Heuristic to minimize attempts to parse an invalid date
        IF dbms_lob.getlength(i_notes) = length('YYYYMMDDHHMMSS')
           AND pk_utils.is_number(char_in => i_notes) = pk_procedures_constant.g_yes -- This is the size of a stored serialized date, not a mask (HH vs HH24).-- This is the size of a stored serialized date, not a mask (HH vs HH24).
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
    END get_procedure_response;

    FUNCTION get_procedure_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN interv_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2 IS
    
        l_response VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT substr(concatenate(t.id_response || '|'), 1, length(concatenate(t.id_response || '|')) - 1)
          INTO l_response
          FROM (SELECT iqr.id_response,
                       dense_rank() over(PARTITION BY iqr.id_questionnaire ORDER BY iqr.dt_last_update_tstz DESC) rn
                  FROM interv_question_response iqr
                 WHERE iqr.id_episode = i_episode
                   AND iqr.id_questionnaire = i_questionnaire) t
         WHERE t.rn = 1;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_episode_response;

    FUNCTION get_procedure_modifiers
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_procedure_modifiers pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT desc_modifiers
          INTO l_procedure_modifiers
          FROM (SELECT substr(concatenate(pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                                          43,
                                                                                          ippm.id_modifier,
                                                                                          ippm.id_inst_owner) ||
                                          nvl2(ippm.id_modifier, '; ', '')),
                              1,
                              length(concatenate(pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                                                 pk_alert_constant.g_task_procedure,
                                                                                                 ippm.id_modifier,
                                                                                                 ippm.id_inst_owner) ||
                                                 nvl2(ippm.id_modifier, '; ', ''))) - 2) desc_modifiers
                  FROM interv_pp_modifiers ippm
                 WHERE ippm.id_interv_presc_plan = i_interv_presc_plan
                 GROUP BY ippm.id_interv_presc_plan
                UNION
                SELECT substr(concatenate(pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                                          43,
                                                                                          ippmh.id_modifier,
                                                                                          ippmh.id_inst_owner) ||
                                          nvl2(ippmh.id_modifier, '; ', '')),
                              1,
                              length(concatenate(pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                                                 43,
                                                                                                 ippmh.id_modifier,
                                                                                                 ippmh.id_inst_owner) ||
                                                 nvl2(ippmh.id_modifier, '; ', ''))) - 2) desc_modifiers
                  FROM interv_pp_modifiers_hist ippmh
                 WHERE ippmh.id_interv_presc_plan_hist = i_interv_presc_plan
                 GROUP BY ippmh.id_interv_presc_plan_hist);
    
        RETURN l_procedure_modifiers;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_modifiers;

    FUNCTION get_procedure_timeout
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_timeout VARCHAR2(1 CHAR);
    
    BEGIN
    
        SELECT flg_timeout
          INTO l_flg_timeout
          FROM (SELECT nvl(idcs.flg_timeout, pk_procedures_constant.g_no) flg_timeout,
                       row_number() over(PARTITION BY idcs.id_intervention ORDER BY idcs.id_professional DESC, idcs.id_institution DESC, idcs.id_software DESC) rn
                  FROM interv_dep_clin_serv idcs
                 WHERE idcs.id_intervention = i_intervention
                   AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                   AND idcs.id_institution IN (0, i_prof.institution)
                   AND idcs.id_software IN (0, i_prof.software)
                   AND nvl(idcs.id_professional, 0) IN (0, i_prof.id))
         WHERE rn = 1;
    
        RETURN l_flg_timeout;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_timeout;

    FUNCTION get_procedure_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN interv_presc_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_diagnosis_list IS
            SELECT pk_diagnosis.get_mcdt_description(i_lang, i_prof, t.id_diagnosis_list, pk_alert_constant.g_yes) desc_diagnosis
              FROM (SELECT column_value id_diagnosis_list
                      FROM TABLE(CAST(pk_utils.str_split(i_diagnosis_list, ';') AS table_varchar2))) t
             ORDER BY desc_diagnosis;
    
        l_diagnosis_list c_diagnosis_list%ROWTYPE;
    
        l_diagnosis_desc VARCHAR2(4000);
    
    BEGIN
    
        FOR l_diagnosis_list IN c_diagnosis_list
        LOOP
            IF l_diagnosis_desc IS NULL
            THEN
                l_diagnosis_desc := l_diagnosis_list.desc_diagnosis;
            ELSE
                l_diagnosis_desc := l_diagnosis_desc || ', ' || l_diagnosis_list.desc_diagnosis;
            END IF;
        END LOOP;
    
        RETURN l_diagnosis_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_diagnosis;

    FUNCTION get_procedure_supplies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies_list IN interv_presc_det_hist.id_supplies_list%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_supplies_list IS
            SELECT pk_supplies_external_api_db.get_supply_description(i_lang,
                                                                      i_prof,
                                                                      CAST(pk_string_utils.str_split(i_supplies_list,
                                                                                                     ';') AS
                                                                           table_varchar)) desc_supplies
              FROM dual;
    
        l_supplies_list c_supplies_list%ROWTYPE;
    
        l_supplies_desc VARCHAR2(1000 CHAR);
    
    BEGIN
    
        FOR l_supplies_list IN c_supplies_list
        LOOP
            IF l_supplies_desc IS NULL
            THEN
                l_supplies_desc := l_supplies_list.desc_supplies;
            ELSE
                l_supplies_desc := l_supplies_desc || ', ' || l_supplies_list.desc_supplies;
            END IF;
        END LOOP;
    
        RETURN l_supplies_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_supplies;

    FUNCTION get_procedure_codification
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_interv_codification IN interv_codification.id_interv_codification%TYPE
    ) RETURN NUMBER IS
    
        l_codification NUMBER;
    
    BEGIN
    
        IF i_interv_codification IS NOT NULL
        THEN
            g_error := 'SELECT INTERV_CODIFICATION';
            SELECT ic.id_codification
              INTO l_codification
              FROM interv_codification ic
             WHERE ic.id_interv_codification = i_interv_codification;
        ELSE
            l_codification := NULL;
        END IF;
    
        RETURN l_codification;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_codification;

    FUNCTION get_procedure_with_codification
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_intervention        IN intervention.id_intervention%TYPE,
        i_interv_codification IN interv_codification.id_interv_codification%TYPE
    ) RETURN VARCHAR2 IS
    
        l_codification VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_interv_codification IS NOT NULL
        THEN
            g_error := 'GET CODIFICATION';
            SELECT ' (' || listagg(desc_codification, ', ') within GROUP(ORDER BY c.desc_codification) || ')'
              INTO l_codification
              FROM (SELECT decode(ic.flg_show_code, pk_procedures_constant.g_yes, ic.standard_code || ' - ', '') ||
                           pk_translation.get_translation(i_lang,
                                                          'CODIFICATION.CODE_CODIFICATION.' || ic.id_codification) desc_codification
                      FROM interv_codification ic
                     WHERE ic.id_interv_codification = i_interv_codification
                       AND ic.flg_show_codification = pk_procedures_constant.g_yes) c;
        
        ELSIF i_intervention IS NOT NULL
        THEN
            g_error := 'GET CODIFICATION';
            SELECT ' (' || listagg(desc_codification, ', ') within GROUP(ORDER BY c.desc_codification) || ')'
              INTO l_codification
              FROM (SELECT decode(ic.flg_show_code, pk_procedures_constant.g_yes, ic.standard_code || ' - ', '') ||
                           pk_translation.get_translation(i_lang, c.code_codification) desc_codification
                      FROM interv_codification ic, codification_instit_soft cis, codification c
                     WHERE ic.id_intervention = i_intervention
                       AND ic.flg_show_codification = pk_procedures_constant.g_yes
                       AND ic.flg_available = pk_procedures_constant.g_available
                       AND ic.id_codification = cis.id_codification
                       AND cis.id_institution = i_prof.institution
                       AND cis.id_software = i_prof.software
                       AND cis.flg_available = pk_procedures_constant.g_available
                       AND cis.id_codification = c.id_codification
                       AND c.flg_available = pk_procedures_constant.g_available) c;
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
    END get_procedure_with_codification;

    FUNCTION get_procedure_code
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_intervention        IN intervention.id_intervention%TYPE,
        i_codification        IN codification.id_codification%TYPE,
        i_interv_codification IN interv_codification.id_interv_codification%TYPE
    ) RETURN VARCHAR2 IS
    
        l_code VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_interv_codification IS NOT NULL
        THEN
            g_error := 'GET CODIFICATION';
            SELECT ' (' || ic.standard_code || ')'
              INTO l_code
              FROM interv_codification ic
             WHERE ic.id_interv_codification = i_interv_codification
               AND ic.flg_show_code = pk_procedures_constant.g_yes;
        
        ELSIF i_intervention IS NOT NULL
              AND i_codification IS NOT NULL
        THEN
            g_error := 'GET CODIFICATION';
            SELECT ' (' || ic.standard_code || ')'
              INTO l_code
              FROM interv_codification ic
             WHERE ic.id_intervention = i_intervention
               AND ic.id_codification = i_codification
               AND ic.flg_show_code = pk_procedures_constant.g_yes
               AND ic.flg_available = pk_procedures_constant.g_available;
        ELSE
            l_code := NULL;
        END IF;
    
        IF l_code = ' ()'
        THEN
            l_code := NULL;
        END IF;
    
        RETURN l_code;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_code;

    FUNCTION get_procedure_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_procedure_doc IN VARCHAR2,
        i_flg_procedure_tde IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_icon_name VARCHAR2(200 CHAR);
    
    BEGIN
    
        IF i_interv_presc_det IS NULL
        THEN
            IF i_flg_procedure_doc = pk_procedures_constant.g_yes
               AND i_flg_procedure_tde = pk_procedures_constant.g_flg_origin_module_o
            THEN
                l_icon_name := pk_sysdomain.get_img(i_lang,
                                                    'DOCUMENT_ORDER_SET',
                                                    pk_alert_constant.g_task_origin_order_set ||
                                                    pk_procedures_constant.g_media_archive_interv_doc);
            
            ELSIF i_flg_procedure_doc = pk_procedures_constant.g_no
                  AND i_flg_procedure_tde = pk_procedures_constant.g_flg_origin_module_o
            THEN
                l_icon_name := pk_sysdomain.get_img(i_lang,
                                                    'INTERV_PRESC_DET.FLG_REQ_ORIGIN_MODULE',
                                                    pk_alert_constant.g_task_origin_order_set);
            ELSIF i_flg_procedure_doc = pk_procedures_constant.g_yes
                  AND i_flg_procedure_tde != pk_procedures_constant.g_flg_origin_module_o
            THEN
                l_icon_name := pk_sysdomain.get_img(i_lang,
                                                    'INTERV_MEDIA_ARCHIVE.FLG_TYPE',
                                                    pk_procedures_constant.g_media_archive_interv_doc);
            END IF;
        ELSE
            g_error := 'GET ORDER_RECURRENCE';
            SELECT decode(ipd.id_order_recurrence, NULL, pk_procedures_constant.g_no, pk_procedures_constant.g_yes)
              INTO l_icon_name
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = i_interv_presc_det;
        END IF;
    
        RETURN l_icon_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_icon;

    FUNCTION get_procedure_concat_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN VARCHAR2,
        i_delim            IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_tbl_interv_presc_det table_number;
    
        l_ret VARCHAR2(4000 CHAR);
    
    BEGIN
        l_tbl_interv_presc_det := pk_utils.str_split_n(i_list => i_interv_presc_det, i_delim => i_delim);
    
        FOR i IN l_tbl_interv_presc_det.first .. l_tbl_interv_presc_det.last
        LOOP
            l_ret := l_ret || pk_procedures_external.get_procedure_description(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_interv_presc_det => l_tbl_interv_presc_det(i),
                                                                               i_co_sign_hist     => NULL) || CASE
                         WHEN i = l_tbl_interv_presc_det.last THEN
                          NULL
                         ELSE
                          ' / '
                     END;
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_concat_desc;

    FUNCTION get_flg_favorite
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2 AS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM interv_favorites IF
         WHERE if.id_intervention = i_id_intervention
           AND if.id_professional = i_prof.id;
    
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_flg_favorite;

    FUNCTION set_interv_favorite
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN AS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM interv_favorites rei
         WHERE rei.id_intervention = i_id_intervention
           AND rei.id_professional = i_prof.id;
    
        IF l_count > 0
        THEN
            DELETE FROM interv_favorites rei
             WHERE rei.id_intervention = i_id_intervention
               AND rei.id_professional = i_prof.id;
        ELSE
            INSERT INTO interv_favorites
                (id_interv_favorites, id_intervention, id_professional)
            VALUES
                (seq_interv_favorites.nextval, i_id_intervention, i_prof.id);
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
                                              'SET_INTERV_FAVORITE',
                                              o_error);
            RETURN FALSE;
    END set_interv_favorite;

    FUNCTION get_interv_hash
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE
    ) RETURN NUMBER IS
    
        l_hash_aux VARCHAR2(30 CHAR);
        l_ret_hash NUMBER(24);
    BEGIN
        l_hash_aux := i_id_intervention || i_prof.id;
        l_ret_hash := dbms_utility.get_hash_value(l_hash_aux, 37, 1073741824);
        RETURN l_ret_hash;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_interv_hash;

    FUNCTION manage_most_frequent
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN AS
        l_hash  NUMBER(24);
        l_count NUMBER(24);
    BEGIN
        l_hash := get_interv_hash(i_lang, i_prof, i_id_intervention);
    
        SELECT COUNT(*)
          INTO l_count
          FROM interv_most_frequent rf
         WHERE rf.id_intervention = i_id_intervention
           AND rf.id_universe = 8
           AND rf.interv_hash = l_hash;
    
        IF l_count > 0
        THEN
            UPDATE interv_most_frequent
               SET rank = rank + 1
             WHERE id_intervention = i_id_intervention
               AND interv_hash = l_hash;
        ELSE
            INSERT INTO interv_most_frequent
                (id_interv_most_frequent, id_universe, id_value, id_intervention, interv_hash, rank)
            VALUES
                (seq_interv_most_frequent.nextval, 8, i_prof.id, i_id_intervention, l_hash, 1);
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
                                              'MANAGE_MOST_FREQUENT',
                                              o_error);
            RETURN FALSE;
    END manage_most_frequent;

    FUNCTION manage_most_frequent_dept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        i_dept            IN clinical_service.id_clinical_service%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN AS
        l_hash  NUMBER(24);
        l_count NUMBER(24);
    BEGIN
        l_hash := get_interv_hash(i_lang, i_prof, i_id_intervention);
    
        SELECT COUNT(*)
          INTO l_count
          FROM interv_most_frequent rf
         WHERE rf.id_intervention = i_id_intervention
           AND rf.id_universe = 10
           AND rf.interv_hash = l_hash;
    
        IF l_count > 0
        THEN
            UPDATE interv_most_frequent
               SET rank = rank + 1
             WHERE id_intervention = i_id_intervention
               AND interv_hash = l_hash;
        ELSE
            INSERT INTO interv_most_frequent
                (id_interv_most_frequent, id_universe, id_value, id_intervention, interv_hash, rank)
            VALUES
                (seq_interv_most_frequent.nextval, 10, i_dept, i_id_intervention, l_hash, 1);
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
                                              'MANAGE_MOST_FREQUENT_DEPT',
                                              o_error);
            RETURN FALSE;
    END manage_most_frequent_dept;

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
    
        l_tbl_id_intervention       table_number;
        l_tbl_id_intervention_final table_number;
        l_patient                   patient%ROWTYPE;
    BEGIN
    
        l_tbl_id_intervention := pk_utils.str_split_n(i_list => i_screen_name, i_delim => '|');
    
        IF i_action = 70
        THEN
            FOR i IN l_tbl_id_intervention.first .. l_tbl_id_intervention.last
            LOOP
                SELECT ipd.id_intervention
                  INTO l_tbl_id_intervention(i)
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det = l_tbl_id_intervention(i);
            END LOOP;
        ELSE
            SELECT DISTINCT eq.id_intervention
              BULK COLLECT
              INTO l_tbl_id_intervention_final
              FROM interv_questionnaire eq
             WHERE eq.id_intervention IN (SELECT column_value
                                            FROM TABLE(l_tbl_id_intervention))
               AND eq.flg_time = pk_exam_constant.g_exam_cq_on_order
               AND eq.id_institution = i_prof.institution
               AND eq.flg_available = pk_exam_constant.g_available;
            IF l_tbl_id_intervention_final.count = 0
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
                       pk_translation.get_translation(i_lang,
                                                      'INTERVENTION.CODE_INTERVENTION.' || to_number(t.column_value)) desc_component,
                       pk_translation.get_translation(i_lang,
                                                      'INTERVENTION.CODE_INTERVENTION.' || to_number(t.column_value)) internal_name,
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
                  FROM TABLE(l_tbl_id_intervention_final) t
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_intervention) id_ds_cmpt_mkt_rel,
                       q.id_intervention id_ds_component_parent,
                       NULL code_alt_desc,
                       pk_mcdt.get_questionnaire_alias(i_lang,
                                                       i_prof,
                                                       'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || q.id_questionnaire) desc_component,
                       to_char('P' || '|' || q.id_intervention || '_' || q.id_questionnaire) internal_name,
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
                       (q.id_questionnaire * 10 + q.id_intervention) service_params,
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
                  FROM (SELECT DISTINCT iq.id_intervention,
                                        iq.id_questionnaire,
                                        qr.id_questionnaire_parent,
                                        qr.id_response_parent,
                                        iq.flg_type,
                                        iq.flg_mandatory,
                                        iq.flg_copy,
                                        iq.id_unit_measure
                          FROM interv_questionnaire iq,
                               questionnaire_response qr,
                               (SELECT column_value AS id_intervention
                                  FROM TABLE(l_tbl_id_intervention_final)) p
                         WHERE iq.id_intervention = p.id_intervention
                           AND iq.flg_time = 'O'
                           AND iq.id_institution = i_prof.institution
                           AND iq.flg_available = pk_procedures_constant.g_available
                           AND iq.id_questionnaire = qr.id_questionnaire
                           AND iq.id_response = qr.id_response
                           AND qr.flg_available = pk_procedures_constant.g_available
                           AND EXISTS
                         (SELECT 1
                                  FROM questionnaire q
                                 WHERE q.id_questionnaire = iq.id_questionnaire
                                   AND q.flg_available = pk_procedures_constant.g_available
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
                
                SELECT (q.id_questionnaire * 10 + q.id_intervention) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        '@1 == ' || get_response_parent(i_lang, i_prof, q.id_intervention, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_intervention id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'A' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_intervention,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM interv_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_intervention IN (SELECT *
                                                         FROM TABLE(l_tbl_id_intervention_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_procedures_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_procedures_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_procedures_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_intervention
                           FROM interv_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_intervention IN (SELECT *
                                                         FROM TABLE(l_tbl_id_intervention_final))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_intervention = q.id_intervention
                   AND q.flg_type IN ('ME', 'MI')
                UNION ALL
                SELECT (q.id_questionnaire * 10 + q.id_intervention) id_cmpt_mkt_origin,
                        q.id_questionnaire id_cmpt_origin,
                        q.id_questionnaire id_ds_event,
                        'E' flg_type,
                        --'@1 == ' || get_response_parent(i_lang, i_prof, q.id_exam, q.id_questionnaire) VALUE,
                        '@1 != ' || get_response_parent(i_lang, i_prof, q.id_intervention, q.id_questionnaire) VALUE,
                        qd.id_questionnaire * 10 + q.id_intervention id_cmpt_mkt_dest,
                        NULL id_cmpt_dest,
                        NULL field_mask,
                        'I' flg_event_target_type,
                        NULL validation_message,
                        1 rn
                  FROM (SELECT DISTINCT iq.id_intervention,
                                         iq.id_questionnaire,
                                         qr.id_questionnaire_parent,
                                         qr.id_response_parent,
                                         iq.flg_type,
                                         iq.flg_mandatory,
                                         iq.flg_copy,
                                         iq.flg_validation,
                                         iq.id_unit_measure,
                                         iq.rank
                           FROM interv_questionnaire iq, questionnaire_response qr
                          WHERE iq.id_intervention IN (SELECT *
                                                         FROM TABLE(l_tbl_id_intervention_final))
                            AND iq.flg_time = 'O'
                            AND iq.id_institution = i_prof.institution
                            AND iq.flg_available = pk_procedures_constant.g_available
                            AND iq.id_questionnaire = qr.id_questionnaire
                            AND iq.id_response = qr.id_response
                            AND qr.flg_available = pk_procedures_constant.g_available
                            AND EXISTS
                          (SELECT 1
                                   FROM questionnaire q
                                  WHERE q.id_questionnaire = iq.id_questionnaire
                                    AND q.flg_available = pk_procedures_constant.g_available
                                    AND (((l_patient.gender IS NOT NULL AND coalesce(q.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_patient.gender)) OR l_patient.gender IS NULL OR
                                        l_patient.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                        nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                        (SELECT DISTINCT qr.id_questionnaire, qr.id_questionnaire_parent, eq.id_intervention
                           FROM interv_questionnaire eq
                          INNER JOIN questionnaire_response qr
                             ON eq.id_questionnaire = qr.id_questionnaire
                          WHERE eq.id_intervention IN (SELECT *
                                                         FROM TABLE(l_tbl_id_intervention_final))
                            AND eq.id_institution = i_prof.institution) qd
                 WHERE q.id_response_parent IS NULL
                   AND qd.id_questionnaire_parent = q.id_questionnaire
                   AND qd.id_intervention = q.id_intervention
                   AND q.flg_type IN ('ME', 'MI')) z;
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
        i_intervention  intervention.id_intervention%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER AS
        l_ret NUMBER(24);
    BEGIN
    
        SELECT DISTINCT qr.id_response_parent
          INTO l_ret
          FROM interv_questionnaire iq
         INNER JOIN questionnaire_response qr
            ON iq.id_questionnaire = qr.id_questionnaire
         WHERE iq.id_intervention = i_intervention
           AND qr.id_questionnaire_parent = i_questionnaire
           AND iq.id_institution = i_prof.institution;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_response_parent;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_procedures_utils;
/
