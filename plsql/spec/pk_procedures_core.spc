/*-- Last Change Revision: $Rev: 2045844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:25:09 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_procedures_core IS

    FUNCTION create_procedure_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention            IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis_notes         IN table_varchar, --10
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar, --15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_flg_location            IN table_varchar,
        i_supply                  IN table_table_number, --20
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number,
        i_dt_return               IN table_table_varchar,
        i_supply_loc              IN table_table_number,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar, --25
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --30
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2, --35
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_procedure_order
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_root_name              IN VARCHAR2,
        i_tbl_id_pk              IN table_number,
        i_tbl_data               IN table_table_varchar,
        i_tbl_ds_internal_name   IN table_varchar,
        i_tbl_real_val           IN table_table_varchar,
        i_tbl_val_clob           IN table_table_clob,
        i_tbl_val_array          IN tt_table_varchar DEFAULT NULL,
        i_tbl_val_array_desc     IN tt_table_varchar DEFAULT NULL,
        i_clinical_question_pk   IN table_number,
        i_clinical_question      IN table_varchar,
        i_response               IN table_table_varchar,
        i_test                   IN VARCHAR2,
        i_flg_update             IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_origin_req         IN VARCHAR2 DEFAULT 'D',
        o_flg_show               OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_msg_req                OUT VARCHAR2,
        o_interv_presc_array     OUT NOCOPY table_number,
        o_interv_presc_det_array OUT NOCOPY table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_procedure_request
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_interv_prescription     IN interv_prescription.id_interv_prescription%TYPE, --5
        i_intervention            IN intervention.id_intervention%TYPE,
        i_flg_time                IN interv_prescription.flg_time%TYPE,
        i_dt_begin                IN VARCHAR2,
        i_episode_destination     IN interv_prescription.id_episode_destination%TYPE,
        i_order_recurrence        IN interv_presc_det.id_order_recurrence%TYPE, --10
        i_diagnosis_notes         IN interv_presc_det.diagnosis_notes%TYPE,
        i_diagnosis               IN pk_edis_types.rec_in_epis_diagnosis,
        i_clinical_purpose        IN interv_presc_det.id_clinical_purpose%TYPE,
        i_clinical_purpose_notes  IN interv_presc_det.clinical_purpose_notes%TYPE,
        i_laterality              IN interv_presc_det.flg_laterality%TYPE, --15
        i_priority                IN interv_presc_det.flg_prty%TYPE,
        i_flg_prn                 IN interv_presc_det.flg_prn%TYPE,
        i_notes_prn               IN interv_presc_det.prn_notes%TYPE,
        i_exec_institution        IN interv_presc_det.id_exec_institution%TYPE,
        i_flg_location            IN interv_presc_det.flg_location%TYPE, --20
        i_supply                  IN table_number,
        i_supply_set              IN table_number,
        i_supply_qty              IN table_number,
        i_dt_return               IN table_varchar,
        i_supply_loc              IN table_number,
        i_not_order_reason        IN not_order_reason.id_not_order_reason%TYPE, --25
        i_notes                   IN interv_presc_det.notes%TYPE,
        i_prof_order              IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order                IN VARCHAR2,
        i_order_type              IN co_sign.id_order_type%TYPE,
        i_codification            IN codification.id_codification%TYPE, --30
        i_health_plan             IN interv_presc_det.id_pat_health_plan%TYPE,
        i_exemption               IN interv_presc_det.id_pat_exemption%TYPE,
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar, --35
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D', --35        
        o_interv_presc            OUT interv_prescription.id_interv_prescription%TYPE,
        o_interv_presc_det        OUT interv_presc_det.id_interv_presc_det%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_procedure_for_execution
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention            IN table_number,
        i_prof_performed          IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time              IN VARCHAR2,
        i_end_time                IN VARCHAR2,
        i_dt_next                 IN VARCHAR2,
        i_modifiers               IN table_varchar,
        i_supply_workflow         IN table_number,
        i_supply                  IN table_number,
        i_supply_set              IN table_number,
        i_supply_qty              IN table_number,
        i_supply_type             IN table_varchar,
        i_barcode_scanned         IN table_varchar,
        i_deliver_needed          IN table_varchar,
        i_flg_cons_type           IN table_varchar,
        i_flg_supplies_reg        IN VARCHAR2,
        i_dt_expiration           IN table_varchar,
        i_flg_validation          IN table_varchar,
        i_lot                     IN table_varchar,
        i_notes                   IN epis_interv.notes%TYPE,
        i_doc_template            IN doc_template.id_doc_template%TYPE,
        i_flg_type                IN doc_template_context.flg_type%TYPE,
        i_id_documentation        IN table_number,
        i_id_doc_element          IN table_number,
        i_id_doc_element_crit     IN table_number,
        i_value                   IN table_varchar,
        i_id_doc_element_qualif   IN table_table_number,
        i_vs_element_list         IN table_number,
        i_vs_save_mode_list       IN table_varchar,
        i_vs_list                 IN table_number,
        i_vs_value_list           IN table_number,
        i_vs_uom_list             IN table_number,
        i_vs_scales_list          IN table_number,
        i_vs_date_list            IN table_varchar,
        i_vs_read_list            IN table_number,
        i_clinical_decision_rule  IN cdr_call.id_cdr_call%TYPE,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_interv_presc_det        OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_procedure_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_intervention.id_schedule%TYPE,
        i_interv_presc_det IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets documentation values for the procedures time out template. Prior to that, performs a
    * a verification for any "no" answers.
    *
    * @param     i_lang                    Language id
    * @param     i_prof                    Professional
    * @param     i_interv_presc_det        Procedure detail order id
    * @param     i_interv_presc_plan       Procedure execution id
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
    * @author    João Martins
    * @version   2.5
    * @since     2009/06/04
    */

    FUNCTION set_procedure_time_out
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_interv_presc_det      IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan     IN interv_presc_plan.id_interv_presc_plan%TYPE,
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
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_test              IN VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT sys_message.desc_message%TYPE,
        o_msg_body              OUT pk_types.cursor_type,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_execution
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_interv_presc_det        IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan       IN interv_presc_plan.id_interv_presc_plan%TYPE, --5
        i_prof_performed          IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time              IN VARCHAR2,
        i_end_time                IN VARCHAR2,
        i_dt_next                 IN VARCHAR2,
        i_flg_next_change         IN VARCHAR2, --10
        i_modifiers               IN table_varchar,
        i_supply_workflow         IN table_number,
        i_supply                  IN table_number,
        i_supply_set              IN table_number,
        i_supply_qty              IN table_number, --15
        i_supply_type             IN table_varchar,
        i_barcode_scanned         IN table_varchar,
        i_deliver_needed          IN table_varchar,
        i_flg_cons_type           IN table_varchar,
        i_flg_supplies_reg        IN VARCHAR2, --20
        i_dt_expiration           IN table_varchar,
        i_flg_validation          IN table_varchar,
        i_lot                     IN table_varchar,
        i_notes                   IN epis_interv.notes%TYPE,
        i_doc_template            IN doc_template.id_doc_template%TYPE, --25
        i_flg_type                IN doc_template_context.flg_type%TYPE,
        i_id_documentation        IN table_number,
        i_id_doc_element          IN table_number,
        i_id_doc_element_crit     IN table_number,
        i_value                   IN table_varchar, --30
        i_id_doc_element_qualif   IN table_table_number,
        i_vs_element_list         IN table_number,
        i_vs_save_mode_list       IN table_varchar,
        i_vs_list                 IN table_number,
        i_vs_value_list           IN table_number, --35
        i_vs_uom_list             IN table_number,
        i_vs_scales_list          IN table_number,
        i_vs_date_list            IN table_varchar,
        i_vs_read_list            IN table_number,
        i_clinical_decision_rule  IN cdr_call.id_cdr_call%TYPE, --40
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_execution
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_interv_presc_det        IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan       IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_next                 IN VARCHAR2,
        i_prof_performed          IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time              IN VARCHAR2,
        i_end_time                IN VARCHAR2,
        i_flg_supplies            IN VARCHAR2,
        i_notes                   IN interv_presc_plan.notes%TYPE,
        i_epis_documentation      IN interv_presc_plan.id_epis_documentation%TYPE DEFAULT NULL,
        i_clinical_decision_rule  IN cdr_call.id_cdr_call%TYPE,
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar,
        o_interv_presc_plan       OUT interv_presc_plan.id_interv_presc_plan%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Associates documents to a given procedure request
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_interv_presc_det    Procedure detail order id
    * @param     i_interv_presc_plan   Procedure's plan id
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/07/07
    */

    FUNCTION set_procedure_doc_associated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_interv_presc_det     IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan    IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_flg_import           IN table_varchar,
        i_id_doc               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_procedure_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_interv_prescription     IN interv_prescription.id_interv_prescription%TYPE,
        i_interv_presc_det        IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_order_recurrence        IN table_number,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_flg_location            IN table_varchar,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number, --20
        i_supply_qty              IN table_table_number,
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number, --25
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --30
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a procedure request
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure execution id
    * @param     i_dt_cancel          Cancel date
    * @param     i_cancel_reason      Cancel reason id
    * @param     i_cancel_notes       Cancellation notes
    * @param     i_prof_order         Professional that ordered the procedure cancelation (co-sign)
    * @param     i_dt_order           Date of the procedure cancelation (co-sign)
    * @param     i_order_type         Type of cancelation (co-sign)  
    * @param     o_error              Error message
    
    * @return    true on success or false on error
    *
    * @author    Rui Batista
    * @version   2.3
    * @since     2005/05/16
    */

    FUNCTION cancel_procedure_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN interv_presc_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN interv_presc_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a procedure execution
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_interv_presc_plan   Procedure execution id
    * @param     i_dt_plan             Next planned date
    * @param     i_cancel_reason       Cancel reason id
    * @param     i_cancel_notes        Cancellation notes 
    * @param     o_error               Error message
    
    * @return    true on success or false on error
    *
    * @author    Cláudia Silva
    * @version   2.3
    * @since     2005/06/09
    */

    FUNCTION cancel_procedure_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_plan           IN VARCHAR2,
        i_cancel_reason     IN interv_presc_plan.id_cancel_reason%TYPE,
        i_cancel_notes      IN interv_presc_plan.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_procedure_doc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_doc_external      IN doc_external.id_doc_external%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2,
        i_flg_filter   IN VARCHAR2 DEFAULT pk_procedures_constant.g_interv_institution,
        i_codification IN codification.id_codification%TYPE,
        i_from_filter  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_rank         IN NUMBER DEFAULT NULL
    ) RETURN t_tbl_procedures_for_selection;

    FUNCTION get_procedure_search
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_procedure_type IN intervention.flg_type%TYPE DEFAULT pk_procedures_constant.g_type_interv,
        i_flg_type       IN interv_dep_clin_serv.flg_type%TYPE DEFAULT pk_procedures_constant.g_interv_can_req,
        i_codification   IN codification.id_codification%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_value          IN VARCHAR2
    ) RETURN t_table_procedures_search;

    FUNCTION get_procedure_search
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_procedure_type IN intervention.flg_type%TYPE DEFAULT pk_procedures_constant.g_type_interv,
        i_flg_type       IN interv_dep_clin_serv.flg_type%TYPE DEFAULT pk_procedures_constant.g_interv_can_req,
        i_codification   IN codification.id_codification%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_value          IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_category_search
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_procedure_type IN intervention.flg_type%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_in_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_interv_category IN interv_category.id_interv_category%TYPE,
        i_procedure_type  IN intervention.flg_type%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_timelineview
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_start_column IN PLS_INTEGER,
        i_end_column   IN PLS_INTEGER,
        i_last_column  IN PLS_INTEGER DEFAULT 9,
        o_task_list    OUT pk_types.cursor_type,
        o_list         OUT pk_types.cursor_type,
        o_count_list   OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of information nedded when ordering a P1
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure detail order id
    * @param     o_list               Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/06
    */

    FUNCTION get_procedure_codification_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a procedure detail
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_interv_presc_det            Procedure detail order id
    * @param     i_flg_report                  Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_interv_order                Cursor
    * @param     o_interv_co_sign              Cursor
    * @param     o_interv_clinical_questions   Cursor
    * @param     o_interv_execution            Cursor
    * @param     o_interv_execution_images     Cursor
    * @param     o_interv_doc                  Cursor
    * @param     o_interv_review               Cursor
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/21
    */

    FUNCTION get_procedure_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT t_tbl_procedures_detail,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT t_tbl_procedures_cq,
        o_interv_execution          OUT t_tbl_procedures_execution,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a procedure detail history
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_interv_presc_det            Procedure detail order id
    * @param     i_flg_report                  Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_interv_order                Cursor
    * @param     o_interv_co_sign              Cursor
    * @param     o_interv_clinical_questions   Cursor
    * @param     o_interv_execution            Cursor
    * @param     o_interv_execution_images     Cursor
    * @param     o_interv_doc                  Cursor
    * @param     o_interv_review               Cursor
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/21
    */

    FUNCTION get_procedure_detail_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT t_tbl_procedures_detail,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT t_tbl_procedures_cq,
        o_interv_execution          OUT t_tbl_procedures_execution,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_detail_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_order
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv                    OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the execution information for a given procedure request
    *
    * @param     i_lang                    Language id
    * @param     i_prof                    Professional
    * @param     i_interv_presc_plan       Procedure's plan id
    * @param     o_interv                  Cursor
    * @param     o_interv_images           Cursor
    * @param     o_interv                  Cursor
    * @param     o_interv_images_history   Cursor
    * @param     o_error                   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/07/07
    */

    FUNCTION get_procedure_execution
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_interv_presc_plan     IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv                OUT pk_types.cursor_type,
        o_interv_images         OUT pk_types.cursor_type,
        o_interv_history        OUT pk_types.cursor_type,
        o_interv_images_history OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the documents associated to a given procedure request
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_interv_presc_det    Procedure detail order id
    * @param     i_interv_presc_plan   Procedure's plan id
    * @param     o_interv_doc          Cursor
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/07/07
    */

    FUNCTION get_procedure_doc_associated
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv_doc        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_to_edit
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN table_number,
        o_interv                    OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_to_edit
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

    FUNCTION get_procedure_default_values
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

    FUNCTION get_procedure_for_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_supplies          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_to_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_execution_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_priority_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_default_priority
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN intervention.id_intervention%TYPE,
        i_value        IN OUT VARCHAR2,
        i_desc_value   IN OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_location_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_location_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_procedure_default_location
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN intervention.id_intervention%TYPE,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        i_value        IN OUT VARCHAR2,
        i_desc_value   IN OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Returns the last registered vital sign and lab tests results associated to a given procedure
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_patient           Patient id
    * @param     i_intervention      Procedure id
    * @param     o_weight            Weight info
    * @param     o_analysis_result   Lab tests results info
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Teresa Coutinho
    * @version   2.6.1
    * @since     2011/11/21
    */

    FUNCTION get_procedure_parameter_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_intervention    IN table_number,
        o_weight          OUT VARCHAR2,
        o_analysis_result OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_codification_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_codification_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN VARCHAR2,
        i_flg_default  IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    FUNCTION get_procedure_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the time out template to be used in the execution of a procedure
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_episode            Episode id
    * @param     i_interv_presc_det   Procedure detail order id
    * @param     o_id_doc_template    Time out template id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    João Martins
    * @version   2.5
    * @since     2009/07/03
    */

    FUNCTION get_procedure_time_out_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_id_doc_template  OUT doc_template.id_doc_template%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_modifiers_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT pk_types.cursor_type,
        o_ds_target   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_multichoice_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_procedure_unit_measure_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    FUNCTION get_procedure_cq_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_int_name   IN table_varchar,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION tf_get_procedure_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_detail;

    FUNCTION tf_get_procedure_order_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_detail;

    FUNCTION tf_get_procedure_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_co_sign;

    FUNCTION tf_get_procedure_cq
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_cq;

    FUNCTION tf_get_procedure_cq_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_cq;

    FUNCTION tf_get_procedure_execution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_execution;

    FUNCTION tf_get_procedure_execution_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_flg_html         IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_execution;

    FUNCTION tf_get_procedure_execution_images
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_execution_images;

    FUNCTION tf_get_procedure_doc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_doc;

    FUNCTION tf_get_procedure_review
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_aa_code_messages IN pk_procedures_constant.t_code_messages DEFAULT pk_procedures_constant.t_code_messages()
    ) RETURN t_tbl_procedures_review;

    FUNCTION get_procedure_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_docs_by_request
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_request IN NUMBER, -- edit, new, submit
        o_docs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_procedures_core;
/
