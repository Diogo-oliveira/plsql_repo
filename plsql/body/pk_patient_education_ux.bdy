/*-- Last Change Revision: $Rev: 2027464 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_education_ux IS

    --
    PROCEDURE insert_ntr_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_rec  nurse_tea_req_hist%ROWTYPE;
        l_rows table_varchar;
    BEGIN
        g_error := 'Get NURSE_TEA_REQ data';
        SELECT ts_nurse_tea_req_hist.next_key,
               ntr.id_nurse_tea_req,
               ntr.id_prof_req,
               ntr.id_episode,
               ntr.req_header,
               ntr.flg_status,
               ntr.notes_req,
               ntr.id_prof_close,
               ntr.notes_close,
               ntr.id_prof_exec,
               ntr.id_prev_episode,
               ntr.dt_nurse_tea_req_tstz,
               ntr.dt_begin_tstz,
               ntr.dt_close_tstz,
               ntr.id_visit,
               ntr.id_patient,
               ntr.status_flg,
               ntr.status_icon,
               ntr.status_msg,
               ntr.status_str,
               ntr.create_user,
               ntr.create_time,
               ntr.create_institution,
               ntr.update_user,
               ntr.update_time,
               ntr.update_institution,
               ntr.id_cancel_reason,
               ntr.id_context,
               ntr.flg_context,
               ntr.id_nurse_tea_topic,
               ntr.id_order_recurr_plan,
               ntr.description,
               ntr.flg_time,
               current_timestamp,
               ntr.desc_topic_aux,
               ntr.id_not_order_reason
          INTO l_rec
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        g_error := 'Insert into history table';
        ts_nurse_tea_req_hist.ins(rec_in => l_rec, rows_out => l_rows);
    
        g_error := 'Process insert on NURSE_TEA_REQ_HIST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ_HIST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_NTR_HIST',
                                              o_error);
    END insert_ntr_hist;

    --
    PROCEDURE update_ntr_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_req_status nurse_tea_req.flg_status%TYPE;
        l_rows       table_varchar;
    BEGIN
        SELECT decode(COUNT(*), 0, g_nurse_tea_req_fin, g_nurse_tea_req_act)
          INTO l_req_status
          FROM nurse_tea_det
         WHERE id_nurse_tea_req = i_id_nurse_tea_req
           AND flg_status = g_nurse_tea_req_pend;
    
        insert_ntr_hist(i_lang             => i_lang,
                        i_prof             => i_prof,
                        i_id_nurse_tea_req => i_id_nurse_tea_req,
                        o_error            => o_error);
    
        ts_nurse_tea_req.upd(id_nurse_tea_req_in => i_id_nurse_tea_req,
                             flg_status_in       => l_req_status,
                             rows_out            => l_rows);
    
        g_error := 'Process insert';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_NTR_STATUS',
                                              o_error);
    END update_ntr_status;
    --
    FUNCTION check_params
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_time   IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_duration   IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        o_params     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_na sys_message.desc_message%TYPE;
    
    BEGIN
        l_na := pk_message.get_message(i_lang, 'COMMON_M018');
    
        OPEN o_params FOR
            SELECT decode(i_flg_time, g_flg_time_next, pk_alert_constant.g_no, pk_alert_constant.g_yes) edit_start_date,
                   decode(i_flg_time, g_flg_time_next, pk_alert_constant.g_no, pk_alert_constant.g_yes) edit_duration,
                   decode(i_flg_time, g_flg_time_next, pk_alert_constant.g_no, pk_alert_constant.g_yes) edit_end_date,
                   decode(i_flg_time, g_flg_time_next, l_na, i_start_date) param_start_date,
                   decode(i_flg_time,
                          g_flg_time_next,
                          l_na,
                          pk_date_utils.get_timestamp_diff(trunc(pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               i_end_date,
                                                                                               NULL),
                                                                 'mi'),
                                                           trunc(pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               i_start_date,
                                                                                               NULL),
                                                                 'mi')) * 24 * 60) param_duration,
                   decode(i_flg_time, g_flg_time_next, l_na, i_end_date) param_end_date
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_params);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PARAMS',
                                              o_error);
    END check_params;

    --
    PROCEDURE create_suggestion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_topic IN table_number,
        i_trig_by            IN table_clob,
        i_id_context         IN nurse_tea_req.id_context%TYPE,
        o_id_nurse_tea_req   OUT table_number
    ) IS
        l_description        pk_translation.t_desc_translation;
        l_next               nurse_tea_req.id_nurse_tea_req%TYPE;
        l_rows_ntr           table_varchar := table_varchar();
        l_rows               table_varchar := table_varchar();
        l_id_nurse_tea_req   table_number := table_number();
        l_id_nurse_tea_topic table_number := table_number();
        l_error              t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT id_nurse_tea_topic
          BULK COLLECT
          INTO l_id_nurse_tea_topic
          FROM (SELECT column_value id_nurse_tea_topic
                  FROM TABLE(i_id_nurse_tea_topic)
                MINUS
                SELECT ntr.id_nurse_tea_topic
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_episode = i_id_episode
                   AND ntr.flg_status = g_nurse_tea_req_sug
                   AND EXISTS (SELECT column_value
                          FROM TABLE(i_id_nurse_tea_topic)
                         WHERE ntr.id_nurse_tea_topic = column_value));
    
        FOR i IN 1 .. l_id_nurse_tea_topic.count
        LOOP
            SELECT pk_translation.get_translation(i_lang, ntt.code_topic_description)
              INTO l_description
              FROM nurse_tea_topic ntt
             WHERE ntt.id_nurse_tea_topic = i_id_nurse_tea_topic(i);
        
            l_next := ts_nurse_tea_req.next_key;
        
            g_error := 'Insert suggestion';
            ts_nurse_tea_req.ins(id_nurse_tea_req_in      => l_next,
                                 id_prof_req_in           => i_prof.id,
                                 id_episode_in            => i_id_episode,
                                 flg_status_in            => g_nurse_tea_req_sug,
                                 dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                 id_visit_in              => pk_episode.get_id_visit(i_id_episode),
                                 id_patient_in            => pk_episode.get_id_patient(i_id_episode),
                                 id_context_in            => i_id_context,
                                 id_nurse_tea_topic_in    => l_id_nurse_tea_topic(i),
                                 description_in           => l_description,
                                 rows_out                 => l_rows_ntr);
        
            insert_ntr_hist(i_lang => i_lang, i_prof => i_prof, i_id_nurse_tea_req => l_next, o_error => l_error);
        
            l_rows := l_rows MULTISET UNION l_rows_ntr;
        
            l_id_nurse_tea_req.extend;
            l_id_nurse_tea_req(i) := l_next;
        
            g_error := 'INSERT LOG ON TI_LOG';
            IF NOT t_ti_log.ins_log(i_lang, i_prof, i_id_episode, g_nurse_tea_req_sug, l_next, 'NT', l_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        g_error := 'Process insert on NURSE_TEA_REQ';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => l_error);
    
        o_id_nurse_tea_req := l_id_nurse_tea_req;
    
    END create_suggestion;

    --
    FUNCTION create_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_diagnoses             IN table_clob,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2 DEFAULT 'N',
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_not_order_reason      IN table_number,
        o_id_nurse_tea_req      OUT table_number,
        o_id_nurse_tea_topic    OUT table_number,
        o_title_topic           OUT table_varchar,
        o_desc_diagnosis        OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init create_request / i_id_episode=' || i_id_episode || ' i_draft=' || i_draft;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_patient_education_db.create_request(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_id_episode            => i_id_episode,
                                                      i_topics                => i_topics,
                                                      i_compositions          => i_compositions,
                                                      i_to_be_performed       => i_to_be_performed,
                                                      i_start_date            => i_start_date,
                                                      i_notes                 => i_notes,
                                                      i_description           => i_description,
                                                      i_order_recurr          => i_order_recurr,
                                                      i_draft                 => i_draft,
                                                      i_id_nurse_tea_req_sugg => i_id_nurse_tea_req_sugg,
                                                      i_desc_topic_aux        => i_desc_topic_aux,
                                                      i_diagnoses             => i_diagnoses,
                                                      i_not_order_reason      => i_not_order_reason,
                                                      o_id_nurse_tea_req      => o_id_nurse_tea_req,
                                                      o_id_nurse_tea_topic    => o_id_nurse_tea_topic,
                                                      o_title_topic           => o_title_topic,
                                                      o_desc_diagnosis        => o_desc_diagnosis,
                                                      o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_REQUEST',
                                              o_error);
        
            RETURN FALSE;
    END create_request;

    FUNCTION create_request
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_draft                IN VARCHAR2 DEFAULT 'N',
        i_topics               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_flg_edition          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_nurse_tea_req    IN table_number DEFAULT NULL,
        o_id_nurse_tea_req     OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prof_req       nurse_tea_req.id_prof_req%TYPE;
        l_prof_req_category category.flg_type%TYPE;
    
        l_tbl_compositions          table_table_number := table_table_number();
        l_tbl_diagnoses             table_clob := table_clob();
        l_tbl_to_be_performed       table_varchar := table_varchar();
        l_tbl_start_date            table_varchar := table_varchar();
        l_tbl_notes                 table_varchar := table_varchar();
        l_tbl_description           table_clob := table_clob();
        l_tbl_order_recurr          table_number := table_number();
        l_tbl_id_nurse_tea_req_sugg table_number := table_number();
        l_tbl_desc_topic_aux        table_varchar := table_varchar();
        l_tbl_not_order_reason      table_number := table_number();
    
        l_id_patient             patient.id_patient%TYPE;
        l_tbl_id_diagnosis       table_number := table_number();
        l_tbl_id_alert_diagnosis table_number := table_number();
    
        l_diag_type VARCHAR2(1) := NULL;
    
        --o_id_nurse_tea_req   table_number;
        o_id_nurse_tea_topic table_number;
        o_title_topic        table_varchar;
        o_desc_diagnosis     table_varchar;
    
    BEGIN
        g_error := 'Init create_request / i_id_episode=' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) NOT IN
               (pk_orders_constant.g_ds_clinical_indication_mw, pk_orders_constant.g_ds_clinical_indication_icnp_mw)
            THEN
                FOR j IN i_topics.first .. i_topics.last
                LOOP
                    IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_to_be_executed
                    THEN
                        l_tbl_to_be_performed.extend();
                        l_tbl_to_be_performed(l_tbl_to_be_performed.count) := i_tbl_real_val(i) (j);
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_start_date
                    THEN
                        l_tbl_start_date.extend();
                        l_tbl_start_date(l_tbl_start_date.count) := i_tbl_real_val(i) (j);
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_notes_clob
                    THEN
                        l_tbl_notes.extend();
                        l_tbl_notes(l_tbl_notes.count) := to_char(i_tbl_val_clob(i) (j)); --pk_patient_education_db.create_request is expecting varchar
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_description
                    THEN
                        l_tbl_description.extend();
                        l_tbl_description(l_tbl_description.count) := i_tbl_val_clob(i) (j);
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_dummy_number
                    THEN
                        l_tbl_order_recurr.extend();
                        l_tbl_order_recurr(l_tbl_order_recurr.count) := to_number(i_tbl_real_val(i) (j));
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_clinical_indication_mw
            THEN
                FOR j IN i_topics.first .. i_topics.last
                LOOP
                    IF i_flg_edition = 'N'
                    THEN
                        --If this is a new request, we can assure that the content of this field is indeed Diagnosis,
                        --because this field is not available for the Nurse profile
                        l_diag_type := 'D';
                    ELSE
                        --When editing, it is necessary to check if the original request has been made by a nurse or
                        --by a phisician. If it was by a nurse, the content of this field is ICNP and not diagnosis
                    
                        SELECT t.id_prof_req
                          INTO l_id_prof_req
                          FROM (SELECT ntrh.id_prof_req,
                                       row_number() over(PARTITION BY ntrh.id_nurse_tea_req ORDER BY ntrh.dt_nurse_tea_req_tstz) AS rn
                                  FROM nurse_tea_req_hist ntrh
                                 WHERE ntrh.id_nurse_tea_req = i_tbl_nurse_tea_req(j)
                                   AND ntrh.flg_status = 'D') t
                         WHERE t.rn = 1;
                    
                        l_prof_req_category := pk_prof_utils.get_category(i_lang,
                                                                          profissional(l_id_prof_req,
                                                                                       i_prof.institution,
                                                                                       i_prof.software));
                    
                        IF l_prof_req_category = 'N'
                        THEN
                            l_diag_type := 'C'; --ICNP (Composition)
                        ELSE
                            l_diag_type := 'D'; --DIAGNOSIS
                        END IF;
                    END IF;
                
                    IF l_diag_type = 'D' --We may only create the XML when deailing with diagnosis
                    THEN
                        l_tbl_id_diagnosis       := table_number();
                        l_tbl_id_alert_diagnosis := table_number();
                    
                        SELECT ad.id_diagnosis, ad.id_alert_diagnosis
                          BULK COLLECT
                          INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
                          FROM alert_diagnosis ad
                         WHERE ad.id_alert_diagnosis IN (SELECT *
                                                           FROM TABLE(i_tbl_val_array(i) (j)));
                    
                        IF l_tbl_id_diagnosis.count > 0
                        THEN
                        
                            l_tbl_diagnoses.extend();
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := '<EPIS_DIAGNOSES ID_PATIENT="' || l_id_patient ||
                                                                      '" ID_EPISODE="' || i_id_episode ||
                                                                      '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
                        
                            FOR k IN l_tbl_id_diagnosis.first .. l_tbl_id_diagnosis.last
                            LOOP
                                l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                          ' <DIAGNOSIS ID_DIAGNOSIS="' ||
                                                                          l_tbl_id_diagnosis(k) || '" ID_ALERT_DIAG="' ||
                                                                          l_tbl_id_alert_diagnosis(k) || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                            END LOOP;
                        
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                      ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
                        ELSE
                            l_tbl_diagnoses.extend();
                        END IF;
                    ELSE
                        IF i_tbl_val_array(i).count > 0
                        THEN
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                            FOR k IN i_tbl_val_array(i)(j).first .. i_tbl_val_array(i)(j).last
                            LOOP
                                l_tbl_compositions(l_tbl_compositions.count).extend();
                                l_tbl_compositions(l_tbl_compositions.count)(k) := to_number(i_tbl_val_array(i) (j) (k));
                            END LOOP;
                        ELSE
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                        END IF;
                    
                        l_tbl_diagnoses.extend(); --To maintain consistency in pk_patient_education_ux
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_clinical_indication_icnp_mw
            THEN
                FOR j IN i_topics.first .. i_topics.last
                LOOP
                    IF i_flg_edition = 'N'
                    THEN
                        --If this is a new request, we can assure that the content of this field is indeed ICNP,
                        --because this field is not available for the Nurse profile
                        l_diag_type := 'C';
                    ELSE
                        --When editing, it is necessary to check if the original request has been made by a nurse or
                        --by a phisician. If it was by a nurse, the content of this field is ICNP and not diagnosis
                        SELECT t.id_prof_req
                          INTO l_id_prof_req
                          FROM (SELECT ntrh.id_prof_req,
                                       row_number() over(PARTITION BY ntrh.id_nurse_tea_req ORDER BY ntrh.dt_nurse_tea_req_tstz) AS rn
                                  FROM nurse_tea_req_hist ntrh
                                 WHERE ntrh.id_nurse_tea_req = i_tbl_nurse_tea_req(j)
                                   AND ntrh.flg_status = 'D') t
                         WHERE t.rn = 1;
                    
                        l_prof_req_category := pk_prof_utils.get_category(i_lang,
                                                                          profissional(l_id_prof_req,
                                                                                       i_prof.institution,
                                                                                       i_prof.software));
                    
                        IF l_prof_req_category = 'N'
                        THEN
                            l_diag_type := 'C'; --ICNP (Composition)
                        ELSE
                            l_diag_type := 'D'; --DIAGNOSIS
                        END IF;
                    END IF;
                
                    IF l_diag_type = 'C'
                    THEN
                        IF i_tbl_val_array(i).count > 0
                        THEN
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                            FOR k IN i_tbl_val_array(i)(j).first .. i_tbl_val_array(i)(j).last
                            LOOP
                                l_tbl_compositions(l_tbl_compositions.count).extend();
                                l_tbl_compositions(l_tbl_compositions.count)(k) := to_number(i_tbl_val_array(i) (j) (k));
                            END LOOP;
                        ELSE
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                        END IF;
                    
                        l_tbl_diagnoses.extend(); --To maintain consistency in pk_patient_education_ux
                    ELSE
                        l_tbl_compositions.extend();
                        l_tbl_compositions(l_tbl_compositions.count) := table_number();
                    
                        l_tbl_id_diagnosis       := table_number();
                        l_tbl_id_alert_diagnosis := table_number();
                    
                        SELECT ad.id_diagnosis, ad.id_alert_diagnosis
                          BULK COLLECT
                          INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
                          FROM alert_diagnosis ad
                         WHERE ad.id_alert_diagnosis IN (SELECT *
                                                           FROM TABLE(i_tbl_val_array(i) (j)));
                    
                        IF l_tbl_id_diagnosis.count > 0
                        THEN
                        
                            l_tbl_diagnoses.extend();
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := '<EPIS_DIAGNOSES ID_PATIENT="' || l_id_patient ||
                                                                      '" ID_EPISODE="' || i_id_episode ||
                                                                      '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
                        
                            FOR k IN l_tbl_id_diagnosis.first .. l_tbl_id_diagnosis.last
                            LOOP
                                l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                          ' <DIAGNOSIS ID_DIAGNOSIS="' ||
                                                                          l_tbl_id_diagnosis(k) || '" ID_ALERT_DIAG="' ||
                                                                          l_tbl_id_alert_diagnosis(k) || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                            END LOOP;
                        
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                      ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
                        ELSE
                            l_tbl_diagnoses.extend();
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            l_tbl_id_nurse_tea_req_sugg.extend();
            l_tbl_desc_topic_aux.extend();
            l_tbl_not_order_reason.extend();
        END LOOP;
    
        IF i_flg_edition = pk_alert_constant.g_no
        THEN
            IF NOT pk_patient_education_db.create_request(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => i_id_episode,
                                                          i_topics                => i_topics,
                                                          i_compositions          => l_tbl_compositions,
                                                          i_to_be_performed       => l_tbl_to_be_performed,
                                                          i_start_date            => l_tbl_start_date,
                                                          i_notes                 => l_tbl_notes,
                                                          i_description           => l_tbl_description,
                                                          i_order_recurr          => l_tbl_order_recurr,
                                                          i_draft                 => i_draft,
                                                          i_id_nurse_tea_req_sugg => l_tbl_id_nurse_tea_req_sugg,
                                                          i_desc_topic_aux        => l_tbl_desc_topic_aux,
                                                          i_diagnoses             => l_tbl_diagnoses,
                                                          i_not_order_reason      => l_tbl_not_order_reason,
                                                          o_id_nurse_tea_req      => o_id_nurse_tea_req,
                                                          o_id_nurse_tea_topic    => o_id_nurse_tea_topic,
                                                          o_title_topic           => o_title_topic,
                                                          o_desc_diagnosis        => o_desc_diagnosis,
                                                          o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_patient_education_db.update_request(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_episode       => i_id_episode,
                                                          i_id_nurse_tea_req => i_tbl_nurse_tea_req,
                                                          i_topics           => i_topics,
                                                          i_compositions     => l_tbl_compositions,
                                                          i_to_be_performed  => l_tbl_to_be_performed,
                                                          i_start_date       => l_tbl_start_date,
                                                          i_notes            => l_tbl_notes,
                                                          i_description      => l_tbl_description,
                                                          i_order_recurr     => l_tbl_order_recurr,
                                                          i_upd_flg_status   => pk_alert_constant.g_yes,
                                                          i_diagnoses        => l_tbl_diagnoses,
                                                          i_not_order_reason => l_tbl_not_order_reason,
                                                          o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_REQUEST',
                                              o_error);
        
            RETURN FALSE;
    END create_request;
    --
    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Cancel patient education';
        FOR i IN 1 .. i_id_nurse_tea_req.count
        LOOP
        
            IF NOT pk_patient_education_db.cancel_nurse_tea_req_int(i_lang             => i_lang,
                                                                    i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                    i_prof_close       => i_prof,
                                                                    i_notes_close      => i_cancel_notes,
                                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                                    i_flg_commit       => pk_alert_constant.g_yes,
                                                                    o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Add to history';
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PATIENT_EDUCATION',
                                              o_error);
        
            RETURN FALSE;
    END cancel_patient_education;

    --
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
                                                  i_flg_std_diag        => g_yes,
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
                                                                   i_flg_std_diag        => g_yes,
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

    --
    --
    FUNCTION get_domain_flg_time
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_values OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_time        sys_config.value%TYPE;
        l_flg_time_no_lst table_varchar;
    BEGIN
        g_error           := 'Return domain values';
        l_flg_time        := pk_sysconfig.get_config('FLG_TIME_P', i_prof.institution, i_prof.software);
        l_flg_time_no_lst := pk_string_utils.str_split(pk_sysconfig.get_config('FLG_TIME_NO_LIST', i_prof), '|');
    
        OPEN o_values FOR
            SELECT desc_val label,
                   val data,
                   img_name,
                   rank,
                   decode(l_flg_time, val, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_sys_domain_flg_time, NULL))
             WHERE val NOT IN (SELECT column_value
                                 FROM TABLE(l_flg_time_no_lst));
    
        RETURN TRUE;
    
    END get_domain_flg_time;

    FUNCTION get_domain_flg_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
    
        l_flg_time        sys_config.value%TYPE;
        l_flg_time_no_lst table_varchar;
    
        l_ret t_tbl_core_domain := t_tbl_core_domain();
    BEGIN
        g_error           := 'Return domain values';
        l_flg_time        := pk_sysconfig.get_config('FLG_TIME_P', i_prof.institution, i_prof.software);
        l_flg_time_no_lst := pk_string_utils.str_split(pk_sysconfig.get_config('FLG_TIME_NO_LIST', i_prof), '|');
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT desc_val label, val data, img_name, rank
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_sys_domain_flg_time, NULL))
                 WHERE val NOT IN (SELECT column_value
                                     FROM TABLE(l_flg_time_no_lst)));
    
        RETURN l_ret;
    
    END get_domain_flg_time;

    FUNCTION get_default_domain_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_val      OUT VARCHAR2,
        o_desc_val OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_val    VARCHAR2(200);
        l_val         VARCHAR2(30);
        l_img_name    VARCHAR2(200);
        l_rank        NUMBER(6);
        l_flg_default VARCHAR2(200);
    
        l_values pk_types.cursor_type;
    BEGIN
    
        IF NOT pk_patient_education_ux.get_domain_flg_time(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           o_values => l_values,
                                                           o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        LOOP
            FETCH l_values
                INTO l_desc_val, l_val, l_img_name, l_rank, l_flg_default;
            EXIT WHEN l_values%NOTFOUND;
        
            IF l_flg_default = pk_alert_constant.g_yes
            THEN
                EXIT;
            END IF;
        END LOOP;
    
        IF l_flg_default = pk_alert_constant.g_yes
        THEN
            o_val      := l_val;
            o_desc_val := l_desc_val;
        END IF;
    
        RETURN TRUE;
    
    END get_default_domain_time;

    --
    FUNCTION get_request_for_update
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_detail FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             ntr.id_nurse_tea_req,
             ntr.id_nurse_tea_topic id_topic,
             pk_patient_education_db.get_desc_topic(i_lang,
                                                    i_prof,
                                                    ntr.id_nurse_tea_topic,
                                                    ntr.desc_topic_aux,
                                                    ntt.code_nurse_tea_topic) title_topic,
             pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
             get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication,
             get_id_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication_id,
             get_desc_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication_desc,
             ntr.flg_time to_be_performed,
             pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang) to_be_performed_desc,
             NULL executions,
             pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_begin_tstz, NULL) start_date,
             pk_date_utils.date_char(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) start_date_str,
             NULL duration,
             NULL end_date,
             NULL end_date_str,
             ntr.notes_req notes,
             --pk_string_utils.clob_to_plsqlvarchar2(ntr.description) desc_topic,
             ntr.description desc_topic,
             pk_patient_education_db.get_instructions(i_lang, i_prof, ntr.id_nurse_tea_req) instructions,
             ntr.id_order_recurr_plan req_plan_id,
             pk_diagnosis.concat_diag_id(i_lang, NULL, NULL, NULL, i_prof, 'S', ntr.id_nurse_tea_req) id_alert_diagnosis,
             pk_not_order_reason_db.get_not_order_reason_id(i_lang                => i_lang,
                                                            i_id_not_order_reason => ntr.id_not_order_reason) not_order_reason_id,
             pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                              i_not_order_reason => ntr.id_not_order_reason) not_order_reason_desc,
             ntr.flg_status
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              JOIN TABLE(i_id_nurse_tea_req) t
                ON t.column_value = ntr.id_nurse_tea_req;
    
        RETURN TRUE;
    
    END get_request_for_update;
    --
    FUNCTION get_patient_education_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_register         OUT pk_types.cursor_type,
        o_detail           OUT pk_types.cursor_type,
        o_main             OUT pk_types.cursor_type,
        o_data             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date_req VARCHAR2(4000);
    
        l_request_rank CONSTANT PLS_INTEGER := 0;
    
        l_patient_education_m026 sys_message.desc_message%TYPE;
        l_patient_education_m027 sys_message.desc_message%TYPE;
        l_patient_education_m029 sys_message.desc_message%TYPE;
        l_patient_education_m028 sys_message.desc_message%TYPE;
        l_patient_education_m030 sys_message.desc_message%TYPE;
        l_patient_education_m031 sys_message.desc_message%TYPE;
        l_patient_education_m041 sys_message.desc_message%TYPE;
        l_patient_education_m042 sys_message.desc_message%TYPE;
        l_patient_education_m045 sys_message.desc_message%TYPE;
        l_common_m130            sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- MENSAGENS
        l_patient_education_m026 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M026');
        l_patient_education_m027 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M027');
        l_patient_education_m028 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M028');
        l_patient_education_m029 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M029');
        l_patient_education_m030 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M030');
        l_patient_education_m031 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M031');
        l_patient_education_m041 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M041');
        l_patient_education_m042 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M042');
        l_patient_education_m045 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M045');
        l_common_m130            := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => pk_not_order_reason_db.g_mcode_not_ordered_label);
        OPEN o_register FOR
        -- DRAFT  (w/o hist)
            SELECT 'DRAFT' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_draft
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_draft)
            UNION ALL
            -- DRAFT (w/ hist)
            SELECT 'DRAFTH' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req_hist ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = g_nurse_tea_req_draft
            UNION ALL
            -- request (w/o hist)
            SELECT 'REQ' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_pend
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_pend)
            UNION ALL
            -- request (w/ hist)
            SELECT 'RQH' flg_type,
                   ntrh.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM nurse_tea_req_hist ntrh
             WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntrh.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                   FROM nurse_tea_req_hist
                                                  WHERE id_nurse_tea_req = ntrh.id_nurse_tea_req
                                                    AND flg_status = ntrh.flg_status)
               AND ntrh.flg_status = g_nurse_tea_req_pend
            -- cancelation
            UNION ALL
            SELECT 'CAN' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m027 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_close_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_close_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_close_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_canc
            UNION ALL
            SELECT 'DIS' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m045 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_close_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_close_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_close_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_descontinued
            -- suggestion (w/o hist)
            UNION ALL
            SELECT 'SUG' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m029 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_sug
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_sug)
            -- suggestion (w/ hist)
            UNION ALL
            SELECT 'SGH' flg_type,
                   ntrh.id_nurse_tea_req id,
                   l_patient_education_m029 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM nurse_tea_req_hist ntrh
             WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntrh.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                   FROM nurse_tea_req_hist
                                                  WHERE id_nurse_tea_req = ntrh.id_nurse_tea_req
                                                    AND flg_status = ntrh.flg_status)
               AND ntrh.flg_status = g_nurse_tea_req_sug
            -- ignored suggestion
            UNION ALL
            SELECT 'IGN' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m030 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_close id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_ign
            -- execution
            UNION ALL
            SELECT 'EXE' flg_type,
                   ntd.id_nurse_tea_det id,
                   l_patient_education_m028 title,
                   ntd.num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_nurse_tea_det_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntd.dt_nurse_tea_det_tstz, NULL) TIMESTAMP,
                   ntd.id_prof_provider id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntd.id_prof_provider,
                                                    ntd.dt_nurse_tea_det_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = g_nurse_tea_det_exec
            -- cancelled execution
            UNION ALL
            SELECT 'CEX' flg_type,
                   ntd.id_nurse_tea_det id,
                   l_patient_education_m031 title,
                   ntd.num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_nurse_tea_det_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntd.dt_nurse_tea_det_tstz, NULL) TIMESTAMP,
                   ntd.id_prof_provider id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntd.id_prof_provider,
                                                    ntd.dt_nurse_tea_det_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = g_nurse_tea_det_canc
            UNION ALL
            --edited
            SELECT 'EDTD' flg_type,
                   ntrh.id_nurse_tea_req_hist id,
                   l_patient_education_m041 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_hist_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_hist_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_hist_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM (SELECT id_nurse_tea_req_hist
                      FROM (SELECT ntr.id_nurse_tea_req_hist,
                                   lag(ntr.notes_req, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_notes_req,
                                   ntr.notes_req,
                                   --lag(ntr.c_description, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_description,
                                   --null prev_description,
                                   --ntr.c_description,
                                   lag(ntr.id_order_recurr_plan, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_order_recurr_plan,
                                   ntr.id_order_recurr_plan,
                                   lag(ntr.flg_time, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_flg_time,
                                   ntr.flg_time,
                                   lag(ntr.id_not_order_reason, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_not_order_reason,
                                   ntr.id_not_order_reason,
                                   ntr.diagnosis AS current_diag,
                                   lag(ntr.diagnosis, 1) over(ORDER BY ntr.id_nurse_tea_req_hist ASC) AS prev_diag
                              FROM (SELECT ntr.id_nurse_tea_req_hist,
                                           ntr.notes_req,
                                           --to_char(ntr.description) c_description,
                                           -- ntr.description c_description,
                                           ntr.id_order_recurr_plan,
                                           ntr.flg_time,
                                           ntr.id_not_order_reason,
                                           ntr.dt_nurse_tea_req_hist_tstz,
                                           dh.dt_nurse_tea_req_diag_tstz,
                                           listagg(dh.id_diagnosis, '|') within GROUP(ORDER BY dh.id_diagnosis ASC) AS diagnosis
                                      FROM nurse_tea_req_hist ntr
                                      LEFT JOIN nurse_tea_req_diag_hist dh
                                        ON dh.id_nurse_tea_req_hist = ntr.id_nurse_tea_req_hist
                                     WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                                     GROUP BY ntr.id_nurse_tea_req_hist,
                                              ntr.notes_req,
                                              --ntr.description,
                                              ntr.id_order_recurr_plan,
                                              ntr.flg_time,
                                              ntr.id_not_order_reason,
                                              dt_nurse_tea_req_hist_tstz,
                                              dh.dt_nurse_tea_req_diag_tstz) ntr)
                     WHERE (nvl(prev_notes_req, 'NULL') <> nvl(notes_req, 'NULL') OR
                           /* REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(prev_description), chr(13), ''),
                           chr(10),
                           '') <>
                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(c_description), chr(13), ''),
                           chr(10),
                           '') OR*/
                           nvl(id_order_recurr_plan, -1) <> nvl(prev_id_order_recurr_plan, -1) OR
                           nvl(flg_time, -1) <> nvl(prev_flg_time, -1) OR
                           (nvl(id_not_order_reason, -1) <> nvl(prev_id_not_order_reason, -1) AND
                           prev_id_not_order_reason IS NOT NULL) OR nvl(current_diag, -1) <> nvl(prev_diag, -1))
                       AND id_nurse_tea_req_hist <>
                           (SELECT MIN(ntr.id_nurse_tea_req_hist)
                              FROM nurse_tea_req_hist ntr
                             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req)
                    UNION
                    -- id_composition
                    SELECT z.id_nurse_tea_req_hist
                      FROM (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                   ntdh.id_nurse_tea_req,
                                   ntdh.id_nurse_tea_req_hist,
                                   listagg(get_composition_hist(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                           '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis1
                              FROM nurse_tea_req_diag_hist ntdh
                             WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                             GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) x
                      JOIN (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                  ntdh.id_nurse_tea_req,
                                  ntdh.id_nurse_tea_req_hist,
                                  listagg(get_composition_hist(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                          '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis2
                             FROM nurse_tea_req_diag_hist ntdh
                            WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                            GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) z
                        ON x.id_nurse_tea_req = z.id_nurse_tea_req
                       AND x.dt_nurse_tea_req_diag_tstz < z.dt_nurse_tea_req_diag_tstz
                     WHERE nvl(id_diagnosis1, 'NULL') != nvl(id_diagnosis2, 'NULL')) n
              JOIN nurse_tea_req_hist ntrh
                ON ntrh.id_nurse_tea_req_hist = n.id_nurse_tea_req_hist
            -- expired task
            UNION ALL
            SELECT 'EXP' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m042 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_close_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_close_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_close_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_expired
            -- not order reason
            UNION ALL
            SELECT 'NOR' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_common_m130 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_not_ord_reas
               AND NOT EXISTS
             (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_db.g_nurse_tea_req_not_ord_reas)
            -- not order reason (hist)
            UNION ALL
            SELECT 'NRH' flg_type,
                   ntrh.id_nurse_tea_req id,
                   l_common_m130 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM nurse_tea_req_hist ntrh
             WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntrh.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                   FROM nurse_tea_req_hist
                                                  WHERE id_nurse_tea_req = ntrh.id_nurse_tea_req
                                                    AND flg_status = ntrh.flg_status)
               AND ntrh.flg_status = pk_patient_education_db.g_nurse_tea_req_not_ord_reas
             ORDER BY TIMESTAMP DESC;
        --
    
        OPEN o_detail FOR
        -- DRAFT (w/o hist)
            SELECT 'DRAFT' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                  pk_patient_education_db.get_desc_topic(i_lang,
                                                                         i_prof,
                                                                         ntr.id_nurse_tea_topic,
                                                                         ntr.desc_topic_aux,
                                                                         ntt.code_nurse_tea_topic),
                                  get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                  pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                  nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                            i_prof,
                                                                                            ntr.id_order_recurr_plan),
                                      
                                      pk_translation.get_translation(i_lang,
                                                                     'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                  pk_date_utils.date_char_tsz(i_lang,
                                                              ntr.dt_begin_tstz,
                                                              i_prof.institution,
                                                              i_prof.software),
                                  ntr.notes_req,
                                  NULL,
                                  pk_message.get_message(i_lang,
                                                         CASE
                                                             WHEN ntr.flg_status = g_nurse_tea_req_fin THEN
                                                              'PATIENT_EDUCATION_M038'
                                                             WHEN ntr.flg_status = g_nurse_tea_req_pend THEN
                                                              CASE
                                                                  WHEN ntr.flg_time = g_flg_time_next THEN
                                                                   'PATIENT_EDUCATION_M036'
                                                                  WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                   'PATIENT_EDUCATION_M036'
                                                                  ELSE
                                                                   'PATIENT_EDUCATION_M043'
                                                              END
                                                             WHEN ntr.flg_status = g_nurse_tea_req_act THEN
                                                              'PATIENT_EDUCATION_M037'
                                                         END)) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_draft
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_draft)
            UNION ALL
            -- DRAFT (with hist)           
            SELECT 'DRAFTH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE
                                                            WHEN ntr.flg_status = g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN ntr.flg_status = g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN ntr.flg_status = g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                        END)) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = g_nurse_tea_req_draft
            UNION ALL
            -- request (w/o hist)
            SELECT 'REQ' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE
                                                            WHEN ntr.flg_status = g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN ntr.flg_status = g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN ntr.flg_status = g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                        END)) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status IN (g_nurse_tea_req_pend, g_nurse_tea_req_act, g_nurse_tea_req_fin)
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_pend)
            UNION ALL
            -- request (w/ hist)
            SELECT 'RQH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis_hist(i_lang, i_prof, ntr.id_nurse_tea_req_hist),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE ntr.flg_status
                                                            WHEN g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                            ELSE
                                                             NULL
                                                        END)) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = g_nurse_tea_req_pend
            -- cancelation
            UNION ALL
            SELECT 'CAN' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('CANCEL_REASON', 'CANCEL_NOTES') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M032'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M033')) label,
                   table_varchar(pk_translation.get_translation(i_lang, cr.code_cancel_reason), ntr.notes_close) data
              FROM nurse_tea_req ntr
              JOIN cancel_reason cr
                ON cr.id_cancel_reason = ntr.id_cancel_reason
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_canc
            UNION ALL
            SELECT 'DIS' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('CANCEL_REASON', 'CANCEL_NOTES') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M046'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M033')) label,
                   table_varchar(pk_translation.get_translation(i_lang, cr.code_cancel_reason), ntr.notes_close) data
              FROM nurse_tea_req ntr
              JOIN cancel_reason cr
                ON cr.id_cancel_reason = ntr.id_cancel_reason
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_descontinued
            -- suggestion (w/o hist)
            UNION ALL
            SELECT 'SUG' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_sug
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_sug)
            -- suggestion (w/ hist)
            UNION ALL
            SELECT 'SGH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MAX(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = g_nurse_tea_req_sug
            -- execution
            UNION ALL
            SELECT 'EXE' flg_type,
                   ntd.id_nurse_tea_det id,
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
                            OR ntr.flg_status = g_nurse_tea_req_act THEN
                        table_varchar('CLINICAL_INDICATION',
                                      'GOALS',
                                      'METHOD',
                                      'GIVEN_TO',
                                      'DELIVERABLES',
                                      'UNDERSTANDING',
                                      'START_DATE',
                                      'DURATION',
                                      'END_DATE',
                                      'DESCRIPTION',
                                      'STATUS')
                       ELSE
                        table_varchar('CLINICAL_INDICATION',
                                      'GOALS',
                                      'METHOD',
                                      'GIVEN_TO',
                                      'DELIVERABLES',
                                      'UNDERSTANDING',
                                      'START_DATE',
                                      'DURATION',
                                      'END_DATE',
                                      'DESCRIPTION')
                   END code,
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
                            OR ntr.flg_status = g_nurse_tea_req_act THEN
                        table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M015'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M016'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M017'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M018'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M019'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M020'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M021'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M022'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M023'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M024'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'))
                       ELSE
                        table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M015'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M016'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M017'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M018'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M019'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M020'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M021'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M022'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M023'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M024'))
                   END label,
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
                            OR ntr.flg_status = g_nurse_tea_req_act THEN
                        table_varchar(get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GOALS'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'METHOD'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GIVEN_TO'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'DELIVERABLES'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'LEVEL_OF_UNDERSTANDING'),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof),
                                      nvl2(ntd.duration,
                                           ntd.duration || ' ' ||
                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                        i_prof,
                                                                                        ntd.id_unit_meas_duration),
                                           NULL),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof),
                                      
                                      NULL,
                                      pk_message.get_message(i_lang,
                                                             CASE ntr.flg_status
                                                                 WHEN g_nurse_tea_req_fin THEN
                                                                  'PATIENT_EDUCATION_M038'
                                                                 WHEN g_nurse_tea_req_pend THEN
                                                                  CASE
                                                                      WHEN ntr.flg_time = g_flg_time_next THEN
                                                                       'PATIENT_EDUCATION_M036'
                                                                      WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                       'PATIENT_EDUCATION_M036'
                                                                      ELSE
                                                                       'PATIENT_EDUCATION_M043'
                                                                  END
                                                                 WHEN g_nurse_tea_req_act THEN
                                                                  'PATIENT_EDUCATION_M044'
                                                                 ELSE
                                                                  NULL
                                                             END))
                       ELSE
                        table_varchar(get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GOALS'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'METHOD'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GIVEN_TO'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'DELIVERABLES'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'LEVEL_OF_UNDERSTANDING'),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof),
                                      nvl2(ntd.duration,
                                           ntd.duration || ' ' ||
                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                        i_prof,
                                                                                        ntd.id_unit_meas_duration),
                                           NULL),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof),
                                      NULL)
                   END data
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = g_nurse_tea_det_exec
            -- cancelled execution
            UNION ALL
            SELECT 'CEX' flg_type,
                   ntd.id_nurse_tea_det id,
                   table_varchar('START_DATE', 'END_DATE', 'PROVIDER') code,
                   table_varchar('Data de inicío:', 'Data de fim:', 'Provider:') label,
                   table_varchar(pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof),
                                 pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider)) data
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = g_nurse_tea_det_canc
            UNION ALL
            --edited
            SELECT 'EDTD' flg_type,
                   ntr.id_nurse_tea_req_hist id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS',
                                 'NOT_ORDER_REASON') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'),
                                 pk_message.get_message(i_lang, pk_not_order_reason_db.g_mcode_reas_not_order)) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis_hist(i_lang, i_prof, ntr.id_nurse_tea_req_hist),
                                 pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_TIME', ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE ntr.flg_status
                                                            WHEN g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                            WHEN pk_patient_education_db.g_nurse_tea_req_not_ord_reas THEN
                                                             pk_not_order_reason_db.g_mcode_not_ordered_data
                                                            ELSE
                                                             NULL
                                                        END),
                                 decode(ntr.id_not_order_reason,
                                        NULL,
                                        NULL,
                                        pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                                         i_not_order_reason => ntr.id_not_order_reason))) data
              FROM (SELECT id_nurse_tea_req_hist
                      FROM (SELECT ntr.id_nurse_tea_req_hist,
                                   lag(ntr.notes_req, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_notes_req,
                                   ntr.notes_req,
                                   --lag(pk_string_utils.clob_to_plsqlvarchar2(ntr.description), 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_description,
                                   --null prev_description,
                                   --ntr.description,
                                   lag(ntr.id_order_recurr_plan, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_order_recurr_plan,
                                   ntr.id_order_recurr_plan,
                                   lag(ntr.flg_time, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_flg_time,
                                   ntr.flg_time,
                                   lag(ntr.id_not_order_reason, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_not_order_reason,
                                   ntr.id_not_order_reason,
                                   ntr.diagnosis AS current_diag,
                                   lag(ntr.diagnosis, 1) over(ORDER BY ntr.id_nurse_tea_req_hist ASC) AS prev_diag
                              FROM (SELECT ntr.id_nurse_tea_req_hist,
                                           ntr.notes_req,
                                           --ntr.description description,
                                           ntr.id_order_recurr_plan,
                                           ntr.flg_time,
                                           ntr.id_not_order_reason,
                                           ntr.dt_nurse_tea_req_hist_tstz,
                                           dh.dt_nurse_tea_req_diag_tstz,
                                           listagg(dh.id_diagnosis, '|') within GROUP(ORDER BY dh.id_diagnosis ASC) AS diagnosis
                                      FROM nurse_tea_req_hist ntr
                                      LEFT JOIN nurse_tea_req_diag_hist dh
                                        ON dh.id_nurse_tea_req_hist = ntr.id_nurse_tea_req_hist --LEFT porque os registos antigos não têm entrada
                                     WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                                     GROUP BY ntr.id_nurse_tea_req_hist,
                                              ntr.notes_req,
                                              --ntr.description,
                                              ntr.id_order_recurr_plan,
                                              ntr.flg_time,
                                              ntr.id_not_order_reason,
                                              dt_nurse_tea_req_hist_tstz,
                                              dh.dt_nurse_tea_req_diag_tstz) ntr)
                     WHERE (nvl(prev_notes_req, 'NULL') <> nvl(notes_req, 'NULL') OR
                           /*                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(prev_description), chr(13), ''),
                           chr(10),
                           '') <>
                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(description), chr(13), ''),
                           chr(10),
                           '') OR*/
                           nvl(id_order_recurr_plan, -1) <> nvl(prev_id_order_recurr_plan, -1) OR
                           nvl(flg_time, -1) <> nvl(prev_flg_time, -1) OR
                           (nvl(id_not_order_reason, -1) <> nvl(prev_id_not_order_reason, -1) AND
                           prev_id_not_order_reason IS NOT NULL) OR nvl(current_diag, -1) <> nvl(prev_diag, -1))
                       AND id_nurse_tea_req_hist <>
                           (SELECT MIN(ntr.id_nurse_tea_req_hist)
                              FROM nurse_tea_req_hist ntr
                             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req)
                    UNION
                    -- id_composition
                    SELECT z.id_nurse_tea_req_hist
                      FROM (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                   ntdh.id_nurse_tea_req,
                                   ntdh.id_nurse_tea_req_hist,
                                   listagg(get_composition_hist(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                           '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis1
                              FROM nurse_tea_req_diag_hist ntdh
                             WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                             GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) x
                      JOIN (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                  ntdh.id_nurse_tea_req,
                                  ntdh.id_nurse_tea_req_hist,
                                  listagg(get_composition_hist(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                          '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis2
                             FROM nurse_tea_req_diag_hist ntdh
                            WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                            GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) z
                        ON x.id_nurse_tea_req = z.id_nurse_tea_req
                       AND x.dt_nurse_tea_req_diag_tstz < z.dt_nurse_tea_req_diag_tstz
                     WHERE nvl(id_diagnosis1, 'NULL') != nvl(id_diagnosis2, 'NULL')) n
              JOIN nurse_tea_req_hist ntr
                ON ntr.id_nurse_tea_req_hist = n.id_nurse_tea_req_hist
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
            UNION ALL
            --expired task
            SELECT 'EXP' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('EXPIRE_NOTES') code,
                   table_varchar(' ') label,
                   table_varchar(pk_message.get_message(i_lang, 'CPOE_M014')) data
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_expired
            -- not order reason
            UNION ALL
            SELECT 'NOR' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS',
                                 'NOT_ORDER_REASON') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'),
                                 pk_message.get_message(i_lang, pk_not_order_reason_db.g_mcode_reas_not_order)) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 ntr.description,
                                 pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => pk_not_order_reason_db.g_mcode_not_ordered_data),
                                 pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                                  i_not_order_reason => ntr.id_not_order_reason)) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_not_ord_reas
               AND NOT EXISTS
             (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_db.g_nurse_tea_req_not_ord_reas)
            -- not order reason (hist)  
            UNION ALL
            SELECT 'NRH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS',
                                 'NOT_ORDER_REASON') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'),
                                 pk_message.get_message(i_lang, pk_not_order_reason_db.g_mcode_reas_not_order)) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_db.get_desc_topic(i_lang,
                                                                        i_prof,
                                                                        ntr.id_nurse_tea_topic,
                                                                        ntr.desc_topic_aux,
                                                                        ntt.code_nurse_tea_topic),
                                 get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(g_sys_domain_flg_time, ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 ntr.description,
                                 pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => pk_not_order_reason_db.g_mcode_not_ordered_data),
                                 pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                                  i_not_order_reason => ntr.id_not_order_reason)) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MAX(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_not_ord_reas;
    
        OPEN o_data FOR
        -- DRAFT
            SELECT 'DRAFT' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_draft
            
            UNION ALL
            -- request (w/o hist)
            SELECT 'REQ' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status IN (g_nurse_tea_req_pend, g_nurse_tea_req_act, g_nurse_tea_req_fin)
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = g_nurse_tea_req_pend)
            UNION ALL
            -- request (w/ hist)
            SELECT 'RQH' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = g_nurse_tea_req_pend
            -- suggestion (w/o hist)
            UNION ALL
            SELECT 'SUG' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_sug
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req)
            -- suggestion (w/ hist)
            UNION ALL
            SELECT 'SGH' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = g_nurse_tea_req_sug
            -- execution
            UNION ALL
            SELECT 'EXE' flg_type, ntd.id_nurse_tea_det id, ntd.description description
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = g_nurse_tea_det_exec
            UNION ALL
            --edited
            SELECT 'EDTD' flg_type, ntr.id_nurse_tea_req_hist id, ntr.description description
              FROM (SELECT id_nurse_tea_req_hist
                      FROM (SELECT ntr.id_nurse_tea_req_hist,
                                   lag(ntr.notes_req, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_notes_req,
                                   ntr.notes_req,
                                   --lag(pk_string_utils.clob_to_plsqlvarchar2(ntr.description), 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_description,
                                   --ntr.description,
                                   lag(ntr.id_order_recurr_plan, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_order_recurr_plan,
                                   ntr.id_order_recurr_plan,
                                   lag(ntr.flg_time, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_flg_time,
                                   ntr.flg_time,
                                   ntr.diagnosis AS current_diag,
                                   lag(ntr.diagnosis, 1) over(ORDER BY ntr.id_nurse_tea_req_hist ASC) AS prev_diag
                              FROM (SELECT ntr.id_nurse_tea_req_hist,
                                           ntr.notes_req,
                                           --ntr.description description,
                                           ntr.id_order_recurr_plan,
                                           ntr.flg_time,
                                           ntr.dt_nurse_tea_req_hist_tstz,
                                           dh.dt_nurse_tea_req_diag_tstz,
                                           listagg(dh.id_diagnosis, '|') within GROUP(ORDER BY dh.id_diagnosis ASC) AS diagnosis
                                      FROM nurse_tea_req_hist ntr
                                      LEFT JOIN nurse_tea_req_diag_hist dh
                                        ON dh.id_nurse_tea_req_hist = ntr.id_nurse_tea_req_hist
                                     WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                                     GROUP BY ntr.id_nurse_tea_req_hist,
                                              ntr.notes_req,
                                              --ntr.description,
                                              ntr.id_order_recurr_plan,
                                              ntr.flg_time,
                                              dt_nurse_tea_req_hist_tstz,
                                              dh.dt_nurse_tea_req_diag_tstz) ntr) ntr
                     WHERE (nvl(prev_notes_req, 'NULL') <> nvl(notes_req, 'NULL') OR
                           /*REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(prev_description), chr(13), ''),
                           chr(10),
                           '') <>
                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(description), chr(13), ''),
                           chr(10),
                           '') OR*/
                           nvl(id_order_recurr_plan, -1) <> nvl(prev_id_order_recurr_plan, -1) OR
                           nvl(flg_time, -1) <> nvl(prev_flg_time, -1) OR
                           nvl(ntr.current_diag, -1) <> nvl(ntr.prev_diag, -1))
                       AND id_nurse_tea_req_hist <>
                           (SELECT MIN(ntr.id_nurse_tea_req_hist)
                              FROM nurse_tea_req_hist ntr
                             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req)
                    UNION
                    -- id_composition
                    SELECT z.id_nurse_tea_req_hist
                      FROM (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                   ntdh.id_nurse_tea_req,
                                   ntdh.id_nurse_tea_req_hist,
                                   listagg(get_composition_hist(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                           '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis1
                              FROM nurse_tea_req_diag_hist ntdh
                             WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                             GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) x
                      JOIN (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                  ntdh.id_nurse_tea_req,
                                  ntdh.id_nurse_tea_req_hist,
                                  listagg(get_composition_hist(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                          '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis2
                             FROM nurse_tea_req_diag_hist ntdh
                            WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                            GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) z
                        ON x.id_nurse_tea_req = z.id_nurse_tea_req
                       AND x.dt_nurse_tea_req_diag_tstz < z.dt_nurse_tea_req_diag_tstz
                     WHERE nvl(id_diagnosis1, 'NULL') != nvl(id_diagnosis2, 'NULL')) n
              JOIN nurse_tea_req_hist ntr
                ON ntr.id_nurse_tea_req_hist = n.id_nurse_tea_req_hist
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject;
    
        SELECT pk_date_utils.get_timestamp_str(i_lang, i_prof, MIN(dt_nurse_tea_req_tstz), NULL)
          INTO l_date_req
          FROM (SELECT ntr.dt_nurse_tea_req_tstz
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                UNION ALL
                SELECT h.dt_nurse_tea_req_tstz
                  FROM nurse_tea_req_hist h
                 WHERE h.id_nurse_tea_req_hist =
                       (SELECT MIN(id_nurse_tea_req_hist)
                          FROM nurse_tea_req_hist
                         WHERE id_nurse_tea_req = i_id_nurse_tea_req));
    
        OPEN o_main FOR
            SELECT pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) title_subject,
                   pk_patient_education_db.get_desc_topic(i_lang,
                                                          i_prof,
                                                          ntr.id_nurse_tea_topic,
                                                          ntr.desc_topic_aux,
                                                          ntt.code_nurse_tea_topic) title_topic,
                   ntr.flg_status flg_status,
                   pk_sysdomain.get_domain(g_sys_domain_req_flg_status, ntr.flg_status, i_lang) desc_status,
                   l_date_req date_req
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              LEFT JOIN nurse_tea_req_hist ntrh
                ON ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_register);
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_main);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_DET',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_det;

    FUNCTION get_patient_education_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_order_detail  t_tbl_health_education_order;
        l_tbl_exec_detail   t_tbl_health_education_exec;
        l_tbl_cancel_detail t_tbl_health_education_cancel;
    
        l_tab_dd_block_data_order  t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_exec   t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_cancel t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --1) Obtaining the data
        --ORDER
        l_tbl_order_detail := pk_patient_education_db.tf_get_order_detail(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --EXECUTION
        l_tbl_exec_detail := pk_patient_education_db.tf_get_execution_detail(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --CANCELLATION
        l_tbl_cancel_detail := pk_patient_education_db.tf_get_cancel_detail(i_lang             => i_lang,
                                                                            i_prof             => i_prof,
                                                                            i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --2) Construct the dd_blocks
        --ORDER
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank * 100,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_order
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.subject,
                                       t.topic,
                                       t.clinical_indication,
                                       t.to_execute,
                                       t.frequency,
                                       t.start_date,
                                       to_char(t.order_notes) order_notes,
                                       to_char(dbms_lob.substr(t.description, 3990)) description,
                                       status,
                                       registry,
                                       end_date
                                  FROM TABLE(l_tbl_order_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                             subject,
                                                                                                                             topic,
                                                                                                                             clinical_indication,
                                                                                                                             to_execute,
                                                                                                                             frequency,
                                                                                                                             start_date,
                                                                                                                             order_notes,
                                                                                                                             description,
                                                                                                                             status,
                                                                                                                             registry,
                                                                                                                             end_date)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'ORDER'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --EXECUTION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_exec
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.clinical_indication,
                                       t.goals,
                                       t.method,
                                       t.given_to,
                                       t.deliverables,
                                       t.understanding,
                                       t.start_date,
                                       t.duration,
                                       t.end_date,
                                       to_char(t.description) description,
                                       t.status,
                                       t.registry,
                                       t.white_line
                                  FROM TABLE(l_tbl_exec_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                            clinical_indication,
                                                                                                                            goals,
                                                                                                                            method,
                                                                                                                            given_to,
                                                                                                                            deliverables,
                                                                                                                            understanding,
                                                                                                                            start_date,
                                                                                                                            duration,
                                                                                                                            end_date,
                                                                                                                            description,
                                                                                                                            status,
                                                                                                                            registry,
                                                                                                                            white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'EXECUTION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --CANCELLATION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100),
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_cancel
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT t.action, t.cancel_reason, t.cancel_notes, t.registry, t.white_line
                                  FROM TABLE(l_tbl_cancel_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                              cancel_reason,
                                                                                                                              cancel_notes,
                                                                                                                              registry,
                                                                                                                              white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'CANCELLATION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL
                                       AND flg_type <> 'L3CQ' THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L3CQ' THEN
                                   data_code_message
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              decode(flg_type, 'L3CQ', 'L3B', flg_type), --TYPE
                              flg_html,
                              NULL,
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
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_order) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_exec) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_cancel) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL')))
         ORDER BY rnk, rank, rank_cq;
    
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
                                              'get_patient_education_det',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_patient_education_det;

    FUNCTION get_patient_education_det_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_order_detail  t_tbl_health_education_order_hist;
        l_tbl_exec_detail   t_tbl_health_education_exec;
        l_tbl_cancel_detail t_tbl_health_education_cancel;
    
        l_tab_dd_block_data_order  t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_exec   t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_cancel t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --1) Obtaining the data
        --ORDER
        l_tbl_order_detail := pk_patient_education_db.tf_get_order_detail_hist(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --EXECUTION
        l_tbl_exec_detail := pk_patient_education_db.tf_get_execution_detail(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --CANCELLATION
        l_tbl_cancel_detail := pk_patient_education_db.tf_get_cancel_detail(i_lang             => i_lang,
                                                                            i_prof             => i_prof,
                                                                            i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --2) Construct the dd_blocks
        --ORDER
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_order
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.subject,
                                       t.topic,
                                       t.clinical_indication,
                                       t.clinical_indication_new,
                                       t.to_execute,
                                       t.to_execute_new,
                                       t.frequency,
                                       t.frequency_new,
                                       t.start_date,
                                       t.start_date_new,
                                       to_char(t.order_notes) order_notes,
                                       to_char(t.order_notes_new) order_notes_new,
                                       to_char(t.description) description,
                                       to_char(t.description_new) description_new,
                                       t.status,
                                       t.status_new,
                                       t.registry,
                                       t.white_line,
                                       t.end_date,
                                       t.end_date_new
                                  FROM TABLE(l_tbl_order_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                             subject,
                                                                                                                             topic,
                                                                                                                             clinical_indication,
                                                                                                                             clinical_indication_new,
                                                                                                                             to_execute,
                                                                                                                             to_execute_new,
                                                                                                                             frequency,
                                                                                                                             frequency_new,
                                                                                                                             start_date,
                                                                                                                             start_date_new,
                                                                                                                             order_notes,
                                                                                                                             order_notes_new,
                                                                                                                             description,
                                                                                                                             description_new,
                                                                                                                             status,
                                                                                                                             status_new,
                                                                                                                             registry,
                                                                                                                             white_line,
                                                                                                                             end_date,
                                                                                                                             end_date_new)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'ORDER'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --EXECUTION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_exec
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.clinical_indication,
                                       t.goals,
                                       t.method,
                                       t.given_to,
                                       t.deliverables,
                                       t.understanding,
                                       t.start_date,
                                       t.duration,
                                       t.end_date,
                                       to_char(t.description) description,
                                       t.status,
                                       t.registry,
                                       t.white_line
                                  FROM TABLE(l_tbl_exec_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                            clinical_indication,
                                                                                                                            goals,
                                                                                                                            method,
                                                                                                                            given_to,
                                                                                                                            deliverables,
                                                                                                                            understanding,
                                                                                                                            start_date,
                                                                                                                            duration,
                                                                                                                            end_date,
                                                                                                                            description,
                                                                                                                            status,
                                                                                                                            registry,
                                                                                                                            white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'EXECUTION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --CANCELLATION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100),
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_cancel
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT t.action, t.cancel_reason, t.cancel_notes, t.registry, t.white_line
                                  FROM TABLE(l_tbl_cancel_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                              cancel_reason,
                                                                                                                              cancel_notes,
                                                                                                                              registry,
                                                                                                                              white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'CANCELLATION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL
                                       AND flg_type <> 'L3CQ' THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L3CQ' THEN
                                   data_code_message
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              decode(flg_type, 'L3CQ', 'L3B', flg_type), -- TYPE
                              flg_html,
                              NULL,
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
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_order) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_exec) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_cancel) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL')))
         ORDER BY rnk, rank, rank_cq;
    
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
                                              'get_patient_education_det',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_patient_education_det_hist;
    --
    FUNCTION get_patient_education_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT get_patient_education_list(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_episode => i_id_episode,
                                          i_id_hhc_req => NULL,
                                          o_list       => o_list,
                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_list;

    FUNCTION get_patient_education_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode      table_number;
        l_has_notes       sys_message.desc_message%TYPE;
        l_begin           sys_message.desc_message%TYPE;
        l_label_notes_req sys_message.desc_message%TYPE;
        l_label_cacel_req sys_message.desc_message%TYPE;
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
    BEGIN
        -- MENSAGENS 
        l_has_notes := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M097');
    
        l_begin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PROCEDURES_T016') || ': ';
    
        l_label_notes_req := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => 'PATIENT_EDUCATION_M012');
    
        l_label_cacel_req := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => 'PATIENT_EDUCATION_M033');
    
        g_error := 'All episodes from this visit';
        SELECT t.id_episode
          BULK COLLECT
          INTO l_id_episode
          FROM (SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(i_id_episode)
                UNION
                SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_prev_episode IN (SELECT ehr.id_epis_hhc
                                               FROM alert.epis_hhc_req ehr
                                              WHERE ehr.id_episode = i_id_episode
                                                 OR ehr.id_epis_hhc_req = i_id_hhc_req)
                UNION
                SELECT ehr.id_epis_hhc
                  FROM alert.epis_hhc_req ehr
                 WHERE ehr.id_episode = i_id_episode
                    OR ehr.id_epis_hhc_req = i_id_hhc_req) t;
    
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_id_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR i_id_hhc_req IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(i_id_hhc_req,
                                  pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => pk_episode.get_id_patient(i_id_episode)));
        
            IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_hhc_req   => l_i_id_hhc_req,
                                               o_flg_can_edit => l_flg_can_edit,
                                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'List this visit?s patient education tasks';
        OPEN o_list FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             ntr.id_nurse_tea_req,
             pk_patient_education_db.get_desc_topic(i_lang,
                                                    i_prof,
                                                    ntr.id_nurse_tea_topic,
                                                    ntr.desc_topic_aux,
                                                    ntt.code_nurse_tea_topic) title_topic,
             pk_translation.get_translation(i_lang,
                                             CASE
                                                 WHEN nts.code_nurse_tea_subject IS NULL THEN
                                                  'NURSE_TEA_SUBJECT.CODE_NURSE_TEA_SUBJECT.1'
                                                 ELSE
                                                  nts.code_nurse_tea_subject
                                             END) title_subject,
             ntt.id_nurse_tea_topic,
             nts.id_nurse_tea_subject,
             CASE
                  WHEN ntr.notes_req IS NOT NULL THEN
                   l_has_notes
                  WHEN ntr.notes_close IS NOT NULL THEN
                   l_has_notes
                  ELSE
                   NULL
              END title_notes,
             decode(ntr.notes_req, NULL, NULL, ntr.notes_req) notes_req,
             l_label_notes_req label_notes_req,
             decode(ntr.flg_status, 'C', ntr.notes_close, NULL) notes_cancel,
             l_label_cacel_req label_notes_cancel,
             l_begin || pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_begin_tstz, i_prof) instructions,
             ntr.flg_status,
             pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status, i_lang) desc_status,
             ntr.flg_time,
             pk_prof_utils.get_nickname(i_lang, ntr.id_prof_req) prof_order,
             get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) desc_diagnosis,
             pk_utils.get_status_string(i_lang, i_prof, ntr.status_str, ntr.status_msg, ntr.status_icon, ntr.status_flg) status_string,
             ntr.id_context,
             pk_info_button.get_cds_show_info_button(i_lang, i_prof, ntr.id_context) info_button_url,
             l_flg_can_edit flg_can_edit
              FROM nurse_tea_req ntr
              LEFT JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              LEFT JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              JOIN professional p
                ON p.id_professional = ntr.id_prof_req
              JOIN TABLE(l_id_episode) t
                ON t.column_value = ntr.id_episode
             WHERE ntr.flg_status NOT IN (pk_patient_education_db.g_nurse_tea_req_draft)
             ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => 'NURSE_TEA_REQ.FLG_STATUS',
                                            i_val      => ntr.flg_status),
                      title_subject,
                      title_topic,
                      desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_list;

    FUNCTION get_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2 DEFAULT NULL,
        i_most_frequent   IN VARCHAR2 DEFAULT 'Y',
        i_id_subject      IN nurse_tea_subject.id_nurse_tea_subject%TYPE DEFAULT NULL,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market          market.id_market%TYPE;
        l_prof_dep_clin_serv table_number;
    BEGIN
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'Get professional?s associated dep_clin_serv';
        BEGIN
            SELECT pdcs.id_dep_clin_serv
              BULK COLLECT
              INTO l_prof_dep_clin_serv
              FROM prof_dep_clin_serv pdcs
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
              JOIN department d
                ON d.id_department = dcs.id_department
             WHERE pdcs.id_professional = i_prof.id
               AND d.id_institution = i_prof.institution
               AND pdcs.flg_status = g_selected
            UNION ALL
            SELECT 0
              FROM dual;
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_dep_clin_serv := table_number();
        END;
    
        IF i_most_frequent IS NULL
        THEN
            NULL;
        ELSIF i_most_frequent NOT IN (pk_alert_constant.g_no, pk_alert_constant.g_yes)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Patient education topics with not-null description, sorted by subject
        OPEN o_topics FOR
            SELECT id_subject, desc_subject, id_topic, title_topic, desc_topic, desc_topic_context_help
              FROM (SELECT o_ntt.id_nurse_tea_topic id_topic,
                           o_ntt.id_nurse_tea_subject id_subject,
                           pk_translation.get_translation(i_lang, o_ntt.code_nurse_tea_topic) title_topic,
                           pk_translation_lob.get_translation(i_lang, o_ntt.code_topic_description) desc_topic,
                           pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                           pk_translation_lob.get_translation(i_lang, o_ntt.code_topic_context_help) desc_topic_context_help
                      FROM nurse_tea_topic o_ntt
                      JOIN nurse_tea_subject nts
                        ON nts.id_nurse_tea_subject = o_ntt.id_nurse_tea_subject
                     WHERE nts.flg_available = pk_alert_constant.g_yes
                       AND (i_flg_show_others = pk_alert_constant.g_no AND o_ntt.id_nurse_tea_topic <> 1)
                        OR (i_flg_show_others = pk_alert_constant.g_yes)
                       AND o_ntt.flg_available = pk_alert_constant.g_yes
                       AND (i_id_subject IS NULL OR
                           (i_id_subject IS NOT NULL AND i_id_subject = nts.id_nurse_tea_subject))
                       AND EXISTS
                     (SELECT nttsi.id_nurse_tea_topic
                              FROM nurse_tea_top_soft_inst nttsi
                             WHERE rownum > 0
                               AND ((i_most_frequent = pk_alert_constant.g_no AND nttsi.flg_type = g_searchable) OR
                                   (i_most_frequent = pk_alert_constant.g_yes AND nttsi.flg_type = g_frequent AND
                                   nvl(nttsi.id_dep_clin_serv, 0) IN
                                   (SELECT column_value
                                        FROM TABLE(l_prof_dep_clin_serv))))
                               AND nttsi.id_nurse_tea_topic = o_ntt.id_nurse_tea_topic
                               AND nttsi.flg_available = pk_alert_constant.g_yes
                               AND nttsi.id_software IN (0, i_prof.software)
                               AND nttsi.id_institution IN (0, i_prof.institution)
                               AND nttsi.id_market IN (0, l_id_market)
                            MINUS
                            SELECT nttsi.id_nurse_tea_topic
                              FROM nurse_tea_top_soft_inst nttsi
                             WHERE rownum > 0
                               AND ((i_most_frequent = pk_alert_constant.g_no AND nttsi.flg_type = g_searchable) OR
                                   (i_most_frequent = pk_alert_constant.g_yes AND nttsi.flg_type = g_frequent AND
                                   nvl(nttsi.id_dep_clin_serv, 0) IN
                                   (SELECT column_value
                                        FROM TABLE(l_prof_dep_clin_serv))))
                               AND nttsi.id_nurse_tea_topic = o_ntt.id_nurse_tea_topic
                               AND nttsi.flg_available = pk_alert_constant.g_no
                               AND nttsi.id_software IN (0, i_prof.software)
                               AND nttsi.id_institution IN (0, i_prof.institution)
                               AND nttsi.id_market IN (0, l_id_market)))
             WHERE title_topic IS NOT NULL
               AND desc_subject IS NOT NULL
             ORDER BY desc_subject, title_topic;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_topics);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOPIC_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_topic_list;

    --
    FUNCTION get_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_topic_list(i_lang            => i_lang,
                              i_prof            => i_prof,
                              i_most_frequent   => pk_alert_constant.g_yes,
                              i_flg_show_others => i_flg_show_others,
                              o_topics          => o_topics,
                              o_error           => o_error);
    END get_topic_list;

    --
    FUNCTION get_topic_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_limit     sys_config.value%TYPE;
        l_count     PLS_INTEGER;
        l_id_market market.id_market%TYPE;
    BEGIN
    
        l_limit     := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        o_flg_show  := 'N';
        l_id_market := pk_prof_utils.get_prof_market(i_prof);
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT id_subject, desc_subject, id_topic, title_topic, desc_topic
                  FROM (SELECT /*+opt_estimate(table st rows=1)*/
                         nts.id_nurse_tea_subject id_subject,
                         pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                         ntt.id_nurse_tea_topic id_topic,
                         st.desc_translation title_topic,
                         pk_translation_lob.get_translation(i_lang, ntt.code_topic_description) desc_topic
                          FROM TABLE(pk_translation.get_search_translation(i_lang,
                                                                           i_keyword,
                                                                           'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC')) st
                          JOIN nurse_tea_topic ntt
                            ON ntt.code_nurse_tea_topic = st.code_translation
                          JOIN nurse_tea_subject nts
                            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                         WHERE ((i_flg_show_others = pk_alert_constant.g_no AND ntt.id_nurse_tea_topic <> 1) OR
                               (i_flg_show_others = pk_alert_constant.g_yes))
                           AND ntt.flg_available = pk_alert_constant.g_yes
                           AND EXISTS (SELECT nttsi.id_nurse_tea_topic
                                  FROM nurse_tea_top_soft_inst nttsi
                                 WHERE rownum > 0
                                   AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                   AND nttsi.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)
                                MINUS
                                SELECT nttsi.id_nurse_tea_topic
                                  FROM nurse_tea_top_soft_inst nttsi
                                 WHERE rownum > 0
                                   AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                   AND nttsi.flg_available = pk_alert_constant.g_no
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)))
                 WHERE title_topic IS NOT NULL
                   AND desc_subject IS NOT NULL);
    
        IF l_count > l_limit
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_flg_has_action => g_yes);
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'R';
        ELSIF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M015');
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'R';
        
            pk_types.open_cursor_if_closed(o_topics);
            RETURN TRUE;
        END IF;
    
        OPEN o_topics FOR
            SELECT id_subject, desc_subject, id_topic, title_topic, desc_topic, desc_topic_context_help
              FROM (SELECT /*+opt_estimate(table st rows=1)*/
                     nts.id_nurse_tea_subject id_subject,
                     pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                     ntt.id_nurse_tea_topic id_topic,
                     st.desc_translation title_topic,
                     pk_translation_lob.get_translation(i_lang, ntt.code_topic_description) desc_topic,
                     pk_translation_lob.get_translation(i_lang, ntt.code_topic_context_help) desc_topic_context_help
                      FROM TABLE(pk_translation.get_search_translation(i_lang,
                                                                       i_keyword,
                                                                       'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC')) st
                      JOIN nurse_tea_topic ntt
                        ON ntt.code_nurse_tea_topic = st.code_translation
                      JOIN nurse_tea_subject nts
                        ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                     WHERE ((i_flg_show_others = pk_alert_constant.g_no AND ntt.id_nurse_tea_topic <> 1) OR
                           (i_flg_show_others = pk_alert_constant.g_yes))
                       AND ntt.flg_available = pk_alert_constant.g_yes
                       AND (EXISTS (SELECT nttsi.id_nurse_tea_topic
                                      FROM nurse_tea_top_soft_inst nttsi
                                     WHERE rownum > 0
                                       AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                       AND nttsi.flg_available = pk_alert_constant.g_yes
                                       AND nttsi.id_software IN (0, i_prof.software)
                                       AND nttsi.id_institution IN (0, i_prof.institution)
                                       AND nttsi.id_market IN (0, l_id_market)
                                    MINUS
                                    SELECT nttsi.id_nurse_tea_topic
                                      FROM nurse_tea_top_soft_inst nttsi
                                     WHERE rownum > 0
                                       AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                       AND nttsi.flg_available = pk_alert_constant.g_no
                                       AND nttsi.id_software IN (0, i_prof.software)
                                       AND nttsi.id_institution IN (0, i_prof.institution)
                                       AND nttsi.id_market IN (0, l_id_market))))
             WHERE title_topic IS NOT NULL
               AND desc_subject IS NOT NULL
             ORDER BY desc_subject, title_topic;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_topics);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOPIC_SEARCH',
                                              o_error);
        
            RETURN FALSE;
    END get_topic_search;

    --
    FUNCTION get_subject_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_subject      IN nurse_tea_subject.id_nurse_tea_subject%TYPE,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_subjects        OUT pk_types.cursor_type,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market market.id_market%TYPE;
    BEGIN
        l_id_market := pk_prof_utils.get_prof_market(i_prof);
    
        -- Patient education subjects with a not-null description and with child topics
        IF i_id_subject IS NOT NULL
        THEN
            pk_types.open_cursor_if_closed(o_subjects);
        
        ELSE
            OPEN o_subjects FOR
                SELECT id_nurse_tea_subject, desc_nurse_tea_subject
                  FROM (SELECT nts.id_nurse_tea_subject,
                               pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_nurse_tea_subject
                          FROM nurse_tea_subject nts
                         WHERE rownum > 0
                           AND (i_flg_show_others = pk_alert_constant.g_no AND nts.id_nurse_tea_subject <> 1)
                            OR (i_flg_show_others = pk_alert_constant.g_yes)
                           AND (i_id_subject IS NULL OR
                               (i_id_subject IS NOT NULL AND i_id_subject = nts.id_nurse_tea_subject))
                           AND nts.flg_available = pk_alert_constant.g_yes
                           AND EXISTS (SELECT ntt.id_nurse_tea_topic
                                  FROM nurse_tea_topic ntt
                                  JOIN nurse_tea_top_soft_inst nttsi
                                    ON nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                 WHERE rownum > 0
                                   AND ntt.id_nurse_tea_subject = nts.id_nurse_tea_subject
                                   AND ntt.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)
                                   AND pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) IS NOT NULL
                                MINUS
                                SELECT ntt.id_nurse_tea_topic
                                  FROM nurse_tea_topic ntt
                                  JOIN nurse_tea_top_soft_inst nttsi
                                    ON nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                 WHERE rownum > 0
                                   AND ntt.id_nurse_tea_subject = nts.id_nurse_tea_subject
                                   AND ntt.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.flg_available = pk_alert_constant.g_no
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)))
                 WHERE desc_nurse_tea_subject IS NOT NULL
                 ORDER BY desc_nurse_tea_subject;
        END IF;
    
        -- Get topics
        IF i_id_subject IS NULL
        THEN
            pk_types.open_cursor_if_closed(o_topics);
        
        ELSE
            IF NOT get_topic_list(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_most_frequent   => pk_alert_constant.g_no,
                                  i_id_subject      => i_id_subject,
                                  i_flg_show_others => i_flg_show_others,
                                  o_topics          => o_topics,
                                  o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_subjects);
            pk_types.open_cursor_if_closed(o_topics);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUBJECT_TOPIC_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_subject_topic_list;

    --
    /******************************************************************************/

    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
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
        o_rowids               OUT table_varchar
    );

    /******************************************************************************/
    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
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
        o_rowids               OUT table_varchar
    ) IS
        -- Auxiliar Variables
        dt_aux_nurse_tea_req_tstz TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_begin_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_close_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        --
        l_ntr_row_old nurse_tea_req%ROWTYPE;
        l_ntr_row     nurse_tea_req%ROWTYPE;
        l_error       t_error_out;
    
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
    
        -- Realiza o UPDATE linha da tabela NURSE_TEA_REQ
        g_error := 'NURSE_TEA_REQ';
        ts_nurse_tea_req.upd(rec_in => l_ntr_row, rows_out => o_rowids);
        -- < END DESNORM >
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_PATIENT_EDUCATION_UX', 'PRV_ALTER_NTR_BY_ID');
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                -- undo changes quando se faz ROLLBACK
                pk_utils.undo_changes;
            
            END;
    END prv_alter_ntr_by_id;

    /******************************************************************************/

    FUNCTION set_nurse_tea_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_epis IS
            SELECT id_episode
              FROM nurse_tea_req
             WHERE id_nurse_tea_req = i_nurse_tea_req;
    
        l_epis episode.id_episode%TYPE;
        --l_error                   VARCHAR2(4000);
        l_error      t_error_out;
        l_ntr_rowids table_varchar;
        --err_id                     PLS_INTEGER;
        l_count_nurse_tea_det      NUMBER;
        l_count_nurse_tea_det_exec NUMBER;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(*)
          INTO l_count_nurse_tea_det_exec
          FROM nurse_tea_det ntd
         WHERE ntd.id_nurse_tea_req = i_nurse_tea_req
           AND ntd.flg_status IN (g_nurse_tea_det_exec, g_nurse_tea_det_canc);
    
        SELECT COUNT(*)
          INTO l_count_nurse_tea_det
          FROM nurse_tea_det ntd
         WHERE ntd.id_nurse_tea_req = i_nurse_tea_req
           AND ntd.flg_status <> g_nurse_tea_det_ign;
    
        CASE
            WHEN l_count_nurse_tea_det_exec = 0 THEN
            
                g_error := 'prv_alter_ntr_by_id';
                prv_alter_ntr_by_id(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_nurse_tea_req => i_nurse_tea_req,
                                    i_flg_status       => g_nurse_tea_req_act,
                                    i_id_prof_req      => profissional(NULL, i_prof.institution, i_prof.software),
                                    i_dt_close_str     => pk_date_utils.get_timestamp_str(i_lang,
                                                                                          i_prof,
                                                                                          g_sysdate_tstz,
                                                                                          NULL),
                                    i_id_prof_close    => i_prof.id,
                                    o_rowids           => l_ntr_rowids);
            
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE NURSE_TEA_REQ - NURSE_TEA_REQ';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'NURSE_TEA_REQ',
                                              i_list_columns => table_varchar('id_nurse_tea_req',
                                                                              'id_prof_req',
                                                                              'id_episode',
                                                                              'req_header',
                                                                              'flg_status',
                                                                              'notes_req',
                                                                              'id_prof_close',
                                                                              'notes_close',
                                                                              'dt_nurse_tea_req_tstz',
                                                                              'dt_begin_tstz',
                                                                              'dt_close_tstz',
                                                                              'id_visit',
                                                                              'id_patient'),
                                              i_rowids       => l_ntr_rowids,
                                              o_error        => o_error);
            
                insert_ntr_hist(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_nurse_tea_req => i_nurse_tea_req,
                                o_error            => o_error);
            
            WHEN l_count_nurse_tea_det_exec = l_count_nurse_tea_det THEN
            
                g_error := 'prv_alter_ntr_by_id';
                prv_alter_ntr_by_id(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_nurse_tea_req => i_nurse_tea_req,
                                    i_flg_status       => g_nurse_tea_req_fin,
                                    i_id_prof_req      => profissional(NULL, i_prof.institution, i_prof.software),
                                    i_dt_close_str     => pk_date_utils.get_timestamp_str(i_lang,
                                                                                          i_prof,
                                                                                          g_sysdate_tstz,
                                                                                          NULL),
                                    i_id_prof_close    => i_prof.id,
                                    o_rowids           => l_ntr_rowids);
            
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE NURSE_TEA_REQ - NURSE_TEA_REQ';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'NURSE_TEA_REQ',
                                              i_list_columns => table_varchar('id_nurse_tea_req',
                                                                              'id_prof_req',
                                                                              'id_episode',
                                                                              'req_header',
                                                                              'flg_status',
                                                                              'notes_req',
                                                                              'id_prof_close',
                                                                              'notes_close',
                                                                              'dt_nurse_tea_req_tstz',
                                                                              'dt_begin_tstz',
                                                                              'dt_close_tstz',
                                                                              'id_visit',
                                                                              'id_patient'),
                                              i_rowids       => l_ntr_rowids,
                                              o_error        => o_error);
            
                insert_ntr_hist(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_nurse_tea_req => i_nurse_tea_req,
                                o_error            => o_error);
            ELSE
                NULL;
            
        END CASE;
    
        g_error := 'OPEN c_epis';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis;
        CLOSE c_epis;
    
        -- PLLopes 30/01/2008 - ALERT912
        -- insert log status
        IF NOT t_ti_log.ins_log(i_lang,
                                i_prof,
                                l_epis,
                                g_nurse_tea_req_fin,
                                i_nurse_tea_req,
                                pk_edis_summary.g_ti_log_nurse_tea,
                                o_error)
        THEN
            RETURN FALSE;
        END IF;
        --  ALERT912
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_PATIENT_EDUCATION_UX', 'SET_NURSE_TEA_REQ_STATUS');
                -- execute error processing
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando se faz ROLLBACK
                pk_utils.undo_changes;
                --reset error state
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
    END set_nurse_tea_req_status;
    /************************************************/
    FUNCTION get_documentation_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_goals            OUT pk_types.cursor_type,
        o_methods          OUT pk_types.cursor_type,
        o_given_to         OUT pk_types.cursor_type,
        o_deliverables     OUT pk_types.cursor_type,
        o_understanding    OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_goals                    nurse_tea_opt.subject%TYPE := 'GOALS';
        l_method                   nurse_tea_opt.subject%TYPE := 'METHOD';
        l_level                    nurse_tea_opt.subject%TYPE := 'LEVEL_OF_UNDERSTANDING';
        l_given_to                 nurse_tea_opt.subject%TYPE := 'GIVEN_TO';
        l_deliverables             nurse_tea_opt.subject%TYPE := 'DELIVERABLES';
        l_free_text                sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                           i_prof,
                                                                                           'PATIENT_EDUCATION_M001');
        l_clinical_service         table_number;
        l_pat_education_id_add_res sys_config.value%TYPE := pk_sysconfig.get_config('DEFAULT_ID_PAT_EDUCATION_ADDITIONAL_RESOURCES',
                                                                                    i_prof.institution,
                                                                                    i_prof.software);
        l_nurse_tea_opt_desc       VARCHAR2(4000);
        l_nurse_tea_opt_id         nurse_tea_opt.id_nurse_tea_opt%TYPE;
    
        CURSOR c_nurse_tea_opt_desc IS
            SELECT DISTINCT pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                            nto.id_nurse_tea_opt id_nurse_tea_opt
              FROM nurse_tea_opt nto
             WHERE nto.id_nurse_tea_opt = l_pat_education_id_add_res;
    BEGIN
    
        OPEN c_nurse_tea_opt_desc;
        FETCH c_nurse_tea_opt_desc
            INTO l_nurse_tea_opt_desc, l_nurse_tea_opt_id;
        CLOSE c_nurse_tea_opt_desc;
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        OPEN o_goals FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_goals
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_goals, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_methods FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_method
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_method, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_deliverables FOR
            SELECT subject, data, label, flg_print
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nto.flg_print flg_print,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_deliverables
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_deliverables, -1, l_free_text, pk_alert_constant.g_no flg_print, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_given_to FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_given_to
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_given_to, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_understanding FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_level
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_level, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_info FOR
            SELECT ntr.description description,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   (SELECT ntd.dt_start
                                                      FROM nurse_tea_det ntd
                                                     WHERE ntd.flg_status = g_nurse_tea_det_pend
                                                       AND ntd.id_nurse_tea_req = ntr.id_nurse_tea_req
                                                       AND ntd.num_order =
                                                           (SELECT MIN(ntd.num_order)
                                                              FROM nurse_tea_det ntd
                                                             WHERE ntd.flg_status = g_nurse_tea_det_pend
                                                               AND ntd.id_nurse_tea_req = ntr.id_nurse_tea_req)),
                                                   NULL) dt_begin,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, e.dt_creation, NULL) dt_creation_epis,
                   CASE
                        WHEN l_nurse_tea_opt_desc IS NOT NULL THEN
                         l_nurse_tea_opt_desc
                        ELSE
                         NULL
                    END add_resources,
                   CASE
                        WHEN l_nurse_tea_opt_id IS NOT NULL THEN
                         l_nurse_tea_opt_id
                        ELSE
                         NULL
                    END add_resources_id
              FROM nurse_tea_req ntr
              JOIN episode e
                ON e.id_episode = ntr.id_episode
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_goals);
            pk_types.open_cursor_if_closed(o_methods);
            pk_types.open_cursor_if_closed(o_given_to);
            pk_types.open_cursor_if_closed(o_deliverables);
            pk_types.open_cursor_if_closed(o_understanding);
            pk_types.open_cursor_if_closed(o_info);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_DET',
                                              o_error);
        
            RETURN FALSE;
    END get_documentation_det;

    FUNCTION get_documentation_goals
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_goals            nurse_tea_opt.subject%TYPE := 'GOALS';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_goals
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_GOALS',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_goals;

    FUNCTION get_documentation_methods
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_method           nurse_tea_opt.subject%TYPE := 'METHOD';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT nto.id_nurse_tea_opt data,
                               pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                               nvl(ntoi.rank, 0) rank,
                               row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                          FROM nurse_tea_opt nto
                          JOIN nurse_tea_opt_inst ntoi
                            ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                         WHERE nto.subject = l_method
                           AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                           AND nvl(ntoi.id_clinical_service, 0) IN
                               (SELECT column_value
                                  FROM TABLE(l_clinical_service))
                        UNION ALL
                        SELECT -1, l_free_text, NULL rank, 1 rn
                          FROM dual)
                 WHERE rn = 1
                 ORDER BY rank NULLS LAST, label);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_METHODS',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_methods;

    FUNCTION get_documentation_given_to
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_given_to         nurse_tea_opt.subject%TYPE := 'GIVEN_TO';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_given_to
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_GIVEN_TO',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_given_to;

    FUNCTION get_documentation_addit_res
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_deliverables     nurse_tea_opt.subject%TYPE := 'DELIVERABLES';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_deliverables
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_ADDIT_RES',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_addit_res;

    FUNCTION get_doc_level_understanding
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_level            nurse_tea_opt.subject%TYPE := 'LEVEL_OF_UNDERSTANDING';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_level
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_ADDIT_RES',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_doc_level_understanding;
    --
    FUNCTION set_documentation_exec
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_nurse_tea_req   IN nurse_tea_det.id_nurse_tea_req%TYPE,
        i_subject            IN table_varchar,
        i_id_nurse_tea_opt   IN table_number,
        i_free_text          IN table_clob,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_duration           IN NUMBER,
        i_unit_meas_duration IN NUMBER,
        i_description        IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_start          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_end            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_nurse_tea_det_opt nurse_tea_det_opt.id_nurse_tea_det_opt%TYPE;
        l_id_nurse_tea_det  nurse_tea_det.id_nurse_tea_det%TYPE;
        l_flg_status        nurse_tea_req.flg_status%TYPE;
        l_episode           nurse_tea_req.id_episode%TYPE;
        l_rows_ntdo         table_varchar := table_varchar();
        l_rows              table_varchar := table_varchar();
        l_exist             BOOLEAN := TRUE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        BEGIN
            SELECT t.id_nurse_tea_det, t.ntr_flg_status, t.id_episode
              INTO l_id_nurse_tea_det, l_flg_status, l_episode
              FROM (SELECT ntd.id_nurse_tea_det,
                           ntr.flg_status ntr_flg_status,
                           ntd.dt_start,
                           ntd.dt_end,
                           ntr.id_episode,
                           rank() over(ORDER BY ntd.num_order) rn
                      FROM nurse_tea_req ntr
                     INNER JOIN nurse_tea_det ntd
                        ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                     WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
                       AND ntd.flg_status = g_nurse_tea_det_pend) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_exist := FALSE;
        END;
    
        -- Check if this is a execution of the task after it expires through CPOE.
        -- If it is, we can not change the status of the request, keeping as expired.
        IF l_flg_status != pk_patient_education_db.g_nurse_tea_req_expired
        THEN
        
            IF NOT pk_patient_education_ux.set_nurse_tea_req_status(i_lang          => i_lang,
                                                                    i_nurse_tea_req => i_id_nurse_tea_req,
                                                                    i_prof          => i_prof,
                                                                    i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                  i_prof),
                                                                    o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_exist
        THEN
            g_error := 'Update execution details';
            ts_nurse_tea_det.upd(id_nurse_tea_det_in      => l_id_nurse_tea_det,
                                 id_prof_provider_in      => i_prof.id,
                                 dt_start_in              => l_dt_start,
                                 dt_end_in                => CASE
                                                                 WHEN l_dt_end IS NOT NULL THEN
                                                                  l_dt_end
                                                                 ELSE
                                                                  current_timestamp
                                                             END,
                                 duration_in              => i_duration,
                                 id_unit_meas_duration_in => i_unit_meas_duration,
                                 dt_nurse_tea_det_tstz_in => g_sysdate_tstz,
                                 flg_status_in            => g_nurse_tea_det_exec,
                                 description_in           => i_description,
                                 rows_out                 => l_rows);
        
            g_error := 'Process insert';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_DET',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            g_error := 'INSERT LOG ON TI_LOG';
            IF NOT t_ti_log.ins_log(i_lang, i_prof, l_episode, g_nurse_tea_det_exec, l_id_nurse_tea_det, 'NT', o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF i_id_nurse_tea_opt.count > 0
            THEN
                l_rows := table_varchar();
            
                g_error := 'Insert execution details options';
                FOR i IN 1 .. i_id_nurse_tea_opt.count
                LOOP
                    l_nurse_tea_det_opt := ts_nurse_tea_det_opt.next_key;
                
                    ts_nurse_tea_det_opt.ins(id_nurse_tea_det_opt_in => l_nurse_tea_det_opt,
                                             id_nurse_tea_det_in     => l_id_nurse_tea_det,
                                             id_nurse_tea_opt_in     => i_id_nurse_tea_opt(i),
                                             subject_in              => i_subject(i),
                                             notes_in                => i_free_text(i),
                                             dt_nurse_tea_det_opt_in => g_sysdate_tstz,
                                             rows_out                => l_rows_ntdo);
                
                    l_rows := l_rows MULTISET UNION l_rows_ntdo;
                END LOOP;
            
                g_error := 'Process insert';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_DET_OPT',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END IF;
        
            -- Check if this is a execution of the task after it expires through CPOE.
            -- If it is, we can not change the status of the request, keeping as expired.
            IF l_flg_status != pk_patient_education_db.g_nurse_tea_req_expired
            THEN
                IF NOT pk_patient_education_ux.set_nurse_tea_req_status(i_lang          => i_lang,
                                                                        i_nurse_tea_req => i_id_nurse_tea_req,
                                                                        i_prof          => i_prof,
                                                                        i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                      i_prof),
                                                                        o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DOCUMENTATION_EXEC',
                                              o_error);
        
            RETURN FALSE;
    END set_documentation_exec;

    FUNCTION set_documentation_exec
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req     IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_start          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_end            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_nurse_tea_det_opt nurse_tea_det_opt.id_nurse_tea_det_opt%TYPE;
        l_id_nurse_tea_det  nurse_tea_det.id_nurse_tea_det%TYPE;
        l_flg_status        nurse_tea_req.flg_status%TYPE;
        l_episode           nurse_tea_req.id_episode%TYPE;
        l_rows_ntdo         table_varchar := table_varchar();
        l_rows              table_varchar := table_varchar();
        l_exist             BOOLEAN := TRUE;
    
        l_subject          table_table_varchar := table_table_varchar();
        l_id_nurse_tea_opt table_table_number := table_table_number();
        l_free_text        table_table_clob := table_table_clob();
    
        l_tbl_dt_start table_varchar := table_varchar();
        l_tbl_dt_end   table_varchar := table_varchar();
        l_tbl_duration table_number := table_number();
        l_tbl_unit_measure table_number := table_number();
    
        l_tbl_description table_clob := table_clob();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN i_id_nurse_tea_req.first .. i_id_nurse_tea_req.last
        LOOP
            l_subject.extend();
            l_subject(i) := table_varchar();
        
            l_id_nurse_tea_opt.extend();
            l_id_nurse_tea_opt(i) := table_number();
        
            l_free_text.extend();
            l_free_text(i) := table_clob();
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_goals
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GOALS';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_method
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'METHOD';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_given_to
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GIVEN_TO';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_addit_res
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'DELIVERABLES';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_level_und
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'LEVEL_OF_UNDERSTANDING';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) IN
                      (pk_orders_constant.g_ds_health_education_goals_ft,
                       pk_orders_constant.g_ds_health_educ_method_ft,
                       pk_orders_constant.g_ds_health_educ_given_to_ft,
                       pk_orders_constant.g_ds_health_educ_addit_res_ft,
                       pk_orders_constant.g_ds_health_educ_level_und_ft)
                THEN
                    l_free_text(i).extend();
                    l_free_text(i)(l_free_text(i).count) := i_tbl_val_clob(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_start_date
                THEN
                    l_tbl_dt_start.extend();
                    l_tbl_dt_start(l_tbl_dt_start.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_end_date
                THEN
                    l_tbl_dt_end.extend();
                    l_tbl_dt_end(l_tbl_dt_end.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_duration
                THEN
                    l_tbl_duration.extend();
                    l_tbl_duration(l_tbl_duration.count) := i_tbl_real_val(j) (i);
                    
                    l_tbl_unit_measure.extend();
                    l_tbl_unit_measure(l_tbl_unit_measure.count) := to_number(i_tbl_val_mea(j)(i));                    
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_description
                THEN
                    l_tbl_description.extend();
                    l_tbl_description(l_tbl_description.count) := i_tbl_val_clob(j) (i);
                END IF;
            END LOOP;
        END LOOP;
    
        FOR i IN i_id_nurse_tea_req.first .. i_id_nurse_tea_req.last
        LOOP
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_start(i), NULL);
            l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_end(i), NULL);
        
            BEGIN
                SELECT t.id_nurse_tea_det, t.ntr_flg_status, t.id_episode
                  INTO l_id_nurse_tea_det, l_flg_status, l_episode
                  FROM (SELECT ntd.id_nurse_tea_det,
                               ntr.flg_status ntr_flg_status,
                               ntd.dt_start,
                               ntd.dt_end,
                               ntr.id_episode,
                               rank() over(ORDER BY ntd.num_order) rn
                          FROM nurse_tea_req ntr
                         INNER JOIN nurse_tea_det ntd
                            ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                         WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                           AND ntd.flg_status = g_nurse_tea_det_pend) t
                 WHERE t.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_exist := FALSE;
            END;
        
            -- check if this is a execution of the task after it expires through cpoe.
            -- if it is, we can not change the status of the request, keeping as expired.
            IF l_flg_status != pk_patient_education_db.g_nurse_tea_req_expired
            THEN
            
                IF NOT pk_patient_education_ux.set_nurse_tea_req_status(i_lang          => i_lang,
                                                                        i_nurse_tea_req => i_id_nurse_tea_req(i),
                                                                        i_prof          => i_prof,
                                                                        i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                      i_prof),
                                                                        o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF l_exist
            THEN
                g_error := 'Update execution details';
                ts_nurse_tea_det.upd(id_nurse_tea_det_in      => l_id_nurse_tea_det,
                                     id_prof_provider_in      => i_prof.id,
                                     dt_start_in              => l_dt_start,
                                     dt_end_in                => CASE
                                                                     WHEN l_dt_end IS NOT NULL THEN
                                                                      l_dt_end
                                                                     ELSE
                                                                      current_timestamp
                                                                 END,
                                     duration_in              => l_tbl_duration(i),
                                     id_unit_meas_duration_in => l_tbl_unit_measure(i),
                                     dt_nurse_tea_det_tstz_in => g_sysdate_tstz,
                                     flg_status_in            => g_nurse_tea_det_exec,
                                     description_in           => l_tbl_description(i),
                                     rows_out                 => l_rows);
            
                g_error := 'Process insert';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_DET',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                g_error := 'INSERT LOG ON TI_LOG';
                IF NOT
                    t_ti_log.ins_log(i_lang, i_prof, l_episode, g_nurse_tea_det_exec, l_id_nurse_tea_det, 'NT', o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_id_nurse_tea_opt(i).count > 0
                THEN
                    l_rows := table_varchar();
                
                    g_error := 'Insert execution details options';
                    FOR j IN l_id_nurse_tea_opt(i).first .. l_id_nurse_tea_opt(i).last
                    LOOP
                        l_nurse_tea_det_opt := ts_nurse_tea_det_opt.next_key;
                    
                        ts_nurse_tea_det_opt.ins(id_nurse_tea_det_opt_in => l_nurse_tea_det_opt,
                                                 id_nurse_tea_det_in     => l_id_nurse_tea_det,
                                                 id_nurse_tea_opt_in     => CASE
                                                                                WHEN l_id_nurse_tea_opt(i) (j) = '-1' THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 l_id_nurse_tea_opt(i) (j)
                                                                            END,
                                                 subject_in              => l_subject(i) (j),
                                                 notes_in                => l_free_text(i) (j),
                                                 dt_nurse_tea_det_opt_in => g_sysdate_tstz,
                                                 rows_out                => l_rows_ntdo);
                    
                        l_rows := l_rows MULTISET UNION l_rows_ntdo;
                    END LOOP;
                
                    g_error := 'Process insert';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'NURSE_TEA_DET_OPT',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                
                END IF;
            
                -- check if this is a execution of the task after it expires through cpoe.
                -- if it is, we can not change the status of the request, keeping as expired.
                IF l_flg_status != pk_patient_education_db.g_nurse_tea_req_expired
                THEN
                    IF NOT pk_patient_education_ux.set_nurse_tea_req_status(i_lang          => i_lang,
                                                                            i_nurse_tea_req => i_id_nurse_tea_req(i),
                                                                            i_prof          => i_prof,
                                                                            i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                          i_prof),
                                                                            o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DOCUMENTATION_EXEC',
                                              o_error);
        
            RETURN FALSE;
    END set_documentation_exec;

    FUNCTION set_order_for_execution
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_nurse_tea_topic   IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_start          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_end            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_nurse_tea_det_opt nurse_tea_det_opt.id_nurse_tea_det_opt%TYPE;
        l_id_nurse_tea_det  nurse_tea_det.id_nurse_tea_det%TYPE;
        l_flg_status        nurse_tea_req.flg_status%TYPE;
        l_episode           nurse_tea_req.id_episode%TYPE;
        l_rows_ntdo         table_varchar := table_varchar();
        l_rows              table_varchar := table_varchar();
        l_exist             BOOLEAN := TRUE;
    
        l_subject          table_table_varchar := table_table_varchar();
        l_id_nurse_tea_opt table_table_number := table_table_number();
        l_free_text        table_table_clob := table_table_clob();
    
        l_tbl_dt_start table_varchar := table_varchar();
        l_tbl_dt_end   table_varchar := table_varchar();
        l_tbl_duration table_number := table_number();
        l_tbl_unit_measure    table_number := table_number();      
    
        l_tbl_description table_clob := table_clob();
    
        l_tbl_id_nurse_teq_req table_number := table_number();
    
        l_tbl_compositions          table_table_number := table_table_number();
        l_tbl_id_nurse_tea_req_sugg table_number := table_number();
        l_tbl_desc_topic_aux        table_varchar := table_varchar();
        l_tbl_not_order_reason      table_number := table_number();
        l_tbl_diagnoses             table_clob := table_clob();
        l_tbl_notes                 table_varchar := table_varchar();
    
        l_value_to_be_executed      VARCHAR2(4000);
        l_value_to_be_executed_desc VARCHAR2(4000);
        l_tbl_values_to_be_executed table_varchar := table_varchar();
    
        --RECURRENCE
        l_order_recurr_desc          VARCHAR2(4000);
        l_order_recurr_option        order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date                 order_recurr_plan.start_date%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date                   order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable        VARCHAR2(1);
        l_order_recurr_plan          order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_plan_original order_recurr_plan.id_order_recurr_plan%TYPE;
        l_tbl_order_recurr_plan      table_number := table_number();
    
        o_id_nurse_tea_topic table_number := table_number();
        o_title_topic        table_varchar := table_varchar();
        o_desc_diagnosis     table_varchar := table_varchar();
    BEGIN
    
        FOR i IN i_id_nurse_tea_topic.first .. i_id_nurse_tea_topic.last
        LOOP
            l_subject.extend();
            l_subject(i) := table_varchar();
        
            l_id_nurse_tea_opt.extend();
            l_id_nurse_tea_opt(i) := table_number();
        
            l_free_text.extend();
            l_free_text(i) := table_clob();
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_goals
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GOALS';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_method
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'METHOD';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_given_to
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GIVEN_TO';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_addit_res
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'DELIVERABLES';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_level_und
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'LEVEL_OF_UNDERSTANDING';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) IN
                      (pk_orders_constant.g_ds_health_education_goals_ft,
                       pk_orders_constant.g_ds_health_educ_method_ft,
                       pk_orders_constant.g_ds_health_educ_given_to_ft,
                       pk_orders_constant.g_ds_health_educ_addit_res_ft,
                       pk_orders_constant.g_ds_health_educ_level_und_ft)
                THEN
                    l_free_text(i).extend();
                    l_free_text(i)(l_free_text(i).count) := i_tbl_val_clob(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_start_date
                THEN
                    l_tbl_dt_start.extend();
                    l_tbl_dt_start(l_tbl_dt_start.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_end_date
                THEN
                    l_tbl_dt_end.extend();
                    l_tbl_dt_end(l_tbl_dt_end.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_duration
                THEN
                    l_tbl_duration.extend();
                    l_tbl_duration(l_tbl_duration.count) := i_tbl_real_val(j) (i);

                      l_tbl_unit_measure.extend();
                      l_tbl_unit_measure(l_tbl_unit_measure.count) := to_number(i_tbl_val_mea(j)(i));
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_description
                THEN
                    l_tbl_description.extend();
                    l_tbl_description(l_tbl_description.count) := i_tbl_val_clob(j) (i);
                END IF;
            END LOOP;
        END LOOP;
    
        IF NOT pk_patient_education_ux.get_default_domain_time(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               o_val      => l_value_to_be_executed,
                                                               o_desc_val => l_value_to_be_executed_desc,
                                                               o_error    => o_error)
        THEN
            g_error := 'error found while calling pk_patient_education_ux.get_default_domain_time function';
            RAISE g_exception;
        END IF;
    
        FOR i IN i_id_nurse_tea_topic.first .. i_id_nurse_tea_topic.last
        LOOP
            IF i = 1
            THEN
                IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_order_recurr_area   => 'PATIENT_EDUCATION',
                                                                         o_order_recurr_desc   => l_order_recurr_desc,
                                                                         o_order_recurr_option => l_order_recurr_option,
                                                                         o_start_date          => l_start_date,
                                                                         o_occurrences         => l_occurrences,
                                                                         o_duration            => l_duration,
                                                                         o_unit_meas_duration  => l_unit_meas_duration,
                                                                         o_end_date            => l_end_date,
                                                                         o_flg_end_by_editable => l_flg_end_by_editable,
                                                                         o_order_recurr_plan   => l_order_recurr_plan,
                                                                         o_error               => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            
                l_order_recurr_plan_original := l_order_recurr_plan;
            ELSE
                IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_order_recurr_plan_from => l_order_recurr_plan_original,
                                                                       o_order_recurr_desc      => l_order_recurr_desc,
                                                                       o_order_recurr_option    => l_order_recurr_option,
                                                                       o_start_date             => l_start_date,
                                                                       o_occurrences            => l_occurrences,
                                                                       o_duration               => l_duration,
                                                                       o_unit_meas_duration     => l_unit_meas_duration,
                                                                       o_end_date               => l_end_date,
                                                                       o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                       o_order_recurr_plan      => l_order_recurr_plan,
                                                                       o_error                  => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            END IF;
        
            l_tbl_order_recurr_plan.extend();
            l_tbl_order_recurr_plan(l_tbl_order_recurr_plan.count) := l_order_recurr_plan;
            l_tbl_id_nurse_tea_req_sugg.extend();
            l_tbl_desc_topic_aux.extend();
            l_tbl_not_order_reason.extend();
            l_tbl_notes.extend();
        
            l_tbl_values_to_be_executed.extend();
            l_tbl_values_to_be_executed(l_tbl_values_to_be_executed.count) := l_value_to_be_executed;
        END LOOP;
    
        IF NOT pk_patient_education_db.create_request(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_id_episode            => i_episode,
                                                      i_topics                => i_id_nurse_tea_topic,
                                                      i_compositions          => l_tbl_compositions,
                                                      i_to_be_performed       => l_tbl_values_to_be_executed,
                                                      i_start_date            => l_tbl_dt_start,
                                                      i_notes                 => l_tbl_notes,
                                                      i_description           => l_tbl_description,
                                                      i_order_recurr          => l_tbl_order_recurr_plan,
                                                      i_draft                 => pk_alert_constant.g_no,
                                                      i_id_nurse_tea_req_sugg => l_tbl_id_nurse_tea_req_sugg,
                                                      i_desc_topic_aux        => l_tbl_desc_topic_aux,
                                                      i_diagnoses             => l_tbl_diagnoses,
                                                      i_not_order_reason      => l_tbl_not_order_reason,
                                                      o_id_nurse_tea_req      => l_tbl_id_nurse_teq_req,
                                                      o_id_nurse_tea_topic    => o_id_nurse_tea_topic,
                                                      o_title_topic           => o_title_topic,
                                                      o_desc_diagnosis        => o_desc_diagnosis,
                                                      o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FOR i IN l_tbl_id_nurse_teq_req.first .. l_tbl_id_nurse_teq_req.last
        LOOP
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_start(i), NULL);
            l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_end(i), NULL);
        
            BEGIN
                SELECT t.id_nurse_tea_det, t.ntr_flg_status, t.id_episode
                  INTO l_id_nurse_tea_det, l_flg_status, l_episode
                  FROM (SELECT ntd.id_nurse_tea_det,
                               ntr.flg_status ntr_flg_status,
                               ntd.dt_start,
                               ntd.dt_end,
                               ntr.id_episode,
                               rank() over(ORDER BY ntd.num_order) rn
                          FROM nurse_tea_req ntr
                         INNER JOIN nurse_tea_det ntd
                            ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                         WHERE ntd.id_nurse_tea_req = l_tbl_id_nurse_teq_req(i)
                           AND ntd.flg_status = g_nurse_tea_det_pend) t
                 WHERE t.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_exist := FALSE;
            END;
        
            -- check if this is a execution of the task after it expires through cpoe.
            -- if it is, we can not change the status of the request, keeping as expired.
            IF l_flg_status != pk_patient_education_db.g_nurse_tea_req_expired
            THEN
            
                IF NOT pk_patient_education_ux.set_nurse_tea_req_status(i_lang          => i_lang,
                                                                        i_nurse_tea_req => l_tbl_id_nurse_teq_req(i),
                                                                        i_prof          => i_prof,
                                                                        i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                      i_prof),
                                                                        o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF l_exist
            THEN
                g_error := 'Update execution details';
                ts_nurse_tea_det.upd(id_nurse_tea_det_in      => l_id_nurse_tea_det,
                                     id_prof_provider_in      => i_prof.id,
                                     dt_start_in              => l_dt_start,
                                     dt_end_in                => CASE
                                                                     WHEN l_dt_end IS NOT NULL THEN
                                                                      l_dt_end
                                                                     ELSE
                                                                      current_timestamp
                                                                 END,
                                     duration_in              => l_tbl_duration(i),
                                     id_unit_meas_duration_in => l_tbl_unit_measure(i),
                                     dt_nurse_tea_det_tstz_in => g_sysdate_tstz,
                                     flg_status_in            => g_nurse_tea_det_exec,
                                     description_in           => l_tbl_description(i),
                                     rows_out                 => l_rows);
            
                g_error := 'Process insert';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_DET',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                g_error := 'INSERT LOG ON TI_LOG';
                IF NOT
                    t_ti_log.ins_log(i_lang, i_prof, l_episode, g_nurse_tea_det_exec, l_id_nurse_tea_det, 'NT', o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_id_nurse_tea_opt(i).count > 0
                THEN
                    l_rows := table_varchar();
                
                    g_error := 'Insert execution details options';
                    FOR j IN l_id_nurse_tea_opt(i).first .. l_id_nurse_tea_opt(i).last
                    LOOP
                        l_nurse_tea_det_opt := ts_nurse_tea_det_opt.next_key;
                    
                        ts_nurse_tea_det_opt.ins(id_nurse_tea_det_opt_in => l_nurse_tea_det_opt,
                                                 id_nurse_tea_det_in     => l_id_nurse_tea_det,
                                                 id_nurse_tea_opt_in     => CASE
                                                                                WHEN l_id_nurse_tea_opt(i) (j) = -1 THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 l_id_nurse_tea_opt(i) (j)
                                                                            END,
                                                 subject_in              => l_subject(i) (j),
                                                 notes_in                => l_free_text(i) (j),
                                                 dt_nurse_tea_det_opt_in => g_sysdate_tstz,
                                                 rows_out                => l_rows_ntdo);
                    
                        l_rows := l_rows MULTISET UNION l_rows_ntdo;
                    END LOOP;
                
                    g_error := 'Process insert';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'NURSE_TEA_DET_OPT',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                
                END IF;
            
                -- check if this is a execution of the task after it expires through cpoe.
                -- if it is, we can not change the status of the request, keeping as expired.
                IF l_flg_status != pk_patient_education_db.g_nurse_tea_req_expired
                THEN
                    IF NOT pk_patient_education_ux.set_nurse_tea_req_status(i_lang          => i_lang,
                                                                            i_nurse_tea_req => l_tbl_id_nurse_teq_req(i),
                                                                            i_prof          => i_prof,
                                                                            i_prof_cat_type => pk_prof_utils.get_category(i_lang,
                                                                                                                          i_prof),
                                                                            o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_order_for_execution',
                                              o_error);
        
            RETURN FALSE;
    END set_order_for_execution;

    --
    FUNCTION set_ignore_suggestion
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_ntr table_varchar := table_varchar();
        l_rows     table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_id_nurse_tea_req.count
        LOOP
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
            ts_nurse_tea_req.upd(id_nurse_tea_req_in      => i_id_nurse_tea_req(i),
                                 id_prof_close_in         => i_prof.id,
                                 flg_status_in            => g_nurse_tea_req_ign,
                                 dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                 rows_out                 => l_rows_ntr);
        
            l_rows := l_rows MULTISET UNION l_rows_ntr;
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_IGNORE_SUGGESTION',
                                              o_error);
        
            RETURN FALSE;
    END set_ignore_suggestion;

    --
    FUNCTION update_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_req IN table_number,
        i_topics           IN table_number,
        i_compositions     IN table_table_number,
        i_diagnoses        IN table_clob,
        i_to_be_performed  IN table_varchar,
        i_start_date       IN table_varchar,
        i_notes            IN table_varchar,
        i_description      IN table_clob,
        i_order_recurr     IN table_number,
        i_upd_flg_status   IN VARCHAR2 DEFAULT 'Y',
        i_not_order_reason IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init update_request / i_id_episode=' || i_id_episode;
        IF NOT pk_patient_education_db.update_request(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_episode       => i_id_episode,
                                                      i_id_nurse_tea_req => i_id_nurse_tea_req,
                                                      i_topics           => i_topics,
                                                      i_compositions     => i_compositions,
                                                      i_to_be_performed  => i_to_be_performed,
                                                      i_start_date       => i_start_date,
                                                      i_notes            => i_notes,
                                                      i_description      => i_description,
                                                      i_order_recurr     => i_order_recurr,
                                                      i_upd_flg_status   => i_upd_flg_status,
                                                      i_diagnoses        => i_diagnoses,
                                                      i_not_order_reason => i_not_order_reason,
                                                      o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_REQUEST',
                                              o_error);
        
            RETURN FALSE;
    END update_request;

    /******************************************************************************/
    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CREATE_NURSE_TEA_REQ';
    BEGIN
        g_error := 'calling pk_patient_education_db.create_nurse_tea_req function';
        IF NOT pk_patient_education_db.create_nurse_tea_req(i_lang             => i_lang,
                                                            i_episode          => i_episode,
                                                            i_prof_req         => i_prof_req,
                                                            i_dt_begin_str     => i_dt_begin_str,
                                                            i_notes_req        => i_notes_req,
                                                            i_prof_cat_type    => i_prof_cat_type,
                                                            o_id_nurse_tea_req => o_id_nurse_tea_req,
                                                            o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_nurse_tea_req;

    FUNCTION get_subject_by_id_topic
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE,
        o_subject  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Patient education subject
        g_error := 'calling pk_patient_education_db.get_subject_by_id_topic';
        IF NOT pk_patient_education_db.get_subject_by_id_topic(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_id_topic => i_id_topic,
                                                               o_subject  => o_subject,
                                                               o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_subject);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUBJECT_BY_ID_TOPIC',
                                              o_error);
        
            RETURN FALSE;
    END get_subject_by_id_topic;

    FUNCTION get_subject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB IS
    
    BEGIN
        -- Patient education subject
        g_error := 'calling pk_patient_education_db.get_subject';
        RETURN pk_patient_education_db.get_subject(i_lang => i_lang, i_prof => i_prof, i_id_topic => i_id_topic);
    
    END get_subject;

    /**
    * Returns available actions according with patient education request's status
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_nurse_tea_req  Patient education request IDs
    * @param   o_actions        Available actions
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   07-11-2011
    */
    FUNCTION get_request_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN table_number,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_request_actions';
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
    
    BEGIN
        g_error := 'CALL pk_patient_education_db.get_request_actions';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        l_ret := pk_patient_education_db.get_request_actions(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_nurse_tea_req => i_nurse_tea_req,
                                                             i_id_episode    => i_id_episode,
                                                             i_id_hhc_req    => i_id_hhc_req,
                                                             o_actions       => o_actions,
                                                             o_error         => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_request_actions;

    FUNCTION get_patient_education_all_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'List this visit?s patient education tasks';
        OPEN o_list FOR
            SELECT ntr.id_nurse_tea_req,
                   pk_patient_education_db.get_desc_topic(i_lang,
                                                          i_prof,
                                                          ntr.id_nurse_tea_topic,
                                                          ntr.desc_topic_aux,
                                                          ntt.code_nurse_tea_topic) title_topic,
                   pk_translation.get_translation(i_lang,
                                                   CASE
                                                       WHEN nts.code_nurse_tea_subject IS NULL THEN
                                                        'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC.1'
                                                       ELSE
                                                        nts.code_nurse_tea_subject
                                                   END) title_subject,
                   ntt.id_nurse_tea_topic,
                   nts.id_nurse_tea_subject,
                   pk_prof_utils.get_nickname(i_lang, ntr.id_prof_req) prof_order,
                   pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                        i_prof,
                                                        pk_episode.get_epis_type(i_lang, ntr.id_episode)) desc_epis_type,
                   pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                        i_prof,
                                                        ntr.id_episode,
                                                        pk_episode.get_epis_type(i_lang, ntr.id_episode),
                                                        '; ') desc_epis,
                   pk_date_utils.date_char_hour_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.dt_chr_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) date_target
              FROM nurse_tea_req ntr
              LEFT JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              LEFT JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              JOIN professional p
                ON p.id_professional = ntr.id_prof_req
              JOIN (SELECT DISTINCT (ntr.id_episode)
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_patient = i_id_patient) t
                ON t.id_episode = ntr.id_episode
             WHERE ntr.flg_status NOT IN (pk_patient_education_db.g_nurse_tea_req_draft)
               AND EXISTS (SELECT 1
                      FROM nurse_tea_det n
                     WHERE n.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND n.flg_status = pk_patient_education_ux.g_nurse_tea_det_exec);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_ALL_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_all_list;

    PROCEDURE init_params_grid
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
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_episode episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_has_notes        sys_message.desc_message%TYPE;
        l_begin            sys_message.desc_message%TYPE;
        l_label_notes_req  sys_message.desc_message%TYPE;
        l_label_cancel_req sys_message.desc_message%TYPE;
    
        l_flg_can_edit   VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_id_req_hhc     episode.id_episode%TYPE;
        l_tbl_id_episode table_number;
        l_epis_type      epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req   epis_hhc_req.id_epis_hhc_req%TYPE;
        l_episode_split  VARCHAR2(1000 CHAR);
    
        --FILTER_BIND
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_context_vals.count > 0
        THEN
            l_id_req_hhc := i_context_vals(1);
        END IF;
    
        -- MENSAGENS 
        l_has_notes := pk_message.get_message(i_lang => l_lang, i_prof => l_prof, i_code_mess => 'COMMON_M097');
    
        l_begin := pk_message.get_message(i_lang => l_lang, i_prof => l_prof, i_code_mess => 'PROCEDURES_T016') || ': ';
    
        l_label_notes_req := pk_message.get_message(i_lang      => l_lang,
                                                    i_prof      => l_prof,
                                                    i_code_mess => 'PATIENT_EDUCATION_M012');
    
        l_label_cancel_req := pk_message.get_message(i_lang      => l_lang,
                                                     i_prof      => l_prof,
                                                     i_code_mess => 'PATIENT_EDUCATION_M033');
    
        SELECT t.id_episode
          BULK COLLECT
          INTO l_tbl_id_episode
          FROM (SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(l_episode)
                UNION
                SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_prev_episode IN (SELECT ehr.id_epis_hhc
                                               FROM alert.epis_hhc_req ehr
                                              WHERE ehr.id_episode = l_episode
                                                 OR ehr.id_epis_hhc_req = l_id_req_hhc)
                UNION
                SELECT ehr.id_epis_hhc
                  FROM alert.epis_hhc_req ehr
                 WHERE ehr.id_episode = l_episode
                    OR ehr.id_epis_hhc_req = l_id_req_hhc) t;
    
        IF l_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => l_lang,
                                            i_id_epis   => l_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR l_id_req_hhc IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(l_id_req_hhc,
                                  pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => pk_episode.get_id_patient(l_episode)));
        
            IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => l_lang,
                                               i_prof         => l_prof,
                                               i_id_hhc_req   => l_i_id_hhc_req,
                                               o_flg_can_edit => l_flg_can_edit,
                                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        l_episode_split := pk_utils.to_string(l_tbl_id_episode);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_episodes', l_episode_split);
    
        g_error := 'PK_TECH_IMAGE, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_has_notes' THEN
                o_vc2 := l_has_notes;
            WHEN 'l_label_notes_req' THEN
                o_vc2 := l_label_notes_req;
            WHEN 'l_label_cacel_req' THEN
                o_vc2 := l_label_cancel_req;
            WHEN 'l_begin' THEN
                o_vc2 := l_begin;
            WHEN 'l_flg_can_edit' THEN
                o_vc2 := l_flg_can_edit;
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PATIENT_EDUCATION_UX',
                                              i_function => 'INIT_PARAMS_GRID',
                                              o_error    => o_error);
    END init_params_grid;

    PROCEDURE init_params_topic_list
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
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_episode         episode.id_episode%TYPE := i_context_ids(g_episode);
        l_id_market       market.id_market%TYPE;
        l_flg_show_others VARCHAR2(1 CHAR) := 'Y';
        l_id_subject      NUMBER(24);
        l_most_frequent   VARCHAR2(1 CHAR) := 'Y';
    
        l_prof_dep_clin_serv table_number;
        l_dcs_split          VARCHAR2(1000 CHAR);
        --FILTER_BIND
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        /*IF i_context_vals.count > 0
        THEN
            l_id_req_hhc := i_context_vals(1);
        END IF;*/
    
        l_id_market := pk_utils.get_institution_market(i_lang => l_lang, i_id_institution => l_prof.institution);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_id_market', l_id_market);
        pk_context_api.set_parameter('i_flg_show_others', l_flg_show_others);
        pk_context_api.set_parameter('i_id_subject', l_id_subject);
        pk_context_api.set_parameter('i_most_frequent', l_most_frequent);
    
        g_error := 'PK_TECH_IMAGE, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'lang' THEN
                o_vc2 := to_char(l_lang);
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PATIENT_EDUCATION_UX',
                                              i_function => 'INIT_PARAMS_TOPIC_LIST',
                                              o_error    => o_error);
    END init_params_topic_list;

BEGIN
    NULL;

END pk_patient_education_ux;
/
