/*-- Last Change Revision: $Rev: 2045843 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:24:49 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_care_plans IS

    FUNCTION create_care_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN care_plan.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_name                    IN care_plan.name%TYPE,
        i_care_plan_type          IN care_plan.id_care_plan_type%TYPE,
        i_care_plan_dt_begin      IN VARCHAR2,
        i_care_plan_dt_end        IN VARCHAR2,
        i_subject_type            IN care_plan.subject_type%TYPE,
        i_subject                 IN care_plan.id_subject%TYPE,
        i_prof_coordinator        IN care_plan.id_prof_coordinator%TYPE,
        i_goals                   IN care_plan.goals%TYPE,
        i_notes                   IN care_plan.notes%TYPE,
        i_item                    IN table_varchar,
        i_task_type               IN table_number,
        i_care_plan_task_dt_begin IN table_varchar,
        i_care_plan_task_dt_end   IN table_varchar,
        i_num_exec                IN table_number,
        i_interval_unit           IN table_number,
        i_interval                IN table_number,
        i_care_plan_task_notes    IN table_varchar,
        o_msg                     OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_care_plan      care_plan.id_care_plan%TYPE;
        l_id_care_plan_task care_plan_task.id_care_plan_task%TYPE;
    
        l_dt_begin                care_plan.dt_begin%TYPE;
        l_dt_end                  care_plan.dt_end%TYPE;
        l_care_plan_task_dt_begin care_plan_task.dt_begin%TYPE;
        l_care_plan_task_dt_end   care_plan_task.dt_begin%TYPE;
        l_dt_next_task            care_plan_task_req.dt_next_task%TYPE;
        l_flg_type                VARCHAR2(2);
        l_appointments            NUMBER := 0;
        l_opinions                NUMBER := 0;
        l_analysis                NUMBER := 0;
        l_group_analysis          NUMBER := 0;
        l_imaging_exams           NUMBER := 0;
        l_other_exams             NUMBER := 0;
        l_procedures              NUMBER := 0;
        l_patient_education       NUMBER := 0;
        l_medication              NUMBER := 0;
        l_ext_medication          NUMBER := 0;
        l_int_medication          NUMBER := 0;
        l_pharm_medication        NUMBER := 0;
        l_ivfluids_medication     NUMBER := 0;
        l_diets                   NUMBER := 0;
    
        l_msg VARCHAR2(4000);
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_care_plan_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_care_plan_dt_end, NULL);
    
        IF l_dt_end < l_dt_begin
        THEN
            l_dt_end := l_dt_begin;
        END IF;
    
        g_error := 'INSERT INTO CARE_PLAN';
        ts_care_plan.ins(id_prof_in             => i_prof.id,
                         dt_care_plan_in        => g_sysdate_tstz,
                         id_patient_in          => i_patient,
                         flg_status_in          => g_pending,
                         str_status_in          => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_pending),
                         name_in                => i_name,
                         id_care_plan_type_in   => i_care_plan_type,
                         dt_begin_in            => l_dt_begin,
                         dt_end_in              => l_dt_end,
                         subject_type_in        => i_subject_type,
                         id_subject_in          => i_subject,
                         id_prof_coordinator_in => i_prof_coordinator,
                         goals_in               => i_goals,
                         notes_in               => i_notes,
                         id_prof_cancel_in      => NULL,
                         dt_cancel_in           => NULL,
                         id_cancel_reason_in    => NULL,
                         notes_cancel_in        => NULL,
                         id_episode_in          => i_episode,
                         rows_out               => l_rowids,
                         id_care_plan_out       => l_id_care_plan);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-CARE_PLAN';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CARE_PLAN',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_msg := REPLACE(pk_message.get_message(i_lang, 'CARE_PLANS_M002'),
                         '@1',
                         '<b>' || i_name || ': </b>' || pk_message.get_message(i_lang, 'CARE_PLANS_T056') || ' ' ||
                         pk_date_utils.date_char_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software) || '; ' || CASE
                             WHEN l_dt_end IS NOT NULL THEN
                              pk_message.get_message(i_lang, 'CARE_PLANS_T004') || ' ' ||
                              pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software)
                             ELSE
                              ''
                         END);
    
        FOR i IN 1 .. i_task_type.count
        LOOP
            IF i_task_type(i) IS NOT NULL
            THEN
                l_care_plan_task_dt_begin := pk_date_utils.get_string_tstz(i_lang,
                                                                           i_prof,
                                                                           i_care_plan_task_dt_begin(i),
                                                                           NULL);
                l_care_plan_task_dt_end   := pk_date_utils.get_string_tstz(i_lang,
                                                                           i_prof,
                                                                           i_care_plan_task_dt_end(i),
                                                                           NULL);
            
                IF l_care_plan_task_dt_end < l_care_plan_task_dt_begin
                THEN
                    l_care_plan_task_dt_end := l_care_plan_task_dt_begin;
                END IF;
            
                IF (l_care_plan_task_dt_begin < l_dt_begin OR l_care_plan_task_dt_begin > l_dt_end)
                   OR (l_care_plan_task_dt_end < l_dt_begin OR l_care_plan_task_dt_end > l_dt_end)
                THEN
                    l_msg := l_msg || '<b>' || pk_care_plans.get_desc_translation(i_lang, i_prof, i_item(i), i_task_type(i)) ||
                             ': </b>' || pk_message.get_message(i_lang, 'CARE_PLANS_T056') || ' ' ||
                             pk_date_utils.date_char_tsz(i_lang, l_care_plan_task_dt_begin, i_prof.institution, i_prof.software) || '; ' || CASE
                                 WHEN l_care_plan_task_dt_end IS NOT NULL THEN
                                  pk_message.get_message(i_lang, 'CARE_PLANS_T004') || ' ' ||
                                  pk_date_utils.date_char_tsz(i_lang, l_care_plan_task_dt_end, i_prof.institution, i_prof.software)
                                 ELSE
                                  ''
                             END;
                    IF i_task_type(i) != i_task_type.last
                    THEN
                        l_msg := l_msg || chr(10);
                    END IF;
                END IF;
            
                g_error := 'INSERT INTO CARE_PLAN_TASK';
                INSERT INTO care_plan_task
                    (id_care_plan_task,
                     id_prof,
                     dt_care_plan_task,
                     id_item,
                     flg_status,
                     id_task_type,
                     dt_begin,
                     dt_end,
                     num_exec,
                     id_unit_measure,
                     INTERVAL,
                     notes,
                     id_prof_cancel,
                     dt_cancel,
                     id_cancel_reason,
                     notes_cancel)
                VALUES
                    (seq_care_plan_task.nextval,
                     i_prof.id,
                     g_sysdate_tstz,
                     i_item(i),
                     g_pending,
                     i_task_type(i),
                     l_care_plan_task_dt_begin,
                     l_care_plan_task_dt_end,
                     i_num_exec(i),
                     i_interval_unit(i),
                     i_interval(i),
                     i_care_plan_task_notes(i),
                     NULL,
                     NULL,
                     NULL,
                     NULL)
                RETURNING id_care_plan_task INTO l_id_care_plan_task;
            
                g_error := 'INSERT INTO CARE_PLAN_TASK_LINK';
                INSERT INTO care_plan_task_link
                    (id_care_plan, id_care_plan_task)
                VALUES
                    (l_id_care_plan, l_id_care_plan_task);
            
                IF i_num_exec(i) IS NOT NULL
                THEN
                    IF i_num_exec(i) >= 1
                    THEN
                    
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 1';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (l_id_care_plan_task, 1, l_care_plan_task_dt_begin, NULL, g_pending, i_task_type(i))
                        RETURNING dt_next_task INTO l_dt_next_task;
                    
                        FOR k IN 2 .. i_num_exec(i)
                        LOOP
                            g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 2';
                            INSERT INTO care_plan_task_req
                                (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                            VALUES
                                (l_id_care_plan_task,
                                 k,
                                 decode(i_interval_unit(i),
                                        g_day,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                        g_week,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                        g_month,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                        g_year,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                                 NULL,
                                 g_pending,
                                 i_task_type(i))
                            RETURNING dt_next_task INTO l_dt_next_task;
                        END LOOP;
                    END IF;
                ELSE
                    IF i_interval(i) IS NOT NULL
                    THEN
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 3';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (l_id_care_plan_task, 1, l_care_plan_task_dt_begin, NULL, g_pending, i_task_type(i))
                        RETURNING dt_next_task INTO l_dt_next_task;
                    
                        FOR k IN 2 .. 10
                        LOOP
                            g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 4';
                            INSERT INTO care_plan_task_req
                                (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                            VALUES
                                (l_id_care_plan_task,
                                 k,
                                 decode(i_interval_unit(i),
                                        g_day,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                        g_week,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                        g_month,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                        g_year,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                                 NULL,
                                 g_pending,
                                 i_task_type(i))
                            RETURNING dt_next_task INTO l_dt_next_task;
                        END LOOP;
                    ELSE
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 3';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (l_id_care_plan_task, 1, l_care_plan_task_dt_begin, NULL, g_pending, i_task_type(i));
                    END IF;
                END IF;
            
                l_flg_type := pk_task_type.get_task_type_flg(i_lang, i_task_type(i));
            
                IF l_flg_type IN (g_appointments, g_spec_appointments)
                THEN
                    l_appointments := l_appointments + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_appointments task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_opinions
                THEN
                    l_opinions := l_opinions + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_opinions task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_analysis
                THEN
                    l_analysis := l_analysis + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_analysis task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_group_analysis
                THEN
                    l_group_analysis := l_group_analysis + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_group_analysis task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_imaging_exams
                THEN
                    l_imaging_exams := l_imaging_exams + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_imaging_exams task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_other_exams
                THEN
                    l_other_exams := l_other_exams + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_other_exams task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_procedures
                THEN
                    l_procedures := l_procedures + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_procedures task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_patient_education
                THEN
                    l_patient_education := l_patient_education + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan,
                                  i_task_type(i) id_task_type,
                                  l_patient_education task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_medication
                THEN
                    l_medication := l_medication + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_ext_medication
                THEN
                    l_ext_medication := l_ext_medication + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_ext_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_int_medication
                THEN
                    l_int_medication := l_int_medication + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_int_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_pharm_medication
                THEN
                    l_pharm_medication := l_pharm_medication + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan,
                                  i_task_type(i) id_task_type,
                                  l_pharm_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_ivfluids_medication
                THEN
                    l_ivfluids_medication := l_ivfluids_medication + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan,
                                  i_task_type(i) id_task_type,
                                  l_ivfluids_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_diets
                THEN
                    l_diets := l_diets + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT l_id_care_plan id_care_plan, i_task_type(i) id_task_type, l_diets task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                END IF;
            END IF;
        END LOOP;
    
        IF l_msg IS NOT NULL
        THEN
            o_msg := REPLACE(o_msg, '@2', l_msg);
            RAISE g_user_exception;
        ELSE
            o_msg := NULL;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_CARE_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_care_plan;

    FUNCTION set_care_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_care_plan               IN care_plan.id_care_plan%TYPE,
        i_name                    IN care_plan.name%TYPE,
        i_care_plan_type          IN care_plan.id_care_plan_type%TYPE,
        i_care_plan_dt_begin      IN VARCHAR2,
        i_care_plan_dt_end        IN VARCHAR2,
        i_subject_type            IN care_plan.subject_type%TYPE,
        i_subject                 IN care_plan.id_subject%TYPE,
        i_prof_coordinator        IN care_plan.id_prof_coordinator%TYPE,
        i_goals                   IN care_plan.goals%TYPE,
        i_notes                   IN care_plan.notes%TYPE,
        i_care_plan_task          IN table_number,
        i_care_plan_task_dt_begin IN table_varchar,
        i_care_plan_task_dt_end   IN table_varchar,
        i_num_exec                IN table_number,
        i_interval_unit           IN table_number,
        i_interval                IN table_number,
        i_care_plan_task_notes    IN table_varchar,
        o_msg                     OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_care_plan IS
            SELECT cp.*
              FROM care_plan cp
             WHERE cp.id_care_plan = i_care_plan;
    
        CURSOR c_care_plan_task(i_care_plan_task care_plan_task.id_care_plan_task%TYPE) IS
            SELECT cpt.*
              FROM care_plan_task cpt
             WHERE cpt.id_care_plan_task = i_care_plan_task;
    
        l_care_plan_hist      c_care_plan%ROWTYPE;
        l_care_plan_task_hist c_care_plan_task%ROWTYPE;
    
        l_dt_begin care_plan.dt_begin%TYPE;
        l_dt_end   care_plan.dt_end%TYPE;
    
        l_care_plan_task_dt_begin care_plan_task.dt_begin%TYPE;
        l_care_plan_task_dt_end   care_plan_task.dt_begin%TYPE;
        l_dt_next_task            care_plan_task_req.dt_next_task%TYPE;
    
        l_count NUMBER;
    
        l_msg VARCHAR2(4000);
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_care_plan_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_care_plan_dt_end, NULL);
    
        FOR l_care_plan_task IN (SELECT cpt.*
                                   FROM care_plan_task cpt, care_plan_task_link cptl
                                  WHERE cpt.id_care_plan_task = cptl.id_care_plan_task
                                    AND cptl.id_care_plan = i_care_plan)
        LOOP
            IF (l_care_plan_task.dt_begin < l_dt_begin OR l_care_plan_task.dt_begin > l_dt_end)
               OR (l_care_plan_task.dt_end < l_dt_begin OR l_care_plan_task.dt_end > l_dt_end)
            THEN
                l_msg := l_msg || '<b>' ||
                         pk_care_plans.get_desc_translation(i_lang, i_prof, l_care_plan_task.id_item, l_care_plan_task.id_task_type) ||
                         ': </b>' || pk_message.get_message(i_lang, 'CARE_PLANS_T056') || ' ' ||
                         pk_date_utils.date_char_tsz(i_lang, l_care_plan_task.dt_begin, i_prof.institution, i_prof.software) || '; ' || CASE
                             WHEN l_care_plan_task.dt_end IS NOT NULL THEN
                              pk_message.get_message(i_lang, 'CARE_PLANS_T004') || ' ' ||
                              pk_date_utils.date_char_tsz(i_lang, l_care_plan_task.dt_end, i_prof.institution, i_prof.software)
                             ELSE
                              ''
                         END;
            END IF;
        END LOOP;
    
        g_error := 'OPEN C_CARE_PLAN';
        OPEN c_care_plan;
        FETCH c_care_plan
            INTO l_care_plan_hist;
        CLOSE c_care_plan;
    
        IF l_msg IS NOT NULL
        THEN
            o_msg := REPLACE(pk_message.get_message(i_lang, 'CARE_PLANS_M002'),
                             '@1',
                             '<b>' || nvl(i_name, l_care_plan_hist.name) || ': </b>' ||
                             pk_message.get_message(i_lang, 'CARE_PLANS_T056') || ' ' ||
                             pk_date_utils.date_char_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software) || '; ' || CASE
                                 WHEN l_dt_end IS NOT NULL THEN
                                  pk_message.get_message(i_lang, 'CARE_PLANS_T004') || ' ' ||
                                  pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software)
                                 ELSE
                                  ''
                             END);
        
            o_msg := REPLACE(o_msg, '@2', l_msg);
        
            g_error := 'o_msg: ' || o_msg;
            RAISE g_user_exception;
        ELSE
            IF (i_name IS NOT NULL)
               OR (i_care_plan_type IS NOT NULL)
               OR (i_care_plan_dt_begin IS NOT NULL)
               OR (i_care_plan_dt_end IS NOT NULL)
               OR (i_subject_type IS NOT NULL)
               OR (i_subject IS NOT NULL)
               OR (i_prof_coordinator IS NOT NULL)
               OR (i_goals IS NOT NULL)
               OR (i_notes IS NOT NULL)
            THEN
                g_error := 'INSERT INTO CARE_PLAN_HIST';
                ts_care_plan_hist.ins(dt_care_plan_hist_in   => g_sysdate_tstz,
                                      id_care_plan_in        => l_care_plan_hist.id_care_plan,
                                      id_prof_in             => l_care_plan_hist.id_prof,
                                      dt_care_plan_in        => l_care_plan_hist.dt_care_plan,
                                      id_patient_in          => l_care_plan_hist.id_patient,
                                      flg_status_in          => l_care_plan_hist.flg_status,
                                      name_in                => l_care_plan_hist.name,
                                      id_care_plan_type_in   => l_care_plan_hist.id_care_plan_type,
                                      dt_begin_in            => l_care_plan_hist.dt_begin,
                                      dt_end_in              => l_care_plan_hist.dt_end,
                                      subject_type_in        => l_care_plan_hist.subject_type,
                                      id_subject_in          => l_care_plan_hist.id_subject,
                                      id_prof_coordinator_in => l_care_plan_hist.id_prof_coordinator,
                                      goals_in               => l_care_plan_hist.goals,
                                      notes_in               => l_care_plan_hist.notes,
                                      id_prof_cancel_in      => l_care_plan_hist.id_prof_cancel,
                                      dt_cancel_in           => l_care_plan_hist.dt_cancel,
                                      id_cancel_reason_in    => l_care_plan_hist.id_cancel_reason,
                                      notes_cancel_in        => l_care_plan_hist.notes_cancel,
                                      id_episode_in          => l_care_plan_hist.id_episode,
                                      rows_out               => l_rowids);
            
                g_error := 'CALL PROCESS_INSERT';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                IF l_dt_end < l_dt_begin
                THEN
                    l_dt_end := l_dt_begin;
                END IF;
            
                g_error := 'UPDATE CARE_PLAN';
                ts_care_plan.upd(id_care_plan_in        => i_care_plan,
                                 id_prof_in             => i_prof.id,
                                 dt_care_plan_in        => g_sysdate_tstz,
                                 name_in                => i_name,
                                 id_care_plan_type_in   => i_care_plan_type,
                                 dt_begin_in            => l_dt_begin,
                                 dt_end_in              => l_dt_end,
                                 subject_type_in        => i_subject_type,
                                 id_subject_in          => i_subject,
                                 id_prof_coordinator_in => i_prof_coordinator,
                                 goals_in               => i_goals,
                                 notes_in               => i_notes,
                                 id_episode_in          => i_episode,
                                 rows_out               => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
            o_msg := NULL;
        END IF;
    
        FOR i IN 1 .. i_care_plan_task.count
        LOOP
        
            g_error := 'GET CURSOR';
            OPEN c_care_plan_task(i_care_plan_task(i));
            FETCH c_care_plan_task
                INTO l_care_plan_task_hist;
            CLOSE c_care_plan_task;
        
            g_error := 'INSERT INTO CARE_PLAN_TASK_HIST';
            INSERT INTO care_plan_task_hist
                (dt_care_plan_task_hist,
                 id_care_plan_task,
                 id_prof,
                 dt_care_plan_task,
                 id_item,
                 flg_status,
                 id_task_type,
                 dt_begin,
                 dt_end,
                 num_exec,
                 id_unit_measure,
                 INTERVAL,
                 notes,
                 id_prof_cancel,
                 dt_cancel,
                 id_cancel_reason,
                 notes_cancel)
            VALUES
                (g_sysdate_tstz,
                 l_care_plan_task_hist.id_care_plan_task,
                 l_care_plan_task_hist.id_prof,
                 l_care_plan_task_hist.dt_care_plan_task,
                 l_care_plan_task_hist.id_item,
                 l_care_plan_task_hist.flg_status,
                 l_care_plan_task_hist.id_task_type,
                 l_care_plan_task_hist.dt_begin,
                 l_care_plan_task_hist.dt_end,
                 l_care_plan_task_hist.num_exec,
                 l_care_plan_task_hist.id_unit_measure,
                 l_care_plan_task_hist.interval,
                 l_care_plan_task_hist.notes,
                 l_care_plan_task_hist.id_prof_cancel,
                 l_care_plan_task_hist.dt_cancel,
                 l_care_plan_task_hist.id_cancel_reason,
                 l_care_plan_task_hist.notes_cancel);
        
            l_care_plan_task_dt_begin := pk_date_utils.get_string_tstz(i_lang,
                                                                       i_prof,
                                                                       i_care_plan_task_dt_begin(i),
                                                                       NULL);
            l_care_plan_task_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_care_plan_task_dt_end(i), NULL);
        
            IF l_care_plan_task_dt_begin < g_sysdate_tstz
            THEN
                l_care_plan_task_dt_begin := g_sysdate_tstz;
            END IF;
        
            IF l_care_plan_task_dt_end < l_care_plan_task_dt_begin
            THEN
                l_care_plan_task_dt_end := l_care_plan_task_dt_begin;
            END IF;
        
            g_error := 'UPDATE CARE_PLAN_TASK';
            UPDATE care_plan_task
               SET dt_begin        = l_care_plan_task_dt_begin,
                   dt_end          = l_care_plan_task_dt_end,
                   num_exec        = i_num_exec(i),
                   id_unit_measure = i_interval_unit(i),
                   INTERVAL        = i_interval(i),
                   notes           = i_care_plan_task_notes(i)
             WHERE id_care_plan_task = i_care_plan_task(i);
        
            IF i_num_exec(i) IS NOT NULL
            THEN
                DELETE care_plan_task_req
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND id_req IS NULL;
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM care_plan_task_req
                 WHERE id_care_plan_task = i_care_plan_task(i);
            
                IF i_num_exec(i) > 1
                THEN
                
                    g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 1';
                    INSERT INTO care_plan_task_req
                        (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                    VALUES
                        (i_care_plan_task(i),
                         l_count + 1,
                         l_care_plan_task_dt_begin,
                         NULL,
                         g_pending,
                         l_care_plan_task_hist.id_task_type)
                    RETURNING dt_next_task INTO l_dt_next_task;
                
                    FOR k IN 2 .. i_num_exec(i)
                    LOOP
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 2';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (i_care_plan_task(i),
                             l_count + k,
                             decode(i_interval_unit(i),
                                    g_day,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                    g_week,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                    g_month,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                    g_year,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                             NULL,
                             g_pending,
                             l_care_plan_task_hist.id_task_type)
                        RETURNING dt_next_task INTO l_dt_next_task;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CARE_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan;

    FUNCTION set_care_plan_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_care_plan     IN care_plan.id_care_plan%TYPE,
        i_status        IN care_plan.flg_status%TYPE,
        i_cancel_reason IN care_plan.id_cancel_reason%TYPE,
        i_notes_cancel  IN care_plan.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_care_plan IS
            SELECT *
              FROM care_plan cp
             WHERE cp.id_care_plan = i_care_plan;
    
        CURSOR c_care_plan_task IS
            SELECT cptl.id_care_plan_task
              FROM care_plan cp, care_plan_task_link cptl
             WHERE cp.id_care_plan = i_care_plan
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan NOT IN (SELECT cptl.id_care_plan
                                               FROM care_plan cp, care_plan_task_link cptl
                                              WHERE cp.id_care_plan != i_care_plan
                                                AND cp.id_care_plan = cptl.id_care_plan);
    
        CURSOR c_count IS
            SELECT *
              FROM (SELECT COUNT(cptr.id_care_plan_task) task_count,
                           decode(cpt.num_exec, NULL, 0, cpt.num_exec) num_exec,
                           cptr.id_care_plan_task
                      FROM care_plan cp, care_plan_task_link cptl, care_plan_task cpt, care_plan_task_req cptr
                     WHERE cp.id_care_plan = i_care_plan
                       AND cp.id_care_plan = cptl.id_care_plan
                       AND cptl.id_care_plan_task = cpt.id_care_plan_task
                       AND cpt.id_care_plan_task = cptr.id_care_plan_task
                       AND (cptr.id_req IS NULL OR cptr.id_req = -1)
                     GROUP BY cptr.id_care_plan_task, cpt.num_exec)
             WHERE task_count != num_exec;
    
        l_care_plan_hist c_care_plan%ROWTYPE;
        l_count          c_count%ROWTYPE;
    
        l_care_plan_task               table_number := table_number();
        l_care_plan_task_status        table_varchar := table_varchar();
        l_care_plan_task_cancel_reason table_number := table_number();
        l_care_plan_task_notes         table_varchar := table_varchar();
    
        i NUMBER;
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CURSOR';
        OPEN c_care_plan;
        FETCH c_care_plan
            INTO l_care_plan_hist;
        CLOSE c_care_plan;
    
        g_error := 'INSERT INTO CARE_PLAN_HIST';
        ts_care_plan_hist.ins(dt_care_plan_hist_in   => g_sysdate_tstz,
                              id_care_plan_in        => l_care_plan_hist.id_care_plan,
                              id_prof_in             => l_care_plan_hist.id_prof,
                              dt_care_plan_in        => l_care_plan_hist.dt_care_plan,
                              id_patient_in          => l_care_plan_hist.id_patient,
                              flg_status_in          => l_care_plan_hist.flg_status,
                              name_in                => l_care_plan_hist.name,
                              id_care_plan_type_in   => l_care_plan_hist.id_care_plan_type,
                              dt_begin_in            => l_care_plan_hist.dt_begin,
                              dt_end_in              => l_care_plan_hist.dt_end,
                              subject_type_in        => l_care_plan_hist.subject_type,
                              id_subject_in          => l_care_plan_hist.id_subject,
                              id_prof_coordinator_in => l_care_plan_hist.id_prof_coordinator,
                              goals_in               => l_care_plan_hist.goals,
                              notes_in               => l_care_plan_hist.notes,
                              id_prof_cancel_in      => l_care_plan_hist.id_prof_cancel,
                              dt_cancel_in           => l_care_plan_hist.dt_cancel,
                              id_cancel_reason_in    => l_care_plan_hist.id_cancel_reason,
                              notes_cancel_in        => l_care_plan_hist.notes_cancel,
                              id_episode_in          => l_care_plan_hist.id_episode,
                              rows_out               => l_rowids);
    
        g_error := 'CALL PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CARE_PLAN_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_status IN (g_canceled, g_interrupted)
        THEN
            g_error := 'UPDATE CARE_PLAN';
            ts_care_plan.upd(id_care_plan_in     => i_care_plan,
                             flg_status_in       => i_status,
                             str_status_in       => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', i_status),
                             id_prof_cancel_in   => i_prof.id,
                             dt_cancel_in        => g_sysdate_tstz,
                             id_cancel_reason_in => i_cancel_reason,
                             notes_cancel_in     => i_notes_cancel,
                             rows_out            => l_rowids);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CARE_PLAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            i := 1;
            FOR rec IN c_care_plan_task
            LOOP
                l_care_plan_task.extend(1);
                l_care_plan_task(i) := rec.id_care_plan_task;
            
                l_care_plan_task_status.extend(1);
                l_care_plan_task_status(i) := i_status;
            
                l_care_plan_task_cancel_reason.extend(1);
                l_care_plan_task_cancel_reason(i) := NULL;
            
                l_care_plan_task_notes.extend(1);
                l_care_plan_task_notes(i) := NULL;
            
                i := i + 1;
            END LOOP;
        
            g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
            IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                           i_prof,
                                                           l_care_plan_task,
                                                           l_care_plan_task_status,
                                                           l_care_plan_task_cancel_reason,
                                                           l_care_plan_task_notes,
                                                           o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSIF i_status = g_suspended
        THEN
        
            g_error := 'UPDATE CARE_PLAN';
            ts_care_plan.upd(id_care_plan_in => i_care_plan,
                             dt_care_plan_in => g_sysdate_tstz,
                             flg_status_in   => g_suspended,
                             str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_suspended),
                             rows_out        => l_rowids);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CARE_PLAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            i := 1;
            FOR rec IN c_care_plan_task
            LOOP
                l_care_plan_task.extend(1);
                l_care_plan_task(i) := rec.id_care_plan_task;
            
                l_care_plan_task_status.extend(1);
                l_care_plan_task_status(i) := g_suspended;
            
                l_care_plan_task_cancel_reason.extend(1);
                l_care_plan_task_cancel_reason(i) := NULL;
            
                l_care_plan_task_notes.extend(1);
                l_care_plan_task_notes(i) := NULL;
            
                i := i + 1;
            END LOOP;
        
            g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
            IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                           i_prof,
                                                           l_care_plan_task,
                                                           l_care_plan_task_status,
                                                           l_care_plan_task_cancel_reason,
                                                           l_care_plan_task_notes,
                                                           o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSIF i_status = g_active
        THEN
        
            g_error := 'GET CURSOR';
            OPEN c_count;
            FETCH c_count
                INTO l_count;
            g_found := c_count%FOUND;
            CLOSE c_count;
        
            IF NOT g_found
            THEN
                g_error := 'UPDATE CARE_PLAN 1';
                ts_care_plan.upd(id_care_plan_in => i_care_plan,
                                 dt_care_plan_in => g_sysdate_tstz,
                                 flg_status_in   => g_pending,
                                 str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_pending),
                                 rows_out        => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                i := 1;
                FOR rec IN c_care_plan_task
                LOOP
                    l_care_plan_task.extend(1);
                    l_care_plan_task(i) := rec.id_care_plan_task;
                
                    l_care_plan_task_status.extend(1);
                    l_care_plan_task_status(i) := g_active;
                
                    l_care_plan_task_cancel_reason.extend(1);
                    l_care_plan_task_cancel_reason(i) := NULL;
                
                    l_care_plan_task_notes.extend(1);
                    l_care_plan_task_notes(i) := NULL;
                
                    i := i + 1;
                END LOOP;
            
                g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
                IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                               i_prof,
                                                               l_care_plan_task,
                                                               l_care_plan_task_status,
                                                               l_care_plan_task_cancel_reason,
                                                               l_care_plan_task_notes,
                                                               o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                g_error := 'UPDATE CARE_PLAN 2';
                ts_care_plan.upd(id_care_plan_in => i_care_plan,
                                 dt_care_plan_in => g_sysdate_tstz,
                                 flg_status_in   => g_inprogress,
                                 str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_inprogress),
                                 rows_out        => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                i := 1;
                FOR rec IN c_care_plan_task
                LOOP
                    l_care_plan_task.extend(1);
                    l_care_plan_task(i) := rec.id_care_plan_task;
                
                    l_care_plan_task_status.extend(1);
                    l_care_plan_task_status(i) := g_active;
                
                    l_care_plan_task_cancel_reason.extend(1);
                    l_care_plan_task_cancel_reason(i) := NULL;
                
                    l_care_plan_task_notes.extend(1);
                    l_care_plan_task_notes(i) := NULL;
                
                    i := i + 1;
                END LOOP;
            
                g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
                IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                               i_prof,
                                                               l_care_plan_task,
                                                               l_care_plan_task_status,
                                                               l_care_plan_task_cancel_reason,
                                                               l_care_plan_task_notes,
                                                               o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
        ELSE
        
            g_error := 'UPDATE CARE_PLAN 3';
            ts_care_plan.upd(id_care_plan_in => i_care_plan,
                             dt_care_plan_in => g_sysdate_tstz,
                             flg_status_in   => i_status,
                             str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', i_status),
                             rows_out        => l_rowids);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CARE_PLAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            i := 1;
            FOR rec IN c_care_plan_task
            LOOP
                l_care_plan_task.extend(1);
                l_care_plan_task(i) := rec.id_care_plan_task;
            
                l_care_plan_task_status.extend(1);
                l_care_plan_task_status(i) := i_status;
            
                l_care_plan_task_cancel_reason.extend(1);
                l_care_plan_task_cancel_reason(i) := NULL;
            
                l_care_plan_task_notes.extend(1);
                l_care_plan_task_notes(i) := NULL;
            
                i := i + 1;
            END LOOP;
        
            g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
            IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                           i_prof,
                                                           l_care_plan_task,
                                                           l_care_plan_task_status,
                                                           l_care_plan_task_cancel_reason,
                                                           l_care_plan_task_notes,
                                                           o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_status;

    FUNCTION set_care_plan_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_care_plan               IN table_number,
        i_item                    IN table_varchar,
        i_task_type               IN table_number,
        i_care_plan_task_dt_begin IN table_varchar,
        i_care_plan_task_dt_end   IN table_varchar,
        i_num_exec                IN table_number,
        i_interval_unit           IN table_number,
        i_interval                IN table_number,
        i_care_plan_task_notes    IN table_varchar,
        o_msg                     OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_care_plan(l_care_plan care_plan.id_care_plan%TYPE) IS
            SELECT cp.name, cp.dt_begin, cp.dt_end
              FROM care_plan cp
             WHERE cp.id_care_plan = l_care_plan;
    
        CURSOR c_care_plan_task_count
        (
            l_care_plan care_plan_task_count.id_care_plan%TYPE,
            l_task_type care_plan_task_count.id_task_type%TYPE
        ) IS
            SELECT cptc.task_count
              FROM care_plan_task_count cptc
             WHERE cptc.id_care_plan = l_care_plan
               AND cptc.id_task_type = l_task_type;
    
        l_care_plan         c_care_plan%ROWTYPE;
        l_id_care_plan_task care_plan_task.id_care_plan_task%TYPE;
    
        l_care_plan_task_dt_begin care_plan_task.dt_begin%TYPE;
        l_care_plan_task_dt_end   care_plan_task.dt_begin%TYPE;
        l_dt_next_task            care_plan_task_req.dt_next_task%TYPE;
    
        l_flg_type            VARCHAR2(2);
        l_task_count          NUMBER;
        l_appointments        NUMBER := 0;
        l_opinions            NUMBER := 0;
        l_analysis            NUMBER := 0;
        l_group_analysis      NUMBER := 0;
        l_imaging_exams       NUMBER := 0;
        l_other_exams         NUMBER := 0;
        l_procedures          NUMBER := 0;
        l_patient_education   NUMBER := 0;
        l_ext_medication      NUMBER := 0;
        l_int_medication      NUMBER := 0;
        l_pharm_medication    NUMBER := 0;
        l_ivfluids_medication NUMBER := 0;
        l_diets               NUMBER := 0;
    
        l_msg VARCHAR2(4000);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_task_type.count
        LOOP
            IF i_task_type(i) IS NOT NULL
            THEN
                l_care_plan_task_dt_begin := pk_date_utils.get_string_tstz(i_lang,
                                                                           i_prof,
                                                                           i_care_plan_task_dt_begin(i),
                                                                           NULL);
                l_care_plan_task_dt_end   := pk_date_utils.get_string_tstz(i_lang,
                                                                           i_prof,
                                                                           i_care_plan_task_dt_end(i),
                                                                           NULL);
            
                IF l_care_plan_task_dt_end < l_care_plan_task_dt_begin
                THEN
                    l_care_plan_task_dt_end := l_care_plan_task_dt_begin;
                END IF;
            
                FOR k IN 1 .. i_care_plan.count
                LOOP
                    OPEN c_care_plan(i_care_plan(k));
                    FETCH c_care_plan
                        INTO l_care_plan;
                    CLOSE c_care_plan;
                
                    IF (l_care_plan_task_dt_begin < l_care_plan.dt_begin OR
                       l_care_plan_task_dt_begin > l_care_plan.dt_end)
                       OR
                       (l_care_plan_task_dt_end < l_care_plan.dt_begin OR l_care_plan_task_dt_end > l_care_plan.dt_end)
                    THEN
                        l_msg := l_msg || '@1<b>' || l_care_plan.name || ': </b>' || pk_message.get_message(i_lang, 'CARE_PLANS_T056') || ' ' ||
                                 pk_date_utils.date_char_tsz(i_lang, l_care_plan.dt_begin, i_prof.institution, i_prof.software) || '; ' || CASE
                                     WHEN l_care_plan.dt_end IS NOT NULL THEN
                                      pk_message.get_message(i_lang, 'CARE_PLANS_T004') || ' ' ||
                                      pk_date_utils.date_char_tsz(i_lang, l_care_plan.dt_end, i_prof.institution, i_prof.software)
                                     ELSE
                                      ''
                                 END;
                        IF i_care_plan(k) != i_care_plan.last
                        THEN
                            l_msg := l_msg || chr(10);
                        END IF;
                    END IF;
                END LOOP;
            
                IF l_msg IS NOT NULL
                THEN
                    o_msg := REPLACE(pk_message.get_message(i_lang, 'CARE_PLANS_M001'), '@2', l_msg);
                    RAISE g_user_exception;
                END IF;
            
                g_error := 'INSERT INTO CARE_PLAN_TASK';
                INSERT INTO care_plan_task
                    (id_care_plan_task,
                     id_prof,
                     dt_care_plan_task,
                     id_item,
                     flg_status,
                     id_task_type,
                     dt_begin,
                     dt_end,
                     num_exec,
                     id_unit_measure,
                     INTERVAL,
                     notes,
                     id_prof_cancel,
                     dt_cancel,
                     id_cancel_reason,
                     notes_cancel)
                VALUES
                    (seq_care_plan_task.nextval,
                     i_prof.id,
                     g_sysdate_tstz,
                     i_item(i),
                     g_pending,
                     i_task_type(i),
                     l_care_plan_task_dt_begin,
                     l_care_plan_task_dt_end,
                     i_num_exec(i),
                     i_interval_unit(i),
                     i_interval(i),
                     i_care_plan_task_notes(i),
                     NULL,
                     NULL,
                     NULL,
                     NULL)
                RETURNING id_care_plan_task INTO l_id_care_plan_task;
            
                FOR j IN 1 .. i_care_plan.count
                LOOP
                    g_error := 'INSERT INTO CARE_PLAN_TASK_LINK';
                    INSERT INTO care_plan_task_link
                        (id_care_plan, id_care_plan_task)
                    VALUES
                        (i_care_plan(j), l_id_care_plan_task);
                END LOOP;
            
                IF i_num_exec(i) IS NOT NULL
                THEN
                    IF i_num_exec(i) >= 1
                    THEN
                    
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 1';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (l_id_care_plan_task, 1, l_care_plan_task_dt_begin, NULL, g_pending, i_task_type(i))
                        RETURNING dt_next_task INTO l_dt_next_task;
                    
                        FOR k IN 2 .. i_num_exec(i)
                        LOOP
                            g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 2';
                            INSERT INTO care_plan_task_req
                                (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                            VALUES
                                (l_id_care_plan_task,
                                 k,
                                 decode(i_interval_unit(i),
                                        g_day,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                        g_week,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                        g_month,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                        g_year,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                                 NULL,
                                 g_pending,
                                 i_task_type(i))
                            RETURNING dt_next_task INTO l_dt_next_task;
                        END LOOP;
                    END IF;
                ELSE
                    IF i_interval(i) IS NOT NULL
                    THEN
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 3';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (l_id_care_plan_task, 1, l_care_plan_task_dt_begin, NULL, g_pending, i_task_type(i))
                        RETURNING dt_next_task INTO l_dt_next_task;
                    
                        FOR k IN 2 .. 10
                        LOOP
                            g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 4';
                            INSERT INTO care_plan_task_req
                                (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                            VALUES
                                (l_id_care_plan_task,
                                 k,
                                 decode(i_interval_unit(i),
                                        g_day,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                        g_week,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                        g_month,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                        g_year,
                                        pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                                 NULL,
                                 g_pending,
                                 i_task_type(i))
                            RETURNING dt_next_task INTO l_dt_next_task;
                        END LOOP;
                    ELSE
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 3';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (l_id_care_plan_task, 1, l_care_plan_task_dt_begin, NULL, g_pending, i_task_type(i));
                    END IF;
                END IF;
            END IF;
        
            FOR j IN 1 .. i_care_plan.count
            LOOP
                g_error := 'OPEN C_CARE_PLAN_TASK_COUNT';
                OPEN c_care_plan_task_count(i_care_plan(j), i_task_type(i));
                FETCH c_care_plan_task_count
                    INTO l_task_count;
                g_found := c_care_plan_task_count%FOUND;
                CLOSE c_care_plan_task_count;
            
                IF NOT g_found
                THEN
                    l_task_count := 0;
                END IF;
            
                l_flg_type := pk_task_type.get_task_type_flg(i_lang, i_task_type(i));
            
                IF l_flg_type IN (g_appointments, g_spec_appointments)
                THEN
                    l_appointments := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_appointments task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_opinions
                THEN
                    l_opinions := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_opinions task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_analysis
                THEN
                    l_analysis := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_analysis task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_group_analysis
                THEN
                    l_group_analysis := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_group_analysis task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_imaging_exams
                THEN
                    l_imaging_exams := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_imaging_exams task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_other_exams
                THEN
                    l_other_exams := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_other_exams task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_procedures
                THEN
                    l_procedures := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_procedures task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_patient_education
                THEN
                    l_patient_education := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan,
                                  i_task_type(i) id_task_type,
                                  l_patient_education task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_medication
                THEN
                    l_ext_medication := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_ext_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_ext_medication
                THEN
                    l_ext_medication := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_ext_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_int_medication
                THEN
                    l_int_medication := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_int_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_pharm_medication
                THEN
                    l_pharm_medication := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan,
                                  i_task_type(i) id_task_type,
                                  l_pharm_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_ivfluids_medication
                THEN
                    l_ivfluids_medication := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan,
                                  i_task_type(i) id_task_type,
                                  l_ivfluids_medication task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                
                ELSIF l_flg_type = g_diets
                THEN
                    l_diets := l_task_count + 1;
                
                    MERGE INTO care_plan_task_count cptc
                    USING (SELECT i_care_plan(j) id_care_plan, i_task_type(i) id_task_type, l_diets task_count
                             FROM dual) t
                    ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type AND (t.task_count != 0 OR t.task_count > cptc.task_count))
                    WHEN MATCHED THEN
                        UPDATE
                           SET task_count = t.task_count
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_care_plan, id_task_type, task_count)
                        VALUES
                            (t.id_care_plan, t.id_task_type, t.task_count);
                END IF;
            END LOOP;
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CARE_PLAN_TASK',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task;

    FUNCTION update_care_plan_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_num_exec       IN table_number,
        i_interval_unit  IN table_number,
        i_interval       IN table_number,
        i_notes          IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_care_plan_task(l_care_plan_task care_plan_task.id_care_plan_task%TYPE) IS
            SELECT *
              FROM care_plan_task cpt
             WHERE cpt.id_care_plan_task = l_care_plan_task;
    
        l_care_plan_task_hist c_care_plan_task%ROWTYPE;
    
        l_care_plan_task_dt_begin care_plan_task.dt_begin%TYPE;
        l_care_plan_task_dt_end   care_plan_task.dt_begin%TYPE;
        l_dt_next_task            care_plan_task_req.dt_next_task%TYPE;
    
        l_count NUMBER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_care_plan_task.count
        LOOP
        
            g_error := 'GET CURSOR';
            OPEN c_care_plan_task(i_care_plan_task(i));
            FETCH c_care_plan_task
                INTO l_care_plan_task_hist;
            CLOSE c_care_plan_task;
        
            g_error := 'INSERT INTO CARE_PLAN_TASK_HIST';
            INSERT INTO care_plan_task_hist
                (dt_care_plan_task_hist,
                 id_care_plan_task,
                 id_prof,
                 dt_care_plan_task,
                 id_item,
                 flg_status,
                 id_task_type,
                 dt_begin,
                 dt_end,
                 num_exec,
                 id_unit_measure,
                 INTERVAL,
                 notes,
                 id_prof_cancel,
                 dt_cancel,
                 id_cancel_reason,
                 notes_cancel)
            VALUES
                (g_sysdate_tstz,
                 l_care_plan_task_hist.id_care_plan_task,
                 l_care_plan_task_hist.id_prof,
                 l_care_plan_task_hist.dt_care_plan_task,
                 l_care_plan_task_hist.id_item,
                 l_care_plan_task_hist.flg_status,
                 l_care_plan_task_hist.id_task_type,
                 l_care_plan_task_hist.dt_begin,
                 l_care_plan_task_hist.dt_end,
                 l_care_plan_task_hist.num_exec,
                 l_care_plan_task_hist.id_unit_measure,
                 l_care_plan_task_hist.interval,
                 l_care_plan_task_hist.notes,
                 l_care_plan_task_hist.id_prof_cancel,
                 l_care_plan_task_hist.dt_cancel,
                 l_care_plan_task_hist.id_cancel_reason,
                 l_care_plan_task_hist.notes_cancel);
        
            l_care_plan_task_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin(i), NULL);
            l_care_plan_task_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end(i), NULL);
        
            IF l_care_plan_task_dt_begin < g_sysdate_tstz
            THEN
                l_care_plan_task_dt_begin := g_sysdate_tstz;
            END IF;
        
            IF l_care_plan_task_dt_end < l_care_plan_task_dt_begin
            THEN
                l_care_plan_task_dt_end := l_care_plan_task_dt_begin;
            END IF;
        
            g_error := 'UPDATE CARE_PLAN_TASK';
            UPDATE care_plan_task
               SET dt_begin        = l_care_plan_task_dt_begin,
                   dt_end          = l_care_plan_task_dt_end,
                   num_exec        = i_num_exec(i),
                   id_unit_measure = i_interval_unit(i),
                   INTERVAL        = i_interval(i),
                   notes           = i_notes(i)
             WHERE id_care_plan_task = i_care_plan_task(i);
        
            IF i_num_exec(i) IS NOT NULL
            THEN
                DELETE care_plan_task_req
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND id_req IS NULL;
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM care_plan_task_req
                 WHERE id_care_plan_task = i_care_plan_task(i);
            
                IF i_num_exec(i) > 1
                THEN
                
                    g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 1';
                    INSERT INTO care_plan_task_req
                        (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                    VALUES
                        (i_care_plan_task(i),
                         l_count + 1,
                         l_care_plan_task_dt_begin,
                         NULL,
                         g_pending,
                         l_care_plan_task_hist.id_task_type)
                    RETURNING dt_next_task INTO l_dt_next_task;
                
                    FOR k IN 2 .. i_num_exec(i)
                    LOOP
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 2';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (i_care_plan_task(i),
                             l_count + k,
                             decode(i_interval_unit(i),
                                    g_day,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                    g_week,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                    g_month,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                    g_year,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                             NULL,
                             g_pending,
                             l_care_plan_task_hist.id_task_type)
                        RETURNING dt_next_task INTO l_dt_next_task;
                    END LOOP;
                
                ELSIF i_num_exec(i) = 1
                THEN
                
                    g_error := 'INSERT INTO CARE_PLAN_TASK_REQ_SINGLE';
                    INSERT INTO care_plan_task_req
                        (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                    VALUES
                        (i_care_plan_task(i),
                         l_count + 1,
                         l_care_plan_task_dt_begin,
                         NULL,
                         g_pending,
                         l_care_plan_task_hist.id_task_type);
                
                END IF;
            ELSE
                DELETE care_plan_task_req
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND id_req IS NULL;
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM care_plan_task_req
                 WHERE id_care_plan_task = i_care_plan_task(i);
            
                IF i_interval(i) IS NOT NULL
                THEN
                    g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 3';
                    INSERT INTO care_plan_task_req
                        (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                    VALUES
                        (i_care_plan_task(i),
                         1,
                         l_care_plan_task_dt_begin,
                         NULL,
                         g_pending,
                         l_care_plan_task_hist.id_task_type)
                    RETURNING dt_next_task INTO l_dt_next_task;
                
                    FOR k IN 2 .. 10
                    LOOP
                        g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 4';
                        INSERT INTO care_plan_task_req
                            (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                        VALUES
                            (i_care_plan_task(i),
                             k,
                             decode(i_interval_unit(i),
                                    g_day,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i))),
                                    g_week,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 7)),
                                    g_month,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 30)),
                                    g_year,
                                    pk_date_utils.add_days_to_tstz(l_dt_next_task, (i_interval(i) * 365))),
                             NULL,
                             g_pending,
                             l_care_plan_task_hist.id_task_type)
                        RETURNING dt_next_task INTO l_dt_next_task;
                    END LOOP;
                ELSE
                    g_error := 'INSERT INTO CARE_PLAN_TASK_REQ 5';
                    INSERT INTO care_plan_task_req
                        (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                    VALUES
                        (i_care_plan_task(i),
                         1,
                         l_care_plan_task_dt_begin,
                         NULL,
                         g_pending,
                         l_care_plan_task_hist.id_task_type);
                END IF;
            END IF;
        END LOOP;
    
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
                                              'UPDATE_CARE_PLAN_TASK',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_care_plan_task;

    FUNCTION set_care_plan_task_association
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan      IN table_number,
        i_care_plan_task IN table_number,
        i_flg_set        VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_flg_set = 'A'
        THEN
            FOR i IN 1 .. i_care_plan_task.count
            LOOP
                FOR k IN 1 .. i_care_plan.count
                LOOP
                    g_error := 'INSERT INTO CARE_PLAN_TASK_LINK';
                    INSERT INTO care_plan_task_link
                        (id_care_plan, id_care_plan_task)
                    VALUES
                        (i_care_plan(k), i_care_plan_task(i));
                END LOOP;
            END LOOP;
        ELSE
            FOR i IN 1 .. i_care_plan_task.count
            LOOP
                FOR k IN 1 .. i_care_plan.count
                LOOP
                    g_error := 'DELETE CARE_PLAN_TASK_LINK';
                    DELETE care_plan_task_link
                     WHERE id_care_plan = i_care_plan(k)
                       AND id_care_plan_task = i_care_plan_task(i);
                END LOOP;
            END LOOP;
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
                                              'SET_CARE_PLAN_TASK_ASSOCIATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_association;

    FUNCTION set_care_plan_task_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        i_status         IN table_varchar,
        i_cancel_reason  IN table_number,
        i_notes_cancel   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_count(l_care_plan_task care_plan_task.id_care_plan_task%TYPE) IS
            SELECT *
              FROM (SELECT COUNT(cptr.id_care_plan_task) task_count, cpt.num_exec
                      FROM care_plan_task cpt, care_plan_task_req cptr
                     WHERE cpt.id_care_plan_task = l_care_plan_task
                       AND cpt.id_care_plan_task = cptr.id_care_plan_task
                       AND (cptr.id_req IS NULL OR cptr.id_req = -1)
                     GROUP BY cptr.id_care_plan_task, cpt.num_exec)
             WHERE task_count != num_exec;
    
        CURSOR c_care_plan_task_count(l_care_plan_task care_plan_task.id_care_plan_task%TYPE) IS
            SELECT cptc.id_care_plan, cptc.id_task_type, cptc.task_count
              FROM care_plan_task cpt, care_plan_task_link cptl, care_plan_task_count cptc
             WHERE cpt.id_care_plan_task = l_care_plan_task
               AND cpt.flg_status NOT IN (g_canceled, g_interrupted)
               AND cpt.id_care_plan_task = cptl.id_care_plan_task
               AND cptl.id_care_plan = cptc.id_care_plan
               AND cpt.id_task_type = cptc.id_task_type;
    
        l_care_plan_hist      care_plan%ROWTYPE;
        l_care_plan_task_hist care_plan_task%ROWTYPE;
    
        l_count c_count%ROWTYPE;
    
        l_flg_type            VARCHAR2(2);
        l_appointments        NUMBER := 0;
        l_opinions            NUMBER := 0;
        l_analysis            NUMBER := 0;
        l_group_analysis      NUMBER := 0;
        l_imaging_exams       NUMBER := 0;
        l_other_exams         NUMBER := 0;
        l_procedures          NUMBER := 0;
        l_patient_education   NUMBER := 0;
        l_ext_medication      NUMBER := 0;
        l_int_medication      NUMBER := 0;
        l_pharm_medication    NUMBER := 0;
        l_ivfluids_medication NUMBER := 0;
        l_diets               NUMBER := 0;
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_care_plan_task.count
        LOOP
        
            SELECT *
              INTO l_care_plan_task_hist
              FROM care_plan_task cpt
             WHERE cpt.id_care_plan_task = i_care_plan_task(i);
        
            IF i_status(i) IN (g_canceled, g_interrupted)
            THEN
            
                IF l_care_plan_task_hist.flg_status NOT IN (g_finished, g_canceled, g_interrupted)
                THEN
                    INSERT INTO care_plan_task_hist
                        (dt_care_plan_task_hist,
                         id_care_plan_task,
                         id_prof,
                         dt_care_plan_task,
                         id_item,
                         flg_status,
                         id_task_type,
                         dt_begin,
                         dt_end,
                         num_exec,
                         id_unit_measure,
                         INTERVAL,
                         notes,
                         id_prof_cancel,
                         dt_cancel,
                         id_cancel_reason,
                         notes_cancel)
                    VALUES
                        (g_sysdate_tstz,
                         l_care_plan_task_hist.id_care_plan_task,
                         l_care_plan_task_hist.id_prof,
                         l_care_plan_task_hist.dt_care_plan_task,
                         l_care_plan_task_hist.id_item,
                         l_care_plan_task_hist.flg_status,
                         l_care_plan_task_hist.id_task_type,
                         l_care_plan_task_hist.dt_begin,
                         l_care_plan_task_hist.dt_end,
                         l_care_plan_task_hist.num_exec,
                         l_care_plan_task_hist.id_unit_measure,
                         l_care_plan_task_hist.interval,
                         l_care_plan_task_hist.notes,
                         l_care_plan_task_hist.id_prof_cancel,
                         l_care_plan_task_hist.dt_cancel,
                         l_care_plan_task_hist.id_cancel_reason,
                         l_care_plan_task_hist.notes_cancel);
                END IF;
            
                FOR k IN c_care_plan_task_count(i_care_plan_task(i))
                LOOP
                    l_flg_type := pk_task_type.get_task_type_flg(i_lang, k.id_task_type);
                
                    IF l_flg_type IN (g_appointments, g_spec_appointments)
                    THEN
                        l_appointments := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan id_care_plan,
                                      k.id_task_type id_task_type,
                                      l_appointments task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_opinions
                    THEN
                        l_opinions := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan id_care_plan, k.id_task_type id_task_type, l_opinions task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_analysis
                    THEN
                        l_analysis := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan id_care_plan, k.id_task_type id_task_type, l_analysis task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_group_analysis
                    THEN
                        l_group_analysis := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan   id_care_plan,
                                      k.id_task_type   id_task_type,
                                      l_group_analysis task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_imaging_exams
                    THEN
                        l_imaging_exams := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan  id_care_plan,
                                      k.id_task_type  id_task_type,
                                      l_imaging_exams task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_other_exams
                    THEN
                        l_other_exams := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan id_care_plan, k.id_task_type id_task_type, l_other_exams task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_procedures
                    THEN
                        l_procedures := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan id_care_plan, k.id_task_type id_task_type, l_procedures task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_patient_education
                    THEN
                        l_patient_education := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan      id_care_plan,
                                      k.id_task_type      id_task_type,
                                      l_patient_education task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_ext_medication
                    THEN
                        l_ext_medication := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan   id_care_plan,
                                      k.id_task_type   id_task_type,
                                      l_ext_medication task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_int_medication
                    THEN
                        l_int_medication := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan   id_care_plan,
                                      k.id_task_type   id_task_type,
                                      l_int_medication task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_pharm_medication
                    THEN
                        l_pharm_medication := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan     id_care_plan,
                                      k.id_task_type     id_task_type,
                                      l_pharm_medication task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_ivfluids_medication
                    THEN
                        l_ivfluids_medication := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan        id_care_plan,
                                      k.id_task_type        id_task_type,
                                      l_ivfluids_medication task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    ELSIF l_flg_type = g_diets
                    THEN
                        l_diets := k.task_count - 1;
                    
                        MERGE INTO care_plan_task_count cptc
                        USING (SELECT k.id_care_plan id_care_plan, k.id_task_type id_task_type, l_diets task_count
                                 FROM dual) t
                        ON (cptc.id_care_plan = t.id_care_plan AND cptc.id_task_type = t.id_task_type)
                        WHEN MATCHED THEN
                            UPDATE
                               SET task_count = t.task_count;
                    
                    END IF;
                END LOOP;
            
                g_error := 'UPDATE CARE_PLAN_TASK';
                UPDATE care_plan_task
                   SET flg_status       = i_status(i),
                       id_prof_cancel   = i_prof.id,
                       dt_cancel        = g_sysdate_tstz,
                       id_cancel_reason = i_cancel_reason(i),
                       notes_cancel     = i_notes_cancel(i)
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND flg_status NOT IN (g_finished, g_canceled, g_interrupted);
            
                g_error := 'UPDATE CARE_PLAN_TASK_REQ';
                UPDATE care_plan_task_req
                   SET id_req = -1, flg_status = i_status(i)
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND id_req IS NULL
                   AND flg_status NOT IN (g_ordered, g_canceled, g_interrupted);
            
            ELSIF i_status(i) = g_suspended
            THEN
                SELECT *
                  INTO l_care_plan_task_hist
                  FROM care_plan_task cpt
                 WHERE cpt.id_care_plan_task = i_care_plan_task(i);
            
                IF l_care_plan_task_hist.flg_status NOT IN (g_suspended, g_finished, g_canceled, g_interrupted)
                THEN
                    INSERT INTO care_plan_task_hist
                        (dt_care_plan_task_hist,
                         id_care_plan_task,
                         id_prof,
                         dt_care_plan_task,
                         id_item,
                         flg_status,
                         id_task_type,
                         dt_begin,
                         dt_end,
                         num_exec,
                         id_unit_measure,
                         INTERVAL,
                         notes,
                         id_prof_cancel,
                         dt_cancel,
                         id_cancel_reason,
                         notes_cancel)
                    VALUES
                        (g_sysdate_tstz,
                         l_care_plan_task_hist.id_care_plan_task,
                         l_care_plan_task_hist.id_prof,
                         l_care_plan_task_hist.dt_care_plan_task,
                         l_care_plan_task_hist.id_item,
                         l_care_plan_task_hist.flg_status,
                         l_care_plan_task_hist.id_task_type,
                         l_care_plan_task_hist.dt_begin,
                         l_care_plan_task_hist.dt_end,
                         l_care_plan_task_hist.num_exec,
                         l_care_plan_task_hist.id_unit_measure,
                         l_care_plan_task_hist.interval,
                         l_care_plan_task_hist.notes,
                         l_care_plan_task_hist.id_prof_cancel,
                         l_care_plan_task_hist.dt_cancel,
                         l_care_plan_task_hist.id_cancel_reason,
                         l_care_plan_task_hist.notes_cancel);
                END IF;
            
                g_error := 'UPDATE CARE_PLAN_TASK';
                UPDATE care_plan_task
                   SET dt_care_plan_task = g_sysdate_tstz, flg_status = i_status(i)
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND flg_status NOT IN (g_finished, g_canceled, g_interrupted);
            
                g_error := 'UPDATE CARE_PLAN_TASK_REQ';
                UPDATE care_plan_task_req
                   SET flg_status = i_status(i)
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND id_req IS NULL
                   AND flg_status NOT IN (g_ordered, g_canceled, g_interrupted);
            
            ELSIF i_status(i) = g_active
            THEN
            
                IF l_care_plan_task_hist.flg_status NOT IN (g_finished, g_canceled, g_interrupted)
                THEN
                    INSERT INTO care_plan_task_hist
                        (dt_care_plan_task_hist,
                         id_care_plan_task,
                         id_prof,
                         dt_care_plan_task,
                         id_item,
                         flg_status,
                         id_task_type,
                         dt_begin,
                         dt_end,
                         num_exec,
                         id_unit_measure,
                         INTERVAL,
                         notes,
                         id_prof_cancel,
                         dt_cancel,
                         id_cancel_reason,
                         notes_cancel)
                    VALUES
                        (g_sysdate_tstz,
                         l_care_plan_task_hist.id_care_plan_task,
                         l_care_plan_task_hist.id_prof,
                         l_care_plan_task_hist.dt_care_plan_task,
                         l_care_plan_task_hist.id_item,
                         l_care_plan_task_hist.flg_status,
                         l_care_plan_task_hist.id_task_type,
                         l_care_plan_task_hist.dt_begin,
                         l_care_plan_task_hist.dt_end,
                         l_care_plan_task_hist.num_exec,
                         l_care_plan_task_hist.id_unit_measure,
                         l_care_plan_task_hist.interval,
                         l_care_plan_task_hist.notes,
                         l_care_plan_task_hist.id_prof_cancel,
                         l_care_plan_task_hist.dt_cancel,
                         l_care_plan_task_hist.id_cancel_reason,
                         l_care_plan_task_hist.notes_cancel);
                END IF;
            
                g_error := 'GET CURSOR';
                OPEN c_count(i_care_plan_task(i));
                FETCH c_count
                    INTO l_count;
                g_found := c_count%FOUND;
                CLOSE c_count;
            
                IF NOT g_found
                THEN
                    g_error := 'UPDATE CARE_PLAN_TASK 1';
                    UPDATE care_plan_task
                       SET dt_care_plan_task = g_sysdate_tstz, flg_status = g_pending
                     WHERE id_care_plan_task = i_care_plan_task(i)
                       AND flg_status != g_finished;
                ELSE
                    g_error := 'UPDATE CARE_PLAN_TASK 2';
                    UPDATE care_plan_task
                       SET dt_care_plan_task = g_sysdate_tstz, flg_status = g_inprogress
                     WHERE id_care_plan_task = i_care_plan_task(i)
                       AND flg_status != g_finished;
                END IF;
            
                SELECT cp.*
                  INTO l_care_plan_hist
                  FROM care_plan cp, care_plan_task_link cptl
                 WHERE cp.id_care_plan = cptl.id_care_plan
                   AND cptl.id_care_plan_task = i_care_plan_task(i);
            
                IF l_care_plan_hist.flg_status = g_suspended
                THEN
                    g_error := 'INSERT INTO CARE_PLAN_HIST';
                    ts_care_plan_hist.ins(dt_care_plan_hist_in   => g_sysdate_tstz,
                                          id_care_plan_in        => l_care_plan_hist.id_care_plan,
                                          id_prof_in             => l_care_plan_hist.id_prof,
                                          dt_care_plan_in        => l_care_plan_hist.dt_care_plan,
                                          id_patient_in          => l_care_plan_hist.id_patient,
                                          flg_status_in          => l_care_plan_hist.flg_status,
                                          name_in                => l_care_plan_hist.name,
                                          id_care_plan_type_in   => l_care_plan_hist.id_care_plan_type,
                                          dt_begin_in            => l_care_plan_hist.dt_begin,
                                          dt_end_in              => l_care_plan_hist.dt_end,
                                          subject_type_in        => l_care_plan_hist.subject_type,
                                          id_subject_in          => l_care_plan_hist.id_subject,
                                          id_prof_coordinator_in => l_care_plan_hist.id_prof_coordinator,
                                          goals_in               => l_care_plan_hist.goals,
                                          notes_in               => l_care_plan_hist.notes,
                                          id_prof_cancel_in      => l_care_plan_hist.id_prof_cancel,
                                          dt_cancel_in           => l_care_plan_hist.dt_cancel,
                                          id_cancel_reason_in    => l_care_plan_hist.id_cancel_reason,
                                          notes_cancel_in        => l_care_plan_hist.notes_cancel,
                                          id_episode_in          => l_care_plan_hist.id_episode,
                                          rows_out               => l_rowids);
                
                    g_error := 'UPDATE T_DATA_GOV_MNT-CARE_PLAN_HIST';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'CARE_PLAN_HIST',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            
                g_error := 'UPDATE CARE_PLAN';
                ts_care_plan.upd(dt_care_plan_in => g_sysdate_tstz,
                                 flg_status_in   => g_inprogress,
                                 str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_inprogress),
                                 where_in        => 'id_care_plan = (SELECT id_care_plan
                                         FROM care_plan_task_link
                                        WHERE id_care_plan_task = ' ||
                                                    i_care_plan_task(i) || ')
                   AND flg_status = ''' || g_suspended || '''',
                                 rows_out        => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'UPDATE CARE_PLAN_TASK_REQ';
                UPDATE care_plan_task_req
                   SET flg_status = g_pending
                 WHERE id_care_plan_task = i_care_plan_task(i)
                   AND id_req IS NULL
                   AND flg_status NOT IN (g_ordered, g_canceled, g_interrupted);
            
            ELSE
                IF l_care_plan_task_hist.flg_status NOT IN (g_finished, g_canceled, g_interrupted)
                THEN
                    INSERT INTO care_plan_task_hist
                        (dt_care_plan_task_hist,
                         id_care_plan_task,
                         id_prof,
                         dt_care_plan_task,
                         id_item,
                         flg_status,
                         id_task_type,
                         dt_begin,
                         dt_end,
                         num_exec,
                         id_unit_measure,
                         INTERVAL,
                         notes,
                         id_prof_cancel,
                         dt_cancel,
                         id_cancel_reason,
                         notes_cancel)
                    VALUES
                        (g_sysdate_tstz,
                         l_care_plan_task_hist.id_care_plan_task,
                         l_care_plan_task_hist.id_prof,
                         l_care_plan_task_hist.dt_care_plan_task,
                         l_care_plan_task_hist.id_item,
                         l_care_plan_task_hist.flg_status,
                         l_care_plan_task_hist.id_task_type,
                         l_care_plan_task_hist.dt_begin,
                         l_care_plan_task_hist.dt_end,
                         l_care_plan_task_hist.num_exec,
                         l_care_plan_task_hist.id_unit_measure,
                         l_care_plan_task_hist.interval,
                         l_care_plan_task_hist.notes,
                         l_care_plan_task_hist.id_prof_cancel,
                         l_care_plan_task_hist.dt_cancel,
                         l_care_plan_task_hist.id_cancel_reason,
                         l_care_plan_task_hist.notes_cancel);
                END IF;
            
                g_error := 'UPDATE CARE_PLAN_TASK 3';
                UPDATE care_plan_task
                   SET dt_care_plan_task = g_sysdate_tstz, flg_status = i_status(i)
                 WHERE id_care_plan_task = i_care_plan_task(i);
            
            END IF;
        END LOOP;
    
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
                                              'SET_CARE_PLAN_TASK_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_status;

    FUNCTION set_care_plan_task_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task_req.id_care_plan_task%TYPE,
        i_task_type      IN care_plan_task_req.id_task_type%TYPE,
        i_order_num      IN care_plan_task_req.order_num%TYPE,
        i_req            IN care_plan_task_req.id_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_care_plan IS
            SELECT cp.*
              FROM care_plan cp, care_plan_task_link cptl
             WHERE cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = i_care_plan_task;
    
        CURSOR c_care_plan_task IS
            SELECT cpt.*
              FROM care_plan_task cpt
             WHERE cpt.id_care_plan_task = i_care_plan_task;
    
        CURSOR c_care_plan_task_req IS
            SELECT cptr.*
              FROM care_plan_task_req cptr
             WHERE cptr.id_care_plan_task = i_care_plan_task
               AND cptr.order_num = (SELECT MAX(r.order_num)
                                       FROM care_plan_task_req r
                                      WHERE r.id_care_plan_task = cptr.id_care_plan_task);
    
        CURSOR c_care_plan_req_count(l_care_plan care_plan.id_care_plan%TYPE) IS
            SELECT COUNT(1)
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task_req cptr
             WHERE cp.id_care_plan = l_care_plan
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cptr.id_care_plan_task
               AND cptr.id_req IS NULL;
    
        CURSOR c_care_plan_task_req_count IS
            SELECT COUNT(1)
              FROM care_plan_task_req r
             WHERE r.id_care_plan_task = i_care_plan_task
               AND r.id_req IS NULL;
    
        l_care_plan_hist     c_care_plan%ROWTYPE;
        l_care_plan_task     c_care_plan_task%ROWTYPE;
        l_care_plan_task_req c_care_plan_task_req%ROWTYPE;
    
        l_order_num care_plan_task_req.order_num%TYPE;
        l_count     NUMBER;
    
        l_care_plan_task_status table_varchar := table_varchar();
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_order_num IS NOT NULL
        THEN
            l_order_num := i_order_num;
        ELSE
            BEGIN
                SELECT MIN(cptr.order_num)
                  INTO l_order_num
                  FROM care_plan_task_req cptr
                 WHERE cptr.id_care_plan_task = i_care_plan_task
                   AND cptr.id_req IS NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    l_order_num := NULL;
            END;
        END IF;
    
        g_error := 'UPDATE CARE_PLAN_TASK_REQ 1';
        UPDATE care_plan_task_req
           SET id_req = i_req, flg_status = g_ordered, id_task_type = i_task_type
         WHERE id_care_plan_task = i_care_plan_task
           AND id_req IS NULL
           AND order_num = l_order_num;
    
        g_error := 'UPDATE CARE_PLAN_TASK_REQ 2';
        UPDATE care_plan_task_req
           SET id_req = -1, flg_status = g_canceled
         WHERE id_care_plan_task = i_care_plan_task
           AND id_req IS NULL
           AND order_num IN (SELECT order_num
                               FROM care_plan_task_req r
                              WHERE r.id_req IS NULL
                                AND r.id_care_plan_task = i_care_plan_task
                                AND r.order_num < l_order_num);
    
        g_error := 'OPEN C_CARE_PLAN_TASK';
        OPEN c_care_plan_task;
        FETCH c_care_plan_task
            INTO l_care_plan_task;
        CLOSE c_care_plan_task;
    
        IF l_care_plan_task.num_exec IS NULL
        THEN
            g_error := 'OPEN C_CARE_PLAN_TASK_REQ';
            OPEN c_care_plan_task_req;
            FETCH c_care_plan_task_req
                INTO l_care_plan_task_req;
            CLOSE c_care_plan_task_req;
        
            IF l_care_plan_task_req.dt_next_task IS NOT NULL
            THEN
                g_error := 'INSERT INTO CARE_PLAN_TASK_REQ';
                INSERT INTO care_plan_task_req
                    (id_care_plan_task, order_num, dt_next_task, id_req, flg_status, id_task_type)
                VALUES
                    (l_care_plan_task_req.id_care_plan_task,
                     l_care_plan_task_req.order_num + 1,
                     decode(l_care_plan_task.id_unit_measure,
                            g_day,
                            pk_date_utils.add_days_to_tstz(l_care_plan_task_req.dt_next_task,
                                                           (l_care_plan_task.interval)),
                            g_week,
                            pk_date_utils.add_days_to_tstz(l_care_plan_task_req.dt_next_task,
                                                           (l_care_plan_task.interval * 7)),
                            g_month,
                            pk_date_utils.add_days_to_tstz(l_care_plan_task_req.dt_next_task,
                                                           (l_care_plan_task.interval * 30)),
                            g_year,
                            pk_date_utils.add_days_to_tstz(l_care_plan_task_req.dt_next_task,
                                                           (l_care_plan_task.interval * 365))),
                     NULL,
                     g_pending,
                     l_care_plan_task_req.id_task_type);
            END IF;
        END IF;
    
        IF l_care_plan_task.flg_status = g_pending
        THEN
            g_error := 'OPEN C_CARE_PLAN_TASK_REQ_COUNT';
            OPEN c_care_plan_task_req_count;
            FETCH c_care_plan_task_req_count
                INTO l_count;
            CLOSE c_care_plan_task_req_count;
        
            IF l_count > 0
            THEN
                l_care_plan_task_status.extend;
                l_care_plan_task_status(1) := g_inprogress;
            ELSE
                l_care_plan_task_status.extend;
                l_care_plan_task_status(1) := g_finished;
            END IF;
        
            g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
            IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                           i_prof,
                                                           table_number(i_care_plan_task),
                                                           l_care_plan_task_status,
                                                           NULL,
                                                           NULL,
                                                           o_error)
            THEN
                ROLLBACK;
            END IF;
        ELSE
            g_error := 'OPEN C_CARE_PLAN_TASK_REQ_COUNT';
            OPEN c_care_plan_task_req_count;
            FETCH c_care_plan_task_req_count
                INTO l_count;
            CLOSE c_care_plan_task_req_count;
        
            IF l_count = 0
            THEN
                l_care_plan_task_status.extend;
                l_care_plan_task_status(1) := g_finished;
            
                g_error := 'CALL SET_CARE_PLAN_TASK_STATUS';
                IF NOT pk_care_plans.set_care_plan_task_status(i_lang,
                                                               i_prof,
                                                               table_number(i_care_plan_task),
                                                               l_care_plan_task_status,
                                                               NULL,
                                                               NULL,
                                                               o_error)
                THEN
                    ROLLBACK;
                END IF;
            END IF;
        END IF;
    
        g_error := 'OPEN C_CARE_PLAN';
        OPEN c_care_plan;
        FETCH c_care_plan
            INTO l_care_plan_hist;
        CLOSE c_care_plan;
    
        g_error := 'INSERT INTO CARE_PLAN_HIST';
        ts_care_plan_hist.ins(dt_care_plan_hist_in   => g_sysdate_tstz,
                              id_care_plan_in        => l_care_plan_hist.id_care_plan,
                              id_prof_in             => l_care_plan_hist.id_prof,
                              dt_care_plan_in        => l_care_plan_hist.dt_care_plan,
                              id_patient_in          => l_care_plan_hist.id_patient,
                              flg_status_in          => l_care_plan_hist.flg_status,
                              name_in                => l_care_plan_hist.name,
                              id_care_plan_type_in   => l_care_plan_hist.id_care_plan_type,
                              dt_begin_in            => l_care_plan_hist.dt_begin,
                              dt_end_in              => l_care_plan_hist.dt_end,
                              subject_type_in        => l_care_plan_hist.subject_type,
                              id_subject_in          => l_care_plan_hist.id_subject,
                              id_prof_coordinator_in => l_care_plan_hist.id_prof_coordinator,
                              goals_in               => l_care_plan_hist.goals,
                              notes_in               => l_care_plan_hist.notes,
                              id_prof_cancel_in      => l_care_plan_hist.id_prof_cancel,
                              dt_cancel_in           => l_care_plan_hist.dt_cancel,
                              id_cancel_reason_in    => l_care_plan_hist.id_cancel_reason,
                              notes_cancel_in        => l_care_plan_hist.notes_cancel,
                              id_episode_in          => l_care_plan_hist.id_episode,
                              rows_out               => l_rowids);
    
        g_error := 'CALL PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CARE_PLAN_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF l_care_plan_hist.flg_status = g_pending
        THEN
            OPEN c_care_plan_req_count(l_care_plan_hist.id_care_plan);
            FETCH c_care_plan_req_count
                INTO l_count;
            CLOSE c_care_plan_req_count;
        
            IF l_count = 0
            THEN
                g_error := 'UPDATE CARE_PLAN 1';
                ts_care_plan.upd(id_care_plan_in => l_care_plan_hist.id_care_plan,
                                 dt_care_plan_in => g_sysdate_tstz,
                                 flg_status_in   => g_finished,
                                 str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_finished),
                                 rows_out        => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            ELSE
                g_error := 'UPDATE CARE_PLAN 2';
                ts_care_plan.upd(id_care_plan_in => l_care_plan_hist.id_care_plan,
                                 dt_care_plan_in => g_sysdate_tstz,
                                 flg_status_in   => g_inprogress,
                                 str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_inprogress),
                                 rows_out        => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
        ELSE
            OPEN c_care_plan_req_count(l_care_plan_hist.id_care_plan);
            FETCH c_care_plan_req_count
                INTO l_count;
            CLOSE c_care_plan_req_count;
        
            IF l_count = 0
            THEN
                g_error := 'UPDATE CARE_PLAN 3';
                ts_care_plan.upd(id_care_plan_in => l_care_plan_hist.id_care_plan,
                                 dt_care_plan_in => g_sysdate_tstz,
                                 flg_status_in   => g_finished,
                                 str_status_in   => pk_sysdomain.get_img(i_lang, 'CARE_PLAN.FLG_STATUS', g_finished),
                                 rows_out        => l_rowids);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CARE_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
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
                                              'SET_CARE_PLAN_TASK_REQ',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_req;

    FUNCTION set_care_plan_task_consults
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_prof_req            IN profissional,
        i_pat                 IN consult_req.id_patient%TYPE,
        i_instit_requests     IN consult_req.id_instit_requests%TYPE,
        i_instit_requested    IN consult_req.id_inst_requested%TYPE,
        i_consult_type        IN consult_req.consult_type%TYPE,
        i_clinical_service    IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str    IN VARCHAR2,
        i_flg_type_date       IN consult_req.flg_type_date%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested      IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_id_complaint        IN consult_req.id_complaint%TYPE,
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        o_consult_req         OUT consult_req.id_consult_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_CONSULT_REQ.SET_CONSULT_REQ';
        IF NOT pk_consult_req.set_consult_req(i_lang             => i_lang,
                                              i_episode          => i_episode,
                                              i_prof_req         => i_prof_req,
                                              i_pat              => i_pat,
                                              i_instit_requests  => i_instit_requests,
                                              i_instit_requested => i_instit_requested,
                                              i_consult_type     => i_consult_type,
                                              i_clinical_service => i_clinical_service,
                                              i_dt_scheduled_str => i_dt_scheduled_str,
                                              i_flg_type_date    => i_flg_type_date,
                                              i_notes            => i_notes,
                                              i_dep_clin_serv    => i_dep_clin_serv,
                                              i_prof_requested   => i_prof_requested,
                                              i_prof_cat_type    => i_prof_cat_type,
                                              i_id_complaint     => i_id_complaint,
                                              i_commit_data      => 'N',
                                              i_flg_type         => pk_consult_req.g_flg_type_speciality,
                                              o_consult_req      => o_consult_req,
                                              o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_consult_req IS NOT NULL
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof_req,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_consult_req,
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_CONSULTS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_consults;

    FUNCTION set_care_plan_task_followup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN VARCHAR2,
        i_dt_end_event        IN VARCHAR2,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN VARCHAR2,
        i_dt_rec_end          IN VARCHAR2,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        i_flg_origin_module   IN VARCHAR2,
        i_task_dependency     IN tde_task_dependency.id_task_dependency%TYPE,
        i_flg_start_depending IN VARCHAR2,
        i_episode_to_exec     IN consult_req.id_episode_to_exec%TYPE,
        i_transaction_id      IN VARCHAR2,
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        o_id_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_id_episode          OUT episode.id_episode%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EVENTS.CREATE_FOLLOW_UP_APPOINTMENT';
        IF NOT pk_events.create_follow_up_appointment(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_patient             => i_patient,
                                                      i_epis_type           => i_epis_type,
                                                      i_request_prof        => i_request_prof,
                                                      i_inst_req_to         => i_inst_req_to,
                                                      i_sch_event           => i_sch_event,
                                                      i_dep_clin_serv       => i_dep_clin_serv,
                                                      i_complaint           => i_complaint,
                                                      i_dt_begin_event      => i_dt_begin_event,
                                                      i_dt_end_event        => i_dt_end_event,
                                                      i_priority            => i_priority,
                                                      i_contact_type        => i_contact_type,
                                                      i_notes               => i_notes,
                                                      i_instructions        => i_instructions,
                                                      i_room                => i_room,
                                                      i_request_type        => i_request_type,
                                                      i_request_responsable => i_request_responsable,
                                                      i_request_reason      => i_request_reason,
                                                      i_prof_approval       => i_prof_approval,
                                                      i_language            => i_language,
                                                      i_recurrence          => i_recurrence,
                                                      i_status              => i_status,
                                                      i_frequency           => i_frequency,
                                                      i_dt_rec_begin        => i_dt_rec_begin,
                                                      i_dt_rec_end          => i_dt_rec_end,
                                                      i_nr_events           => i_nr_events,
                                                      i_week_day            => i_week_day,
                                                      i_week_nr             => i_week_nr,
                                                      i_month_day           => i_month_day,
                                                      i_month_nr            => i_month_nr,
                                                      i_flg_origin_module   => i_flg_origin_module,
                                                      i_task_dependency     => i_task_dependency,
                                                      i_flg_start_depending => i_flg_start_depending,
                                                      i_episode_to_exec     => i_episode_to_exec,
                                                      i_transaction_id      => i_transaction_id,
                                                      i_reason_for_visit    => i_reason_for_visit,
                                                      o_id_consult_req      => o_id_consult_req,
                                                      o_id_episode          => o_id_episode,
                                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_id_consult_req IS NOT NULL
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_id_consult_req,
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_FOLLOWUP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_followup;

    FUNCTION set_care_plan_task_opinion
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN opinion.id_episode%TYPE,
        i_prof_questions      IN profissional,
        i_prof_questioned     IN opinion.id_prof_questioned%TYPE,
        i_spec                IN opinion.id_speciality%TYPE,
        i_desc                IN opinion.desc_problem%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_commit_data         IN VARCHAR2,
        i_diag                IN table_number,
        i_patient             IN opinion.id_patient%TYPE,
        i_flg_type            IN opinion.flg_type%TYPE DEFAULT 'O',
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        o_opinion             OUT opinion.id_opinion%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_CONSULT_REQ.SET_CONSULT_REQ';
        IF NOT pk_opinion.create_opinion(i_lang             => i_lang,
                                         i_episode          => i_episode,
                                         i_prof_questions   => i_prof_questions,
                                         i_prof_questioned  => i_prof_questioned,
                                         i_speciality       => i_spec,
                                         i_clinical_service => NULL,
                                         i_desc             => i_desc,
                                         i_prof_cat_type    => i_prof_cat_type,
                                         i_commit_data      => i_commit_data,
                                         i_diag             => i_diag,
                                         i_patient          => i_patient,
                                         i_flg_type         => i_flg_type,
                                         o_opinion          => o_opinion,
                                         o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_opinion IS NOT NULL
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof_questions,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_opinion,
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_CONSULTS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_opinion;

    FUNCTION set_care_plan_task_analysis
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_harvest                 IN harvest.id_harvest%TYPE,
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar, --10
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar, -- 15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar, -- 20
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, -- 25
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar DEFAULT NULL,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar, -- 30
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, -- 35
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, -- 40
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'C',
        i_task_dependency         IN table_number, -- 45
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2, -- 50
        i_care_plan_task          IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type     IN care_plan_task.id_task_type%TYPE,
        i_order_num               IN care_plan_task_req.order_num%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2, --55
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_analysis_req_array      OUT NOCOPY table_number,
        o_analysis_req_det_array  OUT NOCOPY table_number,
        o_analysis_req_par_array  OUT NOCOPY table_number, --60
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.CREATE_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_patient                 => i_patient,
                                                         i_episode                 => i_episode,
                                                         i_analysis_req            => i_analysis_req,
                                                         i_analysis_req_det        => NULL,
                                                         i_analysis_req_det_parent => NULL,
                                                         i_harvest                 => i_harvest,
                                                         i_analysis                => i_analysis,
                                                         i_analysis_group          => i_analysis_group,
                                                         i_flg_type                => i_flg_type,
                                                         i_dt_req                  => NULL,
                                                         i_flg_time                => i_flg_time,
                                                         i_dt_begin                => i_dt_begin,
                                                         i_dt_begin_limit          => i_dt_begin_limit,
                                                         i_episode_destination     => i_episode_destination,
                                                         i_order_recurrence        => i_order_recurrence,
                                                         i_priority                => i_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_notes_prn               => i_notes_prn,
                                                         i_specimen                => i_specimen,
                                                         i_body_location           => i_body_location,
                                                         i_laterality              => i_laterality,
                                                         i_collection_room         => i_collection_room,
                                                         i_notes                   => i_notes,
                                                         i_notes_scheduler         => i_notes_scheduler,
                                                         i_notes_technician        => i_notes_technician,
                                                         i_notes_patient           => i_notes_patient,
                                                         i_diagnosis_notes         => i_diagnosis_notes,
                                                         i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                                i_prof   => i_prof,
                                                                                                                i_params => i_diagnosis),
                                                         i_exec_institution        => i_exec_institution,
                                                         i_clinical_purpose        => i_clinical_purpose,
                                                         i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                         i_flg_col_inst            => i_flg_col_inst,
                                                         i_flg_fasting             => i_flg_fasting,
                                                         i_lab_req                 => i_lab_req,
                                                         i_prof_cc                 => i_prof_cc,
                                                         i_prof_bcc                => i_prof_bcc,
                                                         i_codification            => i_codification,
                                                         i_health_plan             => i_health_plan,
                                                         i_exemption               => i_exemption,
                                                         i_prof_order              => i_prof_order,
                                                         i_dt_order                => i_dt_order,
                                                         i_order_type              => i_order_type,
                                                         i_clinical_question       => i_clinical_question,
                                                         i_response                => i_response,
                                                         i_clinical_question_notes => i_clinical_question_notes,
                                                         i_clinical_decision_rule  => i_clinical_decision_rule,
                                                         i_flg_origin_req          => 'C',
                                                         i_task_dependency         => i_task_dependency,
                                                         i_flg_task_depending      => i_flg_task_depending,
                                                         i_episode_followup_app    => i_episode_followup_app,
                                                         i_schedule_followup_app   => i_schedule_followup_app,
                                                         i_event_followup_app      => i_event_followup_app,
                                                         i_test                    => i_test,
                                                         o_flg_show                => o_flg_show,
                                                         o_msg_title               => o_msg_title,
                                                         o_msg_req                 => o_msg_req,
                                                         o_button                  => o_button,
                                                         o_analysis_req_array      => o_analysis_req_array,
                                                         o_analysis_req_det_array  => o_analysis_req_det_array,
                                                         o_analysis_req_par_array  => o_analysis_req_par_array,
                                                         o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_analysis_req_array.count IS NOT NULL
           AND o_analysis_req_array.count > 0
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_analysis_req_array(1),
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_ANALYSIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_analysis;

    FUNCTION set_care_plan_task_exams
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL,
        i_exam                    IN table_number,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'C',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2,
        i_care_plan_task          IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type     IN care_plan_task.id_task_type%TYPE,
        i_order_num               IN care_plan_task_req.order_num%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_exam_req_array          OUT NOCOPY table_number,
        o_exam_req_det_array      OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.CREATE_EXAM_ORDER';
        IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_patient                 => i_patient,
                                                 i_episode                 => i_episode,
                                                 i_exam_req                => i_exam_req,
                                                 i_exam_req_det            => NULL,
                                                 i_exam                    => i_exam,
                                                 i_flg_type                => i_flg_type,
                                                 i_dt_req                  => NULL,
                                                 i_flg_time                => i_flg_time,
                                                 i_dt_begin                => i_dt_begin,
                                                 i_dt_begin_limit          => i_dt_begin_limit,
                                                 i_episode_destination     => i_episode_destination,
                                                 i_order_recurrence        => i_order_recurrence,
                                                 i_priority                => i_priority,
                                                 i_flg_prn                 => i_flg_prn,
                                                 i_notes_prn               => i_notes_prn,
                                                 i_flg_fasting             => i_flg_fasting,
                                                 i_notes                   => i_notes,
                                                 i_notes_scheduler         => i_notes_scheduler,
                                                 i_notes_technician        => i_notes_technician,
                                                 i_notes_patient           => i_notes_patient,
                                                 i_diagnosis_notes         => i_diagnosis_notes,
                                                 i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                        i_prof   => i_prof,
                                                                                                        i_params => i_diagnosis),
                                                 i_laterality              => i_laterality,
                                                 i_exec_room               => i_exec_room,
                                                 i_exec_institution        => i_exec_institution,
                                                 i_clinical_purpose        => i_clinical_purpose,
                                                 i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                 i_codification            => i_codification,
                                                 i_health_plan             => i_health_plan,
                                                 i_exemption               => i_exemption,
                                                 i_prof_order              => i_prof_order,
                                                 i_dt_order                => i_dt_order,
                                                 i_order_type              => i_order_type,
                                                 i_clinical_question       => i_clinical_question,
                                                 i_response                => i_response,
                                                 i_clinical_question_notes => i_clinical_question_notes,
                                                 i_clinical_decision_rule  => i_clinical_decision_rule,
                                                 i_flg_origin_req          => 'C',
                                                 i_task_dependency         => i_task_dependency,
                                                 i_flg_task_depending      => i_flg_task_depending,
                                                 i_episode_followup_app    => i_episode_followup_app,
                                                 i_schedule_followup_app   => i_schedule_followup_app,
                                                 i_event_followup_app      => i_event_followup_app,
                                                 i_test                    => i_test,
                                                 o_flg_show                => o_flg_show,
                                                 o_msg_title               => o_msg_title,
                                                 o_msg_req                 => o_msg_req,
                                                 o_button                  => o_button,
                                                 o_exam_req_array          => o_exam_req_array,
                                                 o_exam_req_det_array      => o_exam_req_det_array,
                                                 o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_exam_req_array IS NOT NULL
           AND o_exam_req_array.count > 0
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_exam_req_array(1),
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_EXAMS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_exams;

    FUNCTION set_care_plan_task_procedures
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention            IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_clinical_purpose        IN table_number, --10
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --15
        i_exec_institution        IN table_number,
        i_flg_location            IN table_varchar,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number,
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number, --20
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_codification            IN table_number, --25
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar, --30
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN interv_presc_det.flg_req_origin_module%TYPE DEFAULT 'C',
        i_test                    IN VARCHAR2,
        i_care_plan_task          IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type     IN care_plan_task.id_task_type%TYPE, --35
        i_order_num               IN care_plan_task_req.order_num%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_ORDER';
        IF NOT pk_procedures_core.create_procedure_order(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_patient             => i_patient,
                                                         i_episode             => i_episode,
                                                         i_intervention        => i_intervention,
                                                         i_flg_time            => i_flg_time,
                                                         i_dt_begin            => i_dt_begin,
                                                         i_episode_destination => i_episode_destination,
                                                         i_order_recurrence    => i_order_recurrence,
                                                         i_diagnosis_notes     => i_diagnosis_notes,
                                                         i_diagnosis           => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                            i_prof   => i_prof,
                                                                                                            i_params => i_diagnosis),
                                                         
                                                         i_clinical_purpose        => i_clinical_purpose,
                                                         i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                         i_laterality              => i_laterality,
                                                         i_priority                => i_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_notes_prn               => i_notes_prn,
                                                         i_exec_institution        => i_exec_institution,
                                                         i_flg_location            => i_flg_location,
                                                         i_supply                  => i_supply,
                                                         i_supply_set              => i_supply_set,
                                                         i_supply_qty              => i_supply_qty,
                                                         i_dt_return               => i_dt_return,
                                                         i_supply_loc              => NULL,
                                                         i_not_order_reason        => i_not_order_reason,
                                                         i_notes                   => i_notes,
                                                         i_prof_order              => i_prof_order,
                                                         i_dt_order                => i_dt_order,
                                                         i_order_type              => i_order_type,
                                                         i_codification            => i_codification,
                                                         i_health_plan             => i_health_plan,
                                                         i_exemption               => i_exemption,
                                                         i_clinical_question       => i_clinical_question,
                                                         i_response                => i_response,
                                                         i_clinical_question_notes => i_clinical_question_notes,
                                                         i_clinical_decision_rule  => i_clinical_decision_rule,
                                                         i_flg_origin_req          => 'C',
                                                         i_test                    => i_test,
                                                         o_flg_show                => o_flg_show,
                                                         o_msg_title               => o_msg_title,
                                                         o_msg_req                 => o_msg_req,
                                                         o_interv_presc_array      => o_interv_presc_array,
                                                         o_interv_presc_det_array  => o_interv_presc_det_array,
                                                         o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_interv_presc_det_array IS NOT NULL
           AND o_interv_presc_det_array.count > 0
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_interv_presc_det_array(1),
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_PROCEDURES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_procedures;

    FUNCTION set_care_plan_task_education
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
        i_care_plan_task        IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type   IN care_plan_task.id_task_type%TYPE,
        i_order_num             IN care_plan_task_req.order_num%TYPE,
        o_id_nurse_tea_req      OUT table_number,
        o_id_nurse_tea_topic    OUT table_number,
        o_title_topic           OUT table_varchar,
        o_desc_diagnosis        OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_patient_education_api_db.CREATE_REQUEST';
        IF NOT pk_patient_education_api_db.create_request(i_lang                  => i_lang,
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
            RAISE g_other_exception;
        END IF;
    
        IF o_id_nurse_tea_req.count IS NOT NULL
           AND o_id_nurse_tea_req.count > 0
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_id_nurse_tea_req(1),
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_EDUCATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_education;

    FUNCTION set_care_plan_task_req_med
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task_req.id_care_plan_task%TYPE,
        i_flg_task_type  IN task_type.flg_type%TYPE,
        i_order_num      IN care_plan_task_req.order_num%TYPE,
        i_req            IN care_plan_task_req.id_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_task_type IS
            SELECT tt.id_task_type
              FROM task_type tt
             WHERE tt.flg_type = i_flg_task_type;
    
        l_task_type care_plan_task_req.id_task_type%TYPE;
    
    BEGIN
    
        g_error := 'OPEN C_TASK_TYPE';
        OPEN c_task_type;
        FETCH c_task_type
            INTO l_task_type;
        CLOSE c_task_type;
    
        g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
        IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_care_plan_task => i_care_plan_task,
                                                    i_task_type      => l_task_type,
                                                    i_order_num      => i_order_num,
                                                    i_req            => i_req,
                                                    o_error          => o_error)
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
                                              'SET_CARE_PLAN_TASK_REQ_MED',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_req_med;

    FUNCTION set_care_plan_task_medication
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN presc.id_patient%TYPE,
        i_id_episode           IN presc.id_epis_create%TYPE,
        i_id_presc             IN table_number,
        i_id_action            IN table_number,
        i_id_cdr_call          IN NUMBER DEFAULT NULL,
        i_context              IN VARCHAR2,
        i_id_cdr_overdose_call IN NUMBER,
        i_flg_new_presc        IN VARCHAR2,
        i_all_presc_dir_xml    IN table_varchar,
        i_set_presc_dir_xml    IN table_varchar,
        i_co_sign_xml          IN table_varchar,
        i_care_plan_task       IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type  IN care_plan_task.id_task_type%TYPE,
        i_order_num            IN care_plan_task_req.order_num%TYPE,
        o_id_presc             OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_RT_MED_PFH.CONFIRM_TEMP_PRESC';
        IF NOT pk_rt_med_pfh.confirm_temp_presc(i_lang                 => i_lang,
                                                i_prof                 => i_prof,
                                                i_id_patient           => i_id_patient,
                                                i_id_episode           => i_id_episode,
                                                i_id_presc             => i_id_presc,
                                                i_id_action            => i_id_action,
                                                i_id_cdr_call          => i_id_cdr_call,
                                                i_context              => i_context,
                                                i_id_cdr_overdose_call => i_id_cdr_overdose_call,
                                                i_all_presc_dir_xml    => i_all_presc_dir_xml,
                                                i_flg_new_presc        => i_flg_new_presc,
                                                i_set_presc_dir_xml    => i_set_presc_dir_xml,
                                                i_co_sign_xml          => i_co_sign_xml,
                                                i_pharm_review_xml     => NULL,
                                                i_pharm_dispense_xml   => NULL,
                                                o_id_presc             => o_id_presc,
                                                o_error                => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_id_presc IS NOT NULL
           AND o_id_presc.count > 0
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_id_presc(1),
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_CARE_PLAN_TASK_MEDICATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_medication;

    FUNCTION set_care_plan_task_diets
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_id_epis_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type        IN diet_type.id_diet_type%TYPE,
        i_desc_diet           IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_dt_end_str          IN VARCHAR2,
        i_food_plan           IN epis_diet_req.food_plan%TYPE,
        i_flg_help            IN epis_diet_req.flg_help%TYPE,
        i_notes               IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined  IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule    IN table_number,
        i_id_diet             IN table_number,
        i_quantity            IN table_number,
        i_id_unit             IN table_number,
        i_notes_diet          IN table_varchar,
        i_dt_hour             IN table_varchar,
        i_commit              IN VARCHAR2,
        i_flg_institution     IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share           IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        i_flg_force           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_diet        OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_warning         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_multiple_diet_cfg sys_config.value%TYPE := pk_sysconfig.get_config('DIET_MULTIPLE', i_prof);
    BEGIN
    
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                         i_prof.software,
                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_prof,
                                                                                       i_dt_begin_str,
                                                                                       NULL));
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                         i_prof.software,
                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_prof,
                                                                                       i_dt_end_str,
                                                                                       NULL));
    
        IF i_flg_force = pk_alert_constant.g_yes
           AND l_multiple_diet_cfg = pk_alert_constant.g_no
        THEN
        
            FOR reg IN (SELECT edr.id_epis_diet_req
                          FROM epis_diet_req edr
                         WHERE edr.flg_status IN (pk_diet.g_flg_diet_status_r)
                           AND ((l_start_date BETWEEN pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                       i_prof.software,
                                                                                       pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                                i_inst      => i_prof.institution,
                                                                                                                                i_timestamp => edr.dt_inicial),
                                                                                       NULL) AND
                               pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                           i_inst      => i_prof.institution,
                                                                                                           i_timestamp => edr.dt_end),
                                                                  NULL)) OR
                               (l_end_date BETWEEN pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                     i_prof.software,
                                                                                     pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                              i_inst      => i_prof.institution,
                                                                                                                              i_timestamp => edr.dt_inicial),
                                                                                     NULL) AND
                               pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                           i_inst      => i_prof.institution,
                                                                                                           i_timestamp => edr.dt_end),
                                                                  NULL)) OR
                               (l_start_date <= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND
                               l_end_date >= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                i_prof.software,
                                                                                pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                         i_inst      => i_prof.institution,
                                                                                                                         i_timestamp => edr.dt_end),
                                                                                NULL)) OR
                               (l_start_date <= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND i_dt_end_str IS NULL) OR
                               (l_start_date >= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND edr.dt_end IS NULL))
                              
                           AND id_episode = i_episode)
            LOOP
                IF NOT pk_diet.cancel_diet(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_id_diet => reg.id_epis_diet_req,
                                           i_notes   => NULL,
                                           i_reason  => NULL,
                                           o_error   => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END IF;
        g_error := 'CALL PK_DIET.CREATE_DIET';
        IF NOT pk_diet.create_diet(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_patient            => i_patient,
                                   i_episode            => i_episode,
                                   i_id_epis_diet       => i_id_epis_diet,
                                   i_id_diet_type       => i_id_diet_type,
                                   i_desc_diet          => i_desc_diet,
                                   i_dt_begin_str       => i_dt_begin_str,
                                   i_dt_end_str         => i_dt_end_str,
                                   i_food_plan          => i_food_plan,
                                   i_flg_help           => i_flg_help,
                                   i_notes              => i_notes,
                                   i_id_diet_predefined => i_id_diet_predefined,
                                   i_id_diet_schedule   => i_id_diet_schedule,
                                   i_id_diet            => i_id_diet,
                                   i_quantity           => i_quantity,
                                   i_id_unit            => i_id_unit,
                                   i_notes_diet         => i_notes_diet,
                                   i_dt_hour            => i_dt_hour,
                                   i_commit             => 'N',
                                   i_flg_institution    => i_flg_institution,
                                   i_flg_share          => i_flg_share,
                                   i_flg_force          => i_flg_force,
                                   o_id_epis_diet       => o_id_epis_diet,
                                   o_msg_warning        => o_msg_warning,
                                   o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF o_id_epis_diet IS NOT NULL
        THEN
            g_error := 'CALL PK_CARE_PLANS.SET_CARE_PLAN_TASK_REQ';
            IF NOT pk_care_plans.set_care_plan_task_req(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_care_plan_task => i_care_plan_task,
                                                        i_task_type      => i_care_plan_task_type,
                                                        i_order_num      => i_order_num,
                                                        i_req            => o_id_epis_diet,
                                                        o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
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
                                              'SET_CARE_PLAN_TASK_DIETS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_diets;

    FUNCTION set_care_plan_task_req_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task_req.id_care_plan_task%TYPE,
        i_order_num      IN care_plan_task_req.order_num%TYPE,
        i_status         IN care_plan_task_req.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_count IS
            SELECT *
              FROM (SELECT COUNT(cptr.id_care_plan_task) task_count,
                           decode(cpt.num_exec, NULL, 0, cpt.num_exec) num_exec
                      FROM care_plan_task cpt, care_plan_task_req cptr
                     WHERE cpt.id_care_plan_task = i_care_plan_task
                       AND cpt.id_care_plan_task = cptr.id_care_plan_task
                       AND (cptr.id_req IS NULL OR cptr.id_req = -1)
                     GROUP BY cptr.id_care_plan_task, cpt.num_exec)
             WHERE task_count != num_exec;
    
        CURSOR c_care_plan_task_req IS
            SELECT COUNT(1)
              FROM care_plan_task_req r
             WHERE r.id_care_plan_task = i_care_plan_task
               AND r.id_req IS NULL;
    
        l_count              c_count%ROWTYPE;
        l_care_plan_task_req NUMBER;
    
    BEGIN
    
        IF i_status = g_canceled
        THEN
            g_error := 'UPDATE CARE_PLAN_TASK_REQ 1';
            UPDATE care_plan_task_req
               SET id_req = -1, flg_status = i_status
             WHERE id_care_plan_task = i_care_plan_task
               AND order_num = i_order_num;
        
            g_error := 'GET CURSOR';
            OPEN c_count;
            FETCH c_count
                INTO l_count;
            g_found := c_count%NOTFOUND;
            CLOSE c_count;
        
            IF g_found
            THEN
                g_error := 'UPDATE CARE_PLAN_TASK 1';
                UPDATE care_plan_task
                   SET flg_status = i_status, id_prof_cancel = i_prof.id, dt_cancel = current_timestamp
                 WHERE id_care_plan_task = i_care_plan_task;
            ELSE
                g_error := 'GET CURSOR';
                OPEN c_care_plan_task_req;
                FETCH c_care_plan_task_req
                    INTO l_care_plan_task_req;
                CLOSE c_care_plan_task_req;
            
                IF l_care_plan_task_req = 0
                THEN
                    g_error := 'UPDATE CARE_PLAN_TASK 2';
                    UPDATE care_plan_task
                       SET flg_status = g_finished
                     WHERE id_care_plan_task = i_care_plan_task;
                END IF;
            END IF;
        ELSE
            g_error := 'UPDATE CARE_PLAN_TASK_REQ 2';
            UPDATE care_plan_task_req
               SET flg_status = i_status
             WHERE id_care_plan_task = i_care_plan_task
               AND order_num = i_order_num;
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
                                              'SET_CARE_PLAN_TASK_REQ_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_care_plan_task_req_status;

    FUNCTION get_care_plan_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_notes        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M008');
        l_msg_notes_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M028');
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LIST';
        OPEN o_list FOR
            SELECT cp.id_care_plan,
                   decode(cp.flg_status,
                          g_pending,
                          g_active,
                          g_inprogress,
                          g_active,
                          g_suspended,
                          g_active,
                          g_interrupted,
                          g_inactive,
                          g_finished,
                          g_inactive,
                          g_canceled,
                          g_inactive) flg_status,
                   cp.name,
                   cp.subject_type,
                   cp.id_subject,
                   decode(cp.subject_type,
                          g_relevant_disease,
                          (SELECT decode(phd.id_alert_diagnosis,
                                         NULL,
                                         phd.desc_pat_history_diagnosis,
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                phd.desc_pat_history_diagnosis || ' - ') ||
                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => pk_alert_constant.g_yes)) desc_subject
                             FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                            WHERE phd.id_pat_history_diagnosis = cp.id_subject
                              AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                              AND ad.id_diagnosis = d.id_diagnosis),
                          g_diagnosis,
                          (SELECT decode(pp.desc_pat_problem,
                                         '',
                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                    i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                                  d1.id_diagnosis,
                                                                                                  d.id_diagnosis),
                                                                    i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                                  ed.desc_epis_diagnosis,
                                                                                                  NULL),
                                                                    i_code                => d.code_icd,
                                                                    i_flg_other           => d.flg_other,
                                                                    i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                    i_epis_diag           => ed.id_epis_diagnosis),
                                         pp.desc_pat_problem) desc_subject
                             FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
                            WHERE pp.id_pat_problem = cp.id_subject
                              AND pp.id_diagnosis = d.id_diagnosis(+)
                              AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                              AND d1.id_diagnosis(+) = ed.id_diagnosis
                              AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                              AND ed.id_epis_diagnosis = pp.id_epis_diagnosis),
                          g_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy) desc_subject
                             FROM pat_allergy pa, allergy a
                            WHERE pa.id_pat_allergy = cp.id_subject
                              AND a.id_allergy = pa.id_allergy)) subject,
                   decode(cp.flg_status, g_canceled, l_msg_notes_cancel || ' ') ||
                   decode(cp.notes,
                          NULL,
                          decode(cp.notes_cancel, NULL, '', '(' || l_msg_notes || ')'),
                          '(' || l_msg_notes || ')') notes,
                   decode(pk_profphoto.check_blob(cp.id_prof_coordinator),
                          'N',
                          '',
                          pk_profphoto.get_prof_photo(profissional(cp.id_prof_coordinator, NULL, NULL))) prof_photo,
                   pk_prof_utils.get_nickname(i_lang, cp.id_prof_coordinator) prof_coordinator,
                   pk_date_utils.dt_chr_tsz(i_lang, cp.dt_begin, i_prof) dt_begin,
                   decode(cp.dt_end, NULL, '---', pk_date_utils.dt_chr_tsz(i_lang, cp.dt_end, i_prof)) dt_end,
                   cp.str_status status_icon,
                   cp.flg_status status,
                   pk_sysdomain.get_rank(i_lang, 'CARE_PLAN.FLG_STATUS', cp.flg_status) rank,
                   decode(cp.flg_status, g_pending, 'Y', g_inprogress, 'Y', g_suspended, 'Y', 'N') avail_butt_action,
                   decode(cp.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   cp.id_episode
              FROM care_plan cp
             WHERE cp.id_patient = i_patient
             ORDER BY rank, name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_VIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_view;

    FUNCTION get_care_plan_task_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_notes        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M008');
        l_msg_notes_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M028');
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LIST';
        OPEN o_list FOR
            SELECT cpt.id_care_plan_task,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_item,
                   cpt.id_task_type,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   decode(cpt.flg_status, g_canceled, l_msg_notes_cancel || ' ') ||
                   decode(cpt.notes,
                          NULL,
                          decode(cpt.notes_cancel, NULL, '', '(' || l_msg_notes || ')'),
                          '(' || l_msg_notes || ')') notes,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpt.num_exec,
                                                         cpt.interval,
                                                         cpt.id_unit_measure) task_instructions,
                   cpt.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 nvl(cptr.flg_status, cpt.flg_status),
                                                 NULL,
                                                 pk_date_utils.date_send_tsz(i_lang, cpt.dt_begin, i_prof),
                                                 nvl(cptr.id_req, cpt.id_care_plan_task),
                                                 'CARE_PLAN_TASK') status,
                   pk_sysdomain.get_rank(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', cpt.flg_status) rank,
                   decode(cpt.flg_status, g_inprogress, 'N', 'Y') flg_edit,
                   decode(cpt.flg_status, g_pending, 'Y', g_inprogress, 'Y', g_suspended, 'Y', 'N') avail_butt_action,
                   decode(cpt.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   CASE pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type)
                       WHEN g_imaging_exams THEN
                        pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'EI', cpt.id_item)
                       WHEN g_other_exams THEN
                        pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'EO', cpt.id_item)
                       WHEN g_procedures THEN
                        pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', cpt.id_item)
                       ELSE
                        NULL
                   END flg_laterality_mcdt
              FROM care_plan cp,
                   care_plan_task_link cptl,
                   care_plan_task cpt,
                   (SELECT *
                      FROM care_plan_task_req r
                     WHERE r.order_num =
                           (SELECT MIN(order_num)
                              FROM care_plan_task_req req
                             WHERE req.id_care_plan_task = r.id_care_plan_task
                               AND req.flg_status NOT IN (g_ordered, g_canceled, g_interrupted, g_suspended, g_finished))) cptr
             WHERE cp.id_patient = i_patient
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
             ORDER BY name, TYPE, desc_task, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TASK_VIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_task_view;

    FUNCTION get_care_plan_timeline_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        OPEN o_list FOR
        -- Appointments
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(cr.dt_consult_req_tstz, cr.dt_scheduled_tstz)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(cr.dt_consult_req_tstz, cr.dt_scheduled_tstz)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   consult_req         cr,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = cr.id_consult_req(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type IN (g_appointments, g_spec_appointments, g_followup_appointments)
            UNION ALL
            -- Consults
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(o.dt_approved, o.dt_problem_tstz)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(o.dt_approved, o.dt_problem_tstz)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   opinion             o,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = o.id_opinion(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type = g_opinions
            UNION ALL
            -- Lab tests
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(lte.dt_harvest, lte.dt_req)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(lte.dt_harvest, lte.dt_req)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   lab_tests_ea        lte,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = lte.id_analysis_req(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type = g_analysis
            UNION ALL
            -- Lab tests group
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 ar.dt_req_tstz),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 ar.dt_req_tstz),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   analysis_req        ar,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = ar.id_analysis_req(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type = g_group_analysis
            UNION ALL
            -- Exams
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(eea.start_time, nvl(eea.dt_result, eea.dt_req))),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(eea.start_time, nvl(eea.dt_result, eea.dt_req))),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   erd.flg_laterality flg_laterality,
                   pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LATERALITY', erd.flg_laterality, i_lang) desc_laterality,
                   pk_mcdt.check_mcdt_laterality(i_lang, i_prof, tt.flg_type, cpt.id_item) flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   exams_ea            eea,
                   task_type           tt,
                   exam_req_det        erd
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = eea.id_exam_req(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type IN (g_imaging_exams, g_other_exams)
               AND eea.id_exam_req_det = erd.id_exam_req_det(+)
            UNION ALL
            -- Patient education
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 ntr.dt_nurse_tea_req_tstz),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 ntr.dt_nurse_tea_req_tstz),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   nurse_tea_req       ntr,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = ntr.id_nurse_tea_req(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type = g_patient_education
            UNION ALL
            -- Procedures
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(pea.dt_interv_presc_det, pea.dt_interv_prescription)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(pea.dt_interv_presc_det, pea.dt_interv_prescription)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   pea.flg_laterality flg_laterality,
                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', pea.flg_laterality, i_lang) desc_laterality,
                   pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', cpt.id_item) flg_laterality_mcdt,
                   pea.id_clinical_purpose,
                   CASE pea.id_clinical_purpose
                       WHEN 0 THEN
                        pea.clinical_purpose_notes
                       ELSE
                        pk_translation.get_translation(i_lang,
                                                       'MULTICHOICE_OPTION.CODE_MULTICHOICE_OPTION.' ||
                                                       pea.id_clinical_purpose)
                   END desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   procedures_ea       pea,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = pea.id_interv_presc_det(+)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type = g_procedures
            UNION ALL
            -- Outside medication, Local medication, IV Fluids
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 pk_api_pfh_in.get_presc_change_date(i_lang,
                                                                                                     i_prof,
                                                                                                     cptr.id_req)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 pk_api_pfh_in.get_presc_change_date(i_lang,
                                                                                                     i_prof,
                                                                                                     cptr.id_req)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task cpt, care_plan_task_req cptr, task_type tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_task_type = tt.id_task_type
               AND tt.flg_type IN (g_medication, g_ext_medication, g_int_medication, g_ivfluids_medication)
            UNION ALL
            -- Hospital pharmacy medication
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(vedr.dt_print_tstz, vedr.dt_drug_req_tstz)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(vedr.dt_print_tstz, vedr.dt_drug_req_tstz)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   v_epis_drug_req     vedr,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = vedr.id_drug_req_det(+)
               AND cptr.id_task_type = tt.id_task_type
               AND tt.flg_type = g_pharm_medication
            UNION ALL
            -- Diets
            SELECT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                   cp.id_care_plan,
                   cp.name,
                   cpt.id_care_plan_task,
                   cptr.order_num,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                   cpt.id_item,
                   pk_task_type.get_task_type_flg(i_lang, cpt.id_task_type) flg_type,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6), ' ', '-') today,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(edr.dt_inicial, edr.dt_creation)),
                                      1,
                                      ';') dt_begin,
                   extract(YEAR FROM nvl(cptr.dt_next_task, nvl(cpt.dt_begin, g_sysdate_tstz))) YEAR,
                   cptr.flg_status,
                   pk_care_plans.get_string_task(i_lang,
                                                 i_prof,
                                                 pk_task_type.get_task_type_flg(i_lang,
                                                                                nvl(cptr.id_task_type, cpt.id_task_type)),
                                                 cpt.flg_status,
                                                 cptr.flg_status,
                                                 coalesce(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cptr.dt_next_task,
                                                                                             'YYYYMMDDHH24MISS'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             cpt.dt_begin,
                                                                                             'YYYYMMDDHH24MISS')),
                                                 cptr.id_req,
                                                 'CARE_PLAN_TASK_REQ') status,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_action,
                   decode(cptr.flg_status, g_pending, 'Y', 'N') avail_butt_cancel,
                   pk_utils.str_token(pk_care_plans.get_dt_begin(i_lang,
                                                                 i_prof,
                                                                 cpt.flg_status,
                                                                 cptr.flg_status,
                                                                 nvl(cptr.dt_next_task, cpt.dt_begin),
                                                                 nvl(edr.dt_inicial, edr.dt_creation)),
                                      2,
                                      ';') dt_ord,
                   g_sysdate_char dt_server,
                   NULL flg_laterality,
                   NULL desc_laterality,
                   NULL flg_laterality_mcdt,
                   NULL id_clinical_purpose,
                   NULL desc_clinical_purpose
              FROM care_plan           cp,
                   care_plan_task_link cptl,
                   care_plan_task      cpt,
                   care_plan_task_req  cptr,
                   epis_diet_req       edr,
                   task_type           tt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = cptr.id_care_plan_task(+)
               AND cptr.id_req = edr.id_epis_diet_req(+)
               AND cptr.id_task_type = tt.id_task_type
               AND tt.flg_type = g_diets
             ORDER BY dt_ord, TYPE, desc_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TIMELINE_VIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_timeline_view;

    FUNCTION get_care_plan_timeline_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                            cp.id_care_plan,
                            cp.name,
                            pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                            cpt.id_task_type,
                            pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                            cp.flg_status plan_flg_status,
                            NULL task_flg_status,
                            'N' task_avail_butt_action,
                            'N' task_avail_butt_cancel
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task cpt
             WHERE cp.id_patient = i_patient
               AND cp.flg_status != g_canceled
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
             ORDER BY cp.name, cp.id_care_plan, TYPE, desc_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TIMELINE_TASKS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_timeline_tasks;

    FUNCTION get_care_plan_timeline_update
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task.id_care_plan_task%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT cp.id_care_plan || '_' || cpt.id_item || '_' || cpt.id_task_type unique_id,
                            cp.id_care_plan,
                            cp.name,
                            pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) desc_task,
                            cpt.id_task_type,
                            pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                            NULL task_flg_status,
                            'N' task_avail_butt_action,
                            'N' task_avail_butt_cancel
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task cpt
             WHERE cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task = i_care_plan_task
             ORDER BY cp.name, TYPE, desc_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TIMELINE_UPDATE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_timeline_update;

    FUNCTION get_care_plan_to_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan      IN care_plan.id_care_plan%TYPE,
        o_care_plan      OUT pk_types.cursor_type,
        o_care_plan_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN';
        OPEN o_care_plan FOR
            SELECT cp.id_care_plan,
                   cp.name,
                   cp.id_care_plan_type,
                   pk_translation.get_translation(i_lang, 'CARE_PLAN_TYPE.CODE_CARE_PLAN_TYPE.' || cp.id_care_plan_type) plan_type,
                   pk_date_utils.date_send_tsz(i_lang, cp.dt_begin, i_prof) dt_begin_str,
                   pk_date_utils.date_char_tsz(i_lang, cp.dt_begin, i_prof.institution, i_prof.software) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, cp.dt_end, i_prof) dt_end_str,
                   pk_date_utils.date_char_tsz(i_lang, cp.dt_end, i_prof.institution, i_prof.software) dt_end,
                   cp.subject_type,
                   cp.id_subject,
                   decode(cp.subject_type,
                          g_relevant_disease,
                          (SELECT decode(phd.id_alert_diagnosis,
                                         NULL,
                                         phd.desc_pat_history_diagnosis,
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                phd.desc_pat_history_diagnosis || ' - ') ||
                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => pk_alert_constant.g_yes)) desc_subject
                             FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                            WHERE phd.id_pat_history_diagnosis = cp.id_subject
                              AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                              AND ad.id_diagnosis = d.id_diagnosis),
                          g_diagnosis,
                          (SELECT decode(pp.desc_pat_problem,
                                         '',
                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                    i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                                  d1.id_diagnosis,
                                                                                                  d.id_diagnosis),
                                                                    i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                                  ed.desc_epis_diagnosis,
                                                                                                  NULL),
                                                                    i_code                => d.code_icd,
                                                                    i_flg_other           => d.flg_other,
                                                                    i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                    i_epis_diag           => ed.id_epis_diagnosis),
                                         pp.desc_pat_problem) desc_subject
                             FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
                            WHERE pp.id_pat_problem = cp.id_subject
                              AND pp.id_diagnosis = d.id_diagnosis(+)
                              AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                              AND d1.id_diagnosis(+) = ed.id_diagnosis
                              AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                              AND ed.id_epis_diagnosis = pp.id_epis_diagnosis),
                          g_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy) desc_subject
                             FROM pat_allergy pa, allergy a
                            WHERE pa.id_pat_allergy = cp.id_subject
                              AND a.id_allergy = pa.id_allergy)) subject,
                   cp.id_prof_coordinator,
                   pk_prof_utils.get_nickname(i_lang, cp.id_prof_coordinator) prof_coordinator,
                   cp.goals,
                   cp.notes,
                   cp.flg_status
              FROM care_plan cp
             WHERE cp.id_care_plan = i_care_plan;
    
        g_error := 'OPEN O_CARE_PLAN_TASK';
        OPEN o_care_plan_task FOR
            SELECT cpt.id_care_plan_task,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) task_name,
                   pk_date_utils.date_send_tsz(i_lang, cpt.dt_begin, i_prof) dt_begin_str,
                   pk_date_utils.date_send_tsz(i_lang, cpt.dt_end, i_prof) dt_end_str,
                   cpt.num_exec,
                   cpt.interval,
                   cpt.id_unit_measure,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpt.num_exec,
                                                         cpt.interval,
                                                         cpt.id_unit_measure) task_instructions,
                   cpt.notes,
                   cpt.flg_status
              FROM care_plan_task_link cptl, care_plan_task cpt
             WHERE cptl.id_care_plan = i_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_care_plan);
            pk_types.open_my_cursor(o_care_plan_task);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_to_edit;

    FUNCTION get_care_plan_task_to_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        o_care_plan_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN_TASK';
        OPEN o_care_plan_task FOR
            SELECT cpt.id_care_plan_task,
                   pk_task_type.get_task_type_icon(i_lang, cpt.id_task_type) TYPE,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) task_name,
                   pk_date_utils.date_send_tsz(i_lang, cpt.dt_begin, i_prof) dt_begin_str,
                   pk_date_utils.date_send_tsz(i_lang, cpt.dt_end, i_prof) dt_end_str,
                   cpt.num_exec,
                   cpt.interval,
                   cpt.id_unit_measure,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpt.num_exec,
                                                         cpt.interval,
                                                         cpt.id_unit_measure) task_instructions,
                   cpt.notes,
                   cpt.flg_status
              FROM care_plan_task cpt
             WHERE cpt.id_care_plan_task IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(i_care_plan_task) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TASK_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_care_plan_task);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_task_to_edit;

    FUNCTION get_care_plan_to_associate
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN';
        OPEN o_list FOR
            SELECT cp.id_care_plan,
                   cp.name,
                   decode(cp.subject_type,
                          g_relevant_disease,
                          (SELECT decode(phd.id_alert_diagnosis,
                                         NULL,
                                         phd.desc_pat_history_diagnosis,
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                phd.desc_pat_history_diagnosis || ' - ') ||
                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => pk_alert_constant.g_yes)) desc_subject
                             FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                            WHERE phd.id_pat_history_diagnosis = cp.id_subject
                              AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                              AND ad.id_diagnosis = d.id_diagnosis),
                          g_diagnosis,
                          (SELECT decode(pp.desc_pat_problem,
                                         '',
                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                    i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                                  d1.id_diagnosis,
                                                                                                  d.id_diagnosis),
                                                                    i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                                  ed.desc_epis_diagnosis,
                                                                                                  NULL),
                                                                    i_code                => d.code_icd,
                                                                    i_flg_other           => d.flg_other,
                                                                    i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                    i_epis_diag           => ed.id_epis_diagnosis),
                                         pp.desc_pat_problem) desc_subject
                             FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
                            WHERE pp.id_pat_problem = cp.id_subject
                              AND pp.id_diagnosis = d.id_diagnosis(+)
                              AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                              AND d1.id_diagnosis(+) = ed.id_diagnosis
                              AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                              AND ed.id_epis_diagnosis = pp.id_epis_diagnosis),
                          g_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy) desc_subject
                             FROM pat_allergy pa, allergy a
                            WHERE pa.id_pat_allergy = cp.id_subject
                              AND a.id_allergy = pa.id_allergy)) subject,
                   decode(pk_profphoto.check_blob(cp.id_prof_coordinator),
                          'N',
                          '',
                          pk_profphoto.get_prof_photo(profissional(cp.id_prof_coordinator, NULL, NULL))) prof_photo,
                   pk_prof_utils.get_nickname(i_lang, cp.id_prof_coordinator) prof_coordinator,
                   pk_date_utils.dt_chr_tsz(i_lang, cp.dt_begin, i_prof) dt_begin,
                   decode(cp.dt_end, NULL, '---', pk_date_utils.dt_chr_tsz(i_lang, cp.dt_end, i_prof)) dt_end,
                   cp.str_status status_icon
              FROM care_plan cp
             WHERE cp.id_patient = i_patient
               AND cp.flg_status NOT IN (g_finished, g_interrupted, g_canceled)
             ORDER BY flg_status, name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TO_ASSOCIATE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_to_associate;

    FUNCTION get_care_plan_to_dissociate
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN';
        OPEN o_list FOR
            SELECT cp.id_care_plan,
                   cp.name,
                   decode(cp.subject_type,
                          g_relevant_disease,
                          (SELECT decode(phd.id_alert_diagnosis,
                                         NULL,
                                         phd.desc_pat_history_diagnosis,
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                phd.desc_pat_history_diagnosis || ' - ') ||
                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => pk_alert_constant.g_yes)) desc_subject
                             FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                            WHERE phd.id_pat_history_diagnosis = cp.id_subject
                              AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                              AND ad.id_diagnosis = d.id_diagnosis),
                          g_diagnosis,
                          (SELECT decode(pp.desc_pat_problem,
                                         '',
                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                    i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                                  d1.id_diagnosis,
                                                                                                  d.id_diagnosis),
                                                                    i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                                  ed.desc_epis_diagnosis,
                                                                                                  NULL),
                                                                    i_code                => d.code_icd,
                                                                    i_flg_other           => d.flg_other,
                                                                    i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                    i_epis_diag           => ed.id_epis_diagnosis),
                                         pp.desc_pat_problem) desc_subject
                             FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
                            WHERE pp.id_pat_problem = cp.id_subject
                              AND pp.id_diagnosis = d.id_diagnosis(+)
                              AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                              AND d1.id_diagnosis(+) = ed.id_diagnosis
                              AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                              AND ed.id_epis_diagnosis = pp.id_epis_diagnosis),
                          g_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy) desc_subject
                             FROM pat_allergy pa, allergy a
                            WHERE pa.id_pat_allergy = cp.id_subject
                              AND a.id_allergy = pa.id_allergy)) subject,
                   decode(pk_profphoto.check_blob(cp.id_prof_coordinator),
                          'N',
                          '',
                          pk_profphoto.get_prof_photo(profissional(cp.id_prof_coordinator, NULL, NULL))) prof_photo,
                   pk_prof_utils.get_nickname(i_lang, cp.id_prof_coordinator) prof_coordinator,
                   pk_date_utils.dt_chr_tsz(i_lang, cp.dt_begin, i_prof) dt_begin,
                   decode(cp.dt_end, NULL, '---', pk_date_utils.dt_chr_tsz(i_lang, cp.dt_end, i_prof)) dt_end,
                   cp.str_status status_icon
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task cpt
             WHERE cp.flg_status NOT IN (g_finished, g_interrupted, g_canceled)
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
               AND cpt.id_care_plan_task IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(i_care_plan_task) t)
             ORDER BY cp.flg_status, name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TO_DISSOCIATE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_to_dissociate;

    FUNCTION get_care_plan_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_care_plan       IN care_plan.id_care_plan%TYPE,
        o_care_plan       OUT pk_types.cursor_type,
        o_task_type_count OUT pk_types.cursor_type,
        o_care_plan_task  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_pending     VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T061');
        l_msg_inprogress  VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T062');
        l_msg_suspended   VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T063');
        l_msg_finished    VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T064');
        l_msg_interrupted VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T065');
        l_msg_canceled    VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T066');
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN';
        OPEN o_care_plan FOR
            SELECT cp.id_care_plan,
                   decode(cp.flg_status,
                          g_pending,
                          l_msg_pending,
                          g_inprogress,
                          l_msg_inprogress,
                          g_suspended,
                          l_msg_suspended,
                          g_finished,
                          l_msg_finished,
                          g_interrupted,
                          l_msg_interrupted,
                          g_canceled,
                          l_msg_canceled) msg,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    decode(cp.flg_status,
                                                           g_canceled,
                                                           cp.id_prof_cancel,
                                                           g_interrupted,
                                                           cp.id_prof_cancel,
                                                           cp.id_prof)) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(cp.flg_status,
                                                           g_canceled,
                                                           cp.id_prof_cancel,
                                                           g_interrupted,
                                                           cp.id_prof_cancel,
                                                           cp.id_prof),
                                                    decode(cp.flg_status,
                                                           g_canceled,
                                                           cp.dt_cancel,
                                                           g_interrupted,
                                                           cp.dt_cancel,
                                                           cp.dt_care_plan),
                                                    cp.id_episode) prof_req_spec,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(cp.flg_status,
                                                      g_canceled,
                                                      cp.dt_cancel,
                                                      g_interrupted,
                                                      cp.dt_cancel,
                                                      cp.dt_care_plan),
                                               i_prof.institution,
                                               i_prof.software) dt_care_plan,
                   cp.name,
                   pk_translation.get_translation(i_lang, 'CARE_PLAN_TYPE.CODE_CARE_PLAN_TYPE.' || cp.id_care_plan_type) plan_type,
                   pk_date_utils.date_char_tsz(i_lang, cp.dt_begin, i_prof.institution, i_prof.software) dt_begin,
                   decode(cp.dt_end,
                          NULL,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, cp.dt_end, i_prof.institution, i_prof.software)) dt_end,
                   decode(cp.subject_type,
                          g_relevant_disease,
                          (SELECT decode(phd.id_alert_diagnosis,
                                         NULL,
                                         phd.desc_pat_history_diagnosis,
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                phd.desc_pat_history_diagnosis || ' - ') ||
                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => pk_alert_constant.g_yes)) desc_subject
                             FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                            WHERE phd.id_pat_history_diagnosis = cp.id_subject
                              AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                              AND ad.id_diagnosis = d.id_diagnosis),
                          g_diagnosis,
                          (SELECT decode(pp.desc_pat_problem,
                                         '',
                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                    i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                                  d1.id_diagnosis,
                                                                                                  d.id_diagnosis),
                                                                    i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                                  ed.desc_epis_diagnosis,
                                                                                                  NULL),
                                                                    i_code                => d.code_icd,
                                                                    i_flg_other           => d.flg_other,
                                                                    i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                    i_epis_diag           => ed.id_epis_diagnosis),
                                         pp.desc_pat_problem) desc_subject
                             FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
                            WHERE pp.id_pat_problem = cp.id_subject
                              AND pp.id_diagnosis = d.id_diagnosis(+)
                              AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                              AND d1.id_diagnosis(+) = ed.id_diagnosis
                              AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                              AND ed.id_epis_diagnosis = pp.id_epis_diagnosis),
                          g_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy) desc_subject
                             FROM pat_allergy pa, allergy a
                            WHERE pa.id_pat_allergy = cp.id_subject
                              AND a.id_allergy = pa.id_allergy)) subject,
                   pk_prof_utils.get_nickname(i_lang, cp.id_prof_coordinator) prof_coordinator,
                   cp.goals,
                   cp.notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cp.id_cancel_reason) cancel_reason,
                   cp.notes_cancel,
                   cp.flg_status,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(cp.flg_status,
                                                      g_canceled,
                                                      cp.dt_cancel,
                                                      g_interrupted,
                                                      cp.dt_cancel,
                                                      cp.dt_care_plan),
                                               i_prof) dt_ord
              FROM care_plan cp
             WHERE cp.id_care_plan = i_care_plan
            UNION
            SELECT cph.id_care_plan,
                   decode(cph.flg_status,
                          g_pending,
                          l_msg_pending,
                          g_inprogress,
                          l_msg_inprogress,
                          g_suspended,
                          l_msg_suspended) msg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cph.id_prof) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, cph.id_prof, cph.dt_care_plan, cph.id_episode) prof_req_spec,
                   pk_date_utils.date_char_tsz(i_lang, cph.dt_care_plan, i_prof.institution, i_prof.software) dt_care_plan,
                   cph.name,
                   pk_translation.get_translation(i_lang,
                                                  'CARE_PLAN_TYPE.CODE_CARE_PLAN_TYPE.' || cph.id_care_plan_type) plan_type,
                   pk_date_utils.date_char_tsz(i_lang, cph.dt_begin, i_prof.institution, i_prof.software) dt_begin,
                   decode(cph.dt_end,
                          NULL,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, cph.dt_end, i_prof.institution, i_prof.software)) dt_end,
                   decode(cph.subject_type,
                          g_relevant_disease,
                          (SELECT decode(phd.id_alert_diagnosis,
                                         NULL,
                                         phd.desc_pat_history_diagnosis,
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                phd.desc_pat_history_diagnosis || ' - ') ||
                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => pk_alert_constant.g_yes)) desc_subject
                             FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                            WHERE phd.id_pat_history_diagnosis = cph.id_subject
                              AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                              AND ad.id_diagnosis = d.id_diagnosis),
                          g_diagnosis,
                          (SELECT decode(pp.desc_pat_problem,
                                         '',
                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                    i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                                  d1.id_diagnosis,
                                                                                                  d.id_diagnosis),
                                                                    i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                                  ed.desc_epis_diagnosis,
                                                                                                  NULL),
                                                                    i_code                => d.code_icd,
                                                                    i_flg_other           => d.flg_other,
                                                                    i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                    i_epis_diag           => ed.id_epis_diagnosis),
                                         pp.desc_pat_problem) desc_subject
                             FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
                            WHERE pp.id_pat_problem = cph.id_subject
                              AND pp.id_diagnosis = d.id_diagnosis(+)
                              AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                              AND d1.id_diagnosis(+) = ed.id_diagnosis
                              AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                              AND ed.id_epis_diagnosis = pp.id_epis_diagnosis),
                          g_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy) desc_subject
                             FROM pat_allergy pa, allergy a
                            WHERE pa.id_pat_allergy = cph.id_subject
                              AND a.id_allergy = pa.id_allergy)) subject,
                   pk_prof_utils.get_nickname(i_lang, cph.id_prof_coordinator) prof_coordinator,
                   cph.goals,
                   cph.notes,
                   NULL cancel_reason,
                   NULL notes_cancel,
                   cph.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, cph.dt_care_plan, i_prof) dt_ord
              FROM care_plan_hist cph
             WHERE cph.id_care_plan = i_care_plan
             ORDER BY dt_ord DESC;
    
        g_error := 'OPEN O_TASK_TYPE_COUNT';
        OPEN o_task_type_count FOR
            SELECT id_task_type, task_type, SUM(task_count) task_count
              FROM (SELECT decode(cptc.id_task_type,
                                  g_id_group_analysis,
                                  g_id_analysis,
                                  g_id_imaging_exams,
                                  g_id_exams,
                                  g_id_other_exams,
                                  g_id_exams,
                                  g_id_ext_medication,
                                  g_id_medication,
                                  g_id_int_medication,
                                  g_id_medication,
                                  g_id_pharm_medication,
                                  g_id_medication,
                                  cptc.id_task_type) id_task_type,
                           sd.desc_val task_type,
                           cptc.task_count
                      FROM care_plan cp, care_plan_task_count cptc, sys_domain sd
                     WHERE cp.id_care_plan = i_care_plan
                       AND cp.id_care_plan = cptc.id_care_plan
                       AND sd.val = decode(pk_task_type.get_task_type_flg(i_lang, cptc.id_task_type),
                                           g_group_analysis,
                                           g_analysis,
                                           g_imaging_exams,
                                           g_exams,
                                           g_other_exams,
                                           g_exams,
                                           g_ext_medication,
                                           g_medication,
                                           g_int_medication,
                                           g_medication,
                                           pk_task_type.get_task_type_flg(i_lang, cptc.id_task_type))
                       AND sd.code_domain = 'TASK_TYPE.FLG_TYPE'
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang)
             GROUP BY id_task_type, task_type
             ORDER BY task_type;
    
        g_error := 'OPEN O_CARE_PLAN_TASK';
        OPEN o_care_plan_task FOR
            SELECT decode(cpt.id_task_type,
                          g_id_group_analysis,
                          g_id_analysis,
                          g_id_imaging_exams,
                          g_id_exams,
                          g_id_other_exams,
                          g_id_exams,
                          g_id_ext_medication,
                          g_id_medication,
                          g_id_int_medication,
                          g_id_medication,
                          g_id_pharm_medication,
                          g_id_medication,
                          cpt.id_task_type) id_task_type,
                   cpt.id_care_plan_task,
                   decode(cpt.flg_status,
                          g_pending,
                          l_msg_pending,
                          g_inprogress,
                          l_msg_inprogress,
                          g_suspended,
                          l_msg_suspended,
                          g_finished,
                          l_msg_finished,
                          g_interrupted,
                          l_msg_interrupted,
                          g_canceled,
                          l_msg_canceled) msg,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    decode(cpt.flg_status,
                                                           g_canceled,
                                                           cpt.id_prof_cancel,
                                                           g_interrupted,
                                                           cpt.id_prof_cancel,
                                                           cpt.id_prof)) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(cpt.flg_status,
                                                           g_canceled,
                                                           cpt.id_prof_cancel,
                                                           g_interrupted,
                                                           cpt.id_prof_cancel,
                                                           cpt.id_prof),
                                                    decode(cpt.flg_status,
                                                           g_canceled,
                                                           cpt.dt_cancel,
                                                           g_interrupted,
                                                           cpt.dt_cancel,
                                                           cpt.dt_care_plan_task),
                                                    NULL) prof_req_spec,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(cpt.flg_status,
                                                      g_canceled,
                                                      cpt.dt_cancel,
                                                      g_interrupted,
                                                      cpt.dt_cancel,
                                                      cpt.dt_care_plan_task),
                                               i_prof.institution,
                                               i_prof.software) dt_care_plan_task,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) task_name,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpt.num_exec,
                                                         cpt.interval,
                                                         cpt.id_unit_measure) task_instructions,
                   cpt.notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cpt.id_cancel_reason) cancel_reason,
                   cpt.notes_cancel,
                   cpt.flg_status,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(cpt.flg_status,
                                                      g_canceled,
                                                      cpt.dt_cancel,
                                                      g_interrupted,
                                                      cpt.dt_cancel,
                                                      cpt.dt_care_plan_task),
                                               i_prof) dt_ord
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task cpt
             WHERE cp.id_care_plan = i_care_plan
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpt.id_care_plan_task
            UNION
            SELECT decode(cpth.id_task_type,
                          g_id_group_analysis,
                          g_id_analysis,
                          g_id_imaging_exams,
                          g_id_exams,
                          g_id_other_exams,
                          g_id_exams,
                          g_id_ext_medication,
                          g_id_medication,
                          g_id_int_medication,
                          g_id_medication,
                          g_id_pharm_medication,
                          g_id_medication,
                          cpth.id_task_type) id_task_type,
                   cpth.id_care_plan_task,
                   decode(cpth.flg_status,
                          g_pending,
                          l_msg_pending,
                          g_inprogress,
                          l_msg_inprogress,
                          g_suspended,
                          l_msg_suspended) msg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cpth.id_prof) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, cpth.id_prof, cpth.dt_care_plan_task, NULL) prof_req_spec,
                   pk_date_utils.date_char_tsz(i_lang, cpth.dt_care_plan_task, i_prof.institution, i_prof.software) dt_care_plan_task,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpth.id_item, cpth.id_task_type) task_name,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpth.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpth.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpth.num_exec,
                                                         cpth.interval,
                                                         cpth.id_unit_measure) task_instructions,
                   cpth.notes,
                   NULL cancel_reason,
                   NULL notes_cancel,
                   cpth.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, cpth.dt_care_plan_task, i_prof) dt_ord
              FROM care_plan cp, care_plan_task_link cptl, care_plan_task_hist cpth
             WHERE cp.id_care_plan = i_care_plan
               AND cp.id_care_plan = cptl.id_care_plan
               AND cptl.id_care_plan_task = cpth.id_care_plan_task
             ORDER BY task_name, dt_ord DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_care_plan);
            pk_types.open_my_cursor(o_task_type_count);
            pk_types.open_my_cursor(o_care_plan_task);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_detail;

    FUNCTION get_care_plan_task_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_care_plan_task  IN care_plan_task.id_care_plan_task%TYPE,
        o_task_type_count OUT pk_types.cursor_type,
        o_care_plan_task  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_pending     VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T061');
        l_msg_inprogress  VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T062');
        l_msg_suspended   VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T063');
        l_msg_finished    VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T064');
        l_msg_interrupted VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T065');
        l_msg_canceled    VARCHAR2(100) := pk_message.get_message(i_lang, 'CARE_PLANS_T066');
    
    BEGIN
    
        g_error := 'OPEN O_TASK_TYPE_COUNT';
        OPEN o_task_type_count FOR
            SELECT decode(cptc.id_task_type,
                          g_id_group_analysis,
                          g_id_analysis,
                          g_id_imaging_exams,
                          g_id_exams,
                          g_id_other_exams,
                          g_id_exams,
                          g_id_ext_medication,
                          g_id_medication,
                          g_id_int_medication,
                          g_id_medication,
                          g_id_pharm_medication,
                          g_id_medication,
                          cptc.id_task_type) id_task_type,
                   sd.desc_val task_type,
                   1 task_count
              FROM care_plan cp, care_plan_task_count cptc, care_plan_task_link cptl, care_plan_task cpt, sys_domain sd
             WHERE cpt.id_care_plan_task = i_care_plan_task
               AND cpt.id_care_plan_task = cptl.id_care_plan_task
               AND cptl.id_care_plan = cp.id_care_plan
               AND cp.id_care_plan = cptc.id_care_plan
               AND cptc.id_task_type = cpt.id_task_type
               AND sd.val = decode(pk_task_type.get_task_type_flg(i_lang, cptc.id_task_type),
                                   g_group_analysis,
                                   g_analysis,
                                   g_imaging_exams,
                                   g_exams,
                                   g_other_exams,
                                   g_exams,
                                   g_ext_medication,
                                   g_medication,
                                   g_int_medication,
                                   g_medication,
                                   pk_task_type.get_task_type_flg(i_lang, cptc.id_task_type))
               AND sd.code_domain = 'TASK_TYPE.FLG_TYPE'
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
             ORDER BY dt_care_plan_task DESC;
    
        g_error := 'OPEN O_CARE_PLAN_TASK';
        OPEN o_care_plan_task FOR
            SELECT decode(cpt.id_task_type,
                          g_id_group_analysis,
                          g_id_analysis,
                          g_id_imaging_exams,
                          g_id_exams,
                          g_id_other_exams,
                          g_id_exams,
                          g_id_ext_medication,
                          g_id_medication,
                          g_id_int_medication,
                          g_id_medication,
                          g_id_pharm_medication,
                          g_id_medication,
                          cpt.id_task_type) id_task_type,
                   cpt.id_care_plan_task,
                   decode(cpt.flg_status,
                          g_pending,
                          l_msg_pending,
                          g_inprogress,
                          l_msg_inprogress,
                          g_suspended,
                          l_msg_suspended,
                          g_finished,
                          l_msg_finished,
                          g_interrupted,
                          l_msg_interrupted,
                          g_canceled,
                          l_msg_canceled) msg,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    decode(cpt.flg_status,
                                                           g_canceled,
                                                           cpt.id_prof_cancel,
                                                           g_interrupted,
                                                           cpt.id_prof_cancel,
                                                           cpt.id_prof)) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(cpt.flg_status,
                                                           g_canceled,
                                                           cpt.id_prof_cancel,
                                                           g_interrupted,
                                                           cpt.id_prof_cancel,
                                                           cpt.id_prof),
                                                    decode(cpt.flg_status,
                                                           g_canceled,
                                                           cpt.dt_cancel,
                                                           g_interrupted,
                                                           cpt.dt_cancel,
                                                           cpt.dt_care_plan_task),
                                                    NULL) prof_req_spec,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(cpt.flg_status,
                                                      g_canceled,
                                                      cpt.dt_cancel,
                                                      g_interrupted,
                                                      cpt.dt_cancel,
                                                      cpt.dt_care_plan_task),
                                               i_prof.institution,
                                               i_prof.software) dt_care_plan_task,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) task_name,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpt.num_exec,
                                                         cpt.interval,
                                                         cpt.id_unit_measure) task_instructions,
                   cpt.notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cpt.id_cancel_reason) cancel_reason,
                   cpt.notes_cancel,
                   cpt.flg_status,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(cpt.flg_status,
                                                      g_canceled,
                                                      cpt.dt_cancel,
                                                      g_interrupted,
                                                      cpt.dt_cancel,
                                                      cpt.dt_care_plan_task),
                                               i_prof) dt_ord
              FROM care_plan_task cpt
             WHERE cpt.id_care_plan_task = i_care_plan_task
            UNION
            SELECT decode(cpth.id_task_type,
                          g_id_group_analysis,
                          g_id_analysis,
                          g_id_imaging_exams,
                          g_id_exams,
                          g_id_other_exams,
                          g_id_exams,
                          g_id_ext_medication,
                          g_id_medication,
                          g_id_int_medication,
                          g_id_medication,
                          g_id_pharm_medication,
                          g_id_medication,
                          cpth.id_task_type) id_task_type,
                   cpth.id_care_plan_task,
                   decode(cpth.flg_status,
                          g_pending,
                          l_msg_pending,
                          g_inprogress,
                          l_msg_inprogress,
                          g_suspended,
                          l_msg_suspended) msg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cpth.id_prof) prof_req,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, cpth.id_prof, cpth.dt_care_plan_task, NULL) prof_req_spec,
                   pk_date_utils.date_char_tsz(i_lang, cpth.dt_care_plan_task, i_prof.institution, i_prof.software) dt_care_plan_task,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpth.id_item, cpth.id_task_type) task_name,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpth.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpth.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpth.num_exec,
                                                         cpth.interval,
                                                         cpth.id_unit_measure) task_instructions,
                   cpth.notes,
                   NULL cancel_reason,
                   NULL notes_cancel,
                   cpth.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, cpth.dt_care_plan_task, i_prof) dt_ord
              FROM care_plan_task_hist cpth
             WHERE cpth.id_care_plan_task = i_care_plan_task
             ORDER BY dt_ord DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TASK_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_task_type_count);
            pk_types.open_my_cursor(o_care_plan_task);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_task_detail;

    FUNCTION get_care_plan_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN table_varchar,
        i_care_plan_task IN table_number,
        i_task_type      IN table_varchar,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_task_med IS
            SELECT COUNT(cpt.id_care_plan_task)
              FROM care_plan_task cpt, task_type tt
             WHERE cpt.id_care_plan_task IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(i_care_plan_task) t)
               AND cpt.id_task_type = tt.id_task_type
               AND tt.flg_type IN (g_int_medication, g_ext_medication);
    
        CURSOR c_care_plans IS
            SELECT MIN(COUNT) task_num
              FROM (SELECT COUNT(cptl.id_care_plan) COUNT, cptl.id_care_plan_task
                      FROM care_plan_task_link cptl
                     WHERE cptl.id_care_plan_task IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                       t.column_value
                                                        FROM TABLE(i_care_plan_task) t)
                     GROUP BY cptl.id_care_plan_task);
    
        CURSOR c_task_permission IS
            SELECT nvl(profile_permission_task, '#')
              FROM (SELECT cptsi.profile_permission_task,
                           row_number() over(PARTITION BY cptsi.id_task_type ORDER BY cptsi.id_institution DESC, cptsi.id_software DESC) rn
                      FROM care_plan_task cpt, care_plan_task_soft_inst cptsi
                     WHERE cpt.id_care_plan_task IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                      t.column_value
                                                       FROM TABLE(i_care_plan_task) t)
                       AND cpt.id_task_type = cptsi.id_task_type
                       AND cptsi.id_institution IN (0, i_prof.institution)
                       AND cptsi.id_software IN (0, i_prof.software))
             WHERE rn = 1;
    
        CURSOR c_profile IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt
             WHERE ppt.id_profile_template = pt.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND pt.id_software = i_prof.software;
    
        l_flg_task_type VARCHAR2(2);
        l_num_task_type NUMBER := 0;
    
        l_flg_status VARCHAR2(2);
        l_num_status NUMBER := 0;
    
        l_count_task  NUMBER := 0;
        l_count_state NUMBER := 0;
    
        l_task_med       NUMBER;
        l_num_care_plans NUMBER;
    
        l_profile         VARCHAR2(10);
        l_prof_cat_type   category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
        l_task_permission care_plan_task_soft_inst.profile_permission_task%TYPE;
    
    BEGIN
    
        l_count_task  := i_care_plan_task.count;
        l_count_state := i_from_state.count;
    
        l_flg_task_type := i_task_type(1);
        l_num_task_type := l_num_task_type + 1;
        IF i_task_type.count > 1
        THEN
            FOR i IN 2 .. i_task_type.count
            LOOP
                IF l_flg_task_type = i_task_type(i)
                THEN
                    l_num_task_type := l_num_task_type + 1;
                ELSE
                    l_num_task_type := l_num_task_type - 1;
                END IF;
            END LOOP;
        END IF;
    
        l_flg_status := i_from_state(1);
        l_num_status := l_num_status + 1;
        IF i_from_state.count > 1
        THEN
            FOR i IN 2 .. i_from_state.count
            LOOP
                IF l_flg_status = i_from_state(i)
                THEN
                    l_num_status := l_num_status + 1;
                ELSE
                    l_num_status := l_num_status - 1;
                END IF;
            END LOOP;
        END IF;
    
        IF l_num_status = i_from_state.count
        THEN
            l_count_state := 1;
        END IF;
    
        g_error := 'OPEN C_CARE_PLANS';
        OPEN c_care_plans;
        FETCH c_care_plans
            INTO l_num_care_plans;
        CLOSE c_care_plans;
    
        g_error := 'OPEN C_TASK_PERMISSION';
        OPEN c_task_permission;
        FETCH c_task_permission
            INTO l_task_permission;
        CLOSE c_task_permission;
    
        g_error := 'OPEN C_PROFILE';
        OPEN c_profile;
        FETCH c_profile
            INTO l_profile;
        CLOSE c_profile;
    
        IF l_num_task_type = i_task_type.count
        THEN
            IF i_task_type(1) IN (g_medication, g_ext_medication, g_int_medication)
            THEN
                IF l_count_task > 1
                THEN
                    IF l_num_care_plans = 1
                    THEN
                        g_error := 'GET CURSOR O_ACTIONS 1';
                        IF pk_sysconfig.get_config('PHARMACY_ENABLED', i_prof) = 'Y'
                        THEN
                            OPEN o_actions FOR
                                SELECT id_action,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             g_inactive
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE a.subject = i_subject
                                   AND a.id_parent IS NULL
                                   AND a.internal_name NOT IN ('ORDER', 'DISSOCIATE')
                                   AND (SELECT COUNT(DISTINCT from_state)
                                          FROM action act
                                         WHERE act.id_parent = a.id_action
                                           AND act.from_state IN (SELECT column_value
                                                                    FROM TABLE(i_from_state))) = l_count_state
                                 ORDER BY rank, desc_action;
                        ELSE
                            OPEN o_actions FOR
                                SELECT id_action,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             g_inactive
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE a.subject = i_subject
                                   AND a.id_parent IS NULL
                                   AND a.internal_name NOT IN ('ORDER', 'ORDER_MED_PHARM', 'DISSOCIATE')
                                   AND (SELECT COUNT(DISTINCT from_state)
                                          FROM action act
                                         WHERE act.id_parent = a.id_action
                                           AND act.from_state IN (SELECT column_value
                                                                    FROM TABLE(i_from_state))) = l_count_state
                                 ORDER BY rank, desc_action;
                        END IF;
                    ELSE
                        g_error := 'GET CURSOR O_ACTIONS 2';
                        IF pk_sysconfig.get_config('PHARMACY_ENABLED', i_prof) = 'Y'
                        THEN
                            OPEN o_actions FOR
                                SELECT id_action,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             g_inactive
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE a.subject = i_subject
                                   AND a.id_parent IS NULL
                                   AND internal_name != 'ORDER'
                                   AND (SELECT COUNT(DISTINCT from_state)
                                          FROM action act
                                         WHERE act.id_parent = a.id_action
                                           AND act.from_state IN (SELECT column_value
                                                                    FROM TABLE(i_from_state))) = l_count_state
                                 ORDER BY rank, desc_action;
                        ELSE
                            OPEN o_actions FOR
                                SELECT id_action,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             g_inactive
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE a.subject = i_subject
                                   AND a.id_parent IS NULL
                                   AND internal_name NOT IN ('ORDER', 'ORDER_MED_PHARM')
                                   AND (SELECT COUNT(DISTINCT from_state)
                                          FROM action act
                                         WHERE act.id_parent = a.id_action
                                           AND act.from_state IN (SELECT column_value
                                                                    FROM TABLE(i_from_state))) = l_count_state
                                 ORDER BY rank, desc_action;
                        END IF;
                    END IF;
                ELSE
                    IF l_num_care_plans = 1
                    THEN
                        g_error := 'GET CURSOR O_ACTIONS 3';
                        IF pk_sysconfig.get_config('PHARMACY_ENABLED', i_prof) = 'Y'
                        THEN
                            OPEN o_actions FOR
                                SELECT id_action,
                                       NULL id_parent,
                                       LEVEL,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             decode(l_prof_cat_type,
                                                    g_doctor,
                                                    g_active,
                                                    decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE subject = i_subject
                                   AND from_state IN (SELECT *
                                                        FROM TABLE(i_from_state))
                                   AND internal_name NOT IN ('ORDER', 'DISSOCIATE')
                                CONNECT BY PRIOR id_action = id_parent
                                 START WITH id_parent IS NULL
                                 ORDER BY rank, desc_action;
                        ELSE
                            OPEN o_actions FOR
                                SELECT id_action,
                                       NULL id_parent,
                                       LEVEL,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             decode(l_prof_cat_type,
                                                    g_doctor,
                                                    g_active,
                                                    decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE subject = i_subject
                                   AND from_state IN (SELECT *
                                                        FROM TABLE(i_from_state))
                                   AND internal_name NOT IN ('ORDER', 'ORDER_MED_PHARM', 'DISSOCIATE')
                                CONNECT BY PRIOR id_action = id_parent
                                 START WITH id_parent IS NULL
                                 ORDER BY rank, desc_action;
                        END IF;
                    ELSE
                        g_error := 'GET CURSOR O_ACTIONS 4';
                        IF pk_sysconfig.get_config('PHARMACY_ENABLED', i_prof) = 'Y'
                        THEN
                            OPEN o_actions FOR
                                SELECT id_action,
                                       NULL id_parent,
                                       LEVEL,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             decode(l_prof_cat_type,
                                                    g_doctor,
                                                    g_active,
                                                    decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE subject = i_subject
                                   AND from_state IN (SELECT *
                                                        FROM TABLE(i_from_state))
                                   AND internal_name != 'ORDER'
                                CONNECT BY PRIOR id_action = id_parent
                                 START WITH id_parent IS NULL
                                 ORDER BY rank, desc_action;
                        ELSE
                            OPEN o_actions FOR
                                SELECT id_action,
                                       NULL id_parent,
                                       LEVEL,
                                       to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       icon,
                                       decode(flg_default, 'D', 'Y', 'N') flg_default,
                                       CASE
                                            WHEN a.internal_name IN
                                                 ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                             decode(l_prof_cat_type,
                                                    g_doctor,
                                                    g_active,
                                                    decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                            ELSE
                                             g_active
                                        END flg_active,
                                       internal_name action
                                  FROM action a
                                 WHERE subject = i_subject
                                   AND from_state IN (SELECT *
                                                        FROM TABLE(i_from_state))
                                   AND internal_name NOT IN ('ORDER', 'ORDER_MED_PHARM')
                                CONNECT BY PRIOR id_action = id_parent
                                 START WITH id_parent IS NULL
                                 ORDER BY rank, desc_action;
                        END IF;
                    END IF;
                END IF;
            ELSE
                IF l_count_task > 1
                THEN
                    IF l_num_care_plans = 1
                    THEN
                        g_error := 'GET CURSOR O_ACTIONS 5';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         g_inactive
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE a.subject = i_subject
                               AND a.id_parent IS NULL
                               AND internal_name IN
                                   (SELECT internal_name
                                      FROM action
                                     WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                       AND internal_name NOT IN ('ORDER_MED', 'DISSOCIATE'))
                               AND (SELECT COUNT(DISTINCT from_state)
                                      FROM action act
                                     WHERE act.id_parent = a.id_action
                                       AND act.from_state IN (SELECT column_value
                                                                FROM TABLE(i_from_state))) = l_count_state
                             ORDER BY rank, desc_action;
                    ELSE
                        g_error := 'GET CURSOR O_ACTIONS 6';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         g_inactive
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE a.subject = i_subject
                               AND a.id_parent IS NULL
                               AND internal_name IN (SELECT internal_name
                                                       FROM action
                                                      WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                                        AND internal_name != 'ORDER_MED')
                               AND (SELECT COUNT(DISTINCT from_state)
                                      FROM action act
                                     WHERE act.id_parent = a.id_action
                                       AND act.from_state IN (SELECT column_value
                                                                FROM TABLE(i_from_state))) = l_count_state
                             ORDER BY rank, desc_action;
                    END IF;
                ELSE
                    IF l_num_care_plans = 1
                    THEN
                        g_error := 'GET CURSOR O_ACTIONS 7';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   NULL id_parent,
                                   LEVEL,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         decode(l_prof_cat_type,
                                                g_doctor,
                                                g_active,
                                                decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE subject = i_subject
                               AND from_state IN (SELECT *
                                                    FROM TABLE(i_from_state))
                               AND internal_name IN
                                   (SELECT internal_name
                                      FROM action
                                     WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                       AND internal_name NOT IN ('ORDER_MED', 'DISSOCIATE'))
                            CONNECT BY PRIOR id_action = id_parent
                             START WITH id_parent IS NULL
                             ORDER BY rank, desc_action;
                    ELSE
                        g_error := 'GET CURSOR O_ACTIONS 8';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   NULL id_parent,
                                   LEVEL,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         decode(l_prof_cat_type,
                                                g_doctor,
                                                g_active,
                                                decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE subject = i_subject
                               AND from_state IN (SELECT *
                                                    FROM TABLE(i_from_state))
                               AND internal_name IN (SELECT internal_name
                                                       FROM action
                                                      WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                                        AND internal_name != 'ORDER_MED')
                            CONNECT BY PRIOR id_action = id_parent
                             START WITH id_parent IS NULL
                             ORDER BY rank, desc_action;
                    END IF;
                END IF;
            END IF;
        ELSE
            IF l_count_task > 1
            THEN
                g_error := 'GET CURSOR O_ACTIONS 12';
                OPEN o_actions FOR
                    SELECT id_action,
                           to_state,
                           pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                           icon,
                           decode(flg_default, 'D', 'Y', 'N') flg_default,
                           CASE
                                WHEN a.internal_name IN ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                 g_inactive
                                ELSE
                                 g_active
                            END flg_active,
                           internal_name action
                      FROM action a
                     WHERE a.subject = i_subject
                       AND a.id_parent IS NULL
                       AND internal_name IN (SELECT internal_name
                                               FROM action
                                              WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                                AND internal_name NOT IN ('ORDER', 'ORDER_MED'))
                       AND (SELECT COUNT(DISTINCT from_state)
                              FROM action act
                             WHERE act.id_parent = a.id_action
                               AND act.from_state IN (SELECT DISTINCT column_value
                                                        FROM TABLE(i_from_state))) =
                           (SELECT COUNT(DISTINCT column_value)
                              FROM TABLE(i_from_state))
                     ORDER BY rank, desc_action;
            ELSE
                g_error := 'GET CURSOR C_TASK_MED';
                OPEN c_task_med;
                FETCH c_task_med
                    INTO l_task_med;
                CLOSE c_task_med;
            
                IF l_task_med > 0
                THEN
                    IF l_num_care_plans = 1
                    THEN
                        g_error := 'GET CURSOR O_ACTIONS 9';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         decode(l_prof_cat_type,
                                                g_doctor,
                                                g_active,
                                                decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE a.subject = i_subject
                               AND a.id_parent IS NULL
                               AND internal_name IN
                                   (SELECT internal_name
                                      FROM action
                                     WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                       AND internal_name NOT IN ('ORDER', 'ORDER_MED', 'DISSOCIATE'))
                               AND (SELECT COUNT(DISTINCT from_state)
                                      FROM action act
                                     WHERE act.id_parent = a.id_action
                                       AND act.from_state IN (SELECT DISTINCT column_value
                                                                FROM TABLE(i_from_state))) =
                                   (SELECT COUNT(DISTINCT column_value)
                                      FROM TABLE(i_from_state))
                             ORDER BY rank, desc_action;
                    
                    ELSE
                        g_error := 'GET CURSOR O_ACTIONS 10';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         decode(l_prof_cat_type,
                                                g_doctor,
                                                g_active,
                                                decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE a.subject = i_subject
                               AND a.id_parent IS NULL
                               AND internal_name IN
                                   (SELECT internal_name
                                      FROM action
                                     WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                       AND internal_name NOT IN ('ORDER', 'ORDER_MED'))
                               AND (SELECT COUNT(DISTINCT from_state)
                                      FROM action act
                                     WHERE act.id_parent = a.id_action
                                       AND act.from_state IN (SELECT DISTINCT column_value
                                                                FROM TABLE(i_from_state))) =
                                   (SELECT COUNT(DISTINCT column_value)
                                      FROM TABLE(i_from_state))
                             ORDER BY rank, desc_action;
                    
                    END IF;
                ELSE
                    IF l_num_care_plans = 1
                    THEN
                        g_error := 'GET CURSOR O_ACTIONS 11';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         decode(l_prof_cat_type,
                                                g_doctor,
                                                g_active,
                                                decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE a.subject = i_subject
                               AND a.id_parent IS NULL
                               AND internal_name IN
                                   (SELECT internal_name
                                      FROM action
                                     WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                       AND internal_name NOT IN ('ORDER_MED', 'DISSOCIATE'))
                               AND (SELECT COUNT(DISTINCT from_state)
                                      FROM action act
                                     WHERE act.id_parent = a.id_action
                                       AND act.from_state IN (SELECT DISTINCT column_value
                                                                FROM TABLE(i_from_state))) =
                                   (SELECT COUNT(DISTINCT column_value)
                                      FROM TABLE(i_from_state))
                             ORDER BY rank, desc_action;
                    ELSE
                        g_error := 'GET CURSOR O_ACTIONS 12';
                        OPEN o_actions FOR
                            SELECT id_action,
                                   to_state,
                                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                   icon,
                                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                                   CASE
                                        WHEN a.internal_name IN
                                             ('ORDER', 'ORDER_MED_EXT', 'ORDER_MED_INT', 'ORDER_MED_PHARM') THEN
                                         decode(l_prof_cat_type,
                                                g_doctor,
                                                g_active,
                                                decode(instr(l_task_permission, l_profile), 0, g_inactive, g_active))
                                        ELSE
                                         g_active
                                    END flg_active,
                                   internal_name action
                              FROM action a
                             WHERE a.subject = i_subject
                               AND a.id_parent IS NULL
                               AND internal_name IN (SELECT internal_name
                                                       FROM action
                                                      WHERE (id_action = a.id_parent OR a.id_parent IS NULL)
                                                        AND internal_name != 'ORDER_MED')
                               AND (SELECT COUNT(DISTINCT from_state)
                                      FROM action act
                                     WHERE act.id_parent = a.id_action
                                       AND act.from_state IN (SELECT DISTINCT column_value
                                                                FROM TABLE(i_from_state))) =
                                   (SELECT COUNT(DISTINCT column_value)
                                      FROM TABLE(i_from_state))
                             ORDER BY rank, desc_action;
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
                                              'GET_CARE_PLAN_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_actions;

    FUNCTION get_care_plan_view_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT sd.val id_action, NULL id_parent, sd.desc_val desc_action, NULL icon, 'A' flg_action
              FROM sys_domain sd
             WHERE sd.code_domain = 'CARE_PLAN_VIEW'
               AND sd.id_language = i_lang
               AND sd.flg_available = 'Y'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_VIEW_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_view_list;

    FUNCTION get_care_plan_task_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_add sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CARE_PLANS_T033');
    
    BEGIN
    
        IF i_flg_type = 'O'
        THEN
            g_error := 'GET O_LIST';
            OPEN o_list FOR
                SELECT id_action, id_parent, flg_type, desc_action, icon, flg_action
                  FROM (SELECT decode(a.internal_name, 'TASK', -1, NULL) id_action,
                               NULL id_parent,
                               a.internal_name flg_type,
                               pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                               NULL icon,
                               '' flg_action,
                               a.rank,
                               1 rn
                          FROM action a
                         WHERE a.subject = 'CARE_PLAN_ADD'
                        UNION ALL
                        SELECT tt.id_task_type id_action,
                               decode(tt.id_task_type_parent, NULL, -1, tt.id_task_type_parent) id_parent,
                               tt.flg_type flg_type,
                               l_msg_add || ' ' || lower(pk_translation.get_translation(i_lang, tt.code_task_type)) ||
                               decode((SELECT COUNT(id_task_type)
                                        FROM task_type
                                       WHERE id_task_type_parent = tt.id_task_type
                                         AND id_task_type IN (SELECT id_task_type
                                                                FROM care_plan_task_soft_inst
                                                               WHERE id_software IN (0, i_prof.software)
                                                                 AND id_institution IN (0, i_prof.institution)
                                                                 AND flg_available = g_yes)),
                                      0,
                                      NULL,
                                      '...') desc_action,
                               decode(tt.flg_type,
                                      g_medication,
                                      decode(i_prof.software,
                                             pk_sysconfig.get_config('SOFTWARE_ID_OUTP', i_prof),
                                             'PrescriptionExtIcon',
                                             'TherapeuticIcon'),
                                      tt.icon) icon,
                               'A' flg_action,
                               cptsi.rank,
                               row_number() over(PARTITION BY tt.id_task_type ORDER BY cptsi.id_institution DESC, cptsi.id_software DESC) rn
                          FROM task_type tt, care_plan_task_soft_inst cptsi
                         WHERE tt.id_task_type = cptsi.id_task_type
                           AND cptsi.id_software IN (0, i_prof.software)
                           AND cptsi.id_institution IN (0, i_prof.institution)
                           AND cptsi.flg_available = g_yes
                        UNION ALL
                        SELECT tt.id_task_type id_action,
                               tt.id_task_type_parent id_parent,
                               tt.flg_type flg_type,
                               NULL desc_action,
                               tt.icon icon,
                               'N' flg_action,
                               cptsi.rank,
                               row_number() over(PARTITION BY tt.id_task_type ORDER BY cptsi.id_institution DESC, cptsi.id_software DESC) rn
                          FROM task_type tt, care_plan_task_soft_inst cptsi
                         WHERE tt.id_task_type = cptsi.id_task_type
                           AND cptsi.id_software IN (0, i_prof.software)
                           AND cptsi.id_institution IN (0, i_prof.institution)
                           AND cptsi.flg_available = g_no)
                 WHERE rn = 1
                 ORDER BY flg_action, rank, desc_action;
        ELSE
            g_error := 'GET O_LIST';
            OPEN o_list FOR
                SELECT id_action, id_parent, flg_type, desc_action, icon, flg_action
                  FROM (SELECT tt.id_task_type id_action,
                               id_task_type_parent id_parent,
                               tt.flg_type flg_type,
                               l_msg_add || ' ' || lower(pk_translation.get_translation(i_lang, tt.code_task_type)) ||
                               decode((SELECT COUNT(id_task_type)
                                        FROM task_type
                                       WHERE id_task_type_parent = tt.id_task_type
                                         AND id_task_type IN (SELECT id_task_type
                                                                FROM care_plan_task_soft_inst
                                                               WHERE id_software IN (0, i_prof.software)
                                                                 AND id_institution IN (0, i_prof.institution)
                                                                 AND flg_available = g_yes)),
                                      0,
                                      NULL,
                                      '...') desc_action,
                               decode(tt.flg_type,
                                      g_medication,
                                      decode(i_prof.software,
                                             pk_sysconfig.get_config('SOFTWARE_ID_OUTP', i_prof),
                                             'PrescriptionExtIcon',
                                             'TherapeuticIcon'),
                                      tt.icon) icon,
                               'A' flg_action,
                               cptsi.rank,
                               row_number() over(PARTITION BY tt.id_task_type ORDER BY cptsi.id_institution DESC, cptsi.id_software DESC) rn
                          FROM task_type tt, care_plan_task_soft_inst cptsi
                         WHERE tt.id_task_type = cptsi.id_task_type
                           AND cptsi.id_software IN (0, i_prof.software)
                           AND cptsi.id_institution IN (0, i_prof.institution)
                           AND cptsi.flg_available = g_yes
                        UNION ALL
                        SELECT tt.id_task_type id_action,
                               tt.id_task_type_parent id_parent,
                               tt.flg_type flg_type,
                               NULL desc_action,
                               tt.icon icon,
                               'N' flg_action,
                               cptsi.rank,
                               row_number() over(PARTITION BY tt.id_task_type ORDER BY cptsi.id_institution DESC, cptsi.id_software DESC) rn
                          FROM task_type tt, care_plan_task_soft_inst cptsi
                         WHERE tt.id_task_type = cptsi.id_task_type
                           AND cptsi.id_software IN (0, i_prof.software)
                           AND cptsi.id_institution IN (0, i_prof.institution)
                           AND cptsi.flg_available = g_no)
                 WHERE rn = 1
                 ORDER BY flg_action, rank, desc_action;
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
                                              'GET_CARE_PLAN_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_task_list;

    FUNCTION get_care_plan_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT cpt.id_care_plan_type id_type,
                   pk_translation.get_translation(i_lang, cpt.code_care_plan_type) desc_type,
                   cpt.flg_type,
                   -1 rank
              FROM care_plan_type cpt
             WHERE cpt.flg_type = 'A'
            UNION ALL
            SELECT cpt.id_care_plan_type id_type,
                   pk_translation.get_translation(i_lang, cpt.code_care_plan_type) desc_type,
                   cpt.flg_type,
                   0 rank
              FROM care_plan_type cpt
             WHERE cpt.flg_type != 'A'
             ORDER BY rank, id_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_type;

    FUNCTION get_care_plan_subject
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_allergie         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ALLERGY_LIST_T008');
        l_msg_relevant_disease sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'RELEVANT_DISEASES_T001');
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT phd.id_pat_history_diagnosis id_subject,
                   g_relevant_disease subject_type,
                   decode(phd.id_alert_diagnosis,
                          NULL,
                          phd.desc_pat_history_diagnosis,
                          decode(phd.desc_pat_history_diagnosis, NULL, '', phd.desc_pat_history_diagnosis || ' - ') ||
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => pk_alert_constant.g_yes)) || ' (' ||
                   l_msg_relevant_disease || ')' desc_subject
              FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
             WHERE phd.id_pat_history_diagnosis IN
                   (SELECT decode(phd.id_alert_diagnosis,
                                  NULL,
                                  pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                       NULL,
                                                                       phd.desc_pat_history_diagnosis,
                                                                       i_patient,
                                                                       i_prof,
                                                                       'Y'),
                                  pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                       phd.id_alert_diagnosis,
                                                                       phd.desc_pat_history_diagnosis,
                                                                       i_patient,
                                                                       i_prof,
                                                                       'Y'))
                      FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                     WHERE phd.id_patient = i_patient
                       AND phd.flg_type = 'M'
                       AND (phd.id_alert_diagnosis IS NOT NULL OR phd.desc_pat_history_diagnosis IS NOT NULL OR
                           (d.flg_other = 'Y'))
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND ad.id_diagnosis = d.id_diagnosis(+)
                     GROUP BY phd.id_alert_diagnosis, desc_pat_history_diagnosis)
               AND phd.flg_status != 'C'
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND ad.id_diagnosis = d.id_diagnosis
            UNION ALL
            SELECT pp.id_pat_problem id_subject,
                   g_diagnosis subject_type,
                   decode(pp.desc_pat_problem,
                          '',
                          pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                     i_id_diagnosis        => nvl2(ed.id_epis_diagnosis,
                                                                                   d1.id_diagnosis,
                                                                                   d.id_diagnosis),
                                                     i_desc_epis_diagnosis => nvl2(ed.id_epis_diagnosis,
                                                                                   ed.desc_epis_diagnosis,
                                                                                   NULL),
                                                     i_code                => d.code_icd,
                                                     i_flg_other           => d.flg_other,
                                                     i_flg_std_diag        => pk_alert_constant.g_yes,
                                                     i_epis_diag           => ed.id_epis_diagnosis),
                          pp.desc_pat_problem) desc_subject
              FROM pat_problem pp, diagnosis d, epis_diagnosis ed, diagnosis d1
             WHERE pp.id_patient = i_patient
               AND pp.id_diagnosis = d.id_diagnosis(+)
               AND pp.flg_status != pk_problems.g_pat_probl_cancel
               AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
               AND d1.id_diagnosis(+) = ed.id_diagnosis
               AND (pp.id_diagnosis = d.id_diagnosis OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
               AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
            UNION ALL
            SELECT pa.id_pat_allergy id_subject,
                   g_allergy subject_type,
                   pk_translation.get_translation(i_lang, a.code_allergy) || ' (' || l_msg_allergie || ')' desc_subject
              FROM pat_allergy pa, allergy a
             WHERE pa.id_patient = i_patient
               AND a.id_allergy = pa.id_allergy
               AND pa.flg_status != 'C'
               AND nvl(instr(a.flg_without, 'Y'), 0) <> 1
             ORDER BY 3 ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_SUBJECT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_subject;

    FUNCTION get_care_plan_coordinator
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT p.id_professional data, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label
              FROM professional p, prof_institution pi, prof_cat pc, category c
             WHERE p.id_professional = pi.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = pk_alert_constant.g_active
               AND pi.dt_end_tstz IS NULL
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND pi.id_professional = pc.id_professional
               AND pc.id_institution = i_prof.institution
               AND pc.id_category = c.id_category
               AND c.flg_type IN (g_doctor, g_nurse, g_social, g_case_manager)
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_COORDINATOR',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_coordinator;

    FUNCTION check_care_plan_param
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dt_begin_str        IN VARCHAR2,
        i_dt_end_str          IN VARCHAR2,
        i_num_exec            IN care_plan_task.num_exec%TYPE,
        i_interval_unit       IN care_plan_task.id_unit_measure%TYPE,
        i_interval            IN care_plan_task.interval%TYPE,
        o_sysdate             OUT VARCHAR2,
        o_dt_begin            OUT VARCHAR2,
        o_dt_end              OUT VARCHAR2,
        o_hr_begin            OUT VARCHAR2,
        o_hr_end              OUT VARCHAR2,
        o_num_exec            OUT VARCHAR2,
        o_interval_unit       OUT VARCHAR2,
        o_interval            OUT VARCHAR2,
        o_dt_begin_edit       OUT VARCHAR2,
        o_dt_end_edit         OUT VARCHAR2,
        o_num_exec_edit       OUT VARCHAR2,
        o_interval_unit_edit  OUT VARCHAR2,
        o_interval_edit       OUT VARCHAR2,
        o_dt_begin_param      OUT VARCHAR2,
        o_dt_end_param        OUT VARCHAR2,
        o_num_exec_param      OUT care_plan_task.num_exec%TYPE,
        o_interval_unit_param OUT care_plan_task.id_unit_measure%TYPE,
        o_interval_param      OUT care_plan_task.interval%TYPE,
        o_instructions_format OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interval care_plan_task.interval%TYPE;
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_market VARCHAR2(10) := pk_sysconfig.get_config('MARKET', i_prof);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str, NULL);
    
        g_error    := 'INITIALIZE';
        o_dt_begin := pk_date_utils.dt_chr_tsz(i_lang, nvl(l_dt_begin, g_sysdate_tstz), i_prof);
    
        o_hr_begin := pk_date_utils.date_char_hour_tsz(i_lang,
                                                       nvl(l_dt_begin, g_sysdate_tstz),
                                                       i_prof.institution,
                                                       i_prof.software);
    
        o_dt_begin_param := pk_date_utils.to_char_insttimezone(i_prof,
                                                               nvl(l_dt_begin, g_sysdate_tstz),
                                                               'YYYYMMDDHH24MISS');
    
        o_num_exec       := i_num_exec;
        o_num_exec_param := i_num_exec;
    
        IF l_market = 'USA'
        THEN
            o_interval := pk_message.get_message(i_lang, 'CARE_PLANS_T041') || ' ' || i_interval;
        ELSE
            o_interval := i_interval || ' / ' || i_interval;
        END IF;
    
        o_interval_param := i_interval;
    
        o_interval_unit       := lower(pk_translation.get_translation(i_lang,
                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                      i_interval_unit));
        o_interval_unit_param := i_interval_unit;
    
        o_dt_begin_edit      := 'Y';
        o_dt_end_edit        := 'N';
        o_num_exec_edit      := 'Y';
        o_interval_edit      := 'Y';
        o_interval_unit_edit := 'Y';
    
        o_sysdate := g_sysdate_tstz;
    
        IF i_interval IS NOT NULL
        THEN
            IF i_interval_unit = g_day
            THEN
                l_interval     := to_number(i_interval) * 86400;
                o_dt_end       := pk_date_utils.dt_chr_tsz(i_lang,
                                                           nvl(l_dt_begin, g_sysdate_tstz) +
                                                           numtodsinterval((i_num_exec - 1) * (l_interval / 86400),
                                                                           'DAY'),
                                                           i_prof);
                o_hr_end       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   nvl(l_dt_begin, g_sysdate_tstz) +
                                                                   numtodsinterval((i_num_exec - 1) *
                                                                                   (l_interval / 86400),
                                                                                   'DAY'),
                                                                   i_prof.institution,
                                                                   i_prof.software);
                o_dt_end_param := pk_date_utils.to_char_insttimezone(i_prof,
                                                                     pk_date_utils.add_days_to_tstz(nvl(l_dt_begin,
                                                                                                        g_sysdate_tstz),
                                                                                                    (i_num_exec - 1) *
                                                                                                    (l_interval / 86400)),
                                                                     'YYYYMMDDHH24MISS');
            ELSIF i_interval_unit = g_week
            THEN
                l_interval     := to_number(i_interval) * 604800;
                o_dt_end       := pk_date_utils.dt_chr_tsz(i_lang,
                                                           nvl(l_dt_begin, g_sysdate_tstz) +
                                                           numtodsinterval((i_num_exec - 1) *
                                                                           ((l_interval / 604800) * 7),
                                                                           'DAY'),
                                                           i_prof);
                o_hr_end       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   nvl(l_dt_begin, g_sysdate_tstz) +
                                                                   numtodsinterval((i_num_exec - 1) *
                                                                                   ((l_interval / 604800) * 7),
                                                                                   'DAY'),
                                                                   i_prof.institution,
                                                                   i_prof.software);
                o_dt_end_param := pk_date_utils.to_char_insttimezone(i_prof,
                                                                     pk_date_utils.add_days_to_tstz(nvl(l_dt_begin,
                                                                                                        g_sysdate_tstz),
                                                                                                    (i_num_exec - 1) *
                                                                                                    (l_interval / 604800) * 7),
                                                                     'YYYYMMDDHH24MISS');
            ELSIF i_interval_unit = g_month
            THEN
                l_interval     := to_number(i_interval) * 2592000;
                o_dt_end       := pk_date_utils.dt_chr_tsz(i_lang,
                                                           nvl(l_dt_begin, g_sysdate_tstz) +
                                                           numtodsinterval((i_num_exec - 1) *
                                                                           ((l_interval / 2592000) * 30),
                                                                           'DAY'),
                                                           i_prof);
                o_hr_end       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   nvl(l_dt_begin, g_sysdate_tstz) +
                                                                   numtodsinterval((i_num_exec - 1) *
                                                                                   ((l_interval / 2592000) * 30),
                                                                                   'DAY'),
                                                                   i_prof.institution,
                                                                   i_prof.software);
                o_dt_end_param := pk_date_utils.to_char_insttimezone(i_prof,
                                                                     pk_date_utils.add_days_to_tstz(nvl(l_dt_begin,
                                                                                                        g_sysdate_tstz),
                                                                                                    (i_num_exec - 1) *
                                                                                                    (l_interval / 2592000) * 30),
                                                                     'YYYYMMDDHH24MISS');
            ELSIF i_interval_unit = g_year
            THEN
                l_interval     := to_number(i_interval) * 31536000;
                o_dt_end       := pk_date_utils.dt_chr_tsz(i_lang,
                                                           nvl(l_dt_begin, g_sysdate_tstz) +
                                                           numtodsinterval((i_num_exec - 1) *
                                                                           ((l_interval / 31536000) * 365),
                                                                           'DAY'),
                                                           i_prof);
                o_hr_end       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   nvl(l_dt_begin, g_sysdate_tstz) +
                                                                   numtodsinterval((i_num_exec - 1) *
                                                                                   ((l_interval / 31536000) * 365),
                                                                                   'DAY'),
                                                                   i_prof.institution,
                                                                   i_prof.software);
                o_dt_end_param := pk_date_utils.to_char_insttimezone(i_prof,
                                                                     pk_date_utils.add_days_to_tstz(nvl(l_dt_begin,
                                                                                                        g_sysdate_tstz),
                                                                                                    (i_num_exec - 1) *
                                                                                                    (l_interval /
                                                                                                    31536000) * 365),
                                                                     'YYYYMMDDHH24MISS');
            END IF;
        END IF;
    
        o_instructions_format := '<b>' || pk_message.get_message(i_lang, 'CARE_PLANS_T016') || '</b> [' ||
                                 pk_care_plans.get_instructions_format(i_lang,
                                                                       i_prof,
                                                                       i_dt_begin_str,
                                                                       nvl(o_dt_end_param, i_dt_end_str),
                                                                       i_num_exec,
                                                                       i_interval,
                                                                       i_interval_unit) || ']';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_CARE_PLAN_PARAM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_care_plan_param;

    FUNCTION get_instructions_format
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_num_exec            IN care_plan_task.num_exec%TYPE,
        i_interval            IN care_plan_task.interval%TYPE,
        i_interval_unit       IN care_plan_task.id_unit_measure%TYPE,
        o_instructions_format OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market VARCHAR2(10) := pk_sysconfig.get_config('MARKET', i_prof);
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        IF l_market = 'USA'
        THEN
            SELECT '[' ||
                   decode(i_dt_begin,
                          NULL,
                          '',
                          (pk_message.get_message(i_lang, 'CARE_PLANS_T037') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software))) ||
                   decode(i_interval,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T038') || ': ' ||
                          pk_message.get_message(i_lang, 'CARE_PLANS_T041') || ' ' || i_interval || ' ' ||
                          lower(pk_translation.get_translation(i_lang,
                                                                'UNIT_MEASURE.CODE_UNIT_MEASURE.' || i_interval_unit)))) ||
                   decode(i_num_exec,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T039') || ': ' || i_num_exec)) ||
                   decode(i_dt_end,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T040') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software))) || ']'
              INTO o_instructions_format
              FROM dual;
        ELSE
            SELECT '[' ||
                   decode(i_dt_begin,
                          NULL,
                          '',
                          (pk_message.get_message(i_lang, 'CARE_PLANS_T037') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software))) ||
                   decode(i_interval,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T038') || ': ' || i_interval || ' / ' ||
                          i_interval || ' ' ||
                          lower(pk_translation.get_translation(i_lang,
                                                                'UNIT_MEASURE.CODE_UNIT_MEASURE.' || i_interval_unit)))) ||
                   decode(i_num_exec,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T039') || ': ' || i_num_exec)) ||
                   decode(i_dt_end,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T040') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software))) || ']'
              INTO o_instructions_format
              FROM dual;
        END IF;
    
        IF o_instructions_format = '[]'
        THEN
            o_instructions_format := '';
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
                                              'GET_INSTRUCTIONS_FORMAT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_instructions_format;

    FUNCTION get_instructions_format
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_num_exec      IN care_plan_task.num_exec%TYPE,
        i_interval      IN care_plan_task.interval%TYPE,
        i_interval_unit IN care_plan_task.id_unit_measure%TYPE
    ) RETURN VARCHAR2 IS
    
        l_market VARCHAR2(10) := pk_sysconfig.get_config('MARKET', i_prof);
    
        l_dt_begin            TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end              TIMESTAMP WITH LOCAL TIME ZONE;
        l_instructions_format VARCHAR2(200);
    
    BEGIN
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        IF l_market = 'USA'
        THEN
            SELECT decode(i_dt_begin,
                          NULL,
                          '',
                          (pk_message.get_message(i_lang, 'CARE_PLANS_T037') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software))) ||
                   decode(i_interval,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T038') || ': ' ||
                          pk_message.get_message(i_lang, 'CARE_PLANS_T041') || ' ' || i_interval || ' ' ||
                          lower(pk_translation.get_translation(i_lang,
                                                                'UNIT_MEASURE.CODE_UNIT_MEASURE.' || i_interval_unit)))) ||
                   decode(i_num_exec,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T039') || ': ' || i_num_exec)) ||
                   decode(i_dt_end,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T040') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software)))
              INTO l_instructions_format
              FROM dual;
        ELSE
            SELECT decode(i_dt_begin,
                          NULL,
                          '',
                          (pk_message.get_message(i_lang, 'CARE_PLANS_T037') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software))) ||
                   decode(i_interval,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T038') || ': ' || i_interval || ' / ' ||
                          i_interval || ' ' ||
                          lower(pk_translation.get_translation(i_lang,
                                                                'UNIT_MEASURE.CODE_UNIT_MEASURE.' || i_interval_unit)))) ||
                   decode(i_num_exec,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T039') || ': ' || i_num_exec)) ||
                   decode(i_dt_end,
                          NULL,
                          '',
                          ('; ' || pk_message.get_message(i_lang, 'CARE_PLANS_T040') || ': ' ||
                          pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software)))
              INTO l_instructions_format
              FROM dual;
        END IF;
    
        RETURN l_instructions_format;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_instructions_format;

    FUNCTION get_string_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN VARCHAR2,
        i_task_flg_status IN VARCHAR2,
        i_req_flg_status  IN VARCHAR2,
        i_dt_begin        IN VARCHAR2,
        i_req             IN care_plan_task_req.id_req%TYPE,
        i_view            IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_care_plan_task_req IS
            SELECT *
              FROM care_plan_task_req cptr
             WHERE cptr.id_care_plan_task = (SELECT id_care_plan_task
                                               FROM care_plan_task_req
                                              WHERE id_req = i_req)
               AND cptr.order_num = (SELECT MIN(order_num)
                                       FROM care_plan_task_req r
                                      WHERE r.id_req IS NULL
                                        AND r.id_care_plan_task = cptr.id_care_plan_task
                                        AND r.flg_status != g_canceled);
    
        CURSOR c_care_plan_task IS
            SELECT *
              FROM care_plan_task_req cptr
             WHERE cptr.id_care_plan_task = i_req
               AND cptr.order_num = (SELECT MIN(order_num)
                                       FROM care_plan_task_req r
                                      WHERE r.id_req IS NULL
                                        AND r.id_care_plan_task = cptr.id_care_plan_task
                                        AND r.flg_status != g_canceled);
    
        g_color_green VARCHAR2(200);
        g_color_red   VARCHAR2(200);
        g_color_gray  VARCHAR2(200);
    
        l_dt_req       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end       TIMESTAMP WITH LOCAL TIME ZONE;
        l_elapsed_time VARCHAR2(200);
    
        l_status_flg  VARCHAR2(100);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_str  VARCHAR2(200);
    
        l_flg_status VARCHAR2(2);
        l_text       VARCHAR2(200);
        l_icon       VARCHAR2(200);
        l_episode    NUMBER;
    
        l_care_plan_task_req care_plan_task_req%ROWTYPE;
    
        l_string_task VARCHAR2(200);
    
        l_dt_next_task care_plan_task_req.dt_next_task%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_color_green := '0x829664';
        g_color_red   := '0xc86464';
        g_color_gray  := '0xC3C3A5';
    
        IF i_view = 'CARE_PLAN_TASK'
        THEN
            IF i_task_flg_status = g_pending
            THEN
                IF i_dt_begin IS NULL
                THEN
                
                    l_string_task := '0|I|||' || pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                     g_color_green || '||||';
                ELSE
                    OPEN c_care_plan_task;
                    FETCH c_care_plan_task
                        INTO l_care_plan_task_req;
                    g_found := c_care_plan_task%FOUND;
                    CLOSE c_care_plan_task;
                
                    SELECT r.dt_next_task
                      INTO l_dt_next_task
                      FROM care_plan_task_req r
                     WHERE r.id_care_plan_task = l_care_plan_task_req.id_care_plan_task
                       AND r.order_num IN
                           (SELECT nvl((SELECT MIN(cr_date.order_num)
                                         FROM care_plan_task_req cr_date
                                        WHERE cr_date.id_care_plan_task = r.id_care_plan_task
                                          AND cr_date.dt_next_task IS NOT NULL
                                          AND cr_date.flg_status NOT IN
                                              (g_ordered, g_canceled, g_interrupted, g_suspended, g_finished)),
                                       (SELECT MAX(cr_date.order_num)
                                          FROM care_plan_task_req cr_date
                                         WHERE cr_date.id_care_plan_task = r.id_care_plan_task
                                           AND cr_date.dt_next_task IS NOT NULL))
                              FROM dual);
                
                    IF g_found
                       AND l_care_plan_task_req.id_req IS NULL
                    THEN
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_next_task);
                    
                    ELSE
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    END IF;
                
                    IF instr(l_elapsed_time, '-') = 0
                    THEN
                        l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                         pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                         g_color_red || '||||';
                    ELSE
                        l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                         pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                         g_color_green || '||||';
                    END IF;
                END IF;
            ELSIF i_task_flg_status = g_inprogress
            THEN
                IF i_flg_type IN ('PS', 'PZ', 'PF')
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        END IF;
                    ELSE
                        SELECT cr.flg_status, cr.status_flg, cr.status_msg, cr.status_icon, cr.status_str
                          INTO l_flg_status, l_status_flg, l_status_msg, l_status_icon, l_status_str
                          FROM consult_req cr
                         WHERE cr.id_consult_req = i_req;
                    
                        IF l_flg_status IN ('M', 'S', 'N', 'C')
                        THEN
                            -- agendado, processado, pedido rejeitado, cancelado
                            OPEN c_care_plan_task_req;
                            FETCH c_care_plan_task_req
                                INTO l_care_plan_task_req;
                            g_found := c_care_plan_task_req%FOUND;
                            CLOSE c_care_plan_task_req;
                        
                            IF g_found
                               AND l_care_plan_task_req.id_req IS NULL
                            THEN
                                l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                     l_care_plan_task_req.dt_next_task);
                            
                                IF instr(l_elapsed_time, '-') = 0
                                THEN
                                    l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_red || '||||';
                                ELSE
                                    l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_green || '||||';
                                
                                END IF;
                            ELSE
                                l_string_task := pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            l_status_str,
                                                                            l_status_msg,
                                                                            l_status_icon,
                                                                            l_status_flg);
                            END IF;
                        ELSE
                            l_string_task := pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        l_status_str,
                                                                        l_status_msg,
                                                                        l_status_icon,
                                                                        l_status_flg);
                        END IF;
                    END IF;
                ELSIF i_flg_type = 'O'
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        END IF;
                    ELSE
                        SELECT o.flg_state, o.status_str, o.status_msg, o.status_icon, o.status_flg
                          INTO l_flg_status, l_status_str, l_status_msg, l_status_icon, l_status_flg
                          FROM opinion o
                         WHERE o.id_opinion = i_req;
                    
                        IF l_flg_status IN ('O', 'V', 'X', 'N', 'C')
                        THEN
                            -- conlu�do, aprovado, rejeitado, n�o aprovado, cancelado
                            OPEN c_care_plan_task_req;
                            FETCH c_care_plan_task_req
                                INTO l_care_plan_task_req;
                            g_found := c_care_plan_task_req%FOUND;
                            CLOSE c_care_plan_task_req;
                        
                            IF g_found
                               AND l_care_plan_task_req.id_req IS NULL
                            THEN
                                l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                     l_care_plan_task_req.dt_next_task);
                            
                                IF instr(l_elapsed_time, '-') = 0
                                THEN
                                    l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_red || '||||';
                                ELSE
                                    l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_green || '||||';
                                
                                END IF;
                            ELSE
                                l_string_task := pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            l_status_str,
                                                                            l_status_msg,
                                                                            l_status_icon,
                                                                            l_status_flg);
                            END IF;
                        ELSE
                            l_string_task := pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        l_status_str,
                                                                        l_status_msg,
                                                                        l_status_icon,
                                                                        l_status_flg);
                        END IF;
                    END IF;
                ELSIF i_flg_type IN ('A', 'AG')
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        END IF;
                    ELSE
                        IF i_flg_type = 'A'
                        THEN
                            SELECT flg_status_det, status_str, status_msg, status_icon, status_flg, text, icon
                              INTO l_flg_status,
                                   l_status_str,
                                   l_status_msg,
                                   l_status_icon,
                                   l_status_flg,
                                   l_text,
                                   l_icon
                              FROM (SELECT row_number() over(PARTITION BY lte.id_analysis_req ORDER BY arp.dt_analysis_result_par_tstz DESC) rn,
                                           lte.flg_status_det,
                                           lte.status_str,
                                           lte.status_msg,
                                           lte.status_icon,
                                           lte.status_flg,
                                           nvl(TRIM(arp.desc_analysis_result),
                                               (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                                               arp.analysis_result_value_2)) ||
                                           decode(arp.id_unit_measure,
                                                  NULL,
                                                  arp.desc_unit_measure,
                                                  ' ' || pk_translation.get_translation(i_lang,
                                                                                        'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                        arp.id_unit_measure)) text,
                                           decode(pk_utils.is_number(arp.desc_analysis_result),
                                                  'N',
                                                  decode(to_char(arp.desc_analysis_result),
                                                         ad.value,
                                                         ad.icon,
                                                         'AnalysisResultIcon'),
                                                  NULL) icon
                                      FROM lab_tests_ea lte, analysis_result_par arp, analysis_desc ad
                                     WHERE lte.id_analysis_req = i_req
                                       AND lte.id_analysis_result = arp.id_analysis_result(+)
                                       AND arp.id_analysis_parameter = ad.id_analysis_parameter(+)
                                       AND to_char(arp.desc_analysis_result) = ad.value(+))
                             WHERE rn = 1;
                        
                            IF l_flg_status IN ('F', 'L', 'C')
                            THEN
                                -- finalizado, lido, cancelado
                                OPEN c_care_plan_task_req;
                                FETCH c_care_plan_task_req
                                    INTO l_care_plan_task_req;
                                g_found := c_care_plan_task_req%FOUND;
                                CLOSE c_care_plan_task_req;
                            
                                IF g_found
                                   AND l_care_plan_task_req.id_req IS NULL
                                THEN
                                    l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                         l_care_plan_task_req.dt_next_task);
                                
                                    IF instr(l_elapsed_time, '-') = 0
                                    THEN
                                        l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                         pk_sysdomain.get_img(i_lang,
                                                                              'CARE_PLAN_TASK.FLG_STATUS',
                                                                              g_pending) || '|' || g_color_red ||
                                                         '||||';
                                    ELSE
                                        l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                         pk_sysdomain.get_img(i_lang,
                                                                              'CARE_PLAN_TASK.FLG_STATUS',
                                                                              g_pending) || '|' || g_color_green ||
                                                         '||||';
                                    
                                    END IF;
                                ELSE
                                    IF l_text IS NOT NULL
                                    THEN
                                        l_string_task := '0|T||' || l_text || '||||||';
                                    ELSE
                                        l_string_task := '0|I|||' || l_icon || '|||||';
                                    END IF;
                                END IF;
                            ELSE
                                l_string_task := pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            l_status_str,
                                                                            l_status_msg,
                                                                            l_status_icon,
                                                                            l_status_flg);
                            END IF;
                        ELSE
                            SELECT lte.flg_status_req, lte.dt_req
                              INTO l_flg_status, l_dt_req
                              FROM lab_tests_ea lte
                             WHERE lte.id_analysis_req = i_req
                               AND rownum = 1;
                        
                            IF l_flg_status = 'E'
                            THEN
                                -- em execu��o
                                l_string_task := '0|I|||' ||
                                                 pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ.FLG_STATUS', l_flg_status) ||
                                                 '|||||';
                            ELSIF l_flg_status IN ('F', 'L', 'C')
                            THEN
                                -- finalizado, lido, cancelado
                                OPEN c_care_plan_task_req;
                                FETCH c_care_plan_task_req
                                    INTO l_care_plan_task_req;
                                g_found := c_care_plan_task_req%FOUND;
                                CLOSE c_care_plan_task_req;
                            
                                IF g_found
                                   AND l_care_plan_task_req.id_req IS NULL
                                THEN
                                    l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                         l_care_plan_task_req.dt_next_task);
                                
                                    IF instr(l_elapsed_time, '-') = 0
                                    THEN
                                        l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                         pk_sysdomain.get_img(i_lang,
                                                                              'CARE_PLAN_TASK.FLG_STATUS',
                                                                              g_pending) || '|' || g_color_red ||
                                                         '||||';
                                    ELSE
                                        l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                         pk_sysdomain.get_img(i_lang,
                                                                              'CARE_PLAN_TASK.FLG_STATUS',
                                                                              g_pending) || '|' || g_color_green ||
                                                         '||||';
                                    
                                    END IF;
                                ELSE
                                    l_string_task := '0|I|||' || pk_sysdomain.get_img(i_lang,
                                                                                      'ANALYSIS_REQ.FLG_STATUS',
                                                                                      l_flg_status) || '|||||';
                                END IF;
                            ELSIF l_flg_status = 'R'
                            THEN
                                -- requisitado 
                                l_string_task := '0|D|' ||
                                                 pk_date_utils.to_char_insttimezone(i_prof,
                                                                                    l_dt_req,
                                                                                    'YYYYMMDDHH24MISS') || '||||||' ||
                                                 g_color_red || '|';
                            ELSE
                                l_string_task := '0|T||' || pk_message.get_message(i_lang, 'ICON_T056') || '|||||' ||
                                                 g_color_green || '|';
                            END IF;
                        END IF;
                    END IF;
                ELSIF i_flg_type IN ('EI', 'EO')
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        
                        END IF;
                    ELSE
                        SELECT eea.flg_status_det, eea.status_str, eea.status_msg, eea.status_icon, eea.status_flg
                          INTO l_flg_status, l_status_str, l_status_msg, l_status_icon, l_status_flg
                          FROM exams_ea eea
                         WHERE eea.id_exam_req = i_req;
                    
                        IF l_flg_status IN ('F', 'L', 'C')
                        THEN
                            -- finalizado, lido, cancelado
                            OPEN c_care_plan_task_req;
                            FETCH c_care_plan_task_req
                                INTO l_care_plan_task_req;
                            g_found := c_care_plan_task_req%FOUND;
                            CLOSE c_care_plan_task_req;
                        
                            IF g_found
                               AND l_care_plan_task_req.id_req IS NULL
                            THEN
                                l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                     l_care_plan_task_req.dt_next_task);
                            
                                IF instr(l_elapsed_time, '-') = 0
                                THEN
                                    l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_red || '||||';
                                ELSE
                                    l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_green || '||||';
                                
                                END IF;
                            ELSE
                                l_string_task := pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            l_status_str,
                                                                            l_status_msg,
                                                                            l_status_icon,
                                                                            l_status_flg);
                            END IF;
                        ELSE
                            l_string_task := pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        l_status_str,
                                                                        l_status_msg,
                                                                        l_status_icon,
                                                                        l_status_flg);
                        END IF;
                    END IF;
                ELSIF i_flg_type = 'ED'
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        
                        END IF;
                    ELSE
                        SELECT ntr.flg_status, ntr.status_str, ntr.status_msg, ntr.status_icon, ntr.status_flg
                          INTO l_flg_status, l_status_str, l_status_msg, l_status_icon, l_status_flg
                          FROM nurse_tea_req ntr
                         WHERE ntr.id_nurse_tea_req = i_req;
                    
                        IF l_flg_status IN ('F', 'C')
                        THEN
                            -- finalizado, cancelado
                            OPEN c_care_plan_task_req;
                            FETCH c_care_plan_task_req
                                INTO l_care_plan_task_req;
                            g_found := c_care_plan_task_req%FOUND;
                            CLOSE c_care_plan_task_req;
                        
                            IF g_found
                               AND l_care_plan_task_req.id_req IS NULL
                            THEN
                                l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                     l_care_plan_task_req.dt_next_task);
                            
                                IF instr(l_elapsed_time, '-') = 0
                                THEN
                                    l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_red || '||||';
                                ELSE
                                    l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_green || '||||';
                                
                                END IF;
                            ELSE
                                l_string_task := pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            l_status_str,
                                                                            l_status_msg,
                                                                            l_status_icon,
                                                                            l_status_flg);
                            END IF;
                        ELSE
                            l_string_task := pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        l_status_str,
                                                                        l_status_msg,
                                                                        l_status_icon,
                                                                        l_status_flg);
                        END IF;
                    END IF;
                ELSIF i_flg_type = 'OP'
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        
                        END IF;
                    ELSE
                        SELECT pea.flg_status_det, pea.status_str, pea.status_msg, pea.status_icon, pea.status_flg
                          INTO l_flg_status, l_status_str, l_status_msg, l_status_icon, l_status_flg
                          FROM procedures_ea pea
                         WHERE pea.id_interv_presc_det = i_req;
                    
                        IF l_flg_status IN ('F', 'C')
                        THEN
                            -- finalizado, cancelado
                            OPEN c_care_plan_task_req;
                            FETCH c_care_plan_task_req
                                INTO l_care_plan_task_req;
                            g_found := c_care_plan_task_req%FOUND;
                            CLOSE c_care_plan_task_req;
                        
                            IF g_found
                               AND l_care_plan_task_req.id_req IS NULL
                            THEN
                                l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                     l_care_plan_task_req.dt_next_task);
                            
                                IF instr(l_elapsed_time, '-') = 0
                                THEN
                                    l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_red || '||||';
                                ELSE
                                    l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_green || '||||';
                                
                                END IF;
                            ELSE
                                l_string_task := pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            l_status_str,
                                                                            l_status_msg,
                                                                            l_status_icon,
                                                                            l_status_flg);
                            END IF;
                        ELSE
                            l_string_task := pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        l_status_str,
                                                                        l_status_msg,
                                                                        l_status_icon,
                                                                        l_status_flg);
                        END IF;
                    END IF;
                ELSIF i_flg_type IN ('M', 'ME', 'ML', 'MP', 'MF')
                THEN
                    IF i_req IS NULL
                    THEN
                        l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                        l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                    
                        IF instr(l_elapsed_time, '-') = 0
                        THEN
                            l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_red || '||||';
                        ELSE
                            l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                             pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                             g_color_green || '||||';
                        
                        END IF;
                    ELSE
                        IF pk_api_pfh_in.is_active_presc(i_lang, i_prof, i_req) = 'N'
                        THEN
                            -- impresso, cancelado
                            OPEN c_care_plan_task_req;
                            FETCH c_care_plan_task_req
                                INTO l_care_plan_task_req;
                            g_found := c_care_plan_task_req%FOUND;
                            CLOSE c_care_plan_task_req;
                        
                            IF g_found
                               AND l_care_plan_task_req.id_req IS NULL
                            THEN
                                l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                     l_care_plan_task_req.dt_next_task);
                            
                                IF instr(l_elapsed_time, '-') = 0
                                THEN
                                    l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_red || '||||';
                                ELSE
                                    l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                     pk_sysdomain.get_img(i_lang,
                                                                          'CARE_PLAN_TASK.FLG_STATUS',
                                                                          g_pending) || '|' || g_color_green || '||||';
                                
                                END IF;
                            ELSE
                                g_error       := 'CALL PK_API_PFH_IN.GET_PRESC_STATUS_ICON i_flg_type=' || i_flg_type;
                                l_string_task := pk_api_pfh_in.get_presc_status_icon(i_lang     => i_lang,
                                                                                     i_prof     => i_prof,
                                                                                     i_id_presc => i_req);
                            END IF;
                        ELSE
                            g_error       := 'CALL PK_API_PFH_IN.GET_PRESC_STATUS_ICON i_flg_type=' || i_flg_type;
                            l_string_task := pk_api_pfh_in.get_presc_status_icon(i_lang     => i_lang,
                                                                                 i_prof     => i_prof,
                                                                                 i_id_presc => i_req);
                        END IF;
                    END IF;
                ELSIF i_flg_type = 'DP'
                THEN
                    SELECT edr.flg_status, edr.dt_inicial, edr.dt_end, edr.id_episode
                      INTO l_flg_status, l_dt_begin, l_dt_end, l_episode
                      FROM epis_diet_req edr
                     WHERE edr.id_epis_diet_req = i_req;
                
                    IF l_flg_status NOT IN (pk_diet.g_flg_diet_status_s,
                                            pk_diet.g_flg_diet_status_c,
                                            pk_diet.g_flg_diet_status_x,
                                            pk_diet.g_flg_diet_status_t)
                    THEN
                        IF pk_date_utils.compare_dates_tsz(i_prof, l_dt_begin, g_sysdate_tstz) = pk_diet.g_flg_date_g
                        THEN
                            l_flg_status := pk_diet.g_flg_diet_status_h;
                        ELSE
                            IF pk_date_utils.compare_dates_tsz(i_prof, l_dt_end, g_sysdate_tstz) = pk_diet.g_flg_date_l
                            THEN
                                l_flg_status := pk_diet.g_flg_diet_status_f;
                            ELSE
                                l_flg_status := pk_diet.g_flg_diet_status_a;
                            END IF;
                        END IF;
                    END IF;
                
                    IF l_flg_status IN ('F', 'X', 'C')
                    THEN
                        -- finalizado, expirado, cancelado
                        OPEN c_care_plan_task_req;
                        FETCH c_care_plan_task_req
                            INTO l_care_plan_task_req;
                        g_found := c_care_plan_task_req%FOUND;
                        CLOSE c_care_plan_task_req;
                    
                        IF g_found
                           AND l_care_plan_task_req.id_req IS NULL
                        THEN
                            l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang,
                                                                                 l_care_plan_task_req.dt_next_task);
                        
                            IF instr(l_elapsed_time, '-') = 0
                            THEN
                                l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                                 pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                                 g_color_red || '||||';
                            ELSE
                                l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                                 pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', g_pending) || '|' ||
                                                 g_color_green || '||||';
                            
                            END IF;
                        ELSE
                            l_string_task := pk_diet.get_diet_status_str(i_lang,
                                                                         i_prof,
                                                                         l_flg_status,
                                                                         l_dt_begin,
                                                                         l_dt_end,
                                                                         g_sysdate_tstz);
                        END IF;
                    ELSE
                        l_string_task := pk_diet.get_diet_status_str(i_lang,
                                                                     i_prof,
                                                                     l_flg_status,
                                                                     l_dt_begin,
                                                                     l_dt_end,
                                                                     g_sysdate_tstz);
                    END IF;
                END IF;
            ELSE
                l_string_task := '0|I|||' ||
                                 pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK.FLG_STATUS', i_task_flg_status) ||
                                 '|||||';
            END IF;
        ELSE
            IF i_req_flg_status = g_pending
            THEN
                IF i_dt_begin IS NULL
                THEN
                
                    l_string_task := '0|I|||' ||
                                     pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK_REQ.FLG_STATUS', g_pending) || '|' ||
                                     g_color_green || '||||';
                ELSE
                    l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
                    l_elapsed_time := pk_date_utils.get_elapsed_time_tsz(i_lang, l_dt_begin);
                
                    IF instr(l_elapsed_time, '-') = 0
                    THEN
                        l_string_task := '0|TI||' || lower(l_elapsed_time) || '|' ||
                                         pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK_REQ.FLG_STATUS', g_pending) || '|' ||
                                         g_color_red || '||||';
                    ELSE
                        l_string_task := '0|TI||' || lower(REPLACE(l_elapsed_time, '-')) || '|' ||
                                         pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK_REQ.FLG_STATUS', g_pending) || '|' ||
                                         g_color_green || '||||';
                    END IF;
                END IF;
            ELSIF i_req_flg_status = g_ordered
            THEN
                IF i_flg_type IN ('PS', 'PZ', 'PF')
                THEN
                    SELECT cr.status_str, cr.status_msg, cr.status_icon, cr.status_flg
                      INTO l_status_str, l_status_msg, l_status_icon, l_status_flg
                      FROM consult_req cr
                     WHERE cr.id_consult_req = i_req;
                
                    l_string_task := pk_utils.get_status_string(i_lang,
                                                                i_prof,
                                                                l_status_str,
                                                                l_status_msg,
                                                                l_status_icon,
                                                                l_status_flg);
                ELSIF i_flg_type = 'O'
                THEN
                    SELECT o.status_str, o.status_msg, o.status_icon, o.status_flg
                      INTO l_status_str, l_status_msg, l_status_icon, l_status_flg
                      FROM opinion o
                     WHERE o.id_opinion = i_req;
                
                    l_string_task := pk_utils.get_status_string(i_lang,
                                                                i_prof,
                                                                l_status_str,
                                                                l_status_msg,
                                                                l_status_icon,
                                                                l_status_flg);
                ELSIF i_flg_type IN ('A', 'AG')
                THEN
                    IF i_flg_type = 'A'
                    THEN
                        SELECT flg_status_det, status_str, status_msg, status_icon, status_flg, text, icon
                          INTO l_flg_status, l_status_str, l_status_msg, l_status_icon, l_status_flg, l_text, l_icon
                          FROM (SELECT row_number() over(PARTITION BY lte.id_analysis_req ORDER BY arp.dt_analysis_result_par_tstz DESC) rn,
                                       lte.flg_status_det,
                                       lte.status_str,
                                       lte.status_msg,
                                       lte.status_icon,
                                       lte.status_flg,
                                       nvl(TRIM(arp.desc_analysis_result),
                                           (arp.comparator || arp.analysis_result_value_1 || arp.separator ||
                                           arp.analysis_result_value_2)) ||
                                       decode(arp.id_unit_measure,
                                              NULL,
                                              arp.desc_unit_measure,
                                              ' ' || pk_translation.get_translation(i_lang,
                                                                                    'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                    arp.id_unit_measure)) text,
                                       decode(pk_utils.is_number(arp.desc_analysis_result),
                                              'N',
                                              decode(to_char(arp.desc_analysis_result),
                                                     ad.value,
                                                     ad.icon,
                                                     'AnalysisResultIcon'),
                                              NULL) icon
                                  FROM lab_tests_ea lte, analysis_result_par arp, analysis_desc ad
                                 WHERE lte.id_analysis_req = i_req
                                   AND lte.id_analysis_result = arp.id_analysis_result(+)
                                   AND arp.id_analysis_parameter = ad.id_analysis_parameter(+)
                                   AND to_char(arp.desc_analysis_result) = ad.value(+))
                         WHERE rn = 1;
                    
                        IF l_flg_status = 'F'
                        THEN
                            -- finalizado 
                            IF l_text IS NOT NULL
                            THEN
                                l_string_task := '0|T||' || l_text || '||' || g_color_gray || '|PRNStyle|||';
                            ELSE
                                l_string_task := '0|I|||' || l_icon || '|||||';
                            END IF;
                        ELSE
                            l_string_task := pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        l_status_str,
                                                                        l_status_msg,
                                                                        l_status_icon,
                                                                        l_status_flg);
                        END IF;
                    ELSE
                        SELECT lte.flg_status_req, lte.dt_req
                          INTO l_flg_status, l_dt_req
                          FROM lab_tests_ea lte
                         WHERE lte.id_analysis_req = i_req
                           AND rownum = 1;
                    
                        IF l_flg_status IN ('E', 'F', 'L', 'C')
                        THEN
                            -- em execu��o, finalizado, lido, cancelado
                            l_string_task := '0|I|||' ||
                                             pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ.FLG_STATUS', l_flg_status) ||
                                             '|||||';
                        ELSIF l_flg_status = 'R'
                        THEN
                            -- requisitado 
                            l_string_task := '0|D|' ||
                                             pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS') ||
                                             '|||' || g_color_red || '||||';
                        ELSE
                            l_string_task := '0|T||' || pk_message.get_message(i_lang, 'ICON_T056') || '|' ||
                                             g_color_green || '|||||';
                        END IF;
                    END IF;
                ELSIF i_flg_type IN ('EI', 'EO')
                THEN
                    SELECT eea.status_str, eea.status_msg, eea.status_icon, eea.status_flg
                      INTO l_status_str, l_status_msg, l_status_icon, l_status_flg
                      FROM exams_ea eea
                     WHERE eea.id_exam_req = i_req;
                
                    l_string_task := pk_utils.get_status_string(i_lang,
                                                                i_prof,
                                                                l_status_str,
                                                                l_status_msg,
                                                                l_status_icon,
                                                                l_status_flg);
                ELSIF i_flg_type = 'ED'
                THEN
                    SELECT ntr.status_str, ntr.status_msg, ntr.status_icon, ntr.status_flg
                      INTO l_status_str, l_status_msg, l_status_icon, l_status_flg
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_nurse_tea_req = i_req;
                
                    l_string_task := pk_utils.get_status_string(i_lang,
                                                                i_prof,
                                                                l_status_str,
                                                                l_status_msg,
                                                                l_status_icon,
                                                                l_status_flg);
                ELSIF i_flg_type = 'OP'
                THEN
                    SELECT pea.status_str, pea.status_msg, pea.status_icon, pea.status_flg
                      INTO l_status_str, l_status_msg, l_status_icon, l_status_flg
                      FROM procedures_ea pea
                     WHERE pea.id_interv_presc_det = i_req;
                
                    l_string_task := pk_utils.get_status_string(i_lang,
                                                                i_prof,
                                                                l_status_str,
                                                                l_status_msg,
                                                                l_status_icon,
                                                                l_status_flg);
                ELSIF i_flg_type IN ('M', 'ME', 'ML', 'MP', 'MF')
                THEN
                    g_error       := 'CALL PK_API_PFH_IN.GET_PRESC_STATUS_ICON i_flg_type=' || i_flg_type;
                    l_string_task := pk_api_pfh_in.get_presc_status_icon(i_lang     => i_lang,
                                                                         i_prof     => i_prof,
                                                                         i_id_presc => i_req);
                
                ELSIF i_flg_type = 'DP'
                THEN
                    SELECT edr.flg_status, edr.dt_inicial, edr.dt_end, edr.id_episode
                      INTO l_flg_status, l_dt_begin, l_dt_end, l_episode
                      FROM epis_diet_req edr
                     WHERE edr.id_epis_diet_req = i_req;
                
                    IF l_flg_status NOT IN (pk_diet.g_flg_diet_status_s,
                                            pk_diet.g_flg_diet_status_c,
                                            pk_diet.g_flg_diet_status_x,
                                            pk_diet.g_flg_diet_status_t)
                    THEN
                        IF pk_date_utils.compare_dates_tsz(i_prof, l_dt_begin, g_sysdate_tstz) = pk_diet.g_flg_date_g
                        THEN
                            l_flg_status := pk_diet.g_flg_diet_status_h;
                        ELSE
                            IF pk_date_utils.compare_dates_tsz(i_prof, l_dt_end, g_sysdate_tstz) = pk_diet.g_flg_date_l
                            THEN
                                l_flg_status := pk_diet.g_flg_diet_status_f;
                            ELSE
                                l_flg_status := pk_diet.g_flg_diet_status_a;
                            END IF;
                        END IF;
                    END IF;
                    g_error       := 'Call pk_diet.get_diet_status_str i_flg_type=' || i_flg_type;
                    l_string_task := pk_diet.get_diet_status_str(i_lang,
                                                                 i_prof,
                                                                 l_flg_status,
                                                                 l_dt_begin,
                                                                 l_dt_end,
                                                                 g_sysdate_tstz);
                END IF;
            ELSE
                l_string_task := '0|I|||' ||
                                 pk_sysdomain.get_img(i_lang, 'CARE_PLAN_TASK_REQ.FLG_STATUS', i_req_flg_status) ||
                                 '|||||';
            END IF;
        END IF;
    
        RETURN l_string_task;
    
    END get_string_task;

    FUNCTION get_dt_begin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_flg_status IN VARCHAR2,
        i_req_flg_status  IN VARCHAR2,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req          IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_dt_begin VARCHAR2(100);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_task_flg_status = g_pending
        THEN
            IF i_req_flg_status = g_pending
            THEN
                IF i_dt_begin IS NULL
                THEN
                    l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6),
                                          ' ',
                                          '-') || ';' || pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
                ELSIF instr(pk_date_utils.diff_timestamp(i_dt_begin, g_sysdate_tstz), '-') = 0
                THEN
                    l_dt_begin := pk_message.get_message(i_lang, 'COMMON_M062') || ' ' ||
                                  lower(REPLACE(pk_date_utils.get_elapsed_time_tsz(i_lang, i_dt_begin), '-')) || ';' ||
                                  pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof);
                ELSE
                    l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6),
                                          ' ',
                                          '-') || ';' || pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
                END IF;
            ELSE
                l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang,
                                                                         i_prof,
                                                                         nvl(i_dt_begin, g_sysdate_tstz)),
                                             1,
                                             6),
                                      ' ',
                                      '-') || ';' ||
                              pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_begin, g_sysdate_tstz), i_prof);
            END IF;
        
        ELSIF i_task_flg_status = g_inprogress
        THEN
            IF i_req_flg_status = g_pending
            THEN
                IF i_dt_begin IS NULL
                THEN
                    l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6),
                                          ' ',
                                          '-') || ';' || pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
                ELSIF instr(pk_date_utils.diff_timestamp(i_dt_begin, g_sysdate_tstz), '-') = 0
                THEN
                    l_dt_begin := pk_message.get_message(i_lang, 'COMMON_M062') || ' ' ||
                                  lower(REPLACE(pk_date_utils.get_elapsed_time_tsz(i_lang, i_dt_begin), '-')) || ';' ||
                                  pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof);
                ELSE
                    l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, g_sysdate_tstz), 1, 6),
                                          ' ',
                                          '-') || ';' || pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
                END IF;
            ELSIF i_req_flg_status = g_ordered
            THEN
                l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, nvl(i_dt_req, i_dt_begin)),
                                             1,
                                             6),
                                      ' ',
                                      '-') || ';' ||
                              pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_req, i_dt_begin), i_prof);
            
            ELSE
                l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang,
                                                                         i_prof,
                                                                         nvl(i_dt_begin, g_sysdate_tstz)),
                                             1,
                                             6),
                                      ' ',
                                      '-') || ';' ||
                              pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_begin, g_sysdate_tstz), i_prof);
            END IF;
        ELSE
            IF i_req_flg_status = g_ordered
            THEN
                l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang, i_prof, nvl(i_dt_req, i_dt_begin)),
                                             1,
                                             6),
                                      ' ',
                                      '-') || ';' ||
                              pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_req, i_dt_begin), i_prof);
            ELSE
                l_dt_begin := REPLACE(substr(pk_date_utils.get_month_day(i_lang,
                                                                         i_prof,
                                                                         nvl(i_dt_begin, g_sysdate_tstz)),
                                             1,
                                             6),
                                      ' ',
                                      '-') || ';' ||
                              pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_begin, g_sysdate_tstz), i_prof);
            END IF;
        END IF;
    
        RETURN l_dt_begin;
    END get_dt_begin;

    FUNCTION get_desc_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_item      IN care_plan_task.id_item%TYPE,
        i_task_type IN care_plan_task.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc     VARCHAR2(4000);
        l_flg_type VARCHAR2(2);
    
        l_id_analysis    analysis.id_analysis%TYPE;
        l_id_sample_type sample_type.id_sample_type%TYPE;
    
        l_id_presc NUMBER;
    BEGIN
    
        l_flg_type := pk_task_type.get_task_type_flg(i_lang, i_task_type);
    
        IF l_flg_type = g_followup_appointments
        THEN
            l_desc := pk_message.get_message(i_lang, 'CARE_PLANS_T104');
        
        ELSIF l_flg_type = g_analysis
        THEN
        
            -- get id_analysis token where i_item = '<id_analysis>|<id_sample_type>'
            l_id_analysis    := substr(i_item, 1, instr(i_item, '|') - 1);
            l_id_sample_type := substr(i_item, instr(i_item, '|') + 1);
        
            l_desc := pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                i_prof,
                                                                'A',
                                                                pk_task_type.get_task_type_code_translation(i_lang,
                                                                                                            i_task_type) ||
                                                                l_id_analysis,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || l_id_sample_type,
                                                                NULL);
        
        ELSIF l_flg_type = g_group_analysis
        THEN
        
            l_desc := pk_lab_tests_api_db.get_alias_translation(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_flg_type         => 'G',
                                                                i_code_translation => pk_task_type.get_task_type_code_translation(i_lang,
                                                                                                                                  i_task_type) ||
                                                                                      i_item,
                                                                i_dep_clin_serv    => NULL);
        
        ELSIF l_flg_type IN (g_imaging_exams, g_other_exams)
        THEN
            l_desc := pk_exams_api_db.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_task_type.get_task_type_code_translation(i_lang,
                                                                                                        i_task_type) ||
                                                            i_item,
                                                            NULL);
        ELSIF l_flg_type = g_procedures
        THEN
            l_desc := pk_procedures_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 pk_task_type.get_task_type_code_translation(i_lang,
                                                                                                             i_task_type) ||
                                                                 i_item,
                                                                 NULL);
        ELSIF l_flg_type IN (g_medication, g_ext_medication, g_int_medication, g_ivfluids_medication)
        THEN
            -- retrieve id_presc (care_plan_task_req.id_req in care plans model)
            /* l_id_presc will be sent as null. Therefore, function from medication will always return
            the main descritpion and not the alias.*/
        
            l_id_presc := NULL;
            l_desc     := pk_api_pfh_in.get_product_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_product => i_item,
                                                         i_id_presc   => l_id_presc);
        
        ELSIF l_flg_type = g_diets
        THEN
            SELECT DISTINCT dpi.desc_diet
              INTO l_desc
              FROM diet_prof_instit dpi
             WHERE dpi.id_diet_prof_instit = i_item;
        ELSE
            l_desc := pk_translation.get_translation(i_lang,
                                                     pk_task_type.get_task_type_code_translation(i_lang, i_task_type) ||
                                                     i_item);
        END IF;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_translation;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_yes := 'Y';
    g_no  := 'N';

    g_relevant_disease := 'R';
    g_diagnosis        := 'D';
    g_allergy          := 'A';

    g_appointments          := 'PS';
    g_spec_appointments     := 'PZ';
    g_followup_appointments := 'PF';
    g_opinions              := 'O';
    g_analysis              := 'A';
    g_group_analysis        := 'AG';
    g_exams                 := 'E';
    g_imaging_exams         := 'EI';
    g_other_exams           := 'EO';
    g_procedures            := 'OP';
    g_patient_education     := 'ED';
    g_medication            := 'M';
    g_ext_medication        := 'ME';
    g_int_medication        := 'ML';
    g_pharm_medication      := 'MF';
    g_ivfluids_medication   := 'MP';
    g_diets                 := 'DP';

    g_doctor       := 'D';
    g_nurse        := 'N';
    g_social       := 'S';
    g_case_manager := 'Q';

    g_active   := 'A';
    g_inactive := 'I';

    g_pending     := 'P';
    g_ordered     := 'R';
    g_inprogress  := 'E';
    g_suspended   := 'S';
    g_finished    := 'F';
    g_interrupted := 'I';
    g_canceled    := 'C';

    g_day   := 1039;
    g_week  := 10375;
    g_month := 1127;
    g_year  := 10373;

END;
/
