/*-- Last Change Revision: $Rev: 1997789 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2021-09-14 17:43:08 +0100 (ter, 14 set 2021) $*/

CREATE OR REPLACE PACKAGE pk_hhc_core IS

    -- Author  : VITOR.SA
    -- Created : 08/11/2019 16:22:40
    -- Purpose : hhc requests

    -- Public type declarations

    -- Public constant declarations

    g_action_edit    CONSTANT action.id_action%TYPE := 235534079;
    g_action_submit  CONSTANT action.id_action%TYPE := 235534028;
    g_action_default CONSTANT action.id_action%TYPE := 235534078;
    g_package_name VARCHAR2(32);

    -- Public variable declarations

    -- Public function and procedure declarations
    FUNCTION save_hhc_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_tbl_mkt_rel   IN table_number,
        i_value         IN table_table_varchar,
        i_value_clob    IN table_clob,
        o_result        OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_prof_request(i_epis_hhc_req IN NUMBER) RETURN NUMBER;
    FUNCTION get_id_prof_status
    (
        i_epis_hhc_req IN NUMBER,
        i_flg_status   IN VARCHAR2,
        i_order        IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN NUMBER;

    FUNCTION get_id_prof_coordinator(i_epis_hhc_req IN NUMBER) RETURN NUMBER;
    -- ********************************
    FUNCTION get_dt_status
    (
        i_epis_hhc_req IN NUMBER,
        i_flg_status   IN VARCHAR2
    ) RETURN v_epis_hhc_req_status.dt_status%TYPE;

    FUNCTION get_dt_request(i_epis_hhc_req IN NUMBER) RETURN v_epis_hhc_req_status.dt_status%TYPE;
    -- ***************************************** 
    FUNCTION get_dt_closed(i_epis_hhc_req IN NUMBER) RETURN v_epis_hhc_req_status.dt_status%TYPE;
    -- *****************************************  
    FUNCTION get_type_origin_value
    (
        i_lang         IN NUMBER,
        i_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_type_name    IN VARCHAR2
    ) RETURN VARCHAR2;
    -- *****************************************  
    FUNCTION get_origin_text(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN epis_hhc_req_det.hhc_value%TYPE;
    -- *****************************************     
    FUNCTION get_id_case_manager(i_epis_hhc IN epis_hhc_req.id_epis_hhc%TYPE) RETURN NUMBER;
    -- *****************************************  
    FUNCTION get_prof_case_manager_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hhc         IN epis_hhc_req.id_epis_hhc%TYPE,
        o_id_prof_cmanager OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --get details from hhc request
    FUNCTION get_hhc_req_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_root_name  IN ds_component.internal_name%TYPE,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_report IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_default_values_hhc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    --obtem o histórico de alterações
    FUNCTION get_hhc_req_det_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tbl_id_req IN table_number,
        i_flg_report IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_flg_mrp
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION check_if_prof_can_cancel
    (
        i_flg_status IN VARCHAR2,
        i_flg_mrp    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION check_if_prof_can_edit
    (
        i_flg_status IN VARCHAR2,
        i_flg_mrp    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION check_if_prof_can_discon
    (
        i_flg_status IN VARCHAR2,
        i_flg_mrp    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION check_action_available
    (
        --    i_lang               IN NUMBER,
        --    i_prof               IN profissional,
        i_hhc_request        IN NUMBER,
        i_action_name        IN VARCHAR2,
        i_has_mrp_permission IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION check_active_action
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_action_name IN VARCHAR2,
        i_hhc_request IN NUMBER,
        i_subject     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_subject      IN VARCHAR2,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_hhc_req_by_patient(i_patient IN NUMBER) RETURN NUMBER;

    FUNCTION get_value(i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE) RETURN VARCHAR2;
    FUNCTION get_text(i_id_epis_hhc_req_det IN epis_hhc_req_det.id_epis_hhc_req_det%TYPE) RETURN CLOB;

    FUNCTION get_edit_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_root_name       IN VARCHAR2
        --        ,        o_error           OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_detail_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN hhc_det_type.flg_type%TYPE,
        i_type_name IN hhc_det_type.type_name%TYPE,
        i_value     IN epis_hhc_req_det.hhc_value%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_consult_in_charge
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_internal_name IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION create_hhc_process(i_prof IN profissional,
                                -- i_hhc_req    IN NUMBER,
                                i_id_patient IN NUMBER) RETURN NUMBER;

    FUNCTION get_epis_hhc_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN epis_hhc_req.flg_status%TYPE;

    FUNCTION set_new_hhc_referral_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_hhc_approved_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_hhc_reject_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode IN episode.id_episode%TYPE,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_hhc_end_follow_up_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode IN episode.id_episode%TYPE,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_hhc_case_manager_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode IN episode.id_episode%TYPE,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_id_hhc_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN epis_hhc_req.id_epis_hhc_req%TYPE;

    FUNCTION get_all_hhc_req_from_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN table_number;

    FUNCTION is_coordinator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION is_case_manager
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION set_hhc_alert_general
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req    IN NUMBER,
        i_episode      IN episode.id_episode%TYPE,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_alert_msg    IN VARCHAR2,
        i_id_professional IN NUMBER DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_epis_req
    (
        i_prof                IN profissional,
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status          IN epis_hhc_req.flg_status%TYPE,
        i_id_prof_manager     IN epis_hhc_req.id_prof_manager%TYPE,
        i_dt_prof_manager     IN epis_hhc_req.dt_prof_manager%TYPE,
        i_prof_null           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_prof_coordinator IN epis_hhc_req.id_prof_coordinator%TYPE,
        i_id_cancel_reason    IN epis_hhc_req.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_hhc_req.cancel_notes%TYPE
        
    ) RETURN BOOLEAN;

    FUNCTION get_ref_message_access
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_hhc       IN epis_hhc_req.id_epis_hhc%TYPE,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_msg            OUT sys_message.desc_message%TYPE,
        o_flg_msg        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_ref_status_ie
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_assign_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION remove_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_prev_status     IN VARCHAR2 DEFAULT pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_discharge_validation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_disch_status    IN discharge_status.id_discharge_status%TYPE,
        o_desc_msg           OUT sys_message.code_message%TYPE,
        o_popup_type         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_status_partially_accept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_req_status_formatted
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_detail      IN VARCHAR2,
        io_req_det        IN OUT t_coll_hhc_req_hist,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
	
    /*
    FUNCTION get_epis_hhc_req_flg_status
      (
          i_lang           IN language.id_language%TYPE,
          i_prof           IN profissional,
          i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
          o_error          OUT t_error_out
      ) RETURN epis_hhc_req.flg_status%TYPE;
      */
    FUNCTION get_hhc_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN epis_hhc_req_det.hhc_value%TYPE,
        i_type_name hhc_det_type.type_name%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_all_epis_hhc_req_by_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status        IN table_varchar,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE
    ) RETURN t_coll_epis_hhc_req;

    FUNCTION get_approved_epis_hhc_req_tf
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min       IN NUMBER,
        i_age_max       IN NUMBER,
        i_gender        IN VARCHAR2,
        i_page          IN NUMBER DEFAULT 1,
        i_rows_per_page IN NUMBER DEFAULT 20,
        o_row_count         OUT NUMBER
    ) RETURN t_coll_wl_hhc_req;

    FUNCTION get_approved_epis_hhc_req
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min       IN NUMBER,
        i_age_max       IN NUMBER,
        i_gender        IN VARCHAR2,
        i_page          IN NUMBER DEFAULT 1,
        i_rows_per_page IN NUMBER DEFAULT 20,
        o_data          OUT t_wl_search_row_coll,
        o_row_count     OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_approved_epis_hhc_req_curs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min           IN NUMBER,
        i_age_max           IN NUMBER,
        i_gender            IN VARCHAR2,
        i_page              IN NUMBER DEFAULT 1,
        i_rows_per_page     IN NUMBER DEFAULT 20,
        o_data              OUT pk_types.cursor_type,
        o_row_count         OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_desc_value
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_component IN VARCHAR2,
        i_value     IN VARCHAR2,
        i_type_name IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_type_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        flg_component_type IN ds_component.flg_component_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION upd_req_status_general
    (
        i_id_epis_hhc_req IN epis_hhc_req_status.id_epis_hhc_req %TYPE,
        i_id_professional IN professional.id_professional%TYPE DEFAULT NULL,
        i_flg_status      IN VARCHAR2,
        i_dt_status       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_reason       IN NUMBER DEFAULT NULL,
        i_reason_notes    IN CLOB DEFAULT NULL,
        i_what_2_upd      IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION set_status_approve
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_team_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        o_team_detail OUT pk_types.cursor_type,
        
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_request_status
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_epis_hhc_req     IN NUMBER,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    
    FUNCTION get_flg_status(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN VARCHAR2;
    FUNCTION has_case_manager(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER;

    FUNCTION get_epis_hhc_flg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_status      OUT epis_hhc_req.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
     
    FUNCTION get_hhc_id_department
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_id_department OUT department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
	
    FUNCTION check_action_avail_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_status_reject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_status_undo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --função para devolver o motivo de cancelamento ou de aprovação de um request e as notas
    FUNCTION get_hhc_req_reason_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tbl_id_hhc_rec IN table_number,
        i_flg_report     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_can_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_edit OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_team_id_professional
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN table_number;

    --função para alterar o estado do request para "IN EVALUATION" quando existem alterações 
    --nos ecrãs(supplies, plan, health education)
    --efetuadas pelo case manager e o estado do request é "PARTIALLY ACCEPTED"
    FUNCTION set_req_status_ie
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_epis_hhc_by_hhc_req(i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE)
        RETURN epis_hhc_req.id_epis_hhc%TYPE;

    FUNCTION get_hhc_dt_admission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_hhc_dt_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_hhc_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_hhc_professional
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_hhc_message
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    
        FUNCTION get_home_care_shortcut
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
       i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;
	
    FUNCTION is_part_of_team
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN NUMBER,
        i_team            IN table_number
    ) RETURN VARCHAR2;

    FUNCTION get_id_req_by_epis_hhc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN epis_hhc_req.id_epis_hhc_req%TYPE;

    FUNCTION get_reason
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status      IN epis_hhc_req_status.flg_status%TYPE,
        i_dt_creation     IN epis_hhc_req_h.dt_creation%TYPE
    ) RETURN CLOB;

	FUNCTION get_id_case_manager_by_id_req(i_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER;
	
    FUNCTION get_active_hhc_episode(i_patient IN NUMBER) RETURN NUMBER;
    FUNCTION get_active_hhc_request(i_patient IN NUMBER) RETURN NUMBER;

    -- ***********************************
    FUNCTION set_status_in_progress
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --**************************************************************
    FUNCTION check_all_schedule_pending(i_hhc_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_epis_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_team_profile_template
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN table_number;

    FUNCTION get_visit_status_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2;

    --************************************************************
    FUNCTION get_prof_team_det_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        o_team_detail OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_hhc_epis_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_epis_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_list            OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_hhc_next_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_dt_schedule     IN schedule.dt_begin_tstz%TYPE
    ) RETURN table_number;

    FUNCTION check_has_next_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_page_sections_hhc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_edit_avail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_id_epis_hhc_req_by_pat(i_id_patient IN episode.id_patient%TYPE) RETURN epis_hhc_req.id_epis_hhc_req%TYPE;

    FUNCTION get_id_hhc_req_by_epis(i_id_episode IN episode.id_episode%TYPE) RETURN epis_hhc_req.id_epis_hhc_req%TYPE;

    FUNCTION get_appr_epis_hhc_req_base_tf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min           IN NUMBER,
        i_age_max           IN NUMBER,
        i_gender            IN VARCHAR2,
        i_page              IN NUMBER DEFAULT 1,
        i_rows_per_page     IN NUMBER DEFAULT 20
    ) RETURN t_coll_wl_hhc_req;

    FUNCTION set_status_close
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_visit_information
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_first_dt        OUT schedule_outp.dt_target_tstz%TYPE,
        o_last_dt         OUT schedule_outp.dt_target_tstz%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    
        FUNCTION check_team_has_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_inst        IN table_number,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_list_prof_cat
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN sch_resource.id_schedule%TYPE,
        i_flg_action  IN VARCHAR2
    ) RETURN VARCHAR2;

    -- ************************** cmf 
    FUNCTION get_team_id_professional
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tbl_inst   IN table_number,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN table_number;

    FUNCTION upd_flg_undone
    (
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_status      IN VARCHAR2 DEFAULT NULL,
        i_dt_status       IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN BOOLEAN;

    FUNCTION get_prof_signature
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_sign IN epis_hhc_req_det_h.id_prof_creation%TYPE,
        i_date         IN epis_hhc_req_det_h.dt_creation%TYPE
    ) RETURN VARCHAR2;

    -- this FUNCTION is used IN plan screen
    FUNCTION get_prof_can_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_cancel OUT VARCHAR2,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_coordinator
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN NUMBER;

    FUNCTION check_approved_request(i_patient IN NUMBER) RETURN VARCHAR2;
    
	FUNCTION get_profile_template
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN NUMBER
    ) RETURN VARCHAR2;
        
    FUNCTION get_prof_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN number;

    -- get index of value inside array
    FUNCTION get_idx
    (
        i_array IN table_number,
        i_value IN NUMBER
    ) RETURN NUMBER;

    --***************************************
    FUNCTION get_submit_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          IN t_error_out
    ) RETURN t_tbl_ds_get_value;

    --****************************************

    FUNCTION submit_for_translations
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          IN t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION submit_prof_in_charge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          IN t_error_out
    ) RETURN t_tbl_ds_get_value;

    --- temporary
    -- ***************************************
    FUNCTION get_new_values
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN NUMBER,
        i_patient     IN patient.id_patient%TYPE,
        i_tbl_mkt_rel IN table_number
    ) RETURN t_tbl_ds_get_value;

FUNCTION get_id_episode_by_hhc_req(i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE) RETURN NUMBER;

END pk_hhc_core;
/
