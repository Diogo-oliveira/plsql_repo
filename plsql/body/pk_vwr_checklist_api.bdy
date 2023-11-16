/*-- Last Change Revision: $Rev: 2006458 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-21 12:14:34 +0000 (sex, 21 jan 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_vwr_checklist_api IS

    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);

    k_nothing CONSTANT VARCHAR2(1 CHAR) := '';

    -- *********************************************************************************
    FUNCTION EXECUTE
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_api_name   IN VARCHAR2,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(0050 CHAR);
        o_error  t_error_out;
    BEGIN
    
        CASE i_api_name
        -- ****
            WHEN 'CHIEF_COMPLAINT' THEN
                l_result := pk_episode.get_complaint_viewer_checklist(i_lang,
                                                                      i_prof,
                                                                      i_scope_type,
                                                                      i_id_episode,
                                                                      i_id_patient);
            WHEN 'REASON_FOR_VISIT' THEN
                l_result := pk_episode.get_complaint_viewer_checklist(i_lang,
                                                                      i_prof,
                                                                      i_scope_type,
                                                                      i_id_episode,
                                                                      i_id_patient);
                -- ****
            WHEN 'HOME_MEDICATION' THEN
                l_result := pk_api_pfh_in.get_viewer_checklist_status_hm(i_lang,
                                                                         i_prof,
                                                                         i_scope_type,
                                                                         i_id_episode,
                                                                         i_id_patient);
            WHEN 'MEDICATIONS' THEN
                l_result := pk_api_pfh_in.get_viewer_checklist_status_lm(i_lang,
                                                                         i_prof,
                                                                         i_scope_type,
                                                                         i_id_episode,
                                                                         i_id_patient);
            WHEN 'DISCHARGE_MEDICATIONS' THEN
                l_result := pk_api_pfh_in.get_viewer_checklist_status_am(i_lang,
                                                                         i_prof,
                                                                         i_scope_type,
                                                                         i_id_episode,
                                                                         i_id_patient);
            WHEN 'PHARMACIST_VALIDATION' THEN
                l_result := pk_api_pfh_in.get_viewer_checklist_status_pv(i_lang,
                                                                         i_prof,
                                                                         i_scope_type,
                                                                         i_id_episode,
                                                                         i_id_patient);
            
        -- ****
            WHEN 'ALLERGIES' THEN
                l_result := pk_allergy.get_viewer_allergy_checklist(i_lang,
                                                                    i_prof,
                                                                    i_scope_type,
                                                                    i_id_episode,
                                                                    i_id_patient);
            
        -- ****
            WHEN 'DISCHARGE_DIAGNOSIS' THEN
                l_result := pk_diagnosis.get_diag_final_viewer_check(i_lang,
                                                                     i_prof,
                                                                     i_scope_type,
                                                                     i_id_episode,
                                                                     i_id_patient);
            WHEN 'DIFFERENTIAL_DIAGNOSES' THEN
                l_result := pk_diagnosis.get_diag_diff_viewer_check(i_lang,
                                                                    i_prof,
                                                                    i_scope_type,
                                                                    i_id_episode,
                                                                    i_id_patient);
            
        -- ****  Single page Notes
            WHEN 'CURRENT_VISIT' THEN
                l_result := pk_prog_notes_out.get_cv_vchecklist(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'HISTORY_AND_PHYSICAL' THEN
                l_result := pk_prog_notes_out.get_hp_vchecklist(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'PROGRESS_NOTES' THEN
                l_result := pk_prog_notes_out.get_pn_vchecklist(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'PHYSICIAN_PROGRESS_NOTES' THEN
                l_result := pk_prog_notes_out.get_pn_vchecklist(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'DISCHARGE_SUMMARY' THEN
                l_result := pk_prog_notes_out.get_ds_vchecklist(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'NURSING_ASSESSMENT' THEN
                l_result := pk_prog_notes_out.get_nsp_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'INITIAL_NURSING_ASSESSMENT' THEN
                l_result := pk_prog_notes_out.get_nia_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'NURSING_PROGRESS_NOTES' THEN
                l_result := pk_prog_notes_out.get_npn_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'VISIT_NOTE' THEN
                l_result := pk_prog_notes_out.get_crds_vchecklist(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
            WHEN 'INITIAL_NUTRITION_EVALUATION' THEN
                l_result := pk_prog_notes_out.get_dia_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'NUTRITION_PROGRESS_NOTE' THEN
                l_result := pk_prog_notes_out.get_dpn_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'NUTRITION_VISIT_NOTES' THEN
                l_result := pk_prog_notes_out.get_nvn_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'PHARMACIST_NOTES' THEN
                l_result := pk_prog_notes_out.get_phan_vchecklist(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
            WHEN 'INITIAL_RESPIRATORY_ASSESSMENT' THEN
                l_result := pk_prog_notes_out.get_ria_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'RESPIRATORY_THERAPY_PROGRESS_NOTES' THEN
                l_result := pk_prog_notes_out.get_rpn_vchecklist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
                -- ****
            WHEN 'LAB_TESTS' THEN
                l_result := pk_lab_tests_external_api_db.get_lab_test_viewer_checklist(i_lang,
                                                                                       i_prof,
                                                                                       i_scope_type,
                                                                                       i_id_episode,
                                                                                       i_id_patient);
            
        -- ****
            WHEN 'IMAGING_EXAMS' THEN
                l_result := pk_exams_external_api_db.get_imaging_viewer_checklist(i_lang,
                                                                                  i_prof,
                                                                                  i_scope_type,
                                                                                  i_id_episode,
                                                                                  i_id_patient);
            WHEN 'OTHER_EXAMS' THEN
                l_result := pk_exams_external_api_db.get_exams_viewer_checklist(i_lang,
                                                                                i_prof,
                                                                                i_scope_type,
                                                                                i_id_episode,
                                                                                i_id_patient);
            
        -- ****
            WHEN 'CO_SIGN' THEN
                l_result := pk_co_sign_api.get_co_sign_status(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'PRE_OPERATIVE' THEN
                l_result := pk_api_oris.get_sr_receive_status(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'PROPOSED_SURGERY' THEN
                l_result := pk_api_oris.get_proposed_sr_status(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'PRE_OPERATIVE_ASSESSMENT' THEN
                l_result := pk_api_oris.get_pre_op_eval_status(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'POST_OPERATIVE_ASSESSMENT' THEN
                l_result := pk_api_oris.get_post_op_eval_status(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'INTRA_OPERATIVE_ASSESSMENT' THEN
                l_result := pk_api_oris.get_intra_op_eval_status(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'INTERVENTION_RECORDS' THEN
                l_result := pk_api_oris.get_interv_rec_status(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'POSITIONINGS' THEN
                l_result := pk_api_oris.get_positionings_status(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'SURGICAL_SUPPLIES' THEN
                l_result := pk_api_sr_supplies.get_sr_supplies_status(i_lang,
                                                                      i_prof,
                                                                      i_scope_type,
                                                                      i_id_episode,
                                                                      i_id_patient);
            WHEN 'RESERVES' THEN
                l_result := pk_api_oris.get_reserves_viewer_check(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
            
        -- ****
            WHEN 'HOUSING' THEN
                l_result := pk_social.get_housing_viewer_check(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'SOCIO_DEMOGRAPHIC_DATA' THEN
                l_result := pk_social.get_demographic_viewer_check(i_lang,
                                                                   i_prof,
                                                                   i_scope_type,
                                                                   i_id_episode,
                                                                   i_id_patient);
            WHEN 'HOUSEHOLD_FINANCIAL_SITUATION' THEN
                l_result := pk_social.get_finance_viewer_check(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
        -- ****
            WHEN 'FOLLOW_UP_NOTES' THEN
                l_result := pk_paramedical_prof_core.get_followup_viewer_check(i_lang,
                                                                               i_prof,
                                                                               i_scope_type,
                                                                               i_id_episode,
                                                                               i_id_patient);
            WHEN 'CASE_MANAGEMENT_FOLLOW_UP' THEN
                l_result := pk_paramedical_prof_core.get_followup_viewer_check(i_lang,
                                                                               i_prof,
                                                                               i_scope_type,
                                                                               i_id_episode,
                                                                               i_id_patient);
            
            WHEN 'SOCIAL_SERVICES_REPORT' THEN
                l_result := pk_social.get_serv_report_viewer_check(i_lang,
                                                                   i_prof,
                                                                   i_scope_type,
                                                                   i_id_episode,
                                                                   i_id_patient);
            WHEN 'CASE_MANAGEMENT_PLAN' THEN
                l_result := pk_case_management.get_mng_plan_viewer_check(i_lang,
                                                                         i_prof,
                                                                         i_scope_type,
                                                                         i_id_episode,
                                                                         i_id_patient);
            
        -- ****
            WHEN 'HISTORY_OF_PRESENT_ILLNESS' THEN
                l_result := pk_documentation.get_vwr_hpi(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'REVIEW_OF_SYSTEMS' THEN
                l_result := pk_documentation.get_vwr_review_sys(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            WHEN 'FAMILY_HISTORY' THEN
                l_result := pk_documentation.get_vwr_family_hist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'SOCIAL_HISTORY' THEN
                l_result := pk_documentation.get_vwr_social_hist(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            WHEN 'TRIAGE' THEN
                l_result := pk_edis_triage.get_vwr_triage(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'DIAGNOSES' THEN
                l_result := pk_diagnosis.get_diagnoses_viewer_check(i_lang,
                                                                    i_prof,
                                                                    i_scope_type,
                                                                    i_id_episode,
                                                                    i_id_patient);
            WHEN 'SOCIAL_DIAGNOSES' THEN
                l_result := pk_diagnosis.get_diag_social_viewer_check(i_lang,
                                                                      i_prof,
                                                                      i_scope_type,
                                                                      i_id_episode,
                                                                      i_id_patient);
            
            WHEN 'SOCIAL_INTERVENTION_PLAN' THEN
                l_result := pk_social.get_vwr_social_interv_plan(i_lang,
                                                                 i_prof,
                                                                 i_scope_type,
                                                                 i_id_episode,
                                                                 i_id_patient);
            
            WHEN 'SOCIAL_DISCHARGE' THEN
                l_result := pk_social.get_vwr_social_discharge(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'PAST_MEDICAL_HISTORY' THEN
                l_result := pk_past_history.get_vwr_med_past_hist(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
                    WHEN 'PAST_SURGICAL_HISTORY' THEN
                l_result := pk_past_history.get_vwr_sug_past_hist(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);  
          WHEN 'NUTRITION_DIAGNOSES' THEN
                l_result := pk_diet.get_vwr_diag_diet(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            WHEN 'DIETS' THEN
                l_result := pk_diet.get_vwr_diet(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'CLINICAL_INDICATION_FOR_REHABILITATION' THEN
                l_result := pk_rehab.get_vwr_clinical_rehab(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'DISCHARGE_INSTRUCTIONS' THEN
                l_result := pk_discharge.get_vwr_disch_notes(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'END_OF_ENCOUNTER' THEN
                l_result := pk_case_management.get_vwr_end_of_enc(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
            
            WHEN 'PHYSICAL_EXAM' THEN
                l_result := pk_documentation.get_vwr_physical_exam(i_lang,
                                                                   i_prof,
                                                                   i_scope_type,
                                                                   i_id_episode,
                                                                   i_id_patient);
            WHEN 'PLAN' THEN
                l_result := pk_documentation.get_vwr_plan(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'PAST_HISTORY_PROBLEMS' THEN
                l_result := pk_problems.get_vwr_past_history_ph(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            
            WHEN 'PATIENT_INSTRUCTIONS' THEN
                l_result := pk_discharge.get_vwr_disch_notes(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'TRIAGE' THEN
                l_result := pk_edis_triage.get_vwr_triage(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'IMMUNIZATION_STATUS' THEN
                l_result := pk_immunization_core.get_vwr_vaccines(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
            
            WHEN 'VITAL_SIGNS_AND_INDICATORS' THEN
                l_result := pk_api_vital_sign.get_vwr_vs_monit(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'OTHER_EXAM_REFERRALS' THEN
                l_result := pk_ref_api.get_ref_ot_ex_viewer_checklist(i_lang,
                                                                      i_prof,
                                                                      i_id_patient,
                                                                      i_id_episode,
                                                                      i_scope_type);
            
            WHEN 'PROCEDURE_REFERRALS' THEN
                l_result := pk_ref_api.get_ref_proc_viewer_checklist(i_lang,
                                                                     i_prof,
                                                                     i_id_patient,
                                                                     i_id_episode,
                                                                     i_scope_type);
            
            WHEN 'PATIENT_EDUCATION' THEN
                l_result := pk_patient_education_api_db.get_pat_edu_viewer_checklist(i_lang,
                                                                                     i_prof,
                                                                                     i_id_patient,
                                                                                     i_id_episode,
                                                                                     i_scope_type);
            WHEN 'LAB_TEST_REFERRALS' THEN
                l_result := pk_ref_api.get_ref_lab_viewer_checklist(i_lang,
                                                                    i_prof,
                                                                    i_id_patient,
                                                                    i_id_episode,
                                                                    i_scope_type);
            
            WHEN 'IMAGING_EXAM_REFERRALS' THEN
                l_result := pk_ref_api.get_ref_exam_viewer_checklist(i_lang,
                                                                     i_prof,
                                                                     i_id_patient,
                                                                     i_id_episode,
                                                                     i_scope_type);
            
            WHEN 'CLINICAL_INDICATION_FOR_REHABILITATION' THEN
                l_result := pk_rehab_pbl.get_rehb_diag_viewer_checklit(i_lang,
                                                                       i_prof,
                                                                       i_id_patient,
                                                                       i_id_episode,
                                                                       i_scope_type);
            
            WHEN 'TREATMENT_SESSION' THEN
                l_result := pk_rehab_pbl.get_rehb_sess_viewer_checklit(i_lang,
                                                                       i_prof,
                                                                       i_id_patient,
                                                                       i_id_episode,
                                                                       i_scope_type);
            WHEN 'MEDICAL_DOCUMENTS' THEN
                l_result := pk_documentation.get_vwr_medic_legist(i_lang,
                                                                  i_prof,
                                                                  i_scope_type,
                                                                  i_id_episode,
                                                                  i_id_patient);
            WHEN 'PROCEDURES' THEN
                l_result := pk_procedures_external_api_db.get_procedure_viewer_checklist(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_scope_type => i_scope_type,
                                                                                         i_episode    => i_id_episode,
                                                                                         i_patient    => i_id_patient);
            WHEN 'NUTRITION_DISCHARGE' THEN
                l_result := pk_diet.get_vwr_nutri_discharge(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_scope_type => i_scope_type,
                                                            i_episode    => i_id_episode,
                                                            i_patient    => i_id_patient);
            WHEN 'PHYSICIAN_DISCHARGE' THEN
                l_result := pk_discharge.get_vwr_discharge(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'PSYCHOLOGY_VISIT_NOTES' THEN
                l_result := pk_prog_notes_out.get_vwr_psycho_visit_note(i_lang,
                                                                        i_prof,
                                                                        i_scope_type,
                                                                        i_id_episode,
                                                                        i_id_patient);
            
            WHEN 'PSYCHOLOGY_PROGRESS_NOTE' THEN
                l_result := pk_prog_notes_out.get_vwr_psycho_prog_note(i_lang,
                                                                       i_prof,
                                                                       i_scope_type,
                                                                       i_id_episode,
                                                                       i_id_patient);
            
            WHEN 'PSYCHOLOGY_DISCHARGE' THEN
                l_result := pk_paramedical_ux.get_vwr_psycho_discharge(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_scope_type => i_scope_type,
                                                                       i_episode    => i_id_episode,
                                                                       i_patient    => i_id_patient);
            
            WHEN 'PSYCHOLOGY_DIAGNOSES' THEN
                l_result := pk_paramedical_ux.get_vwr_psycho_diag(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_scope_type => i_scope_type,
                                                                  i_id_episode => i_id_episode,
                                                                  i_id_patient => i_id_patient);
            WHEN 'INITIAL_PSYCHOLOGY_EVALUATION' THEN
                l_result := pk_prog_notes_out.get_vwr_psycho_ia(i_lang,
                                                                i_prof,
                                                                i_scope_type,
                                                                i_id_episode,
                                                                i_id_patient);
            
            WHEN 'CDC_INITIAL_ASSESSMENT' THEN
                l_result := pk_prog_notes_out.get_vwr_cdc_ia(i_lang, i_prof, i_scope_type, i_id_episode, i_id_patient);
            
            WHEN 'CDC_VISIT_NOTES' THEN
                l_result := pk_prog_notes_out.get_vwr_cdc_visit_note(i_lang,
                                                                     i_prof,
                                                                     i_scope_type,
                                                                     i_id_episode,
                                                                     i_id_patient);
            WHEN 'CDC_PROGRESS_NOTE' THEN
                l_result := pk_prog_notes_out.get_vwr_cdc_prog_note(i_lang,
                                                                    i_prof,
                                                                    i_scope_type,
                                                                    i_id_episode,
                                                                    i_id_patient);
            
            WHEN 'CDC_DISCHARGE' THEN
                l_result := pk_paramedical_ux.get_vwr_cdc_discharge(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_scope_type => i_scope_type,
                                                                    i_episode    => i_id_episode,
                                                                    i_patient    => i_id_patient);
            
            ELSE
                l_result := k_nothing;
        END CASE;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => i_api_name,
                                              o_error    => o_error);
            RETURN NULL;
        
    END EXECUTE;

END pk_vwr_checklist_api;
/
