/*-- Last Change Revision: $Rev: 2045843 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:24:49 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_api_ux IS

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_supply            IN table_number,
        i_supply_set        IN table_number,
        i_supply_qty        IN table_number,
        i_supply_loc        IN table_number,
        i_dt_request        IN table_varchar,
        i_dt_return         IN table_varchar,
        i_id_req_reason     IN table_number,
        i_flg_reason_req    IN supply_request.flg_reason%TYPE DEFAULT 'O',
        i_id_context        IN table_number,
        i_flg_context       IN table_varchar,
        i_notes             IN table_varchar,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.create_supply_order(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_supply_area    => NULL,
                                                    i_id_episode        => i_id_episode,
                                                    i_supply            => i_supply,
                                                    i_supply_set        => i_supply_set,
                                                    i_supply_qty        => i_supply_qty,
                                                    i_supply_loc        => i_supply_loc,
                                                    i_dt_request        => i_dt_request,
                                                    i_dt_return         => i_dt_return,
                                                    i_id_req_reason     => i_id_req_reason,
                                                    i_flg_reason_req    => i_flg_reason_req,
                                                    i_id_context        => i_id_context,
                                                    i_flg_context       => i_flg_context,
                                                    i_notes             => i_notes,
                                                    i_supply_flg_status => NULL,
                                                    i_id_inst_dest      => NULL,
                                                    o_id_supply_request => o_id_supply_request,
                                                    o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SUPPLY_ORDER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_supply_order;

    FUNCTION create_supply_with_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply_workflow IN table_number,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_flg_supply_type    IN table_varchar,
        i_barcode_scanned    IN table_varchar,
        i_fixed_asset_number IN table_varchar,
        i_deliver_needed     IN table_varchar,
        i_flg_cons_type      IN table_varchar,
        i_notes              IN table_varchar,
        i_dt_expected_date   IN table_varchar,
        i_check_quantities   IN VARCHAR2,
        i_dt_expiration      IN table_varchar,
        i_flg_validation     IN table_varchar,
        i_lot                IN table_varchar,
        i_test               IN VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.create_supply_with_consumption(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_episode         => i_id_episode,
                                                               i_id_context         => i_id_context,
                                                               i_flg_context        => i_flg_context,
                                                               i_id_supply_workflow => i_id_supply_workflow,
                                                               i_supply             => i_supply,
                                                               i_supply_set         => i_supply_set,
                                                               i_supply_qty         => i_supply_qty,
                                                               i_flg_supply_type    => i_flg_supply_type,
                                                               i_barcode_scanned    => i_barcode_scanned,
                                                               i_fixed_asset_number => NULL,
                                                               i_deliver_needed     => i_deliver_needed,
                                                               i_flg_cons_type      => i_flg_cons_type,
                                                               i_notes              => i_notes,
                                                               i_dt_expected_date   => i_dt_expected_date,
                                                               i_check_quantities   => pk_alert_constant.g_no,
                                                               i_dt_expiration      => i_dt_expiration,
                                                               i_flg_validation     => i_flg_validation,
                                                               i_lot                => i_lot,
                                                               i_test               => i_test,
                                                               o_flg_show           => o_flg_show,
                                                               o_msg                => o_msg,
                                                               o_msg_title          => o_msg_title,
                                                               o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SUPPLY_WITH_CONSUMPTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_supply_with_consumption;

    FUNCTION set_supply_preparation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies      IN table_number,
        i_id_patient    IN patient.id_patient%TYPE,
        i_unic_id       IN table_number,
        i_prepared_by   IN table_varchar,
        i_prep_notes    IN table_varchar,
        i_new_supplies  IN table_number,
        i_qty_dispensed IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_supplies_core.set_supply_preparation(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_supplies      => i_supplies,
                                                       i_id_patient    => i_id_patient,
                                                       i_unic_id       => i_unic_id,
                                                       i_prepared_by   => i_prepared_by,
                                                       i_prep_notes    => i_prep_notes,
                                                       i_new_supplies  => i_new_supplies,
                                                       i_qty_dispensed => i_qty_dispensed,
                                                       o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_PREPARATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_preparation;

    FUNCTION set_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_test         IN VARCHAR2,
        i_supply_workflow  IN table_number,
        i_supply_qty       IN table_number,
        i_dt_return        IN table_varchar,
        i_barcode_scanned  IN table_varchar,
        i_asset_nr_scanned IN table_varchar,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_order(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_episode       => i_id_episode,
                                                 i_flg_test         => i_flg_test,
                                                 i_supply_workflow  => i_supply_workflow,
                                                 i_supply_qty       => i_supply_qty,
                                                 i_dt_return        => i_dt_return,
                                                 i_barcode_scanned  => i_barcode_scanned,
                                                 i_asset_nr_scanned => i_asset_nr_scanned,
                                                 o_flg_show         => o_flg_show,
                                                 o_msg              => o_msg,
                                                 o_msg_title        => o_msg_title,
                                                 o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_ORDER',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_order;

    FUNCTION set_supplies_consume --set_supply_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_consumption(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_id_supply_workflow => i_id_supply_workflow,
                                                       o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLIES_CONSUME',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supplies_consume;

    FUNCTION set_supply_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_flg_status IN supply_workflow.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_status(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_supplies   => i_supplies,
                                                  i_flg_status => i_flg_status,
                                                  o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_status;

    FUNCTION set_supply_delivery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        i_supply_qty      IN table_number,
        i_id_episode      IN supply_workflow.id_episode%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_delivery(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_supply_workflow => i_supply_workflow,
                                                    i_supply_qty      => i_supply_qty,
                                                    i_id_episode      => i_id_episode,
                                                    o_flg_show        => o_flg_show,
                                                    o_msg             => o_msg,
                                                    o_msg_title       => o_msg_title,
                                                    o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_DELIVERY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_delivery;

    FUNCTION set_supply_delivery_confirmation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_delivery_confirmation(i_lang            => i_lang,
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
                                              'SET_SUPPLY_DELIVERY_CONFIRMATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_delivery_confirmation;

    FUNCTION set_supply_devolution
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_supplies IN table_number,
        i_barcode  IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_devolution(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_supplies => i_supplies,
                                                      i_barcode  => i_barcode,
                                                      o_error    => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_DEVOLUTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_devolution;

    FUNCTION set_supply_reject
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_rejection_notes    IN supply_workflow.notes_reject%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_reject(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_episode         => i_id_episode,
                                                  i_id_supply_workflow => i_id_supply_workflow,
                                                  i_rejection_notes    => i_rejection_notes,
                                                  o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_REJECT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_reject;

    FUNCTION set_prepare_supplies_for_surg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        i_barcode_scanned    IN table_varchar,
        i_cod_table          IN table_varchar,
        i_id_episode         IN episode.id_episode%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_prepare_supplies_for_surg(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_id_supply_workflow => i_id_supply_workflow,
                                                              i_barcode_scanned    => i_barcode_scanned,
                                                              i_cod_table          => i_cod_table,
                                                              i_id_episode         => i_id_episode,
                                                              o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PREPARE_SUPPLIES_FOR_SURG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_prepare_supplies_for_surg;

    FUNCTION set_ready_for_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.set_ready_for_preparation(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_supply_workflow => i_id_supply_workflow,
                                                          o_id_supply_workflow => o_id_supply_workflow,
                                                          o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_READY_FOR_PREPARATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_ready_for_preparation;

    FUNCTION set_supply_for_delivery
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_reason     IN table_number,
        i_notes      IN table_varchar,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_for_delivery(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_supplies   => i_supplies,
                                                        i_reason     => i_reason,
                                                        i_notes      => i_notes,
                                                        i_id_episode => i_id_episode,
                                                        o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUPPLY_FOR_DELIVERY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_supply_for_delivery;

    FUNCTION set_sup_cons_count
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_workflow  IN table_table_number,
        i_id_supply           IN table_number,
        i_qty_added           IN table_number,
        i_qty_final_count     IN table_number,
        i_id_recouncile_count IN table_number,
        i_notes               IN table_varchar,
        i_cod_table           IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_sup_cons_count(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_supply_workflow  => i_id_supply_workflow,
                                                   i_id_supply           => i_id_supply,
                                                   i_qty_added           => i_qty_added,
                                                   i_qty_final_count     => i_qty_final_count,
                                                   i_id_recouncile_count => i_id_recouncile_count,
                                                   i_notes               => i_notes,
                                                   i_cod_table           => i_cod_table,
                                                   o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SUP_CONS_COUNT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_sup_cons_count;

    FUNCTION update_supply_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_flg_reason_req  IN supply_request.flg_reason%TYPE DEFAULT 'O',
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.update_supply_order(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_episode      => i_id_episode,
                                                    i_supply_workflow => i_supply_workflow,
                                                    i_supply          => i_supply,
                                                    i_supply_set      => i_supply_set,
                                                    i_supply_qty      => i_supply_qty,
                                                    i_supply_loc      => i_supply_loc,
                                                    i_dt_request      => i_dt_request,
                                                    i_dt_return       => i_dt_return,
                                                    i_id_req_reason   => i_id_req_reason,
                                                    i_id_context      => i_id_context,
                                                    i_flg_context     => i_flg_context,
                                                    i_notes           => i_notes,
                                                    o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_REQUEST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_supply_order;

    FUNCTION update_supply_workflow
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_id_context      IN table_number,
        i_flg_context     IN table_varchar,
        i_notes           IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_cod_table       IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.update_supply_workflow(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_episode      => i_id_episode,
                                                       i_supply_workflow => i_supply_workflow,
                                                       i_supply          => i_supply,
                                                       i_supply_set      => i_supply_set,
                                                       i_supply_qty      => i_supply_qty,
                                                       i_supply_loc      => i_supply_loc,
                                                       i_dt_request      => i_dt_request,
                                                       i_dt_return       => i_dt_return,
                                                       i_id_req_reason   => i_id_req_reason,
                                                       i_id_context      => i_id_context,
                                                       i_flg_context     => i_flg_context,
                                                       i_notes           => i_notes,
                                                       i_flg_cons_type   => i_flg_cons_type,
                                                       i_cod_table       => i_cod_table,
                                                       o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SUPPLY_WORKFLOW',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_supply_workflow;

    FUNCTION cancel_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.cancel_supply_order(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_supplies         => i_supplies,
                                                    i_id_prof_cancel   => NULL,
                                                    i_cancel_notes     => i_cancel_notes,
                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                    i_dt_cancel        => NULL,
                                                    o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_supply_order;

    FUNCTION cancel_supply_deliver
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_test          IN VARCHAR2,
        i_supplies_workflow IN table_number,
        i_cancel_notes      IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason  IN supply_workflow.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_CORE.CANCEL_SUPPLY_DELIVER';
        IF NOT pk_supplies_core.cancel_supply_deliver(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_episode        => i_id_episode,
                                                      i_flg_test          => i_flg_test,
                                                      i_supplies_workflow => i_supplies_workflow,
                                                      i_cancel_notes      => i_cancel_notes,
                                                      i_id_cancel_reason  => i_id_cancel_reason,
                                                      o_flg_show          => o_flg_show,
                                                      o_msg               => o_msg,
                                                      o_msg_title         => o_msg_title,
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
                                              'CANCEL_SUPPLY_DELIVER',
                                              o_error);
            RETURN FALSE;
    END cancel_supply_deliver;

    FUNCTION cancel_supply_loan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_supplies_workflow IN table_number,
        i_id_episode        IN supply_workflow.id_episode%TYPE,
        i_cancel_notes      IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason  IN supply_workflow.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_CORE.CANCEL_SUPPLY_LOAN';
        IF NOT pk_supplies_core.cancel_supply_loan(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_supplies_workflow => i_supplies_workflow,
                                                   i_id_episode        => i_id_episode,
                                                   i_cancel_notes      => i_cancel_notes,
                                                   i_id_cancel_reason  => i_id_cancel_reason,
                                                   o_flg_show          => o_flg_show,
                                                   o_msg               => o_msg,
                                                   o_msg_title         => o_msg_title,
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
                                              'CANCEL_SUPPLY_LOAN',
                                              o_error);
            RETURN FALSE;
    END cancel_supply_loan;

    FUNCTION get_supply_selection_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_selection_list   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_supplies_core.get_supply_selection_list(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_supply_area   => i_id_supply_area,
                                                          i_episode          => i_episode,
                                                          i_consumption_type => i_consumption_type,
                                                          i_id_inst_dest     => i_id_inst_dest,
                                                          o_selection_list   => o_selection_list,
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
                                              'GET_SUPPLY_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_selection_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_selection_list;

    FUNCTION get_supply_for_selection
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_supply_type   IN supply.id_supply_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_supply_inf       OUT pk_types.cursor_type,
        o_supply_type      OUT pk_types.cursor_type,
        o_supply_items     OUT pk_types.cursor_type,
        o_flg_selected     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_for_selection(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_supply_area   => i_id_supply_area,
                                                         i_episode          => i_episode,
                                                         i_consumption_type => i_consumption_type,
                                                         i_flg_type         => i_flg_type,
                                                         i_id_supply        => i_id_supply,
                                                         i_id_supply_type   => i_id_supply_type,
                                                         i_id_inst_dest     => i_id_inst_dest,
                                                         o_supply_inf       => o_supply_inf,
                                                         o_supply_type      => o_supply_type,
                                                         o_supply_items     => o_supply_items,
                                                         o_flg_selected     => o_flg_selected,
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
                                              'GET_SUPPLY_FOR_SELECTION',
                                              o_error);
            pk_types.open_my_cursor(o_supply_inf);
            pk_types.open_my_cursor(o_supply_type);
            pk_types.open_my_cursor(o_supply_items);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_for_selection;

    FUNCTION get_supply_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_value           IN VARCHAR2,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_search(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_value           => i_value,
                                                  i_id_supply_area  => i_id_supply_area,
                                                  i_flg_consumption => i_flg_consumption,
                                                  i_id_inst_dest    => i_id_inst_dest,
                                                  o_flg_show        => o_flg_show,
                                                  o_msg             => o_msg,
                                                  o_msg_title       => o_msg_title,
                                                  o_list            => o_list,
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
                                              'GET_SUPPLY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_search;

    FUNCTION get_supply_listview
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_listview(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_supply_area => i_id_supply_area,
                                                    i_patient        => i_patient,
                                                    i_episode        => i_episode,
                                                    i_flg_type       => i_flg_type,
                                                    i_id_hhc_req     => NULL,
                                                    o_list           => o_list,
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
                                              'GET_SUPPLY_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_listview;

    FUNCTION get_supply_listview
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_listview(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_supply_area => i_id_supply_area,
                                                    i_patient        => i_patient,
                                                    i_episode        => i_episode,
                                                    i_flg_type       => i_flg_type,
                                                    i_id_hhc_req     => i_id_hhc_req,
                                                    o_list           => o_list,
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
                                              'GET_SUPPLY_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_listview;

    FUNCTION get_supply_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_sup_wf IN supply_workflow.id_supply_workflow%TYPE,
        o_register  OUT pk_types.cursor_type,
        o_req       OUT pk_types.cursor_type,
        o_canceled  OUT pk_types.cursor_type,
        o_rejected  OUT pk_types.cursor_type,
        o_consumed  OUT pk_types.cursor_type,
        o_others    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_detail(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_id_sup_wf => i_id_sup_wf,
                                                  o_register  => o_register,
                                                  o_req       => o_req,
                                                  o_canceled  => o_canceled,
                                                  o_rejected  => o_rejected,
                                                  o_consumed  => o_consumed,
                                                  o_others    => o_others,
                                                  o_error     => o_error)
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
                                              'GET_SUPPLY_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_register);
            pk_types.open_my_cursor(o_req);
            pk_types.open_my_cursor(o_canceled);
            pk_types.open_my_cursor(o_consumed);
            pk_types.open_my_cursor(o_rejected);
            pk_types.open_my_cursor(o_others);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_detail;

    FUNCTION get_supply_to_edit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_supply     IN table_number,
        o_supply     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_to_edit(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_episode => i_id_episode,
                                                   i_supply     => i_supply,
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
                                              'GET_SUPPLY_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_supply);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_to_edit;

    FUNCTION get_supply_filter_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL,
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_TYPES';
        OPEN o_types FOR
            SELECT t.val, t.desc_val, t.flg_selected
              FROM TABLE(pk_supplies_core.get_supply_filter_list(i_lang,
                                                                 i_prof,
                                                                 i_id_supply_area,
                                                                 i_episode,
                                                                 i_flg_consumption,
                                                                 i_id_inst_dest)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_FILTER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_filter_list;

    FUNCTION get_supply_location_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_sup IN supply.id_supply%TYPE,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_location_list(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_supply_area => NULL,
                                                         i_id_sup         => i_id_sup,
                                                         o_list           => o_list,
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
                                              'GET_SUPPLY_LOCATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_location_list;

    FUNCTION get_supply_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN supply_reason.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_reason_list(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_flg_type => i_flg_type,
                                                       o_list     => o_list,
                                                       o_error    => o_error)
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
                                              'GET_SUPPLY_REQUEST_REASONS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_supply_reason_list;

    PROCEDURE l_______________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_sup_by_barcode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_barcode        IN supply_barcode.barcode%TYPE,
        i_lot            IN supply_barcode.lot%TYPE,
        i_asset_nr       IN supply_fixed_asset_nr.fixed_asset_nr%TYPE DEFAULT NULL,
        o_c_supply       OUT pk_types.cursor_type,
        o_c_kit_set      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_sup_by_barcode(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_supply_area => i_id_supply_area,
                                                   i_barcode        => i_barcode,
                                                   i_lot            => i_lot,
                                                   i_asset_nr       => i_asset_nr,
                                                   o_c_supply       => o_c_supply,
                                                   o_c_kit_set      => o_c_kit_set,
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
                                              'GET_SUP_BY_BARCODE',
                                              o_error);
            pk_types.open_my_cursor(o_c_kit_set);
            pk_types.open_my_cursor(o_c_supply);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_sup_by_barcode;

    FUNCTION get_sup_not_ready
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_supplies_core.get_sup_not_ready(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_episode     => i_episode,
                                                  i_id_context  => i_id_context,
                                                  i_flg_context => i_flg_context,
                                                  o_list        => o_list,
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
                                              'GET_SUP_NOT_READY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_sup_not_ready;

    FUNCTION get_supplies_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN table_varchar,
        i_flg_context IN supply_context.flg_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supplies_by_context(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_context    => i_id_context,
                                                        i_flg_context   => i_flg_context,
                                                        i_dep_clin_serv => NULL,
                                                        o_supplies      => o_supplies,
                                                        o_error         => o_error)
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
                                              'GET_SUPPLIES_BY_CONTEXT',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supplies_by_context;

    FUNCTION get_request_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        i_ready       IN VARCHAR2,
        i_supply_area IN supply_sup_area.id_supply_area%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_request_by_context(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_context  => i_id_context,
                                                       i_flg_context => i_flg_context,
                                                       i_ready       => i_ready,
                                                       i_supply_area => i_supply_area,
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
                                              'GET_REQUEST_BY_CONTEXT',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_request_by_context;

    FUNCTION get_prepared_by
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_prepared_by OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_prepared_by(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                o_prepared_by => o_prepared_by,
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
                                              'GET_PREPARED_BY',
                                              o_error);
            pk_types.open_my_cursor(o_prepared_by);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prepared_by;

    FUNCTION get_supply_request_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_workflow OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_request_edit(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_supply_workflow => i_supply_workflow,
                                                        o_supply_workflow => o_supply_workflow,
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
                                              'GET_SUPPLY_REQUEST_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_supply_workflow);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supply_request_edit;

    FUNCTION get_same_type_supplies
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        o_supplies       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_supplies_core.get_same_type_supplies(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply_area => i_id_supply_area,
                                                       i_episode        => i_episode,
                                                       i_id_supply      => i_id_supply,
                                                       o_supplies       => o_supplies,
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
                                              'GET_SAME_TYPE_SUPPLIES',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_same_type_supplies;

    FUNCTION get_cross_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_task_type  IN task_type.id_task_type%TYPE,
        i_flg_set    IN VARCHAR2,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_cross_actions_permissions(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_subject    => i_subject,
                                                              i_from_state => i_from_state,
                                                              i_task_type  => i_task_type,
                                                              i_flg_set    => i_flg_set,
                                                              o_actions    => o_actions,
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
                                              'GET_CROSS_ACTIONS_PERMISSIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_cross_actions_permissions;

    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_flg_set    IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_actions_permissions(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_subject    => i_subject,
                                                        i_from_state => i_from_state,
                                                        i_flg_set    => i_flg_set,
                                                        i_episode    => i_episode,
                                                        i_id_hhc_req => i_id_hhc_req,
                                                        o_actions    => o_actions,
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
                                              'GET_ACTIONS_PERMISSIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_actions_permissions;

    FUNCTION get_actions_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN action.from_state%TYPE,
        i_flg_set     IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        i_id_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_context IN VARCHAR2 DEFAULT NULL,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_actions_permissions(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_subject     => i_subject,
                                                        i_from_state  => i_from_state,
                                                        i_flg_set     => i_flg_set,
                                                        i_episode     => i_episode,
                                                        i_id_hhc_req  => i_id_hhc_req,
                                                        i_flg_context => i_flg_context,
                                                        o_actions     => o_actions,
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
                                              'GET_ACTIONS_PERMISSIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_actions_permissions;

    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_actions_with_exceptions(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_subject    => i_subject,
                                                            i_from_state => i_from_state,
                                                            i_episode    => i_episode,
                                                            i_id_hhc_req => i_id_hhc_req,
                                                            o_actions    => o_actions,
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
                                              'GET_ACTIONS_WITH_EXCEPTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_actions_with_exceptions;

    FUNCTION get_deliver_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_deliver_options(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    o_options => o_options,
                                                    o_error   => o_error)
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
                                              'GET_DELIVER_OPTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_options);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_deliver_options;

    FUNCTION get_supply_patients
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE,
        o_grid      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_patients(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_id_supply => i_id_supply,
                                                    o_grid      => o_grid,
                                                    o_error     => o_error)
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
                                              'GET_SUPPLY_PATIENTS',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supply_patients;

    FUNCTION get_type_consumption
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL,
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_type_consumption(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_supply_area  => i_id_supply_area,
                                                     i_episode         => i_episode,
                                                     i_flg_consumption => i_flg_consumption,
                                                     i_id_inst_dest    => i_id_inst_dest,
                                                     o_types           => o_types,
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
                                              'GET_TYPE_CONSUMPTION',
                                              o_error);
            pk_types.open_my_cursor(o_types);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_type_consumption;

    FUNCTION get_type_consumption_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        o_type_consumption OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_type_consumption_list(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_supply_area   => i_id_supply_area,
                                                          i_id_supply        => i_id_supply,
                                                          o_type_consumption => o_type_consumption,
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
                                              'GET_TYPE_CONSUMPTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_type_consumption);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_type_consumption_list;

    FUNCTION get_set_composition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_set  IN supply.id_supply%TYPE,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        o_supply_info    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_set_composition(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_supply_set  => i_id_supply_set,
                                                    i_id_supply_area => i_id_supply_area,
                                                    o_supply_info    => o_supply_info,
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
                                              'GET_SET_COMPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_supply_info);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_set_composition;

    FUNCTION get_workflow_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_workflow_by_context(i_lang        => i_lang,
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
                                              'GET_WORKFLOW_BY_CONTEXT',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_workflow_by_context;

    FUNCTION get_supply_wf_grid_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_wf_data  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_wf_grid_detail(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_supply_workflow => i_supply_workflow,
                                                          o_supply_wf_data  => o_supply_wf_data,
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
                                              'GET_SUPPLY_WF_GRID_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_supply_wf_data);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supply_wf_grid_detail;

    FUNCTION get_coding_supply_type_cons
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_coding_supply_type_cons(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => i_episode,
                                                            i_flg_consumption => i_flg_consumption,
                                                            o_types           => o_types,
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
                                              'GET_CODING_SUPPLY_TYPE_CONS',
                                              o_error);
            pk_types.open_my_cursor(o_types);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_coding_supply_type_cons;

    FUNCTION get_repeated_supplies
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_supply_no_saved IN table_number,
        i_id_supply_checked  IN table_number,
        o_show_message       OUT VARCHAR2,
        o_repeated_supplies  OUT pk_types.cursor_type,
        o_labels             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_repeated_supplies(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_episode         => i_id_episode,
                                                      i_id_supply_no_saved => i_id_supply_no_saved,
                                                      i_id_supply_checked  => i_id_supply_checked,
                                                      o_show_message       => o_show_message,
                                                      o_repeated_supplies  => o_repeated_supplies,
                                                      o_labels             => o_labels,
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
                                              'GET_REPEATED_SUPPLIES',
                                              o_error);
            pk_types.open_my_cursor(o_repeated_supplies);
            pk_types.open_my_cursor(o_labels);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_repeated_supplies;

    FUNCTION get_sup_cons_count
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_sup_cons_count(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_episode     => i_id_episode,
                                                   o_sup_cons_count => o_sup_cons_count,
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
                                              'GET_SUP_CONS_COUNT',
                                              o_error);
            pk_types.open_my_cursor(o_sup_cons_count);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_sup_cons_count;

    FUNCTION get_supplies_consumed_counted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_supplies_consumed_counted(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_id_episode     => i_id_episode,
                                                              o_sup_cons_count => o_sup_cons_count,
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
                                              'GET_SUPPLIES_CONSUMED_COUNTED',
                                              o_error);
            pk_types.open_my_cursor(o_sup_cons_count);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supplies_consumed_counted;

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
    
        IF NOT pk_supplies_core.get_supply_count_detail(i_lang                => i_lang,
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
            pk_types.open_my_cursor(o_supply_count_detail);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supply_count_detail;

    FUNCTION check_barcode_scanned
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_barcode        IN supply_barcode.barcode%TYPE,
        i_lot            IN supply_barcode.lot%TYPE,
        o_check          OUT VARCHAR2,
        o_c_supply       OUT pk_types.cursor_type,
        o_c_kit_set      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.check_barcode_scanned(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_supply_area => i_id_supply_area,
                                                      i_barcode        => i_barcode,
                                                      i_lot            => i_lot,
                                                      o_check          => o_check,
                                                      o_c_supply       => o_c_supply,
                                                      o_c_kit_set      => o_c_kit_set,
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
                                              'CHECK_BARCODE_SCANNED',
                                              o_error);
            pk_types.open_my_cursor(o_c_supply);
            pk_types.open_my_cursor(o_c_kit_set);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_barcode_scanned;

    FUNCTION check_asset_nr_scanned
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_asset_nr  IN supply_fixed_asset_nr.fixed_asset_nr%TYPE,
        o_check     OUT VARCHAR2,
        o_c_supply  OUT pk_types.cursor_type,
        o_c_kit_set OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_supplies_core.check_asset_nr_scanned(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_asset_nr  => i_asset_nr,
                                                       o_check     => o_check,
                                                       o_c_supply  => o_c_supply,
                                                       o_c_kit_set => o_c_kit_set,
                                                       o_error     => o_error)
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
                                              'CHECK_ASSET_NR_SCANNED',
                                              o_error);
            pk_types.open_my_cursor(o_c_supply);
            pk_types.open_my_cursor(o_c_kit_set);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_asset_nr_scanned;

    FUNCTION get_supply_info_viewer
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_consumption    IN VARCHAR2,
        o_supply_info        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_info_viewer(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_id_supply_workflow => i_id_supply_workflow,
                                                       i_flg_consumption    => i_flg_consumption,
                                                       o_supply_info        => o_supply_info,
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
                                              'GET_SUPPLY_INFO_VIEWER',
                                              o_error);
            pk_types.open_my_cursor(o_supply_info);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_supply_info_viewer;

    FUNCTION get_supplies_procedure_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies      IN VARCHAR2,
        o_supplies_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_api_db.get_supplies_procedure_grid(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_supplies      => i_supplies,
                                                              o_supplies_info => o_supplies_info,
                                                              o_error         => o_error)
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
                                              'GET_SUPPLIES_PROCEDURE_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_supplies_info);
            RETURN FALSE;
    END get_supplies_procedure_grid;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_supplies_api_ux;
/
