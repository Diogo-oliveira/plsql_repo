/*-- Last Change Revision: $Rev: 2051359 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-28 09:41:24 +0000 (seg, 28 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_external_api_db IS

    PROCEDURE exams_____________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE procedures________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE surgical_procedures_______ IS
    BEGIN
        NULL;
    END;

    PROCEDURE order_sets________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE activity_therapy__________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE nanda_nic_noc_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_supply_by_context
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_context IN supply_request.id_context%TYPE,
        o_supply     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_EXTERNAL.GET_SUPPLY_BY_CONTEXT';
        IF NOT pk_supplies_external.get_supply_by_context(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_context => i_id_context,
                                                          o_supply     => o_supply,
                                                          o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_BY_CONTEXT',
                                              o_error);
            RETURN FALSE;
    END get_supply_by_context;

    FUNCTION get_surg_supplies_reg
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_material_req IN grid_task.material_req%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_supplies_external.get_surg_supplies_reg(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_episode   => i_id_episode,
                                                          i_material_req => i_material_req);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_surg_supplies_reg;

    FUNCTION set_supply_wf_order_predf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_supply_workflow    IN table_number,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        o_id_supply_request  OUT table_number,
        o_id_supply_workflow OUT table_table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.set_supply_wf_order_predf(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_supply_workflow    => i_supply_workflow,
                                                              i_id_episode         => i_id_episode,
                                                              o_id_supply_request  => o_id_supply_request,
                                                              o_id_supply_workflow => o_id_supply_workflow,
                                                              o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_WF_ORDER_PREDF',
                                              o_error);
            RETURN FALSE;
    END set_supply_wf_order_predf;

    FUNCTION set_edit_supply
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_id_context      IN table_number,
        i_notes           IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_cod_table       IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.set_edit_supply(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_episode      => i_id_episode,
                                                    i_supply_workflow => i_supply_workflow,
                                                    i_supply          => i_supply,
                                                    i_supply_qty      => i_supply_qty,
                                                    i_supply_loc      => i_supply_loc,
                                                    i_dt_return       => i_dt_return,
                                                    i_id_req_reason   => i_id_req_reason,
                                                    i_id_context      => i_id_context,
                                                    i_notes           => i_notes,
                                                    i_flg_cons_type   => i_flg_cons_type,
                                                    i_cod_table       => i_cod_table,
                                                    o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EDIT_SUPPLY',
                                              o_error);
            RETURN FALSE;
    END set_edit_supply;

    FUNCTION get_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN supply_workflow.id_supply_workflow%TYPE,
        o_task_instr   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_task_instructions(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_task_request => i_task_request,
                                                          o_task_instr   => o_task_instr,
                                                          o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_task_instructions;

    FUNCTION cancel_supply
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_id_episode       IN supply_workflow.id_episode%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.cancel_supply(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_supplies         => i_supplies,
                                                  i_id_episode       => i_id_episode,
                                                  i_cancel_notes     => i_cancel_notes,
                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                  o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SUPPLY',
                                              o_error);
            RETURN FALSE;
    END cancel_supply;

    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_supply_count_detail(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => i_id_episode,
                                                            i_id_sr_supply_count  => i_id_sr_supply_count,
                                                            o_supply_count_detail => o_supply_count_detail,
                                                            o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_COUNT_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_supply_count_detail;

    FUNCTION check_max_delay_sup_pharmacist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_supply_workflow IN supply_workflow.dt_supply_workflow%TYPE,
        i_phar_main_grid     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    BEGIN
    
        RETURN pk_supplies_external.check_max_delay_sup_pharmacist(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_episode         => i_id_episode,
                                                                   i_dt_supply_workflow => i_dt_supply_workflow,
                                                                   i_phar_main_grid     => i_phar_main_grid);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END check_max_delay_sup_pharmacist;

    FUNCTION set_supplies_surg_proc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN table_number,
        i_id_episode        IN episode.id_episode%TYPE,
        i_supply            IN table_table_number,
        i_supply_set        IN table_table_number,
        i_supply_qty        IN table_table_number,
        i_supply_loc        IN table_table_number,
        i_dt_return         IN table_table_varchar,
        i_supply_soft_inst  IN table_table_number,
        i_flg_cons_type     IN table_table_varchar,
        i_id_req_reason     IN table_table_number,
        i_notes             IN table_table_varchar,
        i_id_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.set_supplies_surg_proc(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_sr_epis_interv => i_id_sr_epis_interv,
                                                           i_id_episode        => i_id_episode,
                                                           i_supply            => i_supply,
                                                           i_supply_set        => i_supply_set,
                                                           i_supply_qty        => i_supply_qty,
                                                           i_supply_loc        => i_supply_loc,
                                                           i_dt_return         => i_dt_return,
                                                           i_supply_soft_inst  => i_supply_soft_inst,
                                                           i_flg_cons_type     => i_flg_cons_type,
                                                           i_id_req_reason     => i_id_req_reason,
                                                           i_notes             => i_notes,
                                                           i_id_inst_dest      => i_id_inst_dest,
                                                           o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLIES_SURG_PROC',
                                              o_error);
            RETURN FALSE;
    END set_supplies_surg_proc;

    FUNCTION get_sr_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_date           IN supply_workflow.dt_request%TYPE,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_icon_info     IN OUT t_rec_wf_status_info,
        io_icon_type     IN OUT supplies_wf_status.flg_display_type%TYPE,
        o_surgery_date   OUT schedule_sr.dt_target_tstz%TYPE,
        o_icon_color     OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_sr_status_info(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_episode     => i_id_episode,
                                                       i_date           => i_date,
                                                       i_phar_main_grid => i_phar_main_grid,
                                                       io_icon_info     => io_icon_info,
                                                       io_icon_type     => io_icon_type,
                                                       o_surgery_date   => o_surgery_date,
                                                       o_icon_color     => o_icon_color,
                                                       o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_STATUS_INFO',
                                              o_error);
            RETURN FALSE;
    END get_sr_status_info;

    FUNCTION check_loaned_supplies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_supplies_external.check_loaned_supplies(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END check_loaned_supplies;

    FUNCTION get_has_supplies_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
    BEGIN
    
        RETURN pk_supplies_external.get_has_supplies_desc(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_has_supplies_desc;

    FUNCTION copy_supply_wf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE DEFAULT NULL,
        i_dt_request         IN supply_workflow.dt_request%TYPE DEFAULT NULL,
        o_id_supply_workflow OUT supply_workflow.id_supply_workflow%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.copy_supply_wf(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_supply_workflow => i_id_supply_workflow,
                                                   i_id_episode         => i_id_episode,
                                                   i_dt_request         => i_dt_request,
                                                   o_id_supply_workflow => o_id_supply_workflow,
                                                   o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_SUPPLY_WF',
                                              o_error);
            RETURN FALSE;
    END copy_supply_wf;

    FUNCTION create_supply_wf_predf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_id_req_reason      IN table_number,
        i_notes              IN table_varchar,
        i_supply_soft_inst   IN table_number,
        i_flg_cons_type      IN table_varchar,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.create_supply_wf_predf(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_supply_area     => i_id_supply_area,
                                                           i_supply             => i_supply,
                                                           i_supply_set         => i_supply_set,
                                                           i_supply_qty         => i_supply_qty,
                                                           i_supply_loc         => i_supply_loc,
                                                           i_id_req_reason      => i_id_req_reason,
                                                           i_notes              => i_notes,
                                                           i_supply_soft_inst   => i_supply_soft_inst,
                                                           i_flg_cons_type      => i_flg_cons_type,
                                                           o_id_supply_workflow => o_id_supply_workflow,
                                                           o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SUPPLY_WF_PREDF',
                                              o_error);
            RETURN FALSE;
    END create_supply_wf_predf;

    FUNCTION delete_supply_workflow
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.delete_supply_workflow(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_supply_workflow => i_supply_workflow,
                                                           o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_SUPPLY_WORKFLOW',
                                              o_error);
            RETURN FALSE;
    END delete_supply_workflow;

    FUNCTION delete_supply_order
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_supplies_core.DELETE_SUPPLIES_BY_CONTEXT';
        IF NOT pk_supplies_external.delete_supplies_by_context(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_id_context  => i_id_context,
                                                               i_flg_context => i_flg_context,
                                                               o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END delete_supply_order;

    FUNCTION edit_supply_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status    table_varchar := table_varchar();
        l_supply        table_number := table_number();
        i_supply_set    table_number := table_number();
        i_supply_qty    table_number := table_number();
        i_supply_loc    table_number := table_number();
        l_id_req_reason table_number := table_number();
    
    BEGIN
    
        FOR i IN i_supply_workflow.first .. i_supply_workflow.last
        LOOP
        
            l_flg_status.extend;
            l_supply.extend;
            i_supply_set.extend;
            i_supply_qty.extend;
            i_supply_loc.extend;
            l_id_req_reason.extend;
        
            SELECT sw.flg_status, sw.id_supply, sw.id_supply_set, sw.quantity, sw.id_supply_location, sw.id_req_reason
              INTO l_flg_status(i), l_supply(i), i_supply_set(i), i_supply_qty(i), i_supply_loc(i), l_id_req_reason(i)
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_supply_workflow(i);
        
        END LOOP;
    
        IF NOT pk_supplies_core.update_supply_order(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_episode      => i_id_episode,
                                                    i_supply_workflow => i_supply_workflow,
                                                    i_supply          => l_supply,
                                                    i_supply_set      => i_supply_set,
                                                    i_supply_qty      => i_supply_qty,
                                                    i_supply_loc      => i_supply_loc,
                                                    i_dt_request      => i_dt_request,
                                                    i_dt_return       => i_dt_return,
                                                    i_id_req_reason   => l_id_req_reason,
                                                    i_id_context      => i_id_context,
                                                    i_flg_context     => i_flg_context,
                                                    i_notes           => i_notes,
                                                    o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END edit_supply_order;

    FUNCTION get_context_supplies_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE,
        i_flg_status  IN table_varchar DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1000 CHAR);
    BEGIN
    
        l_ret := pk_supplies_external.get_context_supplies_str(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_id_context  => i_id_context,
                                                               i_flg_context => i_flg_context,
                                                               i_flg_status  => i_flg_status);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_context_supplies_str;

    FUNCTION get_count_supplies_str_all
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_context               IN supply_context.id_context%TYPE,
        i_flg_context              IN supply_context.flg_context%TYPE,
        i_flg_filter_type          IN VARCHAR2 DEFAULT 'A', --C--only consumptions (do not have request), D-only dispenses (has request), A-all
        i_flg_status               IN VARCHAR2 DEFAULT NULL, -- NULL - all, NC - all except cancelled, or status specific
        i_flg_show_set_description IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL pk_supplies_core.GET_COUNT_SUPPLIES_STR_ALL';
        RETURN pk_supplies_external.get_count_supplies_str_all(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_id_context               => i_id_context,
                                                               i_flg_context              => i_flg_context,
                                                               i_flg_filter_type          => i_flg_filter_type,
                                                               i_flg_status               => i_flg_status,
                                                               i_flg_show_set_description => i_flg_show_set_description);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_count_supplies_str_all;

    FUNCTION get_inf_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply          IN table_number,
        i_flg_status         IN table_varchar,
        o_has_supplies       OUT VARCHAR2,
        o_id_supply_workflow OUT table_number,
        o_id_supply          OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_inf_supply_workflow(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_context         => i_id_context,
                                                            i_flg_context        => i_flg_context,
                                                            i_id_supply          => i_id_supply,
                                                            i_flg_status         => i_flg_status,
                                                            o_has_supplies       => o_has_supplies,
                                                            o_id_supply_workflow => o_id_supply_workflow,
                                                            o_id_supply          => o_id_supply,
                                                            o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INF_SUPPLY_WORKFLOW',
                                              o_error);
            RETURN FALSE;
    END get_inf_supply_workflow;

    FUNCTION get_supplies_request
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_supplies_core.GET_SUPPLIES_REQUEST';
        IF NOT pk_supplies_external.get_supplies_request(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_context  => i_id_context,
                                                         i_flg_context => i_flg_context,
                                                         o_supplies    => o_supplies,
                                                         o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLIES_REQUEST',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
            RETURN FALSE;
    END get_supplies_request;

    FUNCTION get_supplies_request
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1000 CHAR);
    BEGIN
    
        l_ret := pk_supplies_external.get_supplies_request(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_context  => i_id_context,
                                                           i_flg_context => i_flg_context);
        /*IF NOT pk_supplies_external.get_supplies_request(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_context  => i_id_context,
                                                         i_flg_context => i_flg_context,
                                                         o_supplies    => l_supplies,
                                                         o_error       => l_error)
        THEN
            RAISE g_other_exception;
        END IF;*/
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supplies_request;

    FUNCTION get_supplies_request_history
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL pk_supplies_core.GET_SUPPLIES_REQUEST_HISTORY';
        RETURN pk_supplies_external.get_supplies_request_history(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_context  => i_id_context,
                                                                 i_flg_context => i_flg_context);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supplies_request_history;

    FUNCTION get_supply_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_supply_desc pk_translation.t_desc_translation;
    BEGIN
    
        l_supply_desc := pk_supplies_external.get_supply_desc(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_id_supply => i_id_supply);
    
        RETURN l_supply_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_supply_desc;

    FUNCTION get_supply_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL pk_supplies_core.GET_SUPPLY_DESCRIPTION';
        RETURN pk_supplies_external.get_supply_description(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_supply_workflow => i_supply_workflow,
                                                           i_flg_filter_type => i_flg_filter_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_supply_description;

    FUNCTION get_supply_quantity
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE
    ) RETURN supply_soft_inst.quantity%TYPE IS
        l_ret supply_soft_inst.quantity%TYPE;
    BEGIN
    
        l_ret := pk_supplies_external.get_supply_quantity(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_supply_area => i_id_supply_area,
                                                          i_id_supply      => i_id_supply);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_supply_quantity;

    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_supply_workflow    IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
    BEGIN
        g_error := 'CALL pk_supplies_core.GET_SUPPLY_DESCRIPTION';
        RETURN pk_supplies_external.get_task_description(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_id_supply_workflow    => i_id_supply_workflow,
                                                         i_flg_description       => i_flg_description,
                                                         i_description_condition => i_description_condition);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_task_description;

    FUNCTION get_workflow_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_id_episode         IN table_number,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply          IN supply.id_supply%TYPE,
        i_start_date         IN supply_workflow.dt_supply_workflow%TYPE,
        i_end_date           IN supply_workflow.dt_supply_workflow%TYPE,
        i_flg_screen         IN VARCHAR2,
        i_supply_desc        IN VARCHAR2,
        o_sup_workflow_prof  OUT pk_types.cursor_type,
        o_sup_workflow       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_workflow_history(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_supply_area     => i_id_supply_area,
                                                         i_id_episode         => i_id_episode,
                                                         i_id_supply_workflow => i_id_supply_workflow,
                                                         i_id_supply          => i_id_supply,
                                                         i_start_date         => i_start_date,
                                                         i_end_date           => i_end_date,
                                                         i_flg_screen         => i_flg_screen,
                                                         i_supply_desc        => i_supply_desc,
                                                         o_sup_workflow_prof  => o_sup_workflow_prof,
                                                         o_sup_workflow       => o_sup_workflow,
                                                         o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WORKFLOW_HISTORY',
                                              o_error);
            RETURN FALSE;
    END get_workflow_history;

    FUNCTION get_workflow_parent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN supply_workflow.id_supply_workflow%TYPE IS
        l_ret supply_workflow.id_supply_workflow%TYPE;
    BEGIN
    
        l_ret := pk_supplies_external.get_workflow_parent(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_supply_workflow => i_id_supply_workflow);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_workflow_parent;

    FUNCTION set_independent_supply
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.set_independent_supply(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_supply_workflow => i_id_supply_workflow,
                                                           o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_INDEPENDENT_SUPPLY',
                                              o_error);
            RETURN FALSE;
    END set_independent_supply;

    FUNCTION update_supply_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_supply         IN table_number,
        i_supply_set     IN table_number,
        i_supply_qty     IN table_number,
        i_dt_request     IN table_varchar,
        i_dt_return      IN table_varchar,
        i_id_context     IN supply_request.id_context%TYPE,
        i_flg_context    IN supply_request.flg_context%TYPE,
        o_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_supplies_core.UPDATE_SUPPLY_ORDER';
        IF NOT pk_supplies_external.update_supply_order(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => i_episode,
                                                        i_supply         => i_supply,
                                                        i_supply_set     => i_supply_set,
                                                        i_supply_qty     => i_supply_qty,
                                                        i_dt_request     => i_dt_request,
                                                        i_dt_return      => i_dt_return,
                                                        i_id_context     => i_id_context,
                                                        i_flg_context    => i_flg_context,
                                                        o_supply_request => o_supply_request,
                                                        o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END update_supply_order;

    FUNCTION get_requested_supplies_per_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN supply_request.flg_context%TYPE,
        i_id_context  IN supply_workflow.id_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_requested_supplies_per_context(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_flg_context => i_flg_context,
                                                                       i_id_context  => i_id_context,
                                                                       o_supplies    => o_supplies,
                                                                       o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REQUESTED_SUPPLIES_PER_CONTEXT',
                                              o_error);
            RETURN FALSE;
    END get_requested_supplies_per_context;

    FUNCTION get_default_supplies_req_cfg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context_d   IN supply_request.flg_context%TYPE,
        i_id_context_d    IN supply_workflow.id_context%TYPE,
        i_id_context_m    IN table_varchar,
        i_id_context_p    IN table_varchar,
        i_flg_default_qty IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_supplies        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_external.get_default_supplies_req_cfg(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_flg_context_d   => i_flg_context_d,
                                                                 i_id_context_d    => i_id_context_d,
                                                                 i_id_context_m    => i_id_context_m,
                                                                 i_id_context_p    => i_id_context_p,
                                                                 i_flg_default_qty => i_flg_default_qty,
                                                                 o_supplies        => o_supplies,
                                                                 o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEFAULT_SUPPLIES_REQ_CFG',
                                              o_error);
            RETURN FALSE;
    END get_default_supplies_req_cfg;

    FUNCTION get_supply_workflow_lst
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_context        IN supply_request.flg_context%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        o_supply_wokflow_lst OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_supplies_external.get_supply_workflow_lst(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_flg_context        => i_flg_context,
                                                            i_id_context         => i_id_context,
                                                            o_supply_wokflow_lst => o_supply_wokflow_lst,
                                                            o_error              => o_error);
    
    END get_supply_workflow_lst;

    FUNCTION update_supply_record
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_lot      IN table_varchar,
        i_barcode_scanned IN table_varchar,
        i_dt_request      IN table_varchar,
        i_dt_expiration   IN table_varchar,
        i_flg_validation  IN table_varchar,
        i_flg_supply_type IN table_varchar,
        i_deliver_needed  IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_flg_consumption IN table_varchar,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_supply_request  OUT supply_request.id_supply_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_supplies_external.update_supply_record(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_episode         => i_episode,
                                                         i_supply_workflow => i_supply_workflow,
                                                         i_supply          => i_supply,
                                                         i_supply_set      => i_supply_set,
                                                         i_supply_qty      => i_supply_qty,
                                                         i_supply_lot      => i_supply_lot,
                                                         i_barcode_scanned => i_barcode_scanned,
                                                         i_dt_request      => i_dt_request,
                                                         i_dt_expiration   => i_dt_expiration,
                                                         i_flg_validation  => i_flg_validation,
                                                         i_flg_supply_type => i_flg_supply_type,
                                                         i_deliver_needed  => i_deliver_needed,
                                                         i_flg_cons_type   => i_flg_cons_type,
                                                         i_flg_consumption => i_flg_consumption,
                                                         i_id_context      => i_id_context,
                                                         i_flg_context     => i_flg_context,
                                                         o_supply_request  => o_supply_request,
                                                         o_error           => o_error);
    END update_supply_record;

    FUNCTION cancel_supply_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN supply_context.id_context%TYPE,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN supply_request.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_supply_workflow table_number := table_number();
    BEGIN
    
        SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO l_id_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context
           AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled);
    
        IF (cardinality(l_id_supply_workflow) > 0)
        THEN
            g_error := ' Call pk_supplies_api_db.cancel_supply_order';
            IF NOT pk_supplies_api_db.cancel_supply_order(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_supplies         => l_id_supply_workflow,
                                                          i_id_prof_cancel   => i_prof.id,
                                                          i_cancel_notes     => i_cancel_notes,
                                                          i_id_cancel_reason => i_cancel_reason,
                                                          i_dt_cancel        => current_timestamp,
                                                          o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
        
    END cancel_supply_order;

    FUNCTION check_supplies_not_in_inicial_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN supply_request.flg_context%TYPE,
        i_id_context       IN supply_workflow.id_context%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_supplies_external.check_supplies_not_in_inicial_status(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_flg_context      => i_flg_context,
                                                                         i_id_context       => i_id_context,
                                                                         i_id_cancel_reason => i_id_cancel_reason);
    
    END check_supplies_not_in_inicial_status;

    FUNCTION inactivate_records_by_context
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_supplies_external.inactivate_records_by_context(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_episode         => i_episode,
                                                                  i_supply_workflow => i_supply_workflow,
                                                                  i_id_context      => i_id_context,
                                                                  i_flg_context     => i_flg_context,
                                                                  o_error           => o_error);
    END inactivate_records_by_context;

    FUNCTION get_supplies_descr_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'CALL pk_supplies_core.GET_COUNT_SUPPLIES_STR_ALL';
        RETURN pk_supplies_external.get_supplies_descr_by_id(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_supply_workflow => i_supply_workflow,
                                                             i_flg_filter_type => i_flg_filter_type);
    
    END get_supplies_descr_by_id;

    FUNCTION inactivate_supplies_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
        g_error := 'CALL PK_SUPPLIES_CORE.INACTIVATE_SUPPLIES_TASKS';
        IF NOT pk_supplies_external.inactivate_supplies_tasks(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_inst        => i_inst,
                                                              i_ids_exclude => l_tbl_ids,
                                                              o_has_error   => o_has_error,
                                                              o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    END inactivate_supplies_tasks;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_supplies_external_api_db;
/
