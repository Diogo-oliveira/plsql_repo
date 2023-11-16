/*-- Last Change Revision: $Rev: 2045844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:25:09 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_exam_core IS

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
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL, --5
        i_exam_req_det            IN table_number,
        i_exam                    IN table_number,
        i_flg_type                IN table_varchar,
        i_dt_req                  IN table_varchar,
        i_flg_time                IN table_varchar, --10
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar, --15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar, --20
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_clob,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_laterality              IN table_varchar, --25
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number, --30
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number, --35
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'D', --40
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number, --45
        i_test                    IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_exam_req_array          OUT NOCOPY table_number,
        o_exam_req_det_array      OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_exam_order
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_patient              IN patient.id_patient%TYPE,
        i_tbl_id_pk            IN table_number,
        i_tbl_data             IN table_table_varchar,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_tbl_val_array_desc   IN tt_table_varchar DEFAULT NULL,
        i_clinical_question_pk IN table_number,
        i_clinical_question    IN table_varchar,
        i_response             IN table_table_varchar,
        i_test                 IN VARCHAR2,
        i_flg_update           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_req              OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_exam_req_array       OUT NOCOPY table_number,
        o_exam_req_det_array   OUT NOCOPY table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates an order for a given exam
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exams' order detail id
    * @param     i_exam                      Exams' id
    * @param     i_exam_group                Exams' group id
    * @param     i_exam_codification         Exams' codification id
    * @param     i_flg_time                  Flag that indicates when the exam is to be performed
    * @param     i_dt_begin                  Date for the exam to be performed
    * @param     i_episode_destination       Episode destination id (when flg_time = 'N')
    * @param     i_priority                  Priority of the exam order
    * @param     i_notes                     General notes
    * @param     i_notes_scheduler           Scheduling notes
    * @param     i_notes_technician          Technician notes
    * @param     i_notes_patient             Patient notes
    * @param     i_protocols                 Surgigal protocols
    * @param     i_prof_cat_type             Professional category
    * @param     i_diagnosis                 Clinical indication
    * @param     i_exec_institution          Perform institution id
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_prof_order                Professional that ordered the exame (co-sign)
    * @param     i_dt_order                  Date of the exam order (co-sign)
    * @param     i_order_type                Type of order (co-sign)
    * @param     i_flg_origin_req            Flag that indicates the module from which the exam is being ordered: D - Default, O - Order Sets, I - Interfaces
    * @param     i_task_dependency           Task dependency id
    * @param     i_flg_task_depending        Flag that indicates when the exam has a dependency
    * @param     i_episode_followup_app      Follow up episode id
    * @param     i_schedule_followup_app     Follow up schedule id
    * @param     i_event_followup_app        Follow up event id
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clinical questions notes   
    * @param     i_flg_schedule              Flag that indicates if the exam is to be scheduled
    * @param     o_flg_show                  Flag that indicates if there is a message to be shown
    * @param     o_msg_title                 Message title
    * @param     o_msg_req                   Message to be shown
    * @param     o_button                    Buttons to show
    * @param     o_exam_req                  Exams' order id
    * @param     o_exam_req_det              Exams' order details id 
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/05/26
    *
    * @see Bruno Martins changes ALERT-100157 and ALERT-162793 i_dt_req was added
    */

    FUNCTION create_exam_request
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        i_exam                    IN exam.id_exam%TYPE,
        i_exam_group              IN exam_group.id_exam_group%TYPE,
        i_dt_req                  IN VARCHAR2 DEFAULT NULL,
        i_flg_time                IN exam_req.flg_time%TYPE,
        i_dt_begin                IN VARCHAR2,
        i_dt_begin_limit          IN VARCHAR2,
        i_episode_destination     IN exam_req.id_episode_destination%TYPE,
        i_order_recurrence        IN exam_req_det.id_order_recurrence%TYPE,
        i_priority                IN exam_req.priority%TYPE,
        i_flg_prn                 IN exam_req_det.flg_prn%TYPE,
        i_notes_prn               IN exam_req_det.prn_notes%TYPE,
        i_flg_fasting             IN exam_req_det.flg_fasting%TYPE,
        i_notes                   IN exam_req_det.notes%TYPE,
        i_notes_scheduler         IN exam_req_det.notes_scheduler%TYPE,
        i_notes_technician        IN exam_req_det.notes_tech%TYPE,
        i_notes_patient           IN exam_req_det.notes_patient%TYPE,
        i_diagnosis_notes         IN exam_req_det.diagnosis_notes%TYPE DEFAULT NULL,
        i_diagnosis               IN pk_edis_types.rec_in_epis_diagnosis,
        i_laterality              IN exam_req_det.flg_laterality%TYPE,
        i_exec_room               IN exam_req_det.id_room%TYPE,
        i_exec_institution        IN exam_req_det.id_exec_institution%TYPE,
        i_clinical_purpose        IN exam_req_det.id_clinical_purpose%TYPE,
        i_clinical_purpose_notes  IN exam_req_det.clinical_purpose_notes%TYPE,
        i_codification            IN codification.id_codification%TYPE,
        i_health_plan             IN exam_req_det.id_pat_health_plan%TYPE,
        i_exemption               IN exam_req_det.id_pat_exemption%TYPE,
        i_prof_order              IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order                IN VARCHAR2,
        i_order_type              IN co_sign.id_order_type%TYPE,
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar,
        i_clinical_decision_rule  IN exam_req_det.id_cdr%TYPE,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN exam_req_det.id_task_dependency%TYPE,
        i_flg_task_depending      IN VARCHAR2,
        i_episode_followup_app    IN episode.id_episode%TYPE,
        i_schedule_followup_app   IN schedule.id_schedule%TYPE,
        i_event_followup_app      IN consult_req.id_consult_req%TYPE,
        o_exam_req                OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det            OUT exam_req_det.id_exam_req_det%TYPE,
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

    FUNCTION create_exam_for_execution
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN exam_req.id_episode%TYPE,
        i_exam                  IN table_number,
        i_codification          IN table_number,
        i_flg_type              IN table_varchar,
        i_prof_performed        IN exam_req_det.id_prof_performed%TYPE,
        i_start_time            IN VARCHAR2,
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
        i_doc_flg_type          IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        i_questionnaire         IN table_number,
        i_response              IN table_varchar,
        i_notes                 IN table_varchar,
        o_exam_req_array        OUT NOCOPY table_number,
        o_exam_req_det_array    OUT NOCOPY table_number,
        o_error                 OUT t_error_out
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
        i_abnormality         IN exam_result.id_abnormality%TYPE DEFAULT NULL,
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
    * Creates an order with a result for a given exam
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_patient          Patient id
    * @param     i_episode          Episode id
    * @param     i_schedule         Schedule id
    * @param     i_exam_req_det     Exam's order detail id 
    * @param     i_transaction_id   SCH 3.0 id
    * @param     o_episode          Episode id
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/10/27
    *
    * @see added visit begin date
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
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN table_number,
        i_flg_time                IN table_varchar, --5
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_flg_fasting             IN table_varchar, --10
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar, --15
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
        i_clinical_question_notes IN table_table_varchar, --30
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets documentation values for the exams time out template. Prior to that, performs a
    * a verification for any "no" answers.
    *
    * @param     i_lang                    Language id
    * @param     i_prof                    Professional
    * @param     i_exam_req_det            Exam detail order id
    * @param     i_doc_area                Documentation area id
    * @param     i_doc_template            Template id
    * @param     i_epis_documentation      Episode documentation id
    * @param     i_flg_type                A - Agree, E - Edit, N - New 
    * @param     i_id_documentation        Documentation id
    * @param     i_id_doc_element          Documentation element id
    * @param     i_id_doc_element_crit     Documentation element criteria id
    * @param     i_value                   Value
    * @param     i_notes                   Notes
    * @param     i_id_doc_element_qualif   Element qualification id 
    * @param     i_epis_context            Context id
    * @param     i_summary_and_notes       Summary notes
    * @param     i_episode_context         Episode context id
    * @param     i_flg_test                Flag that indicates if is to proceed
    * @param     o_flg_show                Flag that indicates if there is a message to be shown
    * @param     o_msg_title               Message title
    * @param     o_msg_body                Message to be shown
    * @param     o_error                   Error message
    
    * @return    true or false on success or error
    *
    * @author    Jos� Castro
    * @version   2.6
    * @since     2010/08/27
    */

    FUNCTION set_exam_time_out
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_test              IN VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT sys_message.desc_message%TYPE,
        o_msg_body              OUT pk_types.cursor_type,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
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
    * @param     i_documentation_notes     Notes
    * @param     i_clinical_question       Clinical questions
    * @param     i_response                Response id
    * @param     i_notes                   Clinical questions notes 
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
    * Sets the result for a given exam request with document import
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_patient               Patient id
    * @param     i_episode               Episode id
    * @param     i_exam_req_det          Exam detail order id
    * @param     i_flg_result_origin     Flag that indicates what is the result's origin
    * @param     i_result_origin_notes   Result's origin notes
    * @param     i_notes                 Result notes
    * @param     i_external_doc          Images imported from the database
    * @param     i_external_doc_cancel   Images imported from the database to cancel
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/21
    */

    FUNCTION set_exam_import_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN exam_result.id_patient%TYPE,
        i_episode             IN exam_result.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN table_varchar,
        i_external_doc        IN table_number,
        i_external_doc_cancel IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Associates documents to a given exam request
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_exam_req_det        Exam detail order id
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     i_ext_req             External request id
    * @param     i_doc_type            Document type id
    * @param     i_desc_doc_type       Document type description
    * @param     i_dt_doc              Original document date
    * @param     i_dest                Destination id
    * @param     i_desc_dest           Destination description
    * @param     i_ori_type            Document type id
    * @param     i_desc_ori_doc_type   Document type description
    * @param     i_original            Original document id
    * @param     i_desc_original       Original document description
    * @param     i_btn                 Context
    * @param     i_title               Document description
    * @param     i_desc_perf_by        Performed by description
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/15
    */

    /*FUNCTION set_exam_doc_associated
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN exam_result.id_patient%TYPE,
        i_episode           IN exam_result.id_episode%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_import        IN table_varchar,
        i_id_doc            IN table_number,
        i_doc_type          IN table_number,
        i_desc_doc_type     IN table_varchar,
        i_dt_doc            IN table_varchar,
        i_dest              IN table_number,
        i_desc_dest         IN table_varchar,
        i_ori_doc_type      IN table_number,
        i_desc_ori_doc_type IN table_varchar,
        i_original          IN table_number,
        i_desc_original     IN table_varchar,
        i_title             IN table_varchar,
        i_desc_perf_by      IN table_varchar,
        i_notes             IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;*/

    FUNCTION set_exam_doc_associated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN exam_result.id_patient%TYPE,
        i_episode              IN exam_result.id_episode%TYPE,
        i_exam_req_det         IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_import           IN table_varchar,
        i_id_doc               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Insert to exam result history
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_result     Exam result id
    * @param     o_error           Error message
    
    * @return    true on success or false on error
    *
    * @author    Vanessa Barsottelli
    * @version   2.6.1
    * @since     2012/02/15
    */

    FUNCTION set_exam_result_history
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam_result IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam status
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req_det    Exam detail order id
    * @param     i_status          New status
    * @param     o_error           Error message
    
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
    * @since     2009/08/03set_exam_status_read
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

    FUNCTION set_exam_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_questionnaire IN table_number,
        i_response      IN table_varchar,
        i_notes         IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam order
    *
    * @param     i_lang                      Language
    * @param     i_prof                      Professional
    * @param     i_exam_req                  Exams' order id 
    * @param     i_exam_req_det              Exams' order detail id 
    * @param     i_exam                      Exams' id
    * @param     i_flg_time                  Flag that indicates when the exam is to be performed
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
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --10
        i_notes_prn               IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar, --15
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number, --20
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --25
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
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
    * @param     i_supply                  Disposable supplies id
    * @param     i_supply_qty              Disposable supplies quantity
    * @param     i_supply_notes            Disposable supplies notes
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
    * @author    Teresa Coutinho
    * @version   2.6.3.9
    * @since     2013/12/06
    */

    FUNCTION update_exam_perform
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
    * @param     i_btn                   Context
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
    * @version   2.5
    * @since     2010/05/04
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
        i_btn                   IN sys_button_prop.id_sys_button_prop%TYPE,
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
    * @author    Jo�o Ribeiro
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

    FUNCTION cancel_exam_doc_associated
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
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
        i_flg_type      IN VARCHAR2 DEFAULT pk_exam_constant.g_exam_institution,
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
        i_flg_type      IN exam_dep_clin_serv.flg_type%TYPE DEFAULT pk_exam_constant.g_exam_can_req,
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
    * Returns a list of body parts and exams
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_mcs_concept    Mcs Concept relation to be used in order to get the childs  
    *                             (o_body_structure_list) and also all exams configured (o_exams_list)
    * @param     i_exam_cat       Exams' category id
    * @param     i_exam_type      I/E - Image / Other exams
    * @param     i_codification   Exam codification id
    * @param     o_list           Cursor
    * @param     o_exams_list     Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Jos� Castro
    * @version   2.6.0.3
    * @since     2010/05/27
    */

    FUNCTION get_exam_body_part_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_mcs_concept  IN body_structure_rel.id_mcs_concept%TYPE,
        i_exam_cat     IN exam.id_exam_cat%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_exam_list    OUT pk_types.cursor_type,
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
    * Returns the exams' ids within a given group
    *
    * @param     i_lang         Language id
    * @param     i_exam_group   Exam group id
    * @param     o_exam         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/16
    */

    FUNCTION get_exam_in_group
    (
        i_lang       IN language.id_language%TYPE,
        i_exam_group IN exam_group.id_exam_group%TYPE,
        o_exam       OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of exams for a patient within a visit (thumbnail view)
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_patient       Patient id
    * @param     i_episode       Episode id
    * @param     i_exam_type     Exam type: I - image; E - other exam
    * @param     o_exam_list     Cursor
    * @param     o_filter_list   Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/05/26
    */

    FUNCTION get_exam_thumbnailview
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN exam_req.id_episode%TYPE,
        i_exam_type   IN exam.flg_type%TYPE,
        o_exam_list   OUT pk_types.cursor_type,
        o_filter_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of exams for a patient (timeline view)
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_patient       Patient id
    * @param     i_exam_type     Exam type: I - image; E - other exam
    * @param     o_time_list     Cursor
    * @param     o_exam_list     Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/03/15
    */

    FUNCTION get_exam_timelineview
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_time_list OUT pk_types.cursor_type,
        o_exam_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of exam's orders for a given patient
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/03/18
    */

    FUNCTION get_exam_orders
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_exam    IN exam.id_exam%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_questionnaire
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_exam     IN exam.id_exam%TYPE,
        i_flg_type IN VARCHAR2,
        i_flg_time IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns if for a given exam_req_det and epis_documentation, the time out template is 
    * completed or not.
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_exam_req_det         Exam detail order id
    * @param     i_epis_documentation   Episode documentation id
    * @param     o_flg_complete         Flag that indicates if the time out template is completed or not
    * @param     o_error                Error message
    *
    * @return    true or false on success or error
    *                        
    * @author    Jos� Castro
    * @version   2.6
    * @since     2010/09/23
    */

    FUNCTION get_exam_time_out_completion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_exam_req_det       IN exam_req_det.id_exam_req_det%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_complete       OUT exam_time_out.flg_complete%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of images for a given exam order detail id
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/05/26
    */

    FUNCTION get_exam_images
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req.id_exam_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of information nedded when ordering a P1
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/09/09
    */

    FUNCTION get_exam_codification_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
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

    FUNCTION get_exam_order_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_record IN exam_req.id_exam_req%TYPE,
        i_area      IN dd_content.area%TYPE,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_order_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_record IN exam_req.id_exam_req%TYPE,
        i_area      IN dd_content.area%TYPE,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
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
        i_episode      IN episode.id_episode%TYPE,
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
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the information for a given exam order
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     o_exam                      Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/06/04
    */

    FUNCTION get_exam_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the perform information for a given exam request
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     o_exam                      Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/01
    */

    FUNCTION get_exam_perform
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the result information for a given exam request
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    * @param     o_exam           Cursor
    * @param     o_exam_result    Cursor    
    * @param     o_exam_images    Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/14
    */

    FUNCTION get_exam_result
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_exam         OUT pk_types.cursor_type,
        o_exam_result  OUT pk_types.cursor_type,
        o_exam_images  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the documents associated to a given exam request
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    * @param     o_exam_doc       Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/17
    */

    FUNCTION get_exam_doc_associated
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_to_edit
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN table_number,
        o_exam                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of documents to import
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_episode      Episode id
    * @param     i_exam         Exam id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/20
    */

    FUNCTION get_exam_import_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_exam    IN exam.id_exam%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of request types to be used on exam search
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional structure
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Jos� Castro
    * @version   2.6.0.3
    * @since     2010/06/02
    */

    FUNCTION get_exam_order_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_filter_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/19
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
    * Returns a list of options for prioritizing an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_exam         Array of id_exam     
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/23
    */
    FUNCTION get_exam_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exam  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_default_priority
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_exam       IN exam.id_exam%TYPE,
        i_value      IN OUT VARCHAR2,
        i_desc_value IN OUT VARCHAR2
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
    * @version   2.5
    * @since     2009/08/31
    */

    FUNCTION get_exam_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for the locations for performing an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_exam         Exams' id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/06/19
    */

    FUNCTION get_exam_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exam  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_location
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_exams   IN table_number,
        i_default IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    /*
    * Returns a list of options with the clinical purpose for an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/06/03
    */

    FUNCTION get_exam_clinical_purpose_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of prn options for an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/31
    */

    FUNCTION get_exam_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of fasting options for an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/31
    */

    FUNCTION get_exam_fasting_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of codification options for a given exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_exam         Exam id
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6
    * @since     2018/05/24
    */

    FUNCTION get_exam_codification_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exam  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_codification_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exams       IN VARCHAR2,
        i_flg_default IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    FUNCTION get_exam_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the time out template to be used in the execution of an exam
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_episode           Episode id
    * @param     i_exam_req_det      Exam's order detail id 
    * @param     o_id_doc_template   Time out template id
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Jos� Castro
    * @version   2.6
    * @since     2010/08/27
    */

    FUNCTION get_exam_time_out_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        o_id_doc_template OUT doc_template.id_doc_template%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options with the documentation mode for an exam
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/07/03
    */

    FUNCTION get_exam_documentation_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options with the exams' results status
    *
    * @param     i_lang         Language
    * @param     i_prof         Profissional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3
    * @since     2010/05/05
    */

    FUNCTION get_exam_result_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options with the abnormality options for an exam's result
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/07/03
    */

    FUNCTION get_exam_result_abnormal_list
    (
        i_lang  IN language.id_language%TYPE, --1
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options with the origin of an exam's result
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/03/15
    */

    FUNCTION get_exam_result_origin_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
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

    FUNCTION get_exam_result_diagnosis_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_result_category_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns the last response for a request questionnaire by flg_time
    *
    * @param i_lang                       Id Language
    * @param i_prof                       Professional
    * @param i_id_exam_req_det            exam request detail Id
    * @param i_flg_time                   flg_time ('O','BE','AE')
    *
    * @param o_exam_question_response     Cursor question response
    * @param o_error                      Error message
    *
    * @author  Teresa Coutinho
    * @version 2.6.3
    * @since   2014/02/06
    **************************************************************************/

    FUNCTION get_exam_questionnaire_resp
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_exam_req_det           IN exam_question_response.id_exam_req_det%TYPE,
        i_flg_time               IN exam_question_response.flg_time%TYPE,
        o_exam_question_response OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_documents_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_question_response.id_exam_req_det%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_default_values
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

    FUNCTION tf_get_exam_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exams_detail;

    FUNCTION tf_get_exam_order_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exams_detail;

    FUNCTION tf_get_exam_cq
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report   IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_cq;

    FUNCTION tf_get_exam_cq_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report   IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html     IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_cq;

    FUNCTION tf_get_exam_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_co_sign;

    FUNCTION tf_get_exam_co_sign_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_co_sign;

    FUNCTION tf_get_exam_perform
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_perform;

    FUNCTION tf_get_exam_perform_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_perform_history;

    FUNCTION tf_get_exam_result
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_result;

    FUNCTION tf_get_exam_result_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_result;

    FUNCTION tf_get_exam_review
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_review;

    FUNCTION tf_get_exam_review_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_review;

    FUNCTION tf_get_exam_result_images
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_result_images;

    FUNCTION tf_get_exam_result_images_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_result_images;

    FUNCTION tf_get_exam_doc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_doc;

    FUNCTION tf_get_exam_doc_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_exam_constant.t_tbl_code_messages DEFAULT pk_exam_constant.t_tbl_code_messages()
    ) RETURN t_tbl_exam_doc;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_relationship_type sys_config.value%TYPE;
    g_concept_status    sys_config.value%TYPE;
    g_mcs_source        sys_config.value%TYPE;

END pk_exam_core;
/
