/*-- Last Change Revision: $Rev: 2028549 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_care_plans IS

    /*
    * Creates a new Care Plan
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode Id
    * @param     i_name                      Care plan name
    * @param     i_type                      Care plan type
    * @param     i_care_plan_dt_begin        Begin date 
    * @param     i_care_plan_dt_end          End date 
    * @param     i_subject_type              Pathology or subject type
    * @param     i_id_subject                Pathology or subject
    * @param     i_id_prof_coordinator       Care coordinator
    * @param     i_goals                     Goals
    * @param     i_notes                     Notes
    * @param     i_item                      Id for each care plan task
    * @param     i_task_type                 Task type
    * @param     i_care_plan_task_dt_begin   Begin date for each care plan task
    * @param     i_care_plan_task_dt_end     End date for each care plan task
    * @param     i_num_exec                  Number of orders for each care plan task
    * @param     i_interval_unit             Interval unit for each care plan task
    * @param     i_interval                  Interval for each care plan task
    * @param     i_care_plan_task_notes      Notes for each care plan task
    * @param     o_msg                       Validation message
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/22
    *
    * @author    Pedro Santos
    * @version   2.4.3-Denormalized
    * @since     2008/10/03
    * reason     added column id_episode to care_plan
    */

    FUNCTION create_care_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN care_plan.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_name                    IN care_plan.name%TYPE,
        i_care_plan_type          IN care_plan.id_care_plan_type%TYPE,
        i_care_plan_dt_begin      IN VARCHAR2,
        i_care_plan_dt_end        IN VARCHAR2,
        i_subject_type            IN care_plan.subject_type%TYPE,
        i_subject                 IN care_plan.id_subject%TYPE,
        i_prof_coordinator        IN care_plan.id_prof_coordinator%TYPE,
        i_goals                   IN care_plan.goals%TYPE,
        i_notes                   IN care_plan.notes%TYPE,
        i_item                    IN table_varchar,
        i_task_type               IN table_number,
        i_care_plan_task_dt_begin IN table_varchar,
        i_care_plan_task_dt_end   IN table_varchar,
        i_num_exec                IN table_number,
        i_interval_unit           IN table_number,
        i_interval                IN table_number,
        i_care_plan_task_notes    IN table_varchar,
        o_msg                     OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets a given Care Plan
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_episode               Episode_id
    * @param     i_care_plan             Care plan id
    * @param     i_name                  Care plan name
    * @param     i_type                  Care plan type
    * @param     i_care_plan_dt_begin    Begin date 
    * @param     i_care_plan_dt_end      End date 
    * @param     i_subject_type          Pathology or subject type
    * @param     i_id_subject            Pathology or subject
    * @param     i_id_prof_coordinator   Care coordinator
    * @param     i_goals                 Goals
    * @param     i_notes                 Notes
    * @param     o_msg                   Validation message
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/22
    *
    * @author    Pedro Santos
    * @version   2.4.3-Denormalized
    * @since     2008/10/03
    * reason     added column id_episode to care_plan_hist
    */

    FUNCTION set_care_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_care_plan               IN care_plan.id_care_plan%TYPE,
        i_name                    IN care_plan.name%TYPE,
        i_care_plan_type          IN care_plan.id_care_plan_type%TYPE,
        i_care_plan_dt_begin      IN VARCHAR2,
        i_care_plan_dt_end        IN VARCHAR2,
        i_subject_type            IN care_plan.subject_type%TYPE,
        i_subject                 IN care_plan.id_subject%TYPE,
        i_prof_coordinator        IN care_plan.id_prof_coordinator%TYPE,
        i_goals                   IN care_plan.goals%TYPE,
        i_notes                   IN care_plan.notes%TYPE,
        i_care_plan_task          IN table_number,
        i_care_plan_task_dt_begin IN table_varchar,
        i_care_plan_task_dt_end   IN table_varchar,
        i_num_exec                IN table_number,
        i_interval_unit           IN table_number,
        i_interval                IN table_number,
        i_care_plan_task_notes    IN table_varchar,
        o_msg                     OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the status to a given Care Plan
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_care_plan     Care plan id
    * @param     i_status        Status for update
    * @param     i_notes_cancel  Cancellation notes
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/23
    *
    * @author    Pedro Santos
    * @version   2.4.3-Denormalized
    * @since     2008/10/03
    * reason     added column id_episode to care_plan_hist
    */

    FUNCTION set_care_plan_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_care_plan     IN care_plan.id_care_plan%TYPE,
        i_status        IN care_plan.flg_status%TYPE,
        i_cancel_reason IN care_plan.id_cancel_reason%TYPE,
        i_notes_cancel  IN care_plan.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Adds a new task to a given Care Plan
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_care_plan                 Care plan id
    * @param     i_item                      Id for each care plan task
    * @param     i_task_type                 Task type
    * @param     i_care_plan_task_dt_begin   Begin date for each care plan task
    * @param     i_care_plan_task_dt_end     End date for each care plan task
    * @param     i_num_exec                  Number of orders for each care plan task
    * @param     i_interval_unit             Interval unit for each care plan task
    * @param     i_interval                  Interval for each care plan task
    * @param     i_care_plan_task_notes      Notes for each care plan task
    * @param     o_msg                       Validation message
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/22
    */

    FUNCTION set_care_plan_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_care_plan               IN table_number,
        i_item                    IN table_varchar,
        i_task_type               IN table_number,
        i_care_plan_task_dt_begin IN table_varchar,
        i_care_plan_task_dt_end   IN table_varchar,
        i_num_exec                IN table_number,
        i_interval_unit           IN table_number,
        i_interval                IN table_number,
        i_care_plan_task_notes    IN table_varchar,
        o_msg                     OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the planning instructions of a given task
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     i_dt_begin        Begin date for each care plan task
    * @param     i_dt_end          End date for each care plan task
    * @param     i_num_exec        Number of orders for each care plan task
    * @param     i_interval_unit   Interval unit for each care plan task
    * @param     i_interval        Interval for each care plan task
    * @param     i_notes           Notes for each care plan task
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/11
    */

    FUNCTION update_care_plan_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_num_exec       IN table_number,
        i_interval_unit  IN table_number,
        i_interval       IN table_number,
        i_notes          IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Associates/dissociates a given task to/from a given care plan
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan       Care plan id
    * @param     i_care_plan_task  Care plan task id
    * @param     i_flg_set         Flag that indicates if it is an association or dissociation
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/13
    */

    FUNCTION set_care_plan_task_association
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan      IN table_number,
        i_care_plan_task IN table_number,
        i_flg_set        VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the status to a given Care Plan
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     i_status          Status for update
    * @param     i_notes_cancel    Cancellation notes
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/23
    */

    FUNCTION set_care_plan_task_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        i_status         IN table_varchar,
        i_cancel_reason  IN table_number,
        i_notes_cancel   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates the order for a given task
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     i_task_type       Care plan task type
    * @param     i_order_num       Order number id
    * @param     i_req             Order id
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/05
    */

    FUNCTION set_care_plan_task_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task_req.id_care_plan_task%TYPE,
        i_task_type      IN care_plan_task_req.id_task_type%TYPE,
        i_order_num      IN care_plan_task_req.order_num%TYPE,
        i_req            IN care_plan_task_req.id_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_consults
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_prof_req            IN profissional,
        i_pat                 IN consult_req.id_patient%TYPE,
        i_instit_requests     IN consult_req.id_instit_requests%TYPE,
        i_instit_requested    IN consult_req.id_inst_requested%TYPE,
        i_consult_type        IN consult_req.consult_type%TYPE,
        i_clinical_service    IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str    IN VARCHAR2,
        i_flg_type_date       IN consult_req.flg_type_date%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested      IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_id_complaint        IN consult_req.id_complaint%TYPE,
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        o_consult_req         OUT consult_req.id_consult_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_followup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN VARCHAR2,
        i_dt_end_event        IN VARCHAR2,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN VARCHAR2,
        i_dt_rec_end          IN VARCHAR2,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        i_flg_origin_module   IN VARCHAR2,
        i_task_dependency     IN tde_task_dependency.id_task_dependency%TYPE,
        i_flg_start_depending IN VARCHAR2,
        i_episode_to_exec     IN consult_req.id_episode_to_exec%TYPE,
        i_transaction_id      IN VARCHAR2,
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        o_id_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_id_episode          OUT episode.id_episode%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_opinion
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN opinion.id_episode%TYPE,
        i_prof_questions      IN profissional,
        i_prof_questioned     IN opinion.id_prof_questioned%TYPE,
        i_spec                IN opinion.id_speciality%TYPE,
        i_desc                IN opinion.desc_problem%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_commit_data         IN VARCHAR2,
        i_diag                IN table_number,
        i_patient             IN opinion.id_patient%TYPE,
        i_flg_type            IN opinion.flg_type%TYPE DEFAULT 'O',
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        o_opinion             OUT opinion.id_opinion%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_analysis
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
        i_priority                IN table_varchar, -- 15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar, -- 20
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, -- 25
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar DEFAULT NULL,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar, -- 30
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, -- 35
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, -- 40
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'C',
        i_task_dependency         IN table_number, -- 45
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2, -- 50
        i_care_plan_task          IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type     IN care_plan_task.id_task_type%TYPE,
        i_order_num               IN care_plan_task_req.order_num%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2, --55
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_analysis_req_array      OUT NOCOPY table_number,
        o_analysis_req_det_array  OUT NOCOPY table_number,
        o_analysis_req_par_array  OUT NOCOPY table_number, --60
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_exams
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL, --5
        i_exam                    IN table_number,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar, --10
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --15
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, --20
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number, --25
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --30
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar, --35
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'C',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar, --40
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2,
        i_care_plan_task          IN care_plan_task.id_care_plan_task%TYPE, --45
        i_care_plan_task_type     IN care_plan_task.id_task_type%TYPE,
        i_order_num               IN care_plan_task_req.order_num%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_exam_req_array          OUT NOCOPY table_number,
        o_exam_req_det_array      OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_procedures
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention            IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_clinical_purpose        IN table_number, --10
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --15
        i_exec_institution        IN table_number,
        i_flg_location            IN table_varchar,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number,
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number, --20
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_codification            IN table_number, --25
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar, --30
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN interv_presc_det.flg_req_origin_module%TYPE DEFAULT 'C',
        i_test                    IN VARCHAR2,
        i_care_plan_task          IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type     IN care_plan_task.id_task_type%TYPE, --35
        i_order_num               IN care_plan_task_req.order_num%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_education
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_diagnoses             IN table_clob,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2 DEFAULT 'N',
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_not_order_reason      IN table_number,
        i_care_plan_task        IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type   IN care_plan_task.id_task_type%TYPE,
        i_order_num             IN care_plan_task_req.order_num%TYPE,
        o_id_nurse_tea_req      OUT table_number,
        o_id_nurse_tea_topic    OUT table_number,
        o_title_topic           OUT table_varchar,
        o_desc_diagnosis        OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Associates an order for a given medication task
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     i_flg_task_type   Flag that indicates the task type
    * @param     i_order_num       Order number id
    * @param     i_req             Order id
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/07/10
    */

    FUNCTION set_care_plan_task_req_med
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task_req.id_care_plan_task%TYPE,
        i_flg_task_type  IN task_type.flg_type%TYPE,
        i_order_num      IN care_plan_task_req.order_num%TYPE,
        i_req            IN care_plan_task_req.id_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_medication
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN presc.id_patient%TYPE,
        i_id_episode           IN presc.id_epis_create%TYPE,
        i_id_presc             IN table_number,
        i_id_action            IN table_number,
        i_id_cdr_call          IN NUMBER DEFAULT NULL,
        i_context              IN VARCHAR2,
        i_id_cdr_overdose_call IN NUMBER,
        i_flg_new_presc        IN VARCHAR2,
        i_all_presc_dir_xml    IN table_varchar,
        i_set_presc_dir_xml    IN table_varchar,
        i_co_sign_xml          IN table_varchar,
        i_care_plan_task       IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type  IN care_plan_task.id_task_type%TYPE,
        i_order_num            IN care_plan_task_req.order_num%TYPE,
        o_id_presc             OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_care_plan_task_diets
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_id_epis_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type        IN diet_type.id_diet_type%TYPE,
        i_desc_diet           IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_dt_end_str          IN VARCHAR2,
        i_food_plan           IN epis_diet_req.food_plan%TYPE,
        i_flg_help            IN epis_diet_req.flg_help%TYPE,
        i_notes               IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined  IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule    IN table_number,
        i_id_diet             IN table_number,
        i_quantity            IN table_number,
        i_id_unit             IN table_number,
        i_notes_diet          IN table_varchar,
        i_dt_hour             IN table_varchar,
        i_commit              IN VARCHAR2,
        i_flg_institution     IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share           IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_care_plan_task      IN care_plan_task.id_care_plan_task%TYPE,
        i_care_plan_task_type IN care_plan_task.id_task_type%TYPE,
        i_order_num           IN care_plan_task_req.order_num%TYPE,
        i_flg_force           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_diet        OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_warning         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the status to a given Care Plan instance
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     i_order_num       Order number id
    * @param     i_status          Status for update
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/07/03
    */

    FUNCTION set_care_plan_task_req_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task_req.id_care_plan_task%TYPE,
        i_order_num      IN care_plan_task_req.order_num%TYPE,
        i_status         IN care_plan_task_req.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plan view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/23
    */

    FUNCTION get_care_plan_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the task view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/29
    */

    FUNCTION get_care_plan_task_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the timeline view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/02
    */

    FUNCTION get_care_plan_timeline_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the tasks for the timeline view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/16
    */

    FUNCTION get_care_plan_timeline_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the updated info for a given task
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     o_list            Cursor
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/08/27
    */

    FUNCTION get_care_plan_timeline_update
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN care_plan_task.id_care_plan_task%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_care_plan_to_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan      IN care_plan.id_care_plan%TYPE,
        o_care_plan      OUT pk_types.cursor_type,
        o_care_plan_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_care_plan_task_to_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        o_care_plan_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plans that one could associate to a task
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/09
    */

    FUNCTION get_care_plan_to_associate
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plans associated to a given task
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_care_plan_task  Care plan task id
    * @param     o_list            Cursor
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/09
    */

    FUNCTION get_care_plan_to_dissociate
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_care_plan_task IN table_number,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plan detail
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_care_plan        Care plan id
    * @param     o_care_plan        Cursor
    * @param     o_task_type_count  Cursor
    * @param     o_care_plan_task   Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/23
    */

    FUNCTION get_care_plan_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_care_plan       IN care_plan.id_care_plan%TYPE,
        o_care_plan       OUT pk_types.cursor_type,
        o_task_type_count OUT pk_types.cursor_type,
        o_care_plan_task  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plan task detail
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_care_plan        Care plan id
    * @param     o_task_type_count  Cursor
    * @param     o_care_plan_task   Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/23
    */

    FUNCTION get_care_plan_task_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_care_plan_task  IN care_plan_task.id_care_plan_task%TYPE,
        o_task_type_count OUT pk_types.cursor_type,
        o_care_plan_task  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of possible actions
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_subject         Subject of the action
    * @param     i_from_state      From state
    * @param     i_care_plan_task  Care plan task id
    * @param     i_task_type       Care plan task type
    * @param     o_actions         Cursor
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/21
    */

    FUNCTION get_care_plan_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN table_varchar,
        i_care_plan_task IN table_number,
        i_task_type      IN table_varchar,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of views for the functionality
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/21
    */

    FUNCTION get_care_plan_view_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of tasks that can be associated to a Care Plan
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/29
    */

    FUNCTION get_care_plan_task_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of the Care Plan types
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/23
    */

    FUNCTION get_care_plan_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of the pathologies for a given patient
    * R - Relevant diseases
    * D - Diagnoses
    * A - Allergies
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_patient   Patient id
    * @param     o_list      Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/22
    */

    FUNCTION get_care_plan_subject
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN care_plan.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of the professionals within an institution
    * (doctors, nurses and social assistants)
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/04/22
    */

    FUNCTION get_care_plan_coordinator
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks the dependencies for the fields of the advanced input
    *
    * @param     i_lang                   Language id
    * @param     i_prof                   Professional
    * @param     i_dt_begin_str           Begin date for each care plan task
    * @param     i_dt_end_str             End date for each care plan task
    * @param     i_num_exec               Number of orders for each care plan task
    * @param     i_interval_unit          Interval unit for each care plan task
    * @param     i_interval               Interval for each care plan task
    * @param     o_sysdate                Current date
    * @param     o_dt_begin               Begin date 
    * @param     o_dt_end                 End date 
    * @param     o_hr_begin               Begin time
    * @param     o_hr_end                 End time
    * @param     o_num_exec               Number of orders
    * @param     o_interval_unit          Interval unit
    * @param     o_interval               Interval
    * @param     o_dt_begin_edit          Begin date edition
    * @param     o_dt_end_edit            End date edition
    * @param     o_num_exec_edit          Number of orders edition
    * @param     o_interval_unit_edit     Interval unit edition
    * @param     o_interval_edit          Interval edition
    * @param     o_dt_begin_param         Begin date parameter
    * @param     o_dt_end_param           End date parameter
    * @param     o_num_exec_param         Number of orders parameter
    * @param     o_interval_unit_param    Interval unit parameter
    * @param     o_interval_param         Interval parameter
    * @param     o_error                  Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/05
    */

    FUNCTION check_care_plan_param
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dt_begin_str        IN VARCHAR2,
        i_dt_end_str          IN VARCHAR2,
        i_num_exec            IN care_plan_task.num_exec%TYPE,
        i_interval_unit       IN care_plan_task.id_unit_measure%TYPE,
        i_interval            IN care_plan_task.interval%TYPE,
        o_sysdate             OUT VARCHAR2,
        o_dt_begin            OUT VARCHAR2,
        o_dt_end              OUT VARCHAR2,
        o_hr_begin            OUT VARCHAR2,
        o_hr_end              OUT VARCHAR2,
        o_num_exec            OUT VARCHAR2,
        o_interval_unit       OUT VARCHAR2,
        o_interval            OUT VARCHAR2,
        o_dt_begin_edit       OUT VARCHAR2,
        o_dt_end_edit         OUT VARCHAR2,
        o_num_exec_edit       OUT VARCHAR2,
        o_interval_unit_edit  OUT VARCHAR2,
        o_interval_edit       OUT VARCHAR2,
        o_dt_begin_param      OUT VARCHAR2,
        o_dt_end_param        OUT VARCHAR2,
        o_num_exec_param      OUT care_plan_task.num_exec%TYPE,
        o_interval_unit_param OUT care_plan_task.id_unit_measure%TYPE,
        o_interval_param      OUT care_plan_task.interval%TYPE,
        o_instructions_format OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a formated string to show in the UI screen
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_dt_begin             Begin date for each care plan task
    * @param     i_dt_end               End date for each care plan task
    * @param     i_num_exec             Number of orders for each care plan task
    * @param     i_interval             Interval for each care plan task
    * @param     i_interval_unit        Interval unit for each care plan task
    * @param     o_instructions_format  String with the task instructions
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/13
    */

    FUNCTION get_instructions_format
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_num_exec            IN care_plan_task.num_exec%TYPE,
        i_interval            IN care_plan_task.interval%TYPE,
        i_interval_unit       IN care_plan_task.id_unit_measure%TYPE,
        o_instructions_format OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a formated string to show in the UI screen
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_dt_begin       Begin date for each care plan task
    * @param     i_dt_end         End date for each care plan task
    * @param     i_num_exec       Number of orders for each care plan task
    * @param     i_interval       Interval for each care plan task
    * @param     i_interval_unit  Interval unit for each care plan task
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/19
    */

    FUNCTION get_instructions_format
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_num_exec      IN care_plan_task.num_exec%TYPE,
        i_interval      IN care_plan_task.interval%TYPE,
        i_interval_unit IN care_plan_task.id_unit_measure%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns a formated string to show the task status
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_flg_type         Flag that indicates the task type
    * @param     i_task_flg_status  Flag that indicates the task status
    * @param     i_req_flg_status   Flag that indicates the order status
    * @param     i_dt_begin         Begin date for the task
    * @param     i_req              Order id
    * @param     i_view             View for which the string will be return
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/05/20
    */

    FUNCTION get_string_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN VARCHAR2,
        i_task_flg_status IN VARCHAR2,
        i_req_flg_status  IN VARCHAR2,
        i_dt_begin        IN VARCHAR2,
        i_req             IN care_plan_task_req.id_req%TYPE,
        i_view            IN VARCHAR2
    ) RETURN VARCHAR2;

    /*
    * Returns a formated string to show the begin date
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_task_flg_status  Flag that indicates the task status
    * @param     i_req_flg_status   Flag that indicates the order status
    * @param     i_dt_begin         Begin date for the task
    * @param     i_dt_req           Order id
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/07/27
    */

    FUNCTION get_dt_begin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_flg_status IN VARCHAR2,
        i_req_flg_status  IN VARCHAR2,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req          IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /*
    * Returns a formated string to show the task description
    *
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_item       Id for each care plan task
    * @param     i_task_type  Task type
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/02
    */

    FUNCTION get_desc_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_item      IN care_plan_task.id_item%TYPE,
        i_task_type IN care_plan_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_yes VARCHAR2(1);
    g_no  VARCHAR2(1);

    g_relevant_disease care_plan.subject_type%TYPE;
    g_diagnosis        care_plan.subject_type%TYPE;
    g_allergy          care_plan.subject_type%TYPE;

    g_appointments          task_type.flg_type%TYPE;
    g_spec_appointments     task_type.flg_type%TYPE;
    g_followup_appointments task_type.flg_type%TYPE;
    g_opinions              task_type.flg_type%TYPE;
    g_analysis              task_type.flg_type%TYPE;
    g_group_analysis        task_type.flg_type%TYPE;
    g_exams                 task_type.flg_type%TYPE;
    g_imaging_exams         task_type.flg_type%TYPE;
    g_other_exams           task_type.flg_type%TYPE;
    g_procedures            task_type.flg_type%TYPE;
    g_patient_education     task_type.flg_type%TYPE;
    g_medication            task_type.flg_type%TYPE;
    g_ext_medication        task_type.flg_type%TYPE;
    g_int_medication        task_type.flg_type%TYPE;
    g_pharm_medication      task_type.flg_type%TYPE;
    g_ivfluids_medication   task_type.flg_type%TYPE;
    g_diets                 task_type.flg_type%TYPE;

    g_id_appointments          task_type.id_task_type%TYPE := 3;
    g_id_followup_appointments task_type.id_task_type%TYPE := 2;
    g_id_opinions              task_type.id_task_type%TYPE := 4;
    g_id_analysis              task_type.id_task_type%TYPE := 11;
    g_id_group_analysis        task_type.id_task_type%TYPE := 18;
    g_id_exams                 task_type.id_task_type%TYPE := 6;
    g_id_imaging_exams         task_type.id_task_type%TYPE := 7;
    g_id_other_exams           task_type.id_task_type%TYPE := 8;
    g_id_procedures            task_type.id_task_type%TYPE := 42;
    g_id_patient_education     task_type.id_task_type%TYPE := 43;
    g_id_medication            task_type.id_task_type%TYPE := 45;
    g_id_ext_medication        task_type.id_task_type%TYPE := 15;
    g_id_int_medication        task_type.id_task_type%TYPE := 13;
    g_id_pharm_medication      task_type.id_task_type%TYPE := 16;
    g_id_ivfluids_medication   task_type.id_task_type%TYPE := 17;
    g_id_diets                 task_type.id_task_type%TYPE := 22;

    g_doctor       VARCHAR2(1);
    g_nurse        VARCHAR2(1);
    g_social       VARCHAR2(1);
    g_case_manager VARCHAR2(1);

    g_active   VARCHAR2(1);
    g_inactive VARCHAR2(1);

    g_pending     VARCHAR2(2);
    g_ordered     VARCHAR2(2);
    g_inprogress  VARCHAR2(2);
    g_suspended   VARCHAR2(2);
    g_finished    VARCHAR2(2);
    g_interrupted VARCHAR2(2);
    g_canceled    VARCHAR2(2);

    g_day   unit_measure.id_unit_measure%TYPE;
    g_week  unit_measure.id_unit_measure%TYPE;
    g_month unit_measure.id_unit_measure%TYPE;
    g_year  unit_measure.id_unit_measure%TYPE;
END;
/
