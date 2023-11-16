/*-- Last Change Revision: $Rev: 1950092 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-05-18 15:58:19 +0100 (seg, 18 mai 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hhc_visits IS

    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';

    k_vis_state_name_pending    CONSTANT VARCHAR2(0050 CHAR) := 'PENDING';
    k_vis_state_name_scheduled  CONSTANT VARCHAR2(0050 CHAR) := 'SCHEDULED';
    k_vis_state_name_inprogress CONSTANT VARCHAR2(0050 CHAR) := 'INPROGRESS';
    k_vis_state_name_concluded  CONSTANT VARCHAR2(0050 CHAR) := 'CONCLUDED';
    k_vis_state_name_noshow     CONSTANT VARCHAR2(0050 CHAR) := 'NO_SHOW';

    k_vis_action_name_app_sched CONSTANT VARCHAR2(0050 CHAR) := 'HHC_VISIT_APP_SCHED';
    k_vis_action_name_edit      CONSTANT VARCHAR2(0050 CHAR) := 'HHC_VISIT_EDIT';
    k_vis_action_name_undo      CONSTANT VARCHAR2(0050 CHAR) := 'HHC_VISIT_UNDO';

    --k_sch_status_approve CONSTANT VARCHAR2(0050 CHAR) := 'A';
    --k_sch_status_undo    CONSTANT VARCHAR2(0050 CHAR) := 'V';

    --**************************************************************
    FUNCTION check_inactivate_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_state IN table_varchar,
        i_action    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        k_yes CONSTANT VARCHAR2(0100 CHAR) := 'A';
        k_no  CONSTANT VARCHAR2(0100 CHAR) := 'I';
    
        --l_count   NUMBER;
        l_return  VARCHAR2(4000) := k_yes;
        l_flag    VARCHAR2(0010 CHAR);
        tbl_state table_varchar;
    
        --****************************************
        FUNCTION validate_all_same(i_all_state IN table_varchar) RETURN VARCHAR2 IS
            l_return  VARCHAR2(4000) := k_yes;
            tbl_state table_varchar;
        BEGIN
        
            SELECT DISTINCT column_value
              BULK COLLECT
              INTO tbl_state
              FROM TABLE(i_all_state);
        
            IF tbl_state.count > 1
            THEN
                l_return := k_no;
            END IF;
        
            RETURN l_return;
        
        END validate_all_same;
    
        --****************************************
        FUNCTION validate_concl_inprogress(i_all_state IN table_varchar) RETURN VARCHAR2 IS
            l_return VARCHAR2(4000) := k_yes;
            --tbl_state table_varchar;
        BEGIN
        
            IF i_all_state(1) IN (k_vis_state_name_inprogress, k_vis_state_name_concluded, k_vis_state_name_noshow)
            THEN
                l_return := k_no;
            END IF;
        
            RETURN l_return;
        
        END validate_concl_inprogress;
    
    BEGIN
    
        --        IF i_flg_state.count = 0
        IF NOT i_flg_state.exists(1)
        THEN
            l_return := k_no;
        END IF;
    
        -- all the same state?
        IF l_return = k_yes
        THEN
        
            l_return := validate_all_same(i_all_state => i_flg_state);
        
            IF l_return = k_yes
            THEN
                l_return := validate_concl_inprogress(i_all_state => i_flg_state);
            END IF;
        
            IF l_return = k_yes
            THEN
            
                CASE i_action
                    WHEN k_vis_action_name_app_sched THEN
                        CASE i_flg_state(1)
                            WHEN k_vis_state_name_pending THEN
                            
                                l_flag := pk_hhc_core.is_case_manager(i_lang => i_lang, i_prof => i_prof);
                                IF l_flag = 'Y'
                                THEN
                                    l_return := k_no;
                                END IF;
                            
                                l_flag := pk_hhc_core.is_coordinator(i_lang => i_lang, i_prof => i_prof);
                                IF l_flag = 'Y'
                                THEN
                                    l_return := k_yes;
                                END IF;
                            
                            ELSE
                                l_return := k_no;
                        END CASE;
                    
                    WHEN k_vis_action_name_edit THEN
                    
                        CASE i_flg_state(1)
                            WHEN k_vis_state_name_inprogress THEN
                                l_return := k_no;
                            WHEN k_vis_state_name_concluded THEN
                                l_return := k_no;
                            ELSE
                                l_return := k_yes;
                        END CASE;
                    
                    WHEN k_vis_action_name_undo THEN
                        CASE i_flg_state(1)
                            WHEN k_vis_state_name_scheduled THEN
                                l_flag := pk_hhc_core.is_coordinator(i_lang => i_lang, i_prof => i_prof);
                                IF l_flag = 'Y'
                                THEN
                                    l_return := k_yes;
                                ELSE
                                    l_return := k_no;
                                END IF;
                            ELSE
                                l_return := k_no;
                        END CASE;
                    ELSE
                        l_return := k_no;
                END CASE;
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END check_inactivate_all;

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
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_actions';
        --l_params  VARCHAR2(1000 CHAR);
        l_actions t_coll_action;
        --l_bool    BOOLEAN;
    BEGIN
    
        -- init
        l_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => i_subject,
                                              i_from_state => NULL);
    
        OPEN o_actions FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_action,
             t.id_parent,
             t.level_nr AS "LEVEL",
             t.from_state,
             t.to_state,
             t.desc_action,
             t.icon,
             t.flg_default,
             pk_hhc_visits.check_inactivate_all(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_flg_state => i_flg_state,
                                                i_action    => t.action) flg_active,
             t.action
              FROM TABLE(l_actions) t
             WHERE t.flg_active = pk_alert_constant.g_active
             ORDER BY t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_visits_actions;

    --**************************************************************
    FUNCTION update_visit_base
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_ids         IN table_number,
        i_action      IN VARCHAR2,
        i_transaction IN VARCHAR2,
        i_id_reason   IN NUMBER,
        i_rea_note    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        l_id_episode      NUMBER;
        l_id_epis_hhc_req NUMBER;
        --l_flg_state VARCHAR2(0010 CHAR);
    
        --*********************************
        FUNCTION get_episode_from_sched(i_id_schedule IN NUMBER) RETURN NUMBER IS
            l_return NUMBER;
        BEGIN
        
            SELECT id_episode
              INTO l_return
              FROM epis_info
             WHERE id_schedule = i_id_schedule;
        
            RETURN l_return;
        
        END get_episode_from_sched;
    
    BEGIN
    
        CASE i_action
            WHEN k_vis_action_name_undo THEN
                l_bool := pk_schedule_api_upstream.hhc_undo_schedule(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_schedule    => i_ids,
                                                                     i_transaction_id => i_transaction,
                                                                     i_id_reason      => i_id_reason,
                                                                     i_rea_note       => i_rea_note,
                                                                     o_error          => o_error);
            WHEN k_vis_action_name_app_sched THEN
                l_bool := pk_schedule_api_upstream.hhc_approve_schedule(i_lang           => i_lang,
                                                                        i_prof           => i_prof,
                                                                        i_id_schedule    => i_ids,
                                                                        i_transaction_id => i_transaction,
                                                                        i_id_reason      => i_id_reason,
                                                                        i_rea_note       => i_rea_note,
                                                                        o_error          => o_error);
            
                IF l_bool
                THEN
                    -- we need only one
                    l_id_episode      := get_episode_from_sched(i_ids(1));
                    l_id_epis_hhc_req := pk_hhc_core.get_id_hhc_req_by_epis(i_id_episode => l_id_episode);
                
                    l_bool := pk_hhc_core.set_status_in_progress(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_id_epis_hhc_req => l_id_epis_hhc_req,
                                                                 o_error           => o_error);
                END IF;
            
            ELSE
                l_bool := TRUE;
        END CASE;
    
        RETURN l_bool;
    
    END update_visit_base;

    --**************************************************************
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
    
        err_app_exception EXCEPTION;
        l_transaction_id VARCHAR2(4000);
        l_bool           BOOLEAN;
    
        --**********************************************
        PROCEDURE process_error
        (
            i_lang    IN NUMBER,
            i_sqlcode IN NUMBER,
            i_sqlerrm IN VARCHAR2
        ) IS
        BEGIN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => i_sqlcode,
                                              i_sqlerrm  => i_sqlerrm,
                                              i_message  => i_sqlerrm,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_visit_status',
                                              o_error    => o_error);
        END process_error;
    
    BEGIN
    
        IF i_action != k_vis_action_name_edit
        THEN
        
            --g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
        
            CASE
                WHEN i_action IN (k_vis_action_name_app_sched, k_vis_action_name_undo) THEN
                    l_bool := update_visit_base(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_transaction => l_transaction_id,
                                                i_ids         => i_ids,
                                                i_action      => i_action,
                                                i_id_reason   => i_id_reason,
                                                i_rea_note    => i_rea_note,
                                                o_error       => o_error);
                
                ELSE
                    NULL;
            END CASE;
        
            IF NOT l_bool
            THEN
                RAISE err_app_exception;
            END IF;
        
            IF l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_app_exception THEN
            process_error(i_lang => i_lang, i_sqlcode => SQLCODE, i_sqlerrm => SQLERRM);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            process_error(i_lang => i_lang, i_sqlcode => SQLCODE, i_sqlerrm => SQLERRM);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END set_visit_status;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_hhc_visits;

