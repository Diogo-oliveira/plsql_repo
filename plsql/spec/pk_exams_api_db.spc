/*-- Last Change Revision: $Rev: 2028685 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_exams_api_db IS

    /*
    * Creates an exam order
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode id
    * @param     i_exam_req                  Exams' order id 
    * @param     i_exam_req_det              Exams' order detail id 
    * @param     i_exam                      Exams' id
    * @param     i_dt_req                    Date that indicates when the exam was registered
    * @param     i_flg_type                  Type of the exam: E - exam; G - group of exams
    * @param     i_flg_time                  Flag that indicates when the exam is to be performed
    * @param     i_dt_begin                  Date for the exam to be performed
    * @param     i_dt_begin_limit            Date limit for the exam to be performed
    * @param     i_episode_destination       Episode destination id (when flg_time = 'N')
    * @param     i_order_recurrence          Order recurrence id
    * @param     i_priority                  Priority of the exam order
    * @param     i_flg_prn                   Flag that indicates if the order is PRN
    * @param     i_notes_prn                 PRN notes
    * @param     i_flg_fasting               Flag that indicates if the patient must be fasted or not
    * @param     i_notes                     General notes
    * @param     i_notes_scheduler           Scheduling notes
    * @param     i_notes_technician          Technician notes
    * @param     i_notes_patient             Patient notes    
    * @param     i_notes_diagnosis           Clinical indication notes
    * @param     i_diagnosis                 Clinical indication
    * @param     i_laterality                Laterality
    * @param     i_exec_room                 Execution room id    
    * @param     i_exec_institution          Perform institution id
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_clinical_purpose_notes    Clinical purpose notes
    * @param     i_codification              Exams' codification id
    * @param     i_health_plan               Exams' health plan id    
    * @param     i_exemption                 Exams' exemption id    
    * @param     i_prof_order                Professional that ordered the exam (co-sign)
    * @param     i_dt_order                  Date of the exam order (co-sign)
    * @param     i_order_type                Type of order (co-sign)  
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clinical questions notes 
    * @param     i_clinical_decision_rule    Clinical decision rule id
    * @param     i_flg_origin_req            Flag that indicates the module from which the exam is being ordered: D - Default, O - Order Sets, I - Interfaces
    * @param     i_task_dependency           Task dependency id
    * @param     i_flg_task_depending        Flag that indicates when the exam has a dependency
    * @param     i_episode_followup_app      Follow up episode id
    * @param     i_schedule_followup_app     Follow up schedule id
    * @param     i_event_followup_app        Follow up event id
    * @param     i_test                      Flag that indicates if the exam is really to be ordered
    * @param     o_flg_show                  Flag that indicates if there is a message to be shown
    * @param     o_msg_title                 Message title
    * @param     o_msg_req                   Message to be shown
    * @param     o_button                    Buttons to show
    * @param     o_exam_req_array            Exams' order id
    * @param     o_exam_req_det_array        Exams' order details id 
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/05/26
    */

    FUNCTION create_exam_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL,
        i_exam_req_det            IN table_number,
        i_exam                    IN table_number,
        i_flg_type                IN table_varchar,
        i_dt_req                  IN table_varchar,
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
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_laterality              IN table_varchar DEFAULT NULL,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar DEFAULT NULL,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number DEFAULT NULL,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_exam_req_array          OUT NOCOPY table_number,
        o_exam_req_det_array      OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_exam_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates an order with a result for a given exam
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_patient               Patient id
    * @param     i_episode               Episode id
    * @param     i_exam_req_det          Exam detail order id
    * @param     i_reg                   Periodic observation id
    * @param     i_exam                  Exams' id
    * @param     i_prof_performed        Professional perform id
    * @param     i_start_time            Exams' start time
    * @param     i_end_time              Exams' end time
    * @param     i_flg_result_origin     Flag that indicates what is the result's origin
    * @param     i_result_origin_notes   Result's origin notes
    * @param     i_notes                 Result notes
    * @param     i_flg_import            Flag that indicates if there is a document to import
    * @param     i_id_doc                Closing document id
    * @param     i_doc_type              Document type id
    * @param     i_desc_doc_type         Document type description
    * @param     i_dt_doc                Original document date
    * @param     i_dest                  Destination id
    * @param     i_desc_dest             Destination description
    * @param     i_ori_type              Document type id
    * @param     i_desc_ori_doc_type     Document type description
    * @param     i_original              Original document id
    * @param     i_desc_original         Original document description
    * @param     i_title                 Document description
    * @param     i_desc_perf_by          Performed by description
    * @param     o_exam_req              Exams' order id
    * @param     o_exam_req_det          Exams' order details id 
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/08
    */

    FUNCTION create_exam_with_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2,
        i_flg_pregnancy       IN VARCHAR2 DEFAULT 'N',
        i_result_status       IN result_status.id_result_status%TYPE DEFAULT NULL,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE,
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar,
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number,
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates a visit for an exam episode
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_patient          Patient id
    * @param     i_episode          Episode id
    * @param     i_schedule         Schedule id
    * @param     i_exam_req_det     Exam's order detail id 
    * @param     i_dt_begin         Visit begin date
    * @param     i_transaction_id   SCH 3.0 id
    * @param     o_episode          Episode id 
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/10/27
    */

    FUNCTION create_exam_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_schedule       IN schedule_exam.id_schedule%TYPE,
        i_exam_req_det   IN table_number,
        i_dt_begin       IN VARCHAR2 DEFAULT NULL,
        i_transaction_id IN VARCHAR2,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the perform information for a given order
    *
    * @param     i_lang                    Language id
    * @param     i_prof                    Professional
    * @param     i_exam_req_det            Exam detail order id
    * @param     i_prof_performed          Professional perform id
    * @param     i_start_time              Exams' start time
    * @param     i_end_time                Exams' end time
    * @param     i_supplies                Disposable supplies id
    * @param     i_qty_supplies            Disposable supplies quantity
    * @param     i_notes_supplies          Disposable supplies notes
    * @param     i_doc_template            Documentation template id
    * @param     i_flg_type                A - Agree, E - edit, N - new 
    * @param     i_id_documentation        Documentation id
    * @param     i_id_doc_element          Documentation element id
    * @param     i_id_doc_element_crit     Documentation element criteria id
    * @param     i_value                   Value
    * @param     i_id_doc_element_qualif   Element qualification id
    * @param     i_notes                   Notes
    * @param     o_error                   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/05/26
    */

    FUNCTION set_exam_perform
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
        i_prof_performed        IN exam_req_det.id_prof_performed%TYPE,
        i_start_time            IN VARCHAR2,
        i_end_time              IN VARCHAR2,
        i_supply_workflow       IN table_number,
        i_supply                IN table_number,
        i_supply_set            IN table_number,
        i_supply_qty            IN table_number,
        i_supply_type           IN table_varchar,
        i_barcode_scanned       IN table_varchar,
        i_deliver_needed        IN table_varchar,
        i_flg_cons_type         IN table_varchar,
        i_dt_expiration         IN table_varchar,
        i_flg_validation        IN table_varchar,
        i_lot                   IN table_varchar,
        i_notes_supplies        IN table_varchar,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        i_questionnaire         IN table_number,
        i_response              IN table_varchar,
        i_notes                 IN table_varchar,
        i_transaction_id        IN VARCHAR2 DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the result for a given exam request
    *
    * @param     i_lang                   Language id
    * @param     i_prof                    Professional
    * @param     i_patient                 Patient id
    * @param     i_episode                 Episode id
    * @param     i_exam_req_det            Exam detail order id
    * @param     i_exam_result             Exam result id
    * @param     i_dt_result               Exam result date
    * @param     i_result_status           Result status id
    * @param     i_abnormality             Flag that indicates the exam result abnormality
    * @param     i_flg_result_origin       Flag that indicates what is the result's origin
    * @param     i_result_origin_notes     Result's origin notes
    * @param     i_flg_import              Flag that indicates if there is a document to import
    * @param     i_id_doc                  Closing document id
    * @param     i_doc_type                Document type id
    * @param     i_desc_doc_type           Document type description
    * @param     i_dt_doc                  Original document date
    * @param     i_dest                    Destination id
    * @param     i_desc_dest               Destination description
    * @param     i_ori_type                Document type id
    * @param     i_desc_ori_doc_type       Document type description
    * @param     i_original                Original document id
    * @param     i_desc_original           Original document description
    * @param     i_title                   Document description
    * @param     i_desc_perf_by            Performed by description
    * @param     i_doc_template            Documentation template id
    * @param     i_flg_type                A - Agree, E - edit, N - new 
    * @param     i_id_documentation        Documentation id
    * @param     i_id_doc_element          Documentation element id
    * @param     i_id_doc_element_crit     Documentation element criteria id
    * @param     i_value                   Value
    * @param     i_id_doc_element_qualif   Element qualification id
    * @param     i_documentation_notes     Notes    
    * @param     o_exam_result             Exam result id
    * @param     o_error                   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/14
    */

    FUNCTION set_exam_result
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN exam_result.id_patient%TYPE,
        i_episode               IN exam_result.id_episode_write%TYPE,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
        i_exam_result           IN exam_req_det.id_exam_req_det%TYPE DEFAULT NULL,
        i_dt_result             IN VARCHAR2 DEFAULT NULL,
        i_result_status         IN result_status.id_result_status%TYPE,
        i_abnormality           IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin     IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes   IN exam_result.result_origin_notes%TYPE,
        i_flg_import            IN table_varchar,
        i_id_doc                IN table_number,
        i_doc_type              IN table_number,
        i_desc_doc_type         IN table_varchar,
        i_dt_doc                IN table_varchar,
        i_dest                  IN table_number,
        i_desc_dest             IN table_varchar,
        i_ori_doc_type          IN table_number,
        i_desc_ori_doc_type     IN table_varchar,
        i_original              IN table_number,
        i_desc_original         IN table_varchar,
        i_title                 IN table_varchar,
        i_desc_perf_by          IN table_varchar,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        o_exam_result           OUT exam_result.id_exam_result%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam status
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_exam_req_det      Exam detail order id
    * @param     i_status            New status
    * @param     i_notes             General notes
    * @param     i_notes_scheduler   Scheduling notes
    * @param     o_error             Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/03/23
    */

    FUNCTION set_exam_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN table_number,
        i_status          IN VARCHAR2,
        i_notes           IN table_varchar,
        i_notes_scheduler IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam status ('Read')
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req_det    Exam detail order id
    * @param     i_exam_result     Exam result id
    * @param     i_flg_relevant    Indication wether the result is marked as relevant
    * @param     i_diagnosis       Diagnosis id
    * @param     i_result_notes    Result notes id
    * @param     i_notes_result    Notes 
    * @param     o_error           Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/08/03
    */

    FUNCTION set_exam_status_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN table_number,
        i_exam_result   IN table_table_number,
        i_flg_relevant  IN table_table_varchar,
        i_diagnosis     IN pk_edis_types.table_in_epis_diagnosis DEFAULT NULL,
        i_result_notes  IN exam_result.id_result_notes%TYPE,
        i_notes_result  IN exam_result.notes_result%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Sets an exam date
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_exam_req          Exam order id
    * @param     i_dt_begin          Begin date
    * @param     i_notes_scheduler   Scheduling notes
    * @param     o_error             Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/10/28
    */

    FUNCTION set_exam_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req        IN exam_req.id_exam_req%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_notes_scheduler IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Fills exams grid task table
    *
    * @param      i_lang           Language
    * @param      i_prof           Profissional
    * @param      i_patient        Patient id
    * @param      i_episode        Episode id
    * @param      i_exam_req       Order exam id
    * @param      i_exam_req_det   Order exam detail id
    * @param      o_error          Error
    *
    * @return     boolean
    * @author     Ana Matos
    * @version    2.5
    * @since      2009/02/19
    */

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam order
    *
    * @param     i_lang                      Language
    * @param     i_prof                      Professional
    * @param     i_exam_req                  Exams' order id 
    * @param     i_exam_req_det              Exams' order detail id 
    * @param     i_exam                      Exams' id
    * @param     i_dt_begin                  Date for the exam to be performed
    * @param     i_priority                  Priority of the exam order
    * @param     i_flg_prn                   Flag that indicates if the order is PRN
    * @param     i_notes_prn                 PRN notes
    * @param     i_flg_fasting               Flag that indicates if the patient must be fasted or not
    * @param     i_notes                     General notes
    * @param     i_notes_scheduler           Scheduling notes
    * @param     i_notes_technician          Technician notes
    * @param     i_notes_patient             Patient notes    
    * @param     i_diagnosis                 Clinical indication
    * @param     i_laterality                Laterality
    * @param     i_exec_room                 Execution room id    
    * @param     i_exec_institution          Perform institution id
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_clinical_purpose_notes    Clinical purpose notes
    * @param     i_codification              Exams' codification id
    * @param     i_health_plan               Exams' health plan id    
    * @param     i_exemption                 Exams' exemption id    
    * @param     i_prof_order                Professional that ordered the exam (co-sign)
    * @param     i_dt_order                  Date of the exam order (co-sign)
    * @param     i_order_type                Type of order (co-sign)  
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clinical questions notes 
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Bruno Martins
    * @version   2.6.0.3.5
    * @since     2011/02/21
    */

    FUNCTION update_exam_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE,
        i_exam_req_det            IN table_number, --5
        i_exam                    IN table_number,
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --10
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, --15
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number, --20
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number, --25
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the result for a given exam result
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_patient               Patient id
    * @param     i_episode               Episode id
    * @param     i_exam_result           Exam result id
    * @param     i_result_status         Result status id
    * @param     i_flg_result_origin     Flag that indicates what is the result's origin
    * @param     i_result_origin_notes   Result's origin notes
    * @param     i_notes                 Result notes
    * @param     i_flg_import            Flag that indicates if there is a document to import
    * @param     i_id_doc                Closing document id
    * @param     i_doc_type              Document type id
    * @param     i_desc_doc_type         Document type description
    * @param     i_dt_doc                Original document date
    * @param     i_dest                  Destination id
    * @param     i_desc_dest             Destination description
    * @param     i_ori_type              Document type id
    * @param     i_desc_ori_doc_type     Document type description
    * @param     i_original              Original document id
    * @param     i_desc_original         Original document description
    * @param     i_title                 Document description
    * @param     i_desc_perf_by          Performed by description
    * @param     i_doc_template          Documentation template id
    * @param     i_flg_type              A - Agree, E - edit, N - new 
    * @param     i_id_documentation      Documentation id
    * @param     i_id_doc_element        Documentation element id
    * @param     i_id_doc_element_crit   Documentation element criteria id
    * @param     i_value                 Value
    * @param     i_id_doc_element_qualif Element qualification id
    * @param     i_notes                 Notes    
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.2.0
    * @since     2017/11/09
    */

    FUNCTION update_exam_result
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN exam_result.id_patient%TYPE,
        i_episode               IN exam_result.id_episode_write%TYPE,
        i_exam_result           IN exam_result.id_exam_result%TYPE,
        i_result_status         IN result_status.id_result_status%TYPE DEFAULT NULL,
        i_abnormality           IN exam_result.id_abnormality%TYPE DEFAULT NULL,
        i_flg_result_origin     IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes   IN exam_result.result_origin_notes%TYPE,
        i_flg_import            IN table_varchar,
        i_id_doc                IN table_number,
        i_doc_type              IN table_number,
        i_desc_doc_type         IN table_varchar,
        i_dt_doc                IN table_varchar,
        i_dest                  IN table_number,
        i_desc_dest             IN table_varchar,
        i_ori_doc_type          IN table_number,
        i_desc_ori_doc_type     IN table_varchar,
        i_original              IN table_number,
        i_desc_original         IN table_varchar,
        i_title                 IN table_varchar,
        i_desc_perf_by          IN table_varchar,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam date
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_exam_req          Exam order id
    * @param     i_dt_begin          New begin date
    * @param     i_notes_scheduler   Scheduling notes
    * @param     o_error             Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/08/31
    */

    FUNCTION update_exam_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req        IN table_number,
        i_dt_begin        IN table_varchar,
        i_notes_scheduler IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an exam order
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req        Exam order id
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_cancel_notes    Cancellation notes
    * @param     i_prof_order      Professional that ordered the exam cancelation (co-sign)
    * @param     i_dt_order        Date of the exam cancelation (co-sign)
    * @param     i_order_type      Type of cancelation (co-sign)  
    * @param     i_flg_schedule    Flag that indicates if there is an exam schedule to be cancelled
    * @param     o_error           Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/03
    */

    FUNCTION cancel_exam_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exam_req       IN table_number,
        i_cancel_reason  IN exam_req.id_cancel_reason%TYPE,
        i_cancel_notes   IN exam_req.notes_cancel%TYPE,
        i_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order       IN VARCHAR2,
        i_order_type     IN co_sign.id_order_type%TYPE,
        i_flg_schedule   IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an exam detail order
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req_det    Exam detail order id
    * @param     i_dt_cancel       Cancel date
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_cancel_notes    Cancellation notes
    * @param     i_prof_order      Professional that ordered the exam cancelation (co-sign)
    * @param     i_dt_order        Date of the exam cancelation (co-sign)
    * @param     i_order_type      Type of cancelation (co-sign)  
    * @param     i_flg_schedule    Flag that indicates if there is an exam schedule to be cancelled
    * @param     o_error           Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/10
    */

    FUNCTION cancel_exam_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN exam_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN exam_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_schedule     IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel the execution for a given exam request
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req_det    Exam request id
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_notes_cancel    Cancellation Notes
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Teresa Coutinho
    * @version   2.6.3.9
    * @since     2013/12/04
    */

    FUNCTION cancel_exam_perform
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN exam_req_det.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel the result for a given exam request
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req_det    Exam request id
    * @param     i_exam_result     Exam result id
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_notes_cancel    Cancellation Notes
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    João Ribeiro
    * @version   2.5
    * @since     2009/11/03
    */

    FUNCTION cancel_exam_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_exam_result   IN exam_result.id_exam_result%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN exam_result.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an exam scheduling
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_exam_req    Exam order id
    * @param     o_error       Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/03/25
    */

    FUNCTION cancel_exam_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the most frequent exams for a given professional
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_episode         Episode id
    * @param     i_exam_type       Exam type
    * @param     i_flg_type        Filter type
    * @param     i_codification    Exam codification id
    * @param     i_dep_clin_serv   Specialty id
    
    * @return    type
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/11
    */

    FUNCTION get_exam_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_flg_type      IN VARCHAR2 DEFAULT pk_exam_constant.g_exam_freq,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN t_tbl_exams_for_selection;

    /*
    * Returns a list with the results of the user search
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_exam_type       I/E - Image / Other exams
    * @param     i_codification    Exam codification id
    * @param     i_dep_clin_serv   Specialty id
    * @param     i_value           Search string
    
    * @return    type
    *
    * @author    Pedro Henriques
    * @version   2.8.2.4
    * @since     2021/03/07
    */

    FUNCTION get_exam_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_flg_type      IN exam_dep_clin_serv.flg_type%TYPE DEFAULT pk_exam_constant.g_exam_can_req,
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE,
        i_value         IN VARCHAR2
    ) RETURN t_table_exams_search;

    /*
    * Returns a list with the results of the user search
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_exam_type       I/E - Image / Other exams
    * @param     i_codification    Exam codification id
    * @param     i_dep_clin_serv   Specialty id
    * @param     i_value           Search string
    * @param     o_flg_show        Y/N
    * @param     o_msg_title       Message title
    * @param     o_msg             Message if the search results are more than the limit
    * @param     o_list            Cursor
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/11
    */

    FUNCTION get_exam_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_value         IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the exams' categories
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Exam order id
    * @param     i_exam_type       I/E - Image / Other exams
    * @param     i_codification    Exam codification id
    * @param     i_dep_clin_serv   Specialty id
    * @param     o_list            Cursor
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/10
    */

    FUNCTION get_exam_category_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the exams' within a given category
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Exam order id
    * @param     i_exam_cat        Exams' category id
    * @param     i_exam_type       I/E - Image / Other exams
    * @param     i_codification    Exam codification id
    * @param     o_list            Cursor
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/10
    */

    FUNCTION get_exam_in_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the exams within a given group
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_group     Exam group id
    * @param     i_codification   Exam codification id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/16
    */

    FUNCTION get_exam_in_group
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_group   IN exam_group.id_exam_group%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam order detail
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_exam_req             Exam order id
    * @param     o_exam_order           Cursor
    * @param     o_exam_order_barcode   Cursor
    * @param     o_exam_order_history   Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/07/12
    */

    FUNCTION get_exam_order_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_exam_req           IN exam_req.id_exam_req%TYPE,
        i_flg_report         IN VARCHAR2 DEFAULT 'N',
        o_exam_order         OUT pk_types.cursor_type,
        o_exam_order_barcode OUT pk_types.cursor_type,
        o_exam_order_history OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     i_flg_report                Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_detail                    Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/03
    */

    FUNCTION get_exam_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail history
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     i_flg_report                Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_detail                    Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_exam_detail_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the translation of exam alias if exists
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_code_exam       Exam code for translation
    * @param     i_dep_clin_serv   Dep_clin_serv id
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2008/04/21
    */

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /*
    * Returns a list of options for ordering an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_epis_type    Episode type id
    * @param     i_exam_type    Exam type
    * @param     o_list         Cursor
    * @param     o_error        Error message
    *
    * @value     i_exam_type    {*} I- Image {*} E- Other exams
    *
    * @return    true or false on success or error
    *
    * @author    Ana Monteiro
    * @version   2.6.4
    * @since     2014/08/26
    */
    FUNCTION get_exam_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of result notes options
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     o_result_notes   Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Vanessa Barsottelli
    * @version   2.6.1
    * @since     2012/02/09
    */

    FUNCTION get_exam_result_notes_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_result_notes OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_documents_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_question_response.id_exam_req_det%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_exams_api_db;
/
