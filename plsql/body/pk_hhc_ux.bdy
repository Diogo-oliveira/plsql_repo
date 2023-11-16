/*-- Last Change Revision: $Rev: 1974063 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-12-14 14:48:03 +0000 (seg, 14 dez 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hhc_ux IS

    --g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';

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
    ) RETURN BOOLEAN IS
        l_ret    BOOLEAN;
        l_result NUMBER;
    BEGIN
        l_ret := pk_hhc_core.save_hhc_request(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_id_episode    => i_id_episode,
                                              i_id_patient    => i_id_patient,
                                              id_epis_hhc_req => id_epis_hhc_req,
                                              i_tbl_mkt_rel   => i_tbl_mkt_rel,
                                              i_value         => i_value,
                                              i_value_clob    => i_value_clob,
                                              o_result        => l_result,
                                              o_error         => o_error);
    
        IF l_ret
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_ret;
    
    END save_hhc_request;

    --get details from hhc request
    FUNCTION get_hhc_req_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_root_name  IN ds_component.internal_name%TYPE,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_hhc_core.get_hhc_req_det(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_root_name  => i_root_name,
                                           i_id_request => i_id_request,
                                           o_detail     => o_detail,
                                           o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_hhc_req_det;

    FUNCTION get_hhc_req_status_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_root_name  IN ds_component.internal_name%TYPE,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_detail IN VARCHAR2,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_hhc_core.get_hhc_req_det(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_root_name  => i_root_name,
                                           i_id_request => i_id_request,
                                           i_flg_report => i_flg_detail,
                                           o_detail     => o_detail,
                                           o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_hhc_req_status_det;

    FUNCTION cancel_request
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_epis_hhc_req     IN NUMBER,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
        l_bool := pk_hhc_core.update_request_status(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_epis_hhc_req     => i_epis_hhc_req,
                                                    i_flg_status       => pk_hhc_constant.k_hhc_req_status_canceled,
                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                    i_notes            => i_notes,
                                                    o_error            => o_error);
        IF l_bool
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_bool;
    
    END cancel_request;

    FUNCTION discontinue_request
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_epis_hhc_req     IN NUMBER,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
        l_bool := pk_hhc_core.update_request_status(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_epis_hhc_req     => i_epis_hhc_req,
                                                    i_flg_status       => pk_hhc_constant.k_hhc_req_status_discontinued,
                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                    i_notes            => i_notes,
                                                    o_error            => o_error);
        IF l_bool
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_bool;
    
    END discontinue_request;

    -- to allow fvalidation if prof is mrp
    FUNCTION get_prof_flg_mrp
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_flg_mrp OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count  NUMBER;
        l_return VARCHAR2(0010 CHAR);
    BEGIN
    
        l_return := pk_hhc_core.get_prof_flg_mrp(i_lang, i_prof);
    
        IF l_return = k_yes
        THEN
        
            l_count := pk_hhc_core.get_count_hhc_req_by_patient(i_patient);
        
            IF l_count > 0
            THEN
                l_return := k_no;
            END IF;
        
        END IF;
    
        o_flg_mrp := l_return;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              SQLERRM,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_FLG_MRP',
                                              o_error);
            pk_utils.undo_changes();
            o_flg_mrp := k_no;
            RETURN FALSE;
    END get_prof_flg_mrp;

    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hhc_req IN NUMBER,
        i_subject      IN VARCHAR2,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_hhc_core.get_actions(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_epis_hhc_req => i_epis_hhc_req,
                                       i_subject      => i_subject,
                                       o_actions      => o_actions,
                                       o_error        => o_error);
    
    END get_actions;

    FUNCTION get_prof_case_manager_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hhc         IN epis_hhc_req.id_epis_hhc%TYPE,
        o_id_prof_cmanager OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_hhc_core.get_prof_case_manager_list(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_epis_hhc         => i_epis_hhc,
                                                      o_id_prof_cmanager => o_id_prof_cmanager,
                                                      o_error            => o_error);
    
    END get_prof_case_manager_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hhc_core.get_discharge_validation(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_id_patient         => i_id_patient,
                                                    i_id_episode=>i_id_episode,
                                                    i_id_disch_reas_dest => i_id_disch_reas_dest,
                                                    i_id_disch_status    => i_id_disch_status,
                                                    o_desc_msg           => o_desc_msg,
                                                    o_popup_type         => o_popup_type,
                                                    o_error              => o_error);
    
    END get_discharge_validation;

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
    ) RETURN BOOLEAN IS
        --l_id_case_manager epis_hhc_req.id_prof_manager%TYPE;
        --l_hhc_req_status  epis_hhc_req.flg_status%TYPE;
    BEGIN
    
        RETURN pk_hhc_core.get_ref_message_access(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_epis_hhc       => i_epis_hhc,
                                                  i_id_hhc_request => i_id_hhc_request,
                                                  o_msg            => o_msg,
                                                  o_flg_msg        => o_flg_msg,
                                                  o_error          => o_error);
    
    END get_ref_message_access;

    /* função para fazer UPDATE ao estado do referral
       coloca o referral "IN evaluation
    */
    FUNCTION set_ref_status_ie
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.set_ref_status_ie(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_hhc_request => i_id_hhc_request,
                                             o_error          => o_error);
    END set_ref_status_ie;

    FUNCTION remove_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req %TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.remove_case_man(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_epis_hhc_req => i_id_epis_hhc_req,
                                           o_error           => o_error);
    END remove_case_man;

    --get the flg_status of epis_hhc_request
    FUNCTION get_epis_hhc_req_flg_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_status     OUT epis_hhc_req.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.get_epis_hhc_flg_status(i_lang            => i_lang,
                                                       i_prof           => i_prof,
                                                   i_id_epis_hhc_req => i_id_hhc_request,
                                                   o_flg_status      => o_flg_status,
                                                       o_error          => o_error);
    
    END get_epis_hhc_req_flg_status;

    FUNCTION get_team_categories
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_prof_teams.get_team_categories(i_lang     => i_lang,
        i_prof     => i_prof,
        o_category => o_category,
                                                 o_error    => o_error);
    
    END get_team_categories;

    FUNCTION get_team_professionals
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_professional        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_prof_teams.get_team_professionals(i_lang                => i_lang,
        i_prof                => i_prof,
        i_id_profile_template => i_id_profile_template,
        o_professional        => o_professional,
                                                    o_error               => o_error);
    END get_team_professionals;

    /*FUNCTION get_req_status_formatted
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
    
        l_ret := pk_hhc_core.get_req_status_formatted(i_lang            => i_lang,
                                                     i_prof    => i_prof,
                                                      i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                     o_data    => o_data,
                                                     o_error   => o_error);
    
        RETURN l_ret;
    
    END get_req_status_formatted;*/

    --function used to create or update hhc teams
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_id_prof_team_in IS NULL
                THEN
        
                    RETURN pk_prof_teams.create_prof_team_internal(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_department       => i_id_department,
                                                                   i_prof_team_name   => NULL,
                                                                   i_team_dt_begin    => NULL,
                                                                   i_team_dt_end      => NULL,
                                                                   i_notes            => NULL,
                                                                   i_professional     => i_professional,
                                                                   i_prof_dt_begin    => i_prof_dt_begin,
                                                                   i_prof_dt_end      => i_prof_dt_end,
                                                                   i_prof_notes       => i_prof_notes,
                                                                   i_team_type        => NULL,
                                                                   i_prof_team_leader => NULL,
                                                                   i_id_episode       => i_id_episode,
                                                                   o_id_prof_team     => o_id_prof_team_out,
                                                                   o_error            => o_error);
                
                ELSE
                    o_id_prof_team_out := i_id_prof_team_in;
                    RETURN pk_prof_teams.set_prof_team(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_prof_team      => i_id_prof_team_in,
                                                       i_department     => NULL,
                                                       i_prof_team_name => NULL,
                                                       i_team_dt_begin  => NULL,
                                                       i_team_dt_end    => NULL,
                                                       i_notes          => NULL,
                                                       i_professional   => i_professional,
                                                       i_prof_dt_begin  => i_prof_dt_begin,
                                                       i_prof_dt_end    => i_prof_dt_end,
                                                       i_prof_notes     => i_prof_notes,
                                                       o_error          => o_error);
                END IF;
    
    END set_prof_team;

    FUNCTION get_prof_team_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        i_flg_action  IN VARCHAR2,
        o_team_detail OUT pk_types.cursor_type,
        o_team_edit   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_team_detail pk_types.cursor_type;
    BEGIN
        pk_types.open_my_cursor(o_team_edit);
        --get team members for edit screen
        IF i_flg_action = pk_alert_constant.g_flg_action_e
        THEN
            pk_types.open_my_cursor(o_team_detail);
            RETURN pk_prof_teams.get_prof_team_det(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_prof_team => i_prof_team,
                                                   o_team_reg  => l_team_detail,
                                                   o_team_val  => o_team_edit,
                                                   o_error     => o_error);
        ELSIF i_flg_action = pk_alert_constant.g_flg_action_d
        THEN
            --get team members for detail screen
            RETURN pk_hhc_core.get_prof_team_det(i_lang        => i_lang,
                                                   i_prof      => i_prof,
                                                   i_prof_team => i_prof_team,
                                                 o_team_detail => o_team_detail,
                                                   o_error     => o_error);
        
        END IF;
    
    END get_prof_team_det;

    --função utilizada no hhc -> plan
    FUNCTION get_hhc_id_department
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_id_department OUT department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_hhc_core.get_hhc_id_department(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 o_id_department => o_id_department,
                                                 o_error         => o_error);
    
    END get_hhc_id_department;

    FUNCTION get_id_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_prof_teams.get_id_prof_team(i_lang         => i_lang,
        i_prof         => i_prof,
                                              i_id_hhc_req   => i_id_hhc_req,
        o_id_prof_team => o_id_prof_team,
                                              o_error        => o_error);
    
    END get_id_prof_team;

    FUNCTION set_assign_case_man
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req %TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.set_assign_case_man(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_id_epis_hhc_req => i_id_epis_hhc_req,
                                               i_id_prof_manager => i_id_prof_manager,
                                               i_id_reason       => NULL,
                                               i_reason          => NULL,
                                               o_error           => o_error);
    END set_assign_case_man;

    FUNCTION get_prof_can_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_edit OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.get_prof_can_edit(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_id_hhc_req   => i_id_hhc_req,
                                             o_flg_can_edit => o_flg_can_edit,
                                             o_error        => o_error);
    
    END get_prof_can_edit;

    FUNCTION set_status_approve
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hhc_core.set_status_approve(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_epis_hhc_req => i_id_epis_hhc_req,
                                              i_id_reason       => i_id_reason,
                                              i_reason          => i_reason,
                                              o_error           => o_error);
    
    END set_status_approve;

    FUNCTION set_status_partially_accept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_prof_manager IN epis_hhc_req.id_prof_manager%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hhc_core.set_status_partially_accept(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                       i_id_prof_manager => i_id_prof_manager,
                                                       i_id_reason       => i_id_reason,
                                                       i_reason          => i_reason,
                                                       o_error           => o_error);
    
    END set_status_partially_accept;

    FUNCTION set_status_reject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hhc_core.set_status_reject(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_epis_hhc_req => i_id_epis_hhc_req,
                                             i_id_reason       => i_id_reason,
                                             i_reason          => i_reason,
                                             o_error           => o_error);
    
    END set_status_reject;

    FUNCTION set_status_undo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_reason       IN epis_hhc_req_status.id_cancel_reason%TYPE,
        i_reason          IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hhc_core.set_status_undo(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_epis_hhc_req => i_id_epis_hhc_req,
                                           i_id_reason       => i_id_reason,
                                           i_reason          => i_reason,
                                           o_error           => o_error);
    
    END set_status_undo;

    FUNCTION get_intensity_hhc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_prog_notes_in.get_intensity_hhc(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_patient     => i_id_patient,
                                                  i_tbl_id_request => table_number(i_id_request),
                                                  o_data           => o_data,
                                                  o_error          => o_error);
    END;

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
    ) RETURN BOOLEAN IS
        l_ret    BOOLEAN;
        l_result NUMBER;
    BEGIN
        l_ret := pk_hhc_discharge.save_hhc_discharge(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     id_epis_hhc_req       => id_epis_hhc_req,
                                                     id_epis_hhc_discharge => id_epis_hhc_discharge,
                                                     i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                     i_value               => i_value,
                                                     i_value_clob          => i_value_clob,
                                                     o_result              => l_result,
                                                     o_error               => o_error);
    
        IF l_ret
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_ret;
    
    END save_hhc_discharge;

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
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := pk_hhc_discharge.set_cancel_hhd_discharge(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_hhc_discharge => i_id_hhc_discharge,
                                                           i_id_cancel_reason => i_id_cancel_reason,
                                                           i_cancel_notes     => i_cancel_notes,
                                                           o_error            => o_error);
    
        IF l_ret
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_ret;
    
    END set_cancel_hhd_discharge;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_disch_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_hhc_discharge.get_discharge_list(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                   o_disch_list      => o_disch_list,
                                                   o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_discharge_list;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_disch_actions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_actions          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_hhc_discharge.get_actions(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_hhc_discharge => i_id_hhc_discharge,
                                            o_actions          => o_actions,
                                            o_error            => o_error);
    
    END get_disch_actions;

    --*****************************************************
    FUNCTION get_visits_actions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_state IN table_varchar,
        i_subject   IN VARCHAR2,
        o_actions   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_hhc_visits.get_visits_actions(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_flg_state => i_flg_state,
                                                i_subject   => i_subject,
                                                o_actions   => o_actions,
                                                o_error     => o_error);
    
    END get_visits_actions;

    -- change status of visits ( scheduled, undo )
    FUNCTION set_visit_status
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_ids       IN table_number,
        i_action    IN VARCHAR2,
        i_id_reason IN NUMBER,
        i_rea_note  IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_hhc_visits.set_visit_status(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_ids       => i_ids,
                                              i_action    => i_action,
                                              i_id_reason => i_id_reason,
                                              i_rea_note  => i_rea_note,
                                              o_error     => o_error);
        IF l_bool
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_visit_status',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_visit_status;

    FUNCTION get_prof_team_det_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        o_team_detail OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.get_prof_team_det_hist(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_prof_team   => i_prof_team,
                                                  o_team_detail => o_team_detail,
                                                  o_error       => o_error);
    END get_prof_team_det_hist;

    FUNCTION get_epis_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_disch_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_hhc_discharge.get_discharge_list(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                   o_disch_list      => o_disch_list,
                                                   o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN pk_hhc_core.get_epis_discharge_list(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                   o_list            => o_list,
                                                   o_error           => o_error);
    END get_epis_discharge_list;

    FUNCTION check_epis_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_list            OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.check_epis_discharge(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                o_flg_show        => o_flg_show,
                                                o_list            => o_list,
                                                o_error           => o_error);
    END check_epis_discharge;

    FUNCTION check_has_next_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.check_has_next_schedules(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                    o_flg_show        => o_flg_show,
                                                    o_error           => o_error);
    END check_has_next_schedules;

    FUNCTION get_summary_page_sections_hhc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hhc_core.get_summary_page_sections_hhc(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => i_id_summary_page,
                                                         i_pat             => i_pat,
                                                         i_episode         => i_episode,
                                                         o_sections        => o_sections,
                                                         o_error           => o_error);
    
    END get_summary_page_sections_hhc;

    FUNCTION check_edit_avail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_edit   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_flg_edit := pk_hhc_core.check_edit_avail(i_lang => i_lang, i_prof => i_prof, i_id_hhc_req => i_id_hhc_req);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'check_edit_avail',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_edit_avail;
	
    FUNCTION get_prof_can_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_flg_can_cancel OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hhc_core.get_prof_can_cancel(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_hhc_req     => i_id_hhc_req,
                                               o_flg_can_cancel => o_flg_can_cancel,
                                               o_error          => o_error);
    
    END get_prof_can_cancel;
	
BEGIN
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);

END pk_hhc_ux;
/
