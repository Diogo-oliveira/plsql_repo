/*-- Last Change Revision: $Rev: 2027462 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_education_utils IS

    FUNCTION get_desc_topic
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_topic   IN nurse_tea_req.id_nurse_tea_topic%TYPE,
        i_desc_topic_aux       IN nurse_tea_req.desc_topic_aux%TYPE,
        i_code_nurse_tea_topic IN nurse_tea_topic.code_nurse_tea_topic%TYPE
        
    ) RETURN nurse_tea_req.desc_topic_aux%TYPE IS
    
        l_title_topic nurse_tea_req.desc_topic_aux%TYPE;
    
    BEGIN
        CASE
            WHEN i_id_nurse_tea_topic = 1
                 AND i_desc_topic_aux IS NOT NULL THEN
                l_title_topic := i_desc_topic_aux;
            ELSE
                l_title_topic := pk_translation.get_translation(i_lang, i_code_nurse_tea_topic);
        END CASE;
    
        RETURN l_title_topic;
    
    END get_desc_topic;

    FUNCTION get_instructions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_tbp    VARCHAR2(4000);
        l_start  VARCHAR2(4000);
        l_ret    VARCHAR2(4000);
        l_void   VARCHAR2(3) := '---';
        l_format VARCHAR2(5) := 'TSE';
        l_end    VARCHAR2(4000);
    
        -- Data structures related with error handling
    
        PROCEDURE add_to_ret
        (
            i_add      IN VARCHAR2,
            i_original IN OUT VARCHAR2
        ) IS
        BEGIN
            IF i_original IS NULL
            THEN
                i_original := i_add;
            ELSE
                i_original := i_original || '; ' || nvl(i_add, l_void);
            END IF;
        END add_to_ret;
    
    BEGIN
    
        g_error := 'GET DATA';
        SELECT decode(ntr.flg_time,
                      NULL,
                      NULL,
                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T040') || ' ' ||
                      pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_TIME', ntr.flg_time, i_lang)),
               decode(ntr.dt_begin_tstz,
                      NULL,
                      NULL,
                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T042') || ' ' ||
                      pk_date_utils.date_char_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software)),
               decode(ntr.id_order_recurr_plan,
                      NULL,
                      pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'),
                      pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, ntr.id_order_recurr_plan))
          INTO l_tbp, l_start, l_end
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_nurse_tea_req;
    
        FOR i IN 1 .. length(l_format)
        LOOP
            CASE substr(l_format, i, 1)
                WHEN 'T' THEN
                    add_to_ret(l_tbp, l_ret);
                WHEN 'S' THEN
                    add_to_ret(l_start, l_ret);
                WHEN 'E' THEN
                    add_to_ret(l_end, l_ret);
                ELSE
                    NULL;
            END CASE;
        END LOOP;
    
        RETURN l_ret;
    
    END get_instructions;

    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE DEFAULT NULL,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE DEFAULT NULL,
        i_dt_nurse_tea_req_str IN VARCHAR2 DEFAULT NULL,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE DEFAULT NULL,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE DEFAULT NULL,
        i_id_cancel_reason     IN nurse_tea_req.id_cancel_reason%TYPE DEFAULT NULL,
        o_rowids               IN OUT table_varchar
    ) IS
        -- Auxiliar Variables
        dt_aux_nurse_tea_req_tstz TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_begin_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_close_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        --
        l_ntr_row_old nurse_tea_req%ROWTYPE;
        l_ntr_row     nurse_tea_req%ROWTYPE;
    
    BEGIN
    
        IF i_dt_nurse_tea_req_str IS NOT NULL
        THEN
            dt_aux_nurse_tea_req_tstz := pk_date_utils.get_string_tstz(i_lang,
                                                                       i_id_prof_req,
                                                                       i_dt_nurse_tea_req_str,
                                                                       NULL);
        END IF;
    
        IF i_dt_begin_str IS NOT NULL
        THEN
            dt_aux_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_id_prof_req, i_dt_begin_str, NULL);
        END IF;
    
        IF i_dt_close_str IS NOT NULL
        THEN
            dt_aux_close_tstz := pk_date_utils.get_string_tstz(i_lang, i_id_prof_req, i_dt_close_str, NULL);
        END IF;
    
        -- < DESNORM Luís Maia - Sep 2008 >
        -- Apanha os resultados antes do UPDATE para que se os novos valores forem NULL, mantenha os antigos valores.
        SELECT *
          INTO l_ntr_row_old
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        -- Carrega na estrutura os dados para posteriormente realizar o UPDATE
        l_ntr_row.id_nurse_tea_req      := i_id_nurse_tea_req;
        l_ntr_row.id_prof_req           := nvl(i_id_prof_req.id, l_ntr_row_old.id_prof_req);
        l_ntr_row.id_episode            := nvl(i_id_episode, l_ntr_row_old.id_episode);
        l_ntr_row.req_header            := nvl(i_req_header, l_ntr_row_old.req_header);
        l_ntr_row.flg_status            := nvl(i_flg_status, l_ntr_row_old.flg_status);
        l_ntr_row.notes_req             := nvl(i_notes_req, l_ntr_row_old.notes_req);
        l_ntr_row.id_prof_close         := nvl(i_id_prof_close, l_ntr_row_old.id_prof_close);
        l_ntr_row.notes_close           := nvl(i_notes_close, l_ntr_row_old.notes_close);
        l_ntr_row.dt_nurse_tea_req_tstz := nvl(dt_aux_nurse_tea_req_tstz, l_ntr_row_old.dt_nurse_tea_req_tstz);
        l_ntr_row.dt_begin_tstz         := nvl(dt_aux_begin_tstz, l_ntr_row_old.dt_begin_tstz);
        l_ntr_row.dt_close_tstz         := nvl(dt_aux_close_tstz, l_ntr_row_old.dt_close_tstz);
        l_ntr_row.id_visit              := nvl(i_id_visit, l_ntr_row_old.id_visit);
        l_ntr_row.id_patient            := nvl(i_id_patient, l_ntr_row_old.id_patient);
        l_ntr_row.id_cancel_reason      := nvl(i_id_cancel_reason, l_ntr_row_old.id_cancel_reason);
        l_ntr_row.dt_nurse_tea_req_tstz := current_timestamp;
    
        -- Realiza o UPDATE à linha da tabela NURSE_TEA_REQ
        g_error := 'NURSE_TEA_REQ';
        ts_nurse_tea_req.upd(rec_in => l_ntr_row, rows_out => o_rowids);
        -- < END DESNORM >
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
        
    END prv_alter_ntr_by_id;

    FUNCTION prv_new_nurse_tea_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE,
        i_dt_nurse_tea_req_str IN VARCHAR2,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE,
        o_rowids               OUT table_varchar
    ) RETURN nurse_tea_req.id_nurse_tea_req%TYPE IS
        l_next_id_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
    BEGIN
        /* if primary key is passed as a parameter, use it
        else, take the next value from sequence */
        IF (i_id_nurse_tea_req IS NOT NULL)
        THEN
            l_next_id_nurse_tea_req := i_id_nurse_tea_req;
        ELSE
            l_next_id_nurse_tea_req := ts_nurse_tea_req.next_key();
        END IF;
    
        -- < DESNORM LMAIA - Sep 2008 >
        -- CHAMAR O INSERT DO PACKAGE TS_NURSE_TEA_REQ
        ts_nurse_tea_req.ins(id_nurse_tea_req_in      => l_next_id_nurse_tea_req,
                             id_prof_req_in           => i_id_prof_req.id,
                             id_episode_in            => i_id_episode,
                             req_header_in            => i_req_header,
                             flg_status_in            => i_flg_status,
                             notes_req_in             => i_notes_req,
                             id_prof_close_in         => i_id_prof_close,
                             dt_nurse_tea_req_tstz_in => pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_id_prof_req,
                                                                                       i_dt_nurse_tea_req_str,
                                                                                       NULL),
                             dt_begin_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_id_prof_req,
                                                                                       i_dt_begin_str,
                                                                                       NULL),
                             dt_close_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_id_prof_req,
                                                                                       i_dt_close_str,
                                                                                       NULL),
                             notes_close_in           => i_notes_close,
                             id_patient_in            => i_id_patient,
                             id_visit_in              => i_id_visit,
                             rows_out                 => o_rowids);
        -- < END DESNORM >
    
        RETURN l_next_id_nurse_tea_req;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
        
    END prv_new_nurse_tea_req;

    FUNCTION get_pat_education_end_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN nurse_tea_req.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_order_recurr_desc   VARCHAR2(1000);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date_tstz     order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date_tstz       order_recurr_plan.end_date%TYPE := NULL;
        l_flg_end_by_editable VARCHAR2(10);
    
        l_error t_error_out;
    BEGIN
    
        IF i_id_order_recurr_plan IS NOT NULL
        THEN
            IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_plan          => i_id_order_recurr_plan,
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_start_date          => l_start_date_tstz,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date_tstz,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => l_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_instructions function';
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN l_end_date_tstz;
    
    END get_pat_education_end_date;

    FUNCTION get_pat_educ_add_resources
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN CLOB IS
    
        l_add_resources CLOB;
    
    BEGIN
        BEGIN
            SELECT nvl(pk_translation.get_translation(2, nto.code_nurse_tea_opt), ntdo.notes)
              INTO l_add_resources
              FROM nurse_tea_req ntr
              JOIN nurse_tea_det ntd
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
              JOIN nurse_tea_det_opt ntdo
                ON ntd.id_nurse_tea_det = ntdo.id_nurse_tea_det
              LEFT JOIN nurse_tea_opt nto
                ON ntdo.id_nurse_tea_opt = nto.id_nurse_tea_opt
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
        EXCEPTION
            WHEN no_data_found THEN
                l_add_resources := NULL;
            WHEN too_many_rows THEN
                l_add_resources := NULL;
        END;
    
        RETURN l_add_resources;
    
    END get_pat_educ_add_resources;

    FUNCTION tf_get_order_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order IS
    
        l_ret t_tbl_health_education_order := t_tbl_health_education_order();
    BEGIN
    
        SELECT t_health_education_order(id_nurse_tea_req    => t.id_nurse_tea_req,
                                        action              => t.action,
                                        subject             => t.subject,
                                        topic               => t.topic,
                                        clinical_indication => t.clinical_indication,
                                        to_execute          => t.to_execute,
                                        frequency           => t.frequency,
                                        start_date          => t.start_date,
                                        order_notes         => t.order_notes,
                                        description         => t.description,
                                        status              => t.status,
                                        registry            => t.registry,
                                        end_date            => t.end_date)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntr.id_nurse_tea_req,
                       'ORDER' action,
                       pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) subject,
                       pk_patient_education_utils.get_desc_topic(i_lang,
                                                                 i_prof,
                                                                 ntr.id_nurse_tea_topic,
                                                                 ntr.desc_topic_aux,
                                                                 ntt.code_nurse_tea_topic) topic,
                       get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication,
                       pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time, ntr.flg_time, i_lang) to_execute,
                       nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                 i_prof,
                                                                                 ntr.id_order_recurr_plan,
                                                                                 pk_alert_constant.g_no),
                           pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) frequency,
                       pk_date_utils.date_char_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   (get_pat_education_end_date(i_lang, i_prof, ntr.id_order_recurr_plan)),
                                                   i_prof.institution,
                                                   i_prof.software) end_date,
                       ntr.notes_req order_notes,
                       ntr.description description,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_canc THEN
                                                    'PATIENT_EDUCATION_M027'
                                               END) status,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) ||
                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               ntr.id_prof_req,
                                                               ntr.dt_nurse_tea_req_tstz,
                                                               ntr.id_episode),
                              NULL,
                              '; ',
                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntr.id_prof_req,
                                                                       ntr.dt_nurse_tea_req_tstz,
                                                                       ntr.id_episode) || '); ') ||
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ntr.dt_nurse_tea_req_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) registry
                  FROM nurse_tea_req ntr
                  JOIN nurse_tea_topic ntt
                    ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
                  JOIN nurse_tea_subject nts
                    ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_order();
    END tf_get_order_detail;

    FUNCTION tf_get_order_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order_hist IS
    
        l_msg_del sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M106');
    
        l_ret t_tbl_health_education_order_hist := t_tbl_health_education_order_hist();
    BEGIN
    
        SELECT t_health_education_order_hist(id_nurse_tea_req_hist   => tt.id_nurse_tea_req_hist,
                                             action                  => tt.action,
                                             subject                 => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.subject, NULL, NULL, tt.subject),
                                                                               NULL),
                                             topic                   => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.topic, NULL, NULL, tt.topic),
                                                                               NULL),
                                             clinical_indication     => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.clinical_indication,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.clinical_indication),
                                                                               decode(tt.clinical_indication,
                                                                                      tt.clinical_indication_old,
                                                                                      NULL,
                                                                                      decode(tt.clinical_indication_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.clinical_indication_old))),
                                             clinical_indication_new => decode(tt.clinical_indication,
                                                                               tt.clinical_indication_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.clinical_indication),
                                             to_execute              => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.to_execute,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.to_execute),
                                                                               decode(tt.to_execute,
                                                                                      tt.to_execute_old,
                                                                                      NULL,
                                                                                      decode(tt.to_execute_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.to_execute_old))),
                                             to_execute_new          => decode(tt.to_execute,
                                                                               tt.to_execute_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.to_execute),
                                             frequency               => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.frequency,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.frequency),
                                                                               decode(tt.frequency,
                                                                                      tt.frequency_old,
                                                                                      NULL,
                                                                                      decode(tt.frequency_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.frequency_old))),
                                             frequency_new           => decode(tt.frequency,
                                                                               tt.frequency_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.frequency),
                                             start_date              => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.start_date,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.start_date),
                                                                               decode(tt.start_date,
                                                                                      tt.start_date_old,
                                                                                      NULL,
                                                                                      decode(tt.start_date_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.start_date_old))),
                                             start_date_new          => decode(tt.start_date,
                                                                               tt.start_date_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.start_date),
                                             order_notes             => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.order_notes,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.order_notes),
                                                                               decode(tt.order_notes,
                                                                                      tt.order_notes_old,
                                                                                      NULL,
                                                                                      decode(tt.order_notes_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.order_notes_old))),
                                             order_notes_new         => decode(tt.order_notes,
                                                                               tt.order_notes_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.order_notes),
                                             description             => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.description,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.description),
                                                                               decode(tt.description,
                                                                                      tt.description_old,
                                                                                      NULL,
                                                                                      decode(tt.description_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.description_old))),
                                             description_new         => decode(tt.description,
                                                                               tt.description_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.description),
                                             status                  => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.status, NULL, NULL, tt.status),
                                                                               decode(decode(tt.rn,
                                                                                             1,
                                                                                             tt.status_current,
                                                                                             tt.status),
                                                                                      tt.status_old,
                                                                                      NULL,
                                                                                      decode(tt.status_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.status_old))),
                                             status_new              => decode(decode(tt.rn,
                                                                                      1,
                                                                                      tt.status_current,
                                                                                      tt.status),
                                                                               tt.status_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               decode(tt.rn,
                                                                                      1,
                                                                                      tt.status_current,
                                                                                      tt.status)),
                                             registry                => tt.registry,
                                             white_line              => NULL,
                                             end_date                => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.end_date, NULL, NULL, tt.end_date),
                                                                               decode(tt.end_date,
                                                                                      tt.end_date_old,
                                                                                      NULL,
                                                                                      decode(tt.end_date_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.end_date_old))),
                                             end_date_new            => decode(tt.end_date,
                                                                               tt.end_date_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.end_date))
          BULK COLLECT
          INTO l_ret
          FROM (SELECT row_number() over(ORDER BY t.dt_nurse_tea_req_hist_tstz DESC) rn,
                       MAX(rownum) over() cnt,
                       t.id_nurse_tea_req_hist,
                       t.action,
                       t.subject,
                       t.topic,
                       t.clinical_indication,
                       first_value(t.clinical_indication) over(ORDER BY t.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) clinical_indication_old,
                       pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time, t.flg_time, i_lang) to_execute,
                       pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                               t.flg_time_old,
                                               i_lang) to_execute_old,
                       nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                 i_prof,
                                                                                 t.id_order_recurr_plan,
                                                                                 pk_alert_constant.g_no),
                           pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) frequency,
                       nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                 i_prof,
                                                                                 t.id_order_recurr_plan_old,
                                                                                 pk_alert_constant.g_no),
                           pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) frequency_old,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_begin_tstz_old, i_prof.institution, i_prof.software) start_date_old,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_end_tstz_old, i_prof.institution, i_prof.software) end_date_old,
                       t.order_notes,
                       t.order_notes_old,
                       t.description,
                       t.description_old,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN t.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN t.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN t.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN t.dt_begin_tstz > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN t.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN t.flg_status = pk_patient_education_constant.g_nurse_tea_req_canc THEN
                                                    'DETAIL_COMMON_M003'
                                               END) status,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN t.flg_status_old = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN t.flg_status_old = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN t.flg_status_old = pk_patient_education_constant.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN t.dt_begin_tstz_old > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN t.flg_status_old = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN t.flg_status_old = pk_patient_education_constant.g_nurse_tea_req_canc THEN
                                                    'DETAIL_COMMON_M003'
                                               END) status_old,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN t.flg_status_current = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN t.flg_status_current = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN t.flg_status_current = pk_patient_education_constant.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN t.dt_begin_tstz_old > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN t.flg_status_current = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN t.flg_status_current = pk_patient_education_constant.g_nurse_tea_req_canc THEN
                                                    'DETAIL_COMMON_M003'
                                               END) status_current,
                       t.registry
                  FROM (SELECT ntrh.id_nurse_tea_req_hist,
                               'ORDER' action,
                               pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) subject,
                               pk_patient_education_utils.get_desc_topic(i_lang,
                                                                         i_prof,
                                                                         ntr.id_nurse_tea_topic,
                                                                         ntr.desc_topic_aux,
                                                                         ntt.code_nurse_tea_topic) topic,
                               get_diagnosis_hist(i_lang, i_prof, ntrh.id_nurse_tea_req_hist) clinical_indication,
                               ntrh.flg_time,
                               first_value(ntrh.flg_time) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_time_old,
                               ntrh.id_order_recurr_plan,
                               first_value(ntrh.id_order_recurr_plan) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) id_order_recurr_plan_old,
                               ntrh.dt_begin_tstz,
                               first_value(ntrh.dt_begin_tstz) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) dt_begin_tstz_old,
                               get_pat_education_end_date(i_lang, i_prof, ntrh.id_order_recurr_plan) dt_end_tstz,
                               first_value(get_pat_education_end_date(i_lang, i_prof, ntrh.id_order_recurr_plan)) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) dt_end_tstz_old,
                               dbms_lob.substr(ntrh.notes_req, 3990) order_notes,
                               first_value(dbms_lob.substr(ntrh.notes_req, 3990)) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) order_notes_old,
                               dbms_lob.substr(ntrh.description, 3990) description,
                               first_value(dbms_lob.substr(ntrh.description, 3990)) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) description_old,
                               ntrh.flg_status,
                               first_value(ntrh.flg_status) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_old,
                               ntr.flg_status flg_status_current,
                               ntrh.dt_nurse_tea_req_hist_tstz,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) ||
                               decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntrh.id_prof_req,
                                                                       ntrh.dt_nurse_tea_req_tstz,
                                                                       ntrh.id_episode),
                                      NULL,
                                      '; ',
                                      ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               ntrh.id_prof_req,
                                                                               ntrh.dt_nurse_tea_req_tstz,
                                                                               ntrh.id_episode) || '); ') ||
                               pk_date_utils.date_char_tsz(i_lang,
                                                           ntrh.dt_nurse_tea_req_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) registry
                          FROM nurse_tea_req_hist ntrh
                          JOIN nurse_tea_req ntr
                            ON ntr.id_nurse_tea_req = ntrh.id_nurse_tea_req
                          JOIN nurse_tea_topic ntt
                            ON ntt.id_nurse_tea_topic = ntrh.id_nurse_tea_topic
                          JOIN nurse_tea_subject nts
                            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                           AND ntrh.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_pend,
                                                   pk_patient_education_constant.g_nurse_tea_req_canc,
                                                   pk_patient_education_constant.g_nurse_tea_req_act)) t) tt;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_order_hist();
    END tf_get_order_detail_hist;

    FUNCTION tf_get_execution_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_exec IS
    
        l_ret t_tbl_health_education_exec := t_tbl_health_education_exec();
    BEGIN
        SELECT t_health_education_exec(id_nurse_tea_req    => t.id_nurse_tea_req,
                                       id_nurse_tea_det    => t.id_nurse_tea_det,
                                       action              => t.action,
                                       clinical_indication => t.clinical_indication,
                                       goals               => t.goals,
                                       method              => t.method,
                                       given_to            => t.given_to,
                                       deliverables        => t.deliverables,
                                       understanding       => t.understanding,
                                       start_date          => t.start_date,
                                       duration            => t.duration,
                                       end_date            => t.end_date,
                                       description         => t.description,
                                       status              => t.status,
                                       registry            => t.registry,
                                       white_line          => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntr.id_nurse_tea_req,
                       ntd.id_nurse_tea_det,
                       'EXECUTION' action,
                       get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'GOALS') goals,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'METHOD') method,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'GIVEN_TO') given_to,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'DELIVERABLES') deliverables,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'LEVEL_OF_UNDERSTANDING') understanding,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof) start_date,
                       nvl2(ntd.duration,
                            ntd.duration || ' ' ||
                            pk_unit_measure.get_unit_measure_description(i_lang, i_prof, ntd.id_unit_meas_duration),
                            NULL) duration,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof) end_date,
                       ntd.description,
                       CASE
                            WHEN ntr.flg_status = 'F'
                                 AND ntd.id_nurse_tea_det =
                                 (SELECT ntdz.id_nurse_tea_det
                                        FROM nurse_tea_det ntdz
                                       WHERE ntdz.id_nurse_tea_req = ntr.id_nurse_tea_req
                                         AND ntdz.flg_status = ntd.flg_status
                                         AND ntdz.num_order =
                                             (SELECT MAX(ntdx.num_order)
                                                FROM nurse_tea_det ntdx
                                               WHERE ntdx.id_nurse_tea_req = ntr.id_nurse_tea_req))
                                 OR ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                             pk_message.get_message(i_lang,
                                                    CASE ntr.flg_status
                                                        WHEN pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                         'PATIENT_EDUCATION_M038'
                                                        WHEN pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                         CASE
                                                             WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                              'PATIENT_EDUCATION_M036'
                                                             WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                              'PATIENT_EDUCATION_M036'
                                                             ELSE
                                                              'PATIENT_EDUCATION_M043'
                                                         END
                                                        WHEN pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                         'PATIENT_EDUCATION_M044'
                                                        ELSE
                                                         NULL
                                                    END)
                            ELSE
                             NULL
                        END status,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider) ||
                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               ntd.id_prof_provider,
                                                               ntd.dt_nurse_tea_det_tstz,
                                                               ntr.id_episode),
                              NULL,
                              '; ',
                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntd.id_prof_provider,
                                                                       ntd.dt_nurse_tea_det_tstz,
                                                                       ntr.id_episode) || '); ') ||
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ntd.dt_nurse_tea_det_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) registry
                  FROM nurse_tea_det ntd
                  JOIN nurse_tea_req ntr
                    ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                 WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
                   AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_exec
                 ORDER BY ntd.num_order DESC) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_exec();
    END tf_get_execution_detail;

    FUNCTION tf_get_cancel_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_cancel IS
    
        l_ret t_tbl_health_education_cancel := t_tbl_health_education_cancel();
    BEGIN
    
        SELECT t_health_education_cancel(id_nurse_tea_req => t.id_nurse_tea_req,
                                         action           => t.action,
                                         cancel_reason    => t.cancel_reason,
                                         cancel_notes     => t.cancel_notes,
                                         registry         => t.registry,
                                         white_line       => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntr.id_nurse_tea_req,
                       'CANCELLATION' action,
                       pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                       ntr.notes_close cancel_notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) ||
                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               ntr.id_prof_close,
                                                               ntr.dt_close_tstz,
                                                               ntr.id_episode),
                              NULL,
                              '; ',
                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntr.id_prof_close,
                                                                       ntr.dt_close_tstz,
                                                                       ntr.id_episode) || '); ') ||
                       pk_date_utils.date_char_tsz(i_lang, ntr.dt_close_tstz, i_prof.institution, i_prof.software) registry
                  FROM nurse_tea_req ntr
                  JOIN cancel_reason cr
                    ON cr.id_cancel_reason = ntr.id_cancel_reason
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                   AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_canc) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_cancel();
    END tf_get_cancel_detail;

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret               VARCHAR2(4000);
        l_nurse_tea_req_max nurse_tea_req.id_nurse_tea_req%TYPE;
    BEGIN
    
        SELECT MAX(ntrd.id_nurse_tea_req_hist)
          INTO l_nurse_tea_req_max
          FROM nurse_tea_req_diag_hist ntrd
         WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req;
    
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_ret
          FROM (SELECT (SELECT pk_diagnosis.concat_diag(i_lang, NULL, NULL, NULL, i_prof, i_nurse_tea_req)
                          FROM dual) description
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_nurse_tea_req
                UNION ALL
                SELECT DISTINCT (SELECT pk_translation.get_translation(i_lang, ic.code_icnp_composition)
                                   FROM dual) description
                  FROM nurse_tea_req_diag_hist ntrd
                  JOIN icnp_composition ic
                    ON ic.id_composition = ntrd.id_composition
                 WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                   AND ntrd.id_composition IS NOT NULL
                   AND ntrd.id_nurse_tea_req_hist = l_nurse_tea_req_max
                UNION ALL
                SELECT (SELECT pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ntrd.id_nan_diagnosis,
                                                                   i_code_format   => pk_nan_model.g_code_format_end)
                          FROM dual) description
                  FROM nurse_tea_req_diag_hist ntrd
                 WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                   AND ntrd.id_nan_diagnosis IS NOT NULL
                   AND ntrd.id_nurse_tea_req_hist = l_nurse_tea_req_max)
         WHERE description IS NOT NULL;
    
        RETURN l_ret;
    END get_diagnosis;

    FUNCTION get_diagnosis_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_ret
          FROM (SELECT CASE
                            WHEN ntrdh.id_nurse_tea_req_diag_hist IS NOT NULL THEN
                             pk_diagnosis.concat_diag_hist_id_str(i_lang, i_prof, 'T', i_nurse_tea_req)
                            ELSE
                             nvl(pk_diagnosis.concat_diag_hist_id_str(i_lang, i_prof, 'T', i_nurse_tea_req),
                                 pk_diagnosis.concat_diag(i_lang, NULL, NULL, NULL, i_prof, ntr.id_nurse_tea_req))
                        END AS description
                  FROM nurse_tea_req_hist ntrh
                 INNER JOIN nurse_tea_req ntr
                    ON ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                  LEFT JOIN nurse_tea_req_diag_hist ntrdh
                    ON ntrdh.id_nurse_tea_req_hist = ntrh.id_nurse_tea_req_hist
                   AND ntrdh.id_diagnosis IS NULL
                 WHERE ntrh.id_nurse_tea_req_hist = i_nurse_tea_req
                UNION ALL
                SELECT DISTINCT pk_translation.get_translation(i_lang, ic.code_icnp_composition) description
                  FROM nurse_tea_req_diag_hist ntrd
                  JOIN icnp_composition ic
                    ON ic.id_composition = ntrd.id_composition
                 WHERE ntrd.id_nurse_tea_req_hist = i_nurse_tea_req
                   AND ntrd.id_composition IS NOT NULL
                UNION ALL
                SELECT pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ntrd.id_nan_diagnosis,
                                                           i_code_format   => pk_nan_model.g_code_format_end) description
                  FROM nurse_tea_req_diag_hist ntrd
                 WHERE ntrd.id_nurse_tea_req_hist = i_nurse_tea_req
                   AND ntrd.id_nan_diagnosis IS NOT NULL)
         WHERE description IS NOT NULL;
    
        RETURN l_ret;
    END get_diagnosis_hist;

    FUNCTION get_composition_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_ret
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic.code_icnp_composition) description
                  FROM nurse_tea_req_diag_hist ntrd
                  JOIN icnp_composition ic
                    ON ic.id_composition = ntrd.id_composition
                 WHERE ntrd.id_nurse_tea_req_hist = i_nurse_tea_req
                   AND ntrd.id_composition IS NOT NULL
                UNION ALL
                SELECT pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ntrd.id_nan_diagnosis,
                                                           i_code_format   => pk_nan_model.g_code_format_end) description
                  FROM nurse_tea_req_diag_hist ntrd
                 WHERE ntrd.id_nurse_tea_req_hist = i_nurse_tea_req
                   AND ntrd.id_nan_diagnosis IS NOT NULL)
         WHERE description IS NOT NULL;
    
        RETURN l_ret;
    END get_composition_hist;

    FUNCTION get_diagnosis_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_ret
          FROM (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                  i_id_diagnosis        => d.id_diagnosis,
                                                  i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                  i_code                => d.code_icd,
                                                  i_flg_other           => d.flg_other,
                                                  i_flg_std_diag        => pk_alert_constant.g_yes,
                                                  i_epis_diag           => ed.id_epis_diagnosis) description
                  FROM mcdt_req_diagnosis mrd
                  JOIN epis_diagnosis ed
                    ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
                  JOIN diagnosis d
                    ON d.id_diagnosis = mrd.id_diagnosis
                 WHERE mrd.id_nurse_tea_req = i_nurse_tea_req
                   AND nvl(mrd.flg_status, 'z') = pk_diagnosis.g_mcdt_cancel)
         WHERE description IS NOT NULL;
    
        RETURN l_ret;
    END get_diagnosis_cancel;

    --
    FUNCTION get_id_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_number IS
        l_ret               table_number;
        l_nurse_tea_req_max nurse_tea_req.id_nurse_tea_req%TYPE;
    BEGIN
    
        SELECT MAX(ntrd.id_nurse_tea_req_hist)
          INTO l_nurse_tea_req_max
          FROM nurse_tea_req_diag_hist ntrd
         WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req;
    
        SELECT id
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntrd.id_composition id
                  FROM nurse_tea_req_diag_hist ntrd
                 WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                   AND ntrd.id_composition IS NOT NULL
                   AND ntrd.id_nurse_tea_req_hist = l_nurse_tea_req_max
                UNION ALL
                SELECT ntrd.id_nan_diagnosis id
                  FROM nurse_tea_req_diag_hist ntrd
                 WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                   AND ntrd.id_nan_diagnosis IS NOT NULL
                UNION ALL
                SELECT d.id_diagnosis id
                  FROM diagnosis d
                 WHERE d.id_diagnosis IN
                       (SELECT /*+opt_estimate(table t rows=1)*/
                         t.column_value id_nnn_epis_diagnosis
                          FROM TABLE(pk_diagnosis.concat_diag_id(i_lang, NULL, NULL, NULL, i_prof, 'D', i_nurse_tea_req)) t)
                 ORDER BY id);
    
        RETURN l_ret;
    END get_id_diagnosis;

    FUNCTION get_desc_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_varchar IS
    
        l_ret               table_varchar;
        l_nurse_tea_req_max nurse_tea_req.id_nurse_tea_req%TYPE;
    
    BEGIN
    
        SELECT MAX(ntrd.id_nurse_tea_req_hist)
          INTO l_nurse_tea_req_max
          FROM nurse_tea_req_diag_hist ntrd
         WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req;
    
        SELECT description
          BULK COLLECT
          INTO l_ret
          FROM (SELECT description
                  FROM (SELECT DISTINCT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_alert_diagnosis  => nvl(ed.id_alert_diagnosis,
                                                                                                mrd.id_alert_diagnosis),
                                                                   i_id_diagnosis        => d.id_diagnosis,
                                                                   i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                   i_code                => d.code_icd,
                                                                   i_flg_other           => d.flg_other,
                                                                   i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                   i_epis_diag           => ed.id_epis_diagnosis) description,
                                        d.id_diagnosis id
                          FROM mcdt_req_diagnosis mrd
                          LEFT JOIN epis_diagnosis ed
                            ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
                          JOIN diagnosis d
                            ON d.id_diagnosis = mrd.id_diagnosis
                         WHERE mrd.id_nurse_tea_req = i_nurse_tea_req
                           AND nvl(mrd.flg_status, 'z') != 'C'
                        UNION ALL
                        SELECT DISTINCT pk_translation.get_translation(i_lang, ic.code_icnp_composition) description,
                                        ntrd.id_composition id
                          FROM nurse_tea_req_diag_hist ntrd
                          JOIN icnp_composition ic
                            ON ic.id_composition = ntrd.id_composition
                         WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                           AND ntrd.id_composition IS NOT NULL
                           AND ntrd.id_nurse_tea_req_hist = l_nurse_tea_req_max
                        UNION ALL
                        SELECT pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ntrd.id_nan_diagnosis,
                                                                   i_code_format   => pk_nan_model.g_code_format_end) description,
                               ntrd.id_nan_diagnosis id
                          FROM nurse_tea_req_diag_hist ntrd
                         WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                           AND ntrd.id_nan_diagnosis IS NOT NULL
                           AND ntrd.id_nurse_tea_req_hist = l_nurse_tea_req_max)
                 ORDER BY id)
         WHERE description IS NOT NULL;
    
        RETURN l_ret;
    END get_desc_diagnosis;

    FUNCTION get_nurse_teach_topic_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN VARCHAR2 IS
        l_nurse_teach_title VARCHAR2(1000 CHAR);
    BEGIN
    
        g_error := 'get nurse teach topic title';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) title_topic
          INTO l_nurse_teach_title
          FROM nurse_tea_topic ntt
         WHERE ntt.id_nurse_tea_topic = i_nurse_tea_topic;
    
        RETURN l_nurse_teach_title;
    
    END get_nurse_teach_topic_title;

    FUNCTION get_subject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB IS
        l_ret CLOB;
    BEGIN
    
        IF i_id_topic IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- Patient education subject
        SELECT pk_translation_lob.get_translation(i_lang, ntt.code_topic_description)
          INTO l_ret
          FROM nurse_tea_topic ntt
          JOIN nurse_tea_subject nts
            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
           AND ntt.id_nurse_tea_topic = i_id_topic;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_subject;

BEGIN

    NULL;

END pk_patient_education_utils;
/
