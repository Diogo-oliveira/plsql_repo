CREATE OR REPLACE PACKAGE pk_procedures_external IS

    TYPE t_rec_procedure IS RECORD(
        id_interv_presc_det interv_presc_det.id_interv_presc_det%TYPE,
        id_intervention     intervention.id_intervention%TYPE,
        desc_procedure      VARCHAR2(1000 CHAR),
        dt_req              VARCHAR2(200 CHAR));

    TYPE t_cur_procedure IS REF CURSOR RETURN t_rec_procedure;

    FUNCTION tf_procedures_ea
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_procedures_ea;

    PROCEDURE dashboards_______________;

    /*
    * Returns the date of the last execution of the procedures, dressings and requests for patient education 
    * displayed in the summary panel.
    *
    * @param i_lang          Language id
    * @param i_prof          Professional
    * @param i_unique_id     Patient education order id
    * @param i_flg_status    Status
    *  
    * @return                Returns the TIMESTAMP WITH LOCAL TIME ZONE of the date of the last execution 
    *  
    * @author                Cristina Olveira
    * @version               1.0
    * @since                 2013/07/05
    */

    FUNCTION get_procedure_last_execution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_status       IN interv_presc_det.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    PROCEDURE reports___________________;

    FUNCTION get_procedure_listview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_scope            IN NUMBER,
        i_flg_scope        IN VARCHAR2,
        i_start_date       IN VARCHAR2,
        i_end_date         IN VARCHAR2,
        i_cancelled        IN VARCHAR2,
        i_crit_type        IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a procedure detail
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_interv_presc_det            Procedure detail order id
    * @param     o_interv_order                Cursor
    * @param     o_interv_execution            Cursor
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/21
    */

    FUNCTION get_procedure_orders
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order     OUT pk_types.cursor_type,
        o_interv_execution OUT pk_types.cursor_type,
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
    * @param     o_interv_supplies             Cursor
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
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
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
    * @param     o_interv_supplies             Cursor
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
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE co_sign___________________;

    /*
    * Get the procedure's description
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure's order detail id
    * @param     i_co_sign_hist       Co sign id
    
    * @return    Clob
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_procedure_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /*
    * Get the procedure's instructions
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure's order detail id
    * @param     i_co_sign_hist       Co sign id
    
    * @return    Clob
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_procedure_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /*
    * Get the procedure's action description (Order, Cancellation)
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure's order detail id
    * @param     i_action             Type of action
    * @param     i_co_sign_hist       Co sign id
    
    * @return    String
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_procedure_action_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_action           IN co_sign.id_action%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get the procedure's date to order
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure's order detail id
    * @param     i_action             Type of action
    * @param     i_co_sign_hist       Co sign id
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/10/21
    */

    FUNCTION get_procedure_date_to_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    PROCEDURE cdr_______________________;

    /*
    * Checks the presence of a given procedure in the patient EHR
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_id_patient         Patient id
    * @param     i_intervention       Procedure id
    * @param     i_date               Date
    * @param     o_interv_presc_det   Cursor
    * @param     o_error              Error Menssage
    
    * @return    String
    *
    * @author    Nuno Neves
    * @version   2.6.1
    * @since     2011/06/09
    */

    FUNCTION check_procedure_cdr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_intervention     IN intervention.id_intervention%TYPE,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_presc_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE referral___________________;

    FUNCTION update_procedure_laterality
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_laterality   IN interv_presc_det.flg_laterality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_procedure_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_exec_institution IN interv_presc_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_procedure_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_referral     IN interv_presc_det.flg_referral%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_procedures_external.t_cur_procedure,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exec_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE cpoe______________________;

    FUNCTION copy_procedure_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_procedure_mandatory
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_procedure_draft_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_procedure_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_draft_activation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        i_id_cdr_call   IN cdr_call.id_cdr_call%TYPE,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_procedure_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_procedure_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_expiration
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_task_list     OUT pk_types.cursor_type,
        o_plan_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_order_plan_executed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_cpoe_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE order_sets_________________;

    FUNCTION get_procedure_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN table_number,
        o_interv_presc_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_task_instruction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_procedures_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_desc      OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN interv_presc_det.id_interv_presc_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_id        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_request_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_task_request            IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        o_interv_presc            OUT table_number,
        o_interv_presc_det        OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_interv_presc OUT interv_prescription.id_interv_prescription%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_procedure_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_procedure_mandatory
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_procedure_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_procedure_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_presc_det.id_interv_presc_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN exam_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN exam_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE tde_______________________;

    /*
    * Gets ongoing tasks (procedures)
    *                                        
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_patient       Patient id 
    
    * @return    tf_tasks_list   List of cancelable procedures
    *                                                                            
    * @author    Eduardo Reis
    * @version   v2.6.0.3
    * @since     2010/06/09
    */

    FUNCTION get_procedure_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /*
    * Suspends tasks (exams)
    *                                        
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure requisition detail id
    * @param     i_flg_reason         Reason for the WF suspension: 'D' (Death)        
    * @param     o_msg_error          Error message to be shown
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Eduardo Reis
    * @version   v2.6.0.3
    * @since     2010/06/09
    */
    FUNCTION suspend_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_reason       IN VARCHAR2,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivates tasks (exams)     
    *                                        
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure requisition detail id
    * @param     o_msg_error          Error message to be shown
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Eduardo Reis
    * @version   v2.6.0.3
    * @since     2010/06/09
    */

    FUNCTION reactivate_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE medication_________________;

    /*
    * Creates a new prescription for one or more procedures associated with administered medication 
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_episode        Episode id
    * @param     i_intervention   Procedure id
    * @param     i_flg_time       Flag that indicates when the procedure is to be executed
    * @param     i_dt_begin       Begin date
    * @param     i_medication     Medication id
    * @param     o_error          Error message
    
    * @return    string on success or error
    *
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/10/14 
    */

    FUNCTION set_procedure_with_medication
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_medication   IN NUMBER,
        i_notes        IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE progress_notes_____________;

    /*
    * Returns all procedures requested in the given episode (used in SOAP approach of ambulatory products)
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_episode   Episode id
    * @param     i_order     {*} 'N' to order by name {*} 'D' to order by date
    * @param     o_list      Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Carneiro
    * @version   2.6.0.4
    * @since     2010/11/03
    */

    FUNCTION get_procedure_in_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_order   IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the procedure information (procedure description, status, instructions)
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure request ID
    * @param     o_interv             Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Nuno Neves
    * @version   2.6.2.1.7
    * @since     2012/09/10
    */

    FUNCTION get_procedure_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns if the treatment allows comments or not
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_treatment   Procedure request ID
    
    * @return    String
    *
    * @author    António Neto
    * @version   2.6.2
    * @since     2012/05/17
    */

    FUNCTION check_procedure_revision
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE hand_off__________________;

    FUNCTION get_procedure_by_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE discharge_summary__________;

    FUNCTION get_technical_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_technical_procedure
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE flowsheets_____________;

    /*
    * Returns all procedures for flowsheets that are scheduled
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope        ID for scope type
    * @param     i_scope_type   Scope type (E)pisode/(V)isit/(P)atient
    * @param     o_error        Error message
    
    * @return    Type with procedures
    *
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/10/14
    */

    FUNCTION get_procedure_flowsheets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_coll_mcdt_flowsheets;

    PROCEDURE viewer____________________;

    FUNCTION get_procedure_viewer_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns procedures ordered list for the viewer
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_episode        Episode id
    * @param     i_translate      Translation code
    * @param     o_ordered_list   Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    João Martins
    * @version   2.5
    * @since     2008/11/11
    */

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns info about procedures
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_interv_presc_det   Procedure id
    * @param     o_ordered_list_det   Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Nuno Neves
    * @version   2.5
    * @since     2012/01/12
    */

    FUNCTION get_ordered_list_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns procedures information for the viewer
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_patient      Patient id
    * @param     i_episode      Episode id
    * @param     o_num_occur    Number of procedures for the given patient
    * @param     o_desc_first   First procedure description
    * @param     o_dt_first     First procedure order date
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    João Martins
    * @version   2.5
    * @since     2008/11/14
    */

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_viewer_area IN VARCHAR2,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    /*
    * Updates the viewer_ehr_ea table for the given patients
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_table_id_patients   Patient id
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Coelho
    * @version   2.5
    * @since     2011/04/27
    */

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE match____________________;

    FUNCTION set_procedure_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE cda______________________;

    /*
    * Returns procedures and patient education requests
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope        id_scope   
    * @param     i_flg_scope    Scope type (E - id_episode, V - id_visit, P - id_patient)
    * @param     i_start_date   Start date
    * @param     i_end_date     End date 
    * @param     i_cancelled    Y - return all records, N - return all except cancelled records
    * @param     i_crit_type    A - return all requests, E - return all executions
    * @param     i_proc_array   Array of id_interv_presc_det
    * @param     o_interv       Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Cristina Oliveira
    * @version   2.6.3.10.1
    * @since     2014/02/04
    */

    FUNCTION get_procedure_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        o_interv     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns procedures for CDA section that are pending and future scheduled 
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope        ID for scope type
    * @param     i_scope_type   Scope type (E)pisode/(V)isit/(P)atient
    * @param     o_proc_cda     Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *                        
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/10/14 
    */

    FUNCTION get_procedure_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_proc_cda   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_detail_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_proc_det   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE reset_____________________;

    /*
    * Resets procedures info by patient, by episode or both
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_patient   Patient id
    * @param     i_episode   Episode id
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Nuno Neves
    * @version   2.6.1
    * @since     2011/04/29
    */

    FUNCTION reset_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE system__________________;

    FUNCTION inactivate_procedures_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_grid_task_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
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

END pk_procedures_external;
/
