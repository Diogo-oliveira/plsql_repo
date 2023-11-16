/*-- Last Change Revision: $Rev: 2028850 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_education_db IS

    TYPE nurse_tea_req_rec IS RECORD(
        id_nurse_tea_req     nurse_tea_req.id_nurse_tea_req%TYPE,
        id_order_recurr_plan nurse_tea_req.id_order_recurr_plan%TYPE,
        id_episode           episode.id_episode%TYPE,
        id_software          epis_info.id_software%TYPE);

    TYPE nurse_tea_req_cur IS REF CURSOR RETURN nurse_tea_req_rec;
    TYPE t_coll_nurse_tea_req IS TABLE OF nurse_tea_req_rec;

    /**
    * Creates a patient education execution
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_id_nurse_tea_req        Patient education request identifier
    * @param   i_dt_start                Start date for patient education
    * @param   i_dt_nurse_tea_det_tstz   Date of teaching execution insertion
    * @param   i_flg_status              Execution status
    * @param   i_num_order               Execution order number
    * @param   o_error                   An error message, set when return=false
    *
    * @value   i_flg_status              {*} 'D' Pending {*} 'E' Complete {*} 'C' Cancelled
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   02-05-2011 
    */
    FUNCTION create_execution
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_nurse_tea_req      IN nurse_tea_det.id_nurse_tea_req%TYPE,
        i_dt_start              IN nurse_tea_det.dt_start%TYPE,
        i_dt_nurse_tea_det_tstz IN nurse_tea_det.dt_nurse_tea_det_tstz%TYPE,
        i_flg_status            IN nurse_tea_det.flg_status%TYPE,
        i_num_order             IN nurse_tea_det.num_order%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a patient education execution
    *
    * @param   i_lang             Language associated to the professional 
    * @param   i_prof             Professional, institution and software ids
    * @param   i_id_nurse_tea_det Details about a patient education execution identifier
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   02-05-2011 
    */
    FUNCTION cancel_execution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_det IN nurse_tea_det.id_nurse_tea_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels several patient education executions
    *
    * @param   i_lang                   Language associated to the professional 
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_nurse_tea_req_tab   Array of Patient education request identifier
    * @param   i_flg_status_det         Patient education detail status to be canceled
    * @param   o_error                  An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   16-01-2013 
    */
    FUNCTION cancel_executions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req_tab IN table_number,
        i_flg_status_det       IN nurse_tea_det.flg_status%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a patient education execution
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_exec_tab                Order recurrence plan info
    * @param   o_exec_to_process         For each plan, indicates if there are more executions to be processed
    * @param   o_error                   An error message, set when return=false    
    *
    * @value   o_exec_to_process         {*} 'Y' there are more executions to be processed {*} 'N' there are no more executions to be processed
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-05-2011 
    */
    FUNCTION create_executions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION descontinue_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get nurse teach topic title
    *
    * @param       i_lang                      preferred language id    
    * @param       i_prof                      professional structure
    * @param       i_nurse_tea_topic           nurse teach topic id
    *
    * @return      boolean                     true on success, otherwise false    
    *
    * @author                                  Tiago Silva
    * @since                                   13-MAY-2011
    ********************************************************************************************/
    FUNCTION get_nurse_teach_topic_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get nurse teach topic description
    *
    * @param       i_lang                      preferred language id    
    * @param       i_prof                      professional structure
    * @param       i_nurse_tea_topic           nurse teach topic id
    *
    * @return      boolean                     true on success, otherwise false    
    *
    * @author                                  Tiago Silva
    * @since                                   24-MAY-2011
    ********************************************************************************************/
    FUNCTION get_nurse_teach_topic_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * checks if a nurse teaching topic is available to be ordered or not
    *
    * @param       i_lang                      preferred language id    
    * @param       i_prof                      professional structure
    * @param       i_patient                   patient id
    * @param       i_episode                   episode id
    * @param       i_nurse_tea_topic           nurse teach topic id
    * @param       o_flg_conflict              flag that indicates if exists conflict or not
    * @param       o_error                     error structure for exception handling
    *
    * @return      boolean                     true on success, otherwise false    
    *
    * @author                                  Tiago Silva
    * @since                                   17-MAY-2011
    ********************************************************************************************/
    FUNCTION check_nurse_teach_conflict
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE,
        o_flg_conflict    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2 DEFAULT 'N',
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_diagnoses             IN table_clob DEFAULT NULL,
        i_not_order_reason      IN table_number,
        o_id_nurse_tea_req      OUT table_number,
        o_id_nurse_tea_topic    OUT table_number,
        o_title_topic           OUT table_varchar,
        o_desc_diagnosis        OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION create_req
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_diagnoses             IN table_clob DEFAULT NULL,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2,
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_not_order_reason      IN table_number,
        o_id_nurse_tea_req      OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_req IN table_number,
        i_topics           IN table_number,
        i_compositions     IN table_table_number,
        i_to_be_performed  IN table_varchar,
        i_start_date       IN table_varchar,
        i_notes            IN table_varchar,
        i_description      IN table_clob,
        i_order_recurr     IN table_number,
        i_upd_flg_status   IN VARCHAR2 DEFAULT 'Y',
        i_diagnoses        IN table_clob DEFAULT NULL,
        i_not_order_reason IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get status of a nurse teaching request
    *
    * @param       i_lang                  preferred language id    
    * @param       i_prof                  professional structure
    * @param       i_id_nurse_tea_req      request ID
    * @param       o_flg_status            request status
    * @param       o_status_string         status string to be parsed by the flash layer
    * @param       o_flg_finished          indicates if the request is finished
    * @param       o_flg_canceled          indicates if the request is canceled
    * @param       o_error                 error structure for exception handling
    *
    * @return      boolean                 true on success, otherwise false    
    *
    * @author                              Tiago Silva
    * @since                               24-MAY-2011
    ********************************************************************************************/
    FUNCTION get_nurse_teach_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_flg_status       OUT nurse_tea_req.flg_status%TYPE,
        o_status_string    OUT VARCHAR2,
        o_flg_finished     OUT VARCHAR2,
        o_flg_canceled     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update the request's status for a patient education as finished
    * 
    * @param i_lang                 Professional preferred language
    * @param i_nurse_tea_req        Patient education request to update
    * @param i_prof                 Professional identification and its context (institution and software)
    * @param i_prof_cat_type        Professional category 
    * @param o_error                Error information
    *
    * @deprecated Replaced by {@link pk_patient_education_db.set_nurse_tea_req_status;2 set_nurse_tea_req_status}
    * @see pk_patient_education_db.set_nurse_tea_req_status;2
    */
    FUNCTION set_nurse_tea_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update the request's status for a list of patient education
    *
    * @param i_lang                 Professional preferred language
    * @param i_prof                 Professional identification and its context (institution and software)
    * @param i_prof_cat_type        Professional category
    * @param i_nurse_tea_req_list   List of patient education to update
    * @param i_flg_status           Request's status
    * @param i_notes_close          Notes
    * @param i_flg_commit           Perform transactional commit
    * @param i_flg_history          Saves previous status into history
    * @param o_error                Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.8
    * @since   13-09-2011
    */
    FUNCTION set_nurse_tea_req_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_nurse_tea_req_list IN table_number,
        i_flg_status         IN nurse_tea_req.flg_status%TYPE,
        i_notes_close        IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_flg_commit         IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_history        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Criar requisições de ensinos de enfermagem
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_EPISODE - Episódio
                          I_PROF_REQ - Profissional que requisita
                       I_DT_BEGIN - Data a partir da qual é pedida a realização
                       I_NOTES_REQ - Notas de requisição
                       I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                                     como é retornada em PK_LOGIN.GET_PROF_PREF
                Saida:   O_ERROR - erro
    
      CRIAÇÃO: AA 2005/09/14
      NOTAS:
    *********************************************************************************/
    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_draft            IN VARCHAR2,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Cancelar requisição de ensinos de enfermagem
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_NURSE_TEA_REQ - ID da Req.
                             I_PROF_CANCEL - PROF. que cancelou
                       I_NOTES_CANCEL   - NOTAS DE CANCELAMENTO
    
                Saida:   O_ERROR - erro
    
      CRIAÇÃO: AA 2005/09/14
      NOTAS:
    *********************************************************************************/
    FUNCTION cancel_nurse_tea_req_int
    (
        i_lang             IN language.id_language%TYPE,
        i_nurse_tea_req    IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof_close       IN profissional,
        i_notes_close      IN nurse_tea_req.notes_close%TYPE,
        i_id_cancel_reason IN nurse_tea_req.id_cancel_reason%TYPE,
        i_flg_commit       IN VARCHAR2,
        i_flg_descontinue  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subject_by_id_topic
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE,
        o_subject  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB;

    /**
    * Returns available actions according with patient education request's status
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_nurse_tea_req  Patient education request IDs
    * @param   o_actions        Available actions
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   07-11-2011
    */
    FUNCTION get_request_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN table_number,
        i_id_episode    IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patient education for Plan of Care CDA section that are active or pending: Instructions, Goals
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_pat_edu_cda           Cursor with infomation about patient education for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        CRISTINA.OLIVEIRA
    * @version                       2.6.4
    * @since                         2014/05/23 
    */
    FUNCTION get_pat_education_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type_scope  IN VARCHAR2,
        i_id_scope    IN NUMBER,
        o_pat_edu_cda OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patient education for Instructions CDA section that are executed free text
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_pat_edu_instr         Cursor with infomation about patient education for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        CRISTINA.OLIVEIRA
    * @version                       2.6.4
    * @since                         2014/10/15 
    */
    FUNCTION get_pat_educa_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_edu_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_edu_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_pat_education_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_pat_educ_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patient education information (description, status, instructions)
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_nurse_tea_req   Pat education request ID
    * @param     o_pat_edu_info    Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Nuno Neves
    * @version   2.6.2.1.7
    * @since     2012/09/10
    */

    FUNCTION get_pat_education_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_pat_edu_info  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the human readble text of the instructions of a given patient education 
    * request.
    * 
    * @param i_lang The identifier of the professional preferred language.
    * @param i_prof The identifier of the professional context [id user, id institution, id software].
    * @param i_nurse_tea_req The patient education request identifier.
    * 
    * @return The human readble text of the instructions of a given patient education 
    *         request instructions.
    * 
    * @author Luis Oliveira
    * @version 1.0
    * @since 24/May/2011
    */

    FUNCTION get_instructions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets patient education topic description
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_nurse_tea_topic    Topic ID
    * @param i_desc_topic_aux        Description in free text
    * @param i_code_nurse_tea_topic  Code for translation
    *
    * @return                       Topic description           
    *
    * @author                Artur Costa
    * @version               1.0
    * @since                 2013/01/109
    */

    FUNCTION get_desc_topic
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_topic   IN nurse_tea_req.id_nurse_tea_topic%TYPE,
        i_desc_topic_aux       IN nurse_tea_req.desc_topic_aux%TYPE,
        i_code_nurse_tea_topic IN nurse_tea_topic.code_nurse_tea_topic%TYPE
    ) RETURN nurse_tea_req.desc_topic_aux%TYPE;

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

    FUNCTION get_last_execution
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_pat_educ_add_resources
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN CLOB;

    FUNCTION get_pat_education_end_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN nurse_tea_req.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

    FUNCTION tf_get_order_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order;

    FUNCTION tf_get_order_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order_hist;

    FUNCTION tf_get_execution_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_exec;

    FUNCTION tf_get_cancel_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_cancel;

    g_found        BOOLEAN;
    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;

    -- nurse teaching request status flag
    g_nurse_tea_req_sug          CONSTANT nurse_tea_req.flg_status%TYPE := 'S';
    g_nurse_tea_req_pend         CONSTANT nurse_tea_req.flg_status%TYPE := 'D';
    g_nurse_tea_req_act          CONSTANT nurse_tea_req.flg_status%TYPE := 'A';
    g_nurse_tea_req_fin          CONSTANT nurse_tea_req.flg_status%TYPE := 'F';
    g_nurse_tea_req_canc         CONSTANT nurse_tea_req.flg_status%TYPE := 'C';
    g_nurse_tea_req_ign          CONSTANT nurse_tea_req.flg_status%TYPE := 'I';
    g_nurse_tea_req_draft        CONSTANT nurse_tea_req.flg_status%TYPE := 'Z';
    g_nurse_tea_req_expired      CONSTANT nurse_tea_req.flg_status%TYPE := 'O';
    g_nurse_tea_req_not_ord_reas CONSTANT nurse_tea_req.flg_status%TYPE := 'N';
    g_nurse_tea_req_descontinued CONSTANT nurse_tea_req.flg_status%TYPE := 'X';

    -- nurse teaching configuration type flag
    g_nurse_tea_searchable CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'P';
    g_nurse_tea_frequent   CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'M';

END pk_patient_education_db;
/
