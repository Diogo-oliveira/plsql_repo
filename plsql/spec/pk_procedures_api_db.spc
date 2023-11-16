/*-- Last Change Revision: $Rev: 2028875 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_procedures_api_db IS

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
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number, --20
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --25
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number, --30
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

    FUNCTION set_procedure_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_interv_presc_det       IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan      IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN interv_presc_plan.notes%TYPE,
        i_epis_documentation     IN interv_presc_plan.id_epis_documentation%TYPE DEFAULT NULL,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        o_interv_presc_plan      OUT interv_presc_plan.id_interv_presc_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

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

    FUNCTION get_procedure_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2,
        i_flg_filter   IN VARCHAR2 DEFAULT 'S',
        i_codification IN codification.id_codification%TYPE
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
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
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
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
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

    FUNCTION get_procedure_for_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

END pk_procedures_api_db;
/
