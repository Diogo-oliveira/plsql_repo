/*-- Last Change Revision: $Rev: 1982343 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-03-10 14:03:29 +0000 (qua, 10 mar 2021) $*/

CREATE OR REPLACE PACKAGE pk_api_analysis IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*
    * Creates a new lab test parameter
    *                                                                         
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_analysis             Lab test id
    * @param     i_sample_type          Sample type id
    * @param     i_desc_parameter       Parameter description
    * @param     i_flg_type             Parameter type: R - Result; T - Title
    * @param     i_flg_fill_type        Parameter filling type
    * @param     i_unit_measure         Unit measure id
    * @param     i_min_val              Minimum value
    * @param     i_max_val              Maximum value
    * @param     o_analysis_parameter   Lab test parameter id
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Ana Matos
    * @version   2.7.5.3
    * @since     2019/04/24
    */

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
    * Associates a new lab test order to a pre-existing harvest record                       
    *                                                                         
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab test order id                     
    * @param     i_harvest            Harvest id                         
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Cláudia Silva
    * @version   2.3.5                              
    * @since     2007/04/12                               
    */

    FUNCTION set_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*
    * Repeats a given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_visit                       Visit id
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_body_location               Body location id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition
    * @param     i_collection_room             Local of collection
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id    
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     i_rep_coll_reason             Repeat collection reason
    * @param     i_flg_orig_harvest            Flag that indicates the collection origin: A - Alert; I - Interfaces
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.3.1
    * @since     2018/04/02
    */

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
    ) RETURN BOOLEAN;
    /*
    * Rejects a given lab tests' harvest
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_patient              Patient id
    * @param     i_episode              Episode id
    * @param     i_harvest              Harvest id
    * @param     i_cancel_reason        Rejection reason id
    * @param     i_cancel_notes         Rejection notes
    * @param     i_specimen_condition   Specimen condition
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.4
    * @since     2014/05/12
    */

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
    ) RETURN BOOLEAN;

    /*
    * Updates an order to "With Result" status                      
    *                                                                         
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id  
    * @param     i_analysis_req_det   Lab test order id                     
    * @param     i_notes              Notes
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Ana Matos
    * @version   2.3.5                              
    * @since     2007/07/25                              
    */

    FUNCTION set_lab_test_result
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_notes            IN analysis_result.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*
    * Updates a lab test parameter
    *                                                                         
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_analysis             Lab test id
    * @param     i_sample_type          Sample type id
    * @param     i_analysis_parameter   Lab test parameter id
    * @param     i_desc_parameter       Parameter description
    * @param     i_rank                 Rank
    * @param     i_flg_available        Flag that indicates if the parameter is available or not
    * @param     i_unit_measure         Unit measure id
    * @param     i_min_val              Minimum value
    * @param     i_max_val              Maximum value
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Ana Matos
    * @version   2.7.5.3
    * @since     2019/04/24
    */

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

    FUNCTION update_harvest
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_harvest         IN harvest.id_harvest%TYPE,
        i_status          IN harvest.flg_status%TYPE,
        i_collected_by    IN harvest.id_prof_harvest%TYPE DEFAULT NULL,
        i_collection_time IN harvest.dt_harvest_tstz%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_barcode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        i_barcode_harvest  IN VARCHAR2,
        o_error            OUT t_error_out
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
        i_lang          IN language.id_language%TYPE, --1
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE, --5
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates a lab test parameter
    *                                                                         
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_analysis_parameter   Lab test parameter id
    * @param     i_analysis_result      Lab test result id
    * @param     i_cancel_reason        Cancel reason id
    * @param     i_cancel_notes         Cancellation Notes
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Ana Matos
    * @version   2.8.2.4
    * @since     2021/03/08
    */

    FUNCTION cancel_lab_test_result
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_analysis_result    IN analysis_result.id_analysis_result%TYPE,
        i_cancel_reason      IN analysis_result_par.id_cancel_reason%TYPE,
        i_notes_cancel       IN analysis_result_par.notes_cancel%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_by_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_content     IN VARCHAR2,
        i_flg_type    IN VARCHAR2,
        o_analysis    OUT analysis.id_analysis%TYPE,
        o_sample_type OUT sample_type.id_sample_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_cq_by_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_content  IN VARCHAR2,
        i_flg_type IN VARCHAR2,
        o_id       OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

END pk_api_analysis;
/
