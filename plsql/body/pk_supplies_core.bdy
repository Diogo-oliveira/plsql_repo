/*-- Last Change Revision: $Rev: 2051359 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-28 09:41:24 +0000 (seg, 28 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_core IS

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_supply_area    IN supply_area.id_supply_area%TYPE,
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
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_id_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        i_lot               IN table_varchar DEFAULT NULL,
        i_barcode_scanned   IN table_varchar DEFAULT NULL,
        i_dt_expiration     IN table_varchar DEFAULT NULL,
        i_flg_validation    IN table_varchar DEFAULT NULL,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_supply_workflow table_number;
    
        l_id_supply_area    supply_area.id_supply_area%TYPE := i_id_supply_area;
        l_supply_flg_status supply_request.flg_status%TYPE := CASE
                                                                  WHEN i_supply_flg_status =
                                                                       pk_supplies_constant.g_sww_transport_concluded THEN
                                                                   pk_supplies_constant.g_srt_ongoing
                                                                  ELSE
                                                                   i_supply_flg_status
                                                              END;
    
        l_hashmap           t_hashmap;
        l_sup_wkflow_parent NUMBER;
    
        l_epis_type           epis_type.id_epis_type%TYPE;
        l_flg_type            supply.flg_type%TYPE;
        l_set_supply_location supply_location.id_supply_location%TYPE;
    
        l_tbl_supply_workflow_inact table_number := table_number();
        l_tbl_notes                 table_varchar := table_varchar();
    
        l_count_pharmacy_dispense PLS_INTEGER := 0;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF l_id_supply_area IS NULL
        THEN
            IF i_flg_context IS NOT NULL
               AND i_flg_context.count > 0
               AND i_flg_context(1) = 'S'
            THEN
                l_id_supply_area := pk_supplies_constant.g_area_surgical_supplies;
            
            ELSE
                g_error := 'GET SUPPLY AREA';
                IF NOT pk_supplies_core.get_id_supply_area(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_supply      => i_supply(1),
                                                           i_flg_type       => NULL,
                                                           o_id_supply_area => l_id_supply_area,
                                                           o_error          => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            l_supply_flg_status := CASE
                                       WHEN i_supply_flg_status = pk_supplies_constant.g_sww_predefined THEN
                                        pk_supplies_constant.g_sww_predefined
                                       WHEN i_supply_flg_status = pk_supplies_constant.g_srt_draft THEN
                                        pk_supplies_constant.g_srt_draft
                                       WHEN i_supply_flg_status = pk_supplies_constant.g_sww_transport_concluded THEN
                                        pk_supplies_constant.g_srt_ongoing
                                       ELSE
                                        pk_supplies_constant.g_srt_requested
                                   END;
        
        END IF;
    
        --Block of code to update supply requests associated to medication dispense
        --When updating a medication dispense, the XML of the update it's not indicating that it is an edition,
        --therefore, it is necessary to inactivate supply requests associated to a dispense that are not
        --sent in i_supply.
        IF cardinality(i_flg_context) > 0
        THEN
            IF i_flg_context(1) = pk_supplies_constant.g_context_pharm_dispense
               AND i_id_context(1) IS NOT NULL
            THEN
                SELECT sw.id_supply_workflow
                  BULK COLLECT
                  INTO l_tbl_supply_workflow_inact
                  FROM supply_workflow sw
                 WHERE sw.id_episode = i_id_episode
                   AND sw.id_context = i_id_context(1)
                   AND sw.flg_context = i_flg_context(1)
                   AND sw.id_supply NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                             t.*
                                              FROM TABLE(i_supply) t)
                   AND sw.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                         pk_supplies_constant.g_sww_request_central,
                                         pk_supplies_constant.g_sww_prepared_pharmacist,
                                         pk_supplies_constant.g_sww_in_transit,
                                         pk_supplies_constant.g_sww_transport_concluded,
                                         pk_supplies_constant.g_sww_deliver_concluded);
            
                IF cardinality(l_tbl_supply_workflow_inact) > 0
                THEN
                    FOR i IN l_tbl_supply_workflow_inact.first .. l_tbl_supply_workflow_inact.last
                    LOOP
                        l_tbl_notes.extend();
                        l_tbl_notes(l_tbl_notes.count) := NULL;
                    END LOOP;
                
                    IF NOT pk_supplies_core.update_supply_workflow_status(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_supplies         => l_tbl_supply_workflow_inact,
                                                                          i_id_prof_cancel   => NULL,
                                                                          i_cancel_notes     => NULL,
                                                                          i_id_cancel_reason => NULL,
                                                                          i_dt_cancel        => NULL,
                                                                          i_flg_status       => pk_supplies_constant.g_sww_updated,
                                                                          i_notes            => l_tbl_notes,
                                                                          o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    FOR i IN l_tbl_supply_workflow_inact.first .. l_tbl_supply_workflow_inact.last
                    LOOP
                        SELECT COUNT(1)
                          INTO l_count_pharmacy_dispense
                          FROM (SELECT 1
                                  FROM supply_workflow sw
                                 WHERE sw.id_supply_workflow = l_tbl_supply_workflow_inact(i)
                                   AND sw.flg_status IN
                                       (pk_supplies_constant.g_sww_prepared_pharmacist,
                                        pk_supplies_constant.g_sww_transport_concluded)
                                UNION
                                SELECT 1
                                  FROM supply_workflow_hist swh
                                 WHERE swh.id_supply_workflow = l_tbl_supply_workflow_inact(i)
                                   AND swh.flg_status IN
                                       (pk_supplies_constant.g_sww_prepared_pharmacist,
                                        pk_supplies_constant.g_sww_transport_concluded));
                    
                        IF l_count_pharmacy_dispense > 0
                        THEN
                            pk_ia_event_common.supply_wf_dispense_cancel(i_id_supply_workflow => l_tbl_supply_workflow_inact(i));
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_supply.count
        LOOP
            IF i_supply(i) IS NOT NULL
            THEN
                g_error := 'CREATE REQUEST';
                IF i_id_episode IS NOT NULL
                THEN
                    IF NOT pk_supplies_utils.create_supply_rqt(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_supply_area    => l_id_supply_area,
                                                               i_id_episode        => i_id_episode,
                                                               i_flg_reason_req    => i_flg_reason_req,
                                                               i_id_context        => i_id_context(1),
                                                               i_flg_context       => i_flg_context(1),
                                                               i_supply_flg_status => l_supply_flg_status,
                                                               i_supply_dt_request => g_sysdate_tstz,
                                                               o_id_supply_request => o_id_supply_request,
                                                               o_error             => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                IF i_supply_set(i) IS NOT NULL
                THEN
                    BEGIN
                        l_sup_wkflow_parent := l_hashmap(i_supply_set(i));
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_sup_wkflow_parent := NULL;
                    END;
                ELSE
                    l_sup_wkflow_parent := NULL;
                END IF;
            
                IF i_supply_loc.count() = 0
                   OR i_supply_loc(i) IS NULL
                THEN
                    BEGIN
                        SELECT s.flg_type
                          INTO l_flg_type
                          FROM supply s
                         WHERE s.id_supply = i_supply(i);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_flg_type := NULL;
                    END;
                ELSE
                    l_flg_type := NULL;
                END IF;
            
                l_set_supply_location := NULL;
                IF l_flg_type = pk_supplies_constant.g_supply_set_type
                THEN
                    FOR j IN i_supply_set.first .. i_supply_set.last
                    LOOP
                        IF i_supply_set(j) = i_supply(i)
                        THEN
                            l_set_supply_location := i_supply_loc(j);
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            
                g_error := 'Call create_supply_workflow';
                IF NOT pk_supplies_utils.create_supply_workflow(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_supply_area     => l_id_supply_area,
                                                           i_id_episode         => i_id_episode,
                                                           i_id_supply_request  => o_id_supply_request,
                                                           i_supply             => table_number(i_supply(i)),
                                                           i_supply_set         => table_number(i_supply_set(i)),
                                                           i_supply_qty         => table_number(i_supply_qty(i)),
                                                           i_supply_loc         => CASE
                                                                                       WHEN l_flg_type =
                                                                                            pk_supplies_constant.g_supply_set_type THEN
                                                                                        table_number(l_set_supply_location)
                                                                                       ELSE
                                                                                        table_number(i_supply_loc(i))
                                                                                   END,
                                                           i_flg_status         => CASE
                                                                                       WHEN i_supply_flg_status =
                                                                                            pk_supplies_constant.g_sww_predefined THEN
                                                                                        table_varchar(pk_supplies_constant.g_sww_predefined)
                                                                                       WHEN i_supply_flg_status =
                                                                                            pk_supplies_constant.g_srt_draft THEN
                                                                                        table_varchar(pk_supplies_constant.g_srt_draft)
                                                                                       WHEN i_supply_flg_status =
                                                                                            pk_supplies_constant.g_sww_transport_concluded THEN
                                                                                        table_varchar(pk_supplies_constant.g_sww_transport_concluded)
                                                                                       ELSE
                                                                                        NULL
                                                                                   END, -- calculates flg_status inside this function
                                                           i_dt_request         => table_varchar(i_dt_request(1)),
                                                           i_dt_return          => table_varchar(i_dt_return(i)),
                                                           i_id_req_reason      => table_number(i_id_req_reason(i)),
                                                           i_id_context         => i_id_context(1),
                                                           i_flg_context        => i_flg_context(1),
                                                           i_notes              => table_varchar(i_notes(i)),
                                                           i_id_inst_dest       => i_id_inst_dest,
                                                           i_sup_wkflow_parent  => l_sup_wkflow_parent,
                                                           i_lot                => CASE
                                                                                       WHEN i_lot IS NOT NULL
                                                                                            AND i_lot.exists(i) THEN
                                                                                        table_varchar(i_lot(i))
                                                                                       ELSE
                                                                                        NULL
                                                                                   END,
                                                           i_barcode_scanned    => CASE
                                                                                       WHEN i_barcode_scanned IS NOT NULL
                                                                                            AND i_barcode_scanned.exists(i) THEN
                                                                                        table_varchar(i_barcode_scanned(i))
                                                                                       ELSE
                                                                                        NULL
                                                                                   END,
                                                           i_dt_expiration      => CASE
                                                                                       WHEN i_dt_expiration IS NOT NULL
                                                                                            AND i_dt_expiration.exists(i) THEN
                                                                                        table_varchar(i_dt_expiration(i))
                                                                                       ELSE
                                                                                        NULL
                                                                                   END,
                                                           i_flg_validation     => i_flg_validation,
                                                           o_id_supply_workflow => l_id_supply_workflow,
                                                           o_error              => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF i_supply_flg_status = pk_supplies_constant.g_sww_transport_concluded
                THEN
                    FOR j IN l_id_supply_workflow.first .. l_id_supply_workflow.last
                    LOOP
                        pk_ia_event_common.supply_wf_dispense_new(i_id_supply_workflow => l_id_supply_workflow(j));
                    END LOOP;
                END IF;
            
                IF l_id_supply_workflow.count > 0
                THEN
                    l_hashmap(i_supply(i)) := l_id_supply_workflow(1);
                END IF;
            END IF;
        END LOOP;
    
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
        THEN
            IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => i_id_episode,
                                                 i_id_epis_hhc_req => NULL,
                                                 o_error           => o_error)
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
                                              'CREATE_SUPPLY_ORDER',
                                              o_error);
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
    
        l_continue BOOLEAN := TRUE;
    
        l_id_supply_workflow supply_workflow.id_supply_workflow%TYPE;
        l_delayed_sup_status grid_task.supplies%TYPE;
    
        l_dt_returned          supply_workflow.dt_returned%TYPE;
        l_dt_expiration        supply_workflow.dt_expiration%TYPE;
        l_avail_units          supply_soft_inst.quantity%TYPE;
        l_ret                  BOOLEAN;
        l_total_avail_quantity supply_soft_inst.total_avail_quantity%TYPE;
        l_id_supply_area       supply_area.id_supply_area%TYPE;
        l_id_supply_location   supply_workflow.id_supply_location%TYPE;
    
        l_available_quantity supply_workflow.quantity%TYPE;
        l_remaining_quantity supply_workflow.quantity%TYPE;
        l_quantity_dispensed supply_workflow.quantity%TYPE;
    
        l_set_workflow table_number;
        l_count        NUMBER;
    
        l_fixed_asset_number table_varchar;
    
        l_rows_out table_varchar := table_varchar();
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        l_sw_row supply_workflow%ROWTYPE;
    
        l_tbl_parent_supplies table_number := table_number();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_fixed_asset_number IS NULL
        THEN
            l_fixed_asset_number := table_varchar();
        ELSE
            l_fixed_asset_number := i_fixed_asset_number;
        END IF;
    
        g_error := 'GET SUPPLY AREA';
        IF i_flg_supply_type(1) IS NOT NULL
        THEN
            IF NOT pk_supplies_core.get_id_supply_area(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply      => NULL,
                                                       i_flg_type       => i_flg_supply_type(1),
                                                       o_id_supply_area => l_id_supply_area,
                                                       o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            l_id_supply_area := 1;
        END IF;
    
        IF i_test = pk_supplies_constant.g_yes
        THEN
            --checks if it is necessary to reopen the episode and if it is reopen it
            g_error := 'CALL PK_ACTIVITY_THERAPIST.SET_REOPEN_EPISODE';
            IF NOT pk_activity_therapist.set_reopen_episode(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode,
                                                            i_flg_test   => i_test,
                                                            o_flg_show   => o_flg_show,
                                                            o_msg        => o_msg,
                                                            o_msg_title  => o_msg_title,
                                                            o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF o_flg_show = pk_supplies_constant.g_yes
            THEN
                l_continue := FALSE;
            END IF;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'COUNT:' || i_id_supply_workflow.count;
            FOR i IN 1 .. i_id_supply_workflow.count
            LOOP
                g_error := 'Test quantities' || '-' || i_check_quantities || '-' || pk_supplies_constant.g_yes;
                IF i_check_quantities = pk_supplies_constant.g_yes
                THEN
                    g_error       := 'CALL GET_NR_AVAIL_UNITS';
                    l_avail_units := get_nr_avail_units(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_supply_area => l_id_supply_area,
                                                        i_id_supply      => i_supply(i),
                                                        i_id_episode     => i_id_episode);
                
                    IF i_supply_qty(i) > l_avail_units
                    THEN
                        l_ret := pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                                     i_sqlcode     => '',
                                                                     i_sqlerrm     => '',
                                                                     i_message     => g_error,
                                                                     i_owner       => g_package_owner,
                                                                     i_package     => g_package_name,
                                                                     i_function    => 'CREATE_SUPPLY_WITH_CONSUMPTION',
                                                                     i_action_type => pk_act_therap_constant.g_warning,
                                                                     i_action_msg  => pk_message.get_message(i_lang,
                                                                                                             pk_act_therap_constant.g_msg_error),
                                                                     i_msg_title   => pk_message.get_message(i_lang,
                                                                                                             pk_act_therap_constant.g_msg_wrong_loan_units),
                                                                     o_error       => o_error);
                        RETURN TRUE;
                    END IF;
                END IF;
            
                IF i_dt_expected_date IS NOT NULL
                   AND i_dt_expected_date.count > 0
                THEN
                    l_dt_returned := pk_date_utils.get_string_tstz(i_lang,
                                                                   i_prof,
                                                                   i_dt_expected_date(i),
                                                                   pk_date_utils.get_timezone(i_lang, i_prof));
                END IF;
            
                IF i_dt_expiration IS NOT NULL
                   AND i_dt_expiration.count > 0
                THEN
                    l_dt_expiration := pk_date_utils.get_string_tstz(i_lang,
                                                                     i_prof,
                                                                     i_dt_expiration(i),
                                                                     pk_date_utils.get_timezone(i_lang, i_prof));
                END IF;
            
                l_id_supply_location := pk_supplies_core.get_default_location(i_lang,
                                                                              i_prof,
                                                                              l_id_supply_area,
                                                                              nvl(i_supply_set(i), i_supply(i)));
            
                l_rows_out := NULL;
            
                IF i_id_supply_workflow(i) IS NOT NULL
                THEN
                    l_available_quantity := pk_supplies_core.get_supply_available_quantity(i_lang               => i_lang,
                                                                                           i_prof               => i_prof,
                                                                                           i_id_supply_workflow => i_id_supply_workflow(i));
                
                    l_remaining_quantity := l_available_quantity - nvl(i_supply_qty(i), 0);
                
                    SELECT nvl(s.quantity, 1)
                      INTO l_quantity_dispensed
                      FROM supply_workflow s
                     WHERE s.id_supply_workflow = i_id_supply_workflow(i);
                
                    IF l_remaining_quantity <= 0
                    THEN
                        pk_supplies_utils.set_supply_workflow_hist(i_id_supply_workflow(i), NULL, NULL);
                        ts_supply_workflow.upd(id_supply_workflow_in  => i_id_supply_workflow(i),
                                               id_professional_in     => CASE
                                                                             WHEN i_flg_context = pk_supplies_constant.g_context_medication THEN
                                                                              NULL
                                                                             ELSE
                                                                              i_prof.id
                                                                         END,
                                               id_episode_in          => i_id_episode,
                                               barcode_scanned_in     => i_barcode_scanned(i),
                                               barcode_scanned_nin    => FALSE,
                                               flg_status_in          => CASE
                                                                             WHEN i_supply_qty(i) < l_quantity_dispensed THEN
                                                                              pk_supplies_constant.g_sww_all_consumed
                                                                             ELSE
                                                                              CASE i_flg_cons_type(i)
                                                                                  WHEN pk_supplies_constant.g_consumption_type_loan THEN
                                                                                   pk_supplies_constant.g_sww_loaned
                                                                                  ELSE
                                                                                   CASE i_deliver_needed(i)
                                                                                       WHEN pk_supplies_constant.g_yes THEN
                                                                                        pk_supplies_constant.g_sww_deliver_needed
                                                                                       ELSE
                                                                                        pk_supplies_constant.g_sww_consumed
                                                                                   END
                                                                              END
                                                                         END,
                                               flg_status_nin         => FALSE,
                                               dt_returned_in         => l_dt_returned,
                                               dt_returned_nin        => FALSE,
                                               notes_in               => i_notes(i),
                                               notes_nin              => FALSE,
                                               dt_supply_workflow_in  => g_sysdate_tstz,
                                               dt_supply_workflow_nin => FALSE,
                                               asset_number_in        => CASE l_fixed_asset_number.count
                                                                             WHEN 0 THEN
                                                                              NULL
                                                                             ELSE
                                                                              l_fixed_asset_number(i)
                                                                         END,
                                               flg_cons_type_in       => i_flg_cons_type(i),
                                               lot_in                 => CASE i_lot.count
                                                                             WHEN 0 THEN
                                                                              NULL
                                                                             ELSE
                                                                              i_lot(i)
                                                                         END,
                                               lot_nin                => FALSE,
                                               dt_expiration_in       => l_dt_expiration,
                                               dt_expiration_nin      => FALSE,
                                               flg_validation_in      => CASE i_flg_validation.count
                                                                             WHEN 0 THEN
                                                                              NULL
                                                                             ELSE
                                                                              i_flg_validation(i)
                                                                         END,
                                               flg_validation_nin     => FALSE,
                                               rows_out               => l_rows_out);
                    
                        IF i_flg_context != pk_supplies_constant.g_context_procedure_req
                        THEN
                            pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => i_id_supply_workflow(i));
                        END IF;
                    END IF;
                
                    IF i_supply_qty(i) < l_quantity_dispensed
                    THEN
                        SELECT *
                          INTO l_sw_row
                          FROM supply_workflow sw
                         WHERE sw.id_supply_workflow = i_id_supply_workflow(i);
                    
                        l_id_supply_workflow := ts_supply_workflow.next_key;
                    
                        ts_supply_workflow.ins(id_supply_workflow_in     => l_id_supply_workflow,
                                               id_professional_in        => i_prof.id,
                                               id_episode_in             => l_sw_row.id_episode,
                                               id_supply_request_in      => l_sw_row.id_supply_request,
                                               id_supply_in              => l_sw_row.id_supply,
                                               id_supply_location_in     => l_sw_row.id_supply_location,
                                               barcode_req_in            => l_sw_row.barcode_req,
                                               barcode_scanned_in        => i_barcode_scanned(i),
                                               quantity_in               => i_supply_qty(i),
                                               id_unit_measure_in        => l_sw_row.id_unit_measure,
                                               id_context_in             => l_sw_row.id_context,
                                               flg_context_in            => l_sw_row.flg_context,
                                               flg_status_in             => CASE i_flg_cons_type(i)
                                                                                WHEN
                                                                                 pk_supplies_constant.g_consumption_type_loan THEN
                                                                                 pk_supplies_constant.g_sww_loaned
                                                                                ELSE
                                                                                 CASE i_deliver_needed(i)
                                                                                     WHEN pk_supplies_constant.g_yes THEN
                                                                                      pk_supplies_constant.g_sww_deliver_needed
                                                                                     ELSE
                                                                                      pk_supplies_constant.g_sww_consumed
                                                                                 END
                                                                            END,
                                               dt_request_in             => l_sw_row.dt_request,
                                               dt_returned_in            => l_dt_returned,
                                               notes_in                  => i_notes(i),
                                               id_prof_cancel_in         => l_sw_row.id_prof_cancel,
                                               dt_cancel_in              => l_sw_row.dt_cancel,
                                               notes_cancel_in           => l_sw_row.notes_cancel,
                                               id_cancel_reason_in       => l_sw_row.id_cancel_reason,
                                               notes_reject_in           => l_sw_row.notes_reject,
                                               dt_reject_in              => l_sw_row.dt_reject,
                                               id_prof_reject_in         => l_sw_row.id_prof_reject,
                                               dt_supply_workflow_in     => g_sysdate_tstz,
                                               id_req_reason_in          => l_sw_row.id_req_reason,
                                               id_del_reason_in          => l_sw_row.id_del_reason,
                                               id_supply_set_in          => l_sw_row.id_supply_set,
                                               id_sup_workflow_parent_in => l_sw_row.id_sup_workflow_parent,
                                               total_quantity_in         => i_supply_qty(i),
                                               asset_number_in           => CASE l_fixed_asset_number.count
                                                                                WHEN 0 THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 l_fixed_asset_number(i)
                                                                            END,
                                               flg_outdated_in           => l_sw_row.flg_outdated,
                                               flg_cons_type_in          => i_flg_cons_type(i),
                                               flg_reusable_in           => l_sw_row.flg_reusable,
                                               flg_editable_in           => l_sw_row.flg_editable,
                                               total_avail_quantity_in   => l_total_avail_quantity,
                                               cod_table_in              => l_sw_row.cod_table,
                                               flg_preparing_in          => l_sw_row.flg_preparing,
                                               flg_countable_in          => l_sw_row.flg_countable,
                                               id_supply_area_in         => l_id_supply_area,
                                               lot_in                    => CASE i_lot.count
                                                                                WHEN 0 THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 i_lot(i)
                                                                            END,
                                               dt_expiration_in          => l_dt_expiration,
                                               flg_validation_in         => CASE i_flg_validation.count
                                                                                WHEN 0 THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 i_flg_validation(i)
                                                                            END,
                                               supply_migration_in       => l_sw_row.supply_migration,
                                               id_consumption_parent_in  => i_id_supply_workflow(i),
                                               rows_out                  => l_rows_out);
                    
                        IF i_flg_context != pk_supplies_constant.g_context_procedure_req
                        THEN
                            pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => l_id_supply_workflow);
                        END IF;
                    END IF;
                
                    g_error := 'CALL PROCESS_UPDATE';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SUPPLY_WORKFLOW',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                ELSE
                    l_id_supply_workflow := ts_supply_workflow.next_key;
                
                    g_error                := 'CALL GET_TOTAL_AVAIL_QUANTITY';
                    l_total_avail_quantity := pk_supplies_utils.get_total_avail_quantity(i_lang           => i_lang,
                                                                                         i_prof           => i_prof,
                                                                                         i_id_supply_area => l_id_supply_area,
                                                                                         i_id_supply      => i_supply(i),
                                                                                         i_flg_cons_type  => i_flg_cons_type(i),
                                                                                         i_id_episode     => i_id_episode);
                
                    ts_supply_workflow.ins(id_supply_workflow_in   => l_id_supply_workflow,
                                           id_professional_in      => i_prof.id,
                                           id_episode_in           => i_id_episode,
                                           id_supply_in            => i_supply(i),
                                           id_supply_set_in        => i_supply_set(i),
                                           barcode_scanned_in      => i_barcode_scanned(i),
                                           asset_number_in         => CASE l_fixed_asset_number.count
                                                                          WHEN 0 THEN
                                                                           NULL
                                                                          ELSE
                                                                           l_fixed_asset_number(i)
                                                                      END,
                                           quantity_in             => i_supply_qty(i),
                                           total_quantity_in       => i_supply_qty(i),
                                           id_context_in           => i_id_context,
                                           flg_context_in          => i_flg_context,
                                           flg_status_in           => CASE i_flg_cons_type(i)
                                                                          WHEN pk_supplies_constant.g_consumption_type_loan THEN
                                                                           pk_supplies_constant.g_sww_loaned
                                                                          ELSE
                                                                           CASE i_deliver_needed(i)
                                                                               WHEN pk_supplies_constant.g_yes THEN
                                                                                pk_supplies_constant.g_sww_deliver_needed
                                                                               ELSE
                                                                                pk_supplies_constant.g_sww_consumed
                                                                           END
                                                                      END,
                                           dt_supply_workflow_in   => g_sysdate_tstz,
                                           dt_returned_in          => l_dt_returned,
                                           notes_in                => i_notes(i),
                                           total_avail_quantity_in => l_total_avail_quantity,
                                           id_supply_area_in       => l_id_supply_area,
                                           dt_expiration_in        => l_dt_expiration,
                                           flg_validation_in       => CASE i_flg_validation.count
                                                                          WHEN 0 THEN
                                                                           NULL
                                                                          ELSE
                                                                           i_flg_validation(i)
                                                                      END,
                                           lot_in                  => CASE i_lot.count
                                                                          WHEN 0 THEN
                                                                           NULL
                                                                          ELSE
                                                                           i_lot(i)
                                                                      END,
                                           flg_cons_type_in        => i_flg_cons_type(i),
                                           id_supply_location_in   => l_id_supply_location,
                                           rows_out                => l_rows_out);
                
                    g_error := 'CALL PROCESS_INSERT';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SUPPLY_WORKFLOW',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    IF i_flg_context != pk_supplies_constant.g_context_procedure_req
                    THEN
                        pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => l_id_supply_workflow);
                    END IF;
                END IF;
            
                IF i_deliver_needed(i) = pk_supplies_constant.g_yes
                THEN
                    g_error              := 'i_deliver_needed(i):' || i_deliver_needed(i) || '-' ||
                                            pk_supplies_constant.g_yes || '.';
                    l_delayed_sup_status := get_epis_max_supply_delay(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_patient => pk_episode.get_id_patient(i_id_episode));
                    ts_grid_task.upd(where_in => 'ID_EPISODE = ' || i_id_episode, supplies_in => l_delayed_sup_status);
                END IF;
            END LOOP;
        
            g_error := 'Update parent supply';
            SELECT DISTINCT sw.id_sup_workflow_parent
              BULK COLLECT
              INTO l_tbl_parent_supplies
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(i_id_supply_workflow) t)
               AND sw.id_sup_workflow_parent IS NOT NULL;
        
            IF l_tbl_parent_supplies.exists(1)
            THEN
                IF NOT pk_supplies_core.set_supply_parent_status(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_parents_supplies => l_tbl_parent_supplies,
                                                                 o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION FOR PARENTS SUPPLIES';
                IF NOT update_supply_request(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_id_supply_workflow => l_tbl_parent_supplies,
                                             o_error              => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
        THEN
            IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => i_id_episode,
                                                 i_id_epis_hhc_req => NULL,
                                                 o_error           => o_error)
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
                                              'CREATE_SUPPLY_WITH_CONSUMPTION',
                                              o_error);
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
        i_qty_dispensed IN table_number DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode          supply_workflow.id_episode%TYPE;
        l_new_flg_status      supply_workflow.flg_status%TYPE;
        l_delayed_sup_status  grid_task.supplies%TYPE;
        l_grid_task           grid_task%ROWTYPE;
        l_tbl_parent_supplies table_number := table_number();
    
        l_rows_out table_varchar := table_varchar();
    
        l_transport_needed sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('SUPPLIES_TRANSPORT_NEEDED', i_prof);
    
        l_id_supply_workflow       supply_workflow.id_supply_workflow%TYPE;
        l_available_qty_after_disp supply_workflow.quantity%TYPE := 0;
        r_supply_workflow          supply_workflow%ROWTYPE;
        l_tbl_new_records          table_number := table_number();
    
        l_prof_cat category.flg_type%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        FOR i IN 1 .. i_supplies.count
        LOOP
            CASE i_prepared_by(i)
                WHEN pk_alert_constant.g_cat_type_pharmacist THEN
                    l_new_flg_status := CASE l_transport_needed
                                            WHEN pk_alert_constant.g_yes THEN
                                             pk_supplies_constant.g_sww_prepared_pharmacist
                                            ELSE
                                             pk_supplies_constant.g_sww_transport_concluded
                                        END;
                WHEN pk_alert_constant.g_cat_type_nurse THEN
                    l_new_flg_status := CASE l_transport_needed
                                            WHEN pk_alert_constant.g_yes THEN
                                             CASE l_prof_cat
                                                 WHEN pk_alert_constant.g_cat_type_pharmacist THEN
                                                  pk_supplies_constant.g_sww_prepared_pharmacist
                                                 ELSE
                                                  pk_supplies_constant.g_sww_prepared_technician
                                             END
                                            ELSE
                                             pk_supplies_constant.g_sww_transport_concluded
                                        END;
                ELSE
                    l_new_flg_status := CASE l_transport_needed
                                            WHEN pk_alert_constant.g_yes THEN
                                             pk_supplies_constant.g_sww_prepared_technician
                                            ELSE
                                             pk_supplies_constant.g_sww_transport_concluded
                                        END;
            END CASE;
        
            pk_supplies_utils.set_supply_workflow_hist(i_supplies(i), NULL, NULL);
        
            SELECT sw.*
              INTO r_supply_workflow
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_supplies(i);
        
            IF i_qty_dispensed.exists(i)
            THEN
                IF i_qty_dispensed(i) IS NOT NULL
                THEN
                    l_available_qty_after_disp := r_supply_workflow.quantity - i_qty_dispensed(i);
                END IF;
            END IF;
        
            --If it was a partial dispense, a new requisition is made, and the original requisition is updated
            IF l_available_qty_after_disp > 0
            THEN
                ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                       id_professional_in    => i_prof.id,
                                       id_supply_in          => i_new_supplies(i),
                                       quantity_in           => l_available_qty_after_disp,
                                       dt_supply_workflow_in => g_sysdate_tstz,
                                       rows_out              => l_rows_out);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SUPPLY_WORKFLOW',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                l_id_supply_workflow := ts_supply_workflow.next_key;
            
                l_tbl_new_records.extend();
                l_tbl_new_records(l_tbl_new_records.count) := l_id_supply_workflow;
            
                ts_supply_workflow.ins(id_supply_workflow_in     => l_id_supply_workflow,
                                       id_professional_in        => i_prof.id,
                                       id_episode_in             => r_supply_workflow.id_episode,
                                       id_supply_request_in      => r_supply_workflow.id_supply_request,
                                       id_supply_in              => r_supply_workflow.id_supply,
                                       id_supply_location_in     => r_supply_workflow.id_supply_location,
                                       barcode_req_in            => CASE
                                                                        WHEN i_unic_id.count > 0 THEN
                                                                         i_unic_id(i)
                                                                        ELSE
                                                                         r_supply_workflow.barcode_req
                                                                    END,
                                       barcode_scanned_in        => r_supply_workflow.barcode_scanned,
                                       quantity_in               => i_qty_dispensed(i),
                                       id_unit_measure_in        => r_supply_workflow.id_unit_measure,
                                       id_context_in             => r_supply_workflow.id_context,
                                       flg_context_in            => r_supply_workflow.flg_context,
                                       flg_status_in             => l_new_flg_status,
                                       dt_request_in             => r_supply_workflow.dt_request,
                                       dt_returned_in            => r_supply_workflow.dt_returned,
                                       notes_in                  => CASE
                                                                        WHEN i_prep_notes.count > 0 THEN
                                                                         i_prep_notes(i)
                                                                        ELSE
                                                                         r_supply_workflow.notes
                                                                    END,
                                       id_prof_cancel_in         => r_supply_workflow.id_prof_cancel,
                                       dt_cancel_in              => r_supply_workflow.dt_cancel,
                                       notes_cancel_in           => r_supply_workflow.notes_cancel,
                                       id_cancel_reason_in       => r_supply_workflow.id_cancel_reason,
                                       notes_reject_in           => r_supply_workflow.notes_reject,
                                       dt_reject_in              => r_supply_workflow.dt_reject,
                                       id_prof_reject_in         => r_supply_workflow.id_prof_reject,
                                       dt_supply_workflow_in     => g_sysdate_tstz,
                                       id_req_reason_in          => r_supply_workflow.id_req_reason,
                                       id_del_reason_in          => r_supply_workflow.id_del_reason,
                                       id_supply_set_in          => r_supply_workflow.id_supply_set,
                                       id_sup_workflow_parent_in => r_supply_workflow.id_sup_workflow_parent,
                                       total_quantity_in         => i_qty_dispensed(i),
                                       asset_number_in           => r_supply_workflow.asset_number,
                                       flg_outdated_in           => r_supply_workflow.flg_outdated,
                                       flg_cons_type_in          => r_supply_workflow.flg_cons_type,
                                       flg_reusable_in           => r_supply_workflow.flg_reusable,
                                       flg_editable_in           => r_supply_workflow.flg_editable,
                                       total_avail_quantity_in   => r_supply_workflow.total_avail_quantity,
                                       cod_table_in              => r_supply_workflow.cod_table,
                                       flg_preparing_in          => r_supply_workflow.flg_preparing,
                                       flg_countable_in          => r_supply_workflow.flg_countable,
                                       id_supply_area_in         => r_supply_workflow.id_supply_area,
                                       lot_in                    => r_supply_workflow.lot,
                                       dt_expiration_in          => r_supply_workflow.dt_expiration,
                                       flg_validation_in         => r_supply_workflow.flg_validation,
                                       supply_migration_in       => r_supply_workflow.supply_migration,
                                       id_consumption_parent_in  => NULL,
                                       id_dispense_parent_in     => i_supplies(i),
                                       rows_out                  => l_rows_out);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SUPPLY_WORKFLOW',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => l_id_supply_workflow);
                pk_ia_event_common.supply_wf_dispense_new(i_id_supply_workflow => l_id_supply_workflow);
            ELSE
                ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                       id_professional_in    => i_prof.id,
                                       id_supply_in          => i_new_supplies(i),
                                       barcode_req_in        => CASE
                                                                    WHEN i_unic_id.count > 0 THEN
                                                                     i_unic_id(i)
                                                                    ELSE
                                                                     NULL
                                                                END,
                                       flg_status_in         => l_new_flg_status,
                                       notes_in              => CASE
                                                                    WHEN i_prep_notes.count > 0 THEN
                                                                     i_prep_notes(i)
                                                                    ELSE
                                                                     NULL
                                                                END,
                                       dt_supply_workflow_in => g_sysdate_tstz,
                                       rows_out              => l_rows_out);
            
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SUPPLY_WORKFLOW',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                pk_ia_event_common.supply_wf_dispense_new(i_id_supply_workflow => i_supplies(i));
            END IF;
        
            g_error              := 'get_epis_max_supply_delay';
            l_delayed_sup_status := pk_supplies_core.get_epis_max_supply_delay(i_lang       => i_lang,
                                                                               i_prof       => i_prof,
                                                                               i_id_patient => i_id_patient);
        
            l_grid_task.id_episode := r_supply_workflow.id_episode;
            l_grid_task.supplies   := l_delayed_sup_status;
        
            g_error := 'update_grid_task';
            IF NOT pk_grid.update_grid_task(i_lang, l_grid_task, o_error)
            
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT update_supply_request(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_supply_workflow => i_supplies,
                                     o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Update parent supply';
        SELECT DISTINCT sw.id_sup_workflow_parent
          BULK COLLECT
          INTO l_tbl_parent_supplies
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_supplies) t)
            OR sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(l_tbl_new_records) t);
    
        IF l_tbl_parent_supplies.exists(1)
        THEN
            IF NOT pk_supplies_core.set_supply_parent_status(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_parents_supplies => l_tbl_parent_supplies,
                                                             o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION FOR PARENTS SUPPLIES';
            IF NOT update_supply_request(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_supply_workflow => l_tbl_parent_supplies,
                                         o_error              => o_error)
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
                                              'SET_SUPPLY_PREPARATION',
                                              o_error);
            RETURN FALSE;
    END set_supply_preparation;

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
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_empty_array_varchar table_varchar := table_varchar();
        l_id_context          table_number := table_number();
        l_flg_context         table_varchar := table_varchar();
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        IF i_supply_workflow IS NOT NULL
           AND i_supply_workflow.count > 0
        THEN
            g_error := 'INITIALIZING COLLECTIONS';
            l_empty_array_varchar.extend(i_supply_workflow.count);
            l_id_context.extend(i_supply_workflow.count);
            l_flg_context.extend(i_supply_workflow.count);
        
            FOR i IN 1 .. i_supply_workflow.count
            LOOP
                l_id_context(i) := i_id_context;
                l_flg_context(i) := i_flg_context;
            END LOOP;
        
        END IF;
    
        g_error := 'CALL pk_supplies_core.UPDATE_SUPPLY_WORKFLOW';
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
                                                       i_id_context      => l_id_context,
                                                       i_flg_context     => l_flg_context,
                                                       i_notes           => i_notes,
                                                       i_flg_cons_type   => l_empty_array_varchar,
                                                       i_cod_table       => l_empty_array_varchar,
                                                       o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
        THEN
            IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => i_id_episode,
                                                 i_id_epis_hhc_req => NULL,
                                                 o_error           => o_error)
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
                                              'UPDATE_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END update_supply_order;

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
    
        l_flg_status     supply_workflow.flg_status%TYPE;
        l_quantity       supply_workflow.quantity%TYPE;
        l_total_quantity supply_workflow.total_quantity%TYPE;
        l_id_supply      supply_workflow.id_supply%TYPE;
        l_id_parent      supply_workflow.id_sup_workflow_parent%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_test = pk_supplies_constant.g_yes
        THEN
            g_error := 'CALL check_edit_reopen_epis';
            IF NOT pk_supplies_utils.check_edit_reopen_epis(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_episode      => i_id_episode,
                                                            i_supply_workflow => i_supply_workflow,
                                                            i_supply_qty      => i_supply_qty,
                                                            o_flg_show        => o_flg_show,
                                                            o_msg             => o_msg,
                                                            o_msg_title       => o_msg_title,
                                                            o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            g_error := 'CALL pk_activity_therapist.set_reopen_episode';
            IF NOT pk_activity_therapist.set_reopen_episode(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode,
                                                            i_flg_test   => i_flg_test,
                                                            o_flg_show   => o_flg_show,
                                                            o_msg        => o_msg,
                                                            o_msg_title  => o_msg_title,
                                                            o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF i_flg_test = pk_alert_constant.g_no
           AND o_flg_show = pk_alert_constant.g_no
        THEN
            SELECT sw.flg_status, sw.quantity, sw.total_quantity, sw.id_supply, sw.id_sup_workflow_parent
              INTO l_flg_status, l_quantity, l_total_quantity, l_id_supply, l_id_parent
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_supply_workflow(1);
        
            IF l_flg_status = pk_supplies_constant.g_sww_loaned
            THEN
                --it is only possible to edit the quantity between the nr of loaned units and nr previous loans + nr avail
                g_error := 'CALL set_edit_loans';
                IF NOT pk_supplies_utils.set_edit_loans(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_episode       => i_id_episode,
                                                        i_supply_workflow  => i_supply_workflow,
                                                        i_supply_qty       => i_supply_qty,
                                                        i_dt_return        => i_dt_return,
                                                        i_barcode_scanned  => i_barcode_scanned,
                                                        i_asset_nr_scanned => i_asset_nr_scanned,
                                                        o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
            ELSIF l_flg_status = pk_supplies_constant.g_sww_deliver_institution
            THEN
                --it is only possible to edit the quantity between 1 and the total nr of loans
                g_error := 'CALL set_delivery';
                IF NOT pk_supplies_utils.set_delivery(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_supply_workflow  => i_supply_workflow,
                                                      i_supply_qty       => i_supply_qty,
                                                      i_dt_return        => i_dt_return,
                                                      i_id_episode       => i_id_episode,
                                                      i_flg_edition      => pk_supplies_constant.g_yes,
                                                      i_barcode_scanned  => i_barcode_scanned,
                                                      i_asset_nr_scanned => i_asset_nr_scanned,
                                                      o_flg_show         => o_flg_show,
                                                      o_msg              => o_msg,
                                                      o_msg_title        => o_msg_title,
                                                      o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
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
                                              'SET_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END set_supply_order;

    FUNCTION set_supply_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_supply_workflow table_number;
        l_flg_cons_type      table_varchar;
        l_flg_reusable       table_varchar;
        l_rows_upd           table_varchar;
    
        l_set_workflow table_number;
        l_count        NUMBER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'GET ID_SUPPLY_WORKFLOW, FLG_CONST_TYPE AND FLG_REUSABLE ';
        --GET ALL RECORDS FOR THIS ID_SUPPLY_REQUEST, ID_SUPPLY AND THE STATUS WAS CONSUME AND COUNT
        BEGIN
            SELECT sw.id_supply_workflow, sw.flg_cons_type, sw.flg_reusable
              BULK COLLECT
              INTO l_id_supply_workflow, l_flg_cons_type, l_flg_reusable
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate(table, t1, scale_rows=1))*/
                                              t1.column_value
                                               FROM TABLE(i_id_supply_workflow) t1);
        EXCEPTION
            WHEN no_data_found THEN
                l_id_supply_workflow := NULL;
                l_flg_cons_type      := NULL;
                l_flg_reusable       := NULL;
        END;
    
        FOR i IN 1 .. l_id_supply_workflow.count
        LOOP
            g_error := 'CALL PK_SUPPLIES_API_DB.SET_SUPPLY_WORKFLOW_HIST FOR ID_SUPPLY_WORKFLOW: ' ||
                       l_id_supply_workflow(i);
        
            pk_supplies_api_db.set_supply_workflow_hist(l_id_supply_workflow(i), NULL, NULL);
        
            --IF THE FLG_CONS_TYPE IS LOANED (PROVIDE TO THE PATIENT) SO THE FLG_STATUS IS PASSED TO 'L' 
            --IN CASE IS LOCAL CONSUMPTION IS NECESSARY CHECK THE FLG_REUSABLE IS YES (Y), 
            --IS NECESSARY DELIVER THIS SUPPLY 'N' ELSE THE SUPPLY IS CONSUMED 'O'
            g_error := 'UPDATE SUPPLY_WORKFLOW TABLE FOR I_ID_SUPPLY_WORKFLOW : ' || l_id_supply_workflow(i);
            ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow(i),
                                   id_professional_in    => i_prof.id,
                                   flg_status_in         => CASE l_flg_cons_type(i)
                                                                WHEN pk_supplies_constant.g_consumption_type_loan THEN
                                                                 pk_supplies_constant.g_sww_loaned
                                                                WHEN pk_supplies_constant.g_consumption_type_implant THEN
                                                                 pk_supplies_constant.g_sww_consumed
                                                                ELSE
                                                                 CASE l_flg_reusable(i)
                                                                     WHEN pk_alert_constant.g_yes THEN
                                                                      pk_supplies_constant.g_sww_deliver_needed
                                                                     ELSE
                                                                      pk_supplies_constant.g_sww_consumed
                                                                 END
                                                            END,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows_upd);
        
            g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE FOR SUPPLY_WORKFLOW';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows_upd,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW', 'I_PROF', 'FLG_STATUS'));
        
            pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => l_id_supply_workflow(i));
        
            SELECT DISTINCT sw.id_sup_workflow_parent
              BULK COLLECT
              INTO l_set_workflow
              FROM supply_workflow sw
             WHERE id_supply_workflow IN (SELECT *
                                            FROM TABLE(i_id_supply_workflow))
               AND sw.id_sup_workflow_parent IS NOT NULL;
        
            IF l_set_workflow IS NOT NULL
               AND l_set_workflow.count > 0
            THEN
                FOR i IN 1 .. l_set_workflow.count
                LOOP
                    SELECT COUNT(*)
                      INTO l_count
                      FROM supply_workflow sw
                     WHERE sw.id_sup_workflow_parent = l_set_workflow(i)
                       AND sw.flg_status NOT IN ('O', 'C', 'V', 'Y');
                
                    IF l_count = 0
                    THEN
                        IF NOT set_supply_consumption(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_supply_workflow => table_number(l_set_workflow(i)),
                                                      o_error              => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
        END LOOP;
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT pk_supplies_core.update_supply_request(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_supply_workflow => l_id_supply_workflow,
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
                                              'SET_SUPPLY_CONSUMPTION',
                                              o_error);
            RETURN FALSE;
    END set_supply_consumption;

    FUNCTION set_supply_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_flg_status IN supply_workflow.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_category       category.flg_type%TYPE;
        l_new_flg_status      supply_workflow.flg_status%TYPE := i_flg_status;
        l_tbl_parent_supplies table_number := table_number();
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_status IS NULL
        THEN
            l_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
            --if the professional executing the task is a md or a nurse, the next status will be one
            IF l_prof_category = pk_alert_constant.g_cat_type_doc
               OR l_prof_category = pk_alert_constant.g_cat_type_nurse
            THEN
                l_new_flg_status := pk_supplies_constant.g_sww_transport_concluded;
                --if the professional executing the task is not a md nor a nurse, the next status will be another
            ELSE
                l_new_flg_status := pk_supplies_constant.g_sww_deliver_concluded;
            END IF;
        END IF;
    
        --for each supply on the i_supplies list, we update it's status
        FOR i IN 1 .. i_supplies.count
        LOOP
            g_error := 'UPDATE SUPPLY_WORKFLOW';
            pk_supplies_utils.set_supply_workflow_hist(i_supplies(i), NULL, NULL);
        
            ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                   flg_status_in         => l_new_flg_status,
                                   id_professional_in    => i_prof.id,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows_out);
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT update_supply_request(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_supply_workflow => i_supplies,
                                     o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Update parent supply';
        SELECT DISTINCT sw.id_sup_workflow_parent
          BULK COLLECT
          INTO l_tbl_parent_supplies
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_supplies) t);
    
        IF l_tbl_parent_supplies.exists(1)
        THEN
            IF NOT pk_supplies_core.set_supply_parent_status(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_parents_supplies => l_tbl_parent_supplies,
                                                             o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION FOR PARENTS SUPPLIES';
            IF NOT update_supply_request(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_supply_workflow => l_tbl_parent_supplies,
                                         o_error              => o_error)
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
                                              'SET_SUPPLY_STATUS',
                                              o_error);
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
    
        l_barcode_scanned  table_varchar := table_varchar();
        l_asset_nr_scanned table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_supply_workflow.count
        LOOP
            l_barcode_scanned.extend(1);
            l_barcode_scanned(i) := NULL;
            l_asset_nr_scanned.extend(1);
            l_asset_nr_scanned(i) := NULL;
        END LOOP;
    
        g_error := 'CALL set_delivery';
        IF NOT pk_supplies_utils.set_delivery(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_supply_workflow  => i_supply_workflow,
                                              i_supply_qty       => i_supply_qty,
                                              i_id_episode       => i_id_episode,
                                              i_flg_edition      => pk_alert_constant.g_no,
                                              i_barcode_scanned  => l_barcode_scanned,
                                              i_asset_nr_scanned => l_asset_nr_scanned,
                                              o_flg_show         => o_flg_show,
                                              o_msg              => o_msg,
                                              o_msg_title        => o_msg_title,
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
                                              'SET_SUPPLY_DELIVERY',
                                              o_error);
            RETURN FALSE;
    END set_supply_delivery;

    FUNCTION set_supply_delivery_confirmation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'CHECK RECORDS STATUSES';
        SELECT COUNT(1)
          INTO l_count
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT t.* /*+opt_estimate (table t rows=1)*/
                                           FROM TABLE(i_supply_workflow) t)
           AND sw.flg_status <> pk_supplies_constant.g_sww_deliver_concluded;
    
        IF l_count > 0
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL set_supply_status';
        IF NOT pk_supplies_core.set_supply_status(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_supplies   => i_supply_workflow,
                                                  i_flg_status => pk_supplies_constant.g_sww_deliver_validated,
                                                  o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --Sending interface info regarding delivery validation
        FOR i IN i_supply_workflow.first .. i_supply_workflow.last
        LOOP
            pk_ia_event_common.supply_wf_dispense_return(i_id_supply_workflow => i_supply_workflow(i));
        END LOOP;
    
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
    
        l_rows_out table_varchar := table_varchar();
    
        l_tbl_parent_supplies table_number := table_number();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_supplies.count
        LOOP
            pk_supplies_utils.set_supply_workflow_hist(i_supplies(i), NULL, NULL);
        
            g_error := 'UPDATE SUPPLY_WORKFLOW';
            ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_concluded,
                                   barcode_scanned_in    => i_barcode(i),
                                   id_professional_in    => i_prof.id,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows_out);
        END LOOP;
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT update_supply_request(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_supply_workflow => i_supplies,
                                     o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Update parent supply';
        SELECT DISTINCT sw.id_sup_workflow_parent
          BULK COLLECT
          INTO l_tbl_parent_supplies
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_supplies) t)
           AND sw.id_sup_workflow_parent IS NOT NULL;
    
        IF l_tbl_parent_supplies.exists(1)
        THEN
            IF NOT pk_supplies_core.set_supply_parent_status(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_parents_supplies => l_tbl_parent_supplies,
                                                             o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION FOR PARENTS SUPPLIES';
            IF NOT update_supply_request(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_supply_workflow => l_tbl_parent_supplies,
                                         o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
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
    
        l_prof_category  category.flg_type%TYPE;
        l_new_flg_status supply_workflow.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF l_prof_category = pk_alert_constant.g_cat_type_pharmacist
        THEN
            --if the professional executing the task is a pharmacist
            l_new_flg_status := pk_supplies_constant.g_sww_rejected_pharmacist;
        ELSE
            --if the professional executing the task is not a pharmacist, put it as a technician
            l_new_flg_status := pk_supplies_constant.g_sww_rejected_technician;
        END IF;
    
        g_error := 'update supply_workflow';
        pk_supplies_utils.set_supply_workflow_hist(i_id_supply_workflow, NULL, NULL);
    
        ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_workflow,
                               flg_status_in         => l_new_flg_status,
                               id_prof_reject_in     => i_prof.id,
                               notes_reject_in       => i_rejection_notes,
                               dt_reject_in          => g_sysdate_tstz,
                               dt_supply_workflow_in => g_sysdate_tstz,
                               id_professional_in    => i_prof.id,
                               rows_out              => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT update_supply_request(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_supply_workflow => table_number(i_id_supply_workflow),
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
                                              'SET_SUPPLY_REJECT',
                                              o_error);
            RETURN FALSE;
    END set_supply_reject;

    FUNCTION set_supply_for_delivery
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_supplies    IN table_number,
        i_reason      IN table_number,
        i_notes       IN table_varchar,
        i_id_episode  IN supply_workflow.id_episode%TYPE,
        i_flg_context IN supply_workflow.flg_context%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_delayed_sup_status grid_task.supplies%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
        l_available_quantity supply_workflow.quantity%TYPE;
        l_consumed_quantity  supply_workflow.quantity%TYPE;
    
        l_sw_row              supply_workflow%ROWTYPE;
        l_id_supply_workflow  supply_workflow.id_supply_workflow%TYPE;
        l_tbl_parent_supplies table_number := table_number();
    
        l_transport_needed sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('SUPPLIES_TRANSPORT_NEEDED', i_prof);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_supplies.count
        LOOP
            g_error := 'SET WORKFLOW HISTORY';
            pk_supplies_utils.set_supply_workflow_hist(i_id_supply_workflow => i_supplies(i),
                                                       i_id_context         => NULL,
                                                       i_flg_context        => NULL);
        
            SELECT coalesce(SUM(s.quantity), 0)
              INTO l_consumed_quantity
              FROM supply_workflow s
             WHERE s.id_consumption_parent = i_supplies(i);
        
            IF l_consumed_quantity > 0
            THEN
                l_available_quantity := pk_supplies_core.get_supply_available_quantity(i_lang               => i_lang,
                                                                                       i_prof               => i_prof,
                                                                                       i_id_supply_workflow => i_supplies(i));
            
                g_error := 'UPDATE WORKFLOW STATUS';
                ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                       id_professional_in    => i_prof.id,
                                       flg_status_in         => pk_supplies_constant.g_sww_all_consumed,
                                       id_del_reason_in      => i_reason(i),
                                       notes_in              => i_notes(i),
                                       dt_supply_workflow_in => g_sysdate_tstz,
                                       rows_out              => l_rows_out);
            
                pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => i_supplies(i));
            
                SELECT *
                  INTO l_sw_row
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_supplies(i);
            
                l_id_supply_workflow := seq_supply_workflow.nextval;
            
                ts_supply_workflow.ins(id_supply_workflow_in     => l_id_supply_workflow,
                                       id_professional_in        => i_prof.id,
                                       id_episode_in             => l_sw_row.id_episode,
                                       id_supply_request_in      => l_sw_row.id_supply_request,
                                       id_supply_in              => l_sw_row.id_supply,
                                       id_supply_location_in     => l_sw_row.id_supply_location,
                                       barcode_req_in            => l_sw_row.barcode_req,
                                       barcode_scanned_in        => l_sw_row.barcode_scanned,
                                       quantity_in               => l_available_quantity,
                                       id_unit_measure_in        => l_sw_row.id_unit_measure,
                                       id_context_in             => l_sw_row.id_context,
                                       flg_context_in            => l_sw_row.flg_context,
                                       flg_status_in             => CASE
                                                                        WHEN l_transport_needed = pk_alert_constant.g_yes
                                                                             AND (i_flg_context NOT IN
                                                                             (pk_supplies_constant.g_context_pharm_dispense) OR
                                                                             i_flg_context IS NULL) THEN
                                                                         pk_supplies_constant.g_sww_deliver_needed
                                                                        ELSE
                                                                         pk_supplies_constant.g_sww_deliver_concluded
                                                                    END,
                                       dt_request_in             => l_sw_row.dt_request,
                                       dt_returned_in            => g_sysdate_tstz,
                                       notes_in                  => l_sw_row.notes,
                                       id_prof_cancel_in         => l_sw_row.id_prof_cancel,
                                       dt_cancel_in              => l_sw_row.dt_cancel,
                                       notes_cancel_in           => l_sw_row.notes_cancel,
                                       id_cancel_reason_in       => l_sw_row.id_cancel_reason,
                                       notes_reject_in           => l_sw_row.notes_reject,
                                       dt_reject_in              => l_sw_row.dt_reject,
                                       id_prof_reject_in         => l_sw_row.id_prof_reject,
                                       dt_supply_workflow_in     => g_sysdate_tstz,
                                       id_req_reason_in          => l_sw_row.id_req_reason,
                                       id_del_reason_in          => l_sw_row.id_del_reason,
                                       id_supply_set_in          => l_sw_row.id_supply_set,
                                       id_sup_workflow_parent_in => l_sw_row.id_sup_workflow_parent,
                                       total_quantity_in         => l_sw_row.total_quantity,
                                       asset_number_in           => l_sw_row.asset_number,
                                       flg_outdated_in           => l_sw_row.flg_outdated,
                                       flg_cons_type_in          => l_sw_row.flg_cons_type,
                                       flg_reusable_in           => l_sw_row.flg_reusable,
                                       flg_editable_in           => l_sw_row.flg_editable,
                                       total_avail_quantity_in   => l_sw_row.total_avail_quantity,
                                       cod_table_in              => l_sw_row.cod_table,
                                       flg_preparing_in          => l_sw_row.flg_preparing,
                                       flg_countable_in          => l_sw_row.flg_countable,
                                       id_supply_area_in         => l_sw_row.id_supply_area,
                                       lot_in                    => l_sw_row.lot,
                                       dt_expiration_in          => l_sw_row.dt_expiration,
                                       flg_validation_in         => l_sw_row.flg_validation,
                                       supply_migration_in       => l_sw_row.supply_migration,
                                       id_consumption_parent_in  => i_supplies(i),
                                       rows_out                  => l_rows_out);
            ELSE
                g_error := 'UPDATE WORKFLOW STATUS';
                ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                       id_professional_in    => i_prof.id,
                                       flg_status_in         => CASE
                                                                    WHEN l_transport_needed = pk_alert_constant.g_yes
                                                                         AND (i_flg_context NOT IN
                                                                         (pk_supplies_constant.g_context_pharm_dispense) OR
                                                                         i_flg_context IS NULL) THEN
                                                                     pk_supplies_constant.g_sww_deliver_needed
                                                                    ELSE
                                                                     pk_supplies_constant.g_sww_deliver_concluded
                                                                END,
                                       id_del_reason_in      => i_reason(i),
                                       notes_in              => i_notes(i),
                                       dt_supply_workflow_in => g_sysdate_tstz,
                                       rows_out              => l_rows_out);
            
                pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => i_supplies(i));
            END IF;
        END LOOP;
    
        l_delayed_sup_status := get_epis_max_supply_delay(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => pk_episode.get_id_patient(i_id_episode));
        ts_grid_task.upd(where_in => 'ID_EPISODE = ' || i_id_episode, supplies_in => l_delayed_sup_status);
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST';
        IF NOT update_supply_request(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_supply_workflow => i_supplies,
                                     o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Update parent supply';
        SELECT DISTINCT sw.id_sup_workflow_parent
          BULK COLLECT
          INTO l_tbl_parent_supplies
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_supplies) t)
           AND sw.id_sup_workflow_parent IS NOT NULL;
    
        IF l_tbl_parent_supplies.exists(1)
        THEN
            IF NOT pk_supplies_core.set_supply_parent_status(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_parents_supplies => l_tbl_parent_supplies,
                                                             o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION FOR PARENTS SUPPLIES';
            IF NOT update_supply_request(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_supply_workflow => l_tbl_parent_supplies,
                                         o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
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
        
            RETURN FALSE;
    END set_supply_for_delivery;

    FUNCTION set_supply_parent_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_parents_supplies IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_status PLS_INTEGER := 0;
        l_flg_status   supply_workflow.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        IF i_parents_supplies.count > 0
           AND i_parents_supplies.exists(1)
        THEN
            FOR i IN i_parents_supplies.first .. i_parents_supplies.last
            LOOP
                IF i_parents_supplies(i) IS NOT NULL
                THEN
                    --Verify if all the child records present the same status
                    --Only then the parent can be updated
                    SELECT COUNT(1)
                      INTO l_count_status
                      FROM (SELECT DISTINCT sw.flg_status
                              FROM supply_workflow sw
                             WHERE sw.id_sup_workflow_parent = i_parents_supplies(i)
                               AND sw.flg_status NOT IN
                                   (pk_supplies_constant.g_sww_cancelled,
                                    pk_supplies_constant.g_sww_all_consumed,
                                    pk_supplies_constant.g_sww_consumed,
                                    pk_supplies_constant.g_sww_deliver_needed,
                                    pk_supplies_constant.g_sww_in_delivery,
                                    pk_supplies_constant.g_sww_deliver_concluded));
                
                    IF l_count_status <= 1
                    THEN
                        g_error := 'GET SUPPLY WORKFLOW STATUS';
                        SELECT flg_status
                          INTO l_flg_status
                          FROM (SELECT flg_status,
                                       decode(flg_status,
                                              pk_supplies_constant.g_sww_cancelled,
                                              5,
                                              pk_supplies_constant.g_sww_deliver_concluded,
                                              10,
                                              pk_supplies_constant.g_sww_consumed,
                                              20,
                                              pk_supplies_constant.g_sww_in_delivery,
                                              30,
                                              pk_supplies_constant.g_sww_deliver_needed,
                                              40,
                                              50) rank
                                  FROM (SELECT DISTINCT sw.flg_status
                                          FROM supply_workflow sw
                                         WHERE sw.id_sup_workflow_parent = i_parents_supplies(i)
                                           AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_all_consumed))
                                 ORDER BY rank DESC)
                         WHERE rownum = 1;
                    
                        g_error := 'UPDATE SUPPLY WORKFLOw STATUS';
                        ts_supply_workflow.upd(id_supply_workflow_in => i_parents_supplies(i),
                                               flg_status_in         => l_flg_status,
                                               id_professional_in    => i_prof.id,
                                               dt_supply_workflow_in => g_sysdate_tstz,
                                               rows_out              => l_rows_out);
                    
                        g_error := 'CALL PROCESS_UPDATE';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUPPLY_WORKFLOW',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
            RETURN FALSE;
    END set_supply_parent_status;

    FUNCTION set_pharmacy_delivery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
        l_id_reason  supply_workflow.id_del_reason%TYPE;
        l_notes      supply_workflow.notes%TYPE;
    
        l_tbl_supply_workflow table_number := table_number();
        l_tbl_reason          table_number := table_number();
        l_tbl_notes           table_varchar := table_varchar();
    
    BEGIN
        FOR i IN i_id_pha_dispense.first .. i_id_pha_dispense.last
        LOOP
            SELECT sw.id_supply_workflow
              BULK COLLECT
              INTO l_tbl_supply_workflow
              FROM supply_workflow sw
             WHERE sw.flg_context = pk_supplies_constant.g_context_pharm_dispense
               AND sw.id_context = i_id_pha_dispense(i)
               AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled, pk_supplies_constant.g_sww_consumed);
        
            IF nvl(cardinality(l_tbl_supply_workflow), 0) > 0
            THEN
                SELECT pr.id_reason, pk_translation.get_translation_trs(pr.code_notes), pr.id_episode
                  INTO l_id_reason, l_notes, l_id_episode
                  FROM TABLE(pk_rt_pha_med.get_pharm_return_detail_button(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_id_pha_dispense => i_id_pha_dispense(i),
                                                                          i_id_task_type    => 45,
                                                                          i_flg_history     => pk_alert_constant.g_no,
                                                                          i_flg_distinct    => pk_alert_constant.g_yes)) pr;
            
                FOR j IN l_tbl_supply_workflow.first .. l_tbl_supply_workflow.last
                LOOP
                    l_tbl_reason.extend();
                    l_tbl_reason(l_tbl_reason.count) := l_id_reason;
                
                    l_tbl_notes.extend();
                    l_tbl_notes(l_tbl_notes.count) := to_char(l_notes);
                END LOOP;
            
                IF NOT pk_supplies_core.set_supply_for_delivery(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_supplies    => l_tbl_supply_workflow,
                                                                i_reason      => l_tbl_reason,
                                                                i_notes       => l_tbl_notes,
                                                                i_id_episode  => l_id_episode,
                                                                i_flg_context => pk_supplies_constant.g_context_pharm_dispense,
                                                                o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END LOOP;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PHARMACY_DELIVERY',
                                              o_error);
            RETURN FALSE;
    END set_pharmacy_delivery;

    FUNCTION update_supply_workflow_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_id_prof_cancel   IN professional.id_professional%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel        IN supply_workflow.dt_cancel%TYPE,
        i_flg_status       IN supply_workflow.flg_status%TYPE,
        i_notes            IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_cancel_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_count_status   NUMBER;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_supplies.count
        LOOP
            SELECT COUNT(*)
              INTO l_count_status
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_supplies(i)
               AND sw.flg_status = i_flg_status;
        
            IF l_count_status != 0
            THEN
                g_error := 'Record already updated for ' ||
                           pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_STATUS', i_flg_status, i_lang) || ' status';
                RAISE g_other_exception;
            ELSE
                IF i_flg_status = pk_supplies_constant.g_sww_cancelled
                THEN
                
                    IF i_dt_cancel IS NULL
                    THEN
                        l_dt_cancel_tstz := current_timestamp;
                    ELSE
                        l_dt_cancel_tstz := i_dt_cancel;
                    END IF;
                
                    IF NOT pk_supplies_core.cancel_supply_order(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_supplies         => table_number(i_supplies(i)),
                                                                i_id_prof_cancel   => i_id_prof_cancel,
                                                                i_cancel_notes     => i_cancel_notes,
                                                                i_id_cancel_reason => i_id_cancel_reason,
                                                                i_dt_cancel        => l_dt_cancel_tstz,
                                                                o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                ELSIF i_flg_status IN (pk_supplies_constant.g_sww_request_local,
                                       pk_supplies_constant.g_sww_request_central,
                                       pk_supplies_constant.g_sww_rejected_pharmacist,
                                       pk_supplies_constant.g_sww_prepared_pharmacist,
                                       pk_supplies_constant.g_sww_validated,
                                       pk_supplies_constant.g_sww_prepared_technician,
                                       pk_supplies_constant.g_sww_rejected_technician,
                                       pk_supplies_constant.g_sww_in_transit,
                                       pk_supplies_constant.g_sww_transport_concluded,
                                       pk_supplies_constant.g_sww_loaned,
                                       pk_supplies_constant.g_sww_consumed,
                                       pk_supplies_constant.g_sww_deliver_needed,
                                       pk_supplies_constant.g_sww_in_delivery,
                                       pk_supplies_constant.g_sww_deliver_concluded,
                                       pk_supplies_constant.g_sww_transport_done,
                                       pk_supplies_constant.g_sww_consumed_delivery_needed,
                                       pk_supplies_constant.g_sww_request_wait,
                                       pk_supplies_constant.g_sww_request_external_system,
                                       pk_supplies_constant.g_sww_deliver_institution,
                                       pk_supplies_constant.g_sww_deliver_cancelled,
                                       pk_supplies_constant.g_sww_prep_sup_for_surg,
                                       pk_supplies_constant.g_sww_cons_and_count,
                                       pk_supplies_constant.g_sww_updated)
                THEN
                    pk_supplies_utils.set_supply_workflow_hist(i_supplies(i), NULL, NULL);
                
                    ts_supply_workflow.upd(id_supply_workflow_in => i_supplies(i),
                                           flg_status_in         => i_flg_status,
                                           notes_in              => i_notes(i),
                                           dt_supply_workflow_in => g_sysdate_tstz,
                                           rows_out              => l_rows_out);
                
                    g_error := 'CALL PROCESS_UPDATE';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SUPPLY_WORKFLOW',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => i_supplies(i));
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SUPPLY_WORKFLOW_STATUS',
                                              o_error);
            RETURN FALSE;
    END update_supply_workflow_status;

    FUNCTION cancel_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_id_prof_cancel   IN professional.id_professional%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel        IN supply_workflow.dt_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cancel    professional.id_professional%TYPE;
        l_dt_cancel_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_supplies       table_number;
    
        l_set_workflow table_number;
        l_count        NUMBER;
        l_flg_status   supply_workflow.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
        l_tbl_parent_supplies table_number := table_number();
    
        l_consumed_quantity  supply_workflow.quantity%TYPE;
        l_available_quantity supply_workflow.quantity%TYPE;
        l_sw_row             supply_workflow%ROWTYPE;
        l_id_supply_workflow supply_workflow.id_supply_workflow%TYPE;
    
        l_count_pharmacy_dispense PLS_INTEGER := 0;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_prof_cancel IS NOT NULL
        THEN
            l_prof_cancel := i_id_prof_cancel;
        ELSE
            l_prof_cancel := i_prof.id;
        END IF;
    
        IF i_dt_cancel IS NULL
        THEN
            l_dt_cancel_tstz := current_timestamp;
        ELSE
            l_dt_cancel_tstz := i_dt_cancel;
        END IF;
    
        g_error := 'update supply_workflow';
        FOR i IN 1 .. i_supplies.count
        LOOP
        
            SELECT t.id_supply_workflow
              BULK COLLECT
              INTO l_supplies
              FROM (SELECT sw.id_supply_workflow
                      FROM supply_workflow sw
                     INNER JOIN supply_workflow swp
                        ON sw.id_episode = swp.id_episode
                       AND sw.id_supply_set = swp.id_supply
                       AND sw.id_sup_workflow_parent = swp.id_supply_workflow
                     WHERE swp.id_supply_workflow = i_supplies(i)
                    UNION ALL
                    SELECT i_supplies(i)
                      FROM dual) t;
        
            FOR j IN 1 .. l_supplies.count
            LOOP
            
                SELECT coalesce(SUM(s.quantity), 0)
                  INTO l_consumed_quantity
                  FROM supply_workflow s
                 WHERE s.id_consumption_parent = i_supplies(i);
            
                IF l_consumed_quantity > 0
                THEN
                    l_available_quantity := pk_supplies_core.get_supply_available_quantity(i_lang               => i_lang,
                                                                                           i_prof               => i_prof,
                                                                                           i_id_supply_workflow => l_supplies(i));
                
                    g_error := 'UPDATE WORKFLOW STATUS';
                    ts_supply_workflow.upd(id_supply_workflow_in => l_supplies(i),
                                           id_professional_in    => i_prof.id,
                                           flg_status_in         => pk_supplies_constant.g_sww_all_consumed,
                                           id_del_reason_in      => NULL, --i_reason(i),
                                           notes_in              => NULL, --i_notes(i),
                                           dt_supply_workflow_in => g_sysdate_tstz,
                                           rows_out              => l_rows_out);
                
                    pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => i_supplies(i));
                
                    SELECT *
                      INTO l_sw_row
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = l_supplies(i);
                
                    l_id_supply_workflow := seq_supply_workflow.nextval;
                
                    ts_supply_workflow.ins(id_supply_workflow_in     => l_id_supply_workflow,
                                           id_professional_in        => i_prof.id,
                                           id_episode_in             => l_sw_row.id_episode,
                                           id_supply_request_in      => l_sw_row.id_supply_request,
                                           id_supply_in              => l_sw_row.id_supply,
                                           id_supply_location_in     => l_sw_row.id_supply_location,
                                           barcode_req_in            => l_sw_row.barcode_req,
                                           barcode_scanned_in        => l_sw_row.barcode_scanned,
                                           quantity_in               => l_available_quantity,
                                           id_unit_measure_in        => l_sw_row.id_unit_measure,
                                           id_context_in             => l_sw_row.id_context,
                                           flg_context_in            => l_sw_row.flg_context,
                                           flg_status_in             => pk_supplies_constant.g_sww_cancelled,
                                           dt_request_in             => l_sw_row.dt_request,
                                           dt_returned_in            => g_sysdate_tstz,
                                           notes_in                  => l_sw_row.notes,
                                           id_prof_cancel_in         => l_prof_cancel,
                                           dt_cancel_in              => l_dt_cancel_tstz,
                                           notes_cancel_in           => i_cancel_notes,
                                           id_cancel_reason_in       => i_id_cancel_reason,
                                           notes_reject_in           => l_sw_row.notes_reject,
                                           dt_reject_in              => l_sw_row.dt_reject,
                                           id_prof_reject_in         => l_sw_row.id_prof_reject,
                                           dt_supply_workflow_in     => g_sysdate_tstz,
                                           id_req_reason_in          => l_sw_row.id_req_reason,
                                           id_del_reason_in          => l_sw_row.id_del_reason,
                                           id_supply_set_in          => l_sw_row.id_supply_set,
                                           id_sup_workflow_parent_in => l_sw_row.id_sup_workflow_parent,
                                           total_quantity_in         => l_sw_row.total_quantity,
                                           asset_number_in           => l_sw_row.asset_number,
                                           flg_outdated_in           => l_sw_row.flg_outdated,
                                           flg_cons_type_in          => l_sw_row.flg_cons_type,
                                           flg_reusable_in           => l_sw_row.flg_reusable,
                                           flg_editable_in           => l_sw_row.flg_editable,
                                           total_avail_quantity_in   => l_sw_row.total_avail_quantity,
                                           cod_table_in              => l_sw_row.cod_table,
                                           flg_preparing_in          => l_sw_row.flg_preparing,
                                           flg_countable_in          => l_sw_row.flg_countable,
                                           id_supply_area_in         => l_sw_row.id_supply_area,
                                           lot_in                    => l_sw_row.lot,
                                           dt_expiration_in          => l_sw_row.dt_expiration,
                                           flg_validation_in         => l_sw_row.flg_validation,
                                           supply_migration_in       => l_sw_row.supply_migration,
                                           id_consumption_parent_in  => i_supplies(i),
                                           rows_out                  => l_rows_out);
                
                    SELECT COUNT(1)
                      INTO l_count_pharmacy_dispense
                      FROM (SELECT 1
                              FROM supply_workflow sw
                             WHERE sw.id_supply_workflow = l_id_supply_workflow
                               AND sw.flg_status IN (pk_supplies_constant.g_sww_prepared_pharmacist,
                                                     pk_supplies_constant.g_sww_transport_concluded)
                            UNION
                            SELECT 1
                              FROM supply_workflow_hist swh
                             WHERE swh.id_supply_workflow = l_id_supply_workflow
                               AND swh.flg_status IN (pk_supplies_constant.g_sww_prepared_pharmacist,
                                                      pk_supplies_constant.g_sww_transport_concluded));
                
                    IF l_count_pharmacy_dispense > 0
                    THEN
                        pk_ia_event_common.supply_wf_dispense_cancel(i_id_supply_workflow => l_id_supply_workflow);
                    END IF;
                ELSE
                    pk_supplies_utils.set_supply_workflow_hist(i_supplies(i), NULL, NULL);
                
                    ts_supply_workflow.upd(id_supply_workflow_in => l_supplies(j),
                                           flg_status_in         => pk_supplies_constant.g_sww_cancelled,
                                           notes_cancel_in       => i_cancel_notes,
                                           id_cancel_reason_in   => i_id_cancel_reason,
                                           dt_cancel_in          => l_dt_cancel_tstz,
                                           id_prof_cancel_in     => l_prof_cancel,
                                           dt_supply_workflow_in => g_sysdate_tstz,
                                           id_professional_in    => i_prof.id,
                                           rows_out              => l_rows_out);
                
                    SELECT COUNT(1)
                      INTO l_count_pharmacy_dispense
                      FROM (SELECT 1
                              FROM supply_workflow sw
                             WHERE sw.id_supply_workflow = l_supplies(j)
                               AND sw.flg_status IN (pk_supplies_constant.g_sww_prepared_pharmacist,
                                                     pk_supplies_constant.g_sww_transport_concluded)
                            UNION
                            SELECT 1
                              FROM supply_workflow_hist swh
                             WHERE swh.id_supply_workflow = l_supplies(j)
                               AND swh.flg_status IN (pk_supplies_constant.g_sww_prepared_pharmacist,
                                                      pk_supplies_constant.g_sww_transport_concluded));
                
                    IF l_count_pharmacy_dispense > 0
                    THEN
                        pk_ia_event_common.supply_wf_dispense_cancel(i_id_supply_workflow => l_supplies(j));
                    END IF;
                END IF;
            END LOOP;
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUPPLY_WORKFLOW',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END LOOP;
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT update_supply_request(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_supply_workflow => i_supplies,
                                     o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL REVERT_SUPPLY_CONSUMPTION FUNCTION';
        IF NOT pk_supplies_core.revert_supply_consumption(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_supply_workflow => i_supplies,
                                                          o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --Update set status  
        g_error := 'Update parent supply';
        SELECT DISTINCT sw.id_sup_workflow_parent
          BULK COLLECT
          INTO l_tbl_parent_supplies
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_supplies) t)
           AND sw.id_sup_workflow_parent IS NOT NULL;
    
        IF l_tbl_parent_supplies.exists(1)
        THEN
            IF NOT pk_supplies_core.set_supply_parent_status(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_parents_supplies => l_tbl_parent_supplies,
                                                             o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION FOR PARENTS SUPPLIES';
            IF NOT update_supply_request(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_supply_workflow => l_tbl_parent_supplies,
                                         o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
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

    FUNCTION cancel_supply_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_request   IN supply_request.id_supply_request%TYPE,
        i_notes            IN supply_request.notes%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_supply IS
            SELECT sw.id_supply_workflow
              FROM supply_workflow sw
             WHERE sw.id_supply_request = i_supply_request;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SET REQUEST HISTORY';
        pk_supplies_utils.set_supply_request_hist(i_supply_request);
    
        g_error := 'CANCEL REQUEST';
        ts_supply_request.upd(id_supply_request_in => i_supply_request,
                              id_prof_cancel_in    => i_prof.id,
                              dt_cancel_in         => g_sysdate_tstz,
                              notes_in             => i_notes,
                              rows_out             => l_rows_out);
    
        l_rows_out := NULL;
    
        FOR rec IN c_supply
        LOOP
            g_error := 'SET WORKFLOW HISTORY';
            pk_supplies_utils.set_supply_workflow_hist(rec.id_supply_workflow, NULL, NULL);
        
            g_error := 'CANCEL WORKFLOW';
            ts_supply_workflow.upd(id_supply_workflow_in => rec.id_supply_workflow,
                                   flg_status_in         => pk_supplies_constant.g_sww_cancelled,
                                   id_prof_cancel_in     => i_prof.id,
                                   dt_cancel_in          => g_sysdate_tstz,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   id_professional_in    => i_prof.id,
                                   id_cancel_reason_in   => i_id_cancel_reason,
                                   rows_out              => l_rows_out);
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SUPPLY_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_supply_request;

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
    
        r_supply_workflow       supply_workflow%ROWTYPE;
        l_delivered_quantitites table_number;
        l_id_supplies           table_number := table_number();
    
        l_msg_title_reopen VARCHAR2(4000) := NULL;
        l_msg_reopen       VARCHAR2(4000) := NULL;
        l_flg_show_reopen  VARCHAR2(1 CHAR);
    
    BEGIN
        SELECT s.quantity
          BULK COLLECT
          INTO l_delivered_quantitites
          FROM supply_workflow s
         WHERE s.id_supply_workflow IN (SELECT column_value
                                          FROM TABLE(i_supplies_workflow));
    
        IF (i_flg_test = pk_alert_constant.get_yes)
        THEN
            --2nd test: check if it is necessary to reopen the episode (if the episode had already been discharged)
            --and check if it is possible to reopen the episode (if there is not any other active activity therapy episode)
            g_error := 'CALL pk_activity_therapist.set_reopen_episode';
            IF NOT pk_activity_therapist.set_reopen_episode(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode,
                                                            i_flg_test   => pk_supplies_constant.g_yes,
                                                            o_flg_show   => l_flg_show_reopen,
                                                            o_msg        => l_msg_reopen,
                                                            o_msg_title  => l_msg_title_reopen,
                                                            o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            --if it is not possible to reopen the episode.
            -- Finish the test and show the warning
            IF (l_flg_show_reopen = pk_act_therap_constant.g_flg_show_r)
            THEN
                o_flg_show  := l_flg_show_reopen;
                o_msg       := l_msg_reopen;
                o_msg_title := l_msg_title_reopen;
                RETURN TRUE;
            ELSE
                -- validates if it is possible to cancel all the deliveries       
                FOR i IN 1 .. i_supplies_workflow.count
                LOOP
                
                    SELECT *
                      INTO r_supply_workflow
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_supplies_workflow(i);
                
                    g_error := 'CALL check_cancel_deliver';
                    IF NOT pk_supplies_utils.check_cancel_deliver(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_supply           => r_supply_workflow.id_supply,
                                                                  i_id_episode          => r_supply_workflow.id_episode,
                                                                  i_supply_workflow     => i_supplies_workflow,
                                                                  io_supplies_no_cancel => l_id_supplies,
                                                                  o_error               => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                END LOOP;
            
                IF l_id_supplies IS NOT NULL
                   AND l_id_supplies.exists(1)
                THEN
                    IF NOT pk_supplies_utils.get_canc_deliveries_msgs(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_id_supplies => l_id_supplies,
                                                                      o_flg_show    => o_flg_show,
                                                                      o_msg         => o_msg,
                                                                      o_msg_title   => o_msg_title,
                                                                      o_error       => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                END IF;
            
                --if it is possible to cancel the delivery because the supplies are not available any more
                IF o_flg_show != pk_alert_constant.g_no
                THEN
                    RETURN TRUE;
                ELSIF (l_flg_show_reopen != pk_alert_constant.g_no)
                THEN
                    o_flg_show  := pk_act_therap_constant.g_flg_show_q;
                    o_msg       := l_msg_reopen;
                    o_msg_title := l_msg_title_reopen;
                END IF;
            
                RETURN TRUE;
            END IF;
        ELSE
            --checks if it is necessary to reopen the episode and if it is reopen it
            g_error := 'CALL pk_activity_therapist.set_reopen_episode';
            IF NOT pk_activity_therapist.set_reopen_episode(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode,
                                                            i_flg_test   => pk_alert_constant.g_no,
                                                            o_flg_show   => o_flg_show,
                                                            o_msg        => o_msg,
                                                            o_msg_title  => o_msg_title,
                                                            o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF o_flg_show = pk_alert_constant.g_no
            THEN
                g_error := 'CALL set_cancel_deliver';
                IF NOT pk_supplies_utils.set_cancel_deliver(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_supplies_workflow => i_supplies_workflow,
                                                            i_cancel_notes      => i_cancel_notes,
                                                            i_id_cancel_reason  => i_id_cancel_reason,
                                                            i_flg_edition       => pk_alert_constant.g_no,
                                                            i_quantities        => NULL,
                                                            i_dt_return         => NULL,
                                                            o_flg_show          => o_flg_show,
                                                            o_msg               => o_msg,
                                                            o_msg_title         => o_msg_title,
                                                            o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
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
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'update supply_workflow';
        FOR i IN 1 .. i_supplies_workflow.count
        LOOP
            g_error := 'CALL set_history for id_supply_workflow: ' || i_supplies_workflow(i);
            IF NOT pk_supplies_utils.set_history(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_supply_workflow => i_supplies_workflow(i),
                                                 i_flg_edition        => pk_supplies_constant.g_yes,
                                                 o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            ts_supply_workflow.upd(id_supply_workflow_in => i_supplies_workflow(i),
                                   flg_status_in         => pk_supplies_constant.g_sww_cancelled,
                                   notes_cancel_in       => i_cancel_notes,
                                   id_cancel_reason_in   => i_id_cancel_reason,
                                   dt_cancel_in          => g_sysdate_tstz,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   id_prof_cancel_in     => i_prof.id,
                                   rows_out              => l_rows_out);
        END LOOP;
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE FOR SUPPLY_WORKFLOW';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        --if the patient has not more loaned supplies and the parent episode is inactive, the child episode
        -- should also stay inactive
    
        g_error := 'CALL pk_activity_therapist.set_parent_epis_inact';
        IF NOT pk_activity_therapist.set_epis_inact_no_sup(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_episode => i_id_episode,
                                                           o_flg_show   => o_flg_show,
                                                           o_msg        => o_msg,
                                                           o_msg_title  => o_msg_title,
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
    
        l_type       sys_domain.code_domain%TYPE := 'SUPPLY.FLG_TYPE';
        l_dept       episode.id_dept_requested%TYPE;
        l_count_prof PLS_INTEGER;
        l_count_dept PLS_INTEGER;
    
    BEGIN
    
        g_error := 'i_lang:' || i_lang || ' i_prof.id:' || i_prof.id || ' i_prof.institution:' || i_prof.institution ||
                   ' i_prof.software:' || i_prof.software || 'i_id_supply_area:' || i_id_supply_area || ' i_episode:' ||
                   i_episode;
        IF i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
        THEN
            l_type := 'SUPPLY.FLG_TYPE.SR';
        END IF;
    
        g_error := 'l_count_prof calculate';
        IF i_id_inst_dest IS NULL
        THEN
        
            SELECT COUNT(*)
              INTO l_count_prof
              FROM supply_soft_inst ssi
             INNER JOIN supply s
                ON s.id_supply = ssi.id_supply
             INNER JOIN supply_sup_area ssa
                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
               AND ssa.flg_available = pk_supplies_constant.g_yes
               AND ssa.id_supply_area = nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies)
             WHERE ssi.id_institution = i_prof.institution
               AND ssi.id_software = i_prof.software
               AND ssi.id_professional = i_prof.id
               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
        
            g_error := 'l_count_prof=' || l_count_prof || ', l_dept calculate';
            IF i_episode IS NOT NULL
            THEN
                SELECT e.id_dept_requested
                  INTO l_dept
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            
                g_error := 'l_dept=' || l_dept || ', l_count_dept calculate';
                SELECT COUNT(*)
                  INTO l_count_dept
                  FROM supply_soft_inst ssi
                 INNER JOIN supply s
                    ON s.id_supply = ssi.id_supply
                 INNER JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                   AND ssa.flg_available = pk_supplies_constant.g_yes
                   AND ssa.id_supply_area = nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies)
                 WHERE ssi.id_institution = i_prof.institution
                   AND ssi.id_software = i_prof.software
                   AND ssi.id_dept = l_dept
                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
            
            ELSE
                l_count_dept := 0;
            END IF;
        
            IF l_count_prof > 0
            THEN
            
                g_error := 'OPEN o_selection_list ---  IF l_count_prof > 0';
                OPEN o_selection_list FOR
                    SELECT DISTINCT t.flg_type, t.desc_val
                      FROM (SELECT s.flg_type,
                                   pk_sysdomain.get_domain(l_type, s.flg_type, i_lang) desc_val,
                                   pk_translation.get_translation(i_lang, s.code_supply) desc_trans
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies)
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND ssi.id_professional = i_prof.id
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND rownum > 0) t
                     WHERE t.desc_trans IS NOT NULL
                     ORDER BY desc_val;
            ELSIF (l_count_dept > 0 AND l_count_prof = 0)
            THEN
            
                g_error := 'OPEN o_selection_list ---  ELSIF (l_count_dept > 0 AND l_count_prof = 0)';
                OPEN o_selection_list FOR
                    SELECT DISTINCT t.flg_type, t.desc_val
                      FROM (SELECT s.flg_type,
                                   pk_sysdomain.get_domain(l_type, s.flg_type, i_lang) desc_val,
                                   pk_translation.get_translation(i_lang, s.code_supply) desc_trans
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies)
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND ssi.id_dept = l_dept
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND rownum > 0) t
                     WHERE t.desc_trans IS NOT NULL
                     ORDER BY desc_val;
            ELSIF (l_count_prof = 0 AND l_count_dept = 0)
            THEN
            
                g_error := 'OPEN o_selection_list ---  ELSIF (l_count_prof = 0 AND l_count_dept = 0)';
                OPEN o_selection_list FOR
                    SELECT DISTINCT t.flg_type, t.desc_val
                      FROM (SELECT s.flg_type,
                                   pk_sysdomain.get_domain(l_type, s.flg_type, i_lang) desc_val,
                                   pk_translation.get_translation(i_lang, s.code_supply) desc_trans
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies)
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND rownum > 0) t
                     WHERE t.desc_trans IS NOT NULL
                     ORDER BY desc_val;
            END IF;
        ELSE
            OPEN o_selection_list FOR
                SELECT DISTINCT t.flg_type, t.desc_val
                  FROM (SELECT s.flg_type,
                               pk_sysdomain.get_domain(l_type, s.flg_type, i_lang) desc_val,
                               pk_translation.get_translation(i_lang, s.code_supply) desc_trans
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON s.id_supply = ssi.id_supply
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies)
                         WHERE ssi.id_institution = i_id_inst_dest
                           AND ssi.id_software = pk_sr_planning.g_software_oris
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND rownum > 0) t
                 WHERE desc_trans IS NOT NULL
                 ORDER BY desc_val;
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
    
        l_count_supply_type_child NUMBER;
    
        l_id_supply_area supply_area.id_supply_area%TYPE := i_id_supply_area;
    
    BEGIN
    
        IF i_id_supply_area IS NULL
        THEN
            g_error := 'GET SUPPLY AREA';
            IF NOT pk_supplies_core.get_id_supply_area(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply      => i_id_supply,
                                                       i_flg_type       => i_flg_type,
                                                       o_id_supply_area => l_id_supply_area,
                                                       o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'i_lang:' || i_lang || ' i_prof.id:' || i_prof.id || ' i_prof.institution:' || i_prof.institution ||
                   ' i_prof.software:' || i_prof.software || ' i_id_supply_area:' || l_id_supply_area || ' i_episode:' ||
                   i_episode || ' i_consumption_type:' || i_consumption_type || ' i_flg_type:' || i_flg_type ||
                   '  i_id_supply:' || i_id_supply || ' i_id_supply_type:' || l_id_supply_area || ' i_id_inst_dest:' ||
                   i_id_inst_dest;
    
        OPEN o_supply_inf FOR
            SELECT NULL id_supply,
                   NULL desc_supply,
                   NULL id_supply_type,
                   NULL desc_supply_type,
                   NULL flg_type,
                   NULL quantity,
                   NULL id_unit_measure,
                   NULL desc_unit_measure,
                   NULL flg_reusable,
                   NULL desc_flg_reusable,
                   NULL flg_consumption_type,
                   NULL desc_consumption_type,
                   NULL desc_supply_attrib,
                   NULL nr_units_avail,
                   NULL id_supply_soft_inst,
                   NULL flg_editable,
                   NULL id_supply_location,
                   NULL desc_supply_location,
                   NULL precedence_level,
                   NULL nr_units_avail_desc,
                   NULL id_supply_area,
                   NULL desc_supply_kit
              FROM dual
             WHERE 2 = 1;
    
        OPEN o_supply_type FOR
            SELECT NULL id_supply_type, NULL desc_supply_type, NULL flg_child, NULL flg_type
              FROM dual
             WHERE 2 = 1;
    
        OPEN o_supply_items FOR
            SELECT NULL id_supply,
                   NULL desc_supply,
                   NULL id_supply_type,
                   NULL flg_type,
                   NULL quantity,
                   NULL id_unit_measure,
                   NULL desc_unit_measure,
                   NULL flg_reusable,
                   NULL desc_flg_reusable,
                   NULL flg_consumption_type,
                   NULL desc_consumption_type,
                   NULL desc_supply_attrib,
                   NULL id_supply_soft_inst,
                   NULL id_supply_location,
                   NULL desc_supply_location,
                   NULL id_supply_area
              FROM dual
             WHERE 2 = 1;
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_flg_type IS NOT NULL
        
        THEN
        
            IF i_flg_type IN (pk_supplies_constant.g_supply_type,
                              pk_supplies_constant.g_act_ther_supply,
                              pk_supplies_constant.g_supply_equipment_type,
                              pk_supplies_constant.g_supply_implant_type)
               AND i_id_supply_type IS NULL
            
            THEN
            
                g_error := '  IF NOT get_supply_type';
                IF NOT get_supply_type(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_supply_area   => l_id_supply_area,
                                       i_episode          => i_episode,
                                       i_consumption_type => i_consumption_type,
                                       i_flg_type         => i_flg_type,
                                       i_id_inst_dest     => i_id_inst_dest,
                                       o_supply_type      => o_supply_type,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                o_flg_selected := pk_alert_constant.g_no;
            
            ELSIF i_flg_type IN (pk_supplies_constant.g_supply_type,
                                 pk_supplies_constant.g_act_ther_supply,
                                 pk_supplies_constant.g_supply_equipment_type,
                                 pk_supplies_constant.g_supply_implant_type)
                  AND i_id_supply_type IS NOT NULL
            
            THEN
            
                g_error := '  IF NOT get_supply_child_type';
                IF NOT get_supply_child_type(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_supply_area   => l_id_supply_area,
                                             i_episode          => i_episode,
                                             i_consumption_type => i_consumption_type,
                                             i_flg_type         => i_flg_type,
                                             i_supply_type      => i_id_supply_type,
                                             i_id_inst_dest     => i_id_inst_dest,
                                             o_count_sun        => l_count_supply_type_child,
                                             o_supply_type      => o_supply_type,
                                             o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_count_supply_type_child = 0
                THEN
                    g_error := 'IF NOT get_supply_info';
                    IF NOT get_supply_info(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_supply_area   => l_id_supply_area,
                                           i_episode          => i_episode,
                                           i_consumption_type => i_consumption_type,
                                           i_flg_type         => i_flg_type,
                                           i_id_supply        => i_id_supply,
                                           i_id_supply_type   => i_id_supply_type,
                                           i_id_inst_dest     => i_id_inst_dest,
                                           o_supply           => o_supply_inf,
                                           o_error            => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    o_flg_selected := pk_supplies_constant.g_yes;
                
                ELSE
                    o_flg_selected := pk_alert_constant.g_no;
                END IF;
            END IF;
        
            IF i_flg_type IN (pk_supplies_constant.g_supply_kit_type, pk_supplies_constant.g_supply_set_type)
               AND i_id_supply IS NULL
            THEN
                g_error := 'IF NOT  get_supply_info';
                IF NOT get_supply_info(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_supply_area   => l_id_supply_area,
                                       i_episode          => i_episode,
                                       i_consumption_type => i_consumption_type,
                                       i_flg_type         => i_flg_type,
                                       i_id_supply        => i_id_supply,
                                       i_id_supply_type   => i_id_supply_type,
                                       i_id_inst_dest     => i_id_inst_dest,
                                       o_supply           => o_supply_inf,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                o_flg_selected := pk_alert_constant.g_no;
            
            ELSIF i_flg_type IN (pk_supplies_constant.g_supply_kit_type, pk_supplies_constant.g_supply_set_type)
                  AND i_id_supply IS NOT NULL
            THEN
                g_error := 'IF NOT  get_supply_item';
                IF NOT get_supply_item(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_supply_area   => l_id_supply_area,
                                       i_id_episode       => i_episode,
                                       i_consumption_type => i_consumption_type,
                                       i_supply           => i_id_supply,
                                       i_id_inst_dest     => i_id_inst_dest,
                                       o_supply_items     => o_supply_items,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                o_flg_selected := pk_supplies_constant.g_yes;
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
                                              'GET_SUPPLY_FOR_SELECTION',
                                              o_error);
            pk_types.open_my_cursor(o_supply_inf);
            pk_types.open_my_cursor(o_supply_type);
            pk_types.open_my_cursor(o_supply_items);
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
    
        l_count PLS_INTEGER;
        l_limit sys_config.value%TYPE;
    
        l_req_loan   sys_config.value%TYPE;
        l_cons_loan  sys_config.value%TYPE;
        l_req_local  sys_config.value%TYPE;
        l_cons_local sys_config.value%TYPE;
    
    BEGIN
    
        l_limit    := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        o_flg_show := pk_supplies_constant.g_no;
    
        g_error := 'DELETE TBL_TEMP';
        DELETE FROM tbl_temp;
    
        IF i_id_inst_dest IS NULL
        THEN
            l_req_loan   := pk_sysconfig.get_config('SUPPLIES_LOAN_REQ_AVILABLE', i_prof);
            l_cons_loan  := pk_sysconfig.get_config('SUPPLIES_LOAN_CONSUMPTION_AVILABLE', i_prof);
            l_req_local  := pk_sysconfig.get_config('SUPPLIES_LOCAL_REQ_AVILABLE', i_prof);
            l_cons_local := pk_sysconfig.get_config('SUPPLIES_LOCAL_CONSUMPTION_AVILABLE', i_prof);
        ELSE
            l_req_loan   := pk_sysconfig.get_config('SUPPLIES_LOAN_REQ_AVILABLE',
                                                    i_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
            l_cons_loan  := pk_sysconfig.get_config('SUPPLIES_LOAN_CONSUMPTION_AVILABLE',
                                                    i_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
            l_req_local  := pk_sysconfig.get_config('SUPPLIES_LOCAL_REQ_AVILABLE',
                                                    i_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
            l_cons_local := pk_sysconfig.get_config('SUPPLIES_LOCAL_CONSUMPTION_AVILABLE',
                                                    i_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
        END IF;
    
        g_error := 'INSERT TBL_TEMP NORMAL';
        INSERT INTO tbl_temp
            (num_1, vc_1, num_2, vc_2, num_3, num_4, vc_3, vc_4, vc_5, vc_6, num_5, vc_7, num_6, vc_8)
            SELECT DISTINCT t.id_supply,
                            t.desc_supply,
                            decode(t.flg_type,
                                   pk_supplies_constant.g_supply_kit_type,
                                   NULL,
                                   pk_supplies_constant.g_supply_set_type,
                                   NULL,
                                   t.id_supply_type) id_supply_type,
                            t.flg_type,
                            t.quantity quantity,
                            t.total_avail_quantity -
                            pk_supplies_core.get_nr_loaned_units(i_lang,
                                                                 i_prof,
                                                                 t.id_supply_area,
                                                                 t.id_supply,
                                                                 i_episode,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL) units_available,
                            t.flg_reusable,
                            t.flg_cons_type flg_consumption_type,
                            pk_sysdomain.get_domain(decode(t.id_supply_area,
                                                           pk_supplies_constant.g_area_surgical_supplies,
                                                           'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                           'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                                    t.flg_cons_type,
                                                    i_lang) desc_consumption_type,
                            pk_supplies_core.get_attributes(i_lang,
                                                            i_prof,
                                                            t.id_supply_area,
                                                            t.id_supply,
                                                            i_id_inst_dest) desc_supply_attrib,
                            t.id_supply_soft_inst,
                            t.flg_editable,
                            t.id_supply_location,
                            pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE', t.flg_cons_type, i_lang) || ' > ' ||
                            pk_sysdomain.get_domain(decode(t.id_supply_area,
                                                           pk_supplies_constant.g_area_surgical_supplies,
                                                           'SUPPLY.FLG_TYPE.SR',
                                                           'SUPPLY.FLG_TYPE'),
                                                    t.flg_type,
                                                    i_lang) ||
                            (SELECT sys_connect_by_path(pk_translation.get_translation(i_lang, st.code_supply_type),
                                                        ' > ')
                               FROM supply_type st
                               JOIN supply s_aux
                                 ON s_aux.id_supply_type = st.id_supply_type
                              START WITH s_aux.id_supply = t.id_supply
                             CONNECT BY PRIOR st.id_parent = st.id_supply_type) desc_path
              FROM (SELECT s.id_supply id_supply,
                           t.desc_translation desc_supply,
                           s.code_supply,
                           s.flg_type,
                           s.id_supply_type,
                           st.code_supply_type,
                           ssi.quantity,
                           ssi.id_unit_measure,
                           ssi.flg_reusable,
                           ssi.flg_cons_type,
                           ssa.id_supply_area,
                           ssi.total_avail_quantity,
                           ssi.id_supply_soft_inst,
                           ssi.flg_editable,
                           sl.id_supply_location,
                           sl.code_supply_location,
                           rank() over(PARTITION BY s.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC) rn
                      FROM supply s
                     INNER JOIN supply_soft_inst ssi
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                      LEFT JOIN supply_type st
                        ON st.id_supply_type = s.id_supply_type
                       AND st.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                      LEFT JOIN supply_loc_default sld
                        ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
                      JOIN supply_location sl
                        ON sld.id_supply_location = sl.id_supply_location
                       AND sld.flg_default = pk_supplies_constant.g_yes
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            *
                             FROM TABLE(pk_translation.get_search_translation(i_lang, i_value, 'SUPPLY.CODE_SUPPLY'))) t
                        ON t.code_translation = s.code_supply
                     WHERE s.flg_available = pk_supplies_constant.g_yes
                       AND ssi.id_institution = nvl(i_id_inst_dest, i_prof.institution)
                       AND ssi.id_software = nvl2(i_id_inst_dest, pk_sr_planning.g_software_oris, i_prof.software)
                       AND ssi.id_professional IN (i_prof.id, 0)
                       AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                           l_cons_loan = pk_supplies_constant.g_yes) OR
                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                           l_cons_local = pk_supplies_constant.g_yes) OR
                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                           (i_flg_consumption = pk_alert_constant.g_no AND
                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                           l_req_loan = pk_supplies_constant.g_yes) OR
                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                           l_req_local = pk_supplies_constant.g_yes) OR
                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                           (i_flg_consumption IS NULL AND
                           ssi.flg_cons_type IN
                           (pk_supplies_constant.g_consumption_type_loan,
                              pk_supplies_constant.g_consumption_type_local,
                              pk_supplies_constant.g_consumption_type_implant)))) t
             WHERE t.rn = 1;
    
        SELECT COUNT(0)
          INTO l_count
          FROM tbl_temp;
    
        IF l_count > l_limit
        THEN
            o_flg_show  := pk_supplies_constant.g_yes;
            o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_flg_has_action => pk_supplies_constant.g_yes);
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
        ELSIF l_count = 0
        THEN
            o_flg_show  := pk_supplies_constant.g_yes;
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M015');
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
        
            pk_types.open_cursor_if_closed(o_list);
            RETURN TRUE;
        END IF;
    
        g_error := 'OPEN O_SUPPLY';
        OPEN o_list FOR
            SELECT DISTINCT *
              FROM (SELECT num_1 id_supply,
                           vc_1  desc_supply,
                           num_2 id_supply_type,
                           vc_2  flg_type,
                           num_3 quantity,
                           num_4 units_available,
                           vc_3  flg_reusable,
                           vc_4  flg_consumption_type,
                           vc_5  desc_consumption_type,
                           vc_6  desc_supply_attrib,
                           num_5 id_supply_soft_inst,
                           vc_7  flg_editable,
                           num_6 id_supply_location,
                           vc_8  desc_path
                      FROM tbl_temp tmp
                     WHERE rownum <= l_limit)
             WHERE desc_supply IS NOT NULL
             ORDER BY 2;
    
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
        i_flg_status     IN table_varchar DEFAULT NULL,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_shortcut        sys_shortcut.id_sys_shortcut%TYPE := NULL;
        l_id_category     wf_status_config.id_category%TYPE;
        t_epis            table_number := table_number();
        l_loaned_msg      sys_message.desc_message%TYPE;
        l_with_return_msg sys_message.desc_message%TYPE;
        l_cancelled_desc  sys_message.desc_message%TYPE;
        l_msg_reusable    sys_message.desc_message%TYPE;
        l_msg_disposable  sys_message.desc_message%TYPE;
        l_flg_type        table_varchar;
        l_id_supply_area  supply_area.id_supply_area%TYPE := i_id_supply_area;
    
        l_filter_by_status VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
        l_id_epis_hhc  epis_hhc_req.id_epis_hhc%TYPE;
    
        l_cancel_cfg                      pk_translation.t_desc_translation;
        l_cancel_reason_out_of_stock      cancel_reason.id_cancel_reason%TYPE;
        l_cancel_reason_out_of_stock_desc sys_message.desc_message%TYPE;
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR i_id_hhc_req IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(i_id_hhc_req, pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => i_patient));
        
            IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_hhc_req   => l_i_id_hhc_req,
                                               o_flg_can_edit => l_flg_can_edit,
                                               o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF i_id_hhc_req IS NOT NULL
        THEN
        
            SELECT ehr.id_epis_hhc
              INTO l_id_epis_hhc
              FROM epis_hhc_req ehr
             WHERE ehr.id_epis_hhc_req = i_id_hhc_req;
        END IF;
    
        g_error := 'GET Message';
    
        l_loaned_msg := pk_message.get_message(i_lang      => i_lang,
                                               i_code_mess => pk_act_therap_constant.g_msg_loaned_units);
    
        l_with_return_msg := pk_message.get_message(i_lang      => i_lang,
                                                    i_code_mess => pk_act_therap_constant.g_msg_with_return);
    
        l_cancelled_desc := pk_message.get_message(i_lang      => i_lang,
                                                   i_code_mess => pk_act_therap_constant.g_msg_cancelled);
    
        l_msg_reusable := pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096');
    
        l_msg_disposable := pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095');
    
        l_cancel_cfg                      := pk_sysconfig.get_config(i_code_cf => 'PRESC_CANCEL_OUT_OF_STOCK',
                                                                     i_prof    => i_prof);
        l_cancel_reason_out_of_stock      := pk_cancel_reason.get_id_by_content(i_lang, i_prof, l_cancel_cfg);
        l_cancel_reason_out_of_stock_desc := pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                     i_prof,
                                                                                     l_cancel_reason_out_of_stock);
    
        IF i_flg_status IS NOT NULL
        THEN
            IF i_flg_status.count > 0
            THEN
                l_filter_by_status := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        g_error := 'get past episodes';
        IF l_id_supply_area IS NULL
        THEN
            g_error := 'GET SUPPLY AREA';
            IF NOT pk_supplies_core.get_id_supply_area(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply      => NULL,
                                                       i_flg_type       => i_flg_type(1),
                                                       o_id_supply_area => l_id_supply_area,
                                                       o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF l_id_supply_area IN (pk_supplies_constant.g_area_surgical_supplies,
                                pk_supplies_constant.g_area_activity_therapy,
                                pk_supplies_constant.g_area_supplies) -- if surgical supplies or Activity Therapist supplies
        THEN
            t_epis.extend();
            t_epis(t_epis.count) := i_episode;
            IF l_id_epis_hhc IS NOT NULL
            THEN
                t_epis.extend();
                t_epis(t_epis.count) := l_id_epis_hhc;
            END IF;
        ELSE
            IF i_episode IS NOT NULL
            THEN
                t_epis.extend();
                t_epis(t_epis.count) := i_episode;
                IF l_id_epis_hhc IS NOT NULL
                THEN
                    t_epis.extend();
                    t_epis(t_epis.count) := l_id_epis_hhc;
                END IF;
            ELSE
                SELECT e.id_episode
                  BULK COLLECT
                  INTO t_epis
                  FROM episode e
                 WHERE e.id_patient = i_patient
                   AND e.flg_status = pk_alert_constant.g_active;
            END IF;
        
        END IF;
    
        g_error       := 'get the prof category';
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        IF (l_id_category = pk_supplies_constant.g_ancillary OR i_prof.software = pk_alert_constant.g_soft_labtech)
        THEN
            l_flg_type := table_varchar(pk_supplies_constant.g_supply_kit_type,
                                        pk_supplies_constant.g_supply_set_type,
                                        pk_supplies_constant.g_supply_type,
                                        pk_supplies_constant.g_supply_equipment_type,
                                        pk_supplies_constant.g_supply_implant_type);
        ELSE
            l_flg_type := i_flg_type;
        END IF;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT tb.*,
                   decode(int_notes, '---', '', int_notes) notes,
                   (SELECT REPLACE(REPLACE(l_loaned_msg, pk_act_therap_constant.g_1st_replace, tb.quantity),
                                   pk_act_therap_constant.g_2nd_replace,
                                   tb.conf_quantity)
                      FROM dual) AS nr_units,
                   CASE
                        WHEN l_flg_can_edit = pk_alert_constant.g_no THEN
                         pk_alert_constant.g_no
                        ELSE
                         (SELECT check_supply_wf_cancel(i_lang,
                                                        i_prof,
                                                        l_id_supply_area,
                                                        tb.status,
                                                        tb.quantity,
                                                        tb.total_quantity)
                            FROM dual)
                    END flg_cancelable,
                   tb.total_quantity loaned_total_qty,
                   (SELECT get_delivered_units(i_lang, i_prof, tb.id_supply_workflow, tb.id_sup_workflow_parent)
                      FROM dual) delivered_total_qty,
                   CASE
                        WHEN tb.status IN
                             (pk_supplies_constant.g_sww_cancelled, pk_supplies_constant.g_sww_deliver_cancelled) THEN
                         decode(tb.id_cancel_reason,
                                l_cancel_reason_out_of_stock,
                                l_cancel_reason_out_of_stock_desc,
                                l_cancelled_desc)
                        WHEN tb.status = pk_supplies_constant.g_sww_loaned THEN
                         decode(tb.quantity, tb.total_quantity, '', l_with_return_msg)
                    END supply_status_desc,
                   id_episode,
                   signature
              FROM (SELECT sw.id_supply_workflow,
                           wsc.rank,
                           decode(sw.id_cancel_reason,
                                  l_cancel_reason_out_of_stock,
                                  pk_supplies_constant.g_sww_no_stock,
                                  sw.flg_status) status,
                           CASE
                                WHEN sw.flg_status = pk_supplies_constant.g_sww_deliver_needed
                                     AND sw.id_supply_location = pk_supplies_constant.g_pharmacy_location THEN --Deliver to pharmacy   
                                 (SELECT pk_message.get_message(i_lang, 'SUPPLIES_M002')
                                    FROM dual)
                                ELSE
                                 (SELECT pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_STATUS',
                                                                 decode(sw.id_cancel_reason,
                                                                        l_cancel_reason_out_of_stock,
                                                                        pk_supplies_constant.g_sww_no_stock,
                                                                        sw.flg_status),
                                                                 i_lang)
                                    FROM dual)
                            END desc_status,
                           s.id_supply id_supply,
                           nvl(sw.flg_context, pk_supplies_constant.g_context_supplies) flg_context,
                           (SELECT pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_CONTEXT',
                                                           nvl(sw.flg_context, pk_supplies_constant.g_context_supplies),
                                                           i_lang)
                              FROM dual) desc_context,
                           (SELECT pk_translation.get_translation(i_lang, s.code_supply)
                              FROM dual) ||
                           decode(sw.id_supply_set,
                                  NULL,
                                  NULL,
                                  ' (' || (SELECT pk_translation.get_translation(i_lang, sp.code_supply)
                                             FROM supply sp
                                            WHERE id_supply = sw.id_supply_set) || ')') desc_supply,
                           CASE
                                WHEN sw.flg_status IN (pk_supplies_constant.g_sww_transport_concluded,
                                                       pk_supplies_constant.g_sww_request_local) THEN
                                 pk_supplies_core.get_supply_available_quantity(i_lang               => i_lang,
                                                                                i_prof               => i_prof,
                                                                                i_id_supply_workflow => sw.id_supply_workflow)
                                ELSE
                                 nvl(sw.quantity, 1)
                            END quantity,
                           sw.flg_reusable,
                           decode(sw.flg_reusable, pk_supplies_constant.g_yes, l_msg_reusable, l_msg_disposable) desc_reusable,
                           sw.flg_cons_type,
                           (SELECT pk_sysdomain.get_domain(decode(sw.id_supply_area,
                                                                  pk_supplies_constant.g_area_surgical_supplies,
                                                                  'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                                  'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                                           sw.flg_cons_type,
                                                           i_lang)
                              FROM dual) desc_cons_type,
                           sw.id_supply_location,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, sw.dt_request, i_prof)
                              FROM dual) dt_request,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof)
                              FROM dual) dt_returned,
                           (SELECT pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                         sw.dt_returned,
                                                                         i_prof.institution,
                                                                         i_prof.software)
                              FROM dual) date_returned,
                           (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    sw.dt_returned,
                                                                    i_prof.institution,
                                                                    i_prof.software)
                              FROM dual) hour_returned,
                           (SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                      sw.dt_returned,
                                                                      i_prof.institution,
                                                                      i_prof.software)
                              FROM dual) dt_hr_returned,
                           sw.id_req_reason,
                           (SELECT pk_translation.get_translation(i_lang, sre.code_supply_reason)
                              FROM supply_reason sre
                             WHERE sre.id_supply_reason = sw.id_req_reason) desc_reason,
                           (SELECT get_supply_workflow_col_value(i_lang,
                                                                 i_prof,
                                                                 sw.id_supply_workflow,
                                                                 'SUPPLIES_T109',
                                                                 'SUPPLY_WORKFLOW')
                              FROM dual) int_notes,
                           sr.id_room_req id_room_req,
                           (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                              FROM room r
                             WHERE r.id_room = sr.id_room_req) room,
                           (SELECT pk_translation.get_translation(i_lang, d.code_department)
                              FROM department d, room r
                             WHERE d.id_department = r.id_department
                               AND r.id_room = sr.id_room_req) service,
                           (SELECT pk_translation.get_translation(i_lang, dt.code_dept)
                              FROM department d, room r, dept dt
                             WHERE d.id_department = r.id_department
                               AND r.id_room = sr.id_room_req
                               AND d.id_dept = dt.id_dept) department,
                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)
                              FROM dual) prof_req,
                           (SELECT pk_translation.get_translation(i_lang, sl.code_supply_location)
                              FROM supply_location sl
                             WHERE sw.id_supply_location = sl.id_supply_location) desc_location,
                           (SELECT pk_supplies_core.get_attributes(i_lang,
                                                                   i_prof,
                                                                   sw.id_supply_area,
                                                                   s.id_supply,
                                                                   sw.id_supply_location,
                                                                   NULL,
                                                                   sw.id_supply_workflow)
                              FROM dual) desc_supply_attrib,
                           (SELECT get_supply_wf_status_string(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_flg_status         => decode(sw.id_cancel_reason,
                                                                                              l_cancel_reason_out_of_stock,
                                                                                              pk_supplies_constant.g_sww_no_stock,
                                                                                              sw.flg_status),
                                                               i_id_sys_shortcut    => l_shortcut,
                                                               i_id_workflow        => wsc.id_workflow,
                                                               i_id_supply_area     => sw.id_supply_area,
                                                               i_id_category        => l_id_category,
                                                               i_dt_returned        => sw.dt_returned,
                                                               i_dt_request         => sw.dt_request,
                                                               i_dt_supply_workflow => sw.dt_supply_workflow,
                                                               i_id_episode         => sw.id_episode,
                                                               i_supply_workflow    => sw.id_supply_workflow)
                              FROM dual) status_string,
                           (SELECT pk_translation.get_translation(i_lang, st.code_supply_type)
                              FROM dual) desc_supply_type,
                           pk_translation.get_translation(i_lang, st.code_supply_type) grid_desc_supply_type,
                           st.id_supply_type,
                           sw.total_quantity,
                           (SELECT sw.total_avail_quantity - get_nr_loaned_units(i_lang,
                                                                                 i_prof,
                                                                                 sw.id_supply_area,
                                                                                 s.id_supply,
                                                                                 sw.id_episode,
                                                                                 NULL,
                                                                                 NULL,
                                                                                 NULL)
                              FROM dual) nr_units_avail,
                           sw.id_sup_workflow_parent,
                           sw.total_avail_quantity AS conf_quantity,
                           sw.barcode_scanned,
                           sw.asset_number,
                           sw.cod_table desc_table,
                           sw.flg_preparing,
                           sw.id_supply_request,
                           sw.id_supply_area,
                           decode(ipd.id_interv_presc_det,
                                  NULL,
                                  '',
                                  pk_procedures_api_db.get_alias_translation(i_lang,
                                                                             i_prof,
                                                                             'INTERVENTION.CODE_INTERVENTION.' ||
                                                                             ipd.id_intervention,
                                                                             NULL)) procedures,
                           CASE
                                WHEN (SELECT COUNT(*)
                                        FROM supply_workflow_hist ht
                                       WHERE ht.id_supply_workflow = sw.id_supply_workflow) = 0
                                     OR nvl((SELECT decode(ht.flg_status, sw.flg_status, 0)
                                              FROM supply_workflow_hist ht
                                             WHERE ht.id_supply_workflow = sw.id_supply_workflow
                                               AND ht.id_supply_workflow_hist =
                                                   (SELECT MAX(id_supply_workflow_hist)
                                                      FROM supply_workflow_hist
                                                     WHERE id_supply_workflow = sw.id_supply_workflow)),
                                            0) = 0 THEN
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                 pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                                           i_prof,
                                                                                           sw.id_professional,
                                                                                           sw.dt_supply_workflow,
                                                                                           sw.id_episode),
                                                          ' (@)')
                            END prof_last_upd,
                           CASE
                                WHEN (SELECT COUNT(*)
                                        FROM supply_workflow_hist ht
                                       WHERE ht.id_supply_workflow = sw.id_supply_workflow) = 0
                                     OR nvl((SELECT decode(ht.flg_status, sw.flg_status, 0)
                                              FROM supply_workflow_hist ht
                                             WHERE ht.id_supply_workflow = sw.id_supply_workflow
                                               AND ht.id_supply_workflow_hist =
                                                   (SELECT MAX(id_supply_workflow_hist)
                                                      FROM supply_workflow_hist
                                                     WHERE id_supply_workflow = sw.id_supply_workflow)),
                                            0) = 0 THEN
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                 pk_string_utils.surround(pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                             sw.dt_supply_workflow,
                                                                                             i_prof),
                                                          ' (@)')
                            END dt_last_upd,
                           decode(sw.flg_status,
                                  pk_supplies_constant.g_sww_deliver_institution,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                  pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                                            i_prof,
                                                                                            sw.id_professional,
                                                                                            sw.dt_supply_workflow,
                                                                                            sw.id_episode),
                                                           ' (@)')) prof_returned,
                           s.flg_type,
                           pk_sysdomain.get_domain(i_code_dom => 'SUPPLY.FLG_TYPE.SR',
                                                   i_val      => s.flg_type,
                                                   i_lang     => i_lang) desc_flg_type,
                           decode(s.flg_type,
                                  pk_supplies_constant.g_supply_set_type,
                                  1,
                                  pk_supplies_constant.g_supply_kit_type,
                                  2,
                                  pk_supplies_constant.g_supply_equipment_type,
                                  3,
                                  pk_supplies_constant.g_supply_implant_type,
                                  4,
                                  5) flg_type_rank,
                           sw.id_episode id_episode,
                           pk_prof_utils.get_detail_signature(i_lang,
                                                              i_prof,
                                                              sw.id_episode,
                                                              sw.dt_supply_workflow,
                                                              sw.id_professional) signature,
                           sw.id_cancel_reason
                      FROM supply_workflow sw
                      JOIN supply s
                        ON sw.id_supply = s.id_supply
                      LEFT JOIN supply_location sl
                        ON sl.id_supply_location = sw.id_supply_location
                      LEFT JOIN (SELECT *
                                  FROM supply_request sr
                                 WHERE sr.flg_status != pk_supplies_constant.g_srt_draft) sr
                        ON sw.id_supply_request = sr.id_supply_request
                      JOIN wf_status_config wsc
                        ON wsc.id_status = (SELECT pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status)
                                              FROM dual)
                       AND wsc.id_workflow = decode(sw.id_supply_area,
                                                    pk_supplies_constant.g_area_activity_therapy,
                                                    pk_supplies_constant.g_id_workflow_at,
                                                    pk_supplies_constant.g_area_surgical_supplies,
                                                    pk_supplies_constant.g_id_workflow_sr,
                                                    pk_supplies_constant.g_id_workflow)
                      JOIN supply_type st
                        ON st.id_supply_type = s.id_supply_type
                      LEFT JOIN interv_presc_det ipd
                        ON (ipd.id_interv_presc_det = sr.id_context AND sr.flg_context = 'P')
                     WHERE sw.flg_status NOT IN
                           (pk_supplies_constant.g_sww_predefined, pk_supplies_constant.g_sww_updated)
                       AND wsc.id_category = l_id_category
                       AND (sw.id_supply_set IS NULL OR
                           (sw.id_supply_set IS NOT NULL AND
                           sw.flg_context IN
                           (pk_supplies_constant.g_context_medication, pk_supplies_constant.g_context_pharm_dispense)))
                       AND (sw.id_supply_area = l_id_supply_area OR l_id_supply_area IS NULL)
                       AND (sw.flg_status IN (SELECT t1.column_value
                                                FROM TABLE(i_flg_status) t1) OR
                           l_filter_by_status = pk_alert_constant.g_no)
                       AND EXISTS
                     (SELECT 0
                              FROM supplies_wf_status sws
                             WHERE sws.flg_status = sw.flg_status
                               AND sws.id_category = l_id_category)
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND s.flg_type IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                           t1.column_value
                                            FROM TABLE(l_flg_type) t1)
                       AND sw.id_episode IN (SELECT /*+opt_estimate(table t2 rows=1)*/
                                              t2.column_value
                                               FROM TABLE(t_epis) t2
                                             UNION
                                             SELECT i_episode
                                               FROM dual)
                     ORDER BY flg_type_rank,
                              wsc.rank,
                              decode(sw.flg_status,
                                     pk_supplies_constant.g_sww_consumed,
                                     lower(desc_supply),
                                     to_char(sw.dt_request, 'YYYY-MM-DD HH24:MI')),
                              lower(desc_supply)) tb;
    
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
            pk_types.open_cursor_if_closed(o_list);
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
    
        l_table_surg_supplies table_varchar := table_varchar('SR_SUPPLIES_M039', 'SR_SUPPLIES_M040');
    
        l_table_req table_info := table_info(info(1, 'SUPPLIES_T101', NULL),
                                             info(2, 'SUPPLIES_T105', NULL),
                                             info(3, 'SUPPLIES_T106', NULL),
                                             info(4, 'SUPPLIES_T102', NULL),
                                             --info(5, 'SUPPLIES_T100'),
                                             info(5, 'SUPPLIES_T107', NULL),
                                             info(7, 'SR_SUPPLIES_M039', NULL),
                                             info(6, 'SUPPLIES_T109', NULL),
                                             info(8, 'SUPPLIES_T108', NULL));
    
        l_table_canceled table_info := table_info(info(1, 'SUPPLIES_T113', NULL),
                                                  info(2, 'SUPPLIES_T110', NULL),
                                                  info(3, 'SUPPLIES_T111', NULL),
                                                  info(4, 'SUPPLIES_T112', NULL),
                                                  info(5, 'SR_SUPPLIES_M039', NULL));
    
        l_table_rejected table_info := table_info(info(1, 'SUPPLIES_T114', NULL),
                                                  info(2, 'SUPPLIES_T115', NULL),
                                                  info(3, 'SUPPLIES_T116', NULL),
                                                  info(4, 'SR_SUPPLIES_M039', NULL));
    
        l_table_consumed table_info := table_info(info(1, 'SUPPLIES_T101', NULL),
                                                  info(2, 'SUPPLIES_T105', NULL),
                                                  info(3, 'SR_SUPPLIES_M047', NULL),
                                                  info(4, 'SR_SUPPLIES_M048', NULL),
                                                  info(5, 'SUPPLIES_T104', NULL),
                                                  --info(4,'SUPPLIES_T100'),
                                                  info(6, 'SR_SUPPLIES_M039', NULL),
                                                  info(7, 'SR_SUPPLIES_M040', NULL),
                                                  info(8, 'SUPPLIES_T109', NULL),
                                                  info(9, 'SUPPLIES_T132', NULL),
                                                  info(10, 'SUPPLIES_T129', NULL));
    
        l_table_others table_info := table_info(info(1, 'SUPPLIES_T101', NULL),
                                                info(2, 'SUPPLIES_T105', NULL),
                                                info(3, 'SUPPLIES_T104', NULL),
                                                --info(4,'SUPPLIES_T100'),
                                                info(4, 'SUPPLIES_T125', NULL),
                                                info(5, 'SUPPLIES_T107', NULL),
                                                info(6, 'SR_SUPPLIES_M039', NULL),
                                                info(7, 'SUPPLIES_T109', NULL),
                                                info(8, 'SUPPLIES_T132', NULL),
                                                info(9, 'SUPPLIES_T129', NULL));
    
        l_id_consumption_parent supply_workflow.id_consumption_parent%TYPE;
        l_id_dispense_parent    supply_workflow.id_dispense_parent%TYPE;
    
        l_cancel_cfg                 pk_translation.t_desc_translation;
        l_cancel_reason_out_of_stock cancel_reason.id_cancel_reason%TYPE;
    
    BEGIN
        g_error := 'GET id_consumption_parent';
        SELECT sw.id_consumption_parent, sw.id_dispense_parent
          INTO l_id_consumption_parent, l_id_dispense_parent
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_sup_wf;
    
        l_cancel_cfg                 := pk_sysconfig.get_config(i_code_cf => 'PRESC_CANCEL_OUT_OF_STOCK',
                                                                i_prof    => i_prof);
        l_cancel_reason_out_of_stock := pk_cancel_reason.get_id_by_content(i_lang, i_prof, l_cancel_cfg);
    
        g_error := 'OPEN o_register CURSOR';
        OPEN o_register FOR
        -- status actual
            SELECT t.*, pk_string_utils.surround(t.spec_report, pk_string_utils.g_pattern_parenthesis) speciality
              FROM (SELECT 10 rank,
                           decode(sw.flg_status,
                                  pk_supplies_constant.g_sww_all_consumed,
                                  pk_supplies_constant.g_sww_transport_concluded,
                                  pk_supplies_constant.g_sww_request_local,
                                  decode((SELECT COUNT(1)
                                           FROM supply_workflow w
                                          WHERE w.id_consumption_parent = sw.id_supply_workflow),
                                         0,
                                         sw.flg_status,
                                         pk_supplies_constant.g_sww_transport_concluded),
                                  sw.flg_status) param_val,
                           sw.id_supply_workflow param_id,
                           pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_STATUS',
                                                    decode(sw.flg_status,
                                                           pk_supplies_constant.g_sww_all_consumed,
                                                           pk_supplies_constant.g_sww_transport_concluded,
                                                           decode(sw.id_cancel_reason,
                                                                  l_cancel_reason_out_of_stock,
                                                                  pk_supplies_constant.g_sww_no_stock,
                                                                  sw.flg_status)),
                                                    i_lang) || CASE --Show the tag (updated) for partial dispenses
                                WHEN sw.flg_status = pk_supplies_constant.g_sww_request_central
                                     AND (sw.update_time IS NOT NULL OR sw.id_dispense_parent IS NOT NULL) THEN
                                 pk_message.get_message(i_lang, 'COMMON_M153')
                            END param_title,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(sw.dt_supply_workflow, sw.dt_request), i_prof) tstamp,
                           pk_date_utils.date_send_tsz(i_lang, nvl(sw.dt_supply_workflow, sw.dt_request), i_prof) timestamp_order,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) professional,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            sw.id_professional,
                                                            sw.dt_request,
                                                            sw.id_episode) spec_report
                      FROM supply_workflow sw
                     WHERE (sw.id_supply_workflow = i_id_sup_wf OR
                           (sw.id_supply_workflow =
                           (SELECT swp.id_consumption_parent
                                FROM supply_workflow swp
                               WHERE swp.id_supply_workflow = i_id_sup_wf) AND
                           sw.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled)) OR
                           --Partial dispenses
                           sw.id_supply_workflow =
                           (SELECT swp.id_dispense_parent
                               FROM supply_workflow swp
                              WHERE swp.id_supply_workflow = i_id_sup_wf))
                       AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_predefined)
                    UNION
                    -- status from the past (that came to haunt us buhahaha)
                    SELECT 100 rank,
                           decode(swh.flg_status,
                                  pk_supplies_constant.g_sww_all_consumed,
                                  pk_supplies_constant.g_sww_transport_concluded,
                                  swh.flg_status) flg_status,
                           swh.id_supply_workflow_hist,
                           pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_STATUS',
                                                   decode(swh.flg_status,
                                                          pk_supplies_constant.g_sww_all_consumed,
                                                          pk_supplies_constant.g_sww_transport_concluded,
                                                          decode(swh.id_cancel_reason,
                                                                 l_cancel_reason_out_of_stock,
                                                                 pk_supplies_constant.g_sww_no_stock,
                                                                 swh.flg_status)),
                                                   i_lang) || CASE --Show the tag (updated) for partial dispenses
                               WHEN swh.flg_status = pk_supplies_constant.g_sww_request_central
                                    AND swh.rn_update > 1 THEN
                                pk_message.get_message(i_lang, 'COMMON_M153')
                           END param_title,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, swh.create_time, i_prof) tstamp,
                           pk_date_utils.date_send_tsz(i_lang, swh.create_time, i_prof) timestamp_order,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, swh.id_professional) professional,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            swh.id_professional,
                                                            swh.dt_request,
                                                            swh.id_episode) spec_report
                      FROM (SELECT flg_status,
                                   id_supply_workflow_hist,
                                   id_professional,
                                   dt_request,
                                   id_episode,
                                   CASE
                                        WHEN rn = 1 THEN
                                         orig_create_time
                                        ELSE
                                         lag(create_time, 1) over(ORDER BY id_supply_workflow_hist ASC)
                                    END AS create_time,
                                   id_cancel_reason,
                                   rn_update
                              FROM (SELECT h.*,
                                           s.create_time AS orig_create_time,
                                           row_number() over(PARTITION BY h.id_supply_workflow ORDER BY h.id_supply_workflow_hist ASC) AS rn,
                                           row_number() over(PARTITION BY h.id_supply_workflow, h.flg_status ORDER BY h.id_supply_workflow_hist ASC) AS rn_update
                                      FROM supply_workflow_hist h
                                      JOIN supply_workflow s
                                        ON s.id_supply_workflow = h.id_supply_workflow
                                     WHERE ((h.id_supply_workflow = i_id_sup_wf OR
                                           h.id_supply_workflow =
                                           (SELECT DISTINCT swp.id_consumption_parent
                                                FROM supply_workflow_hist swp
                                               WHERE swp.id_supply_workflow = i_id_sup_wf) OR
                                           --Partial dispenses
                                           h.id_supply_workflow =
                                           (SELECT swp.id_dispense_parent
                                                FROM supply_workflow swp
                                               WHERE swp.id_supply_workflow = i_id_sup_wf)) AND
                                           h.flg_status != pk_supplies_constant.g_sww_predefined)
                                          --When only part of the supplies have been consumed, it is necessary
                                          --to check the history of the original request
                                        OR (((h.id_supply_workflow = l_id_consumption_parent OR
                                           (h.id_supply_workflow =
                                           (SELECT DISTINCT swp.id_consumption_parent
                                                  FROM supply_workflow_hist swp
                                                 WHERE swp.id_supply_workflow = l_id_consumption_parent) AND
                                           h.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled))) OR
                                           --Partial dispense
                                           (h.id_supply_workflow = l_id_dispense_parent OR
                                           (h.id_supply_workflow =
                                           (SELECT DISTINCT swp.id_dispense_parent
                                                  FROM supply_workflow_hist swp
                                                 WHERE swp.id_supply_workflow = l_id_dispense_parent) AND
                                           h.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled)))) AND
                                           h.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                                             pk_supplies_constant.g_sww_request_central,
                                                             pk_supplies_constant.g_sww_request_wait))
                                     ORDER BY h.id_supply_workflow_hist DESC)
                             ORDER BY id_supply_workflow_hist DESC) swh
                     ORDER BY rank, timestamp_order DESC) t;
    
        -- open individual cursors
        -- cursor for initial status. Can be Requested to Central Stock or requested to Local Stock*.        
        g_error := 'OPEN o_req CURSOR';
        OPEN o_req FOR
        -- might be hiding in the history...
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow_hist param_id,
                   sm.desc_message label,
                   sm.code_message code,
                   pk_date_utils.date_send_tsz(i_lang, swh.create_time, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow_hist,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW_HIST') VALUE,
                   100 rank,
                   t.id rank_value
              FROM supply_workflow_hist swh, TABLE(l_table_req) t, sys_message sm, supply s
             WHERE swh.id_supply_workflow = coalesce(l_id_dispense_parent, l_id_consumption_parent, i_id_sup_wf)
               AND swh.id_supply = s.id_supply
               AND swh.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                      pk_supplies_constant.g_sww_request_central,
                                      pk_supplies_constant.g_sww_request_wait)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
            UNION
            -- ...or not
            SELECT sw.flg_status param_val,
                   sw.id_supply_workflow,
                   sm.desc_message,
                   sm.code_message,
                   pk_date_utils.date_send_tsz(i_lang,
                                               nvl(sw.update_time, sw.create_time) /*sw.dt_supply_workflow*/,
                                               i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 sw.id_supply_workflow,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW') VALUE,
                   10 rank,
                   t.id rank_value
              FROM supply_workflow sw, TABLE(l_table_req) t, sys_message sm, supply s
             WHERE sw.id_supply_workflow = coalesce(l_id_dispense_parent, l_id_consumption_parent, i_id_sup_wf)
               AND s.id_supply = sw.id_supply
               AND sw.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                     pk_supplies_constant.g_sww_request_central,
                                     pk_supplies_constant.g_sww_request_wait)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (sw.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
             ORDER BY rank ASC, timestamp_order ASC, param_id DESC, rank_value ASC;
    
        -- cursor for Cancelled status. n rows
        g_error := 'OPEN o_canceled CURSOR';
        OPEN o_canceled FOR
        -- might be hiding in the history
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow_hist param_id,
                   sm.desc_message label,
                   sm.code_message code,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow_hist,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW_HIST') VALUE,
                   100 rank,
                   t.id rank_value
              FROM supply_workflow_hist swh, TABLE(l_table_canceled) t, sys_message sm, supply s
             WHERE swh.id_supply_workflow = i_id_sup_wf
               AND s.id_supply = swh.id_supply
               AND swh.flg_status = pk_supplies_constant.g_sww_cancelled
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
            UNION
            -- ... or not
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow,
                   sm.desc_message,
                   sm.code_message,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW'),
                   10 rank,
                   t.id rank_value
              FROM supply_workflow swh, TABLE(l_table_canceled) t, sys_message sm, supply s
             WHERE swh.id_supply_workflow = i_id_sup_wf
               AND s.id_supply = swh.id_supply
               AND swh.flg_status = pk_supplies_constant.g_sww_cancelled
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
             ORDER BY rank, timestamp_order, rank_value;
    
        -- cursor for Rejected status. n rows
        g_error := 'OPEN o_rejected CURSOR';
        OPEN o_rejected FOR
        -- might be hiding in the history
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow_hist param_id,
                   sm.desc_message label,
                   sm.code_message code,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow_hist,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW_HIST') VALUE,
                   100 rank,
                   t.id rank_value
              FROM supply_workflow_hist swh, TABLE(l_table_rejected) t, sys_message sm, supply s
             WHERE swh.id_supply_workflow = i_id_sup_wf
               AND swh.id_supply = s.id_supply
               AND swh.flg_status IN
                   (pk_supplies_constant.g_sww_rejected_pharmacist, pk_supplies_constant.g_sww_rejected_technician)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
            UNION
            --... or not
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow,
                   sm.desc_message,
                   sm.code_message,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW'),
                   10 rank,
                   t.id rank_value
              FROM supply_workflow swh, TABLE(l_table_rejected) t, sys_message sm, supply s
             WHERE swh.id_supply_workflow = i_id_sup_wf
               AND swh.id_supply = s.id_supply
               AND swh.flg_status IN
                   (pk_supplies_constant.g_sww_rejected_pharmacist, pk_supplies_constant.g_sww_rejected_technician)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
             ORDER BY rank, timestamp_order, rank_value;
    
        -- cursor for Consumed status. n rows
        g_error := 'OPEN o_consumed CURSOR';
        OPEN o_consumed FOR
        -- might be hiding in the history
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow_hist param_id,
                   sm.desc_message label,
                   sm.code_message code,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow_hist,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW_HIST') VALUE,
                   100 rank,
                   t.id rank_value,
                   ssc.qty_added,
                   ssc.qty_final_count
              FROM supply_workflow_hist swh,
                   TABLE(l_table_consumed) t,
                   sys_message sm,
                   supply s,
                   sr_supply_relation ssr,
                   sr_supply_count ssc
             WHERE swh.id_supply_workflow = i_id_sup_wf
               AND s.id_supply = swh.id_supply
               AND swh.flg_status IN (pk_supplies_constant.g_sww_loaned,
                                      pk_supplies_constant.g_sww_consumed,
                                      pk_supplies_constant.g_sww_consumed_delivery_needed,
                                      pk_supplies_constant.g_sww_cons_and_count,
                                      pk_supplies_constant.g_sww_prep_sup_for_surg)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
               AND swh.id_supply_workflow = ssr.id_supply_workflow(+)
               AND ssr.id_sr_supply_count = ssc.id_sr_supply_count(+)
            UNION
            --... or not
            SELECT swh.flg_status param_val,
                   swh.id_supply_workflow,
                   sm.desc_message,
                   sm.code_message,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW'),
                   10 rank,
                   t.id rank_value,
                   ssc.qty_added,
                   ssc.qty_final_count
              FROM supply_workflow swh,
                   TABLE(l_table_consumed) t,
                   sys_message sm,
                   supply s,
                   sr_supply_relation ssr,
                   sr_supply_count ssc
             WHERE swh.id_supply_workflow = i_id_sup_wf
               AND s.id_supply = swh.id_supply
               AND swh.flg_status IN (pk_supplies_constant.g_sww_loaned,
                                      pk_supplies_constant.g_sww_consumed,
                                      pk_supplies_constant.g_sww_consumed_delivery_needed,
                                      pk_supplies_constant.g_sww_cons_and_count,
                                      pk_supplies_constant.g_sww_prep_sup_for_surg)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
               AND swh.id_supply_workflow = ssr.id_supply_workflow(+)
               AND ssr.id_sr_supply_count = ssc.id_sr_supply_count(+)
             ORDER BY rank, timestamp_order, rank_value;
    
        -- cursor for other status. n rows
        g_error := 'OPEN o_others CURSOR';
        OPEN o_others FOR
        -- might be hiding in the history
            SELECT decode(swh.flg_status,
                          pk_supplies_constant.g_sww_all_consumed,
                          pk_supplies_constant.g_sww_transport_concluded,
                          swh.flg_status) param_val,
                   swh.id_supply_workflow_hist param_id,
                   sm.desc_message label,
                   sm.code_message code,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow_hist,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW_HIST') VALUE,
                   100 rank,
                   t.id rank_value
              FROM (SELECT flg_status,
                           id_supply_workflow_hist,
                           dt_supply_workflow,
                           id_supply,
                           id_supply_area,
                           id_cancel_reason
                      FROM supply_workflow_hist
                     WHERE id_supply_workflow = i_id_sup_wf
                    UNION
                    SELECT flg_status,
                           id_supply_workflow_hist,
                           dt_supply_workflow,
                           id_supply,
                           id_supply_area,
                           id_cancel_reason
                      FROM supply_workflow_hist
                     WHERE id_supply_workflow = (SELECT DISTINCT id_consumption_parent
                                                   FROM supply_workflow_hist
                                                  WHERE id_supply_workflow = i_id_sup_wf)
                        OR
                          --Partial dispense
                           id_supply_workflow = (SELECT DISTINCT id_dispense_parent
                                                   FROM supply_workflow_hist
                                                  WHERE id_supply_workflow = i_id_sup_wf)) swh,
                   TABLE(l_table_others) t,
                   sys_message sm,
                   supply s
             WHERE s.id_supply = swh.id_supply
               AND swh.flg_status NOT IN (pk_supplies_constant.g_sww_rejected_pharmacist,
                                          pk_supplies_constant.g_sww_rejected_technician,
                                          pk_supplies_constant.g_sww_cancelled,
                                          pk_supplies_constant.g_sww_request_local,
                                          pk_supplies_constant.g_sww_request_central,
                                          pk_supplies_constant.g_sww_request_wait,
                                          pk_supplies_constant.g_sww_predefined)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
            UNION
            -- ...or not
            SELECT decode(swh.flg_status,
                          pk_supplies_constant.g_sww_all_consumed,
                          pk_supplies_constant.g_sww_transport_concluded,
                          pk_supplies_constant.g_sww_request_local,
                          decode((SELECT COUNT(1)
                                   FROM supply_workflow w
                                  WHERE w.id_consumption_parent = swh.id_supply_workflow),
                                 0,
                                 swh.flg_status,
                                 pk_supplies_constant.g_sww_transport_concluded),
                          swh.flg_status) param_val,
                   swh.id_supply_workflow param_id,
                   sm.desc_message label,
                   sm.code_message code,
                   pk_date_utils.date_send_tsz(i_lang, swh.dt_supply_workflow, i_prof) timestamp_order,
                   get_supply_workflow_col_value(i_lang,
                                                 i_prof,
                                                 swh.id_supply_workflow,
                                                 sm.code_message,
                                                 'SUPPLY_WORKFLOW') VALUE,
                   10 rank,
                   t.id rank_value
              FROM (SELECT flg_status,
                           id_supply_workflow,
                           id_supply,
                           id_supply_area,
                           dt_supply_workflow,
                           id_cancel_reason
                      FROM supply_workflow
                     WHERE id_supply_workflow = i_id_sup_wf
                    UNION
                    SELECT flg_status,
                           id_supply_workflow,
                           id_supply,
                           id_supply_area,
                           dt_supply_workflow,
                           id_cancel_reason
                      FROM supply_workflow
                     WHERE (id_supply_workflow IN (SELECT DISTINCT id_consumption_parent
                                                     FROM supply_workflow
                                                    WHERE id_supply_workflow = i_id_sup_wf) OR
                           --Partial dispenses
                           id_supply_workflow = (SELECT swp.id_dispense_parent
                                                    FROM supply_workflow swp
                                                   WHERE swp.id_supply_workflow = i_id_sup_wf))) swh,
                   TABLE(l_table_others) t,
                   sys_message sm,
                   supply s
             WHERE s.id_supply = swh.id_supply
               AND swh.flg_status NOT IN (pk_supplies_constant.g_sww_rejected_pharmacist,
                                          pk_supplies_constant.g_sww_rejected_technician,
                                          pk_supplies_constant.g_sww_cancelled,
                                          -- pk_supplies_constant.g_sww_request_local,
                                          pk_supplies_constant.g_sww_request_central,
                                          pk_supplies_constant.g_sww_request_wait,
                                          pk_supplies_constant.g_sww_predefined)
               AND sm.code_message = t.desc_info
               AND sm.id_language = i_lang
               AND (swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies OR
                   (swh.id_supply_area != pk_supplies_constant.g_area_surgical_supplies AND
                   t.desc_info NOT IN (SELECT *
                                           FROM TABLE(l_table_surg_supplies) ts)))
               AND (s.flg_type != pk_supplies_constant.g_supply_set_type OR
                   (s.flg_type = pk_supplies_constant.g_supply_set_type AND
                   sm.code_message NOT IN ('SUPPLIES_T109', 'SUPPLIES_T106')))
             ORDER BY rank, timestamp_order, rank_value;
    
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
            pk_types.open_my_cursor(o_rejected);
            pk_types.open_my_cursor(o_others);
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
    
        l_shortcut        sys_shortcut.id_sys_shortcut%TYPE := NULL;
        l_id_category     wf_status_config.id_category%TYPE;
        l_loaned_msg      sys_message.desc_message%TYPE;
        l_with_return_msg sys_message.desc_message%TYPE;
        l_cancelled_desc  sys_message.desc_message%TYPE;
        l_msg_reusable    sys_message.desc_message%TYPE;
        l_msg_disposable  sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'GET Message';
    
        l_loaned_msg := pk_message.get_message(i_lang      => i_lang,
                                               i_code_mess => pk_act_therap_constant.g_msg_loaned_units);
    
        l_with_return_msg := pk_message.get_message(i_lang      => i_lang,
                                                    i_code_mess => pk_act_therap_constant.g_msg_with_return);
    
        l_cancelled_desc := pk_message.get_message(i_lang      => i_lang,
                                                   i_code_mess => pk_act_therap_constant.g_msg_cancelled);
    
        l_msg_reusable := pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096');
    
        l_msg_disposable := pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095');
    
        g_error       := 'get past episodes';
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        OPEN o_supply FOR
            SELECT tb.*,
                   decode(int_notes, '---', '', int_notes) notes,
                   (SELECT REPLACE(REPLACE(l_loaned_msg, pk_act_therap_constant.g_1st_replace, tb.quantity),
                                   pk_act_therap_constant.g_2nd_replace,
                                   tb.conf_quantity)
                      FROM dual) AS nr_units,
                   (SELECT check_supply_wf_cancel(i_lang, i_prof, 3, tb.status, tb.quantity, tb.total_quantity)
                      FROM dual) flg_cancelable,
                   tb.total_quantity loaned_total_qty,
                   (SELECT get_delivered_units(i_lang, i_prof, tb.id_supply_workflow, tb.id_sup_workflow_parent)
                      FROM dual) delivered_total_qty,
                   CASE
                        WHEN tb.status IN
                             (pk_supplies_constant.g_sww_cancelled, pk_supplies_constant.g_sww_deliver_cancelled) THEN
                         l_cancelled_desc
                        WHEN tb.status = pk_supplies_constant.g_sww_loaned THEN
                         decode(tb.quantity, tb.total_quantity, '', l_with_return_msg)
                    END supply_status_desc
              FROM (SELECT sw.id_supply_workflow,
                           wsc.rank,
                           sw.flg_status status,
                           (SELECT pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_STATUS', sw.flg_status, i_lang)
                              FROM dual) desc_status,
                           s.id_supply id_supply,
                           nvl(sw.flg_context, pk_supplies_constant.g_context_supplies) flg_context,
                           (SELECT pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_CONTEXT',
                                                           nvl(sw.flg_context, pk_supplies_constant.g_context_supplies),
                                                           i_lang)
                              FROM dual) desc_context,
                           (SELECT pk_translation.get_translation(i_lang, s.code_supply)
                              FROM dual) ||
                           decode(sw.id_supply_set,
                                  NULL,
                                  NULL,
                                  ' (' || (SELECT pk_translation.get_translation(i_lang, sp.code_supply)
                                             FROM supply sp
                                            WHERE id_supply = sw.id_supply_set) || ')') desc_supply,
                           CASE
                                WHEN sw.flg_status IN (pk_supplies_constant.g_sww_transport_concluded,
                                                       pk_supplies_constant.g_sww_request_local) THEN
                                 pk_supplies_core.get_supply_available_quantity(i_lang               => i_lang,
                                                                                i_prof               => i_prof,
                                                                                i_id_supply_workflow => sw.id_supply_workflow)
                                ELSE
                                 nvl(sw.quantity, 1)
                            END quantity,
                           sw.flg_reusable,
                           decode(sw.flg_reusable, pk_supplies_constant.g_yes, l_msg_reusable, l_msg_disposable) desc_reusable,
                           sw.flg_cons_type,
                           (SELECT pk_sysdomain.get_domain(decode(sw.id_supply_area,
                                                                  pk_supplies_constant.g_area_surgical_supplies,
                                                                  'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                                  'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                                           sw.flg_cons_type,
                                                           i_lang)
                              FROM dual) desc_cons_type,
                           sw.id_supply_location,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, sw.dt_request, i_prof)
                              FROM dual) dt_request,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof)
                              FROM dual) dt_returned,
                           (SELECT pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                         sw.dt_returned,
                                                                         i_prof.institution,
                                                                         i_prof.software)
                              FROM dual) date_returned,
                           (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    sw.dt_returned,
                                                                    i_prof.institution,
                                                                    i_prof.software)
                              FROM dual) hour_returned,
                           (SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                      sw.dt_returned,
                                                                      i_prof.institution,
                                                                      i_prof.software)
                              FROM dual) dt_hr_returned,
                           sw.id_req_reason,
                           (SELECT pk_translation.get_translation(i_lang, sre.code_supply_reason)
                              FROM supply_reason sre
                             WHERE sre.id_supply_reason = sw.id_req_reason) desc_reason,
                           (SELECT get_supply_workflow_col_value(i_lang,
                                                                 i_prof,
                                                                 sw.id_supply_workflow,
                                                                 'SUPPLIES_T109',
                                                                 'SUPPLY_WORKFLOW')
                              FROM dual) int_notes,
                           sr.id_room_req id_room_req,
                           (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                              FROM room r
                             WHERE r.id_room = sr.id_room_req) room,
                           (SELECT pk_translation.get_translation(i_lang, d.code_department)
                              FROM department d, room r
                             WHERE d.id_department = r.id_department
                               AND r.id_room = sr.id_room_req) service,
                           (SELECT pk_translation.get_translation(i_lang, dt.code_dept)
                              FROM department d, room r, dept dt
                             WHERE d.id_department = r.id_department
                               AND r.id_room = sr.id_room_req
                               AND d.id_dept = dt.id_dept) department,
                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)
                              FROM dual) prof_req,
                           (SELECT pk_translation.get_translation(i_lang, sl.code_supply_location)
                              FROM supply_location sl
                             WHERE sw.id_supply_location = sl.id_supply_location) desc_location,
                           (SELECT pk_supplies_core.get_attributes(i_lang,
                                                                   i_prof,
                                                                   sw.id_supply_area,
                                                                   s.id_supply,
                                                                   sw.id_supply_location,
                                                                   NULL,
                                                                   sw.id_supply_workflow)
                              FROM dual) desc_supply_attrib,
                           (SELECT get_supply_wf_status_string(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_flg_status         => sw.flg_status,
                                                               i_id_sys_shortcut    => l_shortcut,
                                                               i_id_workflow        => wsc.id_workflow,
                                                               i_id_supply_area     => sw.id_supply_area,
                                                               i_id_category        => l_id_category,
                                                               i_dt_returned        => sw.dt_returned,
                                                               i_dt_request         => sw.dt_request,
                                                               i_dt_supply_workflow => sw.dt_supply_workflow,
                                                               i_id_episode         => sw.id_episode,
                                                               i_supply_workflow    => sw.id_supply_workflow)
                              FROM dual) status_string,
                           (SELECT pk_translation.get_translation(i_lang,
                                                                  'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || s.id_supply_type)
                              FROM dual) desc_supply_type,
                           CASE
                                WHEN sw.id_supply_set IS NOT NULL THEN
                                 (SELECT pk_translation.get_translation(i_lang, a.code_supply_type)
                                    FROM supply_workflow swp
                                   INNER JOIN supply sp
                                      ON sp.id_supply = swp.id_supply
                                   INNER JOIN supply_type a
                                      ON sp.id_supply_type = a.id_supply_type
                                   WHERE swp.id_supply_workflow = sw.id_sup_workflow_parent)
                                ELSE
                                 (SELECT pk_translation.get_translation(i_lang,
                                                                        'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || s.id_supply_type)
                                    FROM dual)
                            END grid_desc_supply_type,
                           s.id_supply_type,
                           sw.total_quantity,
                           (SELECT sw.total_avail_quantity - get_nr_loaned_units(i_lang,
                                                                                 i_prof,
                                                                                 sw.id_supply_area,
                                                                                 s.id_supply,
                                                                                 sw.id_episode,
                                                                                 NULL,
                                                                                 NULL,
                                                                                 NULL)
                              FROM dual) nr_units_avail,
                           sw.id_sup_workflow_parent,
                           sw.total_avail_quantity AS conf_quantity,
                           sw.barcode_scanned,
                           sw.asset_number,
                           sw.cod_table desc_table,
                           sw.flg_preparing,
                           sw.id_supply_request,
                           sw.id_supply_area,
                           decode(ipd.id_interv_presc_det,
                                  NULL,
                                  '',
                                  pk_procedures_api_db.get_alias_translation(i_lang,
                                                                             i_prof,
                                                                             'INTERVENTION.CODE_INTERVENTION.' ||
                                                                             ipd.id_intervention,
                                                                             NULL)) procedures,
                           CASE
                                WHEN (SELECT COUNT(*)
                                        FROM supply_workflow_hist ht
                                       WHERE ht.id_supply_workflow = sw.id_supply_workflow) = 0
                                     OR nvl((SELECT decode(ht.flg_status, sw.flg_status, 0)
                                              FROM supply_workflow_hist ht
                                             WHERE ht.id_supply_workflow = sw.id_supply_workflow
                                               AND ht.id_supply_workflow_hist =
                                                   (SELECT MAX(id_supply_workflow_hist)
                                                      FROM supply_workflow_hist
                                                     WHERE id_supply_workflow = sw.id_supply_workflow)),
                                            0) = 0 THEN
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                 pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                                           i_prof,
                                                                                           sw.id_professional,
                                                                                           sw.dt_supply_workflow,
                                                                                           sw.id_episode),
                                                          ' (@)')
                            END prof_last_upd,
                           CASE
                                WHEN (SELECT COUNT(*)
                                        FROM supply_workflow_hist ht
                                       WHERE ht.id_supply_workflow = sw.id_supply_workflow) = 0
                                     OR nvl((SELECT decode(ht.flg_status, sw.flg_status, 0)
                                              FROM supply_workflow_hist ht
                                             WHERE ht.id_supply_workflow = sw.id_supply_workflow
                                               AND ht.id_supply_workflow_hist =
                                                   (SELECT MAX(id_supply_workflow_hist)
                                                      FROM supply_workflow_hist
                                                     WHERE id_supply_workflow = sw.id_supply_workflow)),
                                            0) = 0 THEN
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                 pk_string_utils.surround(pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                             sw.dt_supply_workflow,
                                                                                             i_prof),
                                                          ' (@)')
                            END dt_last_upd,
                           decode(sw.flg_status,
                                  pk_supplies_constant.g_sww_deliver_institution,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                  pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                                            i_prof,
                                                                                            sw.id_professional,
                                                                                            sw.dt_supply_workflow,
                                                                                            sw.id_episode),
                                                           ' (@)')) prof_returned,
                           s.flg_type,
                           pk_sysdomain.get_domain(i_code_dom => 'SUPPLY.FLG_TYPE.SR',
                                                   i_val      => s.flg_type,
                                                   i_lang     => i_lang) desc_flg_type,
                           decode(s.flg_type,
                                  pk_supplies_constant.g_supply_set_type,
                                  1,
                                  pk_supplies_constant.g_supply_kit_type,
                                  2,
                                  pk_supplies_constant.g_supply_equipment_type,
                                  3,
                                  pk_supplies_constant.g_supply_implant_type,
                                  4,
                                  5) flg_type_rank
                      FROM supply_workflow sw
                      JOIN supply s
                        ON sw.id_supply = s.id_supply
                      LEFT JOIN supply_location sl
                        ON sl.id_supply_location = sw.id_supply_location
                      LEFT JOIN (SELECT *
                                  FROM supply_request sr
                                 WHERE sr.flg_status != pk_supplies_constant.g_srt_draft) sr
                        ON sw.id_supply_request = sr.id_supply_request
                      JOIN wf_status_config wsc
                        ON wsc.id_status = (SELECT pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status)
                                              FROM dual)
                       AND wsc.id_workflow = decode(sw.id_supply_area,
                                                    pk_supplies_constant.g_area_activity_therapy,
                                                    pk_supplies_constant.g_id_workflow_at,
                                                    pk_supplies_constant.g_area_surgical_supplies,
                                                    pk_supplies_constant.g_id_workflow_sr,
                                                    pk_supplies_constant.g_id_workflow)
                      LEFT JOIN interv_presc_det ipd
                        ON (ipd.id_interv_presc_det = sr.id_context AND sr.flg_context = 'P')
                     WHERE sw.flg_status NOT IN
                           (pk_supplies_constant.g_sww_predefined, pk_supplies_constant.g_sww_updated)
                       AND wsc.id_category = l_id_category
                       AND ((sw.id_sup_workflow_parent IN (SELECT t.column_value /*+opt_estimate(table t rows=1)*/
                                                             FROM TABLE(i_supply) t) AND sw.id_supply_set IS NOT NULL) OR
                           (sw.id_supply_workflow IN (SELECT t.column_value /*+opt_estimate(table t rows=1)*/
                                                         FROM TABLE(i_supply) t) AND
                           s.flg_type != pk_supplies_constant.g_supply_set_type))
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND sw.id_episode = i_id_episode
                     ORDER BY flg_type_rank,
                              wsc.rank,
                              sw.dt_returned,
                              to_char(sw.dt_request, 'YYYY-MM-DD HH24:MI'),
                              lower(desc_supply)) tb;
    
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
            RETURN FALSE;
    END get_supply_to_edit;

    FUNCTION get_supply_filter_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN t_tbl_supply_type_consumption IS
    
        l_req_loan   sys_config.value%TYPE := pk_sysconfig.get_config('SUPPLIES_LOAN_REQ_AVILABLE', i_prof);
        l_cons_loan  sys_config.value%TYPE := pk_sysconfig.get_config('SUPPLIES_LOAN_CONSUMPTION_AVILABLE', i_prof);
        l_req_local  sys_config.value%TYPE := pk_sysconfig.get_config('SUPPLIES_LOCAL_REQ_AVILABLE', i_prof);
        l_cons_local sys_config.value%TYPE := pk_sysconfig.get_config('SUPPLIES_LOCAL_CONSUMPTION_AVILABLE', i_prof);
    
        l_count_prof PLS_INTEGER;
        l_count_dept PLS_INTEGER;
    
        l_dept department.id_department%TYPE;
    
        l_id_supply_area supply_area.id_supply_area%TYPE := nvl(i_id_supply_area, pk_supplies_constant.g_area_supplies);
    
        l_ret t_tbl_supply_type_consumption;
    
    BEGIN
    
        IF i_id_inst_dest IS NULL
        THEN
            IF i_episode IS NOT NULL
            THEN
                g_error := 'GET L_COUNT_PROF';
                SELECT COUNT(DISTINCT ssi.flg_cons_type)
                  INTO l_count_prof
                  FROM supply_soft_inst ssi
                 INNER JOIN supply s
                    ON ssi.id_supply = s.id_supply
                   AND s.flg_available = pk_supplies_constant.g_yes
                 INNER JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                   AND ssa.flg_available = pk_supplies_constant.g_yes
                   AND ssa.id_supply_area = l_id_supply_area
                 WHERE ssi.id_institution = i_prof.institution
                   AND ssi.id_software = i_prof.software
                   AND ssi.id_professional = i_prof.id
                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
            
                g_error := 'GET L_DEPT';
                SELECT e.id_dept_requested
                  INTO l_dept
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            
                g_error := 'GET L_COUNT_DEPT';
                SELECT COUNT(DISTINCT sks.flg_cons_type)
                  INTO l_count_dept
                  FROM supply_soft_inst sks
                 INNER JOIN supply s
                    ON sks.id_supply = s.id_supply
                   AND s.flg_available = pk_supplies_constant.g_yes
                 INNER JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = sks.id_supply_soft_inst
                   AND ssa.flg_available = pk_supplies_constant.g_yes
                   AND ssa.id_supply_area = l_id_supply_area
                 WHERE sks.id_institution = i_prof.institution
                   AND sks.id_software = i_prof.software
                   AND sks.id_dept = l_dept
                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
            
                IF l_count_prof > 0
                THEN
                    g_error := 'IF L_COUNT_PROF > 0';
                    SELECT t_tl_supply_type_consumption(val, desc_val, NULL)
                      BULK COLLECT
                      INTO l_ret
                      FROM (SELECT DISTINCT ssi.flg_cons_type val,
                                            pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                    ssi.flg_cons_type,
                                                                    i_lang) desc_val,
                                            (SELECT coalesce(sdi.rank,
                                                             pk_sysdomain.get_rank(i_lang,
                                                                                   'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                                   ssi.flg_cons_type))
                                               FROM sys_domain_instit_soft_dcs sdi
                                              WHERE sdi.code_domain = 'SUPPLY_SOFT_INST.FLG_CONS_TYPE'
                                                AND sdi.val = ssi.flg_cons_type
                                                AND sdi.flg_action = pk_alert_constant.g_active) rank
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = l_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND ssi.id_professional = i_prof.id
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                               AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                   l_cons_loan = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                   l_cons_local = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                   (i_flg_consumption = pk_alert_constant.g_no AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                   l_req_loan = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                   l_req_local = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                   (i_flg_consumption IS NULL AND
                                   ssi.flg_cons_type IN
                                   (pk_supplies_constant.g_consumption_type_loan,
                                      pk_supplies_constant.g_consumption_type_local,
                                      pk_supplies_constant.g_consumption_type_implant)))
                             ORDER BY rank, desc_val);
                
                ELSIF (l_count_dept > 0 AND l_count_prof = 0)
                THEN
                    g_error := 'ELSIF (L_COUNT_DEPT > 0 AND L_COUNT_PROF = 0)';
                    SELECT t_tl_supply_type_consumption(val, desc_val, NULL)
                      BULK COLLECT
                      INTO l_ret
                      FROM (SELECT DISTINCT ssi.flg_cons_type val,
                                            pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                    ssi.flg_cons_type,
                                                                    i_lang) desc_val,
                                            (SELECT coalesce(sdi.rank,
                                                             pk_sysdomain.get_rank(i_lang,
                                                                                   'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                                   ssi.flg_cons_type))
                                               FROM sys_domain_instit_soft_dcs sdi
                                              WHERE sdi.code_domain = 'SUPPLY_SOFT_INST.FLG_CONS_TYPE'
                                                AND sdi.val = ssi.flg_cons_type
                                                AND sdi.flg_action = pk_alert_constant.g_active) rank
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = l_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND ssi.id_dept = l_dept
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                               AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                   l_cons_loan = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                   l_cons_local = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                   (i_flg_consumption = pk_alert_constant.g_no AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                   l_req_loan = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                   l_req_local = pk_supplies_constant.g_yes) OR
                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                   (i_flg_consumption IS NULL AND
                                   ssi.flg_cons_type IN
                                   (pk_supplies_constant.g_consumption_type_loan,
                                      pk_supplies_constant.g_consumption_type_local,
                                      pk_supplies_constant.g_consumption_type_implant)))
                             ORDER BY rank, desc_val);
                
                ELSIF (l_count_prof = 0 AND l_count_dept = 0)
                THEN
                    g_error := 'ELSIF (l_count_prof = 0 AND l_count_dept = 0)';
                    SELECT t_tl_supply_type_consumption(val, desc_val, NULL)
                      BULK COLLECT
                      INTO l_ret
                      FROM (SELECT t.flg_cons_type val,
                                   pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE', t.flg_cons_type, i_lang) desc_val
                              FROM (SELECT DISTINCT flg_cons_type, rank
                                      FROM (SELECT flg_cons_type,
                                                   s.code_supply,
                                                   (SELECT coalesce(sdi.rank,
                                                                    pk_sysdomain.get_rank(i_lang,
                                                                                          'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                                          ssi.flg_cons_type))
                                                      FROM sys_domain_instit_soft_dcs sdi
                                                     WHERE sdi.code_domain = 'SUPPLY_SOFT_INST.FLG_CONS_TYPE'
                                                       AND sdi.val = ssi.flg_cons_type
                                                       AND sdi.flg_action = pk_alert_constant.g_active) rank
                                              FROM supply_soft_inst ssi
                                             INNER JOIN supply s
                                                ON ssi.id_supply = s.id_supply
                                               AND s.flg_available = pk_supplies_constant.g_yes
                                             INNER JOIN supply_sup_area ssa
                                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                               AND ssa.flg_available = pk_supplies_constant.g_yes
                                               AND ssa.id_supply_area = l_id_supply_area
                                             WHERE ssi.id_institution = i_prof.institution
                                               AND ssi.id_software = i_prof.software
                                               AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                                   l_cons_loan = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                                   l_cons_local = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                                   (i_flg_consumption = pk_alert_constant.g_no AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                                   l_req_loan = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                                   l_req_local = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                                   (i_flg_consumption IS NULL AND
                                                   ssi.flg_cons_type IN
                                                   (pk_supplies_constant.g_consumption_type_loan,
                                                      pk_supplies_constant.g_consumption_type_local,
                                                      pk_supplies_constant.g_consumption_type_implant)))
                                               AND rownum > 0)
                                     WHERE pk_translation.get_translation(i_lang, code_supply) IS NOT NULL) t
                             ORDER BY rank, desc_val);
                END IF;
            ELSE
            
                IF i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                THEN
                    SELECT t_tl_supply_type_consumption(sd.val, sd.desc_val, NULL)
                      BULK COLLECT
                      INTO l_ret
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                          i_prof,
                                                                          'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                          NULL)) sd
                     WHERE sd.val = 'C';
                ELSE
                    SELECT t_tl_supply_type_consumption(sd.val, sd.desc_val, NULL)
                      BULK COLLECT
                      INTO l_ret
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                          i_prof,
                                                                          'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                          NULL)) sd;
                END IF;
            END IF;
        ELSE
            SELECT t_tl_supply_type_consumption(val, desc_val, NULL)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t.flg_cons_type val,
                           pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE', t.flg_cons_type, i_lang) desc_val
                      FROM (SELECT DISTINCT flg_cons_type, rank
                              FROM (SELECT flg_cons_type,
                                           s.code_supply,
                                           (SELECT coalesce(sdi.rank,
                                                            pk_sysdomain.get_rank(i_lang,
                                                                                  'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                                                  ssi.flg_cons_type))
                                              FROM sys_domain_instit_soft_dcs sdi
                                             WHERE sdi.code_domain = 'SUPPLY_SOFT_INST.FLG_CONS_TYPE'
                                               AND sdi.val = ssi.flg_cons_type
                                               AND sdi.flg_action = pk_alert_constant.g_active) rank
                                      FROM supply_soft_inst ssi
                                     INNER JOIN supply s
                                        ON ssi.id_supply = s.id_supply
                                       AND s.flg_available = pk_supplies_constant.g_yes
                                     INNER JOIN supply_sup_area ssa
                                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                       AND ssa.flg_available = pk_supplies_constant.g_yes
                                       AND ssa.id_supply_area = l_id_supply_area
                                     WHERE ssi.id_institution = i_id_inst_dest
                                       AND ssi.id_software = pk_sr_planning.g_software_oris
                                       AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                           l_cons_loan = pk_supplies_constant.g_yes) OR
                                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                           l_cons_local = pk_supplies_constant.g_yes) OR
                                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                           (i_flg_consumption = pk_alert_constant.g_no AND
                                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                           l_req_loan = pk_supplies_constant.g_yes) OR
                                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_loan) AND
                                           ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                           l_req_local = pk_supplies_constant.g_yes) OR
                                           ssi.flg_cons_type != pk_supplies_constant.g_consumption_type_local)) OR
                                           (i_flg_consumption IS NULL AND
                                           ssi.flg_cons_type IN
                                           (pk_supplies_constant.g_consumption_type_loan,
                                              pk_supplies_constant.g_consumption_type_local,
                                              pk_supplies_constant.g_consumption_type_implant)))
                                       AND rownum > 0)
                             WHERE pk_translation.get_translation(i_lang, code_supply) IS NOT NULL) t
                     ORDER BY rank, desc_val);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_supply_filter_list;

    FUNCTION get_supply_location_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_sup         IN supply.id_supply%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_supplies_interface_workflow sys_config.value%TYPE := pk_sysconfig.get_config('SUPPLIES_INTERFACE_WORKFLOW',
                                                                                       i_prof);
        l_id_supply_area              supply_area.id_supply_area%TYPE := i_id_supply_area;
    
    BEGIN
    
        IF i_id_supply_area IS NULL
        THEN
            g_error := 'GET SUPPLY AREA';
            IF NOT pk_supplies_core.get_id_supply_area(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply      => i_id_sup,
                                                       i_flg_type       => NULL,
                                                       o_id_supply_area => l_id_supply_area,
                                                       o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF l_supplies_interface_workflow = pk_supplies_constant.g_yes
        THEN
            g_error := 'OPEN O_LIST 1';
            OPEN o_list FOR
                SELECT NULL data,
                       0 rank,
                       pk_message.get_message(i_lang, 'SUPPLIES_T120') label,
                       pk_supplies_constant.g_yes flg_default,
                       NULL quantity,
                       NULL flg_cons_type,
                       NULL flg_reusable,
                       pk_alert_constant.g_no flg_editable
                  FROM dual;
        ELSE
        
            g_error := 'OPEN O_LIST 2';
            OPEN o_list FOR
                SELECT sl.id_supply_location data,
                       decode(sld.flg_default, pk_supplies_constant.g_yes, 0, 10) rank,
                       pk_translation.get_translation(i_lang, sl.code_supply_location) label,
                       sld.flg_default,
                       ssi.quantity,
                       ssi.flg_cons_type,
                       ssi.flg_reusable,
                       ssi.flg_editable
                  FROM supply_location sl
                  JOIN supply_loc_default sld
                    ON sl.id_supply_location = sld.id_supply_location
                  JOIN supply_soft_inst ssi
                    ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
                 INNER JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                   AND ssa.flg_available = pk_supplies_constant.g_yes
                   AND ssa.id_supply_area = l_id_supply_area
                 WHERE ssi.id_supply = i_id_sup
                   AND ssi.id_institution = i_prof.institution
                   AND ssi.id_software = i_prof.software
                   AND nvl(ssi.id_professional, 0) IN (0, i_prof.id)
                 ORDER BY rank, label;
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
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT data, rank, label
              FROM (SELECT sr.id_supply_reason data,
                           sr.rank,
                           pk_translation.get_translation(i_lang, sr.code_supply_reason) label
                      FROM supply_reason sr
                     WHERE sr.flg_type = i_flg_type
                       AND sr.flg_available = pk_supplies_constant.g_yes
                       AND nvl(sr.id_institution, 0) IN (0, i_prof.institution))
             WHERE label IS NOT NULL
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_REASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_supply_reason_list;

    PROCEDURE x_______________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_type_by_lot
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_lot         IN supply_barcode.lot%TYPE,
        o_supply_type OUT supply.flg_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'getting flg_type - lot:' || i_lot;
        BEGIN
            SELECT s.flg_type
              INTO o_supply_type
              FROM supply s,
                   (SELECT id_supply
                      FROM (SELECT sb.id_supply,
                                   row_number() over(PARTITION BY id_supply ORDER BY nvl(sb.id_institution, 0) DESC) AS rn
                              FROM supply_barcode sb
                             WHERE sb.lot = i_lot
                               AND nvl(sb.id_institution, 0) IN (0, i_prof.institution))
                     WHERE rn = 1) sb2
             WHERE s.id_supply = sb2.id_supply;
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
            
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TYPE_BY_LOT',
                                              o_error);
            RETURN FALSE;
    END get_type_by_lot;

    FUNCTION get_type_by_barcode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_barcode     IN supply_barcode.barcode%TYPE,
        o_supply_type OUT supply.flg_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'getting flg_type - barcode:' || i_barcode;
        BEGIN
            SELECT s.flg_type
              INTO o_supply_type
              FROM supply s,
                   (SELECT id_supply
                      FROM (SELECT sb.id_supply,
                                   row_number() over(PARTITION BY id_supply ORDER BY nvl(sb.id_institution, 0) DESC) AS rn
                              FROM supply_barcode sb
                             WHERE sb.barcode = i_barcode
                               AND nvl(sb.id_institution, 0) IN (0, i_prof.institution))
                     WHERE rn = 1) sb2
             WHERE s.id_supply = sb2.id_supply;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
            
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TYPE_BY_BARCODE',
                                              o_error);
            RETURN FALSE;
    END get_type_by_barcode;

    FUNCTION get_type_by_asset_nr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_asset_nr    IN supply_fixed_asset_nr.fixed_asset_nr%TYPE,
        o_supply_type OUT supply.flg_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'getting flg_type - i_asset_nr:' || i_asset_nr;
        BEGIN
            SELECT s.flg_type
              INTO o_supply_type
              FROM supply s,
                   (SELECT id_supply
                      FROM (SELECT sb.id_supply,
                                   row_number() over(PARTITION BY id_supply ORDER BY nvl(sb.id_institution, 0) DESC) AS rn
                              FROM supply_fixed_asset_nr sb
                             WHERE sb.fixed_asset_nr = i_asset_nr
                               AND nvl(sb.id_institution, 0) IN (0, i_prof.institution)
                               AND sb.flg_available = pk_supplies_constant.g_yes)
                     WHERE rn = 1) sb2
             WHERE s.id_supply = sb2.id_supply;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
            
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TYPE_BY_ASSET_NR',
                                              o_error);
            RETURN FALSE;
    END get_type_by_asset_nr;

    FUNCTION get_sup_by_fixed_assetnr
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_asset_nr       IN supply_fixed_asset_nr.fixed_asset_nr%TYPE DEFAULT NULL,
        o_c_supply       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_reusable_no  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T095');
        l_reusable_yes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T096');
    
        l_cons_type_local sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T097');
        l_cons_type_loan  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T098');
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_SUP_BY_BARCODE';
        OPEN o_c_supply FOR
            SELECT t.*,
                   pk_translation.get_translation(i_lang, t.code_supply) desc_supply,
                   pk_supplies_core.get_attributes(i_lang, i_prof, t.id_supply_area, t.id_supply) desc_supply_attrib
              FROM (SELECT sb.id_supply id_supply,
                           s.code_supply,
                           s.flg_type flg_type,
                           sb.fixed_asset_nr fixed_asset_nr,
                           ssi.flg_cons_type flg_cons_type,
                           decode(ssi.flg_cons_type,
                                  pk_supplies_constant.g_consumption_type_loan,
                                  l_cons_type_loan,
                                  l_cons_type_local) desc_cons_type,
                           ssi.flg_reusable flg_reusable,
                           decode(ssi.flg_reusable, pk_supplies_constant.g_yes, l_reusable_yes, l_reusable_no) desc_reusable,
                           ssi.id_supply_area,
                           rank() over(ORDER BY nvl(sb.id_institution, 0) DESC) AS rank
                      FROM supply_fixed_asset_nr sb
                      JOIN supply s
                        ON sb.id_supply = s.id_supply
                      JOIN (SELECT ssi.id_supply,
                                  ssi.flg_cons_type,
                                  ssi.flg_reusable,
                                  ssa.id_supply_area,
                                  rank() over(PARTITION BY ssi.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC) AS rank
                             FROM supply_soft_inst ssi
                            INNER JOIN supply_sup_area ssa
                               ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                              AND ssa.flg_available = pk_supplies_constant.g_yes
                              AND ssa.id_supply_area = i_id_supply_area
                            WHERE ssi.id_institution = i_prof.institution
                              AND ssi.id_software = i_prof.software) ssi
                        ON ssi.id_supply = sb.id_supply
                     WHERE ssi.rank = 1
                       AND nvl(sb.id_institution, 0) IN (0, i_prof.institution)
                       AND sb.fixed_asset_nr = i_asset_nr
                       AND i_asset_nr IS NOT NULL) t
             WHERE rank = 1;
    
        pk_types.open_cursor_if_closed(o_c_supply);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              '',
                                              '',
                                              'GET_SUP_BY_FIXED_ASSETNR',
                                              o_error);
            pk_types.open_cursor_if_closed(o_c_supply);
            RETURN FALSE;
    END get_sup_by_fixed_assetnr;

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
    
        g_error := 'checking barcode match';
        o_check := pk_sysconfig.get_config('SUPPLIES_BARCODE_VALIDATION', i_prof);
    
        g_error := 'return supply info';
        IF NOT pk_supplies_core.get_sup_by_barcode(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_supply_area => i_id_supply_area,
                                                   i_barcode        => i_barcode,
                                                   i_lot            => i_lot,
                                                   o_c_supply       => o_c_supply,
                                                   o_c_kit_set      => o_c_kit_set,
                                                   o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        pk_types.open_cursor_if_closed(o_c_supply);
        pk_types.open_cursor_if_closed(o_c_kit_set);
    
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
            RETURN FALSE;
    END check_barcode_scanned;

    FUNCTION check_supply_request_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_supply_request IN supply_request.id_supply_request%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_status   supply_request.flg_status%TYPE;
        l_check_cancel VARCHAR2(1 CHAR);
        l_error        t_error_out;
    
    BEGIN
    
        g_error := 'check for this id_supply_request ' || i_id_supply_request ||
                   ' if all id_supply_workflow are cancelled';
    
        SELECT cancel_sup_req
          INTO l_check_cancel
          FROM (SELECT CASE
                            WHEN flg_req = pk_supplies_constant.g_srt_cancelled THEN
                             CASE
                                 WHEN (SUM(flg_req_count) over(PARTITION BY flg_req) = total_flg_req_count) THEN
                                  pk_supplies_constant.g_yes
                                 ELSE
                                  pk_alert_constant.g_no
                             END
                            ELSE
                             pk_alert_constant.g_no
                        END cancel_sup_req
                  FROM (SELECT sw.flg_status,
                               CASE
                                    WHEN sw.flg_status = pk_supplies_constant.g_sww_cancelled THEN
                                     pk_supplies_constant.g_srt_cancelled
                                    ELSE
                                     'OTHER STATUS'
                                END flg_req,
                               COUNT(sw.id_supply_workflow) flg_req_count,
                               SUM(COUNT(sw.id_supply_workflow)) over(ORDER BY sw.id_supply_request) total_flg_req_count
                          FROM supply_workflow sw
                         WHERE sw.id_supply_request = i_id_supply_request
                         GROUP BY sw.id_supply_request, sw.flg_status))
         WHERE rownum = 1;
    
        -- if l_check_cancel is equal 'N' so is necessary calcule for the other status (requested, ongoing or completed)
        IF l_check_cancel = pk_alert_constant.g_no
        THEN
        
            g_error := 'CALCULE THE SUPPLY REQUEST STATUS';
        
            SELECT flg_supply_request
              INTO l_flg_status
              FROM (SELECT CASE
                                WHEN flg_req = pk_supplies_constant.g_srt_requested THEN
                                 CASE
                                     WHEN (SUM(flg_req_count) over(PARTITION BY flg_req) = total_flg_req_count) THEN
                                      pk_supplies_constant.g_srt_requested
                                     ELSE
                                      pk_supplies_constant.g_srt_ongoing
                                 END
                                WHEN flg_req = pk_supplies_constant.g_srt_completed THEN
                                 CASE
                                     WHEN (SUM(flg_req_count) over(PARTITION BY flg_req) = total_flg_req_count) THEN
                                      pk_supplies_constant.g_srt_completed
                                     ELSE
                                      pk_supplies_constant.g_srt_ongoing
                                 END
                                ELSE
                                 pk_supplies_constant.g_srt_ongoing
                            END flg_supply_request
                      FROM (SELECT sw.flg_status,
                                   (CASE
                                        WHEN sw.flg_status IN (pk_supplies_constant.g_sww_request_central,
                                                               pk_supplies_constant.g_sww_request_local) THEN
                                         pk_supplies_constant.g_srt_requested
                                        WHEN sw.flg_status IN
                                             (pk_supplies_constant.g_sww_consumed,
                                              pk_supplies_constant.g_sww_rejected_pharmacist,
                                              pk_supplies_constant.g_sww_rejected_technician,
                                              pk_supplies_constant.g_sww_deliver_validated) THEN
                                         pk_supplies_constant.g_srt_completed
                                        WHEN sw.flg_status = pk_supplies_constant.g_sww_deliver_concluded THEN
                                         CASE sw.id_supply_location
                                             WHEN pk_supplies_constant.g_pharmacy_location THEN
                                              pk_supplies_constant.g_srt_ongoing
                                             ELSE
                                              pk_supplies_constant.g_srt_completed
                                         END
                                        ELSE
                                         pk_supplies_constant.g_srt_ongoing
                                    END) flg_req,
                                   COUNT(sw.id_supply_workflow) flg_req_count,
                                   SUM(COUNT(sw.id_supply_workflow)) over(ORDER BY sw.id_supply_request) total_flg_req_count
                              FROM supply_workflow sw
                             WHERE sw.id_supply_request = i_id_supply_request
                               AND sw.flg_status != pk_supplies_constant.g_sww_cancelled
                             GROUP BY sw.id_supply_request, sw.flg_status))
             WHERE rownum = 1;
        
            --if l_check_cancel is 'Y' so all id_supply_workflow are with cancelled status
        ELSIF l_check_cancel = pk_supplies_constant.g_yes
        THEN
            l_flg_status := pk_supplies_constant.g_srt_cancelled;
        END IF;
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SUPPLY_REQUEST_STATUS',
                                              l_error);
            RETURN NULL;
    END check_supply_request_status;

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
    
        l_count NUMBER := 0;
    
    BEGIN
    
        g_error := 'checking asset nr match';
        SELECT COUNT(*)
          INTO l_count
          FROM supply_fixed_asset_nr sb
         WHERE sb.fixed_asset_nr = i_asset_nr
           AND nvl(sb.id_institution, 0) IN (0, i_prof.institution);
    
        IF l_count = 0
        THEN
            o_check := pk_alert_constant.g_no;
        ELSE
            o_check := pk_supplies_constant.g_yes;
        
            g_error := 'return supply info';
            IF NOT get_sup_by_fixed_assetnr(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_supply_area => pk_supplies_constant.g_area_activity_therapy, --This function it's called only from Activity Therapist 
                                            i_asset_nr       => i_asset_nr,
                                            o_c_supply       => o_c_supply,
                                            o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        pk_types.open_cursor_if_closed(o_c_supply);
        pk_types.open_cursor_if_closed(o_c_kit_set);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_c_supply);
            pk_types.open_cursor_if_closed(o_c_kit_set);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_ASSET_NR_SCANNED',
                                              o_error);
            RETURN FALSE;
    END check_asset_nr_scanned;

    FUNCTION check_repeated_supplies
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_supply_area       IN supply_workflow.id_supply_area%TYPE,
        i_flg_status           IN table_varchar,
        i_id_supply_no_saved   IN table_number,
        i_id_supply_checked    IN table_number,
        o_id_repeated_supplies OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_repeated_supplies table_number;
    
    BEGIN
        g_error := 'CHECK IF THERE ARE REPEATED SUPPLIES FOR THE SAME EPISODE: ' || i_id_episode ||
                   ' AND ID_SUPPLY_AREA : ' || i_id_supply_area;
    
        SELECT id_supply
          BULK COLLECT
          INTO l_id_repeated_supplies
          FROM (SELECT sw.id_supply
                  FROM supply_workflow sw
                 WHERE sw.id_supply_area = i_id_supply_area
                   AND sw.id_episode = i_id_episode
                   AND sw.flg_status NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(i_flg_status) t)
                   AND sw.id_supply IN
                       (SELECT /*+opt_estimate(table t1 rows=1)*/
                         t1.column_value
                          FROM TABLE(i_id_supply_no_saved) t1
                         WHERE column_value NOT IN ((SELECT /*+opt_estimate(table t2 rows=1)*/
                                                     t2.column_value
                                                      FROM TABLE(i_id_supply_checked) t2)))
                UNION ALL
                SELECT *
                  FROM TABLE(i_id_supply_no_saved MULTISET INTERSECT i_id_supply_checked)
                UNION ALL
                -- get the repeated record in i_id_supply_no_saved collection
                SELECT column_value
                  FROM TABLE(i_id_supply_no_saved)
                 GROUP BY column_value
                HAVING COUNT(*) > 1);
    
        --remove duplicates data record
        o_id_repeated_supplies := SET(l_id_repeated_supplies);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_REPEATED_SUPPLIES',
                                              o_error);
            RETURN FALSE;
    END check_repeated_supplies;

    FUNCTION check_supply_wf_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_workflow.id_supply_area%TYPE,
        i_flg_status     IN supply_workflow.flg_status%TYPE,
        i_quantity       IN supply_workflow.quantity%TYPE,
        i_total_quantity IN supply_workflow.total_quantity%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_supply_wf_cancel';
        l_result VARCHAR2(1 CHAR);
        l_idx    PLS_INTEGER;
    BEGIN
        g_error  := 'Init ' || l_func_name || ' / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_area=' ||
                    i_id_supply_area || ' i_flg_status=' || i_flg_status || ' i_quantity=' || i_quantity ||
                    ' i_total_quantity=' || i_total_quantity;
        l_result := pk_alert_constant.g_no;
    
        IF i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
        THEN
            l_idx := pk_utils. search_table_varchar(i_table  => pk_supplies_constant.g_flg_status_can_cancel,
                                                    i_search => i_flg_status);
            IF l_idx != -1
            THEN
                -- status found, supply_workflow can be cancelled
                l_result := pk_supplies_constant.g_yes;
            END IF;
        ELSE
            -- supplies
            IF i_flg_status NOT IN
               (pk_supplies_constant.g_sww_deliver_institution, pk_supplies_constant.g_sww_cancelled)
            THEN
                l_result := pk_supplies_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_supply_wf_cancel;

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
    
        l_flg_type     supply.flg_type%TYPE;
        l_error        t_error_out;
        l_reusable_no  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T095');
        l_reusable_yes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T096');
    
        l_cons_type_local sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T097');
        l_cons_type_loan  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUPPLIES_T098');
        t_sup_list        table_number;
        l_id_supply_area  supply_area.id_supply_area%TYPE;
    
    BEGIN
    
        --IF the barcode is not null, that is the one we need 
        --to get the type from, otherwise we will check the lot info
        g_error := 'checking barcode and lot values';
        IF i_barcode IS NOT NULL
        THEN
            IF NOT get_type_by_barcode(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_barcode     => i_barcode,
                                       o_supply_type => l_flg_type,
                                       o_error       => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        ELSIF i_lot IS NOT NULL
        THEN
            IF NOT get_type_by_lot(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_lot         => i_lot,
                                   o_supply_type => l_flg_type,
                                   o_error       => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSIF i_asset_nr IS NOT NULL
        THEN
            IF NOT get_type_by_asset_nr(i_lang        => i_lang,
                                        i_prof        => i_prof,
                                        i_asset_nr    => i_asset_nr,
                                        o_supply_type => l_flg_type,
                                        o_error       => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        -- if the flg_type is null then, the lot or barcode entered is not on the database
        g_error := 'flg_type is null then, the lot or barcode entered is not on the database ';
        IF l_flg_type IS NULL
        THEN
            pk_types.open_cursor_if_closed(o_c_supply);
            pk_types.open_cursor_if_closed(o_c_kit_set);
            RETURN TRUE;
        END IF;
    
        g_error := 'GET SUPPLY AREA';
        IF i_id_supply_area IS NULL
        THEN
            -- this call was made from Activity Therapist or from material deepanav
            IF NOT pk_supplies_core.get_id_supply_area(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply      => NULL,
                                                       i_flg_type       => l_flg_type,
                                                       o_id_supply_area => l_id_supply_area,
                                                       o_error          => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            --this call was made from surgical supplies and i_id_supply_area=3  
            l_id_supply_area := i_id_supply_area;
        END IF;
    
        --now, we check if the supply type is a individual supply (S)
        g_error := 'we check if the supply type is a individual supply ';
        IF (l_flg_type = pk_supplies_constant.g_supply_type OR
           l_flg_type = pk_supplies_constant.g_supply_equipment_type OR
           l_flg_type = pk_supplies_constant.g_supply_implant_type)
        THEN
            g_error := 'get id_supply_barcode for individual supply';
            SELECT id_supply_barcode
              BULK COLLECT
              INTO t_sup_list
              FROM (SELECT id_supply_barcode, rank() over(ORDER BY id_institution DESC) AS rn
                      FROM (SELECT sb.id_supply_barcode, nvl(id_institution, 0) AS id_institution
                              FROM supply_barcode sb
                             WHERE sb.barcode = i_barcode
                               AND i_barcode IS NOT NULL
                            UNION
                            SELECT sb.id_supply_barcode, nvl(id_institution, 0) AS id_institution
                              FROM supply_barcode sb
                             WHERE sb.lot = i_lot
                               AND i_lot IS NOT NULL)
                     WHERE id_institution IN (0, i_prof.institution))
             WHERE rn = 1;
            --case they are activity therapy supplies
        ELSIF l_flg_type = pk_supplies_constant.g_act_ther_supply
        THEN
            g_error := 'get id_supply_barcode for individual supply';
            SELECT id_supply_barcode
              BULK COLLECT
              INTO t_sup_list
              FROM (SELECT id_supply_barcode, rank() over(ORDER BY id_institution DESC) AS rn
                      FROM (SELECT sb.id_supply_barcode, nvl(id_institution, 0) AS id_institution
                              FROM supply_barcode sb
                             WHERE sb.barcode = i_barcode
                               AND i_barcode IS NOT NULL
                            UNION
                            SELECT sb.id_supply_barcode, nvl(sb.id_institution, 0) AS id_institution
                              FROM supply_barcode sb
                              JOIN supply_fixed_asset_nr sf
                                ON sf.id_supply = sb.id_supply
                             WHERE sf.fixed_asset_nr = i_asset_nr
                               AND i_asset_nr IS NOT NULL)
                     WHERE id_institution IN (0, i_prof.institution))
             WHERE rn = 1;
            --case they are sets or kits
        ELSE
            g_error := 'get id_supply_barcode_item for kits';
            SELECT sbr.id_supply_barcode_item
              BULK COLLECT
              INTO t_sup_list
              FROM supply_barcode_rel sbr,
                   (SELECT id_supply_barcode
                      FROM (SELECT id_supply_barcode, rank() over(ORDER BY id_institution DESC) AS rn
                              FROM (SELECT sb.id_supply_barcode, nvl(id_institution, 0) AS id_institution
                                      FROM supply_barcode sb
                                     WHERE sb.barcode = i_barcode
                                       AND i_barcode IS NOT NULL
                                    UNION
                                    SELECT sb.id_supply_barcode, nvl(id_institution, 0) AS id_institution
                                      FROM supply_barcode sb
                                     WHERE sb.lot = i_lot
                                       AND i_lot IS NOT NULL)
                             WHERE id_institution IN (0, i_prof.institution))
                     WHERE rn = 1) sb2
             WHERE sb2.id_supply_barcode = sbr.id_supply_barcode;
        
            g_error := 'OPEN CURSOR C_KIT_SET';
            OPEN o_c_kit_set FOR
                SELECT t.*,
                       pk_translation.get_translation(i_lang, t.code_supply) desc_supply,
                       pk_supplies_core.get_attributes(i_lang, i_prof, t.id_supply_area, t.id_supply) desc_supply_attrib
                  FROM (SELECT sb.id_supply id_supply,
                               s.code_supply,
                               s.flg_type flg_type,
                               sb.barcode barcode,
                               sb.code code,
                               sb.lot lot,
                               sb.serial_number serial_number,
                               ssi.flg_cons_type flg_cons_type,
                               decode(ssi.flg_cons_type,
                                      pk_supplies_constant.g_consumption_type_loan,
                                      l_cons_type_loan,
                                      l_cons_type_local) desc_cons_type,
                               ssi.flg_reusable flg_reusable,
                               decode(ssi.flg_reusable, pk_supplies_constant.g_yes, l_reusable_yes, l_reusable_no) desc_reusable,
                               rank() over(ORDER BY nvl(sb.id_institution, 0) DESC) AS rank,
                               ssi.id_supply_soft_inst,
                               loc.id_supply_location,
                               pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                               ssi.quantity,
                               ssi.id_supply_area
                          FROM supply_barcode sb
                          JOIN supply s
                            ON sb.id_supply = s.id_supply
                          JOIN (SELECT ssi.id_supply_soft_inst,
                                      ssi.quantity,
                                      ssi.id_supply,
                                      ssi.flg_cons_type,
                                      ssi.flg_reusable,
                                      ssa.id_supply_area,
                                      rank() over(PARTITION BY ssi.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC) AS rank
                                 FROM supply_soft_inst ssi
                                INNER JOIN supply_sup_area ssa
                                   ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                  AND ssa.flg_available = pk_supplies_constant.g_yes
                                  AND ssa.id_supply_area = l_id_supply_area
                                WHERE ssi.id_institution = i_prof.institution
                                  AND ssi.id_software = i_prof.software) ssi
                            ON ssi.id_supply = sb.id_supply
                          LEFT JOIN (SELECT sld.id_supply_location, sld.id_supply_soft_inst, sl.code_supply_location
                                      FROM supply_loc_default sld
                                     INNER JOIN supply_location sl
                                        ON sld.id_supply_location = sl.id_supply_location
                                       AND sld.flg_default = pk_supplies_constant.g_yes) loc
                            ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                         WHERE sb.barcode = i_barcode
                           AND ssi.rank = 1
                           AND nvl(sb.id_institution, 0) IN (0, i_prof.institution)) t
                 WHERE rank = 1;
        END IF;
    
        --then we get the list of supplies with that barcode
        IF t_sup_list IS NOT NULL
        THEN
        
            g_error := 'OPEN CURSOR C_SUP_BY_BARCODE';
            OPEN o_c_supply FOR
                SELECT t.*,
                       pk_translation.get_translation(i_lang, t.code_supply) desc_supply,
                       pk_supplies_core.get_attributes(i_lang, i_prof, t.id_supply_area, t.id_supply) desc_supply_attrib
                  FROM (SELECT sb.id_supply id_supply,
                               s.code_supply,
                               s.flg_type flg_type,
                               sb.barcode barcode,
                               sb.code code,
                               sb.lot lot,
                               sb.serial_number serial_number,
                               ssi.flg_cons_type flg_cons_type,
                               decode(ssi.flg_cons_type,
                                      pk_supplies_constant.g_consumption_type_loan,
                                      l_cons_type_loan,
                                      l_cons_type_local) desc_cons_type,
                               ssi.flg_reusable flg_reusable,
                               decode(ssi.flg_reusable, pk_supplies_constant.g_yes, l_reusable_yes, l_reusable_no) desc_reusable,
                               rank() over(ORDER BY nvl(sb.id_institution, 0) DESC) AS rank,
                               ssi.id_supply_soft_inst,
                               loc.id_supply_location,
                               pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                               ssi.quantity,
                               ssi.id_supply_area,
                               pk_date_utils.date_send_tsz(i_lang, sb.dt_expiration, i_prof) dt_expiration,
                               pk_supplies_constant.g_yes flg_validation
                          FROM supply_barcode sb
                          JOIN supply s
                            ON sb.id_supply = s.id_supply
                          JOIN (SELECT ssi.id_supply_soft_inst,
                                      ssi.quantity,
                                      ssi.id_supply,
                                      ssi.flg_cons_type,
                                      ssi.flg_reusable,
                                      ssa.id_supply_area,
                                      rank() over(PARTITION BY ssi.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC) AS rank
                                 FROM supply_soft_inst ssi
                                INNER JOIN supply_sup_area ssa
                                   ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                  AND ssa.flg_available = pk_supplies_constant.g_yes
                                  AND ssa.id_supply_area = l_id_supply_area
                                WHERE ssi.id_institution = i_prof.institution
                                  AND ssi.id_software = i_prof.software) ssi
                            ON ssi.id_supply = sb.id_supply
                          LEFT JOIN (SELECT sld.id_supply_location, sld.id_supply_soft_inst, sl.code_supply_location
                                      FROM supply_loc_default sld
                                     INNER JOIN supply_location sl
                                        ON sld.id_supply_location = sl.id_supply_location
                                       AND sld.flg_default = pk_supplies_constant.g_yes) loc
                            ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                          JOIN TABLE(t_sup_list) tsl
                            ON tsl.column_value = sb.id_supply_barcode
                         WHERE ssi.rank = 1
                           AND nvl(sb.id_institution, 0) IN (0, i_prof.institution)) t
                 WHERE rank = 1;
        END IF;
    
        pk_types.open_cursor_if_closed(o_c_supply);
        pk_types.open_cursor_if_closed(o_c_kit_set);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang, SQLCODE, SQLERRM, g_error, '', '', 'GET_SUP_BY_BARCODE', o_error);
            pk_types.open_cursor_if_closed(o_c_supply);
            pk_types.open_cursor_if_closed(o_c_kit_set);
            RETURN FALSE;
    END get_sup_by_barcode;

    FUNCTION get_list_req_cons_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN episode.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN supply.flg_type%TYPE,
        i_flg_status IN table_varchar DEFAULT NULL,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type table_varchar := table_varchar();
    BEGIN
        IF i_flg_type = pk_supplies_constant.g_act_ther_supply
        THEN
            l_flg_type := table_varchar(pk_supplies_constant.g_act_ther_supply);
        ELSE
            l_flg_type := table_varchar(pk_supplies_constant.g_supply_type,
                                        pk_supplies_constant.g_supply_kit_type,
                                        pk_supplies_constant.g_supply_set_type);
        END IF;
    
        g_error := 'CALL pk_supplies_core.GET_LIST_REQ_CONS';
        IF NOT get_supply_listview(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_id_supply_area => NULL,
                                   i_patient        => i_patient,
                                   i_episode        => i_episode,
                                   i_flg_type       => l_flg_type,
                                   o_list           => o_list,
                                   o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_list_req_cons_report;

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
    
        g_error := 'open cursor';
        OPEN o_list FOR
            SELECT sw.id_supply_workflow,
                   s.id_supply,
                   pk_translation.get_translation(i_lang, s.code_supply) desc_supply
              FROM supply_workflow sw, supply s
             WHERE sw.flg_status NOT IN (pk_supplies_constant.g_sww_request_local,
                                         pk_supplies_constant.g_sww_cancelled,
                                         pk_supplies_constant.g_sww_transport_concluded)
               AND sw.id_episode = i_episode
               AND sw.id_supply = s.id_supply
               AND sw.id_supply_request IN (SELECT sr.id_supply_request
                                              FROM supply_request sr
                                             WHERE sr.id_context = i_id_context
                                               AND sr.id_episode = i_episode
                                               AND sr.flg_context = i_flg_context)
               AND sw.dt_request = (SELECT MAX(swf.dt_request)
                                      FROM supply_workflow swf
                                     WHERE swf.id_context = i_id_context
                                       AND swf.flg_context = i_flg_context);
    
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
            pk_types.open_cursor_if_closed(o_list);
            RETURN FALSE;
    END get_sup_not_ready;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN table_varchar,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_supply_area supply_area.id_supply_area%TYPE;
    
        l_inst_dest institution.id_institution%TYPE;
        l_software  software.id_software%TYPE;
    
    BEGIN
    
        IF i_flg_context = pk_supplies_constant.g_context_surgery
        THEN
            l_id_supply_area := pk_supplies_constant.g_area_surgical_supplies;
        ELSE
            l_id_supply_area := pk_supplies_constant.g_area_supplies;
        END IF;
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            SELECT d.id_institution
              INTO l_inst_dest
              FROM dep_clin_serv dcs
              JOIN department d
                ON d.id_department = dcs.id_department
             WHERE dcs.id_dep_clin_serv = i_dep_clin_serv;
        
            l_software := pk_alert_constant.g_soft_oris;
        ELSE
            l_software  := i_prof.software;
            l_inst_dest := i_prof.institution;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_supplies FOR
            SELECT nvl(si.id_supply, s.id_supply) id_supply,
                   nvl2(si.id_supply, s.id_supply, NULL) id_parent_supply,
                   pk_translation.get_translation(i_lang, nvl(si.code_supply, s.code_supply)) desc_supply,
                   pk_supplies_core.get_attributes(i_lang, i_prof, l_id_supply_area, nvl(si.id_supply, s.id_supply)) desc_supply_attrib,
                   pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                           pk_supplies_core.get_consumption_type(i_lang,
                                                                                 i_prof,
                                                                                 l_id_supply_area,
                                                                                 nvl(si.id_supply, s.id_supply)),
                                           i_lang) desc_cons_type,
                   pk_supplies_core.get_consumption_type(i_lang,
                                                         i_prof,
                                                         l_id_supply_area,
                                                         nvl(si.id_supply, s.id_supply)) flg_cons_type,
                   decode(s.flg_type,
                          pk_supplies_constant.g_supply_set_type,
                          decode(nvl(sr.quantity, sc.quantity), 0, 1, nvl(sr.quantity, sc.quantity)),
                          nvl(sr.quantity, sc.quantity)) quantity,
                   NULL dt_return,
                   pk_supplies_core.get_default_location(i_lang,
                                                         i_prof,
                                                         l_id_supply_area,
                                                         nvl(si.id_supply, s.id_supply)) id_supply_location,
                   pk_supplies_core.get_default_location_name(i_lang,
                                                              i_prof,
                                                              l_id_supply_area,
                                                              nvl(si.id_supply, s.id_supply)) desc_supply_location,
                   nvl(si.flg_type, s.flg_type) flg_type,
                   sc.id_context id_context,
                   pk_sysdomain.get_rank(i_lang, 'SUPPLY.FLG_TYPE', nvl(si.flg_type, s.flg_type)) rank,
                   (SELECT id_supply_soft_inst
                      FROM supply_soft_inst
                     WHERE id_supply = s.id_supply
                       AND id_institution = l_inst_dest
                       AND id_software = l_software
                       AND rownum = 1) id_supply_soft_inst
              FROM supply_context sc
              LEFT JOIN supply s
                ON s.id_supply = sc.id_supply
              LEFT JOIN supply_relation sr
                ON sr.id_supply = s.id_supply
              LEFT JOIN supply si
                ON si.id_supply = sr.id_supply_item
              JOIN TABLE(i_id_context) id_c
                ON id_c.column_value = sc.id_context
             WHERE nvl(sc.id_professional, 0) IN (0, i_prof.id)
               AND nvl(sc.id_institution, 0) IN (0, l_inst_dest)
               AND nvl(sc.id_software, 0) IN (0, l_software)
               AND sc.flg_context = i_flg_context
               AND (nvl2(si.id_supply, s.id_supply, NULL) IS NULL OR
                    s.flg_type = pk_supplies_constant.g_supply_set_type)
            UNION ALL
            SELECT s.id_supply id_supply,
                   NULL id_parent_supply,
                   pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                   pk_supplies_core.get_attributes(i_lang, i_prof, l_id_supply_area, s.id_supply) desc_supply_attrib,
                   pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                           pk_supplies_core.get_consumption_type(i_lang,
                                                                                 i_prof,
                                                                                 l_id_supply_area,
                                                                                 s.id_supply),
                                           i_lang) desc_cons_type,
                   pk_supplies_core.get_consumption_type(i_lang, i_prof, l_id_supply_area, s.id_supply) flg_cons_type,
                   decode(s.flg_type,
                          pk_supplies_constant.g_supply_set_type,
                          decode(sc.quantity, 0, 1, sc.quantity),
                          sc.quantity) quantity,
                   NULL dt_return,
                   pk_supplies_core.get_default_location(i_lang, i_prof, l_id_supply_area, s.id_supply) id_supply_location,
                   pk_supplies_core.get_default_location_name(i_lang, i_prof, l_id_supply_area, s.id_supply) desc_supply_location,
                   s.flg_type flg_type,
                   sc.id_context id_context,
                   pk_sysdomain.get_rank(i_lang, 'SUPPLY.FLG_TYPE', s.flg_type) rank,
                   (SELECT id_supply_soft_inst
                      FROM supply_soft_inst
                     WHERE id_supply = s.id_supply
                       AND id_institution = l_inst_dest
                       AND id_software = l_software
                       AND rownum = 1) id_supply_soft_inst
              FROM supply_context sc
              LEFT JOIN supply s
                ON s.id_supply = sc.id_supply
              JOIN TABLE(i_id_context) id_c
                ON id_c.column_value = sc.id_context
             WHERE nvl(sc.id_professional, 0) IN (0, i_prof.id)
               AND nvl(sc.id_institution, 0) IN (0, l_inst_dest)
               AND nvl(sc.id_software, 0) IN (0, l_software)
               AND sc.flg_context = i_flg_context
               AND s.flg_type IN (pk_supplies_constant.g_supply_kit_type, pk_supplies_constant.g_supply_set_type)
             ORDER BY rank, desc_supply;
    
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
            pk_types.open_cursor_if_closed(o_supplies);
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
    
        g_error := 'OPEN CURSOR';
        OPEN o_supplies FOR
            SELECT sw.id_supply_workflow id_supply_workflow,
                   s.id_supply id_supply,
                   s.flg_type flg_supply_type,
                   pk_translation.get_translation(i_lang, s.code_supply) description,
                   sw.quantity quantity,
                   sw.flg_status flg_status,
                   sw.barcode_req barcode_req,
                   sw.flg_reusable,
                   sw.id_supply_set,
                   pk_translation.get_translation(i_lang, sd.code_supply) set_description,
                   sw.flg_cons_type,
                   pk_supplies_core.get_attributes(i_lang,
                                                   i_prof,
                                                   i_supply_area,
                                                   s.id_supply,
                                                   NULL,
                                                   NULL,
                                                   sw.id_supply_workflow) desc_supply_attrib
              FROM supply_request sr
              JOIN supply_workflow sw
                ON sw.id_supply_request = sr.id_supply_request
              JOIN supply s
                ON s.id_supply = sw.id_supply
              LEFT JOIN supply sd
                ON sw.id_supply_set = sd.id_supply
             WHERE sr.id_context = i_id_context
               AND sr.flg_context = i_flg_context
               AND (i_ready = pk_alert_constant.g_no OR (i_ready = pk_supplies_constant.g_yes AND
                   sw.flg_status = pk_supplies_constant.g_sww_transport_concluded))
               AND sr.dt_request = (SELECT MAX(srq.dt_request)
                                      FROM supply_request srq
                                     WHERE srq.id_context = i_id_context)
             ORDER BY description;
    
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
            pk_types.open_cursor_if_closed(o_supplies);
            RETURN FALSE;
    END get_request_by_context;

    FUNCTION get_supply_type_id(i_supply IN supply.id_supply%TYPE) RETURN supply.id_supply_type%TYPE IS
        l_type supply.id_supply_type%TYPE;
    BEGIN
        g_error := 'GET SUPPLY_TYPE';
        SELECT t.id_supply_type id_supply_type
          INTO l_type
          FROM supply t
         WHERE t.id_supply = i_supply;
    
        RETURN l_type;
    END get_supply_type_id;

    FUNCTION get_epis_max_supply_delay
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        g_material_grid_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 10489;
    
        CURSOR c_wf_anc
        (
            id_prof       table_number,
            l_id_category category.id_category%TYPE
        ) IS
            SELECT *
              FROM (SELECT sw1.dt_supply_workflow, sw1.flg_status, wsc.id_workflow, sw1.id_episode
                      FROM wf_status_config wsc
                     INNER JOIN (SELECT sw.flg_status,
                                       sw.dt_supply_workflow,
                                       CASE
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                             pk_supplies_constant.g_id_workflow_sr
                                            ELSE
                                             pk_supplies_constant.g_id_workflow
                                        END id_workflow,
                                       sw.id_episode,
                                       pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status) id_flg_status
                                  FROM supply_workflow sw
                                 WHERE sw.id_episode IN (SELECT id_episode
                                                           FROM episode
                                                          WHERE id_patient = i_id_patient)
                                   AND sw.id_professional IN
                                       (SELECT column_value
                                          FROM TABLE(CAST(id_prof AS table_number)))
                                   AND sw.id_supply_area != pk_supplies_constant.g_area_activity_therapy
                                   AND sw.flg_status IN
                                       (pk_supplies_constant.g_sww_deliver_needed,
                                        pk_supplies_constant.g_sww_prepared_pharmacist,
                                        pk_supplies_constant.g_sww_prepared_technician)) sw1
                        ON sw1.id_flg_status = wsc.id_status
                       AND sw1.id_workflow = wsc.id_workflow
                     WHERE wsc.id_category = pk_prof_utils.get_id_category(i_lang, i_prof)
                     ORDER BY wsc.rank, sw1.dt_supply_workflow) t
             WHERE rownum = 1;
    
        CURSOR c_wf_pharm
        (
            id_prof       table_number,
            l_id_category category.id_category%TYPE
        ) IS
            SELECT t.dt_supply_workflow, t.flg_status, t.id_workflow, t.id_episode
              FROM (SELECT sw1.dt_supply_workflow, sw1.flg_status, wsc.id_workflow, sw1.id_episode
                      FROM wf_status_config wsc
                     INNER JOIN (SELECT sw.flg_status,
                                       CASE
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                                                 AND sw.flg_status = pk_supplies_constant.g_sww_request_central THEN
                                             pk_supplies_external_api_db.check_max_delay_sup_pharmacist(i_lang,
                                                                                                        i_prof,
                                                                                                        sw.id_episode,
                                                                                                        sw.dt_supply_workflow,
                                                                                                        CASE
                                                                                                            WHEN i_phar_main_grid = pk_supplies_constant.g_yes THEN
                                                                                                             pk_supplies_constant.g_yes
                                                                                                            ELSE
                                                                                                             NULL
                                                                                                        END)
                                            ELSE
                                             sw.dt_supply_workflow
                                        END dt_supply_workflow,
                                       CASE
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                             pk_supplies_constant.g_id_workflow_sr
                                            ELSE
                                             pk_supplies_constant.g_id_workflow
                                        END id_workflow,
                                       sw.id_episode,
                                       pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status) id_flg_status
                                  FROM supply_workflow sw
                                 WHERE sw.id_episode IN (SELECT id_episode
                                                           FROM episode
                                                          WHERE id_patient = i_id_patient)
                                   AND sw.id_professional IN
                                       (SELECT column_value
                                          FROM TABLE(CAST(id_prof AS table_number)))
                                   AND sw.id_supply_area != pk_supplies_constant.g_area_activity_therapy
                                   AND sw.flg_status IN
                                       (pk_supplies_constant.g_sww_request_central,
                                        pk_supplies_constant.g_sww_in_delivery,
                                        pk_supplies_constant.g_sww_prepared_pharmacist)) sw1
                        ON sw1.id_flg_status = wsc.id_status
                       AND sw1.id_workflow = wsc.id_workflow
                     WHERE wsc.id_category = l_id_category
                       AND sw1.dt_supply_workflow IS NOT NULL
                     ORDER BY wsc.rank, sw1.dt_supply_workflow) t
             WHERE rownum = 1;
    
        CURSOR c_wf
        (
            id_prof       table_number,
            l_id_category category.id_category%TYPE
        ) IS
        
            SELECT *
              FROM (SELECT sw1.dt_supply_workflow, sw1.flg_status, wsc.id_workflow, sw1.id_episode
                      FROM wf_status_config wsc
                     INNER JOIN (SELECT sw.flg_status,
                                       sw.dt_supply_workflow,
                                       CASE
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                             pk_supplies_constant.g_id_workflow_sr
                                            ELSE
                                             pk_supplies_constant.g_id_workflow
                                        END id_workflow,
                                       sw.id_episode,
                                       pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status) id_flg_status
                                  FROM supply_workflow sw
                                 WHERE sw.id_episode IN (SELECT id_episode
                                                           FROM episode
                                                          WHERE id_patient = i_id_patient)
                                   AND sw.id_professional IN
                                       (SELECT column_value
                                          FROM TABLE(CAST(id_prof AS table_number)))
                                   AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_loaned,
                                                             pk_supplies_constant.g_sww_consumed,
                                                             pk_supplies_constant.g_sww_cancelled)
                                   AND sw.id_supply_area != pk_supplies_constant.g_area_activity_therapy) sw1
                        ON sw1.id_flg_status = wsc.id_status
                       AND sw1.id_workflow = wsc.id_workflow
                     WHERE wsc.id_category = l_id_category
                     ORDER BY wsc.rank, sw1.dt_supply_workflow) t
             WHERE rownum = 1;
    
        CURSOR c_supply_request(i_id_patient patient.id_patient%TYPE) IS
            SELECT DISTINCT sr.id_professional
              FROM supply_request sr
             WHERE sr.id_episode IN (SELECT id_episode
                                       FROM episode
                                      WHERE id_patient = i_id_patient);
    
        CURSOR c_supply_request2(i_id_patient patient.id_patient%TYPE) IS
            SELECT DISTINCT sr.id_professional
              FROM supply_request sr
             WHERE sr.id_episode IN (SELECT id_episode
                                       FROM episode
                                      WHERE id_patient = i_id_patient)
            UNION
            SELECT i_prof.id AS id_professional
              FROM dual;
    
        l_date        supply_workflow.dt_supply_workflow%TYPE;
        l_shortcut    sys_shortcut.id_sys_shortcut%TYPE;
        l_category    category.id_category%TYPE;
        l_status      supply_workflow.flg_status%TYPE DEFAULT NULL;
        l_status_str  VARCHAR2(200) := NULL;
        l_id_prof     table_number := table_number();
        l_id_prof2    table_number := table_number();
        l_id_workflow wf_status_config.id_workflow%TYPE;
        l_id_episode  supply_workflow.id_episode%TYPE;
        l_error       t_error_out;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_id_patient IS NOT NULL
        THEN
            g_error    := 'CALCULATE CATEGORY';
            l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'c_supply_request';
            OPEN c_supply_request(i_id_patient);
            FETCH c_supply_request BULK COLLECT
                INTO l_id_prof;
            CLOSE c_supply_request;
        
            OPEN c_supply_request2(i_id_patient);
            FETCH c_supply_request2 BULK COLLECT
                INTO l_id_prof2;
            CLOSE c_supply_request2;
        
            g_error    := 'CATEGORY=' || l_category;
            l_shortcut := g_material_grid_shortcut;
        
            g_error := 'c_wf';
            IF l_category = 6 -- Ancilary
            THEN
                g_error := 'OPEN CURSOR C_WF_ANC';
            
                OPEN c_wf_anc(l_id_prof, l_category);
                FETCH c_wf_anc
                    INTO l_date, l_status, l_id_workflow, l_id_episode;
                CLOSE c_wf_anc;
            
            ELSIF l_category = 7 -- Pharmacist
            THEN
                g_error := 'OPEN CURSOR C_WF_PHARM';
            
                OPEN c_wf_pharm(l_id_prof2, l_category);
                FETCH c_wf_pharm
                    INTO l_date, l_status, l_id_workflow, l_id_episode;
                CLOSE c_wf_pharm;
            
            ELSE
                g_error := 'OPEN CURSOR C_WF_PHARM';
            
                OPEN c_wf(l_id_prof, l_category);
                FETCH c_wf
                    INTO l_date, l_status, l_id_workflow, l_id_episode;
                CLOSE c_wf;
            END IF;
        
            IF l_date IS NOT NULL
               AND l_status IS NOT NULL
            THEN
                l_status_str := pk_sup_status.get_sup_status_string(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_status         => l_status,
                                                                    i_shortcut       => l_shortcut,
                                                                    i_id_workflow    => l_id_workflow,
                                                                    i_id_category    => l_category,
                                                                    i_date           => l_date,
                                                                    i_id_episode     => l_id_episode,
                                                                    i_phar_main_grid => i_phar_main_grid);
            END IF;
        END IF;
    
        RETURN l_status_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_MAX_SUPPLY_DELAY',
                                              l_error);
            RETURN l_status_str;
    END get_epis_max_supply_delay;

    FUNCTION get_supply_workflow_col_value
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_sw    IN supply_workflow.id_supply_workflow%TYPE,
        i_code_msg IN sys_message.code_message%TYPE,
        i_source   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_ret             VARCHAR2(4000);
        l_supply_set_desc VARCHAR2(300 CHAR);
        l_empty           VARCHAR2(3) := '---';
        l_na              VARCHAR2(4000) := pk_message.get_message(i_lang, 'SUPPLIES_T120');
    
        FUNCTION inner_get_from_sw RETURN VARCHAR2 IS
        BEGIN
            CASE i_code_msg
            -- professional
                WHEN 'SUPPLIES_T100' THEN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- supply name
                WHEN 'SUPPLIES_T101' THEN
                    SELECT pk_translation.get_translation(i_lang, code_supply)
                      INTO l_ret
                      FROM supply_workflow sw
                      JOIN supply s
                        ON sw.id_supply = s.id_supply
                     WHERE id_supply_workflow = i_id_sw
                       AND rownum = 1;
                
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, s.code_supply)
                          INTO l_supply_set_desc
                          FROM supply_workflow a
                         INNER JOIN supply s
                            ON s.id_supply = a.id_supply_set
                         WHERE a.id_supply_workflow = i_id_sw;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_supply_set_desc := NULL;
                    END;
                
                    IF l_supply_set_desc IS NOT NULL
                    THEN
                        l_ret := l_ret || ' (' || l_supply_set_desc || ')';
                    END IF;
                
            -- supply location
                WHEN 'SUPPLIES_T102' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, code_supply_location), l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                      JOIN supply_location s
                        ON sw.id_supply_location = s.id_supply_location(+)
                     WHERE id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- barcode
                WHEN 'SUPPLIES_T103' THEN
                    SELECT nvl(barcode_req, l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- barcode scanned
                WHEN 'SUPPLIES_T104' THEN
                    SELECT nvl(barcode_scanned, l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- quantity
                WHEN 'SUPPLIES_T105' THEN
                    SELECT nvl(quantity, 1)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- request reason
                WHEN 'SUPPLIES_T106' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, sr.code_supply_reason), l_empty)
                      INTO l_ret
                      FROM supply_reason sr
                     RIGHT JOIN supply_workflow sw
                        ON sw.id_req_reason = sr.id_supply_reason
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- request date
                WHEN 'SUPPLIES_T107' THEN
                    SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_request, i_prof)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- returned date
                WHEN 'SUPPLIES_T108' THEN
                    SELECT CASE
                               WHEN swh.id_supply_workflow_hist IS NULL THEN
                                nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_returned, i_prof), l_na)
                               WHEN sw.dt_returned = swh.original_return_date THEN
                                nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_returned, i_prof), l_na)
                               ELSE -- Flash Screen for Supply edition does not allow hours and minutes => dt_chr_tsz
                                nvl(pk_date_utils.dt_chr_tsz(i_lang, dt_returned, i_prof.institution, i_prof.software), l_na)
                           END
                      INTO l_ret
                      FROM supply_workflow sw
                      LEFT JOIN (SELECT *
                                   FROM (SELECT id_supply_workflow_hist,
                                                id_supply_workflow,
                                                dt_returned AS original_return_date
                                           FROM supply_workflow_hist
                                          WHERE id_supply_workflow = i_id_sw
                                          ORDER BY 1 ASC)
                                  WHERE rownum = 1) swh
                        ON swh.id_supply_workflow = sw.id_supply_workflow
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- notes
                WHEN 'SUPPLIES_T109' THEN
                    SELECT nvl(notes, l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- cancel prof
                WHEN 'SUPPLIES_T110' THEN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_prof_cancel)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- cancel date
                WHEN 'SUPPLIES_T111' THEN
                    SELECT nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang, sw.dt_cancel, i_prof), l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- cancel notes
                WHEN 'SUPPLIES_T112' THEN
                    SELECT decode(length(sw.notes_cancel), 0, l_empty, sw.notes_cancel)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- cancel reason
                WHEN 'SUPPLIES_T113' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, cr.code_cancel_reason), l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                      JOIN cancel_reason cr
                        ON sw.id_cancel_reason = cr.id_cancel_reason
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- rejection notes
                WHEN 'SUPPLIES_T114' THEN
                    SELECT nvl(sw.notes_reject, l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- rejection date
                WHEN 'SUPPLIES_T115' THEN
                    SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, sw.dt_reject, i_prof)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- rejection prof
                WHEN 'SUPPLIES_T116' THEN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_prof_reject)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- return reason
                WHEN 'SUPPLIES_T125' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, sr.code_supply_reason), l_empty)
                      INTO l_ret
                      FROM supply_reason sr
                      JOIN supply_workflow sw
                        ON sw.id_del_reason = sr.id_supply_reason
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                    -- surgical supplies   
                WHEN 'SR_SUPPLIES_M039' THEN
                    SELECT nvl(pk_sr_clinical_info.get_surgical_procedure_desc(i_lang, i_prof, sw.id_context), l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                       AND rownum = 1;
                    -- supplies table  
                WHEN 'SR_SUPPLIES_M040' THEN
                    SELECT nvl(sw.cod_table, l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                       AND rownum = 1;
                    -- expiration date
                WHEN 'SUPPLIES_T129' THEN
                    SELECT nvl(pk_date_utils.dt_chr(i_lang, sw.dt_expiration, i_prof), l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                
                WHEN 'SUPPLIES_T132' THEN
                    SELECT nvl(sw.lot, l_empty)
                      INTO l_ret
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = i_id_sw
                       AND rownum = 1;
                WHEN 'SR_SUPPLIES_M047' THEN
                    BEGIN
                        SELECT ssc.qty_added
                          INTO l_ret
                          FROM sr_supply_relation ssr
                          JOIN sr_supply_count ssc
                            ON ssr.id_sr_supply_count = ssc.id_sr_supply_count
                         WHERE ssr.id_supply_workflow = i_id_sw
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_ret := l_empty;
                    END;
                WHEN 'SR_SUPPLIES_M048' THEN
                    BEGIN
                        SELECT nvl(ssc.qty_final_count, sw.quantity)
                          INTO l_ret
                          FROM supply_workflow sw
                          LEFT JOIN sr_supply_relation ssr
                            ON sw.id_supply_workflow = ssr.id_supply_workflow
                          LEFT JOIN sr_supply_count ssc
                            ON ssr.id_sr_supply_count = ssc.id_sr_supply_count
                         WHERE sw.id_supply_workflow = i_id_sw
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_ret := l_empty;
                    END;
                ELSE
                    l_ret := '';
            END CASE;
        
            RETURN l_ret;
        END inner_get_from_sw;
    
        FUNCTION inner_get_from_sw_hist RETURN VARCHAR2 IS
        BEGIN
            CASE i_code_msg
            -- professional
                WHEN 'SUPPLIES_T100' THEN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, swh.id_professional)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- supply name
                WHEN 'SUPPLIES_T101' THEN
                    SELECT pk_translation.get_translation(i_lang, s.code_supply)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                      JOIN supply s
                        ON swh.id_supply = s.id_supply
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- supply location
                WHEN 'SUPPLIES_T102' THEN
                    SELECT pk_translation.get_translation(i_lang, s.code_supply_location)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                      JOIN supply_location s
                        ON swh.id_supply_location = s.id_supply_location
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- barcode
                WHEN 'SUPPLIES_T103' THEN
                    SELECT nvl(swh.barcode_req, l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- barcode scanned
                WHEN 'SUPPLIES_T104' THEN
                    SELECT nvl(swh.barcode_scanned, l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- quantity
                WHEN 'SUPPLIES_T105' THEN
                    SELECT nvl(swh.quantity, 1)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- request reason
                WHEN 'SUPPLIES_T106' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, sr.code_supply_reason), l_empty)
                      INTO l_ret
                      FROM supply_reason sr
                     RIGHT JOIN supply_workflow_hist swh
                        ON swh.id_req_reason = sr.id_supply_reason
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- request date
                WHEN 'SUPPLIES_T107' THEN
                    SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, swh.dt_request, i_prof)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- returned date                                    
                WHEN 'SUPPLIES_T108' THEN
                    SELECT CASE
                               WHEN swh.dt_returned = swh_a.original_return_date THEN
                                nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_returned, i_prof), l_na)
                               ELSE -- Flash Screen for Supply edition does not allow hours and minutes => dt_chr_tsz
                                nvl(pk_date_utils.dt_chr_tsz(i_lang, dt_returned, i_prof.institution, i_prof.software), l_na)
                           END
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     INNER JOIN (SELECT *
                                   FROM (SELECT id_supply_workflow_hist,
                                                id_supply_workflow,
                                                dt_returned AS original_return_date
                                           FROM supply_workflow_hist
                                          WHERE id_supply_workflow =
                                                (SELECT id_supply_workflow
                                                   FROM supply_workflow_hist
                                                  WHERE id_supply_workflow_hist = i_id_sw)
                                          ORDER BY 1 ASC)
                                  WHERE rownum = 1) swh_a
                        ON swh_a.id_supply_workflow = swh.id_supply_workflow
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- notes
                WHEN 'SUPPLIES_T109' THEN
                    SELECT nvl(swh.notes, l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- cancel prof
                WHEN 'SUPPLIES_T110' THEN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, swh.id_prof_cancel)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- cancel date
                WHEN 'SUPPLIES_T111' THEN
                    SELECT nvl(pk_date_utils.dt_chr_date_hour_tsz(i_lang, swh.dt_cancel, i_prof), l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- cancel notes
                WHEN 'SUPPLIES_T112' THEN
                    SELECT decode(length(swh.notes_cancel), 0, l_empty, swh.notes_cancel)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- cancel reason
                WHEN 'SUPPLIES_T113' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, swh.id_cancel_reason), l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                      JOIN cancel_reason cr
                        ON swh.id_cancel_reason = cr.id_cancel_reason
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- rejection notes
                WHEN 'SUPPLIES_T114' THEN
                    SELECT nvl(swh.notes_reject, l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- rejection date
                WHEN 'SUPPLIES_T115' THEN
                    SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, swh.dt_reject, i_prof)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- rejection prof
                WHEN 'SUPPLIES_T116' THEN
                    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, swh.id_prof_reject)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- return reason
                WHEN 'SUPPLIES_T125' THEN
                    SELECT nvl(pk_translation.get_translation(i_lang, sr.code_supply_reason), l_empty)
                      INTO l_ret
                      FROM supply_reason sr
                      JOIN supply_workflow_hist swh
                        ON swh.id_del_reason = sr.id_supply_reason
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- surgical supplies   
                WHEN 'SR_SUPPLIES_M039' THEN
                    SELECT nvl(pk_sr_clinical_info.get_surgical_procedure_desc(i_lang, i_prof, swh.id_context), l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                       AND rownum = 1;
                    -- supplies table  
                WHEN 'SR_SUPPLIES_M040' THEN
                    SELECT nvl(swh.cod_table, l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND swh.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                       AND rownum = 1;
                    -- expiration date
                WHEN 'SUPPLIES_T129' THEN
                    SELECT nvl(pk_date_utils.dt_chr(i_lang, swh.dt_expiration, i_prof), l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                    -- lot                 
                WHEN 'SUPPLIES_T132' THEN
                    SELECT nvl(swh.lot, l_empty)
                      INTO l_ret
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow_hist = i_id_sw
                       AND rownum = 1;
                ELSE
                    l_ret := '';
            END CASE;
        
            RETURN l_ret;
        END inner_get_from_sw_hist;
    
    BEGIN
        CASE i_source
            WHEN 'SUPPLY_WORKFLOW' THEN
                RETURN inner_get_from_sw;
            WHEN 'SUPPLY_WORKFLOW_HIST' THEN
                RETURN inner_get_from_sw_hist;
            ELSE
                RETURN '';
        END CASE;
    END get_supply_workflow_col_value;

    FUNCTION get_item_count
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_supply_type   IN supply.id_supply_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        o_supply_prof      OUT PLS_INTEGER,
        o_supply_dept      OUT PLS_INTEGER,
        o_dept             OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_flg_type IS NOT NULL
        THEN
        
            g_error := 'i_lang =' || i_lang || ', i_prof.id=' || i_prof.id || ', i_prof.institution=' ||
                       i_prof.institution || ', i_prof.software=' || i_prof.software || ', i_id_supply_area=' ||
                       i_id_supply_area || ', i_episode=' || i_episode || ', i_consumption_type=' || i_consumption_type ||
                       ', i_flg_type=' || i_flg_type;
            IF i_id_supply IS NOT NULL
            THEN
            
                IF i_id_supply_type IS NOT NULL
                THEN
                
                    g_error := 'o_supply_prof';
                    SELECT COUNT(*)
                      INTO o_supply_prof
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE ssi.id_institution = nvl(i_id_inst_dest, i_prof.institution)
                       AND ssi.id_software = nvl2(i_id_inst_dest, pk_sr_planning.g_software_oris, i_prof.software)
                       AND ssi.id_professional = i_prof.id
                       AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                       AND s.flg_type = i_flg_type
                       AND s.id_supply = i_id_supply
                       AND s.id_supply_type = i_id_supply_type
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    g_error := 'o_dept';
                    IF i_episode IS NOT NULL
                       AND i_id_inst_dest IS NULL
                    THEN
                        SELECT e.id_dept_requested
                          INTO o_dept
                          FROM episode e
                         WHERE e.id_episode = i_episode;
                    
                        g_error := 'o_supply_dept';
                        SELECT COUNT(*)
                          INTO o_supply_dept
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND ssi.id_dept = o_dept
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND s.id_supply = i_id_supply
                           AND s.id_supply_type = i_id_supply_type
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                    ELSE
                        o_supply_dept := 0;
                    END IF;
                ELSE
                
                    g_error := 'o_supply_prof';
                    SELECT COUNT(*)
                      INTO o_supply_prof
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE ssi.id_institution = nvl(i_id_inst_dest, i_prof.institution)
                       AND ssi.id_software = nvl2(i_id_inst_dest, pk_sr_planning.g_software_oris, i_prof.software)
                       AND ssi.id_professional = i_prof.id
                       AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                       AND s.flg_type = i_flg_type
                       AND s.id_supply = i_id_supply
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    g_error := 'o_dept';
                    IF i_episode IS NOT NULL
                       AND i_id_inst_dest IS NULL
                    THEN
                        SELECT e.id_dept_requested
                          INTO o_dept
                          FROM episode e
                         WHERE e.id_episode = i_episode;
                    
                        g_error := 'o_supply_dept';
                        SELECT COUNT(*)
                          INTO o_supply_dept
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND ssi.id_dept = o_dept
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND s.id_supply = i_id_supply
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                    ELSE
                        o_supply_dept := 0;
                    END IF;
                END IF;
            
            ELSE
            
                IF i_id_supply_type IS NOT NULL
                THEN
                    g_error := 'o_supply_prof';
                    SELECT COUNT(*)
                      INTO o_supply_prof
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE ssi.id_institution = nvl(i_id_inst_dest, i_prof.institution)
                       AND ssi.id_software = nvl2(i_id_inst_dest, pk_sr_planning.g_software_oris, i_prof.software)
                       AND ssi.id_professional = i_prof.id
                       AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                       AND s.flg_type = i_flg_type
                       AND s.id_supply_type = i_id_supply_type
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    g_error := 'o_dept';
                    IF i_episode IS NOT NULL
                       AND i_id_inst_dest IS NULL
                    THEN
                        SELECT e.id_dept_requested
                          INTO o_dept
                          FROM episode e
                         WHERE e.id_episode = i_episode;
                    
                        g_error := 'o_supply_dept';
                        SELECT COUNT(*)
                          INTO o_supply_dept
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND ssi.id_dept = o_dept
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND s.id_supply_type = i_id_supply_type
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                    ELSE
                        o_supply_dept := 0;
                    END IF;
                ELSE
                
                    g_error := 'o_supply_prof';
                    SELECT COUNT(*)
                      INTO o_supply_prof
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE ssi.id_institution = nvl(i_id_inst_dest, i_prof.institution)
                       AND ssi.id_software = nvl2(i_id_inst_dest, pk_sr_planning.g_software_oris, i_prof.software)
                       AND ssi.id_professional = i_prof.id
                       AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                       AND s.flg_type = i_flg_type
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    g_error := 'o_dept';
                    IF i_episode IS NOT NULL
                       AND i_id_inst_dest IS NULL
                    THEN
                        SELECT e.id_dept_requested
                          INTO o_dept
                          FROM episode e
                         WHERE e.id_episode = i_episode;
                    
                        g_error := 'o_supply_dept';
                        SELECT COUNT(*)
                          INTO o_supply_dept
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND ssi.id_dept = o_dept
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                    ELSE
                        o_supply_dept := 0;
                    END IF;
                END IF;
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
                                              'GET_ITEM_COUNT',
                                              o_error);
            RETURN FALSE;
    END get_item_count;

    FUNCTION get_supply_info
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
        o_supply           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_prof PLS_INTEGER;
        l_count_dept PLS_INTEGER;
        l_dept       NUMBER;
        l_domain     VARCHAR2(200);
        l_nr_avail   sys_message.desc_message%TYPE;
    
    BEGIN
    
        IF i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
        THEN
            l_domain := 'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR';
        ELSE
            l_domain := 'SUPPLY_SOFT_INST.FLG_CONS_TYPE';
        END IF;
    
        IF i_id_inst_dest IS NULL
        THEN
            IF i_flg_type IS NOT NULL
            THEN
                g_error := 'CALL GET_ITEM_COUNT';
                IF NOT get_item_count(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_id_supply_area   => i_id_supply_area,
                                      i_episode          => i_episode,
                                      i_consumption_type => i_consumption_type,
                                      i_flg_type         => i_flg_type,
                                      i_id_supply        => i_id_supply,
                                      i_id_supply_type   => i_id_supply_type,
                                      i_id_inst_dest     => i_id_inst_dest,
                                      o_supply_prof      => l_count_prof,
                                      o_supply_dept      => l_count_dept,
                                      o_dept             => l_dept,
                                      o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error    := 'GET L_NR_AVAIL';
                l_nr_avail := pk_message.get_message(i_lang      => i_lang,
                                                     i_code_mess => pk_act_therap_constant.g_msg_avail_units);
            
                IF l_count_prof > 0
                THEN
                    g_error := 'OPEN O_SUPPLY 1';
                    OPEN o_supply FOR
                        SELECT t.*,
                               REPLACE(l_nr_avail, pk_act_therap_constant.g_1st_replace, nr_units_avail) nr_units_avail_desc,
                               i_id_supply_area id_supply_area
                          FROM (SELECT DISTINCT s.id_supply,
                                                pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       s.id_supply_type) id_supply_type,
                                                pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                                s.flg_type,
                                                ssi.quantity,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       ssi.id_unit_measure) id_unit_measure,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       s.id_supply_type,
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      ssi.id_unit_measure)) desc_unit_measure,
                                                ssi.flg_reusable,
                                                pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_REUSABLE',
                                                                        ssi.flg_reusable,
                                                                        i_lang) desc_flg_reusable,
                                                ssi.flg_cons_type flg_consumption_type,
                                                pk_sysdomain.get_domain(l_domain, ssi.flg_cons_type, i_lang) desc_consumption_type,
                                                pk_supplies_core.get_attributes(i_lang,
                                                                                i_prof,
                                                                                ssa.id_supply_area,
                                                                                s.id_supply,
                                                                                i_id_inst_dest) desc_supply_attrib,
                                                ssi.total_avail_quantity -
                                                get_nr_loaned_units(i_lang,
                                                                    i_prof,
                                                                    ssa.id_supply_area,
                                                                    s.id_supply,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    i_id_inst_dest) nr_units_avail,
                                                ssi.id_supply_soft_inst,
                                                ssi.flg_editable,
                                                loc.id_supply_location,
                                                pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                                                CASE
                                                     WHEN i_flg_type = 'K' THEN
                                                      pk_supplies_core.get_supply_kit_info(i_lang,
                                                                                           i_prof,
                                                                                           ssa.id_supply_area,
                                                                                           i_episode,
                                                                                           i_consumption_type,
                                                                                           s.id_supply,
                                                                                           i_id_inst_dest)
                                                 END desc_supply_kit
                                  FROM supply_soft_inst ssi
                                 INNER JOIN supply s
                                    ON ssi.id_supply = s.id_supply
                                   AND s.flg_available = pk_supplies_constant.g_yes
                                  LEFT JOIN supply_type st
                                    ON st.id_supply_type = s.id_supply_type
                                   AND st.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_sup_area ssa
                                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                   AND ssa.flg_available = pk_supplies_constant.g_yes
                                   AND ssa.id_supply_area = i_id_supply_area
                                 INNER JOIN (SELECT sld.id_supply_location,
                                                   sld.id_supply_soft_inst,
                                                   sl.code_supply_location
                                              FROM supply_loc_default sld
                                             INNER JOIN supply_location sl
                                                ON sld.id_supply_location = sl.id_supply_location
                                               AND sld.flg_default = pk_supplies_constant.g_yes) loc
                                    ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                                 WHERE ssi.id_institution = i_prof.institution
                                   AND ssi.id_software = i_prof.software
                                   AND ssi.id_professional = i_prof.id
                                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                                   AND s.flg_type = i_flg_type
                                   AND (s.id_supply_type = i_id_supply_type OR i_id_supply_type IS NULL)
                                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                                 ORDER BY 2) t;
                
                ELSIF (l_count_dept > 0 AND l_count_prof = 0 AND i_id_inst_dest IS NULL)
                THEN
                    g_error := 'OPEN O_SUPPLY 2';
                    OPEN o_supply FOR
                        SELECT t.*,
                               REPLACE(l_nr_avail, pk_act_therap_constant.g_1st_replace, nr_units_avail) nr_units_avail_desc,
                               i_id_supply_area id_supply_area
                          FROM (SELECT DISTINCT s.id_supply,
                                                pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       s.id_supply_type) id_supply_type,
                                                pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                                s.flg_type,
                                                ssi.quantity,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       ssi.id_unit_measure) id_unit_measure,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       s.id_supply_type,
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      ssi.id_unit_measure)) desc_unit_measure,
                                                ssi.flg_reusable,
                                                pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_REUSABLE',
                                                                        ssi.flg_reusable,
                                                                        i_lang) desc_flg_reusable,
                                                ssi.flg_cons_type flg_consumption_type,
                                                pk_sysdomain.get_domain(l_domain, ssi.flg_cons_type, i_lang) desc_consumption_type,
                                                pk_supplies_core.get_attributes(i_lang,
                                                                                i_prof,
                                                                                ssa.id_supply_area,
                                                                                s.id_supply,
                                                                                i_id_inst_dest) desc_supply_attrib,
                                                ssi.total_avail_quantity -
                                                get_nr_loaned_units(i_lang,
                                                                    i_prof,
                                                                    ssa.id_supply_area,
                                                                    s.id_supply,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    i_id_inst_dest) nr_units_avail,
                                                ssi.id_supply_soft_inst,
                                                ssi.flg_editable,
                                                loc.id_supply_location,
                                                pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                                                CASE
                                                     WHEN i_flg_type = 'K' THEN
                                                      pk_supplies_core.get_supply_kit_info(i_lang,
                                                                                           i_prof,
                                                                                           ssa.id_supply_area,
                                                                                           i_episode,
                                                                                           i_consumption_type,
                                                                                           s.id_supply,
                                                                                           i_id_inst_dest)
                                                 END desc_supply_kit
                                  FROM supply_soft_inst ssi
                                 INNER JOIN supply s
                                    ON ssi.id_supply = s.id_supply
                                   AND s.flg_available = pk_supplies_constant.g_yes
                                  LEFT JOIN supply_type st
                                    ON st.id_supply_type = s.id_supply_type
                                   AND st.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_sup_area ssa
                                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                   AND ssa.flg_available = pk_supplies_constant.g_yes
                                   AND ssa.id_supply_area = i_id_supply_area
                                 INNER JOIN (SELECT sld.id_supply_location,
                                                   sld.id_supply_soft_inst,
                                                   sl.code_supply_location
                                              FROM supply_loc_default sld
                                             INNER JOIN supply_location sl
                                                ON sld.id_supply_location = sl.id_supply_location
                                               AND sld.flg_default = pk_supplies_constant.g_yes) loc
                                    ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                                 WHERE ssi.id_institution = i_prof.institution
                                   AND ssi.id_software = i_prof.software
                                   AND ssi.id_dept = l_dept
                                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                                   AND s.flg_type = i_flg_type
                                   AND (s.id_supply_type = i_id_supply_type OR i_id_supply_type IS NULL)
                                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                                 ORDER BY 2) t;
                
                ELSIF (l_count_dept = 0 AND l_count_prof = 0)
                THEN
                    g_error := 'OPEN O_SUPPLY 3';
                    OPEN o_supply FOR
                        SELECT t.*,
                               REPLACE(l_nr_avail, pk_act_therap_constant.g_1st_replace, nr_units_avail) nr_units_avail_desc,
                               i_id_supply_area id_supply_area
                          FROM (SELECT DISTINCT s.id_supply,
                                                pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       s.id_supply_type) id_supply_type,
                                                pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                                s.flg_type,
                                                ssi.quantity,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       ssi.id_unit_measure) id_unit_measure,
                                                decode(i_flg_type,
                                                       pk_supplies_constant.g_supply_kit_type,
                                                       NULL,
                                                       pk_supplies_constant.g_supply_set_type,
                                                       NULL,
                                                       s.id_supply_type,
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      ssi.id_unit_measure)) desc_unit_measure,
                                                ssi.flg_reusable,
                                                pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_REUSABLE',
                                                                        ssi.flg_reusable,
                                                                        i_lang) desc_flg_reusable,
                                                ssi.flg_cons_type flg_consumption_type,
                                                pk_sysdomain.get_domain(l_domain, ssi.flg_cons_type, i_lang) desc_consumption_type,
                                                pk_supplies_core.get_attributes(i_lang,
                                                                                i_prof,
                                                                                ssa.id_supply_area,
                                                                                s.id_supply,
                                                                                i_id_inst_dest) desc_supply_attrib,
                                                ssi.total_avail_quantity -
                                                get_nr_loaned_units(i_lang,
                                                                    i_prof,
                                                                    ssa.id_supply_area,
                                                                    s.id_supply,
                                                                    i_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    i_id_inst_dest) nr_units_avail,
                                                ssi.id_supply_soft_inst,
                                                ssi.flg_editable,
                                                loc.id_supply_location,
                                                pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                                                rank() over(PARTITION BY s.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC) precedence_level,
                                                CASE
                                                     WHEN i_flg_type = 'K' THEN
                                                      pk_supplies_core.get_supply_kit_info(i_lang,
                                                                                           i_prof,
                                                                                           ssa.id_supply_area,
                                                                                           i_episode,
                                                                                           i_consumption_type,
                                                                                           s.id_supply,
                                                                                           i_id_inst_dest)
                                                 END desc_supply_kit
                                  FROM supply_soft_inst ssi
                                 INNER JOIN supply s
                                    ON ssi.id_supply = s.id_supply
                                   AND s.flg_available = pk_supplies_constant.g_yes
                                  LEFT JOIN supply_type st
                                    ON st.id_supply_type = s.id_supply_type
                                   AND st.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_sup_area ssa
                                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                   AND ssa.flg_available = pk_supplies_constant.g_yes
                                   AND ssa.id_supply_area = i_id_supply_area
                                 INNER JOIN (SELECT sld.id_supply_location,
                                                   sld.id_supply_soft_inst,
                                                   sl.code_supply_location
                                              FROM supply_loc_default sld
                                             INNER JOIN supply_location sl
                                                ON sld.id_supply_location = sl.id_supply_location
                                               AND sld.flg_default = pk_supplies_constant.g_yes) loc
                                    ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                                 WHERE ssi.id_institution = i_prof.institution
                                   AND ssi.id_software = i_prof.software
                                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                                   AND s.flg_type = i_flg_type
                                   AND (s.id_supply_type = i_id_supply_type OR i_id_supply_type IS NULL)
                                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                                 ORDER BY 2) t
                         WHERE t.precedence_level = 1;
                
                END IF;
            END IF;
        ELSE
            g_error := 'OPEN O_SUPPLY 4';
            OPEN o_supply FOR
                SELECT t.*,
                       REPLACE(l_nr_avail, pk_act_therap_constant.g_1st_replace, nr_units_avail) nr_units_avail_desc,
                       i_id_supply_area id_supply_area
                  FROM (SELECT DISTINCT s.id_supply,
                                        pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                                        decode(i_flg_type,
                                               pk_supplies_constant.g_supply_kit_type,
                                               NULL,
                                               pk_supplies_constant.g_supply_set_type,
                                               NULL,
                                               s.id_supply_type) id_supply_type,
                                        pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                        s.flg_type,
                                        ssi.quantity,
                                        decode(i_flg_type,
                                               pk_supplies_constant.g_supply_kit_type,
                                               NULL,
                                               pk_supplies_constant.g_supply_set_type,
                                               NULL,
                                               ssi.id_unit_measure) id_unit_measure,
                                        decode(i_flg_type,
                                               pk_supplies_constant.g_supply_kit_type,
                                               NULL,
                                               pk_supplies_constant.g_supply_set_type,
                                               NULL,
                                               s.id_supply_type,
                                               pk_translation.get_translation(i_lang,
                                                                              'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                              ssi.id_unit_measure)) desc_unit_measure,
                                        ssi.flg_reusable,
                                        pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_REUSABLE',
                                                                ssi.flg_reusable,
                                                                i_lang) desc_flg_reusable,
                                        ssi.flg_cons_type flg_consumption_type,
                                        pk_sysdomain.get_domain(l_domain, ssi.flg_cons_type, i_lang) desc_consumption_type,
                                        pk_supplies_core.get_attributes(i_lang,
                                                                        i_prof,
                                                                        ssa.id_supply_area,
                                                                        s.id_supply,
                                                                        i_id_inst_dest) desc_supply_attrib,
                                        ssi.total_avail_quantity -
                                        get_nr_loaned_units(i_lang,
                                                            i_prof,
                                                            ssa.id_supply_area,
                                                            s.id_supply,
                                                            i_episode,
                                                            NULL,
                                                            NULL,
                                                            i_id_inst_dest) nr_units_avail,
                                        ssi.id_supply_soft_inst,
                                        ssi.flg_editable,
                                        loc.id_supply_location,
                                        pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                                        rank() over(PARTITION BY s.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC) precedence_level,
                                        CASE
                                             WHEN i_flg_type = 'K' THEN
                                              pk_supplies_core.get_supply_kit_info(i_lang,
                                                                                   i_prof,
                                                                                   ssa.id_supply_area,
                                                                                   i_episode,
                                                                                   i_consumption_type,
                                                                                   s.id_supply,
                                                                                   i_id_inst_dest)
                                         END desc_supply_kit
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                          LEFT JOIN supply_type st
                            ON st.id_supply_type = s.id_supply_type
                           AND st.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         INNER JOIN (SELECT sld.id_supply_location, sld.id_supply_soft_inst, sl.code_supply_location
                                      FROM supply_loc_default sld
                                     INNER JOIN supply_location sl
                                        ON sld.id_supply_location = sl.id_supply_location
                                       AND sld.flg_default = pk_supplies_constant.g_yes) loc
                            ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                         WHERE ssi.id_institution = i_id_inst_dest
                           AND ssi.id_software = pk_sr_planning.g_software_oris
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND (s.id_supply_type = i_id_supply_type OR i_id_supply_type IS NULL)
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                         ORDER BY 2) t
                 WHERE t.precedence_level = 1;
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
                                              'GET_SUPPLY_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_supply);
            RETURN FALSE;
    END get_supply_info;

    FUNCTION get_supply_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_supply_type      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_prof PLS_INTEGER;
        l_count_dept PLS_INTEGER;
        l_dept       NUMBER;
    
    BEGIN
    
        IF i_id_inst_dest IS NULL
        THEN
        
            IF i_lang IS NOT NULL
               AND i_prof.id IS NOT NULL
               AND i_prof.institution IS NOT NULL
               AND i_prof.software IS NOT NULL
               AND i_flg_type IS NOT NULL
            
            THEN
            
                g_error := ' IF NOT get_item_count';
                IF NOT get_item_count(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_id_supply_area   => i_id_supply_area,
                                      i_episode          => i_episode,
                                      i_consumption_type => i_consumption_type,
                                      i_flg_type         => i_flg_type,
                                      i_id_supply        => NULL,
                                      i_id_supply_type   => NULL,
                                      i_id_inst_dest     => i_id_inst_dest,
                                      o_supply_prof      => l_count_prof,
                                      o_supply_dept      => l_count_dept,
                                      o_dept             => l_dept,
                                      o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_count_prof > 0
                THEN
                
                    g_error := 'o_supply_type';
                    OPEN o_supply_type FOR
                        SELECT DISTINCT id_supply_type,
                                        desc_supply_type,
                                        get_supply_child_type_count(i_lang,
                                                                    i_prof,
                                                                    i_id_supply_area,
                                                                    i_consumption_type,
                                                                    i_flg_type,
                                                                    id_supply_type,
                                                                    l_count_prof,
                                                                    l_count_dept,
                                                                    l_dept,
                                                                    i_id_inst_dest) flg_child,
                                        pk_supplies_core.get_parent_supply_type(i_lang, id_supply_type) flg_type
                          FROM (SELECT st.id_supply_type,
                                       pk_translation.get_translation(i_lang,
                                                                      'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' ||
                                                                      st.id_supply_type) desc_supply_type,
                                       s.flg_type
                                  FROM supply_soft_inst ssi
                                 INNER JOIN supply s
                                    ON ssi.id_supply = s.id_supply
                                   AND s.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_type st
                                    ON st.id_supply_type = s.id_supply_type
                                   AND st.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_sup_area ssa
                                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                   AND ssa.flg_available = pk_supplies_constant.g_yes
                                   AND ssa.id_supply_area = i_id_supply_area
                                 WHERE ssi.id_institution = i_prof.institution
                                   AND ssi.id_software = i_prof.software
                                   AND ssi.id_professional = i_prof.id
                                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                                   AND s.flg_type = i_flg_type
                                   AND rownum > 0)
                         WHERE desc_supply_type IS NOT NULL
                         ORDER BY 2;
                
                ELSIF (l_count_dept > 0 AND l_count_prof = 0 AND i_id_inst_dest IS NULL)
                THEN
                
                    g_error := 'o_supply_type';
                    OPEN o_supply_type FOR
                        SELECT id_supply_type,
                               pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || id_supply_type) desc_supply_type,
                               get_supply_child_type_count(i_lang,
                                                           i_prof,
                                                           i_id_supply_area,
                                                           i_consumption_type,
                                                           i_flg_type,
                                                           id_supply_type,
                                                           l_count_prof,
                                                           l_count_dept,
                                                           l_dept,
                                                           i_id_inst_dest) flg_child,
                               flg_type
                          FROM (SELECT DISTINCT get_parent_supply_type(i_lang, st.id_supply_type) id_supply_type,
                                                s.flg_type
                                  FROM supply_soft_inst ssi
                                 INNER JOIN supply s
                                    ON ssi.id_supply = s.id_supply
                                   AND s.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_type st
                                    ON st.id_supply_type = s.id_supply_type
                                   AND st.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_sup_area ssa
                                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                   AND ssa.flg_available = pk_supplies_constant.g_yes
                                   AND ssa.id_supply_area = i_id_supply_area
                                 WHERE ssi.id_institution = i_prof.institution
                                   AND ssi.id_software = i_prof.software
                                   AND ssi.id_dept = l_dept
                                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                                   AND s.flg_type = i_flg_type
                                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL)
                         WHERE pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || id_supply_type) IS NOT NULL
                         ORDER BY 2;
                
                ELSIF (l_count_dept = 0 AND l_count_prof = 0)
                THEN
                
                    g_error := 'o_supply_type';
                    OPEN o_supply_type FOR
                        SELECT id_supply_type,
                               pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || id_supply_type) desc_supply_type,
                               get_supply_child_type_count(i_lang,
                                                           i_prof,
                                                           i_id_supply_area,
                                                           i_consumption_type,
                                                           i_flg_type,
                                                           id_supply_type,
                                                           l_count_prof,
                                                           l_count_dept,
                                                           l_dept,
                                                           i_id_inst_dest) flg_child,
                               flg_type
                          FROM (SELECT DISTINCT get_parent_supply_type(i_lang, st.id_supply_type) id_supply_type,
                                                s.flg_type
                                  FROM supply_soft_inst ssi
                                 INNER JOIN supply s
                                    ON ssi.id_supply = s.id_supply
                                   AND s.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_type st
                                    ON st.id_supply_type = s.id_supply_type
                                   AND st.flg_available = pk_supplies_constant.g_yes
                                 INNER JOIN supply_sup_area ssa
                                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                   AND ssa.flg_available = pk_supplies_constant.g_yes
                                   AND ssa.id_supply_area = i_id_supply_area
                                 WHERE ssi.id_institution = i_prof.institution
                                   AND ssi.id_software = i_prof.software
                                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                                   AND s.flg_type = i_flg_type
                                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL)
                         WHERE pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || id_supply_type) IS NOT NULL
                         ORDER BY 2;
                END IF;
            END IF;
        ELSE
        
            OPEN o_supply_type FOR
                SELECT id_supply_type,
                       pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || id_supply_type) desc_supply_type,
                       get_supply_child_type_count(i_lang,
                                                   i_prof,
                                                   i_id_supply_area,
                                                   i_consumption_type,
                                                   i_flg_type,
                                                   id_supply_type,
                                                   l_count_prof,
                                                   l_count_dept,
                                                   l_dept,
                                                   i_id_inst_dest) flg_child,
                       flg_type
                  FROM (SELECT DISTINCT get_parent_supply_type(i_lang, st.id_supply_type) id_supply_type, s.flg_type
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_type st
                            ON st.id_supply_type = s.id_supply_type
                           AND st.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         WHERE ssi.id_institution = i_id_inst_dest
                           AND ssi.id_software = pk_sr_planning.g_software_oris
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL)
                 WHERE pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || id_supply_type) IS NOT NULL
                 ORDER BY 2;
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
                                              'GET_SUPPLY_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_supply_type);
            RETURN FALSE;
    END get_supply_type;

    FUNCTION get_parent_supply_type
    (
        i_lang        IN language.id_language%TYPE,
        i_supply_type IN supply_type.id_supply_type%TYPE
    ) RETURN NUMBER IS
        o_id_parent_supply_type supply_type.id_supply_type%TYPE;
        o_error                 t_error_out;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_supply_type IS NOT NULL
        THEN
        
            g_error := 'o_id_parent_supply_type';
            SELECT nvl(get_parent_supply_type(i_lang, st.id_parent), st.id_supply_type)
              INTO o_id_parent_supply_type
              FROM supply_type st
             WHERE st.id_supply_type = i_supply_type;
        END IF;
    
        RETURN o_id_parent_supply_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PARENT_SUPPLY_TYPE',
                                              o_error);
            RETURN 0;
    END get_parent_supply_type;

    FUNCTION get_supply_item
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_supply           IN supply.id_supply%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        o_supply_items     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dept                episode.id_dept_requested%TYPE;
        l_id_supply_soft_inst supply_soft_inst.id_supply_soft_inst%TYPE;
        l_domain              sys_domain.code_domain%TYPE;
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
            g_error := 'GET id_dept_requested';
            SELECT e.id_dept_requested
              INTO l_dept
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        ELSE
            l_dept := 0;
        END IF;
    
        IF i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
        THEN
            l_domain := 'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR';
        ELSE
            l_domain := 'SUPPLY_SOFT_INST.FLG_CONS_TYPE';
        END IF;
    
        IF i_lang IS NOT NULL
           AND i_supply IS NOT NULL
        THEN
        
            g_error               := 'GET id_supply_sof_inst';
            l_id_supply_soft_inst := get_id_supply_soft_inst(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_id_supply_area   => i_id_supply_area,
                                                             i_id_dept          => l_dept,
                                                             i_consumption_type => i_consumption_type,
                                                             i_id_supply        => i_supply,
                                                             i_id_inst_dest     => i_id_inst_dest);
        
            g_error := 'o_supply_items';
            OPEN o_supply_items FOR
                SELECT DISTINCT sr.id_supply_item id_supply,
                                pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                                NULL id_supply_type,
                                s.flg_type,
                                sr.quantity,
                                sr.id_unit_measure,
                                pk_translation.get_translation(i_lang,
                                                               'UNIT_MEASURE.CODE_UNIT_MEASURE.' || sr.id_unit_measure) desc_unit_measure,
                                ssi.flg_reusable,
                                pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_REUSABLE', ssi.flg_reusable, i_lang) desc_flg_reusable,
                                pk_supplies_core.get_consumption_type(i_lang,
                                                                      i_prof,
                                                                      i_id_supply_area,
                                                                      sr.id_supply_item,
                                                                      i_id_inst_dest) flg_consumption_type,
                                pk_sysdomain.get_domain(l_domain,
                                                        pk_supplies_core.get_consumption_type(i_lang,
                                                                                              i_prof,
                                                                                              i_id_supply_area,
                                                                                              sr.id_supply_item,
                                                                                              i_id_inst_dest),
                                                        i_lang) desc_consumption_type,
                                pk_supplies_core.get_attributes(i_lang,
                                                                NULL,
                                                                i_id_supply_area,
                                                                sr.id_supply,
                                                                i_id_inst_dest) desc_supply_attrib,
                                l_id_supply_soft_inst id_supply_soft_inst,
                                loc.id_supply_location,
                                pk_translation.get_translation(i_lang, loc.code_supply_location) desc_supply_location,
                                i_id_supply_area id_supply_area
                  FROM supply_relation sr
                  JOIN supply s
                    ON s.id_supply = sr.id_supply_item
                   AND s.flg_available = pk_supplies_constant.g_yes
                 INNER JOIN (SELECT sld.id_supply_location, sld.id_supply_soft_inst, sl.code_supply_location
                               FROM supply_loc_default sld
                              INNER JOIN supply_location sl
                                 ON sld.id_supply_location = sl.id_supply_location
                                AND sld.flg_default = pk_supplies_constant.g_yes) loc
                    ON loc.id_supply_soft_inst = l_id_supply_soft_inst
                  JOIN supply_soft_inst ssi
                    ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                  JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                  JOIN supply_soft_inst ssis
                    ON ssis.id_supply = s.id_supply
                  JOIN supply_sup_area ssas
                    ON ssas.id_supply_soft_inst = ssis.id_supply_soft_inst
                   AND ssa.id_supply_area = ssas.id_supply_area
                 WHERE sr.id_supply = i_supply
                   AND ssas.id_supply_area = i_id_supply_area
                   AND ssis.id_institution = i_prof.institution
                   AND ssis.id_software = i_prof.software
                 ORDER BY 2;
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
                                              'GET_SUPPLY_ITEM',
                                              o_error);
            pk_types.open_my_cursor(o_supply_items);
            RETURN FALSE;
    END get_supply_item;

    FUNCTION get_supply_child_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_supply_type      IN supply_type.id_supply_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_count_sun        OUT NUMBER,
        o_supply_type      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_prof PLS_INTEGER;
        l_count_dept PLS_INTEGER;
        l_dept       NUMBER;
        l_count_suns PLS_INTEGER;
    
        CURSOR c_supply_child(i_supply_type supply_type.id_supply_type%TYPE) IS
            SELECT DISTINCT st.id_supply_type
              FROM supply_type st
             WHERE st.id_parent = i_supply_type
               AND st.flg_available = pk_supplies_constant.g_yes;
    
        l_suns_ids   table_number;
        l_count_conf PLS_INTEGER;
        l_suns_conf  table_number := table_number();
        l_cont       PLS_INTEGER := 0;
    
    BEGIN
    
        IF i_id_inst_dest IS NULL
        THEN
        
            IF i_lang IS NOT NULL
               AND i_prof.id IS NOT NULL
               AND i_prof.institution IS NOT NULL
               AND i_prof.software IS NOT NULL
               AND i_flg_type IS NOT NULL
            
            THEN
                g_error := '  IF NOT get_item_count';
                IF NOT get_item_count(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_id_supply_area   => i_id_supply_area,
                                      i_episode          => i_episode,
                                      i_consumption_type => i_consumption_type,
                                      i_flg_type         => i_flg_type,
                                      i_id_supply        => NULL,
                                      i_id_supply_type   => NULL,
                                      i_id_inst_dest     => i_id_inst_dest,
                                      o_supply_prof      => l_count_prof,
                                      o_supply_dept      => l_count_dept,
                                      o_dept             => l_dept,
                                      o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_count_prof > 0
                THEN
                    g_error := 'l_count_suns';
                    SELECT COUNT(*)
                      INTO l_count_suns
                      FROM supply_type st
                     WHERE st.id_parent = i_supply_type
                       AND st.flg_available = pk_supplies_constant.g_yes;
                
                    IF l_count_suns > 0
                    THEN
                    
                        g_error := 'OPEN c_suns';
                        OPEN c_supply_child(i_supply_type);
                        FETCH c_supply_child BULK COLLECT
                            INTO l_suns_ids;
                        g_found := c_supply_child%NOTFOUND;
                        CLOSE c_supply_child;
                    
                        g_error := 'FOR i IN l_suns_ids.FIRST .. l_suns_ids.LAST';
                        FOR i IN l_suns_ids.first .. l_suns_ids.last
                        LOOP
                            SELECT COUNT(DISTINCT s.id_supply)
                              INTO l_count_conf
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND ssi.id_professional = i_prof.id
                               AND s.flg_type = i_flg_type
                               AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                        
                            g_error := 'IF l_count_conf > 0';
                            IF l_count_conf > 0
                            THEN
                            
                                l_cont := l_cont + 1;
                            
                                l_suns_conf.extend();
                                l_suns_conf(l_cont) := l_suns_ids(i);
                            ELSE
                                l_cont := l_cont;
                            END IF;
                        END LOOP;
                    
                        g_error := ' OPEN o_supply_type FOR';
                        OPEN o_supply_type FOR
                            SELECT DISTINCT st.id_supply_type,
                                            pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                            get_supply_child_type_count(i_lang,
                                                                        i_prof,
                                                                        i_id_supply_area,
                                                                        i_consumption_type,
                                                                        i_flg_type,
                                                                        id_supply_type,
                                                                        l_count_prof,
                                                                        l_count_dept,
                                                                        l_dept,
                                                                        i_id_inst_dest) flg_child,
                                            
                                            i_flg_type flg_type
                              FROM supply_type st
                             WHERE st.id_supply_type IN
                                   (SELECT column_value
                                      FROM TABLE(CAST(l_suns_conf AS table_number)))
                               AND st.flg_available = pk_supplies_constant.g_yes
                               AND pk_translation.get_translation(i_lang, st.code_supply_type) IS NOT NULL;
                    
                        o_count_sun := l_cont;
                    ELSE
                        o_count_sun := 0;
                        pk_types.open_my_cursor(o_supply_type);
                    END IF;
                
                ELSIF l_count_dept > 0
                      AND l_count_prof = 0
                      AND i_id_inst_dest IS NULL
                THEN
                
                    g_error := 'l_count_suns';
                    SELECT COUNT(*)
                      INTO l_count_suns
                      FROM supply_type st
                     WHERE st.id_parent = i_supply_type
                       AND st.flg_available = pk_supplies_constant.g_yes;
                
                    IF l_count_suns > 0
                    THEN
                    
                        g_error := 'OPEN c_suns';
                        OPEN c_supply_child(i_supply_type);
                        FETCH c_supply_child BULK COLLECT
                            INTO l_suns_ids;
                        g_found := c_supply_child%NOTFOUND;
                        CLOSE c_supply_child;
                    
                        g_error := 'FOR i IN l_suns_ids.FIRST .. l_suns_ids.LAST';
                        FOR i IN l_suns_ids.first .. l_suns_ids.last
                        LOOP
                            SELECT COUNT(DISTINCT s.id_supply)
                              INTO l_count_conf
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND ssi.id_dept = l_dept
                               AND s.flg_type = i_flg_type
                               AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                        
                            g_error := 'IF l_count_conf > 0';
                            IF l_count_conf > 0
                            THEN
                                l_cont := l_cont + 1;
                            
                                l_suns_conf.extend();
                                l_suns_conf(l_cont) := l_suns_ids(i);
                            ELSE
                                l_cont := l_cont;
                            END IF;
                        END LOOP;
                    
                        g_error := ' OPEN o_supply_type FOR';
                        OPEN o_supply_type FOR
                            SELECT DISTINCT st.id_supply_type,
                                            pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                            get_supply_child_type_count(i_lang,
                                                                        i_prof,
                                                                        i_id_supply_area,
                                                                        i_consumption_type,
                                                                        i_flg_type,
                                                                        id_supply_type,
                                                                        l_count_prof,
                                                                        l_count_dept,
                                                                        l_dept,
                                                                        i_id_inst_dest) flg_child,
                                            
                                            i_flg_type flg_type
                              FROM supply_type st
                             WHERE st.id_supply_type IN
                                   (SELECT column_value
                                      FROM TABLE(CAST(l_suns_conf AS table_number)))
                               AND st.flg_available = pk_supplies_constant.g_yes
                               AND pk_translation.get_translation(i_lang, st.code_supply_type) IS NOT NULL;
                    
                        o_count_sun := l_cont;
                    ELSE
                        o_count_sun := 0;
                        pk_types.open_my_cursor(o_supply_type);
                    END IF;
                
                ELSIF l_count_dept = 0
                      AND l_count_prof = 0
                THEN
                    g_error := 'l_count_suns';
                    SELECT COUNT(*)
                      INTO l_count_suns
                      FROM supply_type st
                     WHERE st.id_parent = i_supply_type
                       AND st.flg_available = pk_supplies_constant.g_yes;
                
                    IF l_count_suns > 0
                    THEN
                        g_error := 'OPEN c_suns';
                        OPEN c_supply_child(i_supply_type);
                        FETCH c_supply_child BULK COLLECT
                            INTO l_suns_ids;
                        g_found := c_supply_child%NOTFOUND;
                        CLOSE c_supply_child;
                    
                        g_error := 'FOR i IN l_suns_ids.FIRST .. l_suns_ids.LAST';
                        FOR i IN l_suns_ids.first .. l_suns_ids.last
                        LOOP
                        
                            SELECT COUNT(DISTINCT s.id_supply)
                              INTO l_count_conf
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND s.flg_type = i_flg_type
                               AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                        
                            g_error := 'IF l_count_conf > 0';
                            IF l_count_conf > 0
                            THEN
                            
                                l_cont := l_cont + 1;
                            
                                l_suns_conf.extend();
                                l_suns_conf(l_cont) := l_suns_ids(i);
                            ELSE
                                l_cont := l_cont;
                            END IF;
                        
                        END LOOP;
                    
                        g_error := ' OPEN o_supply_type FOR';
                        OPEN o_supply_type FOR
                            SELECT DISTINCT st.id_supply_type,
                                            pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                            get_supply_child_type_count(i_lang,
                                                                        i_prof,
                                                                        i_id_supply_area,
                                                                        i_consumption_type,
                                                                        i_flg_type,
                                                                        id_supply_type,
                                                                        l_count_prof,
                                                                        l_count_dept,
                                                                        l_dept,
                                                                        i_id_inst_dest) flg_child,
                                            i_flg_type flg_supply_type
                              FROM supply_type st
                             WHERE st.id_supply_type IN
                                   (SELECT column_value
                                      FROM TABLE(CAST(l_suns_conf AS table_number)))
                               AND st.flg_available = pk_supplies_constant.g_yes
                               AND pk_translation.get_translation(i_lang, st.code_supply_type) IS NOT NULL;
                    
                        o_count_sun := l_cont;
                    ELSE
                        o_count_sun := 0;
                    
                        OPEN o_supply_type FOR
                            SELECT NULL id_supply_type, NULL desc_supply_type, NULL flg_child, NULL flg_type
                              FROM dual;
                    END IF;
                END IF;
            END IF;
        ELSE
        
            g_error := 'l_count_suns';
            SELECT COUNT(*)
              INTO l_count_suns
              FROM supply_type st
             WHERE st.id_parent = i_supply_type
               AND st.flg_available = pk_supplies_constant.g_yes;
        
            IF l_count_suns > 0
            THEN
            
                g_error := 'OPEN c_suns';
                OPEN c_supply_child(i_supply_type);
                FETCH c_supply_child BULK COLLECT
                    INTO l_suns_ids;
                g_found := c_supply_child%NOTFOUND;
                CLOSE c_supply_child;
            
                g_error := 'FOR i IN l_suns_ids.FIRST .. l_suns_ids.LAST';
                FOR i IN l_suns_ids.first .. l_suns_ids.last
                LOOP
                
                    SELECT COUNT(DISTINCT s.id_supply)
                      INTO l_count_conf
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE ssi.id_institution = i_id_inst_dest
                       AND ssi.id_software = pk_sr_planning.g_software_oris
                       AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                       AND s.flg_type = i_flg_type
                       AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    g_error := 'IF l_count_conf > 0';
                    IF l_count_conf > 0
                    THEN
                    
                        l_cont := l_cont + 1;
                    
                        l_suns_conf.extend();
                        l_suns_conf(l_cont) := l_suns_ids(i);
                    ELSE
                        l_cont := l_cont;
                    END IF;
                
                END LOOP;
            
                g_error := ' OPEN o_supply_type FOR';
                OPEN o_supply_type FOR
                    SELECT DISTINCT st.id_supply_type,
                                    pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                                    get_supply_child_type_count(i_lang,
                                                                i_prof,
                                                                i_id_supply_area,
                                                                i_consumption_type,
                                                                i_flg_type,
                                                                id_supply_type,
                                                                l_count_prof,
                                                                l_count_dept,
                                                                l_dept,
                                                                i_id_inst_dest) flg_child,
                                    i_flg_type flg_type
                      FROM supply_type st
                     WHERE st.id_supply_type IN (SELECT column_value
                                                   FROM TABLE(CAST(l_suns_conf AS table_number)))
                       AND st.flg_available = pk_supplies_constant.g_yes
                       AND pk_translation.get_translation(i_lang, st.code_supply_type) IS NOT NULL;
            
                o_count_sun := l_cont;
            ELSE
                o_count_sun := 0;
            
                OPEN o_supply_type FOR
                    SELECT NULL id_supply_type, NULL desc_supply_type, NULL flg_child, NULL flg_type
                      FROM dual;
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
                                              'GET_SUPPLY_CHILD_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_supply_type);
            RETURN FALSE;
    END get_supply_child_type;

    FUNCTION get_prepared_by
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_prepared_by OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_category      category.flg_type%TYPE;
        l_flg_prof_prep VARCHAR2(200) := 'SUPPLY_REQUEST.FLG_PROF_PREP';
    
    BEGIN
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        
        THEN
            g_error    := 'GET CATEGORY';
            l_category := pk_prof_utils.get_category(i_lang, i_prof);
        
            g_error := 'o_delivery_reason';
            OPEN o_prepared_by FOR
                SELECT sd.desc_val,
                       sd.val,
                       decode(sd.val, l_category, pk_supplies_constant.g_yes, pk_alert_constant.g_no) flg_default
                  FROM sys_domain sd
                 WHERE sd.code_domain = l_flg_prof_prep
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND sd.flg_available = pk_supplies_constant.g_yes
                 ORDER BY sd.rank;
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
        l_supply_area supply_area.id_supply_area%TYPE;
        l_surg_proc   NUMBER := 0;
    BEGIN
    
        SELECT a.id_supply_area
          INTO l_supply_area
          FROM supply_workflow a
         WHERE a.id_supply_workflow = i_supply_workflow(1);
    
        IF l_supply_area = pk_supplies_constant.g_area_surgical_supplies
        THEN
        
            SELECT COUNT(*)
              INTO l_surg_proc
              FROM supply_workflow sw
             INNER JOIN sr_epis_interv sei
                ON sei.id_episode_context = sw.id_episode
               AND sei.flg_status != pk_alert_constant.g_cancelled
             WHERE sw.id_supply_workflow = i_supply_workflow(1);
        
            OPEN o_supply_workflow FOR
                SELECT sw.id_supply,
                       sw.id_supply_workflow,
                       sw.flg_status status,
                       pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                       pk_supplies_api_db.get_attributes(i_lang,
                                                         i_prof,
                                                         sw.id_supply_area,
                                                         s.id_supply,
                                                         NULL,
                                                         NULL,
                                                         sw.id_supply_workflow) desc_supply_attrib,
                       sw.id_supply_location,
                       pk_translation.get_translation(i_lang, sl.code_supply_location) desc_supply_location,
                       CASE
                            WHEN sw.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                                   pk_supplies_constant.g_sww_request_central,
                                                   pk_supplies_constant.g_sww_predefined) THEN
                             pk_supplies_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_edit_location,
                       sw.flg_cons_type,
                       pk_sysdomain.get_domain(decode(sw.id_supply_area,
                                                      pk_supplies_constant.g_area_surgical_supplies,
                                                      'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                      'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                               sw.flg_cons_type,
                                               i_lang) desc_cons_type,
                       CASE
                            WHEN sw.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                                   pk_supplies_constant.g_sww_request_central,
                                                   pk_supplies_constant.g_sww_prepared_pharmacist,
                                                   pk_supplies_constant.g_sww_validated,
                                                   pk_supplies_constant.g_sww_prepared_technician,
                                                   pk_supplies_constant.g_sww_rejected_technician,
                                                   pk_supplies_constant.g_sww_in_transit,
                                                   pk_supplies_constant.g_sww_transport_concluded,
                                                   pk_supplies_constant.g_sww_rejected_pharmacist,
                                                   pk_supplies_constant.g_sww_prep_sup_for_surg,
                                                   pk_supplies_constant.g_sww_cons_and_count,
                                                   pk_supplies_constant.g_sww_predefined) THEN
                             pk_supplies_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_edit_cons_type,
                       sw.quantity,
                       CASE
                            WHEN sw.flg_status IN (pk_supplies_constant.g_sww_predefined,
                                                   pk_supplies_constant.g_sww_request_local,
                                                   pk_supplies_constant.g_sww_request_central) THEN
                             pk_supplies_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_edit_quantity,
                       pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof) dt_return,
                       pk_date_utils.dt_chr_tsz(i_lang, sw.dt_returned, i_prof) dt_return_desc,
                       sei.id_sr_epis_interv,
                       pk_sr_clinical_info.get_surgical_procedure_desc(i_lang, i_prof, sei.id_sr_epis_interv) desc_interv,
                       CASE
                            WHEN l_surg_proc > 0 THEN
                             pk_supplies_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_edit_interv,
                       sw.cod_table desc_table,
                       CASE
                            WHEN (SELECT COUNT(*)
                                    FROM sr_supply_relation ssr
                                   INNER JOIN supply_workflow sw2
                                      ON sw2.id_supply_workflow = ssr.id_supply_workflow
                                   WHERE sw2.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                                     AND sw2.id_episode = sw.id_episode
                                     AND sw2.id_supply = s.id_supply) > 0
                                 OR (sw.cod_table IS NULL AND sw.flg_status != pk_supplies_constant.g_sww_cons_and_count) THEN
                             pk_alert_constant.g_no
                            ELSE
                             pk_supplies_constant.g_yes
                        END flg_edit_table,
                       CASE
                            WHEN (sw.flg_status = pk_supplies_constant.g_sww_cons_and_count OR sw.cod_table IS NOT NULL) THEN
                             pk_supplies_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_show_table,
                       sw.id_req_reason id_reason,
                       pk_translation.get_translation(i_lang, sr.code_supply_reason) desc_reason,
                       pk_supplies_constant.g_yes flg_edit_reason,
                       sw.notes notes,
                       pk_supplies_constant.g_yes flg_edit_notes
                  FROM supply_workflow sw
                 INNER JOIN supply s
                    ON s.id_supply = sw.id_supply
                 INNER JOIN supply_location sl
                    ON sl.id_supply_location = sw.id_supply_location
                  LEFT JOIN supply_reason sr
                    ON sr.id_supply_reason = sw.id_req_reason
                  LEFT JOIN sr_epis_interv sei
                    ON sei.id_sr_epis_interv = sw.id_context
                   AND sei.flg_status != pk_alert_constant.g_cancelled
                   AND sw.flg_context = pk_supplies_constant.g_context_surgery
                 INNER JOIN TABLE(i_supply_workflow) swi
                    ON swi.column_value = sw.id_supply_workflow;
        
        ELSE
        
            g_error := 'OPEN CURSOR';
            OPEN o_supply_workflow FOR
                SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) description,
                       decode(sw.flg_reusable,
                              pk_supplies_constant.g_yes,
                              pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                              pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095')) attributes,
                       pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE', sw.flg_cons_type, i_lang) consumption_type,
                       pk_translation.get_translation(i_lang, 'SUPPLY_REASON.CODE_SUPPLY_REASON.' || sw.id_req_reason) request_reason,
                       pk_utils.to_str(sw.quantity) quantity,
                       nvl(pk_sysdomain.get_domain('SUPPLY_LOCATION.FLG_STOCK_TYPE', sl.flg_stock_type, i_lang),
                           pk_sysdomain.get_domain(i_lang,
                                                   i_prof,
                                                   'SUPPLY_LOCATION.FLG_STOCK_TYPE',
                                                   sl.flg_stock_type,
                                                   NULL)) ||
                       pk_string_utils.surround(pk_translation.get_translation(i_lang, sl.code_supply_location),
                                                pk_string_utils.g_pattern_space_parenthesis) request_to,
                       sw.dt_request request_for,
                       pk_date_utils.dt_chr_tsz(i_lang, sw.dt_request, i_prof) request_for_str,
                       sw.dt_returned est_return,
                       pk_date_utils.dt_chr_tsz(i_lang, sw.dt_returned, i_prof) est_return_str,
                       sw.notes notes
                  FROM supply_workflow sw
                  JOIN supply_location sl
                    ON sl.id_supply_location = sw.id_supply_location
                  JOIN TABLE(i_supply_workflow) swi
                    ON swi.column_value = sw.id_supply_workflow
                 ORDER BY description;
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
            pk_types.open_cursor_if_closed(o_supply_workflow);
            RETURN FALSE;
    END get_supply_request_edit;

    FUNCTION get_sun_supply_type
    (
        i_lang        IN language.id_language%TYPE,
        i_supply_type IN supply_type.id_supply_type%TYPE
    ) RETURN NUMBER IS
        o_id_sun_supply_type supply_type.id_supply_type%TYPE;
        o_error              t_error_out;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_supply_type IS NOT NULL
        THEN
        
            g_error := 'o_id_parent_supply_type';
            BEGIN
                SELECT get_sun_supply_type(i_lang, st.id_supply_type)
                  INTO o_id_sun_supply_type
                  FROM supply_type st
                 WHERE st.id_parent = i_supply_type;
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_sun_supply_type := i_supply_type;
            END;
        
        END IF;
    
        RETURN o_id_sun_supply_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUN_SUPPLY_TYPE',
                                              o_error);
            RETURN 0;
    END get_sun_supply_type;

    FUNCTION get_supply_child_type_count
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_supply_type      IN supply_type.id_supply_type%TYPE,
        l_count_prof       IN PLS_INTEGER,
        l_count_dept       IN PLS_INTEGER,
        l_dept             IN NUMBER,
        i_id_inst_dest     institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        CURSOR c_suns(i_supply_type supply_type.id_supply_type%TYPE) IS
            SELECT DISTINCT st.id_supply_type
              FROM supply_type st
             WHERE st.id_parent = i_supply_type;
    
        l_count_suns PLS_INTEGER;
        l_suns_ids   table_number;
        l_count_conf PLS_INTEGER;
        l_count_sun  PLS_INTEGER := 0;
        l_flg_child  VARCHAR2(1);
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_id_inst_dest IS NULL
        THEN
            IF i_lang IS NOT NULL
               AND i_prof.id IS NOT NULL
               AND i_prof.institution IS NOT NULL
               AND i_prof.software IS NOT NULL
               AND i_flg_type IS NOT NULL
            THEN
                g_error := 'IF NOT get_item_count';
                IF l_count_prof > 0
                THEN
                    g_error := 'l_count_suns';
                    SELECT COUNT(*)
                      INTO l_count_suns
                      FROM supply_type st
                     WHERE st.id_parent = i_supply_type;
                
                    IF l_count_suns > 0
                    THEN
                    
                        g_error := 'OPEN c_suns';
                        OPEN c_suns(i_supply_type);
                        FETCH c_suns BULK COLLECT
                            INTO l_suns_ids;
                        g_found := c_suns%NOTFOUND;
                        CLOSE c_suns;
                    
                        g_error := 'FOR i IN l_suns_ids.FIRST .. l_suns_ids.LAST';
                        FOR i IN l_suns_ids.first .. l_suns_ids.last
                        LOOP
                        
                            SELECT COUNT(DISTINCT s.id_supply)
                              INTO l_count_conf
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND ssi.id_professional = i_prof.id
                               AND ssi.id_supply = s.id_supply
                               AND s.flg_type = i_flg_type
                               AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                        
                            g_error := 'IF l_count_conf > 0';
                            IF l_count_conf > 0
                            THEN
                                l_count_sun := l_count_sun + 1;
                            ELSE
                                l_count_sun := l_count_sun;
                            END IF;
                        END LOOP;
                    ELSE
                        l_count_sun := 0;
                    END IF;
                
                ELSIF (l_count_dept > 0 AND l_count_prof = 0 AND i_id_inst_dest IS NULL)
                THEN
                    g_error := 'l_count_suns';
                    SELECT COUNT(*)
                      INTO l_count_suns
                      FROM supply_type st
                     WHERE st.id_parent = i_supply_type;
                
                    IF l_count_suns > 0
                    THEN
                    
                        g_error := 'OPEN c_suns';
                        OPEN c_suns(i_supply_type);
                        FETCH c_suns BULK COLLECT
                            INTO l_suns_ids;
                        g_found := c_suns%NOTFOUND;
                        CLOSE c_suns;
                    
                        g_error := 'FOR i IN l_suns_ids.FIRST .. l_suns_ids.LAST';
                        FOR i IN l_suns_ids.first .. l_suns_ids.last
                        LOOP
                        
                            SELECT COUNT(DISTINCT s.id_supply)
                              INTO l_count_conf
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON ssi.id_supply = s.id_supply
                               AND s.flg_available = pk_supplies_constant.g_yes
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND ssi.id_dept = l_dept
                               AND s.flg_type = i_flg_type
                               AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                        
                            g_error := 'IF l_count_conf > 0';
                            IF l_count_conf > 0
                            THEN
                                l_count_sun := l_count_sun + 1;
                            ELSE
                                l_count_sun := l_count_sun;
                            END IF;
                        END LOOP;
                    
                    ELSE
                        l_count_sun := 0;
                    END IF;
                
                ELSIF (l_count_dept = 0 AND l_count_prof = 0)
                THEN
                
                    g_error := 'OPEN c_suns';
                    OPEN c_suns(i_supply_type);
                    FETCH c_suns BULK COLLECT
                        INTO l_suns_ids;
                    g_found := c_suns%NOTFOUND;
                    CLOSE c_suns;
                
                    g_error := 'FOR i IN 1 .. l_suns_ids.COUNT';
                    FOR i IN 1 .. l_suns_ids.count
                    LOOP
                    
                        SELECT COUNT(DISTINCT s.id_supply)
                          INTO l_count_conf
                          FROM supply_soft_inst ssi
                         INNER JOIN supply s
                            ON ssi.id_supply = s.id_supply
                           AND s.flg_available = pk_supplies_constant.g_yes
                         INNER JOIN supply_sup_area ssa
                            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                           AND ssa.flg_available = pk_supplies_constant.g_yes
                           AND ssa.id_supply_area = i_id_supply_area
                         WHERE ssi.id_institution = i_prof.institution
                           AND ssi.id_software = i_prof.software
                           AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                           AND s.flg_type = i_flg_type
                           AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                           AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                    
                        g_error := 'IF l_count_conf > 0';
                        IF l_count_conf > 0
                        THEN
                            l_count_sun := l_count_sun + 1;
                        ELSE
                            l_count_sun := l_count_sun;
                        END IF;
                    END LOOP;
                
                ELSE
                    l_count_sun := 0;
                END IF;
            
            END IF;
        
        ELSE
        
            g_error := 'OPEN c_suns';
            OPEN c_suns(i_supply_type);
            FETCH c_suns BULK COLLECT
                INTO l_suns_ids;
            g_found := c_suns%NOTFOUND;
            CLOSE c_suns;
        
            g_error := 'FOR i IN 1 .. l_suns_ids.COUNT';
            FOR i IN 1 .. l_suns_ids.count
            LOOP
            
                SELECT COUNT(DISTINCT s.id_supply)
                  INTO l_count_conf
                  FROM supply_soft_inst ssi
                 INNER JOIN supply s
                    ON ssi.id_supply = s.id_supply
                   AND s.flg_available = pk_supplies_constant.g_yes
                 INNER JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                   AND ssa.flg_available = pk_supplies_constant.g_yes
                   AND ssa.id_supply_area = i_id_supply_area
                 WHERE ssi.id_institution = i_id_inst_dest
                   AND ssi.id_software = pk_sr_planning.g_software_oris
                   AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                   AND s.flg_type = i_flg_type
                   AND s.id_supply_type = get_sun_supply_type(i_lang, l_suns_ids(i))
                   AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
            
                g_error := 'IF l_count_conf > 0';
                IF l_count_conf > 0
                THEN
                    l_count_sun := l_count_sun + 1;
                ELSE
                    l_count_sun := l_count_sun;
                END IF;
            END LOOP;
        
        END IF;
    
        IF l_count_sun > 0
        THEN
            l_flg_child := 'T';
        ELSE
            l_flg_child := 'F';
        END IF;
    
        RETURN l_flg_child;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_CHILD_TYPE_COUNT',
                                              l_error);
            RETURN 'F';
    END get_supply_child_type_count;

    FUNCTION get_default_location
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        i_id_inst_dest   IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
    
        l_id_location supply_location.id_supply_location%TYPE;
    
    BEGIN
    
        g_error := 'GET DEFAULT LOCATION';
        IF i_id_inst_dest IS NULL
        THEN
            SELECT sld.id_supply_location
              INTO l_id_location
              FROM supply_soft_inst ssi
              JOIN supply_loc_default sld
                ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
              JOIN supply_location sl
                ON sl.id_supply_location = sld.id_supply_location
             INNER JOIN supply_sup_area ssa
                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
               AND ssa.flg_available = pk_supplies_constant.g_yes
               AND ssa.id_supply_area = i_id_supply_area
             WHERE sld.flg_default = pk_supplies_constant.g_yes
               AND nvl(ssi.id_professional, 0) IN (0, i_prof.id)
               AND ssi.id_institution = i_prof.institution
               AND ssi.id_software = i_prof.software
               AND ssi.id_supply = i_id_supply
               AND rownum = 1;
        ELSE
            SELECT sld.id_supply_location
              INTO l_id_location
              FROM supply_soft_inst ssi
              JOIN supply_loc_default sld
                ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
              JOIN supply_location sl
                ON sl.id_supply_location = sld.id_supply_location
             INNER JOIN supply_sup_area ssa
                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
               AND ssa.flg_available = pk_supplies_constant.g_yes
               AND ssa.id_supply_area = i_id_supply_area
             WHERE sld.flg_default = pk_supplies_constant.g_yes
               AND ssi.id_institution = i_id_inst_dest
               AND ssi.id_software = pk_sr_planning.g_software_oris
               AND ssi.id_supply = i_id_supply
               AND rownum = 1;
        END IF;
    
        RETURN l_id_location;
    
    END get_default_location;

    FUNCTION get_default_location_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE
    ) RETURN VARCHAR2 IS
    
        l_location_name VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET DEFAULT LOCATION NAME';
        SELECT pk_translation.get_translation(i_lang, sl.code_supply_location)
          INTO l_location_name
          FROM supply_location sl
         WHERE sl.id_supply_location = get_default_location(i_lang, i_prof, i_id_supply_area, i_id_supply);
    
        RETURN l_location_name;
    
    END get_default_location_name;

    FUNCTION tf_get_supply_requests
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_supply_requests IS
    
        l_date           VARCHAR2(200);
        l_date_begin     VARCHAR2(200);
        l_date_end       VARCHAR2(200);
        l_date_begin_tsz supply_workflow.dt_supply_workflow%TYPE;
        l_date_end_tsz   supply_workflow.dt_supply_workflow%TYPE;
        l_grid_hours     sys_config.value%TYPE;
    
        l_ret   t_tbl_supply_requests;
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET POS_PH_GRID_TIME SYSCONFIG';
    
        l_grid_hours := nvl(pk_sysconfig.get_config('SR_SUPPLIES_PH_GRID_TIME', i_prof), '24');
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
        THEN
        
            g_error      := 'CALCULATE DATE';
            l_date       := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            l_date_begin := lpad(l_date, 8, 0) || '000000';
            l_date_end   := lpad(l_date, 8, 0) || '235959';
        
            g_error := 'DATE BEGIN/DATE END';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => l_date_begin,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_date_begin_tsz,
                                                 o_error     => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => l_date_end,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_date_end_tsz,
                                                 o_error     => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'OPEN o_supply_request';
            SELECT t_supply_request(id_patient         => tt.id_patient,
                                    id_episode         => tt.id_episode,
                                    id_room_req        => tt.id_room_req,
                                    desc_room          => tt.desc_room,
                                    code_room          => tt.code_room,
                                    code_department    => tt.code_department,
                                    code_dept          => tt.code_dept,
                                    num_clin_record    => cr.num_clin_record,
                                    id_supply_request  => tt.id_supply_request,
                                    id_supply_workflow => tt.id_supply_workflow,
                                    flg_status         => tt.flg_status,
                                    rank               => tt.rank)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t.id_patient,
                           t.id_episode,
                           t.id_room_req,
                           t.desc_room,
                           t.code_room,
                           t.code_department,
                           t.code_dept,
                           t.id_supply_request,
                           t.id_supply_workflow,
                           t.flg_status,
                           t.rank,
                           row_number() over(PARTITION BY t.id_episode ORDER BY t.rank ASC) AS rn
                      FROM (SELECT tbl_supp.id_patient,
                                   tbl_supp.id_episode,
                                   tbl_supp.id_room_req,
                                   tbl_supp.desc_room,
                                   tbl_supp.code_room,
                                   tbl_supp.code_department,
                                   tbl_supp.code_dept,
                                   tbl_supp.id_supply_request,
                                   tbl_supp.id_supply_workflow,
                                   tbl_supp.flg_status,
                                   (SELECT wsc.rank
                                      FROM wf_status_config wsc
                                     WHERE wsc.id_status =
                                           pk_sup_status.convert_status_n(i_lang, i_prof, tbl_supp.flg_status)
                                       AND wsc.id_category = pk_supplies_constant.g_pharmacist
                                       AND wsc.id_workflow = decode(tbl_supp.id_supply_area,
                                                                    pk_supplies_constant.g_area_activity_therapy,
                                                                    pk_supplies_constant.g_id_workflow_at,
                                                                    pk_supplies_constant.g_area_surgical_supplies,
                                                                    pk_supplies_constant.g_id_workflow_sr,
                                                                    pk_supplies_constant.g_id_workflow)) rank
                              FROM (WITH prof_conf AS (SELECT DISTINCT psi.id_professional
                                                         FROM prof_soft_inst psi
                                                        WHERE psi.id_institution = i_prof.institution)
                                       SELECT e.id_patient,
                                              sr.id_episode,
                                              sr.id_room_req,
                                              r.desc_room,
                                              r.code_room,
                                              d.code_department,
                                              dt.code_dept,
                                              sw.flg_status,
                                              sw.id_supply_area,
                                              sr.id_supply_request,
                                              sw.id_supply_workflow
                                         FROM supply_request sr
                                         JOIN supply_workflow sw
                                           ON sw.id_supply_request = sr.id_supply_request
                                         JOIN episode e
                                           ON e.id_episode = sr.id_episode
                                         LEFT JOIN schedule_sr ss
                                           ON ss.id_episode = sw.id_episode
                                         JOIN supply_location sl
                                           ON sl.id_supply_location = sw.id_supply_location
                                         LEFT JOIN prof_conf pc
                                           ON pc.id_professional = sr.id_professional
                                         LEFT JOIN room r
                                           ON r.id_room = sr.id_room_req
                                         LEFT JOIN department d
                                           ON d.id_department = r.id_department
                                         LEFT JOIN dept dt
                                           ON d.id_dept = dt.id_dept
                                        WHERE ((pk_alert_constant.g_soft_pharmacy = i_prof.software AND
                                              sl.flg_cat_workflow = pk_supplies_constant.g_supply_cat_workflow_f) OR
                                              (i_prof.software NOT IN (pk_alert_constant.g_soft_pharmacy)))
                                          AND sr.flg_status IN
                                              (pk_supplies_constant.g_srt_requested, pk_supplies_constant.g_srt_ongoing)
                                          AND e.id_institution = i_prof.institution
                                          AND (sw.flg_status IN
                                              (pk_supplies_constant.g_sww_request_central,
                                                pk_supplies_constant.g_sww_in_delivery,
                                                pk_supplies_constant.g_sww_in_transit,
                                                pk_supplies_constant.g_sww_prepared_pharmacist,
                                                pk_supplies_constant.g_sww_prep_sup_for_surg,
                                                pk_supplies_constant.g_sww_deliver_concluded) OR
                                              (sw.flg_status = pk_supplies_constant.g_sww_deliver_needed AND
                                              sw.id_supply_location = pk_supplies_constant.g_pharmacy_location))
                                          AND (sw.id_supply_area != pk_supplies_constant.g_area_surgical_supplies OR
                                              (sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies AND
                                              ss.dt_target_tstz < (g_sysdate_tstz + l_grid_hours / 24) AND
                                              ss.dt_target_tstz IS NOT NULL))
                                       UNION ALL
                                       SELECT e.id_patient,
                                              sr.id_episode,
                                              sr.id_room_req,
                                              r.desc_room,
                                              r.code_room,
                                              d.code_department,
                                              dt.code_dept,
                                              sw.flg_status,
                                              sw.id_supply_area,
                                              sr.id_supply_request,
                                              sw.id_supply_workflow
                                         FROM supply_request sr
                                         JOIN supply_workflow sw
                                           ON sw.id_supply_request = sr.id_supply_request
                                         JOIN episode e
                                           ON e.id_episode = sr.id_episode
                                         JOIN supply_location sl
                                           ON sl.id_supply_location = sw.id_supply_location
                                         JOIN prof_conf pc
                                           ON pc.id_professional = sr.id_professional
                                         LEFT JOIN room r
                                           ON r.id_room = sr.id_room_req
                                         LEFT JOIN department d
                                           ON d.id_department = r.id_department
                                         LEFT JOIN dept dt
                                           ON d.id_dept = dt.id_dept
                                        WHERE ((pk_alert_constant.g_soft_pharmacy = i_prof.software AND
                                              sl.flg_cat_workflow = pk_supplies_constant.g_supply_cat_workflow_f) OR
                                              (i_prof.software NOT IN (pk_alert_constant.g_soft_pharmacy)))
                                          AND sr.flg_status IN
                                              (pk_supplies_constant.g_srt_requested, pk_supplies_constant.g_srt_ongoing)
                                          AND e.id_institution = i_prof.institution
                                          AND sw.flg_status IN
                                              (pk_supplies_constant.g_sww_rejected_pharmacist,
                                               pk_supplies_constant.g_sww_cancelled,
                                               pk_supplies_constant.g_sww_deliver_concluded)
                                          AND sw.dt_supply_workflow >= l_date_begin_tsz
                                          AND sw.dt_supply_workflow <= l_date_end_tsz) tbl_supp
                                        WHERE (SELECT pk_supplies_core.get_supply_date_tstz(i_lang,
                                                                                            i_prof,
                                                                                            tbl_supp.id_episode,
                                                                                            tbl_supp.flg_status)
                                                 FROM dual) IS NOT NULL
                                          AND (SELECT pk_supplies_core.get_supply_delay_sr_day(i_lang,
                                                                                               i_prof,
                                                                                               tbl_supp.id_episode,
                                                                                               tbl_supp.flg_status)
                                                 FROM dual) IS NOT NULL
                            ) t) tt
              LEFT JOIN clin_record cr
                ON cr.id_patient = tt.id_patient
               AND (cr.id_episode = tt.id_episode OR cr.id_episode IS NULL)
               AND cr.id_institution = i_prof.institution
               AND cr.flg_status = pk_alert_constant.g_active
               AND rownum = 1
             WHERE tt.rn = 1;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_SUPPLY_REQUESTS',
                                              l_error);
            RETURN t_tbl_supply_requests();
    END tf_get_supply_requests;

    FUNCTION get_consumption_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_supply         IN supply.id_supply%TYPE,
        i_id_inst_dest   IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_flg_cons_type supply_soft_inst.flg_cons_type%TYPE;
    
    BEGIN
    
        g_error := 'GET_CONSUMPTION_TYPE';
        IF i_id_inst_dest IS NULL
        THEN
            SELECT flg_cons_type
              INTO l_flg_cons_type
              FROM (SELECT ssi.flg_cons_type,
                           pk_sysdomain.get_rank(i_lang, 'SUPPLY_SOFT_INST.FLG_CONS_TYPE', ssi.flg_cons_type) rank,
                           row_number() over(PARTITION BY NULL ORDER BY ssi.id_professional DESC, ssi.id_institution DESC, ssi.id_software DESC) AS rn
                      FROM supply_soft_inst ssi
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE nvl(ssi.id_professional, 0) IN (0, i_prof.id)
                       AND ssi.id_institution = i_prof.institution
                       AND ssi.id_software = i_prof.software
                       AND ssi.id_supply = i_supply
                     ORDER BY rn, rank DESC)
             WHERE rownum = 1;
        ELSE
        
            SELECT flg_cons_type
              INTO l_flg_cons_type
              FROM (SELECT ssi.flg_cons_type,
                           pk_sysdomain.get_rank(i_lang, 'SUPPLY_SOFT_INST.FLG_CONS_TYPE', ssi.flg_cons_type) rank,
                           row_number() over(PARTITION BY NULL ORDER BY ssi.id_professional DESC, ssi.id_institution DESC, ssi.id_software DESC) AS rn
                      FROM supply_soft_inst ssi
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE ssi.id_institution = i_id_inst_dest
                       AND ssi.id_software = pk_sr_planning.g_software_oris
                       AND ssi.id_supply = i_supply
                     ORDER BY rn, rank DESC)
             WHERE rownum = 1;
        END IF;
    
        RETURN l_flg_cons_type;
    
    END get_consumption_type;

    FUNCTION get_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_supply             IN supply.id_supply%TYPE,
        i_supply_location    IN supply_location.id_supply_location%TYPE DEFAULT NULL,
        i_id_inst_dest       IN institution.id_institution%TYPE DEFAULT NULL,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_attributes VARCHAR2(4000);
        l_type       VARCHAR2(4000 CHAR);
        l_reusable   VARCHAR2(4000 CHAR);
        l_preparing  VARCHAR2(4000 CHAR);
    BEGIN
    
        IF i_id_supply_workflow IS NOT NULL
        THEN
            SELECT CASE i_id_supply_area
                       WHEN pk_supplies_constant.g_area_surgical_supplies THEN
                        pk_sysdomain.get_domain('SUPPLY.FLG_TYPE.SR', s.flg_type, i_lang)
                       ELSE
                        decode(sw.flg_reusable,
                               pk_supplies_constant.g_yes,
                               pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                               pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095'))
                   END,
                   CASE i_id_supply_area
                       WHEN pk_supplies_constant.g_area_surgical_supplies THEN
                        decode(sw.flg_reusable,
                               pk_supplies_constant.g_yes,
                               pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                               pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095'))
                       ELSE
                        (SELECT pk_translation.get_translation(i_lang,
                                                               'SUPPLY_LOCATION.CODE_SUPPLY_LOCATION.' ||
                                                               sw.id_supply_location)
                           FROM dual)
                   END,
                   CASE i_id_supply_area
                       WHEN pk_supplies_constant.g_area_surgical_supplies THEN
                        pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_PREPARING', sw.flg_preparing, i_lang)
                       ELSE
                        NULL
                   END
              INTO l_type, l_reusable, l_preparing
              FROM supply_workflow sw
             INNER JOIN supply s
                ON s.id_supply = sw.id_supply
             WHERE sw.id_supply_workflow = i_id_supply_workflow;
        
            l_attributes := l_type || CASE
                                WHEN l_reusable IS NOT NULL
                                     AND l_type IS NOT NULL THEN
                                 '; '
                                ELSE
                                 NULL
                            END || l_reusable || CASE
                                WHEN l_preparing IS NOT NULL
                                     AND (l_type IS NOT NULL OR l_reusable IS NOT NULL) THEN
                                 '; '
                                ELSE
                                 NULL
                            END || l_preparing;
        ELSIF i_id_inst_dest IS NULL
        THEN
            SELECT att
              INTO l_attributes
              FROM (SELECT CASE i_id_supply_area
                               WHEN pk_supplies_constant.g_area_surgical_supplies THEN
                                pk_sysdomain.get_domain('SUPPLY.FLG_TYPE.SR', s.flg_type, i_lang) || '; ' ||
                                decode(ssi.flg_reusable,
                                       pk_supplies_constant.g_yes,
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095')) || '; ' ||
                                pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_PREPARING', ssi.flg_preparing, i_lang)
                               ELSE
                                decode(ssi.flg_reusable,
                                       pk_supplies_constant.g_yes,
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095')) || '; ' ||
                                (SELECT pk_translation.get_translation(i_lang, sl.code_supply_location)
                                   FROM dual)
                           END att,
                           row_number() over(PARTITION BY ssi.id_supply ORDER BY ssi.id_institution DESC) rn
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON s.id_supply = ssi.id_supply
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                      JOIN supply_loc_default sld
                        ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
                      JOIN supply_location sl
                        ON sl.id_supply_location = sld.id_supply_location
                     WHERE ssi.id_professional IN (i_prof.id, 0)
                       AND ssi.id_institution = i_prof.institution
                       AND ((ssi.id_software = i_prof.software AND
                           i_id_supply_area != pk_supplies_constant.g_area_surgical_supplies) OR
                           (ssi.id_software = pk_alert_constant.g_soft_oris AND
                           i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies))
                       AND ssi.id_supply = i_supply
                       AND ((i_supply_location IS NULL AND sld.flg_default = pk_supplies_constant.g_yes) OR
                           (i_supply_location IS NOT NULL AND sl.id_supply_location = i_supply_location)))
             WHERE rn = 1;
        ELSE
            SELECT att
              INTO l_attributes
              FROM (SELECT CASE i_id_supply_area
                               WHEN pk_supplies_constant.g_area_surgical_supplies THEN
                                pk_sysdomain.get_domain('SUPPLY.FLG_TYPE.SR', s.flg_type, i_lang) || '; ' ||
                                decode(ssi.flg_reusable,
                                       pk_supplies_constant.g_yes,
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095')) || '; ' ||
                                pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_PREPARING', ssi.flg_preparing, i_lang)
                               ELSE
                                decode(ssi.flg_reusable,
                                       pk_supplies_constant.g_yes,
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096'),
                                       pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095')) || '; ' ||
                                nvl(pk_sysdomain.get_domain('SUPPLY_LOCATION.FLG_STOCK_TYPE', sl.flg_stock_type, i_lang),
                                    pk_sysdomain.get_domain(i_lang,
                                                            i_prof,
                                                            'SUPPLY_LOCATION.FLG_STOCK_TYPE',
                                                            sl.flg_stock_type,
                                                            NULL))
                           END att,
                           row_number() over(PARTITION BY ssi.id_supply ORDER BY ssi.id_institution DESC) rn
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON s.id_supply = ssi.id_supply
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                      JOIN supply_loc_default sld
                        ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
                      JOIN supply_location sl
                        ON sl.id_supply_location = sld.id_supply_location
                     WHERE ssi.id_institution = i_id_inst_dest
                       AND ssi.id_software = pk_sr_planning.g_software_oris
                       AND ssi.id_supply = i_supply
                       AND ((i_supply_location IS NULL AND sld.flg_default = pk_supplies_constant.g_yes) OR
                           (i_supply_location IS NOT NULL AND sl.id_supply_location = i_supply_location)))
             WHERE rn = 1;
        END IF;
    
        RETURN l_attributes;
    
    END get_attributes;

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
        o_type         pk_types.cursor_type;
        o_items        pk_types.cursor_type;
        l_flg_selected VARCHAR2(1);
    BEGIN
        IF NOT pk_supplies_core.get_supply_for_selection(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_supply_area   => NULL,
                                                         i_episode          => i_episode,
                                                         i_consumption_type => pk_supplies_core.get_consumption_type(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_id_supply_area,
                                                                                                                     i_id_supply),
                                                         i_flg_type         => pk_supplies_constant.g_supply_type,
                                                         i_id_supply        => NULL,
                                                         i_id_supply_type   => get_supply_type_id(i_id_supply),
                                                         i_id_inst_dest     => NULL,
                                                         o_supply_inf       => o_supplies,
                                                         o_supply_type      => o_type,
                                                         o_supply_items     => o_items,
                                                         o_flg_selected     => l_flg_selected,
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
                                              'GET_SAME_TYPE_SUPPLIES',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
            RETURN FALSE;
    END get_same_type_supplies;

    FUNCTION get_deliver_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_yes sys_message.code_message%TYPE := 'COMMON_M022';
        l_no  sys_message.code_message%TYPE := 'COMMON_M023';
    
    BEGIN
    
        OPEN o_options FOR
            SELECT a.desc_info data, pk_message.get_message(i_lang, i_prof, b.desc_info) label
              FROM TABLE(table_info(info(1, pk_supplies_constant.g_yes, NULL), info(2, pk_alert_constant.g_no, NULL))) a,
                   TABLE(table_info(info(1, l_yes, NULL), info(2, l_no, NULL))) b
             WHERE a.id = b.id
             ORDER BY a.id;
    
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
        
            RETURN FALSE;
    END get_deliver_options;

    FUNCTION get_supply_delay_sr_day
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        i_flag       IN supply_workflow.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_date                 VARCHAR2(200);
        l_shortcut             sys_shortcut.id_sys_shortcut%TYPE;
        l_category             category.id_category%TYPE;
        l_status               supply_workflow.flg_status%TYPE;
        l_id_workflow          wf_status_config.id_workflow%TYPE;
        l_id_episode           episode.id_episode%TYPE;
        l_pharmacist_main_grid VARCHAR2(1 CHAR);
    
        CURSOR c_wf_pharm
        (
            i_id_episode episode.id_episode%TYPE,
            l_category   category.id_category%TYPE,
            i_flag       supply_workflow.flg_status%TYPE
        ) IS
            SELECT *
              FROM (SELECT sw1.dt, sw1.flg_status, wsc.id_workflow, sw1.id_episode
                      FROM wf_status_config wsc
                     INNER JOIN (SELECT decode(sw.flg_status,
                                              pk_supplies_constant.g_sww_request_central,
                                              sw.dt_request,
                                              sw.dt_supply_workflow) AS dt,
                                       sw.flg_status,
                                       CASE
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                             pk_supplies_constant.g_id_workflow_sr
                                        /*WHEN sw.id_supply_area =pk_supplies_constant.g_area_supplies THEN
                                        pk_supplies_constant.g_id_workflow_sr*/
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_activity_therapy THEN
                                             pk_supplies_constant.g_id_workflow_at
                                            ELSE
                                             pk_supplies_constant.g_id_workflow
                                        END id_workflow,
                                       sw.id_episode,
                                       pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status) id_flg_status
                                  FROM supply_workflow sw
                                  JOIN supply_location sl
                                    ON sl.id_supply_location = sw.id_supply_location
                                 WHERE sw.flg_status = i_flag
                                   AND sw.id_episode = i_id_episode
                                   AND ((pk_alert_constant.g_soft_pharmacy = i_prof.software AND
                                       sl.flg_cat_workflow = pk_supplies_constant.g_supply_cat_workflow_f) OR
                                       (i_prof.software NOT IN (pk_alert_constant.g_soft_pharmacy)))) sw1
                        ON sw1.id_workflow = wsc.id_workflow
                       AND sw1.id_flg_status = wsc.id_status
                     WHERE wsc.id_category = l_category
                     ORDER BY wsc.rank, sw1.dt) t
             WHERE rownum = 1;
    
        l_error      t_error_out;
        l_status_str VARCHAR2(200) := NULL;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'CALCULATE CATEGORY';
            SELECT pc.id_category
              INTO l_category
              FROM prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            g_error := 'CATEGORY=' || l_category;
            IF l_category IN (7, 3) -- Pharmacist and Technician
            THEN
            
                OPEN c_wf_pharm(i_id_episode, l_category, i_flag);
                FETCH c_wf_pharm
                    INTO l_date, l_status, l_id_workflow, l_id_episode;
                CLOSE c_wf_pharm;
                l_shortcut := 10489;
            
                --this function is only called by pharmacist main grids 
                -- so is necessary force the icon background color because theses grids don't have workflow cellrender
                l_pharmacist_main_grid := pk_supplies_constant.g_yes;
            
            ELSE
                --others
                l_shortcut := NULL;
                l_date     := NULL;
                l_status   := NULL;
            END IF;
        
            IF l_date IS NOT NULL
               AND l_status IS NOT NULL
            THEN
            
                l_status_str := pk_sup_status.get_sup_status_string(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_status         => l_status,
                                                                    i_shortcut       => l_shortcut,
                                                                    i_id_workflow    => pk_supplies_constant.g_id_workflow,
                                                                    i_id_category    => l_category,
                                                                    i_date           => l_date,
                                                                    i_id_episode     => l_id_episode,
                                                                    i_phar_main_grid => l_pharmacist_main_grid);
            END IF;
        END IF;
    
        RETURN l_status_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_DELAY_SR_DAY',
                                              l_error);
            RETURN l_status_str;
    END get_supply_delay_sr_day;

    FUNCTION get_supply_patients
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE,
        o_grid      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_shortcut    sys_shortcut.id_sys_shortcut%TYPE := NULL;
        l_id_category wf_status_config.id_category%TYPE;
    
    BEGIN
    
        g_error       := 'get the prof category';
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        g_error := 'GET SUPLIES DATA';
        OPEN o_grid FOR
            SELECT t.id_patient,
                   t.id_episode,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, t.id_patient, t.id_episode, NULL) photo,
                   pk_patient.get_pat_age(i_lang, t.dt_birth, t.dt_deceased, t.age, i_prof.institution, i_prof.software) pat_age,
                   pk_patient.get_julian_age(i_lang, t.dt_birth, t.age) pat_age_for_order_by,
                   pk_patient.get_gender(i_lang, t.gender) gender,
                   pk_patient.get_pat_name(i_lang, i_prof, t.id_patient, t.id_episode) name_pat,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, t.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, t.id_patient) pat_nd_icon,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, t.id_patient, t.id_episode) name_pat_to_sort,
                   t.nr_loaded_units,
                   pk_date_utils.date_send_tsz(i_lang, t.min_dt_return, i_prof) return_date,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, t.min_dt_return, i_prof.institution, i_prof.software) return_date_desc,
                   pk_date_utils.date_char_hour_tsz(i_lang, t.min_dt_return, i_prof.institution, i_prof.software) return_hour_desc,
                   pk_sup_status.get_sup_status_string(i_lang,
                                                        i_prof,
                                                        pk_supplies_constant.g_sww_loaned,
                                                        l_shortcut,
                                                        pk_act_therap_constant.g_id_workflow,
                                                        l_id_category,
                                                        CASE
                                                            WHEN t.min_dt_return < current_timestamp THEN
                                                             t.min_dt_return
                                                            ELSE
                                                             NULL
                                                        END) desc_status
              FROM (SELECT epi.id_episode,
                           epi.id_patient,
                           pat.dt_birth,
                           pat.dt_deceased,
                           pat.gender,
                           pat.age,
                           SUM(nvl(sw.quantity, pk_act_therap_constant.g_supplies_default_qt)) nr_loaded_units,
                           MIN(sw.dt_returned) min_dt_return
                      FROM supply_workflow sw
                      JOIN episode epi
                        ON epi.id_episode = sw.id_episode
                      JOIN patient pat
                        ON pat.id_patient = epi.id_patient
                     WHERE sw.id_supply = i_id_supply
                       AND sw.id_professional = i_prof.id
                       AND sw.flg_status = pk_supplies_constant.g_sww_loaned
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                     GROUP BY epi.id_patient, epi.id_episode, pat.dt_birth, pat.age, pat.gender, pat.dt_deceased) t;
    
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
            RETURN FALSE;
    END get_supply_patients;

    FUNCTION get_nr_loaned_units
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN supply_workflow.quantity%TYPE IS
    
        l_nr_units         supply_workflow.quantity%TYPE := 0;
        l_count_prof       PLS_INTEGER;
        l_count_dept       PLS_INTEGER;
        l_dept             episode.id_dept_requested%TYPE;
        l_consumption_type supply_soft_inst.flg_cons_type%TYPE := i_consumption_type;
        l_flg_type         supply.flg_type%TYPE := i_flg_type;
    
        l_error t_error_out;
    
    BEGIN
    
        IF l_consumption_type IS NULL
        THEN
            l_consumption_type := 'L';
            l_flg_type         := 'M';
        END IF;
    
        IF i_id_inst_dest IS NULL
        THEN
            g_error := 'CALCULATE l_nr_units for id_supply: ' || i_id_supply;
            IF NOT get_item_count(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_id_supply_area   => i_id_supply_area,
                                  i_episode          => i_id_episode,
                                  i_consumption_type => l_consumption_type,
                                  i_flg_type         => l_flg_type,
                                  i_id_supply        => i_id_supply,
                                  i_id_supply_type   => NULL,
                                  i_id_inst_dest     => i_id_inst_dest,
                                  o_supply_prof      => l_count_prof,
                                  o_supply_dept      => l_count_dept,
                                  o_dept             => l_dept,
                                  o_error            => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF l_count_prof > 0
            THEN
                g_error := 'l_nr_units';
                SELECT SUM(nvl(sw.quantity, 1))
                  INTO l_nr_units
                  FROM supply_soft_inst ssi
                  JOIN supply_workflow sw
                    ON sw.id_supply = ssi.id_supply
                 WHERE ssi.id_institution = i_prof.institution
                   AND ssi.id_software = i_prof.software
                   AND ssi.id_professional = i_prof.id
                   AND ssi.flg_cons_type = l_consumption_type
                   AND sw.id_supply = i_id_supply
                   AND ssi.id_supply = i_id_supply
                   AND sw.flg_status = pk_supplies_constant.g_sww_loaned
                   AND sw.id_professional = i_prof.id
                   AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                   AND sw.id_supply_area = i_id_supply_area;
            
            ELSIF (l_count_dept > 0 AND l_count_prof = 0 AND i_id_inst_dest IS NULL)
            THEN
            
                g_error := 'l_nr_units';
                SELECT SUM(nvl(sw.quantity, 1))
                  INTO l_nr_units
                  FROM supply_soft_inst ssi
                  JOIN supply_workflow sw
                    ON sw.id_supply = ssi.id_supply
                  JOIN episode e
                    ON e.id_episode = sw.id_episode
                 WHERE ssi.id_institution = i_prof.institution
                   AND ssi.id_software = i_prof.software
                   AND ssi.id_dept = l_dept
                   AND ssi.flg_cons_type = l_consumption_type
                   AND sw.id_supply = i_id_supply
                   AND ssi.id_supply = i_id_supply
                   AND sw.flg_status = pk_supplies_constant.g_sww_loaned
                   AND e.id_dept_requested = l_dept
                   AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                   AND sw.id_supply_area = i_id_supply_area;
            
            ELSIF (l_count_dept = 0 AND l_count_prof = 0)
            THEN
                g_error := 'l_nr_units';
                SELECT SUM(nvl(sw.quantity, 1))
                  INTO l_nr_units
                  FROM supply_soft_inst ssi
                  JOIN supply_workflow sw
                    ON sw.id_supply = ssi.id_supply
                  JOIN episode e
                    ON e.id_episode = sw.id_episode
                 WHERE ssi.id_institution = i_prof.institution
                   AND ssi.id_software = i_prof.software
                   AND ssi.flg_cons_type = l_consumption_type
                   AND sw.id_supply = i_id_supply
                   AND ssi.id_supply = i_id_supply
                   AND sw.flg_status = pk_supplies_constant.g_sww_loaned
                   AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                   AND e.id_institution = i_prof.institution
                   AND sw.id_supply_area = i_id_supply_area;
            
            END IF;
        
        ELSE
            SELECT SUM(nvl(sw.quantity, 1))
              INTO l_nr_units
              FROM supply_soft_inst ssi
              JOIN supply_workflow sw
                ON sw.id_supply = ssi.id_supply
              JOIN episode e
                ON e.id_episode = sw.id_episode
             WHERE ssi.id_institution = i_id_inst_dest
               AND ssi.id_software = pk_sr_planning.g_software_oris
               AND ssi.flg_cons_type = l_consumption_type
               AND sw.id_supply = i_id_supply
               AND ssi.id_supply = i_id_supply
               AND sw.flg_status = pk_supplies_constant.g_sww_loaned
               AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
               AND e.id_institution = i_prof.institution
               AND sw.id_supply_area = i_id_supply_area;
        END IF;
    
        l_nr_units := nvl(l_nr_units, 0);
    
        RETURN l_nr_units;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_nr_units;
    END get_nr_loaned_units;

    FUNCTION get_nr_avail_units
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
    ) RETURN supply_soft_inst.quantity%TYPE IS
    
        l_nr_units     supply_workflow.quantity%TYPE := 0;
        l_loaned_units supply_workflow.quantity%TYPE := 0;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'CALCULATE l_nr_units available for id_supply: ' || i_id_supply || ' i_id_supply_area: ' ||
                          i_id_supply_area;
        l_loaned_units := get_nr_loaned_units(i_lang,
                                              i_prof,
                                              i_id_supply_area,
                                              i_id_supply,
                                              i_id_episode,
                                              NULL,
                                              NULL,
                                              NULL);
    
        SELECT ssi.total_avail_quantity nr_units_avail
          INTO l_nr_units
          FROM supply_soft_inst ssi
         INNER JOIN supply_sup_area ssa
            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
           AND ssa.flg_available = pk_supplies_constant.g_yes
           AND ssa.id_supply_area = i_id_supply_area
         WHERE ssi.id_institution = i_prof.institution
           AND ssi.id_software = i_prof.software
           AND ssi.id_dept IN (0,
                               (SELECT e.id_dept_requested
                                  FROM episode e
                                 WHERE e.id_episode = i_id_episode)) --
           AND nvl(ssi.id_professional, 0) IN (0, i_prof.id)
           AND ssi.id_supply = i_id_supply;
    
        RETURN l_nr_units - l_loaned_units;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_nr_units;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NR_AVAIL_UNITS',
                                              l_error);
            RETURN l_nr_units;
    END get_nr_avail_units;

    FUNCTION get_delivered_units
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_software_workflow  IN supply.id_supply%TYPE,
        i_software_wf_parent IN supply.id_supply%TYPE
    ) RETURN supply_workflow.quantity%TYPE IS
        l_error    t_error_out;
        l_nr_units supply_workflow.quantity%TYPE := 0;
    
        l_id_supply_workflow supply_workflow.id_supply_workflow%TYPE;
    
    BEGIN
    
        g_error := 'CALCULATE l_nr_units delivered for id_supply_workflow: ' || i_software_workflow;
        IF (i_software_wf_parent IS NOT NULL)
        THEN
            l_id_supply_workflow := i_software_wf_parent;
        ELSE
            l_id_supply_workflow := i_software_workflow;
        END IF;
    
        SELECT SUM(t.quantity)
          INTO l_nr_units
          FROM (SELECT sw.quantity
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = l_id_supply_workflow
                   AND sw.flg_status = pk_supplies_constant.g_sww_deliver_institution
                   AND sw.flg_outdated != pk_supplies_constant.g_sww_outdated
                UNION ALL
                SELECT sw.quantity
                  FROM supply_workflow sw
                 WHERE sw.id_sup_workflow_parent = l_id_supply_workflow
                   AND sw.flg_status = pk_supplies_constant.g_sww_deliver_institution
                   AND sw.flg_outdated != pk_supplies_constant.g_sww_outdated) t;
    
        RETURN l_nr_units;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_nr_units;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DELIVERED_UNITS',
                                              l_error);
            RETURN l_nr_units;
    END get_delivered_units;

    FUNCTION get_supply_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    
        l_supply_desc pk_translation.t_desc_translation;
        l_error       t_error_out;
    
    BEGIN
    
        g_error := 'GET supply description: i_id_supply: ' || i_id_supply;
        SELECT pk_translation.get_translation(i_lang, s.code_supply)
          INTO l_supply_desc
          FROM supply s
         WHERE s.id_supply = i_id_supply;
    
        RETURN l_supply_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_DESC',
                                              l_error);
            RETURN NULL;
    END get_supply_desc;

    -- GS: 20100727 - Made this function only to correct a bug 
    -- review of functions get_supply_date,  get_supply_requests are needed
    FUNCTION get_supply_date_tstz
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        i_flag       IN supply_workflow.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date     supply_workflow.dt_supply_workflow%TYPE;
        l_category category.id_category%TYPE;
        l_error    t_error_out;
    
        CURSOR c_wf_pharm
        (
            i_id_episode  episode.id_episode%TYPE,
            l_id_category category.id_category%TYPE,
            i_flag        supply_workflow.flg_status%TYPE
        ) IS
            SELECT *
              FROM (SELECT sw1.dt_supply
                      FROM wf_status_config wsc
                     INNER JOIN (SELECT CASE sw.flg_status
                                           WHEN pk_supplies_constant.g_sww_request_central THEN
                                            sw.dt_request
                                           ELSE
                                            sw.dt_supply_workflow
                                       END dt_supply,
                                       CASE
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                             pk_supplies_constant.g_id_workflow_sr
                                            WHEN sw.id_supply_area = pk_supplies_constant.g_area_activity_therapy THEN
                                             pk_supplies_constant.g_id_workflow_at
                                            ELSE
                                             pk_supplies_constant.g_id_workflow
                                        END id_workflow,
                                       pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status) id_flg_status
                                  FROM supply_workflow sw
                                 WHERE sw.flg_status = i_flag
                                   AND sw.id_episode = i_id_episode) sw1
                        ON sw1.id_workflow = wsc.id_workflow
                       AND sw1.id_flg_status = wsc.id_status
                     WHERE wsc.id_category = l_id_category
                     ORDER BY wsc.rank, sw1.dt_supply) t
             WHERE rownum = 1;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'CALCULATE CATEGORY';
            SELECT pc.id_category
              INTO l_category
              FROM prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            g_error := 'c_wf';
            IF l_category IN (7, 3) -- Pharmacist and Technician
            THEN
            
                OPEN c_wf_pharm(i_id_episode, l_category, i_flag);
                FETCH c_wf_pharm
                    INTO l_date;
                CLOSE c_wf_pharm;
            
            END IF;
        
        END IF;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SUPPLY_DATE_TSTZ',
                                              o_error    => l_error);
        
            RETURN NULL;
        
    END get_supply_date_tstz;

    FUNCTION get_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply          IN table_number,
        i_flg_status         IN table_varchar,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(30) := 'GET_SUPPLY_WORKFLOW';
        l_id_supply_workflow table_number := table_number();
    
    BEGIN
    
        g_error := 'GET ID SUPPLY WORKFLOWS AND ID_SUPPLY FOR ID_CONTEXT: ' || i_id_context || ' AND FLG_CONTEXT : ' ||
                   i_flg_context;
    
        SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO l_id_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context
           AND sw.flg_status IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                  t1.column_value
                                   FROM TABLE(i_flg_status) t1)
           AND sw.id_supply IN (SELECT /*+opt_estimate(table t2 rows=1)*/
                                 t2.column_value
                                  FROM TABLE(i_id_supply) t2);
    
        o_id_supply_workflow := l_id_supply_workflow;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_supply_workflow;

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
        l_consumption_type  sys_domain.code_domain%TYPE := 'SUPPLY_SOFT_INST.FLG_CONS_TYPE';
        l_config_cons_loan  sys_config.id_sys_config%TYPE := 'SUPPLIES_LOAN_CONSUMPTION_AVILABLE';
        l_config_req_loan   sys_config.id_sys_config%TYPE := 'SUPPLIES_LOAN_REQ_AVILABLE';
        l_config_cons_local sys_config.id_sys_config%TYPE := 'SUPPLIES_LOCAL_CONSUMPTION_AVILABLE';
        l_config_req_local  sys_config.id_sys_config%TYPE := 'SUPPLIES_LOCAL_REQ_AVILABLE';
        l_dept              episode.id_dept_requested%TYPE;
        l_count_prof        PLS_INTEGER;
        l_count_dept        PLS_INTEGER;
        l_req_loan          VARCHAR2(1);
        l_cons_loan         VARCHAR2(1);
        l_req_local         VARCHAR2(1);
        l_cons_local        VARCHAR2(1);
    BEGIN
    
        IF i_episode IS NULL
        THEN
            OPEN o_types FOR
                SELECT t_tl_supply_type_consumption(sd.val, sd.desc_val, NULL)
                
                  FROM sys_domain sd
                 WHERE sd.code_domain = l_consumption_type
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang;
        ELSE
            IF i_id_inst_dest IS NULL
            THEN
            
                IF i_lang IS NOT NULL
                   AND i_prof.id IS NOT NULL
                   AND i_prof.institution IS NOT NULL
                   AND i_prof.software IS NOT NULL
                   AND i_episode IS NOT NULL
                THEN
                
                    g_error := 'l_count_prof';
                    SELECT COUNT(DISTINCT sks.flg_cons_type)
                      INTO l_count_prof
                      FROM supply_soft_inst sks
                     INNER JOIN supply s
                        ON sks.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = sks.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE sks.id_institution = i_prof.institution
                       AND sks.id_software = i_prof.software
                       AND sks.id_professional = i_prof.id
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    g_error := 'l_dept';
                    SELECT e.id_dept_requested
                      INTO l_dept
                      FROM episode e
                     WHERE e.id_episode = i_episode;
                
                    g_error := 'l_count_dept';
                    SELECT COUNT(DISTINCT sks.flg_cons_type)
                      INTO l_count_dept
                      FROM supply_soft_inst sks
                     INNER JOIN supply s
                        ON sks.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = sks.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                     WHERE sks.id_institution = i_prof.institution
                       AND sks.id_software = i_prof.software
                       AND sks.id_dept = l_dept
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL;
                
                    l_req_loan   := pk_sysconfig.get_config(l_config_req_loan, i_prof);
                    l_cons_loan  := pk_sysconfig.get_config(l_config_cons_loan, i_prof);
                    l_req_local  := pk_sysconfig.get_config(l_config_req_local, i_prof);
                    l_cons_local := pk_sysconfig.get_config(l_config_cons_local, i_prof);
                
                    IF l_count_prof > 0
                    THEN
                    
                        g_error := 'IF l_count_prof > 0';
                        OPEN o_types FOR
                            SELECT val, desc_val
                              FROM (SELECT DISTINCT sks.flg_cons_type val,
                                                    pk_sysdomain.get_domain(l_consumption_type,
                                                                            sks.flg_cons_type,
                                                                            i_lang) desc_val
                                      FROM supply_soft_inst sks
                                     INNER JOIN supply s
                                        ON sks.id_supply = s.id_supply
                                       AND s.flg_available = pk_supplies_constant.g_yes
                                     INNER JOIN supply_sup_area ssa
                                        ON ssa.id_supply_soft_inst = sks.id_supply_soft_inst
                                       AND ssa.flg_available = pk_supplies_constant.g_yes
                                       AND ssa.id_supply_area = i_id_supply_area
                                     WHERE sks.id_institution = i_prof.institution
                                       AND sks.id_software = i_prof.software
                                       AND sks.id_professional = i_prof.id
                                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                                       AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                           l_cons_loan = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_loan) AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                           l_cons_local = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_local)) OR
                                           (i_flg_consumption = pk_alert_constant.g_no AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                           l_req_loan = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_loan) AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                           l_req_local = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_local)) OR
                                           (i_flg_consumption IS NULL AND
                                           sks.flg_cons_type IN
                                           (pk_supplies_constant.g_consumption_type_loan,
                                              pk_supplies_constant.g_consumption_type_local,
                                              pk_supplies_constant.g_consumption_type_implant)))
                                     ORDER BY desc_val);
                    ELSIF (l_count_dept > 0 AND l_count_prof = 0)
                    THEN
                    
                        g_error := 'ELSIF (l_count_dept > 0 AND l_count_prof = 0)';
                        OPEN o_types FOR
                            SELECT val, desc_val
                              FROM (SELECT DISTINCT sks.flg_cons_type val,
                                                    pk_sysdomain.get_domain(l_consumption_type,
                                                                            sks.flg_cons_type,
                                                                            i_lang) desc_val
                                      FROM supply_soft_inst sks
                                     INNER JOIN supply s
                                        ON sks.id_supply = s.id_supply
                                       AND s.flg_available = pk_supplies_constant.g_yes
                                     INNER JOIN supply_sup_area ssa
                                        ON ssa.id_supply_soft_inst = sks.id_supply_soft_inst
                                       AND ssa.flg_available = pk_supplies_constant.g_yes
                                       AND ssa.id_supply_area = i_id_supply_area
                                     WHERE sks.id_institution = i_prof.institution
                                       AND sks.id_software = i_prof.software
                                       AND sks.id_dept = l_dept
                                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                                       AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                           l_cons_loan = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_loan) AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                           l_cons_local = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_local)) OR
                                           (i_flg_consumption = pk_alert_constant.g_no AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                           l_req_loan = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_loan) AND
                                           ((sks.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                           l_req_local = pk_supplies_constant.g_yes) OR
                                           sks.flg_cons_type <> pk_supplies_constant.g_consumption_type_local)) OR
                                           (i_flg_consumption IS NULL AND
                                           sks.flg_cons_type IN
                                           (pk_supplies_constant.g_consumption_type_loan,
                                              pk_supplies_constant.g_consumption_type_local,
                                              pk_supplies_constant.g_consumption_type_implant)))
                                     ORDER BY desc_val);
                    
                    ELSIF (l_count_prof = 0 AND l_count_dept = 0)
                    THEN
                    
                        g_error := 'ELSIF (l_count_prof = 0 AND l_count_dept = 0)';
                        OPEN o_types FOR
                            SELECT val, desc_val
                              FROM (SELECT yyy.flg_cons_type val,
                                           pk_sysdomain.get_domain(l_consumption_type, yyy.flg_cons_type, i_lang) desc_val
                                      FROM (SELECT DISTINCT flg_cons_type
                                              FROM (SELECT flg_cons_type, s.code_supply
                                                      FROM supply_soft_inst ssi
                                                     INNER JOIN supply s
                                                        ON ssi.id_supply = s.id_supply
                                                       AND s.flg_available = pk_supplies_constant.g_yes
                                                     INNER JOIN supply_sup_area ssa
                                                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                                       AND ssa.flg_available = pk_supplies_constant.g_yes
                                                       AND ssa.id_supply_area = i_id_supply_area
                                                     WHERE ssi.id_institution = i_prof.institution
                                                       AND ssi.id_software = i_prof.software
                                                       AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                                           ((ssi.flg_cons_type =
                                                           pk_supplies_constant.g_consumption_type_loan AND
                                                           l_cons_loan = pk_supplies_constant.g_yes) OR
                                                           ssi.flg_cons_type <>
                                                           pk_supplies_constant.g_consumption_type_loan) AND
                                                           ((ssi.flg_cons_type =
                                                           pk_supplies_constant.g_consumption_type_local AND
                                                           l_cons_local = pk_supplies_constant.g_yes) OR
                                                           ssi.flg_cons_type <>
                                                           pk_supplies_constant.g_consumption_type_local)) OR
                                                           (i_flg_consumption = pk_alert_constant.g_no AND
                                                           ((ssi.flg_cons_type =
                                                           pk_supplies_constant.g_consumption_type_loan AND
                                                           l_req_loan = pk_supplies_constant.g_yes) OR
                                                           ssi.flg_cons_type <>
                                                           pk_supplies_constant.g_consumption_type_loan) AND
                                                           ((ssi.flg_cons_type =
                                                           pk_supplies_constant.g_consumption_type_local AND
                                                           l_req_local = pk_supplies_constant.g_yes) OR
                                                           ssi.flg_cons_type <>
                                                           pk_supplies_constant.g_consumption_type_local)) OR
                                                           (i_flg_consumption IS NULL AND
                                                           ssi.flg_cons_type IN
                                                           (pk_supplies_constant.g_consumption_type_loan,
                                                              pk_supplies_constant.g_consumption_type_local,
                                                              pk_supplies_constant.g_consumption_type_implant)))
                                                       AND rownum > 0) xxx
                                             WHERE pk_translation.get_translation(i_lang, xxx.code_supply) IS NOT NULL) yyy
                                     ORDER BY desc_val);
                    END IF;
                END IF;
            
            ELSE
                OPEN o_types FOR
                    SELECT val, desc_val
                      FROM (SELECT yyy.flg_cons_type val,
                                   pk_sysdomain.get_domain(l_consumption_type, yyy.flg_cons_type, i_lang) desc_val
                              FROM (SELECT DISTINCT flg_cons_type
                                      FROM (SELECT flg_cons_type, s.code_supply
                                              FROM supply_soft_inst ssi
                                             INNER JOIN supply s
                                                ON ssi.id_supply = s.id_supply
                                               AND s.flg_available = pk_supplies_constant.g_yes
                                             INNER JOIN supply_sup_area ssa
                                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                                               AND ssa.flg_available = pk_supplies_constant.g_yes
                                               AND ssa.id_supply_area = i_id_supply_area
                                             WHERE ssi.id_institution = i_id_inst_dest
                                               AND ssi.id_software = pk_sr_planning.g_software_oris
                                               AND ((i_flg_consumption = pk_supplies_constant.g_yes AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                                   l_cons_loan = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type <> pk_supplies_constant.g_consumption_type_loan) AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                                   l_cons_local = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type <> pk_supplies_constant.g_consumption_type_local)) OR
                                                   (i_flg_consumption = pk_alert_constant.g_no AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                                                   l_req_loan = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type <> pk_supplies_constant.g_consumption_type_loan) AND
                                                   ((ssi.flg_cons_type = pk_supplies_constant.g_consumption_type_local AND
                                                   l_req_local = pk_supplies_constant.g_yes) OR
                                                   ssi.flg_cons_type <> pk_supplies_constant.g_consumption_type_local)) OR
                                                   (i_flg_consumption IS NULL AND
                                                   ssi.flg_cons_type IN
                                                   (pk_supplies_constant.g_consumption_type_loan,
                                                      pk_supplies_constant.g_consumption_type_local,
                                                      pk_supplies_constant.g_consumption_type_implant)))
                                               AND rownum > 0) xxx
                                     WHERE pk_translation.get_translation(i_lang, xxx.code_supply) IS NOT NULL) yyy
                             ORDER BY desc_val);
            
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
                                              'GET_TYPE_CONSUMPTION',
                                              o_error);
            pk_types.open_my_cursor(o_types);
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
    
        l_flg_cons_type supply_soft_inst.flg_cons_type%TYPE;
    
    BEGIN
    
        g_error         := 'GET FLG_CONS_TYPE';
        l_flg_cons_type := pk_supplies_core.get_consumption_type(i_lang, i_prof, i_id_supply_area, i_id_supply);
    
        g_error := 'GET SYS_DOMAIN DESC';
        OPEN o_type_consumption FOR
            SELECT sd.desc_val, sd.val
              FROM sys_domain sd
             WHERE sd.code_domain = decode(i_id_supply_area,
                                           pk_supplies_constant.g_area_surgical_supplies,
                                           'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                           'SUPPLY_SOFT_INST.FLG_CONS_TYPE')
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND (sd.val = l_flg_cons_type OR (l_flg_cons_type = pk_supplies_constant.g_consumption_type_loan AND
                   sd.val = pk_supplies_constant.g_consumption_type_local))
             ORDER BY sd.rank, sd.desc_val;
    
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
            RETURN FALSE;
    END get_type_consumption_list;

    /*Revised*/
    FUNCTION get_id_supply_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply          IN supply.id_supply%TYPE,
        i_flg_type           IN supply.flg_type%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE DEFAULT NULL,
        o_id_supply_area     OUT supply_area.id_supply_area%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type    supply.flg_type%TYPE;
        l_id_category category.id_category%TYPE;
    
    BEGIN
    
        g_error       := 'get profissional category';
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        IF l_id_category = pk_supplies_constant.g_ancillary
        THEN
            o_id_supply_area := NULL; --to all supply areas
        ELSE
            IF i_id_supply_workflow IS NOT NULL
            THEN
                g_error := 'GET ID_SUPPLY_AREA from ID_SUPPLY_WORKFLOW:=' || i_id_supply_workflow;
                SELECT sw.id_supply_area
                  INTO o_id_supply_area
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_id_supply_workflow;
            ELSE
                IF i_flg_type IS NULL
                THEN
                    g_error := 'GET FLG_TYPE FOR ID_SUPPLY:=' || i_id_supply;
                    SELECT s.flg_type
                      INTO l_flg_type
                      FROM supply s
                     WHERE s.id_supply = i_id_supply;
                ELSE
                    l_flg_type := i_flg_type;
                END IF;
            
                IF l_flg_type = pk_supplies_constant.g_act_ther_supply
                THEN
                    o_id_supply_area := pk_supplies_constant.g_area_activity_therapy; --Activity Therapist
                ELSE
                
                    IF i_id_supply IS NOT NULL
                    THEN
                        BEGIN
                            SELECT b.id_supply_area
                              INTO o_id_supply_area
                              FROM supply_soft_inst a
                             INNER JOIN supply_sup_area b
                                ON a.id_supply_soft_inst = b.id_supply_soft_inst
                             WHERE a.id_supply = i_id_supply
                               AND a.id_institution = i_prof.institution
                               AND a.id_software = i_prof.software
                               AND b.flg_available = pk_supplies_constant.g_yes;
                        EXCEPTION
                            WHEN OTHERS THEN
                                o_id_supply_area := pk_supplies_constant.g_area_supplies;
                        END;
                    ELSE
                        o_id_supply_area := pk_supplies_constant.g_area_supplies;
                    END IF;
                END IF;
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
                                              'GET_ID_SUPPLY_AREA',
                                              o_error);
            RETURN FALSE;
    END get_id_supply_area;

    FUNCTION get_id_supply_soft_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_dept          IN episode.id_dept_requested%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN supply_soft_inst.id_supply_soft_inst%TYPE IS
    
        l_id_supply_soft_inst supply_soft_inst.id_supply_soft_inst%TYPE;
    
    BEGIN
    
        IF i_id_inst_dest IS NULL
        THEN
        
            SELECT id_supply_soft_inst
              INTO l_id_supply_soft_inst
              FROM (SELECT sswi.id_supply_soft_inst
                      FROM (SELECT 1 ra, ssi.id_supply_soft_inst
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND ssi.id_professional = i_prof.id
                               AND ssi.id_supply = i_id_supply
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                            UNION ALL --DEPARTMENT
                            SELECT 2 ra, ssi.id_supply_soft_inst
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND ssi.id_dept = i_id_dept
                               AND ssi.id_supply = i_id_supply
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                            UNION ALL
                            SELECT 3 ra, ssi.id_supply_soft_inst
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_prof.institution
                               AND ssi.id_software = i_prof.software
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                               AND ssi.id_supply = i_id_supply) sswi
                     ORDER BY sswi.ra) t
             WHERE rownum = 1;
        
        ELSE
        
            SELECT id_supply_soft_inst
              INTO l_id_supply_soft_inst
              FROM (SELECT sswi.id_supply_soft_inst
                      FROM (SELECT 1 ra, ssi.id_supply_soft_inst
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_id_inst_dest
                               AND ssi.id_software = pk_sr_planning.g_software_oris
                               AND ssi.id_supply = i_id_supply
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                            UNION ALL --DEPARTMENT
                            SELECT 2 ra, ssi.id_supply_soft_inst
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_id_inst_dest
                               AND ssi.id_software = pk_sr_planning.g_software_oris
                               AND ssi.id_dept = i_id_dept
                               AND ssi.id_supply = i_id_supply
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                            UNION ALL
                            SELECT 3 ra, ssi.id_supply_soft_inst
                              FROM supply_soft_inst ssi
                             INNER JOIN supply s
                                ON s.id_supply = ssi.id_supply
                             INNER JOIN supply_sup_area ssa
                                ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                               AND ssa.flg_available = pk_supplies_constant.g_yes
                               AND ssa.id_supply_area = i_id_supply_area
                             WHERE ssi.id_institution = i_id_inst_dest
                               AND ssi.id_software = pk_sr_planning.g_software_oris
                               AND (ssi.flg_cons_type = i_consumption_type OR i_consumption_type IS NULL)
                               AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                               AND ssi.id_supply = i_id_supply) sswi
                     ORDER BY sswi.ra) t
             WHERE rownum = 1;
        
        END IF;
    
        RETURN l_id_supply_soft_inst;
    
    END get_id_supply_soft_inst;

    FUNCTION update_supply_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_supply_request table_number;
        l_check_status      supply_request.flg_status%TYPE;
        l_flg_status        supply_request.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_error := 'GET CURRENT TIMESTAMP';
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_supply_workflow IS NOT NULL
           AND i_id_supply_workflow.count > 0
        THEN
            g_error := 'GET ID_SUPPLY_REQUEST';
            SELECT sw.id_supply_request
              BULK COLLECT
              INTO l_id_supply_request
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.*
                                               FROM TABLE(i_id_supply_workflow) t)
               AND sw.id_supply_request IS NOT NULL;
        END IF;
    
        g_error := 'REMOVE DUPLICATE RECORDS IN L_ID_SUPPLY_REQUEST COLLECTION';
    
        --remove duplicate id_supply_request
        l_id_supply_request := SET(l_id_supply_request);
    
        FOR c IN 1 .. l_id_supply_request.count
        LOOP
            g_error        := 'GET THE NEW SUPPLY REQUEST STATUS FOR ID_SUPPLY_REQUEST ' || l_id_supply_request(c);
            l_check_status := pk_supplies_core.check_supply_request_status(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_id_supply_request => l_id_supply_request(c));
        
            SELECT sr.flg_status
              INTO l_flg_status
              FROM supply_request sr
             WHERE sr.id_supply_request = l_id_supply_request(c);
        
            IF l_flg_status != l_check_status
            THEN
            
                g_error := 'CALL SET_SUPPLY_REQUEST_HIST PROCEDURE';
                pk_supplies_utils.set_supply_request_hist(l_id_supply_request(c));
            
                g_error := 'UDPATE SUPPLY_REQUEST TABLE FOR ID_SUPPLY_REQUEST ' || l_id_supply_request(c);
                ts_supply_request.upd(id_supply_request_in => l_id_supply_request(c),
                                      id_professional_in   => i_prof.id,
                                      flg_status_in        => l_check_status,
                                      id_prof_cancel_in    => CASE
                                                                  WHEN l_check_status = pk_supplies_constant.g_srt_cancelled THEN
                                                                   i_prof.id
                                                              END,
                                      dt_cancel_in         => CASE
                                                                  WHEN l_check_status = pk_supplies_constant.g_srt_cancelled THEN
                                                                   g_sysdate_tstz
                                                              END,
                                      rows_out             => l_rows_out);
            END IF;
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE FOR SUPPLY_REQUEST';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_REQUEST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SUPPLY_REQUEST',
                                              o_error);
            RETURN FALSE;
    END update_supply_request;

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
    
        l_dt_request         supply_workflow.dt_request%TYPE;
        l_dt_return          supply_workflow.dt_returned%TYPE;
        l_flg_status_sw      supply_workflow.flg_status%TYPE;
        l_flg_status         supply_workflow.flg_status%TYPE;
        l_dt_supply_workflow supply_workflow.dt_supply_workflow%TYPE;
        l_id_supply_area     supply_workflow.id_supply_area%TYPE;
    
        l_id_supply_workflow_parent supply_workflow.id_consumption_parent%TYPE;
        l_qty_requested             supply_workflow.quantity%TYPE;
        l_qty_consumed              supply_workflow.quantity%TYPE;
        l_previous_flg_status       supply_workflow_hist.flg_status%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CREATE REQUEST WORKFLOWS';
        FOR i IN 1 .. i_supply_workflow.count
        LOOP
            IF i_supply_workflow(i) IS NOT NULL
            THEN
                pk_supplies_utils.set_supply_workflow_hist(i_supply_workflow(i), NULL, NULL);
            
                g_error := 'GET STATUS AND DT_SUPPLY_WORKFLOW FOR ID_SUPPLY_WORKFLOW: ' || i_supply_workflow(i);
            
                SELECT sw.flg_status, sw.dt_supply_workflow, sw.id_supply_area
                  INTO l_flg_status_sw, l_dt_supply_workflow, l_id_supply_area
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_supply_workflow(i);
            
                l_dt_request := pk_date_utils.get_string_tstz(i_lang,
                                                              i_prof,
                                                              i_dt_request(i),
                                                              pk_date_utils.get_timezone(i_lang, i_prof));
                l_dt_return  := pk_date_utils.get_string_tstz(i_lang,
                                                              i_prof,
                                                              i_dt_return(i),
                                                              pk_date_utils.get_timezone(i_lang, i_prof));
            
                l_flg_status := pk_supplies_utils.get_status_req(i_prof,
                                                                 nvl(i_supply_loc(i),
                                                                     pk_supplies_core.get_default_location(i_lang,
                                                                                                           i_prof,
                                                                                                           l_id_supply_area,
                                                                                                           nvl(i_supply_set(i),
                                                                                                               i_supply(i)))));
            
                g_error := 'UPDATE SUPPLY_WORKFLOW TABLE FOR ID_SUPPLY_WORKFLOW ' || i_supply_workflow(i);
            
                ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow(i),
                                       id_professional_in    => i_prof.id,
                                       id_episode_in         => i_id_episode,
                                       id_supply_in          => i_supply(i),
                                       id_supply_set_in      => i_supply_set(i),
                                       id_supply_location_in => i_supply_loc(i),
                                       --quantity_in           => 1, --i_supply_qty(i),
                                       quantity_in   => nvl(i_supply_qty(i), 1),
                                       id_context_in => i_id_context(i),
                                       /*flg_context_in        => i_flg_context(i),*/
                                       flg_status_in         => CASE
                                                                    WHEN l_flg_status_sw IN
                                                                         (pk_supplies_constant.g_sww_request_central,
                                                                          pk_supplies_constant.g_sww_request_local) THEN
                                                                     l_flg_status
                                                                    ELSE
                                                                     l_flg_status_sw
                                                                END,
                                       dt_request_in         => l_dt_request,
                                       dt_returned_in        => l_dt_return,
                                       dt_supply_workflow_in => CASE
                                                                    WHEN l_flg_status_sw = l_flg_status THEN
                                                                     l_dt_supply_workflow
                                                                    ELSE
                                                                     g_sysdate_tstz
                                                                END,
                                       id_req_reason_in      => i_id_req_reason(i),
                                       id_req_reason_nin     => FALSE,
                                       notes_in              => i_notes(i),
                                       notes_nin             => FALSE,
                                       flg_cons_type_in      => i_flg_cons_type(i),
                                       cod_table_in          => i_cod_table(i),
                                       rows_out              => l_rows_out);
            
                SELECT sw.id_consumption_parent
                  INTO l_id_supply_workflow_parent
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_supply_workflow(i);
            
                IF l_id_supply_workflow_parent IS NOT NULL
                THEN
                    SELECT sw.quantity
                      INTO l_qty_requested
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = l_id_supply_workflow_parent;
                
                    SELECT SUM(sw.quantity)
                      INTO l_qty_consumed
                      FROM supply_workflow sw
                     WHERE sw.id_consumption_parent = l_id_supply_workflow_parent
                       AND sw.flg_status IN (pk_supplies_constant.g_sww_consumed);
                
                    IF l_qty_consumed < l_qty_requested
                    THEN
                        SELECT flg_status
                          INTO l_previous_flg_status
                          FROM (SELECT swh.flg_status
                                  FROM supply_workflow_hist swh
                                 WHERE swh.id_supply_workflow = l_id_supply_workflow_parent
                                 ORDER BY swh.id_supply_workflow_hist DESC)
                         WHERE rownum = 1;
                    
                        ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow_parent,
                                               flg_status_in         => l_previous_flg_status,
                                               rows_out              => l_rows_out);
                    ELSE
                        ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow_parent,
                                               flg_status_in         => pk_supplies_constant.g_sww_all_consumed,
                                               rows_out              => l_rows_out);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE FOR SUPPLY_WORKFLOW';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
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
            RETURN FALSE;
    END update_supply_workflow;

    FUNCTION get_list_req_cons_no_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        i_flg_status     IN table_varchar DEFAULT NULL,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_shortcut        sys_shortcut.id_sys_shortcut%TYPE := NULL;
        l_id_category     wf_status_config.id_category%TYPE;
        t_epis            table_number := table_number();
        l_loaned_msg      sys_message.desc_message%TYPE;
        l_with_return_msg sys_message.desc_message%TYPE;
        l_cancelled_desc  sys_message.desc_message%TYPE;
        l_msg_reusable    sys_message.desc_message%TYPE;
        l_msg_disposable  sys_message.desc_message%TYPE;
        l_flg_type        table_varchar;
        l_id_supply_area  supply_area.id_supply_area%TYPE := i_id_supply_area;
    
        l_filter_by_status VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        g_error := 'GET Message';
    
        l_loaned_msg := pk_message.get_message(i_lang      => i_lang,
                                               i_code_mess => pk_act_therap_constant.g_msg_loaned_units);
    
        l_with_return_msg := pk_message.get_message(i_lang      => i_lang,
                                                    i_code_mess => pk_act_therap_constant.g_msg_with_return);
    
        l_cancelled_desc := pk_message.get_message(i_lang      => i_lang,
                                                   i_code_mess => pk_act_therap_constant.g_msg_cancelled);
    
        l_msg_reusable := pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T096');
    
        l_msg_disposable := pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T095');
    
        IF i_flg_status IS NOT NULL
           OR i_flg_status.count > 0
        THEN
            l_filter_by_status := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'get past episodes';
        IF l_id_supply_area IS NULL
        THEN
            g_error := 'GET SUPPLY AREA';
            IF NOT get_id_supply_area(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_supply      => NULL,
                                      i_flg_type       => i_flg_type(1),
                                      o_id_supply_area => l_id_supply_area,
                                      o_error          => o_error)
            
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF l_id_supply_area IN
           (pk_supplies_constant.g_area_surgical_supplies, pk_supplies_constant.g_area_activity_therapy) -- if surgical supplies or Activity Therapist supplies
        THEN
            t_epis := table_number(i_episode);
        ELSE
            IF i_episode IS NOT NULL
            THEN
                t_epis := table_number(i_episode);
            ELSE
                SELECT e.id_episode
                  BULK COLLECT
                  INTO t_epis
                  FROM episode e
                 WHERE e.id_patient = i_patient
                   AND e.flg_status = pk_alert_constant.g_active;
            END IF;
        END IF;
    
        g_error       := 'get the prof category';
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        IF l_id_category = pk_supplies_constant.g_ancillary
        THEN
            l_flg_type := table_varchar(pk_supplies_constant.g_supply_kit_type,
                                        pk_supplies_constant.g_supply_set_type,
                                        pk_supplies_constant.g_supply_type,
                                        pk_supplies_constant.g_supply_equipment_type,
                                        pk_supplies_constant.g_supply_implant_type);
        ELSE
            l_flg_type := i_flg_type;
        END IF;
    
        g_error := 'open cursor';
        OPEN o_list FOR
            SELECT DISTINCT tb.*,
                            decode(int_notes, '---', '', int_notes) notes,
                            (SELECT REPLACE(REPLACE(l_loaned_msg, pk_act_therap_constant.g_1st_replace, tb.quantity),
                                            pk_act_therap_constant.g_2nd_replace,
                                            tb.conf_quantity)
                               FROM dual) AS nr_units,
                            (SELECT check_supply_wf_cancel(i_lang,
                                                           i_prof,
                                                           l_id_supply_area,
                                                           tb.status,
                                                           tb.quantity,
                                                           tb.total_quantity)
                               FROM dual) flg_cancelable,
                            tb.total_quantity loaned_total_qty,
                            (SELECT get_delivered_units(i_lang, i_prof, tb.id_supply_workflow, tb.id_sup_workflow_parent)
                               FROM dual) delivered_total_qty,
                            CASE
                                 WHEN tb.status IN
                                      (pk_supplies_constant.g_sww_cancelled, pk_supplies_constant.g_sww_deliver_cancelled) THEN
                                  l_cancelled_desc
                                 WHEN tb.status = pk_supplies_constant.g_sww_loaned THEN
                                  decode(tb.quantity, tb.total_quantity, '', l_with_return_msg)
                             END supply_status_desc
            
              FROM (SELECT DISTINCT sw.id_supply_workflow,
                                    wsc.rank,
                                    sw.flg_status status,
                                    (SELECT pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_STATUS', sw.flg_status, i_lang)
                                       FROM dual) desc_status,
                                    s.id_supply id_supply,
                                    nvl(sw.flg_context, pk_supplies_constant.g_context_supplies) flg_context,
                                    (SELECT DISTINCT pk_sysdomain.get_domain('SUPPLY_WORKFLOW.FLG_CONTEXT',
                                                                             nvl(sw.flg_context,
                                                                                 pk_supplies_constant.g_context_supplies),
                                                                             i_lang)
                                       FROM dual) desc_context,
                                    (SELECT DISTINCT pk_translation.get_translation(i_lang, s.code_supply)
                                       FROM dual) desc_supply,
                                    nvl(sw.quantity, 1) quantity,
                                    sw.flg_reusable,
                                    decode(sw.flg_reusable, pk_supplies_constant.g_yes, l_msg_reusable, l_msg_disposable) desc_reusable,
                                    sw.flg_cons_type,
                                    (SELECT pk_sysdomain.get_domain(decode(sw.id_supply_area,
                                                                           pk_supplies_constant.g_area_surgical_supplies,
                                                                           'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                                           'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                                                    sw.flg_cons_type,
                                                                    i_lang)
                                       FROM dual) desc_cons_type,
                                    sw.id_supply_location,
                                    (SELECT pk_date_utils.date_send_tsz(i_lang, sw.dt_request, i_prof)
                                       FROM dual) dt_request,
                                    (SELECT pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof)
                                       FROM dual) dt_returned,
                                    (SELECT pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                  sw.dt_returned,
                                                                                  i_prof.institution,
                                                                                  i_prof.software)
                                       FROM dual) date_returned,
                                    (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             sw.dt_returned,
                                                                             i_prof.institution,
                                                                             i_prof.software)
                                       FROM dual) hour_returned,
                                    (SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                               sw.dt_returned,
                                                                               i_prof.institution,
                                                                               i_prof.software)
                                       FROM dual) dt_hr_returned,
                                    sw.id_req_reason,
                                    (SELECT pk_translation.get_translation(i_lang, sre.code_supply_reason)
                                       FROM supply_reason sre
                                      WHERE sre.id_supply_reason = sw.id_req_reason) desc_reason,
                                    (SELECT get_supply_workflow_col_value(i_lang,
                                                                          i_prof,
                                                                          sw.id_supply_workflow,
                                                                          'SUPPLIES_T109',
                                                                          'SUPPLY_WORKFLOW')
                                       FROM dual) int_notes,
                                    sr.id_room_req id_room_req,
                                    (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                                       FROM room r
                                      WHERE r.id_room = sr.id_room_req) room,
                                    (SELECT pk_translation.get_translation(i_lang, d.code_department)
                                       FROM department d, room r
                                      WHERE d.id_department = r.id_department
                                        AND r.id_room = sr.id_room_req) service,
                                    (SELECT pk_translation.get_translation(i_lang, dt.code_dept)
                                       FROM department d, room r, dept dt
                                      WHERE d.id_department = r.id_department
                                        AND r.id_room = sr.id_room_req
                                        AND d.id_dept = dt.id_dept) department,
                                    (SELECT pk_translation.get_translation(i_lang, sl.code_supply_location)
                                       FROM supply_location sl
                                      WHERE sw.id_supply_location = sl.id_supply_location) desc_location,
                                    (SELECT pk_supplies_core.get_attributes(i_lang,
                                                                            i_prof,
                                                                            sw.id_supply_area,
                                                                            s.id_supply,
                                                                            sw.id_supply_location)
                                       FROM dual) desc_supply_attrib,
                                    (SELECT pk_sup_status.get_sup_status_string(i_lang,
                                                                                 i_prof,
                                                                                 sw.flg_status,
                                                                                 l_shortcut,
                                                                                 wsc.id_workflow,
                                                                                 l_id_category,
                                                                                 decode(i_prof.software,
                                                                                        pk_act_therap_constant.g_id_software_at,
                                                                                        decode(sw.flg_status,
                                                                                               pk_supplies_constant.g_sww_loaned,
                                                                                               CASE
                                                                                                   WHEN sw.dt_returned < current_timestamp THEN
                                                                                                    sw.dt_returned
                                                                                                   ELSE
                                                                                                    NULL
                                                                                               END),
                                                                                        sw.dt_supply_workflow),
                                                                                 sw.id_episode)
                                       FROM dual) status_string,
                                    (SELECT pk_translation.get_translation(i_lang, st.code_supply_type)
                                       FROM dual) desc_supply_type,
                                    st.id_supply_type,
                                    sw.total_quantity,
                                    (SELECT sw.total_avail_quantity - get_nr_loaned_units(i_lang,
                                                                                          i_prof,
                                                                                          sw.id_supply_area,
                                                                                          s.id_supply,
                                                                                          sw.id_episode,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL)
                                       FROM dual) nr_units_avail,
                                    sw.id_sup_workflow_parent,
                                    sw.total_avail_quantity AS conf_quantity,
                                    sw.barcode_scanned,
                                    sw.asset_number,
                                    sw.cod_table desc_table,
                                    sw.flg_preparing,
                                    sw.id_supply_request,
                                    sw.id_supply_area,
                                    CASE
                                         WHEN (SELECT COUNT(*)
                                                 FROM supply_workflow_hist ht
                                                WHERE ht.id_supply_workflow = sw.id_supply_workflow) = 0
                                              OR nvl((SELECT decode(ht.flg_status, sw.flg_status, 0)
                                                       FROM supply_workflow_hist ht
                                                      WHERE ht.id_supply_workflow = sw.id_supply_workflow
                                                        AND ht.id_supply_workflow_hist =
                                                            (SELECT MAX(id_supply_workflow_hist)
                                                               FROM supply_workflow_hist
                                                              WHERE id_supply_workflow = sw.id_supply_workflow)),
                                                     0) = 0 THEN
                                          pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                          pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                                                    i_prof,
                                                                                                    sw.id_professional,
                                                                                                    sw.dt_supply_workflow,
                                                                                                    sw.id_episode),
                                                                   ' (@)')
                                     END prof_last_upd,
                                    CASE
                                         WHEN (SELECT COUNT(*)
                                                 FROM supply_workflow_hist ht
                                                WHERE ht.id_supply_workflow = sw.id_supply_workflow) = 0
                                              OR nvl((SELECT decode(ht.flg_status, sw.flg_status, 0)
                                                       FROM supply_workflow_hist ht
                                                      WHERE ht.id_supply_workflow = sw.id_supply_workflow
                                                        AND ht.id_supply_workflow_hist =
                                                            (SELECT MAX(id_supply_workflow_hist)
                                                               FROM supply_workflow_hist
                                                              WHERE id_supply_workflow = sw.id_supply_workflow)),
                                                     0) = 0 THEN
                                          pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                          pk_string_utils.surround(pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                                      sw.dt_supply_workflow,
                                                                                                      i_prof),
                                                                   ' (@)')
                                     END dt_last_upd,
                                    decode(sw.flg_status,
                                           pk_supplies_constant.g_sww_deliver_institution,
                                           pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) ||
                                           pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                                                     i_prof,
                                                                                                     sw.id_professional,
                                                                                                     sw.dt_supply_workflow,
                                                                                                     sw.id_episode),
                                                                    ' (@)')) prof_returned,
                                    s.flg_type,
                                    -- requisitou o material
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) prof_req,
                                    sr.id_professional id_prof_req,
                                    pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     sr.id_professional,
                                                                     sr.dt_request,
                                                                     sr.id_episode) speciality_req,
                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, sr.dt_request, i_prof) dt_req,
                                    -- consumiu o material
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, sw.id_professional) prof_consum,
                                    sw.id_professional id_prof_consum,
                                    pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     sw.id_professional,
                                                                     sw.dt_request,
                                                                     sw.id_episode) speciality_consum,
                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, sw.dt_supply_workflow, i_prof) dt_consum
                      FROM supply_workflow sw
                      JOIN supply s
                        ON sw.id_supply = s.id_supply
                      LEFT JOIN supply_request sr
                        ON sw.id_supply_request = sr.id_supply_request
                      JOIN wf_status_config wsc
                        ON wsc.id_status = (SELECT pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status)
                                              FROM dual)
                       AND wsc.id_workflow = decode(sw.id_supply_area,
                                                    pk_supplies_constant.g_area_activity_therapy,
                                                    pk_supplies_constant.g_id_workflow_at,
                                                    pk_supplies_constant.g_area_surgical_supplies,
                                                    pk_supplies_constant.g_id_workflow_sr,
                                                    pk_supplies_constant.g_id_workflow)
                      JOIN supply_type st
                        ON st.id_supply_type = s.id_supply_type
                     WHERE sw.flg_status != pk_supplies_constant.g_sww_predefined
                       AND (sw.id_supply_area = l_id_supply_area OR l_id_supply_area IS NULL)
                       AND EXISTS
                     (SELECT 0
                              FROM supplies_wf_status sws
                             WHERE sws.flg_status = sw.flg_status)
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND (sw.flg_status IN (SELECT t1.column_value
                                                FROM TABLE(i_flg_status) t1) OR
                           l_filter_by_status = pk_alert_constant.g_no)
                       AND s.flg_type IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                           t1.column_value
                                            FROM TABLE(l_flg_type) t1)
                       AND sw.id_episode IN (SELECT /*+opt_estimate(table t2 rows=1)*/
                                              t2.column_value
                                               FROM TABLE(t_epis) t2
                                             UNION
                                             SELECT i_episode
                                               FROM dual)
                     ORDER BY wsc.rank, sw.dt_returned) tb;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LIST_REQ_CONS_NO_CAT',
                                              o_error);
            pk_types.open_cursor_if_closed(o_list);
            RETURN FALSE;
    END get_list_req_cons_no_cat;

    FUNCTION get_list_req_cons_reprt_no_cat
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN episode.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN supply.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type table_varchar := table_varchar();
    BEGIN
        IF i_flg_type = pk_supplies_constant.g_act_ther_supply
        THEN
            l_flg_type := table_varchar(pk_supplies_constant.g_act_ther_supply);
        ELSE
            l_flg_type := table_varchar(pk_supplies_constant.g_supply_type,
                                        pk_supplies_constant.g_supply_kit_type,
                                        pk_supplies_constant.g_supply_set_type);
        END IF;
    
        g_error := 'CALL pk_supplies_core.GET_LIST_REQ_CONS_REPORT_NO_CAT';
        IF NOT get_list_req_cons_no_cat(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_id_supply_area => NULL,
                                        i_patient        => i_patient,
                                        i_episode        => i_episode,
                                        i_flg_type       => l_flg_type,
                                        i_flg_status     => NULL,
                                        o_list           => o_list,
                                        o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_list_req_cons_reprt_no_cat;

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
    
        g_error := 'GET_SET_COMPOSITION';
        OPEN o_supply_info FOR
            SELECT t.*
              FROM (SELECT DISTINCT s.id_supply,
                                    pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                                    decode(s.flg_type,
                                           pk_supplies_constant.g_supply_kit_type,
                                           NULL,
                                           pk_supplies_constant.g_supply_set_type,
                                           NULL,
                                           s.id_supply_type) id_supply_type,
                                    s.flg_type,
                                    ssi.quantity quantity,
                                    ssi.flg_reusable,
                                    ssi.flg_cons_type flg_consumption_type,
                                    pk_sysdomain.get_domain(decode(ssa.id_supply_area,
                                                                   pk_supplies_constant.g_area_surgical_supplies,
                                                                   'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                                   'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                                            ssi.flg_cons_type,
                                                            i_lang) desc_consumption_type,
                                    pk_supplies_core.get_attributes(i_lang, i_prof, ssa.id_supply_area, s.id_supply) desc_supply_attrib,
                                    ssi.id_supply_soft_inst,
                                    ssi.flg_editable,
                                    loc.id_supply_location
                      FROM supply_soft_inst ssi
                     INNER JOIN supply s
                        ON ssi.id_supply = s.id_supply
                       AND s.flg_available = pk_supplies_constant.g_yes
                      JOIN supply_relation sr
                        ON s.id_supply = sr.id_supply_item
                      LEFT JOIN supply_type st
                        ON st.id_supply_type = s.id_supply_type
                       AND st.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                       AND ssa.flg_available = pk_supplies_constant.g_yes
                       AND ssa.id_supply_area = i_id_supply_area
                      LEFT JOIN (SELECT sld.id_supply_location, sld.id_supply_soft_inst, sl.code_supply_location
                                  FROM supply_loc_default sld
                                 INNER JOIN supply_location sl
                                    ON sld.id_supply_location = sl.id_supply_location
                                   AND sld.flg_default = pk_supplies_constant.g_yes) loc
                        ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                     WHERE sr.id_supply = i_id_supply_set
                       AND ssi.id_institution = i_prof.institution
                       AND ssi.id_software = i_prof.software
                       AND ssi.id_professional IN (i_prof.id, 0)
                       AND pk_translation.get_translation(i_lang, s.code_supply) IS NOT NULL
                     ORDER BY 2) t;
    
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
        g_error := 'OPEN CURSOR';
        OPEN o_supplies FOR
            SELECT sw.id_supply_workflow id_supply_workflow,
                   s.id_supply id_supply,
                   s.flg_type flg_supply_type,
                   pk_translation.get_translation(i_lang, s.code_supply) description,
                   sw.quantity quantity,
                   sw.flg_status flg_status,
                   sw.barcode_scanned barcode_id,
                   sw.flg_reusable,
                   sw.id_supply_set,
                   pk_translation.get_translation(i_lang, sd.code_supply) set_description,
                   sw.flg_cons_type,
                   pk_date_utils.date_send_tsz(i_lang, sw.dt_expiration, i_prof) expiration_date,
                   sw.lot lot_id
              FROM supply_workflow sw
              JOIN supply s
                ON s.id_supply = sw.id_supply
              LEFT JOIN supply sd
                ON sw.id_supply_set = sd.id_supply
             WHERE sw.id_context = i_id_context
               AND sw.flg_context = i_flg_context
               AND sw.flg_status != pk_supplies_constant.g_sww_cancelled
             ORDER BY description;
    
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
            pk_types.open_cursor_if_closed(o_supplies);
            RETURN FALSE;
    END get_workflow_by_context;

    FUNCTION get_id_workflow
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_workflow.id_supply_area%TYPE
    ) RETURN wf_workflow.id_workflow%TYPE IS
    
        l_error       t_error_out;
        l_id_workflow wf_workflow.id_workflow%TYPE;
    
    BEGIN
    
        g_error := 'Init get_id_workflow / i_id_supply_area=' || i_id_supply_area;
        CASE i_id_supply_area
            WHEN pk_supplies_constant.g_area_activity_therapy THEN
                l_id_workflow := pk_supplies_constant.g_id_workflow_at;
            WHEN pk_supplies_constant.g_area_surgical_supplies THEN
                l_id_workflow := pk_supplies_constant.g_id_workflow_sr;
            ELSE
                l_id_workflow := pk_supplies_constant.g_id_workflow;
        END CASE;
    
        RETURN l_id_workflow;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_WORKFLOW',
                                              l_error);
            RETURN NULL;
    END get_id_workflow;

    FUNCTION get_supply_wf_status_string
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_status         IN supply_workflow.flg_status%TYPE,
        i_id_sys_shortcut    IN sys_shortcut.id_sys_shortcut%TYPE,
        i_id_workflow        IN wf_workflow.id_workflow%TYPE,
        i_id_supply_area     IN supply_workflow.id_supply_area%TYPE,
        i_id_category        IN category.id_category%TYPE,
        i_dt_returned        IN supply_workflow.dt_returned%TYPE,
        i_dt_request         IN supply_workflow.dt_request%TYPE,
        i_dt_supply_workflow IN supply_workflow.dt_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        i_supply_workflow    IN supply_workflow.id_supply_workflow%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_supply_wf_status_string';
        l_params          VARCHAR2(1000 CHAR);
        l_error           t_error_out;
        l_status_string   VARCHAR2(1000 CHAR);
        l_id_workflow     wf_workflow.id_workflow%TYPE;
        l_date            supply_workflow.dt_supply_workflow%TYPE;
        l_sum_supply      NUMBER;
        l_final_count     NUMBER;
        l_tbl_sum_supply  table_number;
        l_tbl_final_count table_number;
        l_icon_mismatch   VARCHAR2(10 CHAR);
        l_supply_type     supply.flg_type%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_flg_status=' || i_flg_status ||
                    ' i_id_sys_shortcut=' || i_id_sys_shortcut || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_supply_area=' || i_id_supply_area || ' i_id_category=' || i_id_category || ' i_id_episode=' ||
                    i_id_episode;
    
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        BEGIN
            BEGIN
                SELECT flg_type, qty_before + nvl(qty_added, 0), qty_final_count
                  INTO l_supply_type, l_sum_supply, l_final_count
                  FROM (SELECT DISTINCT s.flg_type,
                                        SUM(sw.quantity) over(PARTITION BY sw.id_supply) qty_before,
                                        nvl(ssc.qty_added, 0) qty_added,
                                        ssc.qty_final_count
                          FROM sr_supply_count ssc
                         INNER JOIN sr_supply_relation ssr
                            ON ssc.id_sr_supply_count = ssr.id_sr_supply_count
                         INNER JOIN supply_workflow sw
                            ON sw.id_supply_workflow = ssr.id_supply_workflow
                         INNER JOIN supply s
                            ON s.id_supply = sw.id_supply
                         WHERE ssc.id_sr_supply_count =
                               (SELECT sw.id_sr_supply_count
                                  FROM sr_supply_relation sw
                                 WHERE sw.id_supply_workflow = i_supply_workflow));
            EXCEPTION
                WHEN OTHERS THEN
                    SELECT s.flg_type
                      INTO l_supply_type
                      FROM supply_workflow a
                     INNER JOIN supply s
                        ON a.id_supply = s.id_supply
                     WHERE a.id_supply_workflow = i_supply_workflow;
                
                    l_sum_supply  := 0;
                    l_final_count := 0;
            END;
        
            IF l_supply_type != pk_supplies_constant.g_supply_set_type
            THEN
                IF l_final_count IS NOT NULL
                   AND l_final_count != l_sum_supply
                THEN
                    l_icon_mismatch := pk_supplies_constant.g_yes;
                END IF;
            ELSE
                BEGIN
                    SELECT flg_type, qty_before + nvl(qty_added, 0), qty_final_count
                      INTO l_supply_type, l_sum_supply, l_final_count
                      FROM (SELECT DISTINCT s.flg_type,
                                            SUM(sw.quantity) over(PARTITION BY sw.id_supply) qty_before,
                                            nvl(ssc.qty_added, 0) qty_added,
                                            ssc.qty_final_count
                              FROM sr_supply_count ssc
                             INNER JOIN sr_supply_relation ssr
                                ON ssc.id_sr_supply_count = ssr.id_sr_supply_count
                             INNER JOIN supply_workflow sw
                                ON sw.id_supply_workflow = ssr.id_supply_workflow
                             INNER JOIN supply s
                                ON s.id_supply = sw.id_supply
                             WHERE ssc.id_sr_supply_count IN
                                   (SELECT sw.id_sr_supply_count
                                      FROM sr_supply_relation sw
                                     WHERE sw.id_sup_workflow_parent = i_supply_workflow));
                EXCEPTION
                    WHEN OTHERS THEN
                    
                        l_sum_supply  := 0;
                        l_final_count := 0;
                END;
            
                IF l_final_count IS NOT NULL
                   AND l_final_count != l_sum_supply
                THEN
                    l_icon_mismatch := pk_supplies_constant.g_yes;
                END IF;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        -- getting workflow identifier
        IF i_id_workflow IS NULL
        THEN
            l_id_workflow := get_id_workflow(i_lang => i_lang, i_prof => i_prof, i_id_supply_area => i_id_supply_area);
        ELSE
            l_id_workflow := i_id_workflow;
        END IF;
    
        -- getting date
        g_error := 'getting date / ' || l_params;
        IF i_prof.software = pk_act_therap_constant.g_id_software_at
        THEN
            IF i_flg_status = pk_supplies_constant.g_sww_loaned
            THEN
                CASE
                    WHEN i_dt_returned < current_timestamp THEN
                        l_date := i_dt_returned;
                    ELSE
                        l_date := NULL;
                END CASE;
            END IF;
        ELSIF i_flg_status IN
              (pk_supplies_constant.g_sww_prepared_pharmacist, pk_supplies_constant.g_sww_prepared_technician)
        THEN
            l_date := i_dt_supply_workflow;
        ELSE
            l_date := nvl(i_dt_request, i_dt_supply_workflow);
        END IF;
    
        -- getting status string
        g_error         := 'Call pk_sup_status.get_sup_status_string / ' || l_params;
        l_status_string := pk_sup_status.get_sup_status_string(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_status        => i_flg_status,
                                                               i_shortcut      => i_id_sys_shortcut,
                                                               i_id_workflow   => l_id_workflow,
                                                               i_id_category   => i_id_category,
                                                               i_date          => l_date,
                                                               i_id_episode    => i_id_episode,
                                                               i_icon_mismatch => l_icon_mismatch);
    
        RETURN l_status_string;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_supply_wf_status_string;

    FUNCTION get_supply_wf_grid_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_wf_data  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_params   VARCHAR2(1000 CHAR);
        l_nr_avail sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_supply_workflow=' ||
                    pk_utils.to_string(i_supply_workflow);
    
        IF i_supply_workflow IS NULL
           OR i_supply_workflow.count = 0
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_other_exception;
        END IF;
    
        l_nr_avail := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_act_therap_constant.g_msg_avail_units);
    
        g_error := 'OPEN o_supply_wf_data FOR / ' || l_params;
        OPEN o_supply_wf_data FOR
            SELECT REPLACE(l_nr_avail, pk_act_therap_constant.g_1st_replace, t.nr_units_avail) nr_units_avail_desc, t.*
              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                     sw.id_supply_workflow,
                     sw.id_supply,
                     pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                     s.id_supply_type,
                     pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                     s.flg_type,
                     sw.quantity,
                     sw.id_unit_measure,
                     pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || sw.id_unit_measure) desc_unit_measure,
                     sw.flg_reusable,
                     pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_REUSABLE', sw.flg_reusable, i_lang) desc_flg_reusable,
                     sw.flg_cons_type flg_consumption_type,
                     pk_sysdomain.get_domain(decode(sw.id_supply_area,
                                                    pk_supplies_constant.g_area_surgical_supplies,
                                                    'SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                    'SUPPLY_SOFT_INST.FLG_CONS_TYPE'),
                                             sw.flg_cons_type,
                                             i_lang) desc_consumption_type,
                     pk_supplies_core.get_attributes(i_lang,
                                                     i_prof,
                                                     sw.id_supply_area,
                                                     sw.id_supply,
                                                     sw.id_supply_location) desc_supply_attrib,
                     get_nr_loaned_units(i_lang,
                                         i_prof,
                                         sw.id_supply_area,
                                         sw.id_supply,
                                         sw.id_episode,
                                         NULL,
                                         NULL,
                                         NULL) nr_units_avail,
                     sw.id_supply_location,
                     pk_translation.get_translation(i_lang,
                                                    'SUPPLY_LOCATION.CODE_SUPPLY_LOCATION.' || sw.id_supply_location) desc_supply_location,
                     sw.id_req_reason,
                     pk_translation.get_translation(i_lang, sr.code_supply_reason) req_reason_desc,
                     sw.notes,
                     pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof) dt_returned,
                     pk_date_utils.date_send_tsz(i_lang, sw.dt_request, i_prof) request_for
                      FROM supply_workflow sw
                      JOIN TABLE(CAST(i_supply_workflow AS table_number)) t
                        ON (t.column_value = sw.id_supply_workflow)
                      JOIN supply s
                        ON s.id_supply = sw.id_supply
                      JOIN supply_type st
                        ON st.id_supply_type = s.id_supply_type
                      LEFT JOIN supply_reason sr
                        ON sr.id_supply_reason = sw.id_req_reason) t;
    
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
    
        g_error := 'OPEN O_TYPES';
        OPEN o_types FOR
            SELECT t.val, t.desc_val, t.id_area
              FROM (SELECT t.val, t.desc_val, pk_supplies_constant.g_area_supplies id_area
                      FROM TABLE(pk_supplies_core.get_supply_filter_list(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_id_supply_area  => NULL,
                                                                         i_episode         => i_episode,
                                                                         i_flg_consumption => i_flg_consumption,
                                                                         i_id_inst_dest    => NULL)) t
                    UNION ALL
                    SELECT NULL val,
                           pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE.SR',
                                                   pk_supplies_constant.g_consumption_type_local,
                                                   i_lang) desc_val,
                           pk_supplies_constant.g_area_surgical_supplies id_area
                      FROM dual) t;
    
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
            RETURN FALSE;
    END get_coding_supply_type_cons;

    FUNCTION get_supply_set_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_request  IN supply_workflow.id_supply_request%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_supplies pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT listagg(desc_supply, '; ') within GROUP(ORDER BY 1) desc_supply
          INTO l_desc_supplies
          FROM (SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) || ' (' ||
                       pk_utils.to_str(SUM(sw.quantity)) || ')' desc_supply
                  FROM supply_workflow sw
                 WHERE sw.id_supply_set IN (SELECT id_supply
                                              FROM supply_workflow
                                             WHERE id_supply_workflow = i_supply_workflow)
                   AND sw.id_supply_request = i_supply_request
                 GROUP BY sw.id_supply, sw.id_supply_request, sw.dt_request);
    
        RETURN l_desc_supplies;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supply_set_info;

    FUNCTION check_changes_supply_count
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        i_qty_added           IN sr_supply_count.qty_added%TYPE,
        i_qty_final_count     IN sr_supply_count.qty_final_count%TYPE,
        i_id_recouncile_count IN sr_supply_count.id_reconcile_reason%TYPE,
        i_notes               IN sr_supply_count.notes%TYPE,
        o_has_changes         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_get_records IS
            SELECT ssc.qty_added, ssc.qty_final_count, ssc.id_reconcile_reason, ssc.notes
              FROM sr_supply_count ssc
             WHERE ssc.id_sr_supply_count = i_id_sr_supply_count;
    
        TYPE cursor_sup_count IS TABLE OF c_get_records%ROWTYPE;
        l_supply_count cursor_sup_count;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_GET_RECORDS';
        OPEN c_get_records;
        FETCH c_get_records BULK COLLECT
            INTO l_supply_count;
        CLOSE c_get_records;
    
        g_error := 'CHECK IF THERE ARE CHANGES';
        IF nvl(l_supply_count(1).qty_added, -1) = nvl(i_qty_added, -1)
           AND nvl(l_supply_count(1).qty_final_count, -1) = nvl(i_qty_final_count, -1)
           AND nvl(l_supply_count(1).id_reconcile_reason, -1) = nvl(i_id_recouncile_count, -1)
           AND nvl(l_supply_count(1).notes, 'null') = nvl(i_notes, 'null')
        THEN
            o_has_changes := pk_alert_constant.g_no;
        ELSE
            o_has_changes := pk_supplies_constant.g_yes;
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
                                              'CHECK_CHANGES_SUPPLY_COUNT',
                                              o_error);
            RETURN FALSE;
    END check_changes_supply_count;

    FUNCTION insert_sr_supply_count_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_supply_count IN sr_supply_count.id_sr_supply_count%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        r_sr_supply_count         sr_supply_count%ROWTYPE;
        l_id_sr_supply_count_hist sr_supply_count_hist.id_sr_supply_count_hist%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        SELECT ssc.*
          INTO r_sr_supply_count
          FROM sr_supply_count ssc
         WHERE ssc.id_sr_supply_count = i_id_sr_supply_count;
    
        l_id_sr_supply_count_hist := ts_sr_supply_count_hist.next_key;
    
        ts_sr_supply_count_hist.ins(id_sr_supply_count_hist_in => l_id_sr_supply_count_hist,
                                    id_sr_supply_count_in      => i_id_sr_supply_count,
                                    qty_added_in               => r_sr_supply_count.qty_added,
                                    qty_final_count_in         => r_sr_supply_count.qty_final_count,
                                    id_reconcile_reason_in     => r_sr_supply_count.id_reconcile_reason,
                                    notes_in                   => r_sr_supply_count.notes,
                                    id_prof_reg_in             => r_sr_supply_count.id_prof_reg,
                                    dt_reg_in                  => r_sr_supply_count.dt_reg,
                                    rows_out                   => l_rows_out);
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR SR_SUPPLY_COUNT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_SUPPLY_COUNT_HIST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_SR_SUPPLY_COUNT_HIST',
                                              o_error);
            RETURN FALSE;
    END insert_sr_supply_count_hist;

    FUNCTION get_id_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        i_id_supply          IN supply_workflow.id_supply%TYPE,
        i_cod_table          IN supply_workflow.cod_table%TYPE,
        o_id_supply_workflow OUT table_number,
        o_id_sr_supply_count OUT sr_supply_relation.id_sr_supply_count%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sr_supply_count table_number;
    
    BEGIN
    
        --get all records for id_sr_supply_count
        g_error := 'GET ID_SUPPLY_WORKFLOW and id_sr_supply_count for id_supply ' || i_id_supply || ' and cod_table : ' ||
                   i_cod_table;
        BEGIN
            SELECT ssr.id_sr_supply_count
              BULK COLLECT
              INTO l_id_sr_supply_count
              FROM supply_workflow sw
              JOIN sr_supply_relation ssr
                ON ssr.id_supply_workflow = sw.id_supply_workflow
              JOIN sr_supply_count ssc
                ON ssc.id_sr_supply_count = ssr.id_sr_supply_count
             WHERE sw.id_supply = i_id_supply
               AND sw.flg_status = pk_supplies_constant.g_sww_cons_and_count
               AND nvl(sw.cod_table, 0) = nvl(i_cod_table, 0)
               AND ssc.qty_final_count IS NULL
               AND sw.id_supply_workflow IN (SELECT /*+opt_estimate(table, t1, scale_rows=1))*/
                                              t1.column_value
                                               FROM TABLE(i_id_supply_workflow) t1);
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sr_supply_count := NULL;
        END;
    
        g_error := 'GET ID_SUPPLY_WORKFLOW  for id_supply ' || i_id_supply || ' and cod_table : ' || i_cod_table;
        IF l_id_sr_supply_count IS NOT NULL
        THEN
            --get all id_supply_workflow records where don't exists in sr_supply_relation
            BEGIN
                SELECT sw.id_supply_workflow
                  BULK COLLECT
                  INTO o_id_supply_workflow
                  FROM supply_workflow sw
                 WHERE sw.id_supply = i_id_supply
                   AND sw.flg_status = pk_supplies_constant.g_sww_cons_and_count
                   AND nvl(sw.cod_table, 0) = nvl(i_cod_table, 0)
                   AND sw.id_supply_workflow NOT IN
                       (SELECT /*+opt_estimate(table, t1, scale_rows=1))*/
                         t1.column_value
                          FROM TABLE(i_id_supply_workflow) t1
                         INNER JOIN sr_supply_relation ssr
                            ON ssr.id_supply_workflow = t1.column_value)
                   AND sw.id_supply_workflow IN (SELECT /*+opt_estimate(table, t2, scale_rows=1))*/
                                                  t2.column_value
                                                   FROM TABLE(i_id_supply_workflow) t2);
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_supply_workflow := NULL;
            END;
        END IF;
        --remove repeated id_sr_supply_count
        l_id_sr_supply_count := SET(l_id_sr_supply_count);
    
        -- if the collection is not empty, there only exists one id_sr_supply_count 
        IF l_id_sr_supply_count IS NOT NULL
           AND l_id_sr_supply_count.count > 0
        THEN
            o_id_sr_supply_count := l_id_sr_supply_count(1);
        ELSE
            o_id_sr_supply_count := NULL;
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
                                              'GET_ID_SUPPLY_WORKFLOW',
                                              o_error);
            RETURN FALSE;
    END get_id_supply_workflow;

    FUNCTION set_relation_sup_count
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_workflow  IN table_number,
        i_id_supply           IN supply_workflow.id_supply%TYPE,
        i_cod_table           IN supply_workflow.cod_table%TYPE,
        i_qty_added           IN sr_supply_count.qty_added%TYPE,
        i_qty_final_count     IN sr_supply_count.qty_final_count%TYPE,
        i_id_recouncile_count IN sr_supply_count.id_reconcile_reason%TYPE,
        i_notes               IN sr_supply_count.notes%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_supply_workflow  table_number := table_number();
        l_id_sr_supply_count  sr_supply_count.id_sr_supply_count%TYPE;
        l_tbl_sr_supply_count table_number := table_number();
        l_has_changes         VARCHAR2(1 CHAR);
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL GET_ID_SUPPLY_WORKFLOW FOR ID_SUPPLY ' || i_id_supply || ' AND COD_TABLE ' || i_cod_table;
        IF NOT get_id_supply_workflow(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_id_supply_workflow => i_id_supply_workflow,
                                      i_id_supply          => i_id_supply,
                                      i_cod_table          => i_cod_table,
                                      o_id_supply_workflow => l_id_supply_workflow,
                                      o_id_sr_supply_count => l_id_sr_supply_count,
                                      o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_id_sr_supply_count IS NULL
        THEN
        
            --FOR i IN 1..l_id_supply_workflow.count LOOP
            g_error              := 'GET NEXT REQUEST ID for ID_SR_SUPPLY_COUNT';
            l_id_sr_supply_count := ts_sr_supply_count.next_key;
        
            g_error := 'INSERT TS_SR_SUPPLY_COUNT FOR ID_SR_SUPPLY_COUNT: ' || l_id_sr_supply_count;
            ts_sr_supply_count.ins(id_sr_supply_count_in  => l_id_sr_supply_count,
                                   qty_added_in           => i_qty_added,
                                   qty_final_count_in     => i_qty_final_count,
                                   id_reconcile_reason_in => i_id_recouncile_count,
                                   notes_in               => i_notes,
                                   id_prof_reg_in         => i_prof.id,
                                   dt_reg_in              => g_sysdate_tstz,
                                   rows_out               => l_rows_out);
        
            g_error := 'CALL PROCESS_INSERT FOR SR_SUPPLY_COUNT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_SUPPLY_COUNT',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
            --l_tbl_sr_supply_count.extend;
            --l_tbl_sr_supply_count(i) := l_id_sr_supply_count;
            --END LOOP;
        
        ELSE
            g_error := 'CHECK IF THERE ARE CHANGES IN SR_SUPPLY_COUNT TABLE ' || l_id_sr_supply_count;
            IF NOT check_changes_supply_count(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_sr_supply_count  => l_id_sr_supply_count,
                                              i_qty_added           => i_qty_added,
                                              i_qty_final_count     => i_qty_final_count,
                                              i_id_recouncile_count => i_id_recouncile_count,
                                              i_notes               => i_notes,
                                              o_has_changes         => l_has_changes,
                                              o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'IF THERE ARE CHANGES ' || l_has_changes ||
                       ' IN SR_SUPPLY_COUNT SO IS NECESSARY SEND DATA FOR HISTORY TABLE AND UPDATE THE SR_SUPPLY_COUNT';
        
            IF l_has_changes = pk_supplies_constant.g_yes
            THEN
                g_error := 'INSERT INTO SR_SUPPLY_COUNT_HIST FOR ID_SR_SUPPLY_COUNT: ' || l_id_sr_supply_count;
                IF NOT insert_sr_supply_count_hist(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_sr_supply_count => l_id_sr_supply_count,
                                                   o_error              => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'UPDATE TS_SR_SUPPLY_COUNT FOR ID_SR_SUPPLY_COUNT: ' || l_id_sr_supply_count;
                ts_sr_supply_count.upd(id_sr_supply_count_in  => l_id_sr_supply_count,
                                       qty_added_in           => i_qty_added,
                                       qty_final_count_in     => i_qty_final_count,
                                       id_reconcile_reason_in => i_id_recouncile_count,
                                       notes_in               => i_notes,
                                       id_prof_reg_in         => i_prof.id,
                                       dt_reg_in              => g_sysdate_tstz,
                                       rows_out               => l_rows_out);
            
                g_error := 'CALL PROCESS_UPDATE FOR SR_SUPPLY_COUNT';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_SUPPLY_COUNT',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        IF l_id_supply_workflow.count > 0
           AND l_id_supply_workflow(1) IS NOT NULL
        THEN
            FOR i IN 1 .. l_id_supply_workflow.count
            LOOP
                g_error := 'CALL TS_SR_SUPPLY_RELATION FOR ID_SUPPLY_WORKFLOW: ' || l_id_supply_workflow(i) ||
                           ' AND ID_SR_SUPPLY_COUNT ' || l_id_sr_supply_count;
                ts_sr_supply_relation.ins(id_supply_workflow_in => l_id_supply_workflow(i),
                                          id_sr_supply_count_in => l_id_sr_supply_count,
                                          rows_out              => l_rows_out);
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR SR_SUPPLY_RELATION';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_SUPPLY_RELATION',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END LOOP;
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
                                              'SET_RELATION_SUP_COUNT',
                                              o_error);
            RETURN FALSE;
    END set_relation_sup_count;

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
    
        -- insert counting supplies
        IF i_id_supply IS NOT NULL
        THEN
            FOR i IN 1 .. i_id_supply_workflow.count
            LOOP
            
                IF i_id_supply_workflow(i).count > 0
                THEN
                
                    g_error := 'CALL SET_RELATION_SUP_COUNT';
                    IF NOT set_relation_sup_count(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_supply_workflow  => i_id_supply_workflow(i),
                                                  i_id_supply           => i_id_supply(i),
                                                  i_cod_table           => i_cod_table(i),
                                                  i_qty_added           => i_qty_added(i),
                                                  i_qty_final_count     => (i_qty_final_count(i)),
                                                  i_id_recouncile_count => i_id_recouncile_count(i),
                                                  i_notes               => i_notes(i),
                                                  o_error               => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                END IF;
            
                IF i_qty_final_count(i) IS NOT NULL
                THEN
                    -- change status for consumed, loaned or delivery needed
                    g_error := 'CALL SET_SUPPLY_CONS_COUNT FOR ID_SR_SUPPLY_COUNT: ';
                    IF NOT pk_supplies_core.set_supply_consumption(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_supply_workflow => i_id_supply_workflow(i),
                                                                   o_error              => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
            END LOOP;
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
                                              'SET_SUP_CONS_COUNT',
                                              o_error);
            RETURN FALSE;
    END set_sup_cons_count;

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
    
        l_screen_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SUPPLIES_T011');
        l_mess1        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SUPPLIES_M001');
        l_mess2        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SUPPLIES_M002');
    
        l_flg_status           table_varchar := table_varchar(pk_supplies_constant.g_sww_cancelled);
        l_id_repeated_supplies table_number;
    
    BEGIN
    
        g_error := 'CHECK IF THERE ARE REPEATED SUPPLIES BETWEEN SURGICAL PROCEDURES FOR THE SAME EPISODE: ' ||
                   i_id_episode;
        IF NOT check_repeated_supplies(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_id_episode           => i_id_episode,
                                       i_id_supply_area       => pk_supplies_constant.g_area_surgical_supplies,
                                       i_flg_status           => l_flg_status,
                                       i_id_supply_no_saved   => i_id_supply_no_saved,
                                       i_id_supply_checked    => i_id_supply_checked,
                                       o_id_repeated_supplies => l_id_repeated_supplies,
                                       o_error                => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --If there exists repeated supplies, so is necessary show these ones
        IF l_id_repeated_supplies.count > 0
           AND l_id_repeated_supplies IS NOT NULL
        THEN
            o_show_message := pk_supplies_constant.g_yes;
        ELSE
            o_show_message := pk_alert_constant.g_no;
        END IF;
    
        IF o_show_message = pk_supplies_constant.g_yes
        THEN
            g_error := 'OPEN CURSOR O_REPEATED_SUPPLIES';
            OPEN o_repeated_supplies FOR
                SELECT desc_supply, id_supply
                  FROM (SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || column_value) ||
                               pk_supplies_constant.g_semicolon desc_supply,
                               column_value id_supply
                          FROM (SELECT /*+opt_estimate(table, t1, scale_rows=1))*/
                                 t1.column_value
                                  FROM TABLE(l_id_repeated_supplies) t1))
                 ORDER BY desc_supply;
        
            OPEN o_labels FOR
                SELECT l_screen_title screen_title, l_mess1 message_1, l_mess2 message_2
                  FROM dual;
        END IF;
    
        pk_types.open_cursor_if_closed(o_repeated_supplies);
        pk_types.open_cursor_if_closed(o_labels);
    
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
            pk_types.open_cursor_if_closed(o_repeated_supplies);
            pk_types.open_cursor_if_closed(o_labels);
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
    
        g_error := 'OPEN CURSOR O_SUP_CONS_COUNT';
        OPEN o_sup_cons_count FOR
            SELECT z.id_supply,
                   z.desc_supply,
                   z.desc_supply_attrib,
                   z.desc_supply_type,
                   z.desc_table,
                   z.qty_added,
                   z.qty_before,
                   z.flg_type_rank,
                   z.desc_flg_type,
                   z.flg_type,
                   pk_string_utils.str_split(i_list => z.id_supply_workflow, i_delim => '|') id_supply_workflow,
                   get_supply_info_viewer(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_supply_workflow => pk_string_utils.str_split(i_list  => z.id_supply_workflow,
                                                                                            i_delim => '|'),
                                          i_id_supply_count    => NULL) tooltip_desc
              FROM (SELECT t.id_supply,
                           t.supply_name desc_supply,
                           t.desc_supply_attrib,
                           t.sup_type desc_supply_type,
                           t.cod_table desc_table,
                           (SELECT qty_added
                              FROM sr_supply_count ssr
                             WHERE ssr.id_sr_supply_count IN
                                   (SELECT ssr1.id_sr_supply_count
                                      FROM sr_supply_count ssr1
                                      JOIN sr_supply_relation sss
                                        ON sss.id_sr_supply_count = ssr1.id_sr_supply_count
                                      JOIN supply_workflow sw
                                        ON sw.id_supply_workflow = sss.id_supply_workflow
                                     WHERE sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                                       AND sw.flg_status = pk_supplies_constant.g_sww_cons_and_count
                                       AND nvl(sw.cod_table, 0) = nvl(t.cod_table, 0)
                                       AND sw.id_supply = t.id_supply
                                          /*AND sw.id_supply_workflow = t.id_supply_workflow*/
                                       AND sw.id_episode = i_id_episode)) qty_added,
                           listagg(t.id_supply_workflow, '|') within GROUP(ORDER BY t.id_supply_workflow) "ID_SUPPLY_WORKFLOW",
                           SUM(t.qty_before) AS qty_before,
                           t.flg_type_rank,
                           pk_sysdomain.get_domain('SUPPLY.FLG_TYPE.SR', t.flg_type, i_lang) desc_flg_type,
                           t.flg_type
                      FROM (SELECT sw.id_supply,
                                   sw.id_supply_workflow,
                                   pk_translation.get_translation(i_lang, s.code_supply) supply_name,
                                   pk_supplies_api_db.get_attributes(i_lang, i_prof, sw.id_supply_area, s.id_supply) desc_supply_attrib,
                                   decode(sw.id_supply_set,
                                          NULL,
                                          pk_translation.get_translation(i_lang, st.code_supply_type),
                                          pk_translation.get_translation(i_lang, 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.20576')) sup_type,
                                   sw.cod_table,
                                   ssc.qty_added qty_added,
                                   sw.quantity qty_before,
                                   ssr.id_sr_supply_count,
                                   s.flg_type,
                                   decode(s.flg_type,
                                          pk_supplies_constant.g_supply_set_type,
                                          1,
                                          pk_supplies_constant.g_supply_kit_type,
                                          2,
                                          pk_supplies_constant.g_supply_equipment_type,
                                          3,
                                          pk_supplies_constant.g_supply_implant_type,
                                          4,
                                          5) flg_type_rank
                              FROM supply_workflow sw
                             INNER JOIN supply s
                                ON s.id_supply = sw.id_supply
                             INNER JOIN supply_type st
                                ON st.id_supply_type = s.id_supply_type
                              LEFT JOIN sr_supply_relation ssr
                                ON ssr.id_supply_workflow = sw.id_supply_workflow
                              LEFT JOIN sr_supply_count ssc
                                ON ssc.id_sr_supply_count = ssr.id_sr_supply_count
                             WHERE sw.id_episode = i_id_episode
                               AND sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                               AND s.flg_type != pk_supplies_constant.g_supply_set_type
                               AND (sw.flg_status = pk_supplies_constant.g_sww_cons_and_count OR
                                   (sw.id_supply_set IS NOT NULL AND
                                   sw.flg_status != pk_supplies_constant.g_sww_cancelled AND EXISTS
                                    (SELECT 1
                                        FROM supply_workflow sws
                                       INNER JOIN supply ss
                                          ON ss.id_supply = sws.id_supply
                                       WHERE sws.id_episode = i_id_episode
                                         AND ss.id_supply = sw.id_supply_set
                                         AND sws.flg_status = pk_supplies_constant.g_sww_cons_and_count)))) t
                     GROUP BY t.id_supply,
                              t.supply_name,
                              t.desc_supply_attrib,
                              t.sup_type,
                              t.cod_table,
                              t.flg_type,
                              t.flg_type_rank,
                              t.qty_added
                     ORDER BY t.flg_type_rank, t.supply_name) z;
    
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
            RETURN FALSE;
    END get_sup_cons_count;

    FUNCTION tf_surg_supply_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_sr_supply_count IN sr_supply_count.id_sr_supply_count%TYPE
    ) RETURN t_surg_supply_count
        PIPELINED IS
    
        l_surg_supply_count t_surg_supply_count;
        l_limit             NUMBER(6) := 1000;
    
        CURSOR c_surg_supply_count IS
            SELECT t.id_sr_supply_count,
                   t.id_supply,
                   t.desc_supply,
                   t.desc_supply_attrib,
                   t.cod_table,
                   t.flg_type,
                   t.desc_supply_type,
                   t.id_supply_type,
                   t.desc_code_supply_type,
                   t.qty_before
              FROM (SELECT ssr.id_sr_supply_count,
                           sw.id_supply,
                           pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) desc_supply,
                           pk_supplies_api_db.get_attributes(i_lang, i_prof, sw.id_supply_area, sw.id_supply) desc_supply_attrib,
                           sw.cod_table,
                           s.flg_type,
                           pk_sysdomain.get_domain('SUPPLY.FLG_TYPE', s.flg_type, i_lang) desc_supply_type,
                           st.id_supply_type,
                           pk_translation.get_translation(i_lang, st.code_supply_type) desc_code_supply_type,
                           --sw.quantity qty_before,
                           SUM(sw.quantity) over(PARTITION BY sw.id_supply, sw.cod_table) qty_before
                      FROM supply_workflow sw
                     INNER JOIN sr_supply_relation ssr
                        ON ssr.id_supply_workflow = sw.id_supply_workflow
                     INNER JOIN supply s
                        ON s.id_supply = sw.id_supply
                     INNER JOIN supply_type st
                        ON st.id_supply_type = s.id_supply_type
                     WHERE sw.id_episode = i_id_episode
                       AND (i_id_sr_supply_count IS NULL OR ssr.id_sr_supply_count = i_id_sr_supply_count)) t
            /*GROUP BY id_sr_supply_count,
            id_supply,
            desc_supply,
            desc_supply_attrib,
            cod_table,
            flg_type,
            desc_supply_type,
            id_supply_type,
            desc_code_supply_type,
            qty_before*/
            ;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_SURG_SUPPLY_COUNT';
        OPEN c_surg_supply_count;
        LOOP
            g_error := 'FETCH CURSOR C_SURG_SUPPLY_COUNT';
        
            FETCH c_surg_supply_count BULK COLLECT
                INTO l_surg_supply_count LIMIT l_limit;
            FOR i IN 1 .. l_surg_supply_count.count
            LOOP
                PIPE ROW(l_surg_supply_count(i));
            END LOOP;
            EXIT WHEN c_surg_supply_count%NOTFOUND;
        END LOOP;
    
        g_error := 'CLOSE CURSOR C_SURG_SUPPLY_COUNT';
        CLOSE c_surg_supply_count;
    
        RETURN;
    
    END tf_surg_supply_count;

    FUNCTION get_supplies_consumed_counted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_sup_cons_count FOR
            SELECT DISTINCT z.id_supply,
                            pk_string_utils.clob_to_varchar2(z.desc_supply, 1000) desc_supply,
                            pk_string_utils.clob_to_varchar2(z.desc_supply_attrib, 1000) desc_supply_attrib,
                            pk_string_utils.clob_to_varchar2(z.desc_supply_type, 1000) desc_supply_type,
                            z.desc_table,
                            z.id_sr_supply_count,
                            z.flg_type,
                            pk_string_utils.clob_to_varchar2(z.tooltip_desc, 1000) tooltip_desc,
                            z.qty_added qty_added,
                            z.qty_final qty_final,
                            z.qty_before qty_before
              FROM (SELECT t.id_supply,
                           t.desc_supply,
                           t.desc_supply_attrib,
                           t.desc_supply_type,
                           t.cod_table desc_table,
                           ssc.qty_added,
                           ssc.id_sr_supply_count,
                           ssc.qty_final_count qty_final,
                           t.qty_before,
                           s.flg_type,
                           get_supply_info_viewer(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_supply_workflow => NULL,
                                                  i_id_supply_count    => t.id_sr_supply_count) tooltip_desc
                      FROM TABLE(tf_surg_supply_count(i_lang, i_prof, i_id_episode, NULL)) t
                     INNER JOIN supply s
                        ON s.id_supply = t.id_supply
                     INNER JOIN sr_supply_count ssc
                        ON ssc.id_sr_supply_count = t.id_sr_supply_count) z;
    
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
            RETURN FALSE;
    END get_supplies_consumed_counted;

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
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_id_supply_workflow.count
        LOOP
            IF i_id_supply_workflow(i) IS NOT NULL
            THEN
                g_error := 'CALL PK_SUPPLIES_API_DB.SET_SUPPLY_WORKFLOW_HIST FOR ID_SUPPLY_WORKFLOW: ' ||
                           i_id_supply_workflow(i);
                pk_supplies_utils.set_supply_workflow_hist(i_id_supply_workflow(i), NULL, NULL);
            
                g_error := 'update supply_workflow table for  i_id_supply_workflow : ' || i_id_supply_workflow(i) ||
                           ' barcode_scanned: ' || i_barcode_scanned(i) || ' and table: ' || i_cod_table(i);
                ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_workflow(i),
                                       barcode_scanned_in    => i_barcode_scanned(i),
                                       flg_status_in         => pk_supplies_constant.g_sww_cons_and_count,
                                       cod_table_in          => i_cod_table(i),
                                       id_professional_in    => i_prof.id,
                                       dt_supply_workflow_in => g_sysdate_tstz,
                                       rows_out              => l_rows_out);
            
            END IF;
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE FOR SUPPLY_WORKFLOW';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                      i_list_columns => table_varchar('BARCODE_SCANNED',
                                                                      'COD_TABLE',
                                                                      'FLG_STATUS',
                                                                      'ID_PROFESSIONAL'),
                                      i_rowids       => l_rows_out,
                                      o_error        => o_error);
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT update_supply_request(i_lang               => i_lang,
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
                                              'SET_PREPARE_SUPPLIES_FOR_SURG',
                                              o_error);
        
            RETURN FALSE;
    END set_prepare_supplies_for_surg;

    FUNCTION set_ready_for_preparation_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_preparing      IN supply_workflow.flg_preparing%TYPE,
        o_id_supply_workflow OUT supply_workflow.id_supply_workflow%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL PK_SUPPLIES_API_DB.SET_SUPPLY_WORKFLOW_HIST FOR ID_SUPPLY_WORKFLOW: ' || i_id_supply_workflow;
        pk_supplies_api_db.set_supply_workflow_hist(i_id_supply_workflow, NULL, NULL);
    
        g_error := 'UPDATE SUPPLY_WORKFLOW TABLE FOR I_ID_SUPPLY_WORKFLOW : ' || i_id_supply_workflow;
        ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_workflow,
                               id_professional_in    => i_prof.id,
                               flg_status_in         => CASE i_flg_preparing
                                                            WHEN pk_supplies_constant.g_yes THEN
                                                             pk_supplies_constant.g_sww_prep_sup_for_surg
                                                            ELSE
                                                             pk_supplies_constant.g_sww_transport_concluded
                                                        END,
                               dt_supply_workflow_in => g_sysdate_tstz,
                               rows_out              => l_rows_out);
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE FOR SUPPLY_WORKFLOW';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                      i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW', 'I_PROF', 'FLG_STATUS'),
                                      i_rowids       => l_rows_out,
                                      o_error        => o_error);
    
        g_error := 'CALL UPDATE_SUPPLY_REQUEST FUNCTION';
        IF NOT pk_supplies_api_db.update_supply_request(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_supply_workflow => table_number(i_id_supply_workflow),
                                                        o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        o_id_supply_workflow := i_id_supply_workflow;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_READY_FOR_PREPARATION_INT',
                                              o_error);
            RETURN FALSE;
    END set_ready_for_preparation_int;

    FUNCTION set_ready_for_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_preparing         supply_workflow.flg_preparing%TYPE;
        l_id_supply_workflow    supply_workflow.id_supply_workflow%TYPE;
        l_id_supply_workflow_tn table_number := table_number();
    
    BEGIN
    
        FOR i IN 1 .. i_id_supply_workflow.count
        LOOP
            l_id_supply_workflow_tn.extend();
        
            g_error := 'GET FLG_PREPARING FOR ID_SUPPLY_WORKFLOW :' || i_id_supply_workflow(i);
            BEGIN
                SELECT sw.flg_preparing
                  INTO l_flg_preparing
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_id_supply_workflow(i);
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_preparing := NULL;
            END;
        
            g_error := 'CALL SET_READY_FOR_PREPARATION FOR ID_SUPPLY_WORKFLOW: ' || i_id_supply_workflow(i);
            IF NOT set_ready_for_preparation_int(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_supply_workflow => i_id_supply_workflow(i),
                                                 i_flg_preparing      => l_flg_preparing,
                                                 o_id_supply_workflow => l_id_supply_workflow,
                                                 o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_id_supply_workflow_tn(i) := l_id_supply_workflow;
        END LOOP;
    
        o_id_supply_workflow := l_id_supply_workflow_tn;
    
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
            RETURN FALSE;
    END set_ready_for_preparation;

    FUNCTION get_supply_attributs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_soft_inst IN table_number,
        o_flg_reusable     OUT table_varchar,
        o_flg_editable     OUT table_varchar,
        o_flg_preparing    OUT table_varchar,
        o_flg_countable    OUT table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_editable  table_varchar := table_varchar();
        l_flg_reusable  table_varchar := table_varchar();
        l_flg_preparing table_varchar := table_varchar();
        l_flg_countable table_varchar := table_varchar();
    
    BEGIN
    
        --get the supplies attributs
        FOR i IN 1 .. i_supply_soft_inst.count
        LOOP
            IF i_supply_soft_inst(i) IS NOT NULL
            THEN
            
                l_flg_editable.extend();
                l_flg_reusable.extend();
                l_flg_preparing.extend();
                l_flg_countable.extend();
            
                g_error := 'GET THE SUPPLIES ATTRIBUTS FOR THE ID_SUPPLY_SOFT_INST : ' || i_supply_soft_inst(i);
                BEGIN
                    SELECT ssi.flg_reusable, ssi.flg_editable, ssi.flg_preparing, ssi.flg_countable
                      INTO l_flg_reusable(i), l_flg_editable(i), l_flg_preparing(i), l_flg_countable(i)
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply_soft_inst = i_supply_soft_inst(i);
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_flg_reusable(i) := NULL;
                        l_flg_editable(i) := NULL;
                        l_flg_preparing(i) := NULL;
                        l_flg_countable(i) := NULL;
                END;
            
            ELSE
                l_flg_editable.extend();
                l_flg_reusable.extend();
                l_flg_preparing.extend();
                l_flg_countable.extend();
            
                l_flg_reusable(i) := NULL;
                l_flg_editable(i) := NULL;
                l_flg_preparing(i) := NULL;
                l_flg_countable(i) := NULL;
            
            END IF;
        END LOOP;
    
        o_flg_reusable  := l_flg_reusable;
        o_flg_editable  := l_flg_editable;
        o_flg_preparing := l_flg_preparing;
        o_flg_countable := l_flg_countable;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_ATTRIBUTS',
                                              o_error);
        
            RETURN FALSE;
    END get_supply_attributs;

    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_messages table_varchar := table_varchar('SR_SUPPLIES_M040',
                                                       'SR_SUPPLIES_M043',
                                                       'SR_SUPPLIES_M034',
                                                       'SR_SUPPLIES_M044',
                                                       'SR_SUPPLIES_M045',
                                                       'SR_SUPPLIES_M046',
                                                       'SR_SUPPLIES_M047',
                                                       'SR_SUPPLIES_M025',
                                                       'SR_SUPPLIES_M026',
                                                       'SR_SUPPLIES_M027');
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(2000 CHAR) INDEX BY sys_message.code_message%TYPE;
        aa_code_messages t_code_messages;
    
    BEGIN
    
        g_error := 'GET MESSAGES';
    
        FOR i IN l_code_messages.first .. l_code_messages.last
        LOOP
            aa_code_messages(l_code_messages(i)) := pk_message.get_message(i_lang, l_code_messages(i));
        END LOOP;
    
        g_error := 'OPEN CURSOR O_SUPPLY_COUNT_DETAIL';
        OPEN o_supply_count_detail FOR
            SELECT 10 rank,
                   ssc.id_sr_supply_count,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ssc.dt_reg, i_prof) tstamp,
                   ssc.dt_reg timestamp_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ssc.id_prof_reg) professional,
                   pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             ssc.id_prof_reg,
                                                                             ssc.dt_reg,
                                                                             NULL),
                                            pk_string_utils.g_pattern_parenthesis) speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ssc.id_prof_reg, ssc.dt_reg, NULL) spec_report,
                   t.id_supply,
                   aa_code_messages('SR_SUPPLIES_M047') supply_name_label,
                   t.desc_supply,
                   aa_code_messages('SR_SUPPLIES_M034') supply_attrib_label,
                   t.desc_supply_attrib,
                   aa_code_messages('SR_SUPPLIES_M043') supply_attrib_label,
                   t.flg_type supply_type,
                   t.desc_supply_type,
                   t.id_supply_type,
                   t.desc_code_supply_type,
                   aa_code_messages('SR_SUPPLIES_M046') qty_before_label,
                   t.qty_before,
                   aa_code_messages('SR_SUPPLIES_M045') qty_added_label,
                   SUM(nvl(ssc.qty_added, 0)) qty_added,
                   aa_code_messages('SR_SUPPLIES_M044') qty_final_label,
                   SUM(ssc.qty_final_count) qty_final,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         aa_code_messages('SR_SUPPLIES_M025')
                    END title_reconcile_reason_label,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         aa_code_messages('SR_SUPPLIES_M026')
                    END reconcile_reason_label,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ssc.id_reconcile_reason)
                    END reconcile_reason,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         aa_code_messages('SR_SUPPLIES_M027')
                    END notes_label,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         nvl(ssc.notes, pk_supplies_constant.g_dashes)
                    END notes,
                   aa_code_messages('SR_SUPPLIES_M040') cod_table_label,
                   t.cod_table
              FROM TABLE(pk_supplies_core.tf_surg_supply_count(i_lang, i_prof, i_id_episode, i_id_sr_supply_count)) t
             INNER JOIN sr_supply_count ssc
                ON ssc.id_sr_supply_count = t.id_sr_supply_count
            UNION ALL
            SELECT 100 rank,
                   ssch.id_sr_supply_count,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ssch.dt_reg, i_prof) tstamp,
                   ssch.dt_reg timestamp_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ssch.id_prof_reg) professional,
                   pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             ssch.id_prof_reg,
                                                                             ssch.dt_reg,
                                                                             NULL),
                                            pk_string_utils.g_pattern_parenthesis) speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ssch.id_prof_reg, ssch.dt_reg, NULL) spec_report,
                   t.id_supply,
                   aa_code_messages('SR_SUPPLIES_M047') supply_name_label,
                   t.desc_supply,
                   aa_code_messages('SR_SUPPLIES_M034') supply_attrib_label,
                   t.desc_supply_attrib,
                   aa_code_messages('SR_SUPPLIES_M043') supply_attrib_label,
                   t.flg_type supply_type,
                   t.desc_supply_type,
                   t.id_supply_type,
                   t.desc_code_supply_type desc_code_supply_type,
                   aa_code_messages('SR_SUPPLIES_M046') qty_before_label,
                   t.qty_before,
                   aa_code_messages('SR_SUPPLIES_M045') qty_added_label,
                   nvl(ssch.qty_added, 0) qty_added,
                   aa_code_messages('SR_SUPPLIES_M044') qty_final_label,
                   ssch.qty_final_count,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        aa_code_messages('SR_SUPPLIES_M025')
                   END title_reconcile_reason_label,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        aa_code_messages('SR_SUPPLIES_M026')
                   END reconcile_reason_label,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ssch.id_reconcile_reason)
                   END reconcile_reason,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        aa_code_messages('SR_SUPPLIES_M027')
                   END notes_label,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        nvl(ssch.notes, pk_supplies_constant.g_dashes)
                   END notes,
                   aa_code_messages('SR_SUPPLIES_M040') cod_table_label,
                   t.cod_table
              FROM TABLE(pk_supplies_core.tf_surg_supply_count(i_lang, i_prof, i_id_episode, i_id_sr_supply_count)) t
             INNER JOIN sr_supply_count_hist ssch
                ON ssch.id_sr_supply_count = t.id_sr_supply_count
             ORDER BY rank, timestamp_order DESC;
    
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
            RETURN FALSE;
    END get_supply_count_detail;

    FUNCTION get_supply_info_viewer
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_varchar,
        i_id_supply_count    IN sr_supply_count.id_sr_supply_count%TYPE
    ) RETURN CLOB IS
    
        l_supply_type        supply.flg_type%TYPE;
        l_ret                CLOB;
        l_id_supply_workflow supply_workflow.id_supply_workflow%TYPE;
    
    BEGIN
    
        IF i_id_supply_count IS NOT NULL
        THEN
            SELECT a.id_supply_workflow
              INTO l_id_supply_workflow
              FROM sr_supply_relation a
              JOIN sr_supply_count b
                ON a.id_sr_supply_count = b.id_sr_supply_count
             WHERE b.id_sr_supply_count = i_id_supply_count;
        ELSE
            l_id_supply_workflow := i_id_supply_workflow(1);
        END IF;
    
        SELECT s.flg_type
          INTO l_supply_type
          FROM supply_workflow sw
         INNER JOIN supply s
            ON s.id_supply = sw.id_supply
         WHERE sw.id_supply_workflow = l_id_supply_workflow;
    
        CASE l_supply_type
            WHEN pk_supplies_constant.g_supply_set_type THEN
                SELECT listagg('<b>' || y.title || '</b><b>' || y.label || '</b>' || y.data) within GROUP(ORDER BY y.data)
                  INTO l_ret
                  FROM (SELECT CASE
                                   WHEN z.rn = 1 THEN
                                    z.title
                                   ELSE
                                    '<br>'
                               END title,
                               z.label,
                               z.data
                          FROM (SELECT t.title,
                                       t.label,
                                       t.flg_type_rank,
                                       listagg(t.data) within GROUP(ORDER BY t.data) data,
                                       row_number() over(PARTITION BY t.title ORDER BY t.flg_type_rank) rn
                                  FROM (SELECT pk_translation.get_translation(i_lang, s.code_supply) || '<br><br>' title,
                                               pk_translation.get_translation(i_lang, sk.code_supply) || ' (' ||
                                               (SELECT COUNT(*)
                                                  FROM supply_workflow swkc
                                                 WHERE swkc.id_supply = sk.id_supply
                                                   AND swkc.id_supply_set = s.id_supply
                                                   AND swkc.id_sup_workflow_parent = sw.id_supply_workflow
                                                   AND swkc.id_episode = sw.id_episode) || ')<br><br>' label,
                                               CASE
                                                   WHEN sk.flg_type = pk_supplies_constant.g_supply_kit_type THEN
                                                    pk_translation.get_translation(i_lang, si.code_supply) || ' (' || srk.quantity || ')<br>'
                                                   ELSE
                                                    NULL
                                               END data,
                                               decode(sk.flg_type,
                                                      pk_supplies_constant.g_supply_set_type,
                                                      1,
                                                      pk_supplies_constant.g_supply_kit_type,
                                                      2,
                                                      pk_supplies_constant.g_supply_equipment_type,
                                                      3,
                                                      pk_supplies_constant.g_supply_implant_type,
                                                      4,
                                                      5) flg_type_rank
                                          FROM supply_workflow sw
                                         INNER JOIN supply s
                                            ON sw.id_supply = s.id_supply
                                          LEFT JOIN supply_relation sr
                                            ON sr.id_supply = s.id_supply
                                          LEFT JOIN supply sk
                                            ON sk.id_supply = sr.id_supply_item
                                          LEFT JOIN supply_relation srk
                                            ON srk.id_supply = sk.id_supply
                                          LEFT JOIN supply si
                                            ON si.id_supply = srk.id_supply_item
                                         WHERE sw.id_supply_workflow = l_id_supply_workflow) t
                                 GROUP BY t.title, t.label, t.flg_type_rank) z
                         ORDER BY z.rn, z.flg_type_rank) y;
            
            WHEN pk_supplies_constant.g_supply_kit_type THEN
                SELECT listagg('<b>' || y.title || '</b><b>' || y.label || '</b>' || y.data) within GROUP(ORDER BY y.data)
                  INTO l_ret
                  FROM (SELECT t.title, t.label, listagg(t.data) within GROUP(ORDER BY t.data) data
                          FROM (SELECT CASE
                                           WHEN ss.code_supply IS NOT NULL THEN
                                            pk_translation.get_translation(i_lang, ss.code_supply) || '<br><br>'
                                           ELSE
                                            NULL
                                       END title,
                                       pk_translation.get_translation(i_lang, s.code_supply) || '<br><br>' label,
                                       pk_translation.get_translation(i_lang, sk.code_supply) || ' (' || sr.quantity ||
                                       ')<br>' data
                                  FROM supply_workflow sw
                                 INNER JOIN supply s
                                    ON sw.id_supply = s.id_supply
                                  LEFT JOIN supply ss
                                    ON ss.id_supply = sw.id_supply_set
                                  LEFT JOIN supply_relation sr
                                    ON sr.id_supply = s.id_supply
                                  LEFT JOIN supply sk
                                    ON sk.id_supply = sr.id_supply_item
                                 WHERE id_supply_workflow = l_id_supply_workflow) t
                         GROUP BY t.title, t.label) y;
            ELSE
                SELECT listagg(y.title || y.label || y.data) within GROUP(ORDER BY y.data)
                  INTO l_ret
                  FROM (SELECT NULL title, NULL label, pk_translation.get_translation(i_lang, s.code_supply) data
                          FROM supply_workflow sw
                         INNER JOIN supply s
                            ON sw.id_supply = s.id_supply
                         WHERE sw.id_supply_workflow = l_id_supply_workflow) y;
        END CASE;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supply_info_viewer;

    FUNCTION get_supply_info_viewer
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_consumption    IN VARCHAR2,
        o_supply_info        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_supply_type supply.flg_type%TYPE;
    
    BEGIN
    
        SELECT s.flg_type
          INTO l_supply_type
          FROM supply_workflow sw
         INNER JOIN supply s
            ON s.id_supply = sw.id_supply
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        CASE l_supply_type
            WHEN pk_supplies_constant.g_supply_set_type THEN
                OPEN o_supply_info FOR
                    SELECT CASE
                               WHEN z.rn = 1 THEN
                                z.title
                               ELSE
                                '<br>'
                           END title,
                           z.label,
                           z.data
                      FROM (SELECT t.title,
                                   t.label,
                                   t.flg_type_rank,
                                   listagg(t.data) within GROUP(ORDER BY t.data) data,
                                   row_number() over(PARTITION BY t.title ORDER BY t.flg_type_rank) rn
                              FROM (SELECT CASE
                                               WHEN sw.id_sup_workflow_parent IS NULL THEN
                                                pk_translation.get_translation(i_lang, s.code_supply) || '<br><br>'
                                               ELSE
                                                NULL
                                           END title,
                                           CASE
                                               WHEN sw.id_sup_workflow_parent IS NOT NULL THEN
                                                pk_translation.get_translation(i_lang, s.code_supply) || ' (' || nvl(sw.quantity, 1) || ')<br><br>'
                                               ELSE
                                                NULL
                                           END label,
                                           CASE
                                               WHEN sk.flg_type = pk_supplies_constant.g_supply_kit_type THEN
                                                pk_translation.get_translation(i_lang, si.code_supply) || ' (' || srk.quantity || ')<br>'
                                               ELSE
                                                NULL
                                           END data,
                                           decode(sk.flg_type,
                                                  pk_supplies_constant.g_supply_set_type,
                                                  1,
                                                  pk_supplies_constant.g_supply_kit_type,
                                                  2,
                                                  pk_supplies_constant.g_supply_equipment_type,
                                                  3,
                                                  pk_supplies_constant.g_supply_implant_type,
                                                  4,
                                                  5) flg_type_rank
                                      FROM supply_workflow sw
                                     INNER JOIN supply s
                                        ON sw.id_supply = s.id_supply
                                      LEFT JOIN supply_relation sr
                                        ON sr.id_supply = s.id_supply
                                      LEFT JOIN supply sk
                                        ON sk.id_supply = sr.id_supply_item
                                      LEFT JOIN supply_relation srk
                                        ON srk.id_supply = sk.id_supply
                                      LEFT JOIN supply si
                                        ON si.id_supply = srk.id_supply_item
                                     WHERE (sw.id_sup_workflow_parent = i_id_supply_workflow OR
                                           sw.id_supply_workflow = i_id_supply_workflow)
                                       AND sw.flg_status NOT IN
                                           (pk_supplies_constant.g_sww_all_consumed, pk_supplies_constant.g_sww_cancelled)) t
                             GROUP BY t.title, t.label, t.flg_type_rank) z
                     ORDER BY z.rn, z.flg_type_rank;
            
            WHEN pk_supplies_constant.g_supply_kit_type THEN
                OPEN o_supply_info FOR
                    SELECT t.title, t.label, listagg(t.data) within GROUP(ORDER BY t.data) data
                      FROM (SELECT CASE
                                       WHEN ss.code_supply IS NOT NULL THEN
                                        pk_translation.get_translation(i_lang, ss.code_supply) || '<br><br>'
                                       ELSE
                                        NULL
                                   END title,
                                   pk_translation.get_translation(i_lang, s.code_supply) || '<br><br>' label,
                                   pk_translation.get_translation(i_lang, sk.code_supply) || ' (' || sr.quantity ||
                                   ')<br>' data
                              FROM supply_workflow sw
                             INNER JOIN supply s
                                ON sw.id_supply = s.id_supply
                              LEFT JOIN supply ss
                                ON ss.id_supply = sw.id_supply_set
                              LEFT JOIN supply_relation sr
                                ON sr.id_supply = s.id_supply
                              LEFT JOIN supply sk
                                ON sk.id_supply = sr.id_supply_item
                             WHERE id_supply_workflow = i_id_supply_workflow) t
                     GROUP BY t.title, t.label;
            ELSE
                OPEN o_supply_info FOR
                    SELECT NULL title, NULL label, pk_translation.get_translation(i_lang, s.code_supply) data
                      FROM supply_workflow sw
                     INNER JOIN supply s
                        ON sw.id_supply = s.id_supply
                     WHERE sw.id_supply_workflow = i_id_supply_workflow;
        END CASE;
    
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
            RETURN FALSE;
    END get_supply_info_viewer;

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
    
        l_from_state          table_varchar;
        l_id_category         NUMBER;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error               := 'Filter duplicates';
        l_from_state          := SET(i_from_state);
        l_id_category         := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l AS "LEVEL",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   MAX(flg_active) flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT act.id_action,
                           act.id_parent,
                           act.l,
                           act.to_state,
                           act.desc_action,
                           act.icon,
                           act.flg_default,
                           act.flg_active,
                           act.action,
                           act.from_state,
                           act.rank,
                           rank() over(ORDER BY ap.id_institution DESC, ap.id_software DESC NULLS LAST) origin_rank
                      FROM (SELECT a.id_action,
                                   a.id_parent,
                                   LEVEL AS l,
                                   a.to_state,
                                   pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                                   a.icon,
                                   decode(flg_default, 'D', pk_supplies_constant.g_yes, pk_alert_constant.g_no) flg_default,
                                   decode(i_flg_set,
                                          pk_supplies_constant.g_yes,
                                          decode(a.internal_name,
                                                 'EDIT',
                                                 pk_alert_constant.g_active,
                                                 'CANCEL',
                                                 pk_alert_constant.g_active,
                                                 pk_alert_constant.g_inactive),
                                          a.flg_status) AS flg_active,
                                   a.internal_name action,
                                   a.from_state,
                                   a. rank
                              FROM action a
                             WHERE subject = i_subject
                               AND from_state IN (SELECT *
                                                    FROM TABLE(l_from_state))
                            CONNECT BY PRIOR a.id_action = a.id_parent
                             START WITH a.id_parent IS NULL) act
                     INNER JOIN action_permission ap
                        ON ap.id_action = act.id_action
                     WHERE ap.id_profile_template = l_id_profile_template
                       AND ap.id_institution IN (0, i_prof.institution)
                       AND ap.id_software IN (0, i_prof.software)
                       AND ap.id_task_type = i_task_type
                       AND ap.id_category = l_id_category)
             WHERE origin_rank = 1
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
            HAVING COUNT(from_state) = (SELECT COUNT(*)
                                          FROM TABLE(table_varchar() MULTISET UNION DISTINCT l_from_state))
            UNION ALL
            SELECT 10 id_action,
                   NULL id_parent,
                   1 AS "LEVEL",
                   NULL to_state,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'SUPPLIES_T138') desc_action,
                   NULL icon,
                   pk_alert_constant.g_no flg_default,
                   decode(i_flg_set,
                          pk_supplies_constant.g_yes,
                          pk_alert_constant.g_active,
                          pk_alert_constant.g_inactive) flg_active,
                   'GOTO_SET_SCREEN' action,
                   1 rank
              FROM dual
             ORDER BY "LEVEL", rank, desc_action;
    
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
            RETURN FALSE;
    END get_cross_actions_permissions;

    FUNCTION get_actions_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN action.from_state%TYPE,
        i_flg_set     IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        i_flg_context IN VARCHAR2 DEFAULT NULL,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_profile_template IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt, software s
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software IN (i_prof.software, 0)
               AND ppt.id_institution IN (i_prof.institution, 0)
               AND ppt.id_profile_template = pt.id_profile_template
               AND pt.id_software = s.id_software
               AND s.flg_viewer = 'N';
    
        r_profile_template c_profile_template%ROWTYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
    
    BEGIN
    
        g_error := 'GET PROFILE_TEMPLATE';
        OPEN c_profile_template;
        FETCH c_profile_template
            INTO r_profile_template;
    
        IF c_profile_template%FOUND
        THEN
            l_profile_template := r_profile_template.id_profile_template;
        END IF;
        CLOSE c_profile_template;
    
        IF i_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR i_id_hhc_req IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(i_id_hhc_req,
                                  pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => pk_episode.get_id_patient(i_episode)));
        
            IF NOT pk_hhc_core.get_prof_can_edit(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_id_hhc_req   => l_i_id_hhc_req,
                                                 o_flg_can_edit => l_flg_can_edit,
                                                 o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT t.id_action,
                   t.id_parent,
                   t.lvl,
                   t.from_state,
                   t.to_state,
                   t.desc_action,
                   t.icon,
                   t.flg_default,
                   CASE
                        WHEN l_flg_can_edit = pk_alert_constant.g_no
                             AND t.action IN ('CANCEL', 'EDIT') THEN
                         pk_alert_constant.g_inactive
                        WHEN i_flg_context IS NOT NULL
                             AND i_flg_context = 'D' -- Dispense 
                             AND t.action = 'CONSUME' THEN
                         pk_alert_constant.g_inactive
                        ELSE
                         decode(i_flg_set,
                                pk_supplies_constant.g_yes,
                                decode(t.action,
                                       'EDIT',
                                       pk_alert_constant.g_active,
                                       'CANCEL',
                                       pk_alert_constant.g_active,
                                       'GOTO_SET_SCREEN',
                                       pk_alert_constant.g_active,
                                       pk_alert_constant.g_inactive),
                                t.flg_active)
                    END flg_active,
                   t.action,
                   t.rank
              FROM (SELECT a.id_action,
                           a.id_parent,
                           a.level_nr lvl, --used to manage the shown' items by Flash
                            a.from_state, --destination state flag
                            a.to_state, --destination state flag
                            a.desc_action, --action's description
                           a.icon, --action's icon
                            a.flg_default, --default action
                            a.flg_active, --action's state
                           a.action,
                           pk_action.get_action_rank(i_lang, i_prof, a.id_action) rank
                      FROM TABLE(pk_action.tf_get_actions_permissions(i_lang, i_prof, i_subject, i_from_state)) a
                    UNION ALL
                    SELECT 10 id_action,
                           NULL id_parent,
                           1 AS lvl,
                           NULL from_state,
                           NULL to_state,
                           pk_message.get_message(i_lang, i_prof, 'SUPPLIES_T138') desc_action,
                           NULL icon,
                           pk_alert_constant.g_no flg_default,
                           decode(i_flg_set,
                                  pk_supplies_constant.g_yes,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.g_inactive) flg_active,
                           'GOTO_SET_SCREEN' action,
                           -1 rank
                      FROM dual) t
             ORDER BY lvl DESC, rank ASC, desc_action DESC;
    
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
            RETURN FALSE;
    END get_actions_permissions;

    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_episode    IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
    
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF i_id_hhc_req IS NOT NULL
        THEN
        
            IF NOT pk_hhc_core.get_prof_can_edit(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_id_hhc_req   => i_id_hhc_req,
                                                 o_flg_can_edit => l_flg_can_edit,
                                                 o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'GET CURSOR o_actions';
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr "level", --used to manage the shown' items by Flash
                   a.from_state,
                   a.to_state, --destination state flag
                   a.desc_action, --action's description
                   a.icon, --action's icon
                   a.flg_default, --default action
                   CASE
                        WHEN l_epis_type = 99
                             AND a.action = 'ADD_NEW_CONSUMPTION' THEN
                         pk_alert_constant.g_inactive
                        WHEN l_flg_can_edit = pk_alert_constant.g_no THEN
                         pk_alert_constant.g_inactive
                        ELSE
                         a.flg_active
                    END flg_active, --action's state
                   a.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, i_subject, i_from_state)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SUPPLIES_CORE',
                                              'GET_ACTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_with_exceptions;

    FUNCTION get_supply_available_quantity
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN NUMBER IS
    
        l_quantity_dispensed supply_workflow.quantity%TYPE;
        l_quantity_consumed  supply_workflow.quantity%TYPE;
        l_available_quantity supply_workflow.quantity%TYPE;
    
    BEGIN
    
        g_error := 'GET QUANTITY DISPENSED';
        SELECT nvl(s.quantity, 1)
          INTO l_quantity_dispensed
          FROM supply_workflow s
         WHERE s.id_supply_workflow = i_id_supply_workflow;
    
        g_error := 'GET QUANTITY CONSUMED';
        SELECT nvl(SUM(nvl(s.quantity, 1)), 0)
          INTO l_quantity_consumed
          FROM supply_workflow s
         WHERE s.id_consumption_parent = i_id_supply_workflow
           AND s.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled);
    
        g_error              := 'GET AVAILABLE QUANTITY';
        l_available_quantity := l_quantity_dispensed - l_quantity_consumed;
    
        IF l_available_quantity < 0
        THEN
            RETURN 0;
        ELSE
            RETURN l_available_quantity;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_supply_available_quantity;

    FUNCTION get_supply_kit_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_supply           IN supply.id_supply%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_dept                episode.id_dept_requested%TYPE;
        l_id_supply_soft_inst supply_soft_inst.id_supply_soft_inst%TYPE;
    
        l_ret VARCHAR(4000 CHAR);
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
            g_error := 'GET id_dept_requested';
            SELECT e.id_dept_requested
              INTO l_dept
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        ELSE
            l_dept := 0;
        END IF;
    
        IF i_lang IS NOT NULL
           AND i_supply IS NOT NULL
        THEN
        
            g_error               := 'GET id_supply_sof_inst';
            l_id_supply_soft_inst := get_id_supply_soft_inst(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_id_supply_area   => i_id_supply_area,
                                                             i_id_dept          => l_dept,
                                                             i_consumption_type => i_consumption_type,
                                                             i_id_supply        => i_supply,
                                                             i_id_inst_dest     => i_id_inst_dest);
        
            g_error := 'GETTING L_RET';
            SELECT listagg(desc_supply, chr(10)) within GROUP(ORDER BY desc_supply ASC)
              INTO l_ret
              FROM (SELECT pk_translation.get_translation(i_lang, s.code_supply) || ' (' || sr.quantity || ')' desc_supply,
                           sr.quantity
                      FROM supply_relation sr
                      JOIN supply s
                        ON s.id_supply = sr.id_supply_item
                       AND s.flg_available = pk_supplies_constant.g_yes
                     INNER JOIN (SELECT sld.id_supply_location, sld.id_supply_soft_inst, sl.code_supply_location
                                  FROM supply_loc_default sld
                                 INNER JOIN supply_location sl
                                    ON sld.id_supply_location = sl.id_supply_location
                                   AND sld.flg_default = pk_supplies_constant.g_yes
                                   AND sld.id_supply_soft_inst = l_id_supply_soft_inst) loc
                        ON loc.id_supply_soft_inst = l_id_supply_soft_inst
                      JOIN supply_soft_inst ssi
                        ON loc.id_supply_soft_inst = ssi.id_supply_soft_inst
                      JOIN supply_sup_area ssa
                        ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                      JOIN supply_soft_inst ssis
                        ON ssis.id_supply = s.id_supply
                      JOIN supply_sup_area ssas
                        ON ssas.id_supply_soft_inst = ssis.id_supply_soft_inst
                       AND ssa.id_supply_area = ssas.id_supply_area
                     WHERE sr.id_supply = i_supply
                       AND ssas.id_supply_area = i_id_supply_area
                       AND ssis.id_institution = i_prof.institution
                       AND ssis.id_software = i_prof.software) t;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supply_kit_info;

    FUNCTION revert_supply_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_consumption_parent table_number;
        l_flg_status             supply_workflow.flg_status%TYPE;
    
        l_hist_row supply_workflow_hist%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        SELECT DISTINCT sw.id_consumption_parent
          BULK COLLECT
          INTO l_tbl_consumption_parent
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate(table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_id_supply_workflow) t);
    
        IF l_tbl_consumption_parent.count > 0
        THEN
            FOR i IN l_tbl_consumption_parent.first .. l_tbl_consumption_parent.last
            LOOP
                IF l_tbl_consumption_parent(i) IS NOT NULL
                THEN
                    SELECT sw.flg_status
                      INTO l_flg_status
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = l_tbl_consumption_parent(i);
                
                    IF l_flg_status = pk_supplies_constant.g_sww_all_consumed
                    THEN
                        SELECT *
                          INTO l_hist_row
                          FROM (SELECT *
                                  FROM supply_workflow_hist swh
                                 WHERE swh.id_supply_workflow = l_tbl_consumption_parent(i)
                                 ORDER BY swh.id_supply_workflow_hist DESC)
                         WHERE rownum = 1;
                    
                        ts_supply_workflow.upd(id_supply_workflow_in      => l_tbl_consumption_parent(i),
                                               id_professional_in         => l_hist_row.id_professional,
                                               id_professional_nin        => TRUE,
                                               id_episode_in              => l_hist_row.id_episode,
                                               id_episode_nin             => TRUE,
                                               id_supply_request_in       => l_hist_row.id_supply_request,
                                               id_supply_request_nin      => TRUE,
                                               id_supply_in               => l_hist_row.id_supply,
                                               id_supply_nin              => TRUE,
                                               id_supply_location_in      => l_hist_row.id_supply_location,
                                               id_supply_location_nin     => TRUE,
                                               barcode_req_in             => l_hist_row.barcode_req,
                                               barcode_req_nin            => TRUE,
                                               barcode_scanned_in         => l_hist_row.barcode_scanned,
                                               barcode_scanned_nin        => TRUE,
                                               quantity_in                => l_hist_row.quantity,
                                               quantity_nin               => TRUE,
                                               id_unit_measure_in         => l_hist_row.id_unit_measure,
                                               id_unit_measure_nin        => TRUE,
                                               id_context_in              => l_hist_row.id_context,
                                               id_context_nin             => TRUE,
                                               flg_context_in             => l_hist_row.flg_context,
                                               flg_context_nin            => TRUE,
                                               flg_status_in              => l_hist_row.flg_status,
                                               flg_status_nin             => TRUE,
                                               dt_request_in              => l_hist_row.dt_request,
                                               dt_request_nin             => TRUE,
                                               dt_returned_in             => l_hist_row.dt_returned,
                                               dt_returned_nin            => TRUE,
                                               notes_in                   => l_hist_row.notes,
                                               notes_nin                  => TRUE,
                                               id_prof_cancel_in          => l_hist_row.id_prof_cancel,
                                               id_prof_cancel_nin         => TRUE,
                                               dt_cancel_in               => l_hist_row.dt_cancel,
                                               dt_cancel_nin              => TRUE,
                                               notes_cancel_in            => l_hist_row.notes_cancel,
                                               notes_cancel_nin           => TRUE,
                                               id_cancel_reason_in        => l_hist_row.id_cancel_reason,
                                               id_cancel_reason_nin       => TRUE,
                                               notes_reject_in            => l_hist_row.notes_reject,
                                               notes_reject_nin           => TRUE,
                                               dt_reject_in               => l_hist_row.dt_reject,
                                               dt_reject_nin              => TRUE,
                                               id_prof_reject_in          => l_hist_row.id_prof_reject,
                                               id_prof_reject_nin         => TRUE,
                                               dt_supply_workflow_in      => l_hist_row.dt_supply_workflow,
                                               dt_supply_workflow_nin     => TRUE,
                                               id_req_reason_in           => l_hist_row.id_req_reason,
                                               id_req_reason_nin          => TRUE,
                                               id_del_reason_in           => l_hist_row.id_del_reason,
                                               id_del_reason_nin          => TRUE,
                                               id_supply_set_in           => l_hist_row.id_supply_set,
                                               id_supply_set_nin          => TRUE,
                                               id_sup_workflow_parent_in  => l_hist_row.id_sup_workflow_parent,
                                               id_sup_workflow_parent_nin => TRUE,
                                               total_quantity_in          => l_hist_row.total_quantity,
                                               total_quantity_nin         => TRUE,
                                               asset_number_in            => l_hist_row.asset_number,
                                               asset_number_nin           => TRUE,
                                               flg_outdated_in            => l_hist_row.flg_outdated,
                                               flg_outdated_nin           => TRUE,
                                               flg_cons_type_in           => l_hist_row.flg_cons_type,
                                               flg_cons_type_nin          => TRUE,
                                               flg_reusable_in            => l_hist_row.flg_reusable,
                                               flg_reusable_nin           => TRUE,
                                               flg_editable_in            => l_hist_row.flg_editable,
                                               flg_editable_nin           => TRUE,
                                               total_avail_quantity_in    => l_hist_row.total_avail_quantity,
                                               total_avail_quantity_nin   => TRUE,
                                               cod_table_in               => l_hist_row.cod_table,
                                               cod_table_nin              => TRUE,
                                               flg_preparing_in           => l_hist_row.flg_preparing,
                                               flg_preparing_nin          => TRUE,
                                               flg_countable_in           => l_hist_row.flg_countable,
                                               flg_countable_nin          => TRUE,
                                               id_supply_area_in          => l_hist_row.id_supply_area,
                                               id_supply_area_nin         => TRUE,
                                               lot_in                     => l_hist_row.lot,
                                               lot_nin                    => TRUE,
                                               dt_expiration_in           => l_hist_row.dt_expiration,
                                               dt_expiration_nin          => TRUE,
                                               flg_validation_in          => l_hist_row.flg_validation,
                                               flg_validation_nin         => TRUE,
                                               supply_migration_in        => l_hist_row.supply_migration,
                                               supply_migration_nin       => TRUE,
                                               id_consumption_parent_in   => l_hist_row.id_consumption_parent,
                                               id_consumption_parent_nin  => TRUE,
                                               rows_out                   => l_rows_out);
                    
                        g_error := 'CALL PROCESS_UPDATE';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUPPLY_WORKFLOW',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    
                        ts_supply_workflow_hist.del(id_supply_workflow_hist_in => l_hist_row.id_supply_workflow_hist,
                                                    rows_out                   => l_rows_out);
                    
                        pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => l_tbl_consumption_parent(i));
                    
                    END IF;
                
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SUPPLIES_CORE',
                                              'REVERT_SUPPLY_CONSUMPTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END revert_supply_consumption;

    PROCEDURE init_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        o_error t_error_out;
    BEGIN
    
        pk_context_api.set_parameter('l_lang', l_lang);
        pk_context_api.set_parameter('l_prof_id', l_prof.id);
        pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('l_prof_software', l_prof.software);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_prof_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_prof_software' THEN
                o_vc2 := to_char(l_prof.software);
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SUPPLIES_CORE',
                                              i_function => 'INIT_PARAMS',
                                              o_error    => o_error);
    END init_params;
BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_supplies_core;
/
