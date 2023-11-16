/*-- Last Change Revision: $Rev: 2028769 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_api_ux IS

    /*
    * Creates a lab test order
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode id
    * @param     i_analysis_req              Lab tests' order id 
    * @param     i_harvest                   Harvest id
    * @param     i_analysis                  Lab tests' id
    * @param     i_analysis_group            Lab tests' id in a panel
    * @param     i_flg_type                  Type of the lab test: A - Lab test; G - group of lab tests
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
        i_harvest                 IN harvest.id_harvest%TYPE,
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar, --10
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar, --15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar, --20
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, --25
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar, --30
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar, --35
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --40
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number, --45
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number DEFAULT NULL,
        i_flg_task_depending      IN table_varchar DEFAULT NULL,
        i_episode_followup_app    IN table_number DEFAULT NULL,
        i_schedule_followup_app   IN table_number DEFAULT NULL, --50
        i_event_followup_app      IN table_number DEFAULT NULL,
        i_test                    IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_analysis_req_array      OUT NOCOPY table_number,
        o_analysis_req_det_array  OUT NOCOPY table_number,
        o_analysis_req_par_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_lab_test_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_exam.id_schedule%TYPE,
        i_analysis_req_det IN table_number,
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

    /*
    * Collects the given lab tests
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_body_location               Body part id
    * @param     i_collection_method           Collection method
    * @param     i_collection_room             Local of collection
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipient id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     i_flg_rep_collection          Flag that indicates if the user is collecting again
    * @param     i_rep_coll_reason             Repeat collection reason
    * @param     i_flg_orig_harvest            Flag that indicates the collection origin: A - Alert; I - Interfaces
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number, --5
        i_analysis_req_det          IN table_table_number,
        i_body_location             IN table_number,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar, --15
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_rep_collection        IN VARCHAR2,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE, --20
        i_revised_by                IN professional.id_professional%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_result
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_doc_external           IN table_table_number DEFAULT NULL,
        i_doc_type               IN table_table_number DEFAULT NULL,
        i_doc_ori_type           IN table_table_number DEFAULT NULL,
        i_title                  IN table_table_varchar DEFAULT NULL,
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        o_result                 OUT VARCHAR2,
        o_error                  OUT t_error_out
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
    * Updates a lab test result
    *                                                                         
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_analysis_result_par   Lab test result parameter id
    * @param     i_flg_relevant          Indication wether the result is marked as relevant
    * @param     i_notes                 Notes
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Ana Matos
    * @version   v2.7.1.0
    * @since     2017/04/05
    */

    FUNCTION set_lab_test_status_read
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN table_number,
        i_flg_relevant        IN table_varchar,
        i_notes               IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    * Edit harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_body_location               Body location id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipient id
    * @param     i_num_recipient               Number of recipient
    * @param     i_collect_time                Collection time 
    * @param     i_collection_amount           Collection amount   
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_edit
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number,
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Combine the given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_collection_method           Collection method
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_harvest                     Harvest id
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
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
    ) RETURN BOOLEAN;

    /*
    * Divides a given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_episode                     Episode id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_flg_divide                  Flag that indicates if the lab test harvest is to be divided or not: Y - Yes; N - No
    * @param     i_collection_method           Collection method
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_divide
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_analysis_harvest          IN table_table_number, --5
        i_flg_divide                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number, --10
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar, --15
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Divides a given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_flg_divide                  Flag that indicates if the lab test harvest is to be divided or not: Y - Yes; N - No
    * @param     i_flg_collect                 Flag that indicates if the lab test is to be collected or not: Y - Yes; N - No
    * @param     i_body_location               Body part id
    * @param     i_collection_method           Collection method
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_harvest                     Harvest id
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_divide_and_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN harvest.id_harvest%TYPE, --5
        i_analysis_harvest          IN table_table_number,
        i_analysis_req_det          IN table_table_number,
        i_flg_divide                IN table_varchar,
        i_flg_collect               IN table_varchar,
        i_collection_method         IN table_varchar, --10
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_body_location             IN table_number,
        i_sample_recipient          IN table_number, --15
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar, --20
        i_notes                     IN table_varchar,
        o_harvest                   OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_harvest_questionnaire
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_harvest          IN table_number,
        i_questionnaire    IN table_table_number,
        i_response         IN table_table_varchar,
        i_notes            IN table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req_det        IN table_number,
        i_flg_time                IN table_varchar, --5
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number, --10
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar, --15
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number, --20
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_lab_req                 IN table_number, --25
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --30
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar, --35
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_harvest
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN table_number,
        i_status  IN table_varchar,
        o_error   OUT t_error_out
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
        i_cancel_reason    IN analysis_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN analysis_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a given lab tests' harvest
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_episode         Episode id
    * @param     i_harvest         Harvest id
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_cancel_notes    Cancellation Notes
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION cancel_harvest
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
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
    
    * @return    true or false on success or error
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
        i_harvest      IN harvest.id_harvest%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
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
        o_list            OUT pk_types.cursor_type,
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

    /*
    * Public Function. Parâmetros de uma análise
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
    * @param     o_result_list        Cursor
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
        o_list             OUT pk_types.cursor_type,
        o_result_list      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_x_data           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_movement_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_preview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
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
        o_lab_test_order         OUT pk_types.cursor_type,
        o_lab_test_order_barcode OUT pk_types.cursor_type,
        o_lab_test_order_history OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
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
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail history
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
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
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test harvest detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_harvest                       Harvest id
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_harvest_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test harvest detail history
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_harvest                       Harvest id
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_harvest_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test harvest movement detail (with history detail)
    *
    * @param     i_lang                       Language id
    * @param     i_prof                       Professional
    * @param     i_harvest                    Harvest id
    * @param     o_lab_test_harvest           Cursor
    * @param     o_lab_test_harvest_history   Cursor
    * @param     o_error                      Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
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

    FUNCTION get_harvest
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_barcode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_lab_test_harvest OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the EPL code for a given harvest to be sent to the printer
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_harvest             Harvest id
    * @param     o_printer             Printer
    * @param     o_codification_type   Barcode type: EPL; ZPL
    * @param     o_barcode             Barcode
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/07/24
    */

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_harvest           IN table_number,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode           OUT VARCHAR2,
        o_error             OUT t_error_out
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

    FUNCTION get_harvest_to_collect
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN table_number,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_laboratory
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_sample_recipient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
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
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

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

    FUNCTION get_harvest_order_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for specimen collection method
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.4
    * @since     2014/05/06
    */

    FUNCTION get_harvest_method_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for specimen transportation
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/09/23
    */

    FUNCTION get_harvest_transport_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for collection repeating 
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5
    * @since     2011/01/17
    */

    FUNCTION get_harvest_reason_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
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
        i_lang  IN language.id_language%TYPE,
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

    FUNCTION get_lab_test_result_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_url
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_url_type         IN VARCHAR2,
        o_url              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_patient            IN patient.id_patient%TYPE,
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

    FUNCTION get_lab_test_param_unit_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_unit_measure       IN lab_tests_par_uni_mea.id_unit_measure%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_parameter_for_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_param     IN table_number,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_context_help
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis            IN table_varchar,
        i_analysis_result_par IN table_number,
        o_content             OUT table_varchar,
        o_map_target_code     OUT table_varchar,
        o_id_map_set          OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_print_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION add_print_list_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_print_arguments  IN table_varchar,
        o_print_list_job   OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

END pk_lab_tests_api_ux;
/
