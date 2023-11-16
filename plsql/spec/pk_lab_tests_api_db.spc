/*-- Last Change Revision: $Rev: 2028767 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_api_db IS

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
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_exec_institution        IN table_number, --30
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_lab_req                 IN table_number, --35
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --40
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar, --45
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar, --50
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
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
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_error            OUT t_error_out
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
    * @param     i_specimen_condition          Specimen condition id
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipient id
    * @param     i_num_recipient               Number of recipient
    * @param     i_collect_time                Collection time    
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
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number, --5
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar, --15
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN NUMBER,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE,
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN VARCHAR2,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
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

    FUNCTION set_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN analysis_result.id_patient%TYPE,
        i_episode                    IN analysis_result.id_episode%TYPE,
        i_analysis                   IN analysis.id_analysis%TYPE,
        i_sample_type                IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter         IN table_number,
        i_analysis_param             IN table_number,
        i_analysis_req_det           IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par           IN table_number,
        i_analysis_result_par        IN table_number,
        i_analysis_result_par_parent IN table_number,
        i_flg_type                   IN table_varchar,
        i_harvest                    IN harvest.id_harvest%TYPE,
        i_dt_sample                  IN VARCHAR2,
        i_prof_req                   IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result         IN VARCHAR2,
        i_flg_result_origin          IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes        IN analysis_result.result_origin_notes%TYPE,
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
        i_flg_intf_orig              IN analysis_result_par.flg_intf_orig%TYPE DEFAULT 'N',
        i_flg_orig_analysis          IN analysis_result.flg_orig_analysis%TYPE,
        i_clinical_decision_rule     IN NUMBER,
        o_result                     OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

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
    * Fills the lab tests grid task table
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id
    * @param     i_episode            Episode id
    * @param     i_analysis_req       Lab tests' order id
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.4.2
    * @since     2008/03/12
    */

    FUNCTION set_lab_test_grid_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN table_number,
        i_status           IN table_varchar,
        i_collected_by     IN table_number,
        i_collection_time  IN table_varchar,
        i_flg_orig_harvest IN harvest.flg_orig_harvest%TYPE,
        o_error            OUT t_error_out
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
        i_clinical_decision_rule IN analysis_result_par.id_cdr%TYPE,
        o_result                 OUT VARCHAR2,
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

    FUNCTION cancel_lab_test_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_cancel_reason       IN analysis_result_par.id_cancel_reason%TYPE,
        i_notes_cancel        IN analysis_result_par.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_lab_test_schedule
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        o_error        OUT t_error_out
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
        i_flg_type     IN VARCHAR2 DEFAULT 'M',
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE DEFAULT NULL,
        i_harvest      IN harvest.id_harvest%TYPE DEFAULT NULL
    ) RETURN t_tbl_lab_tests_for_selection;

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
        i_analysis_req IN analysis_req.id_analysis_req%TYPE DEFAULT NULL,
        i_harvest      IN harvest.id_harvest%TYPE DEFAULT NULL,
        i_value        IN VARCHAR2
    ) RETURN t_table_lab_tests_search;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
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
        o_list            OUT pk_types.cursor_type, --t_tbl_lab_tests_cat_search,
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
        o_list            OUT t_tbl_lab_tests_cat_search,
        o_error           OUT t_error_out
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
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

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

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        i_flg_report               IN VARCHAR2 DEFAULT 'N',
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
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
    * @author    Ana Monteiro
    * @version   2.6.4
    * @since     2014/09/02
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
    * Returns a list of options for the locations for performing a lab test
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_exam         Exams' id
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

    FUNCTION get_alias_translation
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_flg_type                  IN VARCHAR2 DEFAULT 'A',
        i_analysis_code_translation IN translation.code_translation%TYPE,
        i_sample_code_translation   IN translation.code_translation%TYPE,
        i_dep_clin_serv             IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_alias_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2 DEFAULT 'A',
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_unit_measure
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_access_permission
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN analysis.id_analysis%TYPE,
        i_flg_type IN group_access.flg_type%TYPE DEFAULT pk_lab_tests_constant.g_infectious_diseases_orders
    ) RETURN VARCHAR2;

    /*
    * Returns the number of parameters for complex lab tests
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id 
    
    * @return    String
    *
    * @author    Teresa Coutinho
    * @version   2.5.1.5
    * @since     2011/04/14
    */

    FUNCTION get_lab_test_result_parameters
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_blood_type_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_blood_type_det_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error           VARCHAR2(4000);
    g_error_code      VARCHAR2(100);

END;
/
