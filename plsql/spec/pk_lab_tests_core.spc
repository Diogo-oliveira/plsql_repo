/*-- Last Change Revision: $Rev: 2045844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:25:09 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_core IS

    /*
    * Creates a lab test order
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode id
    * @param     i_analysis_req              Lab tests' order id 
    * @param     i_analysis_req_det          Lab tests' order detail id 
    * @param     i_analysis_req_det_parent   Lab tests' order detail parent id 
    * @param     i_harvest                   Harvest id
    * @param     i_analysis                  Lab tests' id
    * @param     i_analysis_group            Lab tests' id in a panel
    * @param     i_flg_type                  Type of the lab test: A - Lab test; G - group of lab tests
    * @param     i_dt_req                    Order date
    * @param     i_flg_time                  Flag that indicates when the lab test is to be performed
    * @param     i_dt_begin                  Date for the lab test to be performed
    * @param     i_dt_begin_limit            Date limit for the lab test to be performed
    * @param     i_episode_destination       Episode destination id (when flg_time = 'N')
    * @param     i_order_recurrence          Order recurrence id
    * @param     i_priority                  Priority of the lab test order
    * @param     i_flg_prn                   Flag that indicates if the order is PRN
    * @param     i_notes_prn                 PRN notes
    * @param     i_specimen                  Spacimen id
    * @param     i_body_location             Body location id
    * @param     i_laterality                Laterality
    * @param     i_collection_room           Collection room id    
    * @param     i_notes                     General notes
    * @param     i_notes_scheduler           Scheduling notes
    * @param     i_notes_technician          Technician notes
    * @param     i_notes_patient             Patient notes
    * @param     i_diagnosis                 Clinical indication
    * @param     i_exec_institution          Perform institution id
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_clinical_purpose_notes    Clinical purpose notes
    * @param     i_flg_col_inst              Flag that indicates if the collection is to be done in the institution
    * @param     i_flg_fasting               Flag that indicates if the patient must be fasted or not
    * @param     i_lab_req                   Execution room id
    * @param     i_prof_cc                   Professionals who receive an email with the lab tests result (cc)
    * @param     i_prof_bcc                  Professionals who receive an email with the lab tests result (bcc)
    * @param     i_codification              Lab tests' codification id
    * @param     i_health_plan               Lab tests' health plan id    
    * @param     i_prof_order                Professional that ordered the lab test (co-sign)
    * @param     i_dt_order                  Date of the lab test order (co-sign)
    * @param     i_order_type                Type of order (co-sign)  
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clinical questions notes 
    * @param     i_clinical_decision_rule    Clinical decision rule id
    * @param     i_flg_origin_req            Flag that indicates the module from which the lab test is being ordered: D - Default, O - Order Sets, I - Interfaces
    * @param     i_task_dependency           Task dependency id
    * @param     i_flg_task_depending        Flag that indicates when the lab test has a dependency
    * @param     i_episode_followup_app      Follow up episode id
    * @param     i_schedule_followup_app     Follow up schedule id
    * @param     i_event_followup_app        Follow up event id
    * @param     i_test                      Flag that indicates if the lab test is really to be ordered
    * @param     o_flg_show                  Flag that indicates if there is a message to be shown
    * @param     o_msg_title                 Message title
    * @param     o_msg_req                   Message to be shown
    * @param     o_button                    Buttons to show
    * @param     o_analysis_req_array        Lab tests' order id
    * @param     o_analysis_req_det_array    Lab tests' order details id 
    * @param     o_analysis_req_par_array    Lab tests' order parameters id 
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

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
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar, --10
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
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar, --25
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --30
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar, --35
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --40
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, --45
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number, --50
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2, --55
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_analysis_req_array      OUT NOCOPY table_number,
        o_analysis_req_det_array  OUT NOCOPY table_number,
        o_analysis_req_par_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates a lab test order
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode id
    * @param     i_analysis_req              Lab tests' order id 
    * @param     i_analysis_req_det          Lab tests' order detail id 
    * @param     i_analysis_req_det_parent   Lab tests' order detail parent id 
    * @param     i_harvest                   Harvest id
    * @param     i_analysis                  Lab tests' id
    * @param     i_analysis_group            Lab tests' group id
    * @param     i_dt_req                    Order date
    * @param     i_flg_time                  Flag that indicates when the lab test is to be performed
    * @param     i_dt_begin                  Date for the lab test to be performed
    * @param     i_dt_begin_limit            Date limit for the lab test to be performed
    * @param     i_episode_destination       Episode destination id (when flg_time = 'N')
    * @param     i_order_recurrence          Order recurrence id
    * @param     i_priority                  Priority of the lab test order
    * @param     i_flg_prn                   Flag that indicates if the order is PRN
    * @param     i_notes_prn                 PRN notes
    * @param     i_specimen                  Spacimen id
    * @param     i_body_location             Body location id
    * @param     i_laterality                Laterality
    * @param     i_collection_room           Collection room id    
    * @param     i_notes                     General notes
    * @param     i_notes_scheduler           Scheduling notes
    * @param     i_notes_technician          Technician notes
    * @param     i_notes_patient             Patient notes
    * @param     i_diagnosis                 Clinical indication
    * @param     i_diagnosis_desc            Clinical indication description (when others)
    * @param     i_exec_institution          Perform institution id
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_clinical_purpose_notes    Clinical purpose notes
    * @param     i_flg_col_inst              Flag that indicates if the collection is to be done in the institution
    * @param     i_flg_fasting               Flag that indicates if the patient must be fasted or not
    * @param     i_lab_req                   Execution room id
    * @param     i_prof_cc                   Professionals who receive an email with the lab tests result (cc)
    * @param     i_prof_bcc                  Professionals who receive an email with the lab tests result (bcc)
    * @param     i_codification              Lab tests' codification id
    * @param     i_health_plan               Lab tests' health plan id    
    * @param     i_prof_order                Professional that ordered the lab test (co-sign)
    * @param     i_dt_order                  Date of the lab test order (co-sign)
    * @param     i_order_type                Type of order (co-sign)  
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clinical questions notes 
    * @param     i_clinical_decision_rule    Clinical decision rule id
    * @param     i_flg_origin_req            Flag that indicates the module from which the lab test is being ordered: D - Default, O - Order Sets, I - Interfaces
    * @param     i_task_dependency           Task dependency id
    * @param     i_flg_task_depending        Flag that indicates when the lab test has a dependency
    * @param     i_episode_followup_app      Follow up episode id
    * @param     i_schedule_followup_app     Follow up schedule id
    * @param     i_event_followup_app        Follow up event id
    * @param     o_analysis_req              Lab tests' order id
    * @param     o_analysis_req_det          Lab tests' order details id 
    * @param     o_analysis_req_par          Lab tests' order parameters id 
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION create_lab_test_request
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det        IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_det_parent IN analysis_req_det.id_ard_parent%TYPE,
        i_harvest                 IN harvest.id_harvest%TYPE,
        i_analysis                IN analysis.id_analysis%TYPE,
        i_analysis_group          IN analysis_group.id_analysis_group%TYPE, --10
        i_dt_req                  IN VARCHAR2,
        i_flg_time                IN analysis_req_det.flg_time_harvest%TYPE,
        i_dt_begin                IN VARCHAR2,
        i_dt_begin_limit          IN VARCHAR2,
        i_episode_destination     IN analysis_req_det.id_episode_destination%TYPE DEFAULT NULL, --15
        i_order_recurrence        IN analysis_req_det.id_order_recurrence%TYPE,
        i_priority                IN analysis_req_det.flg_urgency%TYPE,
        i_flg_prn                 IN analysis_req_det.flg_prn%TYPE,
        i_notes_prn               IN analysis_req_det.notes_prn%TYPE,
        i_specimen                IN analysis_req_det.id_sample_type%TYPE, --20
        i_body_location           IN table_number,
        i_laterality              IN table_varchar,
        i_collection_room         IN analysis_req_det.id_room%TYPE,
        i_notes                   IN analysis_req_det.notes%TYPE,
        i_notes_scheduler         IN analysis_req_det.notes_scheduler%TYPE, --25
        i_notes_technician        IN analysis_req_det.notes_tech%TYPE,
        i_notes_patient           IN analysis_req_det.notes_patient%TYPE,
        i_diagnosis_notes         IN analysis_req_det.diagnosis_notes%TYPE,
        i_diagnosis               IN pk_edis_types.rec_in_epis_diagnosis,
        i_exec_institution        IN analysis_req_det.id_exec_institution%TYPE, --30
        i_clinical_purpose        IN analysis_req_det.id_clinical_purpose%TYPE,
        i_clinical_purpose_notes  IN analysis_req_det.clinical_purpose_notes%TYPE,
        i_flg_col_inst            IN analysis_req_det.flg_col_inst%TYPE,
        i_flg_fasting             IN analysis_req_det.flg_fasting%TYPE,
        i_lab_req                 IN analysis_req_det.id_room_req%TYPE, --35
        i_prof_cc                 IN table_varchar,
        i_prof_bcc                IN table_varchar,
        i_codification            IN codification.id_codification%TYPE,
        i_health_plan             IN analysis_req_det.id_pat_health_plan%TYPE,
        i_exemption               IN analysis_req_det.id_pat_exemption%TYPE, --40
        i_prof_order              IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order                IN VARCHAR2,
        i_order_type              IN co_sign.id_order_type%TYPE,
        i_clinical_question       IN table_number,
        i_response                IN table_varchar, --45
        i_clinical_question_notes IN table_varchar,
        i_clinical_decision_rule  IN analysis_req_det.id_cdr%TYPE,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN analysis_req_det.id_task_dependency%TYPE DEFAULT NULL,
        i_flg_task_depending      IN VARCHAR2 DEFAULT pk_alert_constant.g_no, --50
        i_episode_followup_app    IN episode.id_episode%TYPE DEFAULT NULL,
        i_schedule_followup_app   IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_event_followup_app      IN consult_req.id_consult_req%TYPE DEFAULT NULL,
        o_analysis_req            OUT analysis_req.id_analysis_req%TYPE,
        o_analysis_req_det        OUT analysis_req_det.id_analysis_req_det%TYPE,
        o_analysis_req_par        OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_lab_test_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_lab_test_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_exam.id_schedule%TYPE,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det        IN table_number,
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar, --10
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number, --20
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis               IN table_clob, --25
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar, --30
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --35
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, --40
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number, --45
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE, --1
        i_prof                       IN profissional,
        i_patient                    IN analysis_result.id_patient%TYPE,
        i_episode                    IN analysis_result.id_episode%TYPE,
        i_analysis                   IN analysis.id_analysis%TYPE, --5
        i_sample_type                IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter         IN table_number,
        i_analysis_param             IN table_number,
        i_analysis_req_det           IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par           IN table_number, --10
        i_analysis_result_par        IN table_number,
        i_analysis_result_par_parent IN table_number,
        i_flg_type                   IN table_varchar,
        i_harvest                    IN harvest.id_harvest%TYPE,
        i_dt_sample                  IN VARCHAR2, --15
        i_prof_req                   IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result         IN VARCHAR2,
        i_flg_result_origin          IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes        IN analysis_result.result_origin_notes%TYPE,
        i_result_notes               IN analysis_result.notes%TYPE, --20
        i_loinc_code                 IN analysis_result.loinc_code%TYPE DEFAULT NULL,
        i_dt_ext_registry            IN table_varchar DEFAULT NULL,
        i_instit_origin              IN table_number DEFAULT NULL,
        i_result_value_1             IN table_varchar,
        i_result_value_2             IN table_number DEFAULT NULL, --25
        i_analysis_desc              IN table_number,
        i_doc_external               IN table_table_number DEFAULT NULL,
        i_doc_type                   IN table_table_number DEFAULT NULL,
        i_doc_ori_type               IN table_table_number DEFAULT NULL,
        i_title                      IN table_table_varchar DEFAULT NULL, --30
        i_comparator                 IN table_varchar DEFAULT NULL,
        i_separator                  IN table_varchar DEFAULT NULL,
        i_standard_code              IN table_varchar DEFAULT NULL,
        i_unit_measure               IN table_number,
        i_desc_unit_measure          IN table_varchar DEFAULT NULL, --35
        i_result_status              IN table_number,
        i_ref_val                    IN table_varchar DEFAULT NULL,
        i_ref_val_min                IN table_varchar,
        i_ref_val_max                IN table_varchar,
        i_parameter_notes            IN table_varchar, --40
        i_interface_notes            IN table_varchar DEFAULT NULL,
        i_laboratory                 IN table_number DEFAULT NULL,
        i_laboratory_desc            IN table_varchar DEFAULT NULL,
        i_laboratory_short_desc      IN table_varchar DEFAULT NULL,
        i_coding_system              IN table_varchar DEFAULT NULL, --45
        i_method                     IN table_varchar DEFAULT NULL,
        i_equipment                  IN table_varchar DEFAULT NULL,
        i_abnormality                IN table_number DEFAULT NULL,
        i_abnormality_nature         IN table_number DEFAULT NULL,
        i_prof_validation            IN table_number DEFAULT NULL, --50
        i_dt_validation              IN table_varchar DEFAULT NULL,
        i_flg_intf_orig              IN analysis_result_par.flg_intf_orig%TYPE DEFAULT 'N',
        i_flg_orig_analysis          IN analysis_result.flg_orig_analysis%TYPE,
        i_clinical_decision_rule     IN NUMBER,
        o_result                     OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE, --1
        i_prof                       IN profissional,
        i_patient                    IN analysis_result.id_patient%TYPE,
        i_episode                    IN analysis_result.id_episode%TYPE,
        i_analysis                   IN analysis.id_analysis%TYPE, --5
        i_sample_type                IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter         IN analysis_parameter.id_analysis_parameter%TYPE,
        i_analysis_param             IN analysis_param.id_analysis_param%TYPE,
        i_analysis_req_det           IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par           IN analysis_req_par.id_analysis_req_par%TYPE, --10
        i_analysis_result_par_parent IN analysis_result_par.id_arp_parent%TYPE,
        i_harvest                    IN harvest.id_harvest%TYPE,
        i_dt_sample                  IN VARCHAR2,
        i_prof_req                   IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result         IN VARCHAR2, --15
        i_flg_result_origin          IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes        IN analysis_result.result_origin_notes%TYPE,
        i_result_notes               IN analysis_result.notes%TYPE,
        i_loinc_code                 IN analysis_result.loinc_code%TYPE DEFAULT NULL,
        i_dt_ext_registry            IN VARCHAR2 DEFAULT NULL, --20
        i_instit_origin              IN analysis_result_par.id_instit_origin%TYPE DEFAULT NULL,
        i_result_value_1             IN analysis_result_par.desc_analysis_result%TYPE,
        i_result_value_2             IN analysis_result_par.analysis_result_value_2%TYPE DEFAULT NULL,
        i_analysis_desc              IN analysis_desc.id_analysis_desc%TYPE,
        i_doc_external               IN table_number DEFAULT NULL, --25
        i_doc_type                   IN table_number DEFAULT NULL,
        i_doc_ori_type               IN table_number DEFAULT NULL,
        i_title                      IN table_varchar DEFAULT NULL,
        i_comparator                 IN analysis_result_par.comparator%TYPE DEFAULT NULL,
        i_separator                  IN analysis_result_par.separator%TYPE DEFAULT NULL, --30
        i_standard_code              IN analysis_result_par.standard_code%TYPE DEFAULT NULL,
        i_unit_measure               IN unit_measure.id_unit_measure%TYPE,
        i_desc_unit_measure          IN analysis_result_par.desc_unit_measure%TYPE DEFAULT NULL,
        i_result_status              IN result_status.id_result_status%TYPE,
        i_ref_val                    IN analysis_result_par.ref_val%TYPE DEFAULT NULL, --35
        i_ref_val_min                IN analysis_result_par.ref_val_min_str%TYPE,
        i_ref_val_max                IN analysis_result_par.ref_val_max_str%TYPE,
        i_parameter_notes            IN analysis_result_par.parameter_notes%TYPE,
        i_interface_notes            IN analysis_result_par.interface_notes%TYPE DEFAULT NULL,
        i_laboratory                 IN analysis_result_par.id_laboratory%TYPE DEFAULT NULL, --40
        i_laboratory_desc            IN analysis_result_par.laboratory_desc%TYPE DEFAULT NULL,
        i_laboratory_short_desc      IN analysis_result_par.laboratory_short_desc%TYPE DEFAULT NULL,
        i_coding_system              IN analysis_result_par.coding_system%TYPE DEFAULT NULL,
        i_method                     IN analysis_result_par.method%TYPE DEFAULT NULL,
        i_equipment                  IN analysis_result_par.equipment%TYPE DEFAULT NULL, --45
        i_abnormality                IN analysis_result_par.id_abnormality%TYPE DEFAULT NULL,
        i_abnormality_nature         IN analysis_result_par.id_abnormality_nature%TYPE DEFAULT NULL,
        i_prof_validation            IN analysis_result_par.id_prof_validation%TYPE DEFAULT NULL,
        i_dt_validation              IN VARCHAR2 DEFAULT NULL,
        i_flg_intf_orig              IN analysis_result_par.flg_intf_orig%TYPE DEFAULT 'N', --50
        i_flg_orig_analysis          IN analysis_result.flg_orig_analysis%TYPE,
        i_clinical_decision_rule     IN NUMBER,
        o_result                     OUT VARCHAR2,
        o_id_result                  OUT analysis_result.id_analysis_result%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_doc_associated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN exam_result.id_patient%TYPE,
        i_episode              IN exam_result.id_episode%TYPE,
        i_analysis_req_det     IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_import           IN table_varchar,
        i_id_doc               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates a lab test order status (1 - Pending (P) -> Requested (R); 2 - Waiting (W) -> Requested (R) or Pending (P))
    *                                                                         
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab test order id
    * @param     i_status             Status to update
    * @param     i_dt_begin           Date to start
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Gustavo Serrano
    * @version   v2.6.0.3
    * @since     2010/05/27
    */

    FUNCTION set_lab_test_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_status           IN analysis_req_det.flg_status%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set lab test as read
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_analysis_result_par   Lab test result parameter id
    * @param     i_flg_relevant          Indication wether the result is marked as relevant
    * @param     i_notes                 Notes
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.1
    * @since     2009/04/24
    */

    FUNCTION set_lab_test_status_read
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN table_number,
        i_flg_relevant        IN table_varchar,
        i_notes               IN table_varchar,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_result_history
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result     IN analysis_result.id_analysis_result%TYPE,
        i_analysis_result_par IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the begining date for a lab test order                        
    *                                                                         
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_analysis_req_det  Lab test order id                     
    * @param     i_dt_begin          Date to start                         
    * @param     i_notes_scheduler   Scheduling notes
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Gustavo Serrano                        
    * @version   2.6.0.3                               
    * @since     2010/07/06                                
    */

    FUNCTION set_lab_test_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN VARCHAR2,
        i_notes_scheduler  IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Add new parameters to the lab test history view
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_analysis_param   Parameter id
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author     Ana Matos
    * @version    2.3.6.2
    * @since      2007/06/03                            
    */

    FUNCTION set_lab_test_timeline
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_analysis_param IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates a lab test order
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_analysis_req              Lab tests' order id
    * @param     i_analysis_req_det          Lab tests' order detail id
    * @param     i_flg_time                  Flag that indicates when the lab test is to be performed
    * @param     i_dt_begin                  Date for the lab test to be performed
    * @param     i_priority                  Priority of the lab test order
    * @param     i_flg_prn                   Flag that indicates if the order is PRN
    * @param     i_notes_prn                 PRN notes
    * @param     i_specimen                  Spacimen id
    * @param     i_body_location             Body location id
    * @param     i_collection_room           Collection room id    
    * @param     i_notes                     General notes
    * @param     i_notes_scheduler           Scheduling notes
    * @param     i_notes_technician          Technician notes
    * @param     i_notes_patient             Patient notes
    * @param     i_diagnosis                 Clinical indication
    * @param     i_diagnosis_desc            Clinical indication description (when others)
    * @param     i_exec_institution          Perform institution id
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_flg_col_inst              Flag that indicates if the collection is to be done in the institution
    * @param     i_flg_fasting               Flag that indicates if the patient must be fasted or not
    * @param     i_lab_req                   Execution room id
    * @param     i_prof_cc                   Professionals who receive an email with the lab tests result (cc)
    * @param     i_prof_bcc                  Professionals who receive an email with the lab tests result (bcc)
    * @param     i_codification              Lab tests' codification id
    * @param     i_health_plan               Lab tests' health plan id    
    * @param     i_prof_order                Professional that ordered the lab test (co-sign)
    * @param     i_dt_order                  Date of the lab test order (co-sign)
    * @param     i_order_type                Type of order (co-sign)  
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clinical questions notes 
    * @param     i_clinical_decision_rule    Clinical decision rule id
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION update_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det        IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --10
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar, --15
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --20
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar, --25
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --30
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, --35
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_lab_test_result
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN analysis_req.id_episode%TYPE,
        i_analysis_result_par    IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN VARCHAR2,
        i_dt_ext_registry        IN VARCHAR2 DEFAULT NULL,
        i_instit_origin          IN analysis_result_par.id_instit_origin%TYPE DEFAULT NULL,
        i_result_value_1         IN analysis_result_par.desc_analysis_result%TYPE,
        i_result_value_2         IN analysis_result_par.analysis_result_value_2%TYPE DEFAULT NULL,
        i_analysis_desc          IN analysis_desc.id_analysis_desc%TYPE,
        i_doc_external           IN table_number DEFAULT NULL,
        i_doc_type               IN table_number DEFAULT NULL,
        i_doc_ori_type           IN table_number DEFAULT NULL,
        i_title                  IN table_varchar DEFAULT NULL,
        i_comparator             IN analysis_result_par.comparator%TYPE DEFAULT NULL,
        i_separator              IN analysis_result_par.separator%TYPE DEFAULT NULL,
        i_standard_code          IN analysis_result_par.standard_code%TYPE DEFAULT NULL,
        i_unit_measure           IN analysis_result_par.id_unit_measure%TYPE,
        i_desc_unit_measure      IN analysis_result_par.desc_unit_measure%TYPE DEFAULT NULL,
        i_result_status          IN analysis_result_par.id_result_status%TYPE,
        i_ref_val                IN analysis_result_par.ref_val%TYPE DEFAULT NULL,
        i_ref_val_min            IN analysis_result_par.ref_val_min_str%TYPE,
        i_ref_val_max            IN analysis_result_par.ref_val_max_str%TYPE,
        i_parameter_notes        IN analysis_result_par.parameter_notes%TYPE,
        i_interface_notes        IN analysis_result_par.interface_notes%TYPE DEFAULT NULL,
        i_laboratory             IN analysis_result_par.id_laboratory%TYPE DEFAULT NULL,
        i_laboratory_desc        IN analysis_result_par.laboratory_desc%TYPE DEFAULT NULL,
        i_laboratory_short_desc  IN analysis_result_par.laboratory_short_desc%TYPE DEFAULT NULL,
        i_coding_system          IN analysis_result_par.coding_system%TYPE DEFAULT NULL,
        i_method                 IN analysis_result_par.method%TYPE DEFAULT NULL,
        i_equipment              IN analysis_result_par.equipment%TYPE DEFAULT NULL,
        i_abnormality            IN analysis_result_par.id_abnormality%TYPE DEFAULT NULL,
        i_abnormality_nature     IN analysis_result_par.id_abnormality_nature%TYPE DEFAULT NULL,
        i_prof_validation        IN analysis_result_par.id_prof_validation%TYPE DEFAULT NULL,
        i_dt_validation          IN VARCHAR2 DEFAULT NULL,
        i_flg_intf_orig          IN analysis_result_par.flg_intf_orig%TYPE DEFAULT 'N',
        i_clinical_decision_rule IN analysis_result_par.id_cdr%TYPE,
        o_result                 OUT VARCHAR2,
        o_id_result              OUT analysis_result.id_analysis_result%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_lab_test_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN table_varchar,
        i_notes_scheduler  IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates a patient blood type and group, if the lab test is configured
    * and the patient had no previous blood type/group inserted.
    * A patient doesn't change blood group/type over time but can only change
    * on some subtypes.
    * A wrong blood type/group can kill a patient so extra care is needed when
    * updating this table.
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_episode         Episode id
    * @param     i_analysis_result Lab test result id
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3
    * @since     2010/06/17
    */

    FUNCTION update_lab_test_blood_group
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_analysis_result IN analysis_result.id_analysis_result%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        i_flg_schedule     IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_yes,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_lab_test_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_cancel_reason       IN analysis_result_par.id_cancel_reason%TYPE,
        i_notes_cancel        IN analysis_result_par.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_lab_test_doc_associated
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_doc_external     IN doc_external.id_doc_external%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a scheduled lab test
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_analysis_req   Lab tests' order id 
    * @param     o_error          Error message
    
    * @return    string on success or error
    *
    * @author    Teresa Coutinho
    * @version   2.6.3.10.1
    * @since     2014/02/10
    */

    FUNCTION cancel_lab_test_schedule
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the lab tests selection list
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_episode        Episode id
    * @param     i_flg_type       Flag that indicates the type of list
    * @param     i_codification   Codification id
    * @param     i_analysis_req   Lab tests' order id 
    * @param     i_harvest        Harvest id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    type
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3 
    * @since     2010/06/07
    */

    FUNCTION get_lab_test_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_analysis_institution,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE
    ) RETURN t_tbl_lab_tests_for_selection;

    FUNCTION get_lab_test_all_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        i_flg_search_type IN VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the lab tests search list
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_codification   Codification id
    * @param     i_analysis_req   Lab tests' order id 
    * @param     i_harvest        Harvest id
    * @param     i_value          Search criteria
    
    * @return    type
    *
    * @author    Pedro Henriques
    * @version   2.8.2.4
    * @since     2021/03/07
    */

    FUNCTION get_lab_test_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        i_value        IN VARCHAR2
    ) RETURN t_table_lab_tests_search;

    /*
    * Returns the lab tests search list
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_codification   Codification id
    * @param     i_analysis_req   Lab tests' order id 
    * @param     i_harvest        Harvest id
    * @param     i_value          Search criteria
    * @param     o_flg_show       Flag that indicates if there is a message to be shown
    * @param     o_msg            Message to be shown
    * @param     o_msg_title      Message title
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3 
    * @since     2010/06/07
    */

    FUNCTION get_lab_test_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        i_value        IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns all lab tests' groups
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_analysis_req   Lab tests' order id 
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3 
    * @since     2010/06/08
    */

    FUNCTION get_lab_test_group_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns all lab tests' samples
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_exam_cat       Lab test category id
    * @param     i_codification   Codification id
    * @param     i_analysis_req   Lab tests' order id 
    * @param     i_harvest        Harvest id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3 
    * @since     2010/06/08
    */

    FUNCTION get_lab_test_sample_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns all lab tests' categories
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_patient           Patient id
    * @param     i_sample_type       Lab test sample type id
    * @param     i_exam_cat_parent   Lab test category id
    * @param     i_codification      Codification id
    * @param     i_analysis_req      Lab tests' order id 
    * @param     i_harvest           Harvest id
    * @param     o_list              Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3 
    * @since     2010/06/08
    */

    FUNCTION get_lab_test_category_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_category_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        o_list            OUT t_tbl_lab_tests_cat_search,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the lab tests parameter search list
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_value       Search criteria
    * @param     o_flg_show    Flag that indicates if there is a message to be shown
    * @param     o_msg         Message to be shown
    * @param     o_msg_title   Message title
    * @param     o_list        Cursor
    * @param     o_error       Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.5.0.6.3
    * @since     2009/10/12
    */

    FUNCTION get_lab_test_parameter_search
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns all lab tests available for selection
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_patient           Patient id
    * @param     i_sample_type       Lab test sample type id
    * @param     i_exam_cat          Lab test category id
    * @param     i_exam_cat_parent   Lab test category parent id
    * @param     i_codification      Codification id
    * @param     i_analysis_req      Lab tests' order id 
    * @param     i_harvest           Harvest id
    * @param     o_list              Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3 
    * @since     2010/06/09
    */

    FUNCTION get_lab_test_for_selection
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        o_list            OUT t_tbl_lab_tests_for_selection,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_in_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_in_group
    (
        i_lang           IN language.id_language%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        o_lab_test       OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the parameters of a lab test
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_analysis      Lab test id
    * @param     i_sample_type   Lab test sample type id
    * @param     o_list          Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.3.6.2
    * @since     2007/06/03
    */

    FUNCTION get_lab_test_parameter
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of lab tests' results for a patient within a visit (results view)
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id
    * @param     i_analysis_req_det   Lab tests' order detail id 
    * @param     i_flg_type           Flag that indicates which date is shown: H - Harvest date; R - Result date
    * @param     o_list               Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/09/02
    */

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        i_flg_report       IN VARCHAR2 DEFAULT 'N',
        o_list             OUT t_tbl_lab_tests_results,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns lab tests results of a patient for graph view
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     o_cursor_units        Check if there is more then one unit measure for the lab test parameter
    * @param     o_cursor_values       Lab test parameters values results (result values)
    * @param     o_cursor_ref_values   Lab test parameters reference values (min and max interval and reference values)
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Maia
    * @version   2.6.0.3
    * @since     2010/05/04
    */

    FUNCTION get_lab_test_timelineview
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_start_column       IN PLS_INTEGER,
        i_end_column         IN PLS_INTEGER,
        i_last_column_number IN PLS_INTEGER DEFAULT 6,
        o_list_results       OUT pk_types.cursor_type,
        o_list_columns       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_graphview
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        o_units_convert     OUT table_table_varchar,
        o_cursor_values     OUT pk_types.cursor_type,
        o_cursor_ref_values OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the horizontal scales for the timeline and episodes
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     id_tl_timeline       Timeline id
    * @param     id_tl_scale          Scale id
    * @param     i_block_req_number   Number of information blocks
    * @param     i_request_date       Begin date
    * @param     i_direction          Time direction: R-RIGHT, L-LEFT, B-BOTH
    * @param     i_patient            Patient id
    * @param     o_time_data          Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Maia
    * @version   2.6.0.3
    * @since     2010/05/17 
    */

    FUNCTION get_lab_test_graphview_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        id_tl_timeline     IN tl_timeline.id_tl_timeline%TYPE,
        id_tl_scale        IN tl_scale.id_tl_scale%TYPE,
        i_block_req_number IN NUMBER,
        i_request_date     IN VARCHAR2,
        i_direction        IN VARCHAR2 DEFAULT 'B',
        i_patient          IN NUMBER,
        o_time_data        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_questionnaire
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        i_room        IN room.id_room%TYPE,
        i_flg_type    IN VARCHAR2,
        i_flg_time    IN VARCHAR2,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_codification_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test order information with no result
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_patient       Patient id
    * @param     i_analysis      Lab test id
    * @param     i_sample_type   Sample type id
    * @param     o_list          Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/06/26
    */

    FUNCTION get_lab_test_no_result
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test order detail
    *
    * @param     i_lang                     Language id
    * @param     i_prof                     Professional
    * @param     i_analysis_req             Lab tests' order id
    * @param     i_flg_report               Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_lab_test_order           Cursor
    * @param     o_lab_test_order_barcode   Cursor
    * @param     o_lab_test_order_history   Cursor
    * @param     o_error                    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/06/26
    */

    FUNCTION get_lab_test_order_detail
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_analysis_req           IN analysis_req.id_analysis_req%TYPE,
        i_flg_report             IN VARCHAR2 DEFAULT 'N',
        o_lab_test_order         OUT pk_types.cursor_type,
        o_lab_test_order_barcode OUT pk_types.cursor_type,
        o_lab_test_order_history OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_order_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_flg_report   IN VARCHAR2 DEFAULT 'N',
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     i_flg_report                    Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT t_tbl_lab_tests_detail,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT t_tbl_lab_tests_cq,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_co_sign OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail history
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     i_flg_report                    Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT t_tbl_lab_tests_detail,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT t_tbl_lab_tests_cq,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test order detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_order
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test harvest detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_harvest
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test result detail
    *
    * @param     i_lang                         Language id
    * @param     i_prof                         Professional
    * @param     i_analysis_result_par          Lab test parameter result id
    * @param     o_lab_test_result              Cursor
    * @param     o_lab_test_result_laboratory   Cursor
    * @param     o_lab_test_result_history      Cursor
    * @param     o_error                        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_analysis_result_par        IN table_number,
        o_lab_test_result            OUT pk_types.cursor_type,
        o_lab_test_result_laboratory OUT pk_types.cursor_type,
        o_lab_test_result_history    OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_doc_associated
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_doc     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_to_edit
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN table_number,
        o_lab_test                    OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the lab test clinical question response to be edited
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.4.3
    * @since     2008/07/28
    */

    FUNCTION get_lab_test_response_to_edit
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_analysis_req_det            IN analysis_question_response.id_analysis_req_det%TYPE,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the lab test information to register the result
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id
    * @param     i_analysis           Lab test id
    * @param     i_sample_type        Sample type id
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_harvest            Harvest id
    * @param     i_analysis_result    Lab tests' result id
    * @param     i_flg_type           Flag that indicates if is a new result or an update
    * @param     o_lab_test           Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.5
    * @since     2009/04/24
    */

    FUNCTION get_lab_test_to_result
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis         IN analysis.id_analysis%TYPE,
        i_sample_type      IN sample_type.id_sample_type%TYPE,
        i_analysis_req_det IN table_number,
        i_harvest          IN harvest.id_harvest%TYPE,
        i_analysis_result  IN analysis_result.id_analysis_result%TYPE,
        i_flg_type         IN VARCHAR2,
        o_lab_test         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_to_read
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_lab_test         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_barcode_for_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for ordering a lab test
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_analysis_req   Lab tests' order id 
    * @param     i_harvest        Harvest id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3
    * @since     2010/06/10
    */

    FUNCTION get_lab_test_order_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for ordering a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_epis_type    Episode type id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for prioritizing a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_analysis     Array of id_analysis
    * @param     i_sample_type  Array of id_sample_type    
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_priority_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options with the diagnosis associated for a given episode
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_episode      Episode id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options with the clinical purpose for a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of prn options for a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of fasting options for a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/04
    */

    FUNCTION get_lab_test_fasting_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of specimen options for a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_analysis     Lab tests' id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/04
    */

    FUNCTION get_lab_test_specimen_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN table_number,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_specimen_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN analysis_sample_type.id_sample_type%TYPE,
        i_default     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    /*
    * Returns a list of body parts for a lab test
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_analysis      Lab tests' id
    * @param     i_sample_type   Sample type id
    * @param     i_value         Search criteria
    * @param     o_list          Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/04
    */

    FUNCTION get_lab_test_body_part_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        i_value       IN VARCHAR2,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for the locations for performing a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_analysis     Lab tests' id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_location_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        i_flg_type    IN analysis_room.flg_type%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_location_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_varchar,
        i_sample_type IN table_varchar,
        i_flg_type    IN analysis_room.flg_type%TYPE,
        i_default     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    /*
    * Returns a list of codification options for a lab test
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_analysis      Lab tests' id
    * @param     i_sample_type   Sample types' id
    * @param     o_list          Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/24
    */

    FUNCTION get_lab_test_codification_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of health plans for a patient
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_analysis     Lab tests' id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/04
    */

    FUNCTION get_lab_test_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of result options for a lab test
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_analysis             Lab tests' id
    * @param     i_sample_type          Sample type id
    * @param     i_analysis_parameter   Lab tests' parameter id
    * @param     o_list                 Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2012/11/16
    */

    FUNCTION get_lab_test_result_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_analysis_param IN analysis_param.id_analysis_param%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of statuses options for a lab test results
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3
    * @since     2010/05/05
    */

    FUNCTION get_lab_test_result_status
    (
        i_lang  IN language.id_language%TYPE, --1
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of result origin options for a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/05/05
    */

    FUNCTION get_lab_test_result_origin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of unit measure options for a lab test results
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_analysis             Lab tests' id
    * @param     i_sample_type          Sample type id
    * @param     i_analysis_parameter   Lab tests' parameter id
    * @param     o_list                 Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2012/11/16
    */

    FUNCTION get_lab_test_unit_measure_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Obter lista de profissionais
    *
    * @param      i_lang      number, default language
    * @param      i_prof      object type, health profisisonal
    * @param      o_list      varchar array
    * @param      o_error     erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     ASM
    * @version    0.1
    * @since      2007/07/16
    */

    FUNCTION get_lab_test_result_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_prof_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    /*
    * Returns the conversion value between diferent measure units for a specific lab test parameter
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_patient              Patient id
    * @param     i_analysis_parameter   Lab test parameter id
    * @param     i_unit_meas_src        Source unit measure
    * @param     i_unit_meas_dst        Destination unit measure
    * @param     i_values               Values for conversion
    * @param     o_list                 Converted values
    * @param     o_unit_measure_list    Unit measure list
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Maia
    * @version   2.6.0.3
    * @since     2010/05/13 
    */

    FUNCTION get_lab_test_unit_conversion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_unit_measure_src   IN unit_measure.id_unit_measure%TYPE,
        i_unit_measure_dst   IN unit_measure.id_unit_measure%TYPE,
        i_values             IN table_varchar,
        o_list               OUT table_varchar,
        o_unit_measure_list  OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the unit measures of a lab test parameter
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_patient              Patient id
    * @param     i_analysis_parameter   Lab test parameter id
    * @param     o_list                 Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Maia
    * @version   2.6.0.3
    * @since     2010/05/17 
    */

    FUNCTION get_lab_test_parameter_unit_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_unit_measure       IN lab_tests_par_uni_mea.id_unit_measure%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_analysis_result IN analysis_result.id_analysis_result%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_det_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_analysis_result IN analysis_result.id_analysis_result%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_default_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_result     IN OUT t_tbl_ds_get_value,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_lab_test_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no
    ) RETURN t_tbl_lab_tests_detail;

    FUNCTION tf_get_lab_test_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_flg_report   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_lab_test_order_detail;

    FUNCTION tf_get_lab_test_cq
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no
    ) RETURN t_tbl_lab_tests_cq;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_lab_tests_core;
/
