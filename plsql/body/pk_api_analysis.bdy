/*-- Last Change Revision: $Rev: 1987715 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-04-30 18:08:02 +0100 (sex, 30 abr 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_analysis IS

    FUNCTION create_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det        IN table_number,
        i_analysis_req_det_parent IN table_number,
        i_harvest                 IN harvest.id_harvest%TYPE,
        i_analysis_content        IN table_varchar,
        i_analysis_group_content  IN table_table_varchar, --10
        i_flg_type                IN table_varchar,
        i_dt_req                  IN table_varchar,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar, --15
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --20
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar, --25
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number, --30
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar, --35
        i_lab_req                 IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number, --40
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_varchar,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar, --45
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number, --50
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        o_analysis_req_array      OUT NOCOPY table_number,
        o_analysis_req_det_array  OUT NOCOPY table_number,
        o_analysis_req_par_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis          table_number := table_number();
        l_analysis_group    table_table_varchar := table_table_varchar();
        l_specimen          table_number := table_number();
        l_specimen_group    table_number := table_number();
        l_clinical_question table_table_number := table_table_number();
        l_response          table_table_varchar := table_table_varchar();
    
        l_flg_show  VARCHAR2(10);
        l_msg_title VARCHAR2(10);
        l_msg_req   VARCHAR2(10);
        l_button    VARCHAR2(10);
    
    BEGIN
    
        FOR i IN 1 .. i_analysis_content.count
        LOOP
            IF i_flg_type(i) = 'A'
            THEN
                l_analysis.extend;
                l_specimen.extend;
            
                IF NOT pk_api_analysis.get_lab_test_by_id_content(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_content     => i_analysis_content(i),
                                                                  i_flg_type    => i_flg_type(i),
                                                                  o_analysis    => l_analysis(i),
                                                                  o_sample_type => l_specimen(i),
                                                                  o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                l_analysis.extend;
                l_specimen_group.extend;
            
                IF NOT pk_api_analysis.get_lab_test_by_id_content(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_content     => i_analysis_content(i),
                                                                  i_flg_type    => i_flg_type(i),
                                                                  o_analysis    => l_analysis(i),
                                                                  o_sample_type => l_specimen_group(i),
                                                                  o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                FOR j IN 1 .. i_analysis_group_content.count
                LOOP
                    l_analysis_group.extend;
                    l_specimen_group.extend;
                
                    IF NOT pk_api_analysis.get_lab_test_by_id_content(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_content     => i_analysis_group_content(i) (j),
                                                                      i_flg_type    => 'A',
                                                                      o_analysis    => l_analysis_group(i)
                                                                                       (l_analysis_group.count),
                                                                      o_sample_type => l_specimen_group(i),
                                                                      o_error       => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                END LOOP;
            END IF;
        
            l_clinical_question.extend;
            l_clinical_question(i) := table_number();
        
            l_response.extend;
            l_response(i) := table_varchar();
        
            FOR j IN 1 .. i_clinical_question(i).count
            LOOP
                IF i_clinical_question(i) (j) IS NOT NULL
                THEN
                    l_clinical_question(i).extend();
                    l_response(i).extend();
                
                    g_error := 'CALL GET_LAB_TEST_CQ_BY_ID_CONTENT - CQ';
                    IF NOT pk_api_analysis.get_lab_test_cq_by_id_content(i_lang     => i_lang,
                                                                         i_prof     => i_prof,
                                                                         i_content  => i_clinical_question(i) (j),
                                                                         i_flg_type => 'CQ',
                                                                         o_id       => l_clinical_question(i)
                                                                                       (l_clinical_question.count),
                                                                         o_error    => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF i_response(i) (j) IS NOT NULL
                    THEN
                        g_error := 'CALL GET_LAB_TEST_CQ_BY_ID_CONTENT - R';
                        IF NOT
                            pk_api_analysis.get_lab_test_cq_by_id_content(i_lang     => i_lang,
                                                                          i_prof     => i_prof,
                                                                          i_content  => i_response(i) (j),
                                                                          i_flg_type => 'R',
                                                                          o_id       => l_response(i) (l_response.count),
                                                                          o_error    => o_error)
                        THEN
                            RAISE g_other_exception;
                        ELSE
                            l_response(i)(j) := i_response(i) (j);
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
    
        g_error := 'CALL CREATE_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_patient                 => i_patient,
                                                         i_episode                 => i_episode,
                                                         i_analysis_req            => i_analysis_req,
                                                         i_analysis_req_det        => i_analysis_req_det,
                                                         i_analysis_req_det_parent => i_analysis_req_det_parent,
                                                         i_harvest                 => i_harvest,
                                                         i_analysis                => l_analysis,
                                                         i_analysis_group          => l_analysis_group,
                                                         i_flg_type                => i_flg_type,
                                                         i_dt_req                  => i_dt_req,
                                                         i_flg_time                => i_flg_time,
                                                         i_dt_begin                => i_dt_begin,
                                                         i_dt_begin_limit          => i_dt_begin_limit,
                                                         i_episode_destination     => i_episode_destination,
                                                         i_order_recurrence        => i_order_recurrence,
                                                         i_priority                => i_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_notes_prn               => i_notes_prn,
                                                         i_specimen                => l_specimen,
                                                         i_body_location           => i_body_location,
                                                         i_laterality              => i_laterality,
                                                         i_collection_room         => i_collection_room,
                                                         i_notes                   => i_notes,
                                                         i_notes_scheduler         => i_notes_scheduler,
                                                         i_notes_technician        => i_notes_technician,
                                                         i_notes_patient           => i_notes_patient,
                                                         i_diagnosis_notes         => NULL,
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
                                                         i_clinical_question       => l_clinical_question,
                                                         i_response                => l_response,
                                                         i_clinical_question_notes => i_clinical_question_notes,
                                                         i_clinical_decision_rule  => i_clinical_decision_rule,
                                                         i_flg_origin_req          => i_flg_origin_req,
                                                         i_task_dependency         => i_task_dependency,
                                                         i_flg_task_depending      => i_flg_task_depending,
                                                         i_episode_followup_app    => i_episode_followup_app,
                                                         i_schedule_followup_app   => i_schedule_followup_app,
                                                         i_event_followup_app      => i_event_followup_app,
                                                         i_test                    => pk_lab_tests_constant.g_no,
                                                         o_flg_show                => l_flg_show,
                                                         o_msg_title               => l_msg_title,
                                                         o_msg_req                 => l_msg_req,
                                                         o_button                  => l_button,
                                                         o_analysis_req_array      => o_analysis_req_array,
                                                         o_analysis_req_det_array  => o_analysis_req_det_array,
                                                         o_analysis_req_par_array  => o_analysis_req_par_array,
                                                         o_error                   => o_error)
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
                                              'CREATE_LAB_TEST_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_order;

    FUNCTION create_lab_test_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_exam.id_schedule%TYPE,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN VARCHAR2,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CREATE_LAB_TEST_VISIT';
        IF NOT pk_lab_tests_api_db.create_lab_test_visit(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_patient          => i_patient,
                                                         i_episode          => i_episode,
                                                         i_schedule         => i_schedule,
                                                         i_analysis_req_det => i_analysis_req_det,
                                                         i_dt_begin         => i_dt_begin,
                                                         i_transaction_id   => i_transaction_id,
                                                         o_episode          => o_episode,
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
                                              'CREATE_EXAM_VISIT',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_visit;

    FUNCTION create_lab_test_parameter
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_desc_parameter     IN table_varchar,
        i_flg_type           IN table_varchar,
        i_flg_fill_type      IN table_varchar,
        i_unit_measure       IN table_number,
        i_min_val            IN table_number,
        i_max_val            IN table_number,
        o_analysis_parameter OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_parameter analysis_parameter.id_analysis_parameter%TYPE;
    
        l_rank analysis_param.rank%TYPE;
    
        l_analysis_software table_varchar2;
        l_software_exists   NUMBER;
    
    BEGIN
    
        o_analysis_parameter := table_number();
    
        l_analysis_software := pk_utils.str_split(pk_sysconfig.get_config('LAB_TESTS_PARAMETER_SOFTWARE_LIST', i_prof),
                                                  '|');
    
        FOR i IN 1 .. i_desc_parameter.count
        LOOP
            g_error := 'GET SEQ_ANALYSIS_PARAMETER.NEXTVAL';
            SELECT seq_analysis_parameter.nextval
              INTO l_analysis_parameter
              FROM dual;
        
            g_error := 'INSERT INTO ANALYSIS_PARAMETER';
            INSERT INTO analysis_parameter
                (id_analysis_parameter, flg_available, rank, flg_type)
            VALUES
                (l_analysis_parameter, pk_lab_tests_constant.g_available, 0, i_flg_type(i));
        
            g_error := 'UPDATE TRANSLATION';
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                   l_analysis_parameter,
                                                   i_desc_trans => i_desc_parameter(i));
        
            o_analysis_parameter.extend;
            o_analysis_parameter(o_analysis_parameter.count) := l_analysis_parameter;
        
            FOR j IN 1 .. l_analysis_software.count
            LOOP
                BEGIN
                    SELECT 1
                      INTO l_software_exists
                      FROM software_institution si
                     WHERE si.id_software = l_analysis_software(j)
                       AND si.id_institution = i_prof.institution;
                
                    BEGIN
                        SELECT MAX(ap.rank)
                          INTO l_rank
                          FROM analysis_param ap
                         WHERE ap.id_analysis = i_analysis
                           AND ap.id_sample_type = i_sample_type
                           AND ap.id_software = l_analysis_software(j)
                           AND ap.id_institution = i_prof.institution;
                    
                        IF l_rank IS NULL
                        THEN
                            l_rank := 0;
                        END IF;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_rank := 0;
                    END;
                
                    g_error := 'INSERT INTO ANALYSIS_PARAM';
                    INSERT INTO analysis_param
                        (id_analysis_param,
                         id_analysis,
                         id_sample_type,
                         id_analysis_parameter,
                         flg_fill_type,
                         flg_available,
                         id_institution,
                         id_software,
                         rank)
                    VALUES
                        (seq_analysis_param.nextval,
                         i_analysis,
                         i_sample_type,
                         l_analysis_parameter,
                         nvl(i_flg_fill_type(i), pk_lab_tests_constant.g_analysis_result_text),
                         pk_lab_tests_constant.g_available,
                         i_prof.institution,
                         l_analysis_software(j),
                         l_rank + 10);
                
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END LOOP;
        
            IF i_unit_measure(i) IS NOT NULL
            THEN
                INSERT INTO lab_tests_par_uni_mea
                    (id_lab_tests_par_uni_mea,
                     id_analysis_parameter,
                     id_unit_measure,
                     min_measure_interval,
                     max_measure_interval)
                VALUES
                    (seq_lab_tests_par_uni_mea.nextval,
                     l_analysis_parameter,
                     i_unit_measure(i),
                     i_min_val(i),
                     i_max_val(i));
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
                                              'CREATE_LAB_TEST_PARAMETER',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_parameter;

    FUNCTION set_lab_test_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN VARCHAR2,
        i_notes_scheduler  IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_DATE';
        IF NOT pk_lab_tests_api_db.set_lab_test_date(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_analysis_req_det => i_analysis_req_det,
                                                     i_dt_begin         => i_dt_begin,
                                                     i_notes_scheduler  => i_notes_scheduler,
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
                                              'SET_LAB_TEST_DATE',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_date;

    FUNCTION set_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_HARVEST';
        IF NOT pk_lab_tests_api_db.set_harvest(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_analysis_req_det => i_analysis_req_det,
                                               i_harvest          => i_harvest,
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
                                              'SET_HARVEST',
                                              o_error);
            RETURN FALSE;
    END set_harvest;

    FUNCTION set_harvest_edit
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN table_number, --5
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number,
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number, --10
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number, --15
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_HARVEST_EDIT';
        IF NOT pk_lab_tests_api_db.set_harvest_edit(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    i_harvest                   => i_harvest,
                                                    i_analysis_harvest          => i_analysis_harvest,
                                                    i_body_location             => i_body_location,
                                                    i_laterality                => i_laterality,
                                                    i_collection_method         => i_collection_method,
                                                    i_specimen_condition        => i_specimen_condition,
                                                    i_collection_room           => i_collection_room,
                                                    i_lab                       => i_lab,
                                                    i_exec_institution          => i_exec_institution,
                                                    i_sample_recipient          => i_sample_recipient,
                                                    i_num_recipient             => i_num_recipient,
                                                    i_collection_time           => i_collection_time,
                                                    i_collection_amount         => i_collection_amount,
                                                    i_collection_transportation => i_collection_transportation,
                                                    i_notes                     => i_notes,
                                                    i_flg_orig_harvest          => pk_lab_tests_constant.g_harvest_orig_harvest_i,
                                                    o_error                     => o_error)
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
                                              'SET_HARVEST_EDIT',
                                              o_error);
            RETURN FALSE;
    END set_harvest_edit;

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_req_det          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE,
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN VARCHAR2,
        o_harvest                   OUT harvest.id_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_harvest       analysis_harvest.id_analysis_harvest%TYPE;
        l_analysis_harvest_array table_table_number := table_table_number();
    
    BEGIN
    
        l_analysis_harvest_array.extend(i_harvest.count);
    
        FOR i IN 1 .. i_harvest.count
        LOOP
            l_analysis_harvest_array(i) := table_number();
        
            FOR j IN 1 .. i_analysis_req_det(i).count
            LOOP
                SELECT ah.id_analysis_harvest
                  INTO l_analysis_harvest
                  FROM analysis_harvest ah
                 WHERE ah.id_harvest = i_harvest(i)
                   AND ah.id_analysis_req_det = i_analysis_req_det(i) (j);
            
                l_analysis_harvest_array(i).extend();
            
                l_analysis_harvest_array(i)(j) := l_analysis_harvest;
            END LOOP;
        END LOOP;
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_HARVEST_COMBINE';
        IF NOT pk_lab_tests_api_db.set_harvest_combine(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_patient                   => i_patient,
                                                       i_episode                   => i_episode,
                                                       i_harvest                   => i_harvest,
                                                       i_analysis_harvest          => l_analysis_harvest_array,
                                                       i_collection_method         => i_collection_method,
                                                       i_specimen_condition        => i_specimen_condition,
                                                       i_collection_room           => i_collection_room,
                                                       i_lab                       => i_lab,
                                                       i_exec_institution          => i_exec_institution,
                                                       i_sample_recipient          => i_sample_recipient,
                                                       i_num_recipient             => i_num_recipient,
                                                       i_collection_time           => i_collection_time,
                                                       i_collection_amount         => i_collection_amount,
                                                       i_collection_transportation => i_collection_transportation,
                                                       i_notes                     => i_notes,
                                                       i_flg_orig_harvest          => pk_lab_tests_constant.g_harvest_orig_harvest_i,
                                                       o_harvest                   => o_harvest,
                                                       o_error                     => o_error)
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
                                              'SET_HARVEST_COMBINE',
                                              o_error);
            RETURN FALSE;
    END set_harvest_combine;

    FUNCTION set_harvest_repeat
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_visit                     IN visit.id_visit%TYPE,
        i_episode                   IN episode.id_episode%TYPE, --5
        i_harvest                   IN harvest.id_harvest%TYPE,
        i_analysis_harvest          IN table_number,
        i_analysis_req_det          IN table_number,
        i_body_location             IN harvest.id_body_part%TYPE,
        i_laterality                IN harvest.flg_laterality%TYPE, --10
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE, --15
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collected_by              IN harvest.id_prof_harvest%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE, --20
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN harvest.notes%TYPE,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_HARVEST_REPEAT';
        IF NOT pk_lab_tests_api_db.set_harvest_repeat(i_lang                      => i_lang,
                                                      i_prof                      => i_prof,
                                                      i_patient                   => i_patient,
                                                      i_visit                     => i_visit,
                                                      i_episode                   => i_episode,
                                                      i_harvest                   => i_harvest,
                                                      i_analysis_harvest          => i_analysis_harvest,
                                                      i_analysis_req_det          => i_analysis_req_det,
                                                      i_body_location             => i_body_location,
                                                      i_laterality                => i_laterality,
                                                      i_collection_method         => i_collection_method,
                                                      i_specimen_condition        => i_specimen_condition,
                                                      i_collection_room           => i_collection_room,
                                                      i_lab                       => i_lab,
                                                      i_exec_institution          => i_exec_institution,
                                                      i_sample_recipient          => i_sample_recipient,
                                                      i_num_recipient             => i_num_recipient,
                                                      i_collected_by              => i_collected_by,
                                                      i_collection_time           => i_collection_time,
                                                      i_collection_amount         => i_collection_amount,
                                                      i_collection_transportation => i_collection_transportation,
                                                      i_notes                     => i_notes,
                                                      i_rep_coll_reason           => i_rep_coll_reason,
                                                      i_flg_orig_harvest          => i_flg_orig_harvest,
                                                      o_error                     => o_error)
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
                                              'SET_HARVEST_REPEAT',
                                              o_error);
            RETURN FALSE;
    END set_harvest_repeat;

    FUNCTION set_harvest_reject
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_harvest            IN table_number,
        i_cancel_reason      IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes       IN harvest.notes_cancel%TYPE,
        i_specimen_condition IN harvest.id_specimen_condition%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_HARVEST_REJECT';
        IF NOT pk_lab_tests_api_db.set_harvest_reject(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_patient            => i_patient,
                                                      i_episode            => i_episode,
                                                      i_harvest            => i_harvest,
                                                      i_cancel_reason      => i_cancel_reason,
                                                      i_cancel_notes       => i_cancel_notes,
                                                      i_specimen_condition => i_specimen_condition,
                                                      o_error              => o_error)
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
                                              'SET_HARVEST_REJECT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_harvest_reject;

    FUNCTION set_lab_test_result
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_notes            IN analysis_result.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result VARCHAR2(1000 CHAR);
    
    BEGIN
    
        g_error := 'PK_LAB_TESTS_API_DB.SET_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_api_db.set_lab_test_result(i_lang                       => i_lang,
                                                       i_prof                       => i_prof,
                                                       i_patient                    => i_patient,
                                                       i_episode                    => NULL,
                                                       i_analysis                   => NULL,
                                                       i_sample_type                => NULL,
                                                       i_analysis_parameter         => NULL,
                                                       i_analysis_param             => NULL,
                                                       i_analysis_req_det           => i_analysis_req_det,
                                                       i_analysis_req_par           => NULL,
                                                       i_analysis_result_par        => NULL,
                                                       i_analysis_result_par_parent => NULL,
                                                       i_flg_type                   => NULL,
                                                       i_harvest                    => NULL,
                                                       i_dt_sample                  => NULL,
                                                       i_prof_req                   => NULL,
                                                       i_dt_analysis_result         => NULL,
                                                       i_flg_result_origin          => pk_lab_tests_constant.g_analysis_result_origin_i,
                                                       i_result_origin_notes        => NULL,
                                                       i_result_notes               => NULL,
                                                       i_loinc_code                 => NULL,
                                                       i_dt_ext_registry            => NULL,
                                                       i_instit_origin              => NULL,
                                                       i_result_value_1             => table_varchar(i_notes),
                                                       i_result_value_2             => NULL,
                                                       i_analysis_desc              => NULL,
                                                       i_doc_external               => NULL,
                                                       i_comparator                 => NULL,
                                                       i_separator                  => NULL,
                                                       i_standard_code              => NULL,
                                                       i_unit_measure               => NULL,
                                                       i_desc_unit_measure          => NULL,
                                                       i_result_status              => NULL,
                                                       i_ref_val                    => NULL,
                                                       i_ref_val_min                => NULL,
                                                       i_ref_val_max                => NULL,
                                                       i_parameter_notes            => NULL,
                                                       i_interface_notes            => NULL,
                                                       i_laboratory                 => NULL,
                                                       i_laboratory_desc            => NULL,
                                                       i_laboratory_short_desc      => NULL,
                                                       i_coding_system              => NULL,
                                                       i_method                     => NULL,
                                                       i_equipment                  => NULL,
                                                       i_abnormality                => NULL,
                                                       i_abnormality_nature         => NULL,
                                                       i_prof_validation            => NULL,
                                                       i_dt_validation              => NULL,
                                                       i_flg_intf_orig              => pk_lab_tests_constant.g_yes,
                                                       i_flg_orig_analysis          => NULL,
                                                       i_clinical_decision_rule     => NULL,
                                                       o_result                     => l_result,
                                                       o_error                      => o_error)
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
                                              'SET_LAB_TEST_RESULT',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_result;

    FUNCTION set_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN analysis_result.id_patient%TYPE,
        i_episode                    IN analysis_result.id_episode%TYPE,
        i_analysis_content           IN analysis_sample_type.id_content%TYPE,
        i_analysis_parameter         IN table_number,
        i_analysis_req_det           IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par           IN table_number,
        i_analysis_result_par        IN table_number,
        i_analysis_result_par_parent IN table_number,
        i_flg_type                   IN table_varchar,
        i_harvest                    IN harvest.id_harvest%TYPE,
        i_dt_analysis_result         IN VARCHAR2,
        i_result_notes               IN analysis_result.notes%TYPE,
        i_loinc_code                 IN analysis_result.loinc_code%TYPE DEFAULT NULL,
        i_dt_ext_registry            IN table_varchar DEFAULT NULL,
        i_instit_origin              IN table_number DEFAULT NULL,
        i_result_value_1             IN table_varchar,
        i_result_value_2             IN table_number DEFAULT NULL,
        i_analysis_desc              IN table_number,
        i_doc_external               IN table_table_number DEFAULT NULL,
        i_comparator                 IN table_varchar DEFAULT NULL,
        i_separator                  IN table_varchar DEFAULT NULL,
        i_standard_code              IN table_varchar DEFAULT NULL,
        i_unit_measure               IN table_number,
        i_desc_unit_measure          IN table_varchar DEFAULT NULL,
        i_result_status              IN table_number,
        i_ref_val                    IN table_varchar DEFAULT NULL,
        i_ref_val_min                IN table_varchar,
        i_ref_val_max                IN table_varchar,
        i_parameter_notes            IN table_varchar,
        i_interface_notes            IN table_varchar DEFAULT NULL,
        i_laboratory                 IN table_number DEFAULT NULL,
        i_laboratory_desc            IN table_varchar DEFAULT NULL,
        i_laboratory_short_desc      IN table_varchar DEFAULT NULL,
        i_coding_system              IN table_varchar DEFAULT NULL,
        i_method                     IN table_varchar DEFAULT NULL,
        i_equipment                  IN table_varchar DEFAULT NULL,
        i_abnormality                IN table_number DEFAULT NULL,
        i_abnormality_nature         IN table_number DEFAULT NULL,
        i_prof_validation            IN table_number DEFAULT NULL,
        i_dt_validation              IN table_varchar DEFAULT NULL,
        i_clinical_decision_rule     IN NUMBER,
        o_result                     OUT analysis_result.id_analysis_result%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis    analysis.id_analysis%TYPE;
        l_sample_type sample_type.id_sample_type%TYPE;
    
        l_result VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF NOT pk_api_analysis.get_lab_test_by_id_content(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_content     => i_analysis_content,
                                                          i_flg_type    => 'A',
                                                          o_analysis    => l_analysis,
                                                          o_sample_type => l_sample_type,
                                                          o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'PK_LAB_TESTS_API_DB.SET_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_api_db.set_lab_test_result(i_lang                       => i_lang,
                                                       i_prof                       => i_prof,
                                                       i_patient                    => i_patient,
                                                       i_episode                    => i_episode,
                                                       i_analysis                   => l_analysis,
                                                       i_sample_type                => l_sample_type,
                                                       i_analysis_parameter         => i_analysis_parameter,
                                                       i_analysis_param             => NULL,
                                                       i_analysis_req_det           => i_analysis_req_det,
                                                       i_analysis_req_par           => i_analysis_req_par,
                                                       i_analysis_result_par        => i_analysis_result_par,
                                                       i_analysis_result_par_parent => i_analysis_result_par_parent,
                                                       i_flg_type                   => i_flg_type,
                                                       i_harvest                    => i_harvest,
                                                       i_dt_sample                  => NULL,
                                                       i_prof_req                   => NULL,
                                                       i_dt_analysis_result         => i_dt_analysis_result,
                                                       i_flg_result_origin          => pk_lab_tests_constant.g_analysis_result_origin_i,
                                                       i_result_origin_notes        => NULL,
                                                       i_result_notes               => i_result_notes,
                                                       i_loinc_code                 => i_loinc_code,
                                                       i_dt_ext_registry            => i_dt_ext_registry,
                                                       i_instit_origin              => i_instit_origin,
                                                       i_result_value_1             => i_result_value_1,
                                                       i_result_value_2             => i_result_value_2,
                                                       i_analysis_desc              => i_analysis_desc,
                                                       i_doc_external               => i_doc_external,
                                                       i_comparator                 => i_comparator,
                                                       i_separator                  => i_separator,
                                                       i_standard_code              => i_standard_code,
                                                       i_unit_measure               => i_unit_measure,
                                                       i_desc_unit_measure          => i_desc_unit_measure,
                                                       i_result_status              => i_result_status,
                                                       i_ref_val                    => i_ref_val,
                                                       i_ref_val_min                => i_ref_val_min,
                                                       i_ref_val_max                => i_ref_val_max,
                                                       i_parameter_notes            => i_parameter_notes,
                                                       i_interface_notes            => i_interface_notes,
                                                       i_laboratory                 => i_laboratory,
                                                       i_laboratory_desc            => i_laboratory_desc,
                                                       i_laboratory_short_desc      => i_laboratory_short_desc,
                                                       i_coding_system              => i_coding_system,
                                                       i_method                     => i_method,
                                                       i_equipment                  => i_equipment,
                                                       i_abnormality                => i_abnormality,
                                                       i_abnormality_nature         => i_abnormality_nature,
                                                       i_prof_validation            => i_prof_validation,
                                                       i_dt_validation              => i_dt_validation,
                                                       i_flg_intf_orig              => pk_lab_tests_constant.g_yes,
                                                       i_flg_orig_analysis          => NULL,
                                                       i_clinical_decision_rule     => i_clinical_decision_rule,
                                                       o_result                     => l_result,
                                                       o_error                      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        BEGIN
            SELECT substr(l_result, 0, instr(l_result, '|') - 1)
              INTO o_result
              FROM dual;
        EXCEPTION
            WHEN no_data_found THEN
                o_result := NULL;
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
                                              'SET_LAB_TEST_RESULT',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_result;

    FUNCTION update_lab_test_parameter
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_desc_parameter     IN VARCHAR2,
        i_rank               IN analysis_parameter.rank%TYPE,
        i_flg_available      IN analysis_parameter.flg_available%TYPE,
        i_unit_measure       IN lab_tests_par_uni_mea.id_unit_measure%TYPE,
        i_min_val            IN lab_tests_par_uni_mea.min_measure_interval%TYPE,
        i_max_val            IN lab_tests_par_uni_mea.max_measure_interval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rank      analysis_param.rank%TYPE;
        l_available analysis_parameter.flg_available%TYPE;
    
        l_analysis_software table_varchar2;
        l_software_exists   NUMBER;
        l_code_translation  translation.code_translation%TYPE := 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                 i_analysis_parameter;
        l_desc_translation  translation.desc_lang_1%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT ap.flg_available
              INTO l_available
              FROM analysis_parameter ap
             WHERE ap.id_analysis_parameter = i_analysis_parameter;
        
            IF l_available != i_flg_available
            THEN
                UPDATE analysis_parameter
                   SET flg_available = nvl(i_flg_available, flg_available)
                 WHERE id_analysis_parameter = i_analysis_parameter;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        SELECT pk_translation.get_translation(i_lang, l_code_translation)
          INTO l_desc_translation
          FROM dual;
    
        IF l_desc_translation != i_desc_parameter
        THEN
            g_error := 'UPDATE TRANSLATION';
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => l_code_translation,
                                                   i_desc_trans => i_desc_parameter);
        END IF;
    
        l_analysis_software := pk_utils.str_split(pk_sysconfig.get_config('LAB_TESTS_PARAMETER_SOFTWARE_LIST', i_prof),
                                                  '|');
    
        FOR i IN 1 .. l_analysis_software.count
        LOOP
            BEGIN
                SELECT 1
                  INTO l_software_exists
                  FROM software_institution si
                 WHERE si.id_institution = i_prof.institution
                   AND si.id_software = l_analysis_software(i);
            
                BEGIN
                    SELECT ap.rank
                      INTO l_rank
                      FROM analysis_param ap
                     WHERE ap.id_analysis = i_analysis
                       AND ap.id_sample_type = i_sample_type
                       AND ap.id_analysis_parameter = i_analysis_parameter
                       AND ap.id_institution = i_prof.institution
                       AND ap.id_software = l_analysis_software(i);
                
                    IF l_rank != i_rank
                    THEN
                        UPDATE analysis_param
                           SET rank = i_rank
                         WHERE id_analysis = i_analysis
                           AND id_sample_type = i_sample_type
                           AND id_analysis_parameter = i_analysis_parameter
                           AND id_institution = i_prof.institution
                           AND id_software = l_analysis_software(i);
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                    
                        g_error := 'INSERT INTO ANALYSIS_PARAM';
                        INSERT INTO analysis_param
                            (id_analysis_param,
                             id_analysis,
                             id_sample_type,
                             id_analysis_parameter,
                             flg_fill_type,
                             flg_available,
                             id_institution,
                             id_software,
                             rank)
                        VALUES
                            (seq_analysis_param.nextval,
                             i_analysis,
                             i_sample_type,
                             i_analysis_parameter,
                             pk_lab_tests_constant.g_analysis_result_text,
                             i_flg_available,
                             i_prof.institution,
                             l_analysis_software(i),
                             i_rank);
                END;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        END LOOP;
    
        IF i_unit_measure IS NOT NULL
        THEN
            UPDATE lab_tests_par_uni_mea
               SET min_measure_interval = i_min_val
             WHERE id_analysis_parameter = i_analysis_parameter
               AND id_unit_measure = i_unit_measure
               AND min_measure_interval > i_min_val;
        
            UPDATE lab_tests_par_uni_mea
               SET min_measure_interval = i_max_val
             WHERE id_analysis_parameter = i_analysis_parameter
               AND id_unit_measure = i_unit_measure
               AND max_measure_interval < i_max_val;
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
                                              'UPDATE_LAB_TEST_PARAMETER',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_parameter;

    FUNCTION update_lab_test_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN table_varchar,
        i_notes_scheduler  IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.UPDATE_LAB_TEST_DATE';
        IF NOT pk_lab_tests_api_db.update_lab_test_date(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_analysis_req_det => i_analysis_req_det,
                                                        i_dt_begin         => i_dt_begin,
                                                        i_notes_scheduler  => i_notes_scheduler,
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
                                              'UPDATE_LAB_TEST_DATE',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_date;

    FUNCTION update_harvest
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_harvest         IN harvest.id_harvest%TYPE,
        i_status          IN harvest.flg_status%TYPE,
        i_collected_by    IN harvest.id_prof_harvest%TYPE DEFAULT NULL,
        i_collection_time IN harvest.dt_harvest_tstz%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.UPDATE_HARVEST';
        IF NOT pk_lab_tests_api_db.update_harvest(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_harvest          => table_number(i_harvest),
                                                  i_status           => table_varchar(i_status),
                                                  i_collected_by     => table_number(i_collected_by),
                                                  i_collection_time  => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                  i_collection_time,
                                                                                                                  i_prof)),
                                                  i_flg_orig_harvest => pk_lab_tests_constant.g_harvest_orig_harvest_i,
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
                                              'UPDATE_HARVEST',
                                              o_error);
            RETURN FALSE;
    END update_harvest;

    FUNCTION update_barcode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        i_barcode_harvest  IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_harvest harvest.id_harvest%TYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        IF i_barcode_harvest IS NOT NULL
        THEN
            IF i_harvest IS NULL
            THEN
                BEGIN
                    SELECT id_harvest
                      INTO l_harvest
                      FROM analysis_harvest ah
                     WHERE ah.id_analysis_req_det = i_analysis_req_det
                       AND ah.flg_status = pk_lab_tests_constant.g_active;
                EXCEPTION
                    WHEN too_many_rows THEN
                        g_error := 'This id_analysis_req_det has more than one harvest';
                        RAISE g_other_exception;
                END;
            END IF;
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE HARVEST';
            ts_harvest.upd(id_harvest_in => nvl(i_harvest, l_harvest),
                           barcode_in    => i_barcode_harvest,
                           barcode_nin   => FALSE,
                           rows_out      => l_rows_out);
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
                                              'UPDATE_BARCODE',
                                              o_error);
            RETURN FALSE;
    END update_barcode;

    FUNCTION cancel_lab_test_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis_req  IN table_number,
        i_cancel_reason IN analysis_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN analysis_req.notes_cancel%TYPE,
        i_prof_order    IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order      IN VARCHAR2,
        i_order_type    IN co_sign.id_order_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.cancel_lab_test_order(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_analysis_req  => i_analysis_req,
                                                       i_cancel_reason => i_cancel_reason,
                                                       i_cancel_notes  => i_cancel_notes,
                                                       i_prof_order    => i_prof_order,
                                                       i_dt_order      => i_dt_order,
                                                       i_order_type    => i_order_type,
                                                       o_error         => o_error)
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
                                              'CANCEL_LAB_TEST_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_order;

    FUNCTION cancel_lab_test_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN analysis_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN analysis_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_REQUEST';
        IF NOT pk_lab_tests_core.cancel_lab_test_request(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_analysis_req_det => i_analysis_req_det,
                                                         i_dt_cancel        => i_dt_cancel,
                                                         i_cancel_reason    => i_cancel_reason,
                                                         i_cancel_notes     => i_cancel_notes,
                                                         i_prof_order       => i_prof_order,
                                                         i_dt_order         => i_dt_order,
                                                         i_order_type       => i_order_type,
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
                                              'CANCEL_LAB_TEST_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_request;

    FUNCTION cancel_harvest
    (
        i_lang          IN language.id_language%TYPE, --1
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE, --5
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.CANCEL_HARVEST';
        IF NOT pk_lab_tests_api_db.cancel_harvest(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_patient       => i_patient,
                                                  i_episode       => i_episode,
                                                  i_harvest       => i_harvest,
                                                  i_cancel_reason => i_cancel_reason,
                                                  i_cancel_notes  => i_cancel_notes,
                                                  o_error         => o_error)
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
                                              'CANCEL_HARVEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_harvest;

    FUNCTION cancel_lab_test_result
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_analysis_result    IN analysis_result.id_analysis_result%TYPE,
        i_cancel_reason      IN analysis_result_par.id_cancel_reason%TYPE,
        i_notes_cancel       IN analysis_result_par.notes_cancel%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_result_par table_number;
    
    BEGIN
    
        SELECT id_analysis_result_par
          BULK COLLECT
          INTO l_analysis_result_par
          FROM (SELECT arp.id_analysis_result_par,
                       row_number() over(PARTITION BY arp.id_analysis_result ORDER BY arp.dt_analysis_result_par_tstz DESC) rn
                  FROM analysis_result ar, analysis_result_par arp
                 WHERE ar.id_analysis_result = i_analysis_result
                   AND ar.id_analysis_result = arp.id_analysis_result
                   AND arp.id_analysis_parameter = i_analysis_parameter);
    
        FOR i IN 1 .. l_analysis_result_par.count
        LOOP
            g_error := 'CALL PK_LAB_TESTS_API_DB.CANCEL_LAB_TEST_RESULT';
            IF NOT pk_lab_tests_api_db.cancel_lab_test_result(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_analysis_result_par => l_analysis_result_par(i),
                                                              i_cancel_reason       => i_cancel_reason,
                                                              i_notes_cancel        => i_notes_cancel,
                                                              o_error               => o_error)
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
                                              'CANCEL_LAB_TEST_RESULT',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_result;

    FUNCTION get_lab_test_by_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_content     IN VARCHAR2,
        i_flg_type    IN VARCHAR2,
        o_analysis    OUT analysis.id_analysis%TYPE,
        o_sample_type OUT sample_type.id_sample_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_flg_type = 'A'
        THEN
            g_error := 'GET ID_ANALYSIS & ID_SAMPLE_TYPE';
            SELECT ast.id_analysis, ast.id_sample_type
              INTO o_analysis, o_sample_type
              FROM analysis_sample_type ast
             WHERE ast.id_content = i_content;
        ELSE
            g_error := 'GET ID_ANALYSIS_GROUP';
            SELECT ag.id_analysis_group, NULL
              INTO o_analysis, o_sample_type
              FROM analysis_group ag
             WHERE ag.id_content = i_content;
        
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
                                              'GET_LAB_TEST_BY_ID_CONTENT',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_by_id_content;

    FUNCTION get_lab_test_cq_by_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_content  IN VARCHAR2,
        i_flg_type IN VARCHAR2,
        o_id       OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_flg_type = 'CQ'
        THEN
            g_error := 'GET ID_QUESTIONNAIRE';
            SELECT q.id_questionnaire
              INTO o_id
              FROM questionnaire q
             WHERE q.id_content = i_content;
        ELSE
            g_error := 'GET ID_RESPONSE';
            SELECT r.id_response
              INTO o_id
              FROM response r
             WHERE r.id_content = i_content;
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
                                              'GET_LAB_TEST_CQ_BY_ID_CONTENT',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_cq_by_id_content;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_analysis;
/
