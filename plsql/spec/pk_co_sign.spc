/*-- Last Change Revision: $Rev: 2028578 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_co_sign AS
    --
    g_cosign_config_table CONSTANT VARCHAR2(30 CHAR) := 'CO-SIGN';
    --
    g_cosign_action_subject    CONSTANT action.subject%TYPE := 'CO_SIGN_DEFAULT_ACTIONS';
    g_cosign_action_def_add    CONSTANT action.internal_name%TYPE := 'NEEDS_COSIGN_ORDER';
    g_cosign_action_def_cancel CONSTANT action.internal_name%TYPE := 'NEEDS_COSIGN_CANCEL';

    --Flag status code domain
    g_cosign_flg_status CONSTANT sys_domain.code_domain%TYPE := 'CO_SIGN.FLG_STATUS';
    --Pending state value
    g_cosign_flg_status_p CONSTANT sys_domain.val%TYPE := 'P';
    --Co-signed state value
    g_cosign_flg_status_cs CONSTANT sys_domain.val%TYPE := 'CS';
    --Not applicable state value
    g_cosign_flg_status_na CONSTANT sys_domain.val%TYPE := 'NA';
    --Draft state value
    g_cosign_flg_status_d CONSTANT sys_domain.val%TYPE := 'D';
    --Outdated state value
    g_cosign_flg_status_o CONSTANT sys_domain.val%TYPE := 'O';
    --
    --                                                                                    
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    --
    g_available     profile_template.flg_available%TYPE;
    g_epis_active   episode.flg_status%TYPE;
    g_not_available VARCHAR2(1);
    ---
    g_co_sign_interv         VARCHAR2(1);
    g_co_sign_exam           VARCHAR2(1);
    g_co_sign_analysis       VARCHAR2(1);
    g_co_sign_monitorization VARCHAR2(1);
    g_co_sign_prescription   VARCHAR2(1);
    g_co_sign_opinion        VARCHAR2(2);
    --------------------------
    flg_co_sign_yes VARCHAR2(1);
    --
    flg_prof_default_y VARCHAR2(1);

    flg_prof_default_n VARCHAR2(1);

    --G_ATTEND_STATUS_ACT EPIS_ATTENDING_NOTES.FLG_STATUS%TYPE;
    --G_ATTEND_STATUS_CANC  EPIS_ATTENDING_NOTES.FLG_STATUS%TYPE;
    --
    g_flg_status_a records_review_read.flg_status%TYPE;
    g_flg_status_c records_review_read.flg_status%TYPE;
    --
    g_exam_status_final exam_req_det.flg_status%TYPE;
    g_exam_status_read  exam_req_det.flg_status%TYPE;
    -- 
    g_analisys_status_final analysis_req_det.flg_status%TYPE;
    g_analisys_status_red   analysis_req_det.flg_status%TYPE;
    --
    g_tests_type_exam     tests_review.flg_type%TYPE;
    g_tests_type_analisys tests_review.flg_type%TYPE;
    --
    g_icon_type_analysis sys_domain.img_name%TYPE;
    g_icon_type_exam     sys_domain.img_name%TYPE;
    --
    g_treat_type_interv treatment_management.flg_type%TYPE;
    g_treat_type_drug   treatment_management.flg_type%TYPE;
    --
    g_interv_status_final interv_presc_det.flg_status%TYPE;
    g_interv_status_curso interv_presc_det.flg_status%TYPE;
    g_interv_status_inter interv_presc_det.flg_status%TYPE;
    --
    g_icon_type_interv sys_domain.img_name%TYPE;
    g_icon_type_drug   sys_domain.img_name%TYPE;
    --
    g_interv_take_sos interv_presc_det.flg_interv_type%TYPE;
    --
    g_flg_type_c critical_care.flg_type%TYPE;
    g_flg_type_h critical_care.flg_type%TYPE;
    g_flg_type_n critical_care.flg_type%TYPE;

    --
    g_flg_type_d category.flg_type%TYPE;
    --
    g_cms_area_hpi  mdm_evaluation.cms_area%TYPE;
    g_cms_area_ros  mdm_evaluation.cms_area%TYPE;
    g_cms_area_pfsh mdm_evaluation.cms_area%TYPE;
    g_cms_area_pe   mdm_evaluation.cms_area%TYPE;
    g_cms_area_mdm  mdm_evaluation.cms_area%TYPE;
    ---

    g_bartchart_status_a epis_bartchart.flg_status%TYPE;
    g_label              VARCHAR2(1);
    g_no_color           VARCHAR2(1);
    --
    g_type_add   CONSTANT VARCHAR2(1) := 'A';
    g_type_rem   CONSTANT VARCHAR2(1) := 'R';
    g_type_match CONSTANT VARCHAR2(1) := 'M';
    -- 
    g_flg_type_tech CONSTANT category.flg_type%TYPE := 'T';
    g_exception EXCEPTION;
    g_flg_current_user        CONSTANT order_type.flg_default_ob%TYPE := 'CU';
    g_flg_not_applicable      CONSTANT order_type.flg_default_ob%TYPE := 'NA';
    g_flg_external            CONSTANT order_type.flg_default_ob%TYPE := 'EX';
    g_flg_prof_list           CONSTANT order_type.flg_default_ob%TYPE := 'PL';
    g_id_order_type_external  CONSTANT order_type.id_order_type%TYPE := 7;
    g_id_order_type_stand_ord CONSTANT order_type.id_order_type%TYPE := 4;

    g_translation_trs_module       CONSTANT translation_trs.module%TYPE := 'CO_SIGN';
    g_co_sign_text_format          CONSTANT translation_trs.flg_record_format%TYPE := 'F';
    g_translation_trs_co_sign_code CONSTANT translation_trs.code_translation%TYPE := 'CO_SIGN.CO_SIGN_NOTES.';

    g_action_sys_message   CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M017';
    g_order_sys_message    CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M018';
    g_instr_sys_message    CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M019';
    g_cs_notes_sys_message CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M020';

    g_order_type_sys_message CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M007';
    g_ordered_by_sys_message CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M005';
    g_ordered_at_sys_message CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M027';

    g_ordered_at_sm_no_collon CONSTANT sys_message.code_message%TYPE := 'CO_SIGN_M021';

    --Co-sign detail
    --Current information details
    g_cosign_curr_info CONSTANT sys_domain.val%TYPE := 'C';
    --Not applicable state value
    g_cosign_hist_info CONSTANT sys_domain.val%TYPE := 'H';

    g_table_name      CONSTANT VARCHAR2(20 CHAR) := 'CO_SIGN';
    g_table_name_hist CONSTANT VARCHAR2(20 CHAR) := 'CO_SIGN_HIST';

    /********************************************************************************************
    * Listar os profissionais que podem efectuar co-sign 
    *
    * @param i_lang                   The language ID
    * @param o_prof_list              Cursor containing the professional list 
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Sílvia Freitas
    * @since                          2007/08/30
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_prof_list  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_order_type    IN order_type.id_order_type%TYPE,
        i_internal_name    IN VARCHAR2,
        i_flg_show_default IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error            OUT t_error_out
    ) RETURN t_tbl_core_domain;

    /**
    * Returns description of professional that requested the order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)    
    * @param   i_flg_ordered_by     Ordered by list
    * @param   i_id_prof_order      Professional identifier that requested the order
    *
    * @return  varchar2             Professional description that requested the order
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   28-04-2014
    */
    FUNCTION get_prof_order_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_ordered_by IN order_type.flg_ordered_by%TYPE,
        i_id_prof_order  IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns description of professional that requested the order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)    
    * @param   i_id_order_type      Order type identifier
    * @param   i_id_prof_order      Professional identifier that requested the order
    *
    * @return  varchar2             Professional description that requested the order
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   28-04-2014
    */
    FUNCTION get_prof_order_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE,
        i_id_prof_order IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Listar todos os tipos de ordens para co_sign 
    *
    * @param i_lang                   The language ID
    * @param o_order_type             Listar todos os tipos de ordens para co_sign 
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Sílvia Freitas
    * @since                          2007/08/24
    **********************************************************************************************/
    FUNCTION get_order_type
    (
        i_lang       IN language.id_language%TYPE,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * validar se o perfil tem ou não permissão registar date /time stamp nas requisições
    
    * @param i_lang                   The language ID
    * @param o_prof                   Cursor containing the professional list 
    
    * @param i_flg_type               Devolve Y ou N                                      
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Sílvia Freitas
    * @since                          2007/08/30
    **********************************************************************************************/
    FUNCTION get_date_time_stamp_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *
    * Function to insert or delete co-sign alerts
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_id_episode          Episode ID
    * @param i_id_episode_new      New Episode ID (applicable in match case) 
    * @param i_id_req_det          Detail ID (eg. id_co_sign_task)
    * @param i_dt_req_det          Record date
    * @param i_type                Operation type A - add, R- remove        
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      José Silva
    * @since                       2008/05/22
    * @version                     1.0
    *
    */

    FUNCTION set_co_sign_alerts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN sys_alert_event.id_episode%TYPE,
        i_id_episode_new  IN sys_alert_event.id_episode%TYPE DEFAULT NULL,
        i_id_req_det      IN sys_alert_event.id_record%TYPE,
        i_dt_req_det      IN sys_alert_event.dt_record%TYPE,
        i_id_professional IN sys_alert_event.id_professional%TYPE,
        i_type            IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the co_sign task
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_dest                  destination professional    
    * @param i_episode                    episode ID
    * @param i_id_task                    task ID
    * @param i_flg_type                   task type: (A) Analysis, (D) Drugs and other types of medication, (E) Exams, (I) Interventions, (M) Monitorizations.        
    * @param i_dt_reg                     task request date   
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              21-05-2008
    **********************************************************************************************/
    FUNCTION set_co_sign_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_dest     IN professional.id_professional%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_task       IN co_sign_task.id_task%TYPE,
        i_flg_type      IN co_sign_task.flg_type%TYPE,
        i_dt_reg        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_order_type IN order_type.id_order_type%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Removes the co_sign task
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_episode                    episode ID    
    * @param i_id_task                    task ID
    * @param i_flg_type                   task type: (A) Analysis, (D) Drugs and other types of medication, (E) Exams, (I) Interventions, (M) Monitorizations.        
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              21-05-2008
    **********************************************************************************************/
    FUNCTION remove_co_sign_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_id_task  IN co_sign_task.id_task%TYPE,
        i_flg_type IN co_sign_task.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_flg_co_sign_wf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_order_type  order_type.id_order_type%TYPE,
        i_flg_co_sign_wf order_type.flg_co_sign_wf%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Gets co sign task type functions result
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_task                   Task transactional id
    * @param i_func_name              Function to be executed
    *                        
    * @return                         Returns i_func_name description
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task            IN co_sign_task.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_func_name       IN VARCHAR2
    ) RETURN CLOB;

    /********************************************************************************************
    * Gets co sign task type functions result
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_task                   Task transactional id
    * @param i_func_name              Function to be executed
    *                        
    * @return                         Returns i_func_name date
    * 
    * @author                         Nuno Alves
    * @version                        2.6.5
    * @since                          2015/10/13
    **********************************************************************************************/
    FUNCTION get_task_exec_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task            IN co_sign.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_func_name       IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * Gets action description from a co-sign task
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign             Co-sign task identifier
    * @param i_func_name              Function to be executed
    *                        
    * @return                         Returns i_func_name description
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_action_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task            IN co_sign_task.id_task%TYPE,
        i_id_action       IN co_sign.id_action%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_func_name       IN VARCHAR2
    ) RETURN CLOB;
    --
    FUNCTION get_id_task_type_action
    (
        i_task_type IN task_type_actions.id_task_type%TYPE,
        i_action    IN task_type_actions.id_action%TYPE
    ) RETURN task_type_actions.id_task_type_action%TYPE;
    --
    /**
    * Insert a co-sign task_type action.
    *
    * @param i_task_type_action         Task type action
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_func_task_description    Function that returns the description of the order/task
    * @param i_func_instructions        Function that returns the instructions of the order/task
    * @param i_func_task_action_desc    Function that returns the action description of the order/task
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_task_type_actions
    (
        i_task_type_action       IN task_type_actions.id_task_type_action%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT NULL,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_func_task_description  IN task_type_actions.func_task_description%TYPE DEFAULT NULL,
        i_func_instructions      IN task_type_actions.func_instructions%TYPE DEFAULT NULL,
        i_func_task_action_desc  IN task_type_actions.func_task_action_desc%TYPE DEFAULT NULL,
        i_func_task_exec_date    IN task_type_actions.func_task_exec_date%TYPE DEFAULT NULL
    );

    /**
    * Insert a co-sign task_type action.
    *
    * @param i_id_config                Configuration identifier
    * @param i_id_inst_owner            Instituiton owner of the record (0-ALERT)
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_flg_needs_cosign         Needs cosign to order/cancel tasks? Y - yes; N - otherwise
    * @param i_flg_has_cosign           Can validate co-signed tasks? Y - yes; N - otherwise
    * @param i_flg_add_remove           Action id
    *
    * @value   i_cosign_def_action_type  ADD        - Add co-sign task
    *                                    CANCEL     - Cancel co-sign task
    *                                    HAS_COSIGN - Has cosign action
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_config_table
    (
        i_id_config              IN pk_core_config.t_low_char,
        i_id_inst_owner          IN pk_core_config.t_big_num DEFAULT pk_core_config.k_zero_value,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_flg_needs_cosign       IN pk_core_config.t_med_char, --FIELD_01
        i_flg_has_cosign         IN pk_core_config.t_med_char, --FIELD_02
        i_flg_add_remove         IN pk_core_config.t_flg_char DEFAULT pk_core_config.k_flg_type_add
    );
    --
    /**
    * Insert into config table a new task with co-sign availability
    *
    * @param i_id_config                Configuration identifier
    * @param i_id_inst_owner            Instituiton owner of the record (0-ALERT)
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_flg_add_remove           Action id
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_ctbl_has_cosign
    (
        i_id_config              IN pk_core_config.t_low_char,
        i_id_inst_owner          IN pk_core_config.t_big_num DEFAULT pk_core_config.k_zero_value,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_flg_add_remove         IN pk_core_config.t_flg_char DEFAULT pk_core_config.k_flg_type_add
    );
    --
    /**
    * Insert a co-sign task_type action.
    *
    * @param i_id_config                Configuration identifier
    * @param i_id_inst_owner            Instituiton owner of the record (0-ALERT)
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_flg_add_remove           Action id
    *
    * @value   i_cosign_def_action_type  NEEDS_COSIGN_ORDER      - Add co-sign task
    *                                    NEEDS_COSIGN_CANCEL     - Cancel co-sign task
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_ctbl_needs_cosign
    (
        i_id_config              IN pk_core_config.t_low_char,
        i_id_inst_owner          IN pk_core_config.t_big_num DEFAULT pk_core_config.k_zero_value,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_flg_add_remove         IN pk_core_config.t_flg_char DEFAULT pk_core_config.k_flg_type_add
    );
    --
    /********************************************************************************************
    * Gets the co-sign config table
    *
    * @param i_lang             Origin Institution id
    * @param i_prof             Destination institution id
    * @param i_prof_dcs         Professional dep_clin_serv
    * @param i_episode          Episode id
    * @param i_task_type        Task type id 
    * @param i_action           Action id 
    *
    * @author                      Alexandre Santos
    * @since                       2014-12-01
    * @version                     2.6.4
    ********************************************************************************************/
    FUNCTION tf_cosign_config
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_dcs  IN table_number DEFAULT NULL,
        i_episode   IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type IN task_type_actions.id_task_type%TYPE DEFAULT NULL,
        i_action    IN task_type_actions.id_action%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign_cfg;

    /********************************************************************************************
    * Gets the co-sign config table
    *
    * @param i_lang             Origin Institution id
    * @param i_prof             Destination institution id
    * @param i_prof_dcs         Professional dep_clin_serv
    * @param i_episode          Episode id
    * @param i_task_type        Task type id 
    * @param i_action           Action id 
    *
    * @author                      Alexandre Santos
    * @since                       2014-12-01
    * @version                     2.6.4
    ********************************************************************************************/
    FUNCTION tf_cosign_config
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_dcs         IN table_number DEFAULT NULL,
        i_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_tbl_id_task_type IN table_number,
        i_action           IN task_type_actions.id_action%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign_cfg;

    --
    /**
    * Checks if the current professional needs co-sign to complete the action
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  NEEDS_COSIGN_ORDER  - Add co-sign task
    *                                    NEEDS_COSIGN_CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the current professional needs co-sign to complete the action
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_tbl_task_type          Task type ids
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  NEEDS_COSIGN_ORDER  - Add co-sign task
    *                                    NEEDS_COSIGN_CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_tbl_id_task_type       IN table_number,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the current professional has permissions to co-sign tasks
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Gisela Couto
    * @version  2.6.4
    * @since    31-12-2014
    */
    FUNCTION check_prof_has_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_has_cosign    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if one co-sign task exists
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_id_co_sign             Co-sign task id
    * @param i_task                   Task id
    * @param i_task_type              Task type id
    * @param i_id_action              Action id 
    * @param o_id_co_sign             Co-sign task identifier (if exists)
    * @param o_flg_status             Flag status from co_sign task (if exists)
    * @param o_error                  Error message
    *
    * @return  true or false on success or error
    *
    * @author   Gisela Couto
    * @version  2.6.4
    * @since    18-12-2014
    */
    FUNCTION check_co_sign_task_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_co_sign    IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_task       IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_id_task_type  IN action.internal_name%TYPE DEFAULT NULL,
        i_id_action     IN action.id_action%TYPE DEFAULT NULL,
        o_id_co_sign    OUT VARCHAR2,
        o_flg_status    OUT VARCHAR2,
        o_id_order_type OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates formated co-sign task tooltip text
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_tbl_labels             Labels (text will be formated with bold style)
    * @param i_tbl_desc               Descriptions
    *                                 (The array must be the same range and the items must be 
    *                                  in the same order)
    *                        
    * @return                         Tooltip text formatted
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_tooltip_task_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tbl_labels IN table_varchar,
        i_tbl_desc   IN table_varchar
    ) RETURN CLOB;

    /********************************************************************************************
    * Gets co-sign information by episode and/or by task identifier. Returns all tasks in all 
    * statuses
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_tbl_id_co_sign         Co-sign tasks  id
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_tbl_status             Set of task status
    * @param i_id_task_group          Task group identifier
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_tasks_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type      IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign IN table_number DEFAULT NULL,
        i_prof_ord_by    IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_tbl_status     IN table_varchar DEFAULT NULL,
        i_id_task_group  IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_flg_with_desc  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_filter     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets co-sign information by episode and/or by task identifier. Returns all tasks in all 
    * statuses
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_tbl_id_co_sign         Co-sign tasks  id
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_tbl_status             Set of task status
    * @param i_id_task_group          Task group identifier
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_tasks_hist_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type           IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign      IN table_number DEFAULT NULL,
        i_tbl_id_co_sign_hist IN table_number DEFAULT NULL,
        i_prof_ord_by         IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_tbl_status          IN table_varchar DEFAULT NULL,
        i_id_task_group       IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_flg_with_desc       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_id_task         IN table_number DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets information about pending co-sign tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_pending_co_sign_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_flg_with_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets information about co-signed tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_signed_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_flg_with_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets information about outdated co-sign tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_outdated_co_sign_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_flg_with_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Validate the input co-sign task status 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_order_type          Order type identifier 
    * @param i_flg_status             Co-sign task flag status ('P' - Peding, 'D' - Draft)
    *                        
    * @return                         Returns a valid co-sign task flag status
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/18
    **********************************************************************************************/
    FUNCTION get_co_sign_flg_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE,
        i_flg_status    IN sys_domain.val%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if order type generates co_sign workflow
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_order_type          Order type identifier 
    *                        
    * @return                         Returns 'Y' or 'N'
    * 
    * @author                         Nuno Alves
    * @version                        2.6.5
    * @since                          2015/04/22
    **********************************************************************************************/
    FUNCTION get_order_type_generates_wf
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Insert co-sign task in co_sign_hist table, by co-sign task identifier
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign             Co-sign identifier 
    * @param o_notes_trans_code       Code translation notes
    * @param o_id_prof_ordered        Ordered by professional id    
    * @param o_id_co_sign_hist        Co-sign history record identifier        
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/18
    **********************************************************************************************/
    FUNCTION insert_into_co_sign_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_co_sign       IN co_sign.id_co_sign%TYPE,
        o_notes_trans_code OUT translation.code_translation%TYPE,
        o_id_prof_ordered  OUT professional.id_professional%TYPE,
        o_id_co_sign_hist  OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Verify if a co-sign task can be co-signed inline
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_id_co_sign             Co-sign identifier 
    * @param i_id_task_group          Co-sign task group
    * @param i_task_type              Task type identifier
    *                        
    * @return                         Value 'Y' (yes) or 'N' (no)
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/21
    **********************************************************************************************/
    FUNCTION check_task_co_sign_inline
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_co_sign    IN co_sign.id_co_sign%TYPE,
        i_id_task_group IN co_sign.id_task_group%TYPE,
        i_task_type     IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets existing co-sign tasks by episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param o_co_sign_list           Cursor containing the task list to co-sign 
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION get_cosign_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_filter   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_co_sign_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates the co-sign task in draft status
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_task_type            Task type identifier
    * @param i_id_action               Action identifier
    * @param i_cosign_def_action_type  Co-sign default action ('NEEDS_COSIGN_ORDER', 'NEEDS_COSIGN_CANCEL',
                                       'HAS_COSIGN')       
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param o_id_co_sign              Co-sign record identifier created  
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_draft_co_sign_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_co_sign             IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_co_sign_hist        IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type           IN task_type.id_task_type%TYPE,
        i_id_action              IN action.id_action%TYPE DEFAULT NULL,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT pk_co_sign.g_cosign_action_def_add,
        i_id_task                IN co_sign.id_task%TYPE,
        i_id_task_group          IN co_sign.id_task_group%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE,
        --
        i_dt_created      IN co_sign.dt_created%TYPE,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates the co-sign task in pending status
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign task identifier (to be updated)
    * @param i_id_task_type            Task type identifier
    * @param i_id_action               Action identifier
    * @param i_cosign_def_action_type  Co-sign default action ('NEEDS_COSIGN_ORDER', 'NEEDS_COSIGN_CANCEL',
                                       'HAS_COSIGN')       
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param o_id_co_sign              Co-sign record identifier created
    * @param o_id_co_sign_hist         Co-sign history record id created  
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_pending_co_sign_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_co_sign             IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist        IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type           IN task_type.id_task_type%TYPE,
        i_id_action              IN action.id_action%TYPE DEFAULT NULL,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT pk_co_sign.g_cosign_action_def_add,
        i_id_task                IN co_sign.id_task%TYPE,
        i_id_task_group          IN co_sign.id_task_group%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE,
        --
        i_dt_created      IN co_sign.dt_created%TYPE,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns co-sign detail information 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign task identifier
    * @param i_flg_detail              Detail type: 'C'- current information details
    *                                               'H' - History of changes 
    * @param i_tbl_status              Co-sign task flag status list ('CS' - Cosigned)
    * @param o_co_sign_info            Co-sign details
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION get_co_sign_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN table_number,
        i_flg_detail   IN VARCHAR2,
        i_tbl_status   IN table_varchar DEFAULT NULL,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Change co-sign task status to "outdated" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_id_co_sign_hist         Co_sign_hist record identifiers
    * @param i_dt_update               Date when record was updated
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_outdated
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_dt_update       IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Change co-sign task status to "pending" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_id_co_sign_hist         Co_sign_hist record identifiers
    * @param i_dt_update               Date when record was updated
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_pending
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_upd     IN co_sign.id_task%TYPE DEFAULT NULL,
        i_dt_update       IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Changes the co-sign status to "co-signed" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_tbl_id_co_sign              Co-sign record identifier
    * @param i_cosign_notes            Co-sign notes
    * @param i_flg_made_auth           Flag that indicates if professional was made authentication: 
                                       (Y) - Yes, (N) - No
    * @param o_tbl_id_co_sign_hist     Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_co_signed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_tbl_id_co_sign      IN table_number,
        i_id_prof_cosigned    IN co_sign.id_prof_co_signed%TYPE,
        i_dt_cosigned         IN co_sign.dt_co_signed%TYPE DEFAULT current_timestamp,
        i_cosign_notes        IN translation_trs.desc_translation%TYPE,
        i_flg_made_auth       IN co_sign.flg_made_auth%TYPE,
        o_tbl_id_co_sign_hist OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Match co-sign task from id_episode to id_episode_new  
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              Old episode identifier
    * @param i_id_episode_new          New episode identifier
    *
    * @param o_error                   Error message       
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2015/01/13
    **********************************************************************************************/

    FUNCTION match_co_sign_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_episode_new IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns de id_action based on the default co-sign actions  
    *
    * @param i_cosign_def_action_type  The default co_sign action (order or cancel)
    *
    * @param o_error                   Error message       
    *                    
    * @return                         id_action
    * 
    * @author                         Nuno Alves
    * @since                          2015/04/10
    **********************************************************************************************/
    FUNCTION get_id_action
    (
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE
    ) RETURN action.id_action%TYPE;

    /*********************************************************************************************
    * This function deletes all data related to a co-sign request for patient (all episodes) 
    * or for a singular patient episode. 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_patients             Array of patient identifiers
    * @param i_id_episodes             Array of episode identifiers
    *
    * @param o_error                   Error message       
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Renato Nunes
    * @since                          2015/04/10
    **********************************************************************************************/

    FUNCTION reset_cosign_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * This function deletes all task_type data related to a co-sign request in a task_type_group
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              Episode identifier
    * @param i_id_task_group           Task group identifiers
    * @param i_id_task_type            Task Type identifier
    *
    * @param o_error                   Error message       
    *                    
    * @return                          true or false on success or error
    * 
    * @author                          Renato Nunes
    * @since                           2015/04/13
    **********************************************************************************************/

    FUNCTION remove_draft_cosign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_task_group IN task_group.id_task_group%TYPE,
        i_id_task_type  IN task_type.id_task_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_co_sign_from_hist(i_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE)
        RETURN co_sign_hist.id_co_sign%TYPE;

    /********************************************************************************************
    * Gets co-sign information by episode and/or by task identifier. Returns all tasks in all 
    * statuses
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_tbl_id_co_sign         Co-sign tasks  id
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_tbl_status             Set of task status
    * @param i_id_task_group          Task group identifier
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016/11/04
    **********************************************************************************************/

    FUNCTION tf_co_sign_tasks_info_int
    (
        i_prof          IN profissional,
        i_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        i_prof_ord_by     IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_task_type       IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign  IN table_number DEFAULT NULL,
        i_total_id_cs     IN NUMBER,
        i_tbl_status      IN table_varchar DEFAULT NULL,
        i_total_status_cs IN NUMBER,
        i_id_task_group   IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_flg_filter      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign_int;

    /********************************************************************************************
    * Gets List of profile templates that can co-sign tasks
    * @param i_lang             Language
    * @param i_prof             profissional
    * @param i_profile_template Profile_template
    *
    * @author                      Elisabete Bugalho
    * @since                       2017/01/12
    * @version                     2.7.0
    ********************************************************************************************/
    FUNCTION tf_get_prof_co_sign
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;

    FUNCTION tf_cs_t_hist_info_int
    (
        i_episode             IN episode.id_episode%TYPE DEFAULT NULL,
        i_prof_ord_by         IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_task_type           IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign      IN table_number DEFAULT NULL,
        i_total_id_cs         IN NUMBER,
        i_tbl_id_co_sign_hist IN table_number DEFAULT NULL,
        i_total_id_csh        IN NUMBER,
        i_tbl_status          IN table_varchar DEFAULT NULL,
        i_total_status_cs     IN NUMBER,
        i_id_task_group       IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_tbl_id_task         IN table_number DEFAULT NULL
    ) RETURN t_tab_cs_t_hist_int;

    FUNCTION get_co_sign_detail_ux
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_co_sign IN NUMBER,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_co_sign_detail_ux_h
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_co_sign IN NUMBER,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_co_sign;
/
