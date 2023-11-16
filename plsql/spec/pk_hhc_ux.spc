/*-- Last Change Revision: $Rev: 1974062 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-12-14 14:46:46 +0000 (seg, 14 dez 2020) $*/

CREATE OR REPLACE PACKAGE pk_hhc_ux IS

    -- Author  : VITOR.SA
    -- Created : 12/11/2019 09:03:04
    -- Purpose :

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
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --get details from hhc request
    FUNCTION get_hhc_req_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_root_name  IN ds_component.internal_name%TYPE,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_request
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_epis_hhc_req     IN NUMBER,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION discontinue_request
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_epis_hhc_req     IN NUMBER,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    -- to allow fvalidation if prof is mrp
    FUNCTION get_prof_flg_mrp
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_flg_mrp OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_case_manager_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hhc         IN epis_hhc_req.id_epis_hhc%TYPE,
        o_id_prof_cmanager OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_subject      IN VARCHAR2,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_discharge_validation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode in episode.id_episode%type,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_disch_status    IN discharge_status.id_discharge_status%TYPE,
        o_desc_msg           OUT sys_message.desc_message%TYPE,
        o_popup_type         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /* função para validar se exibe mensagem de acesso a um referral
    exibe mensagem quando o profissional que está a aceder é o case manager do pedido e se o estado do pedido FOR partial acepted
        */

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

    /* função para fazer UPDATE ao estado do referral
       coloca o referral "IN evaluation
    */
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
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req %TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION remove_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req %TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --get the flg_status of epis_hhc_request
    FUNCTION get_epis_hhc_req_flg_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_status     OUT epis_hhc_req.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_team_categories
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_team_professionals
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_professional        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*FUNCTION get_req_status_formatted
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;*/

    FUNCTION set_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_professional     IN table_number,
        i_id_prof_team_in  IN prof_team.id_prof_team%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        o_id_prof_team_out OUT prof_team.id_prof_team%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_team_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        i_flg_action  IN VARCHAR2,
        o_team_detail OUT pk_types.cursor_type,
        o_team_edit   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hhc_id_department
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_id_department OUT department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_can_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_edit OUT VARCHAR2,
        o_error        OUT t_error_out
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

    FUNCTION get_intensity_hhc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION save_hhc_discharge
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        id_epis_hhc_req       IN epis_hhc_req.id_epis_hhc_req%TYPE,
        id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_tbl_mkt_rel         IN table_number,
        i_value               IN table_table_varchar,
        i_value_clob          IN table_clob,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_cancel_hhd_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_cancel_reason IN epis_out_on_pass.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_disch_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_disch_actions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_actions          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hhc_req_status_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_root_name  IN ds_component.internal_name%TYPE,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_detail IN VARCHAR2,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_team_det_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        o_team_detail OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_disch_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_epis_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_list            OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_edit   OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --*****************************************************
    FUNCTION get_visits_actions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_state IN table_varchar,
        i_subject   IN VARCHAR2,
        o_actions   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    -- change status of visits ( scheduled, undo )
    FUNCTION set_visit_status
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_ids    IN table_number,
        i_action IN VARCHAR2,
		i_id_reason in number,
		i_rea_note  in VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

	FUNCTION get_prof_can_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_cancel OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
END pk_hhc_ux;
/
