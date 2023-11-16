CREATE OR REPLACE PACKAGE BODY alert.pk_dynamic_detail IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    /********************************************************************************************
    * Get Detail
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_area                   Detail Area
    * @param   i_id                     Detail identifier (can be any identifier, it depends on the detail area)
    * @param   o_detail                 Output cursor with detail data
    * @param   o_table_detail           Output cursor with detail table data (data that constructs tables inside detail)
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   02/10/2019
    ********************************************************************************************/
    FUNCTION get_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        i_id           IN NUMBER,
        o_detail       OUT pk_types.cursor_type,
        o_table_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_DETAIL';
    
    BEGIN
        IF i_area = g_area_out_on_pass
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_epis_out_on_pass.get_epis_out_on_pass_det(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_id_epis_out_on_pass => i_id,
                                                                o_detail              => o_detail,
                                                                o_error               => o_error);
        ELSIF i_area = g_area_med_error
        THEN
            RETURN pk_rt_med_pfh.get_med_errors_det(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_presc_error => i_id,
                                                    o_detail         => o_detail,
                                                    o_table_detail   => o_table_detail,
                                                    o_error          => o_error);
        ELSIF i_area = g_area_presc_dispense
        THEN
            RETURN pk_rt_med_pfh.get_presc_dispense_det(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_dispense  => i_id,
                                                        o_detail       => o_detail,
                                                        o_table_detail => o_table_detail,
                                                        o_error        => o_error);
        ELSIF i_area = g_area_presc
        THEN
            RETURN pk_rt_med_pfh.get_presc_detail(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_presc     => i_id,
                                                  o_detail       => o_detail,
                                                  o_table_detail => o_table_detail,
                                                  o_error        => o_error);
        ELSIF i_area = g_area_presc_task
        THEN
            RETURN pk_rt_med_pfh.get_presc_task_detail(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_id_presc_plan_task => i_id,
                                                       o_detail             => o_detail,
                                                       o_table_detail       => o_table_detail,
                                                       o_error              => o_error);
        ELSIF i_area = g_area_opinion
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_opinion.get_opinion_det(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_opinion => i_id,
                                              o_detail  => o_detail,
                                              o_error   => o_error);
        
        ELSIF i_area = g_area_hhc_request
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_hhc_core.get_hhc_req_det(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_root_name  => i_area,
                                               i_id_request => i_id,
                                               o_detail     => o_detail,
                                               o_error      => o_error);
        
        ELSIF i_area = g_area_pha_car
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_rt_pha_pfh.get_pha_car_det(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_pha_car => i_id,
                                                 o_detail     => o_detail,
                                                 o_error      => o_error);
        
        ELSIF i_area IN (g_area_exam_order_tech, g_area_exam_order)
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_exams_api_ux.get_exam_order_detail(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_id_record => i_id,
                                                         i_area      => i_area,
                                                         o_detail    => o_detail,
                                                         o_error     => o_error);
        
        ELSIF i_area = g_area_pha_car_model
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_rt_pha_pfh.get_pha_car_model_det(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_pha_car_model => i_id,
                                                       o_detail           => o_detail,
                                                       o_error            => o_error);
        ELSIF i_area = g_area_hhc_discharge
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_hhc_discharge.get_detail(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_hhc_discharge => i_id,
                                               o_detail           => o_detail,
                                               o_error            => o_error);
        ELSIF i_area = g_area_positioning
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_ux_inp_positioning.get_epis_positioning_detail(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_epis_positioning => i_id,
                                                                     o_hist                => o_detail,
                                                                     o_error               => o_error);
        ELSIF i_area = g_area_positioning_plan
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_ux_inp_positioning.get_epis_posit_plan_detail(i_lang                     => i_lang,
                                                                    i_prof                     => i_prof,
                                                                    i_id_epis_positioning_plan => i_id,
                                                                    i_flg_screen               => 'D',
                                                                    o_hist                     => o_detail,
                                                                    o_error                    => o_error);
        ELSIF i_area = g_area_blood_products
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_blood_products_api_ux.get_bp_detail_html(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_blood_product_det => i_id,
                                                               o_detail            => o_detail,
                                                               o_error             => o_error);
        ELSIF i_area = g_area_blood_type
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_lab_tests_api_db.get_pat_blood_type_detail(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_pat_blood_group => i_id,
                                                                 o_detail          => o_detail,
                                                                 o_error           => o_error);
        ELSIF i_area = g_area_presc_hm_review
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_rt_med_pfh.get_presc_hm_detail(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_episode => i_id,
                                                     o_detail     => o_detail,
                                                     o_error      => o_error);
        ELSIF i_area = g_area_presc_med_recon
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_rt_med_pfh.get_presc_mr_detail(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_episode => i_id,
                                                     o_detail     => o_detail,
                                                     o_error      => o_error);
        
        ELSIF i_area = g_area_complaint
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_complaint.get_epis_complaint_detail(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id,
                                                          o_detail     => o_detail,
                                                          o_error      => o_error);
        
        ELSIF i_area = g_area_health_education
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_patient_education_api_db.get_patient_education_det(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_id_nurse_tea_req => i_id,
                                                                         o_detail           => o_detail,
                                                                         o_error            => o_error);
        ELSIF i_area = g_area_external_referral
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_p1_ext_sys.get_p1_detail_html(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_ext_req    => i_id,
                                                    i_status_detail => NULL,
                                                    o_detail        => o_detail,
                                                    o_error         => o_error);
        ELSIF i_area = g_area_hand_off
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_hand_off_core.get_epis_prof_resp_detail(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_epis_prof_resp => i_id,
                                                              o_detail         => o_detail,
                                                              o_error          => o_error);
        ELSIF i_area = g_area_event
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_events.get_event_detail(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_consult_req => i_id,
                                              o_detail      => o_detail,
                                              o_error       => o_error);
        ELSIF i_area = g_area_consults
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_opinion.get_opin_prof(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_opinion => i_id,
                                            o_detail  => o_detail,
                                            o_error   => o_error);
        ELSIF i_area IN (g_rehab_treatment, g_rehab_session)
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_rehab.get_rehab_treatment_detail(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id     => i_id,
                                                       i_area   => i_area,
                                                       o_detail => o_detail,
                                                       o_error  => o_error);
        ELSIF i_area = pk_dynamic_detail.g_scheduled_mcdt
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            IF i_prof.software = pk_alert_constant.g_soft_labtech
            THEN
                RETURN pk_schedule_lab.get_sch_detail(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_schedule => i_id,
                                                      o_detail      => o_detail,
                                                      o_error       => o_error);
            ELSE
                RETURN pk_schedule_exam.get_sch_detail(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_schedule => i_id,
                                                       o_detail      => o_detail,
                                                       o_error       => o_error);
            END IF;
        ELSIF i_area = pk_dynamic_detail.g_scheduled_lab_test
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_schedule_lab.get_sch_detail(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_schedule => i_id,
                                                  o_detail      => o_detail,
                                                  o_error       => o_error);
        ELSIF i_area = pk_dynamic_detail.g_exams
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_exams_api_db.get_exam_detail(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_exam_req_det => i_id,
                                                   o_detail       => o_detail,
                                                   o_error        => o_error);
        
        ELSIF i_area = pk_dynamic_detail.g_lab_test_order
        THEN
            pk_types.open_my_cursor(o_table_detail);
        
            RETURN pk_lab_tests_core.get_lab_test_order_detail(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_analysis_req => i_id,
                                                               o_detail       => o_detail,
                                                               o_error        => o_error);
        
        ELSIF i_area = pk_dynamic_detail.g_follow_up_notes
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_paramedical_prof_core.get_followup_notes_detail(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_mng_followup => i_id,
                                                                      o_detail       => o_detail,
                                                                      o_error        => o_error);
        
        ELSIF i_area = 'COSIGN_DETAIL'
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_co_sign.get_co_sign_detail_ux(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_co_sign => i_id,
                                                    o_detail  => o_detail,
                                                    o_error   => o_error);
        ELSIF i_area = pk_dynamic_detail.g_procedures
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_procedures_api_db.get_procedure_detail(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_episode          => NULL,
                                                             i_interv_presc_det => i_id,
                                                             o_detail           => o_detail,
                                                             o_error            => o_error);
        
        ELSIF i_area = 'SAMPLE_TEXT'
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_sample_text.get_sample_text_detail(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_area        => i_area,
                                                         i_sample_text => i_id,
                                                         o_detail      => o_detail,
                                                         o_error       => o_error);
        ELSIF i_area = 'SAMPLE_TEXT2'
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_sample_text.get_sample_text_detail(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_area        => i_area,
                                                         i_sample_text => i_id,
                                                         o_detail      => o_detail,
                                                         o_error       => o_error);
        ELSIF i_area = pk_dynamic_detail.g_order_set_bo
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_order_sets.get_odst_detail(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_order_set => i_id,
                                                 o_detail    => o_detail,
                                                 o_error     => o_error);
        
        ELSIF i_area = pk_dynamic_detail.g_order_set_group
        THEN
            pk_types.open_my_cursor(o_table_detail);
            RETURN pk_task_groups.get_task_group_detail(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_task_group => i_id,
                                                        o_detail        => o_detail,
                                                        o_error         => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_table_detail);
            RETURN FALSE;
    END get_detail;

    /********************************************************************************************
    * Get Detail history
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_area                   Detail Area
    * @param   i_id                     Detail identifier (can be any identifier, it depends on the detail area)
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   02/10/2019
    ********************************************************************************************/
    FUNCTION get_detail_hist
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_area   IN VARCHAR2,
        i_id     IN NUMBER,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_DETAIL_HIST';
    
    BEGIN
        IF i_area = g_area_out_on_pass
        THEN
            RETURN pk_epis_out_on_pass.get_epis_out_on_pass_hist(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_id_epis_out_on_pass => i_id,
                                                                 o_detail              => o_detail,
                                                                 o_error               => o_error);
        ELSIF i_area = g_area_med_error
        THEN
            RETURN pk_rt_med_pfh.get_med_errors_hist(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_presc_error => i_id,
                                                     o_detail         => o_detail,
                                                     o_error          => o_error);
        ELSIF i_area = g_area_presc_dispense
        THEN
            RETURN pk_rt_med_pfh.get_presc_dispense_hist(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_dispense => i_id,
                                                         o_detail      => o_detail,
                                                         o_error       => o_error);
        ELSIF i_area = g_area_presc
        THEN
            RETURN pk_rt_med_pfh.get_presc_hist(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_id_presc => i_id,
                                                o_detail   => o_detail,
                                                o_error    => o_error);
        ELSIF i_area = g_area_presc_task
        THEN
            RETURN pk_rt_med_pfh.get_presc_task_hist(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_presc_plan_task => i_id,
                                                     o_detail             => o_detail,
                                                     o_error              => o_error);
        ELSIF i_area = g_area_hhc_request
        THEN
        
            RETURN pk_hhc_core.get_hhc_req_det_hist(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_tbl_id_req => table_number(i_id),
                                                    i_flg_report => pk_alert_constant.g_no,
                                                    o_detail     => o_detail,
                                                    o_error      => o_error);
        
        ELSIF i_area = g_area_opinion
        THEN
        
            RETURN pk_opinion.get_opinion_hist(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_opinion => i_id,
                                               o_detail  => o_detail,
                                               o_error   => o_error);
        
        ELSIF i_area = g_area_pha_car
        THEN
            RETURN pk_rt_pha_pfh.get_pha_car_hist(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_pha_car => i_id,
                                                  o_detail     => o_detail,
                                                  o_error      => o_error);
        
        ELSIF i_area IN (g_area_exam_order_tech, g_area_exam_order)
        THEN
            RETURN pk_exams_api_ux.get_exam_order_hist(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_id_record => i_id,
                                                       i_area      => i_area,
                                                       o_detail    => o_detail,
                                                       o_error     => o_error);
        
        ELSIF i_area = g_area_pha_car_model
        THEN
            RETURN pk_rt_pha_pfh.get_pha_car_model_hist(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_pha_car_model => i_id,
                                                        o_detail           => o_detail,
                                                        o_error            => o_error);
        ELSIF i_area = g_area_hhc_discharge
        THEN
            RETURN pk_hhc_discharge.get_detail_hist(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_id_hhc_discharge => i_id,
                                                    o_detail           => o_detail,
                                                    o_error            => o_error);
        
        ELSIF i_area = g_area_positioning
        THEN
            RETURN pk_ux_inp_positioning.get_epis_positioning_detail_hist(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_id_epis_positioning => i_id,
                                                                          o_hist                => o_detail,
                                                                          o_error               => o_error);
        ELSIF i_area = g_area_positioning_plan
        THEN
            RETURN pk_ux_inp_positioning.get_epis_posit_plan_detail(i_lang                     => i_lang,
                                                                    i_prof                     => i_prof,
                                                                    i_id_epis_positioning_plan => i_id,
                                                                    i_flg_screen               => 'H',
                                                                    o_hist                     => o_detail,
                                                                    o_error                    => o_error);
        ELSIF i_area = g_area_blood_products
        THEN
        
            RETURN pk_blood_products_api_ux.get_bp_detail_history_html(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_blood_product_det => i_id,
                                                                       o_detail            => o_detail,
                                                                       o_error             => o_error);
        ELSIF i_area = g_area_blood_type
        THEN
        
            RETURN pk_lab_tests_api_db.get_pat_blood_type_det_hist(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_pat_blood_group => i_id,
                                                                   o_detail          => o_detail,
                                                                   o_error           => o_error);
        ELSIF i_area = g_area_presc_hm_review
        THEN
            RETURN pk_rt_med_pfh.get_presc_hm_hist(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_episode => i_id,
                                                   o_detail     => o_detail,
                                                   o_error      => o_error);
        ELSIF i_area = g_area_presc_med_recon
        THEN
            RETURN pk_rt_med_pfh.get_presc_mr_hist(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_episode => i_id,
                                                   o_detail     => o_detail,
                                                   o_error      => o_error);
        ELSIF i_area = g_area_health_education
        THEN
            RETURN pk_patient_education_api_db.get_patient_education_det_hist(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_id_nurse_tea_req => i_id,
                                                                              o_detail           => o_detail,
                                                                              o_error            => o_error);
        ELSIF i_area = g_area_complaint
        THEN
            RETURN pk_complaint.get_epis_complaint_hist(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_episode => i_id,
                                                        o_detail     => o_detail,
                                                        o_error      => o_error);
        
        ELSIF i_area = g_area_hand_off
        THEN
        
            RETURN pk_hand_off_core.get_epis_prof_resp_history(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_epis_prof_resp => i_id,
                                                               o_detail         => o_detail,
                                                               o_error          => o_error);
        
        ELSIF i_area = g_area_event
        THEN
            RETURN pk_events.get_event_detail_hist(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_consult_req => i_id,
                                                   o_detail      => o_detail,
                                                   o_error       => o_error);
        ELSIF i_area = 'REHAB_TREATMENT'
        THEN
            RETURN pk_rehab.get_rehab_treatment_history(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_rehab_presc => i_id,
                                                        o_detail         => o_detail,
                                                        o_error          => o_error);
        ELSIF i_area = pk_dynamic_detail.g_scheduled_mcdt
        THEN
            IF i_prof.software = pk_alert_constant.g_soft_labtech
            THEN
                RETURN pk_schedule_lab.get_sch_hist(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_schedule => i_id,
                                                    o_detail      => o_detail,
                                                    o_error       => o_error);
            ELSE
                RETURN pk_schedule_exam.get_sch_hist(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_schedule => i_id,
                                                     o_detail      => o_detail,
                                                     o_error       => o_error);
            END IF;
        ELSIF i_area = pk_dynamic_detail.g_scheduled_lab_test
        THEN
            RETURN pk_schedule_lab.get_sch_hist(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_schedule => i_id,
                                                o_detail      => o_detail,
                                                o_error       => o_error);
        ELSIF i_area = pk_dynamic_detail.g_lab_test_order
        THEN
            RETURN pk_lab_tests_core.get_lab_test_order_detail(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_analysis_req => i_id,
                                                               o_detail       => o_detail,
                                                               o_error        => o_error);
        ELSIF i_area = pk_dynamic_detail.g_exams
        THEN
            RETURN pk_exams_api_db.get_exam_detail_history(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_exam_req_det => i_id,
                                                           o_detail       => o_detail,
                                                           o_error        => o_error);
        
        ELSIF i_area = pk_dynamic_detail.g_follow_up_notes
        THEN
            RETURN pk_paramedical_prof_core.get_followup_notes_hist(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_mng_followup => i_id,
                                                                    o_detail       => o_detail,
                                                                    o_error        => o_error);
        ELSIF i_area = 'COSIGN_DETAIL'
        THEN
        
            RETURN pk_co_sign.get_co_sign_detail_ux_h(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_co_sign => i_id,
                                                      o_detail  => o_detail,
                                                      o_error   => o_error);
        ELSIF i_area = pk_dynamic_detail.g_procedures
        THEN
            RETURN pk_procedures_api_db.get_procedure_detail_history(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_episode          => NULL,
                                                                     i_interv_presc_det => i_id,
                                                                     o_detail           => o_detail,
                                                                     o_error            => o_error);
        ELSIF i_area = pk_dynamic_detail.g_order_set_bo
        THEN
            RETURN pk_order_sets.get_odst_detail_hist(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_order_set => i_id,
                                                      o_detail    => o_detail,
                                                      o_error     => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_detail_hist;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_dynamic_detail;
/
