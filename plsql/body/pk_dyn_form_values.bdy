CREATE OR REPLACE PACKAGE BODY pk_dyn_form_values AS

    k_pck_owner VARCHAR2(0100 CHAR) := 'ALERT';
    k_pck_name  VARCHAR2(0100 CHAR);
    --k_yes CONSTANT t_low_char := 'Y';
    --k_no  CONSTANT t_low_char := 'N';
    --k_default_action CONSTANT NUMBER := pk_dyn_form_constant.get_default_action();

    -- ******************************************
    -- ******************************************
    -- development team function 

    FUNCTION get_values_base
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        k_action_submit CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
        o_error t_error_out;
    BEGIN
    
        CASE
            WHEN i_root_name = 'DS_EPIS_OUT_ON_PASS' THEN
                tbl_result := pk_epis_out_on_pass.get_values(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_episode        => i_episode,
                                                             i_patient        => i_patient,
                                                             i_action         => i_action,
                                                             i_root_name      => i_root_name,
                                                             i_curr_component => i_curr_component,
                                                             i_tbl_id_pk      => i_tbl_id_pk,
                                                             i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                             i_value          => i_value,
                                                             o_error          => o_error);
            WHEN i_root_name = 'DS_ADT_SCHEDULED_APPOINTMENT' THEN
            
                tbl_result := pk_schedule.get_schedule_values(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_episode,
                                                              i_patient        => i_patient,
                                                              i_action         => i_action,
                                                              i_root_name      => i_root_name,
                                                              i_curr_component => i_curr_component,
                                                              i_tbl_id_pk      => i_tbl_id_pk,
                                                              i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                              i_value          => i_value,
                                                              o_error          => o_error);
            
            WHEN i_root_name = 'DS_HHC_REQUEST' THEN
                tbl_result := pk_hhc_core.get_default_values_hhc(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_episode        => i_episode,
                                                                 i_patient        => i_patient,
                                                                 i_action         => i_action,
                                                                 i_root_name      => i_root_name,
                                                                 i_curr_component => i_curr_component,
                                                                 i_tbl_id_pk      => i_tbl_id_pk,
                                                                 i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                 i_value          => i_value,
                                                                 i_value_clob     => i_value_clob,
                                                                 o_error          => o_error);
            WHEN i_root_name IN ('DS_PHA_CARTS_CONFIGS',
                                 'DS_PHA_UNIDOSE_ORDERS',
                                 'DS_MED_ERRORS',
                                 'DS_MED_LOCAL_PRESC',
                                 'DS_MED_ADM_COMPLETE',
                                 'DS_MED_ADM_DRIP',
                                 'DS_MED_ADM_DISCONTINUE',
                                 'DS_MED_ADM_EDIT_DT_END',
                                 'DS_MED_ADM_COND_ORDER',
                                 'DS_MED_OTHER_FREQUENCIES') THEN
                tbl_result := pk_api_pfh_in.get_values(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_episode        => i_episode,
                                                       i_patient        => i_patient,
                                                       i_action         => i_action,
                                                       i_root_name      => i_root_name,
                                                       i_curr_component => i_curr_component,
                                                       i_tbl_id_pk      => i_tbl_id_pk,
                                                       i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                       i_value          => i_value,
                                                       o_error          => o_error);
            WHEN i_root_name IN ('DS_SEARCH_ACT_THERAPY_INACT',
                                 'DS_SEARCH_CM_INACT',
                                 'DS_SEARCH_DIETITIAN_INACT',
                                 'DS_SEARCH_EDIS_INACT',
                                 'DS_SEARCH_IMGEX_INACT',
                                 'DS_SEARCH_INP_INACT',
                                 'DS_SEARCH_LABS_INACT',
                                 'DS_SEARCH_MT_INACT',
                                 'DS_SEARCH_ORIS_INACT',
                                 'DS_SEARCH_OUTP_INACT',
                                 'DS_SEARCH_PHARM_INACTIVE',
                                 'DS_SEARCH_PRIM_CARE_INACT',
                                 'DS_SEARCH_PRIV_PRATICE_INACT',
                                 'DS_SEARCH_REHAB_INACT')
                 AND (i_action IS NULL OR i_action <> k_action_submit) THEN
                tbl_result := pk_search.get_inactive_search_values(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_episode        => i_episode,
                                                                   i_patient        => i_patient,
                                                                   i_action         => i_action,
                                                                   i_root_name      => i_root_name,
                                                                   i_curr_component => i_curr_component,
                                                                   i_tbl_id_pk      => i_tbl_id_pk,
                                                                   i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                   i_value          => i_value,
                                                                   o_error          => o_error);
            
            WHEN i_root_name IN ('DS_SEARCH_DIETITIAN_ACT', 'DS_SEARCH_REHAB_ACT')
                 AND (i_action IS NULL OR i_action <> k_action_submit) THEN
                tbl_result := pk_search.get_active_search_values(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_episode        => i_episode,
                                                                 i_patient        => i_patient,
                                                                 i_action         => i_action,
                                                                 i_root_name      => i_root_name,
                                                                 i_curr_component => i_curr_component,
                                                                 i_tbl_id_pk      => i_tbl_id_pk,
                                                                 i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                 i_value          => i_value,
                                                                 o_error          => o_error);
            
            WHEN i_root_name IN ('DS_SEARCH_ACT_THERAPY_INACT',
                                 'DS_SEARCH_CANCEL',
                                 'DS_SEARCH_CM_ACT',
                                 'DS_SEARCH_CM_INACT',
                                 'DS_SEARCH_DIETITIAN_ACT',
                                 'DS_SEARCH_DIETITIAN_INACT',
                                 'DS_SEARCH_EDIS_ACT',
                                 'DS_SEARCH_EDIS_CANCEL',
                                 'DS_SEARCH_EDIS_INACT',
                                 'DS_SEARCH_EXAMS_COMPLETE',
                                 'DS_SEARCH_EXAMS_SCHED',
                                 'DS_SEARCH_IMGEX_ACT',
                                 'DS_SEARCH_IMGEX_INACT',
                                 'DS_SEARCH_INP_CANC',
                                 'DS_SEARCH_INP_INACT',
                                 'DS_SEARCH_LABS_ACT',
                                 'DS_SEARCH_LABS_INACT',
                                 'DS_SEARCH_MT_ACT',
                                 'DS_SEARCH_MT_INACT',
                                 'DS_SEARCH_ORIS_ACT',
                                 'DS_SEARCH_ORIS_INACT',
                                 'DS_SEARCH_OUTP_ACT',
                                 'DS_SEARCH_OUTP_INACT',
                                 'DS_SEARCH_OUTP_SCHED',
                                 'DS_SEARCH_PHARM_ACTIVE',
                                 'DS_SEARCH_PHARM_INACTIVE',
                                 'DS_SEARCH_PRIM_CARE_ACTIVE',
                                 'DS_SEARCH_PRIM_CARE_CANC_SCHED',
                                 'DS_SEARCH_PRIM_CARE_INACT',
                                 'DS_SEARCH_PRIM_CARE_SCHED',
                                 'DS_SEARCH_PRIV_PRATICE_ACTIVE',
                                 'DS_SEARCH_PRIV_PRATICE_EXAM_FINISHED',
                                 'DS_SEARCH_PRIV_PRATICE_INACT',
                                 'DS_SEARCH_PRIV_PRATICE_SCHED',
                                 'DS_SEARCH_REFF_ACT',
                                 'DS_SEARCH_REFF_MYREFF',
                                 'DS_SEARCH_REFF_ORDERS',
                                 'DS_SEARCH_REHAB_ACT',
                                 'DS_SEARCH_REHAB_INACT',
                                 'DS_SEARCH_RT_ACT',
                                 'DS_SEARCH_SCH_APPOINTMENTS',
                                 'DS_SEARCH')
                 AND (i_action = k_action_submit) THEN
                tbl_result := pk_search.get_submit_values(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => i_episode,
                                                          i_patient        => i_patient,
                                                          i_action         => i_action,
                                                          i_root_name      => i_root_name,
                                                          i_curr_component => i_curr_component,
                                                          i_tbl_id_pk      => i_tbl_id_pk,
                                                          i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                          i_tbl_int_name   => i_tbl_int_name,
                                                          i_value          => i_value,
                                                          o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_follow_up_social,
                                 pk_orders_constant.g_ds_follow_up_case_management,
                                 pk_orders_constant.g_ds_follow_up_cdc,
                                 pk_orders_constant.g_ds_follow_up_mental,
                                 pk_orders_constant.g_ds_follow_up_diet,
                                 pk_orders_constant.g_ds_follow_up_psy,
                                 pk_orders_constant.g_ds_follow_up_rehab_occupational,
                                 pk_orders_constant.g_ds_follow_up_rehab_physical,
                                 pk_orders_constant.g_ds_follow_up_rehab_speech,
                                 pk_orders_constant.g_ds_follow_up_religious,
                                 pk_orders_constant.g_ds_follow_up_social_original,
                                 pk_orders_constant.g_ds_follow_up_activity_therapist) THEN
                tbl_result := pk_opinion.get_consult_request_values(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_episode        => i_episode,
                                                                    i_patient        => i_patient,
                                                                    i_action         => i_action,
                                                                    i_root_name      => i_root_name,
                                                                    i_curr_component => i_curr_component,
                                                                    i_tbl_id_pk      => i_tbl_id_pk,
                                                                    i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                    i_tbl_int_name   => i_tbl_int_name,
                                                                    i_value          => i_value,
                                                                    i_value_clob     => i_value_clob,
                                                                    o_error          => o_error);
            WHEN i_root_name IN ('DS_HHC_DISCHARGE')
                 AND (i_action IS NULL OR i_action <> k_action_submit) THEN
                tbl_result := pk_hhc_discharge.get_values(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => i_episode,
                                                          i_patient        => i_patient,
                                                          i_action         => i_action,
                                                          i_root_name      => i_root_name,
                                                          i_curr_component => i_curr_component,
                                                          i_tbl_id_pk      => i_tbl_id_pk,
                                                          i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                          i_value          => i_value,
                                                          o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_positioning, pk_orders_constant.g_ds_sr_positioning) THEN
                tbl_result := pk_inp_positioning.get_positioning_request_values(i_lang           => i_lang,
                                                                                i_prof           => i_prof,
                                                                                i_episode        => i_episode,
                                                                                i_patient        => i_patient,
                                                                                i_action         => i_action,
                                                                                i_root_name      => i_root_name,
                                                                                i_curr_component => i_curr_component,
                                                                                i_tbl_id_pk      => i_tbl_id_pk,
                                                                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                                i_value          => i_value,
                                                                                o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_positioning_execution) THEN
                tbl_result := pk_inp_positioning.get_positioning_exec_values(i_lang           => i_lang,
                                                                             i_prof           => i_prof,
                                                                             i_episode        => i_episode,
                                                                             i_patient        => i_patient,
                                                                             i_action         => i_action,
                                                                             i_root_name      => i_root_name,
                                                                             i_curr_component => i_curr_component,
                                                                             i_tbl_id_pk      => i_tbl_id_pk,
                                                                             i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                             i_value          => i_value,
                                                                             o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_health_education_order THEN
                tbl_result := pk_patient_education_core.get_he_order_values(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_episode        => i_episode,
                                                                            i_patient        => i_patient,
                                                                            i_action         => i_action,
                                                                            i_root_name      => i_root_name,
                                                                            i_curr_component => i_curr_component,
                                                                            i_idx            => i_idx,
                                                                            i_tbl_id_pk      => i_tbl_id_pk,
                                                                            i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                            i_tbl_int_name   => i_tbl_int_name,
                                                                            i_value          => i_value,
                                                                            i_value_mea      => i_value_mea,
                                                                            i_value_desc     => i_value_desc,
                                                                            i_value_clob     => i_value_clob,
                                                                            o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_lab_test_request,
                                 pk_orders_constant.g_ds_imaging_exam_request,
                                 pk_orders_constant.g_ds_other_exam_request,
                                 pk_orders_constant.g_ds_procedure_request) THEN
                tbl_result := pk_orders_utils.get_generic_form_values(i_lang           => i_lang,
                                                                      i_prof           => i_prof,
                                                                      i_episode        => i_episode,
                                                                      i_patient        => i_patient,
                                                                      i_action         => i_action,
                                                                      i_root_name      => i_root_name,
                                                                      i_curr_component => i_curr_component,
                                                                      i_idx            => i_idx,
                                                                      i_tbl_id_pk      => i_tbl_id_pk,
                                                                      i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                      i_tbl_int_name   => i_tbl_int_name,
                                                                      i_value          => i_value,
                                                                      i_value_mea      => i_value_mea,
                                                                      i_value_desc     => i_value_desc,
                                                                      i_tbl_data       => i_tbl_data,
                                                                      i_value_clob     => i_value_clob,
                                                                      o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                tbl_result := pk_order_sets.get_os_generic_task_form_values(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_episode        => i_episode,
                                                                            i_patient        => i_patient,
                                                                            i_action         => i_action,
                                                                            i_root_name      => i_root_name,
                                                                            i_curr_component => i_curr_component,
                                                                            i_idx            => i_idx,
                                                                            i_tbl_id_pk      => i_tbl_id_pk,
                                                                            i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                            i_tbl_int_name   => i_tbl_int_name,
                                                                            i_value          => i_value,
                                                                            i_value_mea      => i_value_mea,
                                                                            i_value_desc     => i_value_desc,
                                                                            i_tbl_data       => i_tbl_data,
                                                                            i_value_clob     => i_value_clob,
                                                                            o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_to_execute) THEN
                tbl_result := pk_orders_utils.get_to_execute_form_values(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_episode        => i_episode,
                                                                         i_patient        => i_patient,
                                                                         i_action         => i_action,
                                                                         i_root_name      => i_root_name,
                                                                         i_curr_component => i_curr_component,
                                                                         i_idx            => i_idx,
                                                                         i_tbl_id_pk      => i_tbl_id_pk,
                                                                         i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                         i_tbl_int_name   => i_tbl_int_name,
                                                                         i_value          => i_value,
                                                                         i_value_mea      => i_value_mea,
                                                                         i_value_desc     => i_value_desc,
                                                                         i_tbl_data       => i_tbl_data,
                                                                         i_value_clob     => i_value_clob,
                                                                         o_error          => o_error);
            WHEN i_root_name IN ('DS_NEW_MEDICAL_APPOINTMENT_EPISODE') THEN
                tbl_result := pk_events.get_event_form_values(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_episode,
                                                              i_patient        => i_patient,
                                                              i_action         => i_action,
                                                              i_root_name      => i_root_name,
                                                              i_curr_component => i_curr_component,
                                                              i_idx            => i_idx,
                                                              i_tbl_id_pk      => i_tbl_id_pk,
                                                              i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                              i_tbl_int_name   => i_tbl_int_name,
                                                              i_value          => i_value,
                                                              i_value_mea      => i_value_mea,
                                                              i_value_desc     => i_value_desc,
                                                              i_tbl_data       => i_tbl_data,
                                                              i_value_clob     => i_value_clob,
                                                              o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_health_education_execution) THEN
                tbl_result := pk_patient_education_core.get_request_for_execution(i_lang                 => i_lang,
                                                                                  i_prof                 => i_prof,
                                                                                  i_episode              => i_episode,
                                                                                  i_action               => i_action,
                                                                                  i_tbl_id_nurse_tea_req => i_tbl_id_pk,
                                                                                  i_curr_component       => i_curr_component,
                                                                                  i_idx                  => i_idx,
                                                                                  i_tbl_mkt_rel          => i_tbl_mkt_rel,
                                                                                  i_value                => i_value,
                                                                                  i_value_mea            => i_value_mea,
                                                                                  i_value_desc           => i_value_desc,
                                                                                  i_value_clob           => i_value_clob,
                                                                                  o_error                => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_health_education_order_execution) THEN
                tbl_result := pk_patient_education_core.get_order_for_execution(i_lang           => i_lang,
                                                                                i_prof           => i_prof,
                                                                                i_episode        => i_episode,
                                                                                i_patient        => i_patient,
                                                                                i_action         => i_action,
                                                                                i_root_name      => i_root_name,
                                                                                i_curr_component => i_curr_component,
                                                                                i_idx            => i_idx,
                                                                                i_tbl_id_pk      => i_tbl_id_pk,
                                                                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                                i_value          => i_value,
                                                                                i_value_mea      => i_value_mea,
                                                                                i_value_desc     => i_value_desc,
                                                                                i_value_clob     => i_value_clob,
                                                                                o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_other_frequencies THEN
                tbl_result := pk_orders_utils.get_other_frequencies_values(i_lang           => i_lang,
                                                                           i_prof           => i_prof,
                                                                           i_episode        => i_episode,
                                                                           i_patient        => i_patient,
                                                                           i_action         => i_action,
                                                                           i_root_name      => i_root_name,
                                                                           i_curr_component => i_curr_component,
                                                                           i_idx            => i_idx,
                                                                           i_tbl_id_pk      => i_tbl_id_pk,
                                                                           i_tbl_data       => i_tbl_data,
                                                                           i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                           i_tbl_int_name   => i_tbl_int_name,
                                                                           i_value          => i_value,
                                                                           i_value_desc     => i_value_desc,
                                                                           i_value_clob     => i_value_clob,
                                                                           i_value_mea      => i_value_mea,
                                                                           o_error          => o_error);
            WHEN i_root_name IN (pk_orders_utils.g_p1_appointment,
                                 pk_orders_utils.g_p1_lab_test,
                                 pk_orders_utils.g_p1_intervention,
                                 pk_orders_utils.g_p1_imaging_exam,
                                 pk_orders_utils.g_p1_other_exam,
                                 pk_orders_utils.g_p1_rehab) THEN
                tbl_result := pk_p1_ext_sys.get_p1_order_values(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_episode        => i_episode,
                                                                i_patient        => i_patient,
                                                                i_action         => i_action,
                                                                i_root_name      => i_root_name,
                                                                i_curr_component => i_curr_component,
                                                                i_idx            => i_idx,
                                                                i_tbl_id_pk      => i_tbl_id_pk,
                                                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                i_value          => i_value,
                                                                i_value_desc     => i_value_desc,
                                                                o_error          => o_error);
            WHEN i_root_name IN ('DS_CONSULT_REPLY') THEN
                tbl_result := pk_opinion.get_consult_for_reply(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_episode        => i_episode,
                                                               i_patient        => i_patient,
                                                               i_action         => i_action,
                                                               i_root_name      => i_root_name,
                                                               i_curr_component => i_curr_component,
                                                               i_tbl_id_pk      => i_tbl_id_pk,
                                                               i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                               i_value          => i_value,
                                                               o_error          => o_error);
            WHEN i_root_name IN ('DS_DOCUMENT_ARCHIVE',
                                 'DS_DOC_LAB_TEST_RESULT',
                                 'DS_ASSOCIATE_DOC_LAB_TEST',
                                 'DS_DOC_EXAM_RESULT',
                                 'DS_ASSOCIATE_DOC_EXAM',
                                 'DS_ASSOCIATE_DOC_PROCEDURE') THEN
                tbl_result := pk_doc.get_doc_archive_values(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_episode        => i_episode,
                                                            i_patient        => i_patient,
                                                            i_action         => i_action,
                                                            i_root_name      => i_root_name,
                                                            i_curr_component => i_curr_component,
                                                            i_idx            => i_idx,
                                                            i_tbl_id_pk      => i_tbl_id_pk,
                                                            i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                            i_value          => i_value,
                                                            o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_rehab_treatment) THEN
                tbl_result := pk_rehab.get_rehab_treatment_values(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_episode        => i_episode,
                                                                  i_patient        => i_patient,
                                                                  i_action         => i_action,
                                                                  i_root_name      => i_root_name,
                                                                  i_curr_component => i_curr_component,
                                                                  i_idx            => i_idx,
                                                                  i_tbl_id_pk      => i_tbl_id_pk,
                                                                  i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                  i_value          => i_value,
                                                                  i_value_mea      => i_value_mea,
                                                                  i_value_desc     => i_value_desc,
                                                                  o_error          => o_error);
            WHEN i_root_name IN
                 (pk_orders_constant.g_ds_lab_results, pk_orders_constant.g_ds_lab_results_with_prof_list) THEN
                tbl_result := pk_lab_tests_utils.get_result_form_values(i_lang           => i_lang,
                                                                        i_prof           => i_prof,
                                                                        i_episode        => i_episode,
                                                                        i_patient        => i_patient,
                                                                        i_action         => i_action,
                                                                        i_root_name      => i_root_name,
                                                                        i_curr_component => i_curr_component,
                                                                        i_idx            => i_idx,
                                                                        i_tbl_id_pk      => i_tbl_id_pk,
                                                                        i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                        i_tbl_int_name   => i_tbl_int_name,
                                                                        i_value          => i_value,
                                                                        i_value_desc     => i_value_desc,
                                                                        i_tbl_data       => i_tbl_data,
                                                                        i_value_clob     => i_value_clob,
                                                                        o_error          => o_error);
            WHEN i_root_name LIKE 'CLINQUEST%' THEN
                tbl_result := pk_mcdt.get_request_values(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_episode        => i_episode,
                                                         i_patient        => i_patient,
                                                         i_action         => i_action,
                                                         i_root_name      => i_root_name,
                                                         i_curr_component => i_curr_component,
                                                         i_tbl_int_name   => i_tbl_int_name,
                                                         i_tbl_id_pk      => i_tbl_id_pk,
                                                         i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                         i_value          => i_value,
                                                         o_error          => o_error);
            WHEN i_root_name = 'DS_FOLLOW_UP_NOTES'
                 AND (i_action IS NULL OR i_action <> k_action_submit) THEN
                tbl_result := pk_paramedical_prof_core.get_followup_notes_values(i_lang           => i_lang,
                                                                                 i_prof           => i_prof,
                                                                                 i_episode        => i_episode,
                                                                                 i_patient        => i_patient,
                                                                                 i_action         => i_action,
                                                                                 i_root_name      => i_root_name,
                                                                                 i_curr_component => i_curr_component,
                                                                                 i_tbl_id_pk      => i_tbl_id_pk,
                                                                                 i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                                 i_value          => i_value,
                                                                                 o_error          => o_error);
            
            WHEN i_root_name = 'DS_SAMPLE_TEXT' THEN
                tbl_result := pk_sample_text.get_stext_values(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_episode,
                                                              i_patient        => i_patient,
                                                              i_action         => i_action,
                                                              i_root_name      => i_root_name,
                                                              i_curr_component => i_curr_component,
                                                              i_tbl_id_pk      => i_tbl_id_pk,
                                                              i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                              i_value          => i_value,
                                                              i_value_clob     => i_value_clob,
                                                              o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_bo) THEN
                tbl_result := pk_order_sets.get_order_set_bo_form_values(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_episode        => NULL,
                                                                         i_patient        => NULL,
                                                                         i_action         => i_action,
                                                                         i_root_name      => i_root_name,
                                                                         i_curr_component => i_curr_component,
                                                                         i_idx            => i_idx,
                                                                         i_tbl_id_pk      => i_tbl_id_pk,
                                                                         i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                         i_tbl_int_name   => i_tbl_int_name,
                                                                         i_value          => i_value,
                                                                         i_value_mea      => i_value_mea,
                                                                         i_value_desc     => i_value_desc,
                                                                         i_tbl_data       => i_tbl_data,
                                                                         i_value_clob     => i_value_clob,
                                                                         o_error          => o_error);
            
            WHEN i_root_name = 'DS_RETRO_INFORMATION' THEN
                tbl_result := pk_retro_information.get_retro_information_values(i_lang           => i_lang,
                                                                                i_prof           => i_prof,
                                                                                i_episode        => i_episode,
                                                                                i_patient        => i_patient,
                                                                                i_action         => i_action,
                                                                                i_root_name      => i_root_name,
                                                                                i_curr_component => i_curr_component,
                                                                                i_tbl_id_pk      => i_tbl_id_pk,
                                                                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                                i_tbl_int_name   => i_tbl_int_name,
                                                                                i_value          => i_value,
                                                                                i_value_mea      => i_value_mea,
                                                                                i_value_desc     => i_value_desc,
                                                                                i_tbl_data       => i_tbl_data,
                                                                                i_value_clob     => i_value_clob,
                                                                                o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_monitoring) THEN
                tbl_result := pk_order_sets.get_os_monitoring_form_values(i_lang           => i_lang,
                                                                          i_prof           => i_prof,
                                                                          i_episode        => i_episode,
                                                                          i_patient        => i_patient,
                                                                          i_action         => i_action,
                                                                          i_root_name      => i_root_name,
                                                                          i_curr_component => i_curr_component,
                                                                          i_idx            => i_idx,
                                                                          i_tbl_id_pk      => i_tbl_id_pk,
                                                                          i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                          i_tbl_int_name   => i_tbl_int_name,
                                                                          i_value          => i_value,
                                                                          i_value_mea      => i_value_mea,
                                                                          i_value_desc     => i_value_desc,
                                                                          i_tbl_data       => i_tbl_data,
                                                                          i_value_clob     => i_value_clob,
                                                                          o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_consult) THEN
                tbl_result := pk_opinion.get_order_set_consult_form(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_episode        => i_episode,
                                                                    i_patient        => i_patient,
                                                                    i_action         => i_action,
                                                                    i_root_name      => i_root_name,
                                                                    i_curr_component => i_curr_component,
                                                                    i_idx            => i_idx,
                                                                    i_tbl_id_pk      => i_tbl_id_pk,
                                                                    i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                    i_tbl_int_name   => i_tbl_int_name,
                                                                    i_value          => i_value,
                                                                    i_value_mea      => i_value_mea,
                                                                    i_value_desc     => i_value_desc,
                                                                    i_tbl_data       => i_tbl_data,
                                                                    i_value_clob     => i_value_clob,
                                                                    o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_order_set_health_education THEN
                tbl_result := pk_patient_education_core.get_os_he_order_values(i_lang           => i_lang,
                                                                               i_prof           => i_prof,
                                                                               i_episode        => i_episode,
                                                                               i_patient        => i_patient,
                                                                               i_action         => i_action,
                                                                               i_root_name      => i_root_name,
                                                                               i_curr_component => i_curr_component,
                                                                               i_idx            => i_idx,
                                                                               i_tbl_id_pk      => i_tbl_id_pk,
                                                                               i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                               i_tbl_int_name   => i_tbl_int_name,
                                                                               i_value          => i_value,
                                                                               i_value_mea      => i_value_mea,
                                                                               i_value_desc     => i_value_desc,
                                                                               i_value_clob     => i_value_clob,
                                                                               o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_medical_appointment,
                                 pk_orders_constant.g_ds_order_set_nursing_appointment,
                                 pk_orders_constant.g_ds_order_set_rehab_appointment,
                                 pk_orders_constant.g_ds_order_set_social_appointment,
                                 pk_orders_constant.g_ds_order_set_diet_appointment) THEN
                tbl_result := pk_order_sets.get_os_appointment_form_values(i_lang           => i_lang,
                                                                           i_prof           => i_prof,
                                                                           i_episode        => i_episode,
                                                                           i_patient        => i_patient,
                                                                           i_action         => i_action,
                                                                           i_root_name      => i_root_name,
                                                                           i_curr_component => i_curr_component,
                                                                           i_idx            => i_idx,
                                                                           i_tbl_id_pk      => i_tbl_id_pk,
                                                                           i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                           i_tbl_int_name   => i_tbl_int_name,
                                                                           i_value          => i_value,
                                                                           i_value_mea      => i_value_mea,
                                                                           i_value_desc     => i_value_desc,
                                                                           i_tbl_data       => i_tbl_data,
                                                                           i_value_clob     => i_value_clob,
                                                                           o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_discharge_instructions) THEN
                tbl_result := pk_order_sets.get_os_discharge_form_values(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_episode        => i_episode,
                                                                         i_patient        => i_patient,
                                                                         i_action         => i_action,
                                                                         i_root_name      => i_root_name,
                                                                         i_curr_component => i_curr_component,
                                                                         i_idx            => i_idx,
                                                                         i_tbl_id_pk      => i_tbl_id_pk,
                                                                         i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                         i_tbl_int_name   => i_tbl_int_name,
                                                                         i_value          => i_value,
                                                                         i_value_mea      => i_value_mea,
                                                                         i_value_desc     => i_value_desc,
                                                                         i_tbl_data       => i_tbl_data,
                                                                         i_value_clob     => i_value_clob,
                                                                         o_error          => o_error);
            WHEN i_root_name IN (pk_orders_constant.g_ds_order_set_personalised_diets) THEN
                tbl_result := pk_order_sets.get_os_personalised_diet_form_values(i_lang           => i_lang,
                                                                                 i_prof           => i_prof,
                                                                                 i_episode        => i_episode,
                                                                                 i_patient        => i_patient,
                                                                                 i_action         => i_action,
                                                                                 i_root_name      => i_root_name,
                                                                                 i_curr_component => i_curr_component,
                                                                                 i_idx            => i_idx,
                                                                                 i_tbl_id_pk      => i_tbl_id_pk,
                                                                                 i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                                 i_tbl_int_name   => i_tbl_int_name,
                                                                                 i_value          => i_value,
                                                                                 i_value_mea      => i_value_mea,
                                                                                 i_value_desc     => i_value_desc,
                                                                                 i_tbl_data       => i_tbl_data,
                                                                                 i_value_clob     => i_value_clob,
                                                                                 o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_order_set_group THEN
                tbl_result := pk_task_groups.get_task_group_form_values(i_lang           => i_lang,
                                                                        i_prof           => i_prof,
                                                                        i_episode        => NULL,
                                                                        i_patient        => NULL,
                                                                        i_action         => i_action,
                                                                        i_root_name      => i_root_name,
                                                                        i_curr_component => i_curr_component,
                                                                        i_idx            => i_idx,
                                                                        i_tbl_id_pk      => i_tbl_id_pk,
                                                                        i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                        i_tbl_int_name   => i_tbl_int_name,
                                                                        i_value          => i_value,
                                                                        i_value_mea      => i_value_mea,
                                                                        i_value_desc     => i_value_desc,
                                                                        i_tbl_data       => i_tbl_data,
                                                                        i_value_clob     => i_value_clob,
                                                                        o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_order_set_front_office THEN
                tbl_result := pk_order_sets.get_order_set_fo_form_values(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_episode        => i_episode,
                                                                         i_patient        => i_patient,
                                                                         i_action         => i_action,
                                                                         i_root_name      => i_root_name,
                                                                         i_curr_component => i_curr_component,
                                                                         i_idx            => i_idx,
                                                                         i_tbl_id_pk      => i_tbl_id_pk,
                                                                         i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                         i_tbl_int_name   => i_tbl_int_name,
                                                                         i_value          => i_value,
                                                                         i_value_mea      => i_value_mea,
                                                                         i_value_desc     => i_value_desc,
                                                                         i_tbl_data       => i_tbl_data,
                                                                         i_value_clob     => i_value_clob,
                                                                         o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_prof_bleep_info THEN
                tbl_result := pk_orders_utils.get_prof_bleep_info(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_episode        => i_episode,
                                                                  i_patient        => i_patient,
                                                                  i_action         => i_action,
                                                                  i_root_name      => i_root_name,
                                                                  i_curr_component => i_curr_component,
                                                                  i_idx            => i_idx,
                                                                  i_tbl_id_pk      => i_tbl_id_pk,
                                                                  i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                  i_tbl_int_name   => i_tbl_int_name,
                                                                  i_value          => i_value,
                                                                  i_value_mea      => i_value_mea,
                                                                  i_value_desc     => i_value_desc,
                                                                  i_tbl_data       => i_tbl_data,
                                                                  i_value_clob     => i_value_clob,
                                                                  o_error          => o_error);
            WHEN i_root_name = 'DS_DIGITAL_SIG' THEN
                tbl_result := pk_sig.get_sig_info(i_lang => i_lang,
                                                  i_prof => i_prof,
                                                  --i_episode        => i_episode,
                                                  --i_patient        => i_patient,
                                                  i_action         => i_action,
                                                  i_root_name      => i_root_name,
                                                  i_curr_component => i_curr_component,
                                                  i_tbl_id_pk      => i_tbl_id_pk,
                                                  i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                  i_tbl_int_name   => i_tbl_int_name,
                                                  i_value          => i_value,
                                                  i_value_clob     => i_value_clob,
                                                  o_error          => o_error);
            WHEN i_root_name = pk_orders_constant.g_ds_exam_associate_pregnancy THEN
                tbl_result := pk_pregnancy_exam.get_pregnancy_confirm_form_values(i_lang           => i_lang,
                                                                                  i_prof           => i_prof,
                                                                                  i_episode        => i_episode,
                                                                                  i_patient        => i_patient,
                                                                                  i_action         => i_action,
                                                                                  i_root_name      => i_root_name,
                                                                                  i_curr_component => i_curr_component,
                                                                                  i_idx            => i_idx,
                                                                                  i_tbl_id_pk      => i_tbl_id_pk,
                                                                                  i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                                  i_tbl_int_name   => i_tbl_int_name,
                                                                                  i_value          => i_value,
                                                                                  i_value_mea      => i_value_mea,
                                                                                  i_value_desc     => i_value_desc,
                                                                                  i_tbl_data       => i_tbl_data,
                                                                                  i_value_clob     => i_value_clob,
                                                                                  o_error          => o_error);
            ELSE
                tbl_result := t_tbl_ds_get_value();
        END CASE;
    
        RETURN tbl_result;
    
    END get_values_base;

    FUNCTION get_values_multi
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN tt_table_varchar,
        i_value_mea      IN tt_table_varchar,
        i_value_desc     IN tt_table_varchar,
        i_value_clob     IN table_table_clob,
        i_tbl_data       IN table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count    NUMBER;
        l_bool     BOOLEAN;
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_agg    t_tbl_ds_get_value := t_tbl_ds_get_value();
    BEGIN
    
        l_count := i_tbl_id_pk.count;
    
        <<lup_thru_multi>>
        FOR i IN 1 .. l_count
        LOOP
            tbl_result := get_values_base(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_episode        => i_episode,
                                          i_patient        => i_patient,
                                          i_action         => i_action,
                                          i_root_name      => i_root_name,
                                          i_curr_component => i_curr_component,
                                          i_idx            => i,
                                          i_tbl_id_pk      => i_tbl_id_pk,
                                          i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                          i_tbl_int_name   => i_tbl_int_name,
                                          i_value          => i_value(i),
                                          i_value_mea      => i_value_mea(i),
                                          i_value_desc     => i_value_desc(i),
                                          i_value_clob     => i_value_clob(i),
                                          i_tbl_data       => i_tbl_data);
        
            tbl_agg := tbl_agg MULTISET UNION tbl_result;
        
        END LOOP lup_thru_multi;
    
        l_bool := process_multi_form_result(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_episode   => i_episode,
                                            i_patient   => i_patient,
                                            i_root_name => i_root_name,
                                            o_result    => tbl_agg,
                                            o_error     => o_error);
        IF NOT l_bool
        THEN
            -- dont process any more if error....
            RETURN FALSE;
        END IF;
    
        OPEN o_result FOR
            SELECT --xsql.rn ,
             xsql.idx,
             xsql.id_ds_cmpt_mkt_rel,
             xsql.id_ds_component,
             xsql.internal_name,
             xsql.value,
             xsql.value_clob,
             xsql.min_value,
             xsql.max_value,
             xsql.desc_value,
             xsql.desc_clob,
             xsql.id_unit_measure,
             xsql.desc_unit_measure,
             xsql.flg_validation,
             xsql.err_msg,
             xsql.flg_event_type,
             xsql.flg_multi_status,
             dcmr.input_mask,
             dcmr.text_line_nr
              FROM TABLE(tbl_agg) xsql
              JOIN ds_cmpt_mkt_rel dcmr
                ON dcmr.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
             WHERE xsql.id_ds_cmpt_mkt_rel IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => k_pck_owner,
                                              i_package  => k_pck_name,
                                              i_function => 'GET_VALUES_MULTI',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_result);
            RETURN FALSE;
        
    END get_values_multi;

    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar, --fot unitmeasure, currency of value
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_data       IN table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        --k_action_submit CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
    BEGIN
    
        tbl_result := get_values_base(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_episode        => i_episode,
                                      i_patient        => i_patient,
                                      i_action         => i_action,
                                      i_root_name      => i_root_name,
                                      i_curr_component => i_curr_component,
                                      i_idx            => 1,
                                      i_tbl_id_pk      => i_tbl_id_pk,
                                      i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                      i_tbl_int_name   => i_tbl_int_name,
                                      i_value          => i_value,
                                      i_value_mea      => i_value_mea,
                                      i_value_desc     => i_value_desc,
                                      i_value_clob     => i_value_clob,
                                      i_tbl_data       => i_tbl_data);
    
        OPEN o_result FOR
            SELECT xsql.id_ds_cmpt_mkt_rel,
                   xsql.id_ds_component,
                   xsql.internal_name,
                   xsql.value,
                   xsql.value_clob,
                   xsql.min_value,
                   xsql.max_value,
                   xsql.desc_value,
                   xsql.desc_clob,
                   xsql.id_unit_measure,
                   xsql.desc_unit_measure,
                   xsql.flg_validation,
                   xsql.err_msg,
                   xsql.flg_event_type,
                   xsql.flg_multi_status,
                   xsql.idx,
                   dcmr.input_mask,
                   dcmr.text_line_nr
              FROM TABLE(tbl_result) xsql
              JOIN ds_cmpt_mkt_rel dcmr
                ON dcmr.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
             WHERE xsql.id_ds_cmpt_mkt_rel IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => k_pck_owner,
                                              i_package  => k_pck_name,
                                              i_function => 'GET_VALUES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_result);
            RETURN FALSE;
    END get_values;

    -- **************************************************

    FUNCTION get_custom_multichoice
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_episode              IN NUMBER,
        i_patient              IN NUMBER,
        i_root_name            IN VARCHAR2,
        i_service_name_curr    IN VARCHAR2,
        i_internal_name_origin IN table_varchar,
        i_internal_name_values IN table_table_varchar,
        o_result               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_total t_tbl_core_domain := t_tbl_core_domain();
        l_array   table_varchar := table_varchar();
    BEGIN
    
        CASE i_service_name_curr
            WHEN 'GET_SAMPLE_TEXT_AREA' THEN
                tbl_total := pk_sample_text.get_sample_text_area(i_lang, i_prof);
            WHEN 'GET_PAT_CRIT_MCHOICE' THEN
                tbl_total := pk_search.get_pat_crit_mchoice_mkt_rel(i_lang, i_prof, i_internal_name_origin(1));
            WHEN 'GET_HHC_CONSULTANT_IN_CHARGE' THEN
            
                IF i_internal_name_origin.exists(1)
                THEN
                    l_array := i_internal_name_origin;
                ELSE
                    l_array := table_varchar('');
                END IF;
            
                tbl_total := pk_hhc_core.get_consult_in_charge(i_lang, i_prof, i_episode, i_patient, l_array(1));
            
            WHEN 'GET_UNIDOSE_SERVICES' THEN
            
                tbl_total := pk_api_pfh_in.get_unidose_services(i_lang,
                                                                i_prof,
                                                                CASE
                                                                    WHEN i_internal_name_origin.exists(1) THEN
                                                                     i_internal_name_origin(1)
                                                                    ELSE
                                                                     NULL
                                                                END,
                                                                o_error);
            WHEN 'GET_UNIDOSE_CART_SLOTS' THEN
                tbl_total := pk_api_pfh_in.get_pharm_slots(i_lang,
                                                           i_prof,
                                                           CASE
                                                               WHEN i_internal_name_origin.exists(1) THEN
                                                                i_internal_name_origin(1)
                                                               ELSE
                                                                NULL
                                                           END,
                                                           o_error);
            WHEN 'GET_FOLLOW_UP_PROF_LIST_SOCIAL' THEN
            
                IF i_internal_name_origin.exists(1)
                THEN
                    l_array := i_internal_name_origin;
                ELSE
                    l_array := table_varchar('');
                END IF;
            
                tbl_total := pk_opinion.get_prof_list(i_lang,
                                                      i_prof,
                                                      pk_opinion.g_ot_social_worker_ds,
                                                      l_array(1),
                                                      o_error);
            WHEN 'GET_FOLLOW_UP_PROF_LIST' THEN
                tbl_total := pk_opinion.get_prof_list(i_lang,
                                                      i_prof,
                                                      CASE
                                                          WHEN i_internal_name_values(1).exists(1) THEN
                                                           i_internal_name_values(1) (1)
                                                          ELSE
                                                           NULL
                                                      END,
                                                      CASE
                                                          WHEN i_internal_name_values(2).exists(1) THEN
                                                           i_internal_name_values(2) (1)
                                                          ELSE
                                                           NULL
                                                      END);
            WHEN 'GET_FOLLOW_UP_SPEC_LIST' THEN
                tbl_total := pk_opinion.get_clin_serv_list(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_opinion_type => CASE
                                                                                 WHEN i_internal_name_values(1).exists(1) THEN
                                                                                  i_internal_name_values(1) (1)
                                                                                 ELSE
                                                                                  NULL
                                                                             END);
            WHEN 'GET_TIME_LIST' THEN
                tbl_total := pk_orders_utils.get_time_list(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_id_episode           => i_episode,
                                                           i_id_order_recurr_plan => i_internal_name_values(1) (1));
            WHEN 'GET_PRN_LIST' THEN
                tbl_total := pk_orders_utils.get_prn_list(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_root_name => i_internal_name_values(1) (1));
            WHEN 'GET_FASTING_LIST' THEN
                tbl_total := pk_orders_utils.get_fasting_list(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_root_name => i_root_name);
            WHEN 'GET_MOST_FREQUENT_RECURRENCES' THEN
                tbl_total := pk_order_recurrence_core.get_most_frequent_recurrences(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_order_recurr_area => CASE
                                                                                                            i_root_name
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                                'LAB_TEST'
                                                                                                               WHEN
                                                                                                                'DS_BLOOD_PRODUCTS' THEN
                                                                                                                'BLOOD_PRODUCTS'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                                'IMAGE_EXAM'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                                'OTHER_EXAM'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_procedure_request THEN
                                                                                                                'PROCEDURE'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_order_set_procedure THEN
                                                                                                                'PROCEDURE'
                                                                                                           END);
            WHEN 'GET_MOST_FREQUENT_RECURRENCES_HEALTH_EDUCATION' THEN
                tbl_total := pk_order_recurrence_core.get_most_frequent_recurrences(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_order_recurr_area => 'PATIENT_EDUCATION');
            
            WHEN 'GET_ORDER_TYPE' THEN
                tbl_total := pk_co_sign.get_order_type(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_internal_name => NULL,
                                                       o_error         => o_error);
            
            WHEN 'GET_PROF_LIST' THEN
                tbl_total := pk_co_sign.get_prof_list(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_episode    => i_episode,
                                                      i_id_order_type => CASE
                                                                             WHEN i_internal_name_values(1).exists(1) THEN
                                                                              i_internal_name_values(1) (1)
                                                                             ELSE
                                                                              NULL
                                                                         END,
                                                      i_internal_name => NULL,
                                                      o_error         => o_error);
            WHEN 'GET_PREDEFINED_TIME_SCHEDULES' THEN
                tbl_total := pk_order_recurrence_core.get_predefined_time_schedules(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_order_recurr_area => CASE
                                                                                                            i_internal_name_values(1) (1)
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                                'IMAGE_EXAM'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                                'OTHER_EXAM'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_procedure_request THEN
                                                                                                                'PROCEDURE'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_order_set_procedure THEN
                                                                                                                'PROCEDURE'
                                                                                                               WHEN
                                                                                                                pk_orders_constant.g_ds_health_education_order THEN
                                                                                                                'PATIENT_EDUCATION'
                                                                                                           END);
            WHEN 'GET_ORDER_RECURR_PLAN_END' THEN
                tbl_total := pk_order_recurrence_core.get_order_recurr_plan_end(i_lang        => i_lang,
                                                                                i_prof        => i_prof,
                                                                                i_domain      => 'ORDER_RECURR_PLAN.FLG_END_BY',
                                                                                i_flg_context => 'P');
            
            WHEN 'GET_HEALTH_EDUCATION_FLG_TIME' THEN
                tbl_total := pk_patient_education_api_db.get_domain_flg_time(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_DOCUMENTATION_GOALS' THEN
                tbl_total := pk_patient_education_api_db.get_documentation_goals(i_lang  => i_lang,
                                                                                 i_prof  => i_prof,
                                                                                 o_error => o_error);
            WHEN 'GET_DOCUMENTATION_METHODS' THEN
                tbl_total := pk_patient_education_api_db.get_documentation_methods(i_lang  => i_lang,
                                                                                   i_prof  => i_prof,
                                                                                   o_error => o_error);
            WHEN 'GET_DOCUMENTATION_GIVEN_TO' THEN
                tbl_total := pk_patient_education_api_db.get_documentation_given_to(i_lang  => i_lang,
                                                                                    i_prof  => i_prof,
                                                                                    o_error => o_error);
            WHEN 'GET_DOCUMENTATION_ADDIT_RES' THEN
                tbl_total := pk_patient_education_api_db.get_documentation_addit_res(i_lang  => i_lang,
                                                                                     i_prof  => i_prof,
                                                                                     o_error => o_error);
            WHEN 'GET_DOCUMENTATION_UNDERSTANDING' THEN
                tbl_total := pk_patient_education_api_db.get_doc_level_understanding(i_lang  => i_lang,
                                                                                     i_prof  => i_prof,
                                                                                     o_error => o_error);
            WHEN 'GET_P1_INST' THEN
                CASE i_internal_name_values(1) (1)
                    WHEN pk_orders_utils.g_p1_appointment THEN
                        tbl_total := pk_p1_data_export.get_clinical_institution(i_lang => i_lang,
                                                                                i_prof => i_prof,
                                                                                i_spec => i_internal_name_values(2) (1));
                    WHEN pk_orders_utils.g_p1_lab_test THEN
                        --The form recevies a piped analysis_instit_soft, it is necessary to obtain 
                        --the piped id_analysis in order to call pk_p1_analysis.get_analysis_inst
                        tbl_total := pk_p1_analysis.get_analysis_inst(i_lang     => i_lang,
                                                                      i_prof     => i_prof,
                                                                      i_analysis => pk_orders_utils.get_piped_analysis(i_lang               => i_lang,
                                                                                                                       i_prof               => i_prof,
                                                                                                                       i_analysis_inst_soft => i_internal_name_values(2) (1)));
                    WHEN pk_orders_utils.g_p1_intervention THEN
                        tbl_total := pk_p1_interv.get_interv_inst(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_interventions => i_internal_name_values(2) (1));
                    WHEN pk_orders_utils.g_p1_imaging_exam THEN
                        tbl_total := pk_p1_exam.get_exam_inst(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_exams => i_internal_name_values(2) (1));
                    WHEN pk_orders_utils.g_p1_other_exam THEN
                        tbl_total := pk_p1_exam.get_exam_inst(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_exams => i_internal_name_values(2) (1));
                    WHEN pk_orders_utils.g_p1_rehab THEN
                        --The form recevies a piped id_rehab_area_interv, it is necessary to obtain 
                        --the piped in_intervention in order to call pk_p1_interv.get_rehab_inst
                        tbl_total := pk_p1_interv.get_rehab_inst(i_lang   => i_lang,
                                                                 i_prof   => i_prof,
                                                                 i_rehabs => pk_orders_utils.get_piped_rehab_interv(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_rehab_area_interv => i_internal_name_values(2) (1)));
                    
                END CASE;
            WHEN 'GET_P1_LATERALITY' THEN
                tbl_total := pk_mcdt.get_laterality_all(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_flg_type  => 'U',
                                                        i_mcdt_type => CASE i_internal_name_values(1) (1)
                                                                           WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                            'E'
                                                                           WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                            'E'
                                                                           WHEN pk_orders_utils.g_p1_intervention THEN
                                                                            'P'
                                                                           WHEN pk_orders_utils.g_p1_rehab THEN
                                                                            'P'
                                                                       END,
                                                        i_mcdt      => i_internal_name_values(2) (1));
            
            WHEN 'GET_P1_PRIORITY_LIST' THEN
                tbl_total := pk_ref_list.get_priority_list(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_P1_CLINICAL_SERVICES' THEN
                tbl_total := pk_p1_data_export.get_clinical_service(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_patient => i_patient);
            WHEN 'GET_PATIENT_HEALTH_PLAN_ENTITY' THEN
                tbl_total := pk_orders_utils.get_patient_health_plan_entity(i_lang    => i_lang,
                                                                            i_prof    => i_prof,
                                                                            i_patient => i_patient);
            WHEN 'GET_PATIENT_HEALTH_PLAN_LIST' THEN
                tbl_total := pk_orders_utils.get_patient_health_plan_list(i_lang               => i_lang,
                                                                          i_prof               => i_prof,
                                                                          i_patient            => i_patient,
                                                                          i_health_plan_entity => i_internal_name_values(1) (1));
            WHEN 'GET_PAT_EXEMPTIONS' THEN
                tbl_total := pk_orders_utils.get_pat_exemptions(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_patient => i_patient);
            WHEN 'GET_CLINICAL_PURPOSE' THEN
                tbl_total := pk_orders_utils.get_multichoice_options(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_id_patient       => i_patient,
                                                                     i_multichoice_type => CASE i_root_name
                                                                                               WHEN
                                                                                                pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                'ANALYSIS_REQ_DET.ID_CLINICAL_PURPOSE'
                                                                                               WHEN
                                                                                                pk_orders_constant.g_ds_rehab_treatment THEN
                                                                                                'REHAB_PRESC.ID_CLINICAL_PURPOSE'
                                                                                               WHEN
                                                                                                pk_orders_constant.g_ds_procedure_request THEN
                                                                                                'INTERV_PRESC_DET.ID_CLINICAL_PURPOSE'
                                                                                               WHEN
                                                                                                pk_orders_constant.g_ds_order_set_procedure THEN
                                                                                                'INTERV_PRESC_DET.ID_CLINICAL_PURPOSE'
                                                                                               WHEN
                                                                                                pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                'EXAM_REQ_DET.ID_CLINICAL_PURPOSE'
                                                                                               WHEN
                                                                                                pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                'EXAM_REQ_DET.ID_CLINICAL_PURPOSE'
                                                                                           END);
            WHEN 'GET_PRIORITY_LIST' THEN
                tbl_total := pk_orders_utils.get_priority_list(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_root_name => i_root_name);
            
            WHEN 'GET_INST_EPIS_DEPARTMENTS' THEN
                tbl_total := pk_api_pfh_out.get_inst_epis_departments(i_lang, i_prof, i_episode, o_error);
            
            WHEN 'GET_MED_MULTICHOICE_OPTIONS' THEN
                tbl_total := pk_orders_utils.get_multichoice_options(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_id_patient       => i_patient,
                                                                     i_multichoice_type => CASE i_internal_name_origin(1)
                                                                                               WHEN 'DS_ME_COMMITED_BY' THEN
                                                                                                'MEDICATION_ERRORS.COMMITED_BY'
                                                                                               WHEN 'DS_ME_DISCOVERED_BY' THEN
                                                                                                'MEDICATION_ERRORS.DISCOVERED_BY'
                                                                                               WHEN 'DS_ME_REASON' THEN
                                                                                                'MEDICATION_ERRORS.CRITERIA'
                                                                                               WHEN 'DS_ME_STAGES_INVOLVED' THEN
                                                                                                'MEDICATION_ERRORS.STAGES_INVOLVED'
                                                                                               WHEN 'DS_ME_ERROR_OUTCOME' THEN
                                                                                                'MEDICATION_ERRORS.ERROR_OUTCOME'
                                                                                               WHEN 'DS_ME_CAUSE_OF_ERROR' THEN
                                                                                                'MEDICATION_ERRORS.CAUSE_OF_ERROR'
                                                                                           END);
            WHEN 'GET_SPEC_LIST_BY_CONFIG' THEN
                tbl_total := pk_opinion.get_spec_list_by_config(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_PROF_SPEC_LIST_BY_CONFIG' THEN
                tbl_total := pk_opinion.get_prof_spec_list_by_config(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_speciality => i_internal_name_values(1) (1));
            WHEN 'GET_MED_CLIN_PURPOSE' THEN
                tbl_total := pk_api_pfh_in.get_clinical_purpose_list(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_patient          => i_patient,
                                                                     i_id_episode          => i_episode,
                                                                     i_id_product          => table_varchar(i_internal_name_values(1) (1)),
                                                                     i_id_product_supplier => table_varchar(i_internal_name_values(2) (1)),
                                                                     i_id_presc_type_rel   => 1);
            
            WHEN 'GET_SOS_TAKE_CONDITION' THEN
                tbl_total := pk_api_pfh_in.get_cancel_reasons_by_type(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_presc_list_type => 18);
            WHEN 'GET_COND_ORDER_JUSTIFY' THEN
                tbl_total := pk_api_pfh_in.get_cancel_reasons_by_type(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_presc_list_type => 30);
            WHEN 'GET_DIAG_PROBLEM_LIST' THEN
                tbl_total := pk_api_pfh_in.get_diag_problem_list(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_patient => i_patient,
                                                                 i_id_episode => i_episode);
            WHEN 'GET_ADMIN_METHOD_LIST' THEN
                tbl_total := pk_api_pfh_in.get_admin_method_list(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_id_route          => i_internal_name_values(1) (1),
                                                                 i_id_route_supplier => i_internal_name_values(2) (1));
            WHEN 'GET_ADMIN_SITE_LIST' THEN
                tbl_total := pk_api_pfh_in.get_admin_site_list(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_route          => i_internal_name_values(1) (1),
                                                               i_id_route_supplier => i_internal_name_values(2) (1));
            WHEN 'GET_TYPE_TREATMENT' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => i_internal_name_values(1) (1),
                                                                  i_id_product_supplier => i_internal_name_values(2) (1),
                                                                  i_presc_list_type     => 21);
            WHEN 'GET_YES_NO_LIST' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => NULL,
                                                                  i_id_product_supplier => NULL,
                                                                  i_presc_list_type     => 4);
            WHEN 'GET_COND_ORDER_LIST' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => i_internal_name_values(1) (1),
                                                                  i_id_product_supplier => i_internal_name_values(2) (1),
                                                                  i_presc_list_type     => 30);
            WHEN 'GET_EXECUTE_LIST' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => i_internal_name_values(1) (1),
                                                                  i_id_product_supplier => i_internal_name_values(2) (1),
                                                                  i_presc_list_type     => 36);
            WHEN 'GET_SUPPLY_SOURCE' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => i_internal_name_values(1) (1),
                                                                  i_id_product_supplier => i_internal_name_values(2) (1),
                                                                  i_presc_list_type     => 264);
            WHEN 'GET_CANCEL_REASONS_BY_TYPE' THEN
                tbl_total := pk_api_pfh_in.get_cancel_reasons_by_type(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_presc_list_type => 1);
            WHEN 'GET_DISPENSE_METHOD' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => i_internal_name_values(1) (1),
                                                                  i_id_product_supplier => i_internal_name_values(2) (1),
                                                                  i_presc_list_type     => 43);
            WHEN 'GET_DOC_CATEGORIES' THEN
                tbl_total := pk_doc.get_categories(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_DOC_TYPES' THEN
                tbl_total := pk_doc.get_doc_types(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_patient,
                                                  i_episode      => i_episode,
                                                  i_ext_req      => NULL,
                                                  i_btn          => NULL,
                                                  i_doc_ori_type => i_internal_name_values(1) (1));
            WHEN 'GET_SPECIALTY_LIST' THEN
                tbl_total := pk_list.get_specialty_list(i_lang => i_lang);
            WHEN 'GET_DOC_ORIGINALS' THEN
                tbl_total := pk_doc.get_doc_originals(i_lang => i_lang, i_prof => i_prof, i_btn => NULL);
            WHEN 'GET_DOC_DESTINATIONS' THEN
                tbl_total := pk_doc.get_doc_destinations(i_lang => i_lang, i_prof => i_prof, i_btn => NULL);
            WHEN 'GET_LANGUAGE_LIST' THEN
                tbl_total := pk_list.get_language_list(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_PRESC_RATE_BY_TYPE' THEN
                tbl_total := pk_api_pfh_in.get_presc_rate_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => NULL,
                                                                  i_id_product_supplier => NULL,
                                                                  i_presc_list_type     => 1,
                                                                  i_context             => 'EDIT_RATE');
            WHEN 'GET_LATERALITY' THEN
                tbl_total := pk_mcdt.get_laterality_all(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_flg_laterality_mcdt => CASE i_root_name
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_rehab_treatment THEN
                                                                                      table_varchar('O')
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_procedure_request THEN
                                                                                      i_internal_name_values(2)
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_order_set_procedure THEN
                                                                                      i_internal_name_values(2)
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                      i_internal_name_values(2)
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_other_exam_request THEN
                                                                                      i_internal_name_values(2)
                                                                                 END,
                                                        i_flg_type            => CASE i_root_name
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_rehab_treatment THEN
                                                                                      'U'
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_procedure_request THEN
                                                                                      'I'
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_order_set_procedure THEN
                                                                                      'I'
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                      'U'
                                                                                     WHEN
                                                                                      pk_orders_constant.g_ds_other_exam_request THEN
                                                                                      'U'
                                                                                 END);
            WHEN 'GET_REHAB_PLACE_SERVICE' THEN
                --The form recevies a piped id_rehab_area_interv, it is necessary to obtain 
                --the piped in_intervention in order to call pk_rehab.get_rehab_inst              
                tbl_total := pk_rehab.get_rehab_inst(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_intervs => pk_orders_utils.get_piped_rehab_interv(i_lang              => i_lang,
                                                                                                         i_prof              => i_prof,
                                                                                                         i_rehab_area_interv => i_internal_name_values(1) (1)));
            
            WHEN 'GET_REHAB_NOT_ORDER_LIST' THEN
                tbl_total := pk_not_order_reason.get_not_order_reason_list(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_task_type => 50);
            WHEN 'GET_MULTICHOICE_CQ' THEN
                tbl_total := pk_mcdt.get_multichoice_options(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_patient => i_patient,
                                                             i_episode => i_episode,
                                                             i_field   => i_internal_name_origin(1));
            WHEN 'GET_REHAB_ICF' THEN
                tbl_total := pk_rehab.get_patient_icf(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
            WHEN 'GET_PROCEDURE_LOCATION_LIST' THEN
                --The form recevies a piped id_intervention                           
                tbl_total := pk_procedures_core.get_procedure_location_list(i_lang         => i_lang,
                                                                            i_prof         => i_prof,
                                                                            i_intervention => pk_utils.str_split_n(i_list  => i_internal_name_values(1) (1),
                                                                                                                   i_delim => '|'),
                                                                            i_flg_time     => 'E');
            WHEN 'GET_UNIT_MEASURE_LIST' THEN
                tbl_total := pk_orders_utils.get_unit_measure_list(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_root_name => i_root_name);
            WHEN 'GET_UNIT_MEASURE_REGULAR_INTERVALS' THEN
                tbl_total := pk_orders_utils.get_unit_measure_list(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_root_name => 'DS_UNIT_MEASURE_REGULAR_INTERVALS');
            WHEN 'GET_UNIT_MEASURE_DURATION' THEN
                tbl_total := pk_orders_utils.get_unit_measure_list(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_root_name => 'DS_UNIT_MEASURE_DURATION');
            WHEN 'GET_UNIT_MEASURE_END_AFTER' THEN
                tbl_total := pk_orders_utils.get_unit_measure_list(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_root_name => 'DS_END_AFTER_N');
            WHEN 'GET_CATALOGUE' THEN
                tbl_total := pk_orders_utils.get_catalogue_list(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_root_name => i_internal_name_values(1) (1),
                                                                i_records   => i_internal_name_values(2) (1));
            WHEN 'GET_LAB_TEST_RESULT_PROF_LIST' THEN
                tbl_total := pk_lab_tests_core.get_lab_test_result_prof_list(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_LOCATION_LIST' THEN
                tbl_total := pk_orders_utils.get_location_list(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_root_name => i_root_name,
                                                               i_records   => i_internal_name_values(1) (1));
            WHEN 'GET_REASON_REQUEST_LIST' THEN
                tbl_total := pk_opinion.get_reason_request_list(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_patient => i_patient);
            WHEN 'GET_REASON_REQUEST_LIST' THEN
                tbl_total := pk_opinion.get_reason_request_list(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_patient => i_patient);
            WHEN 'GET_FREQUENCIES_BY_TYPE' THEN
                tbl_total := pk_api_pfh_in.get_frequencies_by_type(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_product          => NULL,
                                                                   i_id_product_supplier => NULL,
                                                                   i_freq_type           => CASE i_internal_name_origin(1)
                                                                                                WHEN 'DS_DAYS_OF_WEEK' THEN
                                                                                                 4
                                                                                                WHEN 'DS_ON_WEEKS' THEN
                                                                                                 9
                                                                                                WHEN 'DS_DAYS_OF_MONTH' THEN
                                                                                                 5
                                                                                                WHEN 'DS_ON_MONTHS' THEN
                                                                                                 10
                                                                                            END);
            WHEN 'GET_OTHER_FREQ_REPEAT_ON' THEN
                tbl_total := pk_api_pfh_in.get_presc_list_by_type(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => NULL,
                                                                  i_id_product_supplier => NULL,
                                                                  i_presc_list_type     => 10);
            WHEN 'GET_LOCATIONS' THEN
                tbl_total := pk_events.get_locations(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_institution => i_prof.institution);
            WHEN 'GET_APPROVAL_PROFESSIONALS' THEN
                tbl_total := pk_events.get_approval_professionals(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_APPOINTMENT_TYPE_OF_VISIT' THEN
                tbl_total := pk_events.tf_get_type_of_visit(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_institution  => i_internal_name_values(1) (1),
                                                            i_id_task_type => 30);
            WHEN 'GET_EVENTS' THEN
                tbl_total := pk_events.get_events(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_dep_clin_serv => i_internal_name_values(2) (1),
                                                  i_institution   => i_internal_name_values(1) (1),
                                                  i_id_task_type  => i_internal_name_values(3) (1));
            WHEN 'GET_DEST_PROFESSIONALS' THEN
                tbl_total := pk_events.get_dest_professionals(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_institution   => i_internal_name_values(1) (1),
                                                              i_dep_clin_serv => i_internal_name_values(2) (1),
                                                              i_sch_event     => i_internal_name_values(3) (1),
                                                              i_id_task_type  => i_internal_name_values(4) (1));
            WHEN 'GET_EVENT_ROOMS' THEN
                tbl_total := pk_events.get_rooms(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_dep_clin_serv => i_internal_name_values(1) (1),
                                                 i_flg_search       => NULL);
            WHEN 'GET_REASON_OF_VISIT' THEN
                tbl_total := pk_events.get_reason_of_visit(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_dep_clin_serv => i_internal_name_values(1) (1),
                                                           i_patient          => i_patient,
                                                           i_episode          => i_episode,
                                                           i_sch_event        => i_internal_name_values(2) (1),
                                                           i_institution      => i_internal_name_values(3) (1),
                                                           i_professional     => i_internal_name_values(4) (1),
                                                           i_id_task_type     => i_internal_name_values(5) (1));
            WHEN 'GET_ALERT_LANGUAGES' THEN
                tbl_total := pk_orders_utils.get_alert_languages(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_patient => i_patient);
            WHEN 'GET_SPECIMEN_LIST' THEN
                tbl_total := pk_lab_tests_core.get_lab_test_specimen_list(i_lang        => i_lang,
                                                                          i_prof        => i_prof,
                                                                          i_analysis    => to_number(i_internal_name_values(1) (1)),
                                                                          i_sample_type => NULL);
            WHEN 'GET_COLLECTION_PLACE' THEN
                tbl_total := pk_lab_tests_core.get_lab_test_location_list(i_lang        => i_lang,
                                                                          i_prof        => i_prof,
                                                                          i_analysis    => i_internal_name_values(1),
                                                                          i_sample_type => i_internal_name_values(2),
                                                                          i_flg_type    => pk_lab_tests_constant.g_arm_flg_type_room_pat);
            WHEN 'GET_LAB_EXECUTION_PLACE' THEN
                tbl_total := pk_lab_tests_core.get_lab_test_location_list(i_lang        => i_lang,
                                                                          i_prof        => i_prof,
                                                                          i_analysis    => i_internal_name_values(1),
                                                                          i_sample_type => i_internal_name_values(2),
                                                                          i_flg_type    => pk_lab_tests_constant.g_arm_flg_type_room_tube);
            
            WHEN 'GET_ORDER_SET_TYPE' THEN
                tbl_total := pk_order_sets.get_order_set_type_list(i_lang         => i_lang,
                                                                   i_prof         => i_prof,
                                                                   i_id_order_set => i_internal_name_values(1) (1),
                                                                   o_error        => o_error);
            WHEN 'GET_ORDER_SET_DEPARTMENT' THEN
                tbl_total := pk_order_sets.get_order_set_environment_list(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_institutions => i_internal_name_values(1),
                                                                          o_error        => o_error);
            WHEN 'GET_ORDER_SET_USE_PERMISSION' THEN
                tbl_total := pk_order_sets.get_odst_permission_list(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_id_order_set    => i_internal_name_values(1) (1),
                                                                    i_permission_type => pk_order_sets.g_odst_target_profs_domain,
                                                                    o_error           => o_error);
            WHEN 'GET_ORDER_SET_EDIT_PERMISSION' THEN
                tbl_total := pk_order_sets.get_odst_permission_list(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_id_order_set    => i_internal_name_values(1) (1),
                                                                    i_permission_type => pk_order_sets.g_odst_edit_perms_domain,
                                                                    o_error           => o_error);
            WHEN 'GET_PROF_INSTITUTIONS' THEN
                tbl_total := pk_orders_utils.get_prof_institutions(i_lang  => i_lang,
                                                                   i_prof  => i_prof,
                                                                   o_error => o_error);
            WHEN 'GET_PAT_RACE' THEN
                tbl_total := pk_adt_core.get_race(i_lang => i_lang, i_prof => i_prof);
            
            WHEN 'DS_OCCUPATION' THEN
                tbl_total := pk_adt_core.get_occupation(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_UNIT_MEASURE_DAYS' THEN
                tbl_total := pk_unit_measure.tf_get_unit_measure_list(i_lang => i_lang,
                                                                      i_prof => i_prof,
                                                                      i_area => i_service_name_curr);
            WHEN 'GET_UNIT_MEASURE_SURGERY' THEN
                tbl_total := pk_unit_measure.tf_get_unit_measure_list(i_lang => i_lang,
                                                                      i_prof => i_prof,
                                                                      i_area => i_service_name_curr);
            WHEN 'GET_ADVANCED_INPUT_PRIORITY' THEN
                tbl_total := pk_advanced_input.get_multichoice_options(i_lang                    => i_lang,
                                                                       i_prof                    => i_prof,
                                                                       i_advanced_input          => i_internal_name_values(1) (1),
                                                                       i_id_advanced_input_field => 91,
                                                                       o_error                   => o_error);
            WHEN 'GET_ADVANCED_INPUT_RELEASE_FROM' THEN
                tbl_total := pk_advanced_input.get_multichoice_options(i_lang                    => i_lang,
                                                                       i_prof                    => i_prof,
                                                                       i_advanced_input          => i_internal_name_values(1) (1),
                                                                       i_id_advanced_input_field => 102,
                                                                       o_error                   => o_error);
            WHEN 'GET_ADVANCED_INPUT_FREQUENCY_UM' THEN
                tbl_total := pk_advanced_input.get_unit_measure_list(i_lang                    => i_lang,
                                                                     i_prof                    => i_prof,
                                                                     i_advanced_input          => CASE i_root_name
                                                                                                      WHEN
                                                                                                       pk_orders_constant.g_ds_order_set_monitoring THEN
                                                                                                       55
                                                                                                  END,
                                                                     i_id_advanced_input_field => 98,
                                                                     o_error                   => o_error);
            WHEN 'GET_SPEC_LIST' THEN
                tbl_total := pk_opinion.tf_get_spec_list(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
            WHEN 'GET_PROF_SPEC_LIST' THEN
                tbl_total := pk_opinion.tf_get_prof_spec_list(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_speciality => i_internal_name_values(1) (1),
                                                              o_error      => o_error);
            WHEN 'GET_TYPE_OF_VISIT' THEN
                tbl_total := pk_events.tf_get_type_of_visit(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_institution  => i_internal_name_values(1) (1),
                                                            i_id_task_type => i_internal_name_values(2) (1));
            WHEN 'GET_FOLLOW_UP_TYPE' THEN
                tbl_total := pk_discharge.tf_get_follow_up_type_list(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_ORDER_SET_SERVICES' THEN
                tbl_total := pk_order_sets.get_services_list(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_tbl_dept => i_internal_name_values(1));
            WHEN 'GET_DISCHARGE_PROF_LIST' THEN
                tbl_total := pk_discharge.tf_get_followup_with_wofreetext(i_lang => i_lang, i_prof => i_prof);
            WHEN 'GET_SIG_ORDER_LIST' THEN
                tbl_total := pk_sig.get_sig_order_list(i_lang, i_prof);
            WHEN 'GET_EXAM_ASSOCIATE_PREGNANCY' THEN
                tbl_total := pk_pregnancy_exam.tf_get_pregn_associated_opt(i_lang            => i_lang,
                                                                           i_prof            => i_prof,
                                                                           i_flg_female_exam => i_internal_name_values(1) (1));
            ELSE
                tbl_total := t_tbl_core_domain();
            
        END CASE;
    
        OPEN o_result FOR
            SELECT xdmn.internal_name, xdmn.desc_domain, xdmn.domain_value, xdmn.order_rank, xdmn.img_name
              FROM TABLE(tbl_total) xdmn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => k_pck_owner,
                                              i_package  => k_pck_name,
                                              i_function => 'GET_MULTICHOICE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_result);
            RETURN FALSE;
    END get_custom_multichoice;

    FUNCTION get_event_value
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_value   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        l_sql    VARCHAR2(4000);
    
        -- *******************************************
        FUNCTION set_up_function
        (
            i_lang    IN NUMBER,
            i_prof    IN profissional,
            i_patient IN NUMBER,
            i_episode IN NUMBER,
            i_value   IN VARCHAR2
        ) RETURN VARCHAR2 IS
            k_mrk_lang             CONSTANT VARCHAR2(0100 CHAR) := '@I_LANG';
            k_mrk_prof_id          CONSTANT VARCHAR2(0100 CHAR) := '@I_PROF_ID';
            k_mrk_patient_id       CONSTANT VARCHAR2(0100 CHAR) := '@I_ID_PATIENT';
            k_mrk_episode_id       CONSTANT VARCHAR2(0100 CHAR) := '@I_ID_EPISODE';
            k_mrk_prof_institution CONSTANT VARCHAR2(0100 CHAR) := '@I_INSTITUTION';
            k_mrk_prof_software    CONSTANT VARCHAR2(0100 CHAR) := '@I_SOFTWARE';
            l_sql VARCHAR2(4000);
        BEGIN
        
            l_sql := i_value;
            l_sql := REPLACE(l_sql, k_mrk_lang, i_lang);
            l_sql := REPLACE(l_sql, k_mrk_prof_id, i_prof.id);
            l_sql := REPLACE(l_sql, k_mrk_prof_institution, i_prof.institution);
            l_sql := REPLACE(l_sql, k_mrk_prof_software, i_prof.software);
            l_sql := REPLACE(l_sql, k_mrk_patient_id, i_patient);
            l_sql := REPLACE(l_sql, k_mrk_episode_id, i_episode);
        
            RETURN l_sql;
        
        END set_up_function;
    
        -- *******************************************
        FUNCTION run_function(i_sql IN VARCHAR2) RETURN VARCHAR2 IS
            l_sql    VARCHAR2(4000);
            l_return VARCHAR2(4000);
        BEGIN
        
            IF i_sql IS NOT NULL
            THEN
                l_sql := pk_dyn_form_constant.get_crit_block_str(i_text => i_sql);
                EXECUTE IMMEDIATE l_sql
                    USING OUT l_return;
            END IF;
        
            RETURN l_return;
        
        END run_function;
    
    BEGIN
    
        IF i_value IS NOT NULL
        THEN
        
            l_sql := set_up_function(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_patient => i_patient,
                                     i_episode => i_episode,
                                     i_value   => i_value);
        
            l_return := run_function(i_sql => l_sql);
        
        END IF;
    
        RETURN l_return;
    
    END get_event_value;

    FUNCTION process_multi_form_result
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_episode   IN NUMBER,
        i_patient   IN NUMBER,
        i_root_name IN VARCHAR2,
        o_result    IN OUT t_tbl_ds_get_value,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN := TRUE;
    BEGIN
    
        CASE
            WHEN i_root_name IN (pk_orders_constant.g_ds_rehab_treatment,
                                 pk_orders_constant.g_ds_health_education_order,
                                 pk_orders_constant.g_ds_health_education_execution,
                                 pk_orders_constant.g_ds_health_education_order_execution,
                                 pk_orders_constant.g_ds_lab_test_request,
                                 pk_orders_constant.g_ds_imaging_exam_request,
                                 pk_orders_constant.g_ds_other_exam_request,
                                 pk_orders_constant.g_ds_procedure_request,
                                 pk_orders_constant.g_p1_appointment,
                                 pk_orders_constant.g_p1_lab_test,
                                 pk_orders_constant.g_p1_intervention,
                                 pk_orders_constant.g_p1_imaging_exam,
                                 pk_orders_constant.g_p1_other_exam,
                                 pk_orders_constant.g_p1_rehab,
                                 pk_orders_constant.g_ds_other_frequencies,
                                 pk_orders_constant.g_ds_to_execute,
                                 pk_orders_constant.g_ds_order_set_health_education,
                                 pk_orders_constant.g_ds_order_set_procedure) THEN
            
                l_bool := pk_orders_utils.process_multi_form(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_episode   => i_episode,
                                                             i_patient   => i_patient,
                                                             i_root_name => i_root_name,
                                                             o_result    => o_result,
                                                             o_error     => o_error);
            ELSE
                l_bool := TRUE;
        END CASE;
    
        RETURN l_bool;
    
    END process_multi_form_result;

BEGIN
    pk_alertlog.who_am_i(k_pck_owner, k_pck_name);
    pk_alertlog.log_init(k_pck_name);
END pk_dyn_form_values;
/
