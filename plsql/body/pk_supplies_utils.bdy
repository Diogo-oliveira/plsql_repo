/*-- Last Change Revision: $Rev: 2045834 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-09-22 08:43:00 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_utils IS

    FUNCTION create_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_supply_request  IN supply_request.id_supply_request%TYPE,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_flg_status         IN table_varchar,
        i_dt_request         IN table_varchar,
        i_dt_return          IN table_varchar,
        i_id_req_reason      IN table_number,
        i_id_context         IN supply_request.id_context%TYPE,
        i_flg_context        IN supply_request.flg_context%TYPE,
        i_notes              IN table_varchar,
        i_id_inst_dest       IN institution.id_institution%TYPE DEFAULT NULL,
        i_sup_wkflow_parent  IN supply_workflow.id_sup_workflow_parent%TYPE DEFAULT NULL,
        i_lot                IN table_varchar DEFAULT NULL,
        i_barcode_scanned    IN table_varchar DEFAULT NULL,
        i_dt_expiration      IN table_varchar DEFAULT NULL,
        i_flg_validation     IN table_varchar DEFAULT NULL,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sup_int_wf    sys_config.value%TYPE;
        l_supply_qty    supply_workflow.quantity%TYPE;
        l_flg_status    supply_workflow.flg_status%TYPE;
        l_dt_request    supply_workflow.dt_request%TYPE;
        l_dt_return     supply_workflow.dt_returned%TYPE;
        l_dt_expiration supply_workflow.dt_expiration%TYPE;
    
        l_flg_cons_type supply_workflow.flg_cons_type%TYPE;
        l_flg_reusable  supply_workflow.flg_reusable%TYPE;
        l_flg_editable  supply_workflow.flg_editable%TYPE;
        l_flg_preparing supply_workflow.flg_preparing%TYPE;
        l_flg_countable supply_workflow.flg_countable%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_id_supply_workflow := table_number();
    
        -- CONFIG       
        l_sup_int_wf := pk_sysconfig.get_config('SUPPLIES_INTERFACE_WORKFLOW', i_prof);
    
        FOR i IN 1 .. i_supply.count
        LOOP
        
            l_supply_qty := nvl(i_supply_qty(i), 1);
        
            g_error := 'FOR j IN 1 .. ' || l_supply_qty || ' / <<supply_qty>> / ' || 'i_prof=' ||
                       pk_utils.to_string(i_prof) || ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' ||
                       i_id_episode || ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' ||
                       i_supply.count || ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context ||
                       ' l_sup_int_wf=' || l_sup_int_wf;
            <<supply_qty>>
        --      FOR j IN 1 .. l_supply_qty
            --      LOOP
        
            -- GETS SUPPLY_WORKFLOW STATE
            g_error := 'Gets supply_workflow state / ' || 'i_prof=' || pk_utils.to_string(i_prof) ||
                       ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' || i_id_episode ||
                       ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' || i_supply.count ||
                       ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context || ' l_sup_int_wf=' ||
                       l_sup_int_wf;
        
            IF i_flg_status IS NOT NULL
               AND i_flg_status.exists(i)
               AND i_flg_status(i) IN (pk_supplies_constant.g_sww_predefined,
                                       pk_supplies_constant.g_srt_draft,
                                       pk_supplies_constant.g_sww_transport_concluded)
            THEN
                l_flg_status := i_flg_status(i); -- MAINTAINS THE STATE               
            ELSE
                l_flg_status := get_ini_status_supply_wf(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_supply_area     => i_id_supply_area,
                                                         i_id_supply_location => CASE
                                                                                     WHEN i_supply_loc.count() = 0
                                                                                          OR i_supply_loc IS NULL THEN
                                                                                      NULL
                                                                                     ELSE
                                                                                      i_supply_loc(i)
                                                                                 END,
                                                         i_id_supply_set      => i_supply_set(i),
                                                         i_id_supply          => i_supply(i),
                                                         i_sup_interface      => l_sup_int_wf,
                                                         i_id_inst_dest       => i_id_inst_dest);
            
            END IF;
        
            -- CALCULATES DATES
            g_error      := 'Gets supply_workflow state / ' || 'i_prof=' || pk_utils.to_string(i_prof) ||
                            ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' || i_id_episode ||
                            ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' || i_supply.count ||
                            ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context || ' l_sup_int_wf=' ||
                            l_sup_int_wf;
            l_dt_request := pk_date_utils.get_string_tstz(i_lang,
                                                          i_prof,
                                                          i_dt_request(i),
                                                          pk_date_utils.get_timezone(i_lang, i_prof));
            l_dt_return  := pk_date_utils.get_string_tstz(i_lang,
                                                          i_prof,
                                                          i_dt_return(i),
                                                          pk_date_utils.get_timezone(i_lang, i_prof));
        
            BEGIN
                SELECT ssi.flg_cons_type, ssi.flg_reusable, ssi.flg_editable, ssi.flg_preparing, ssi.flg_countable
                  INTO l_flg_cons_type, l_flg_reusable, l_flg_editable, l_flg_preparing, l_flg_countable
                  FROM supply_soft_inst ssi
                 WHERE ssi.id_supply = i_supply(i)
                   AND ((ssi.id_institution = i_prof.institution AND i_id_inst_dest IS NULL AND
                       ssi.id_software = i_prof.software) OR
                       (ssi.id_institution = i_id_inst_dest AND ssi.id_software = pk_alert_constant.g_soft_oris));
            EXCEPTION
                WHEN no_data_found THEN
                    SELECT ssi.flg_cons_type, ssi.flg_reusable, ssi.flg_editable, ssi.flg_preparing, ssi.flg_countable
                      INTO l_flg_cons_type, l_flg_reusable, l_flg_editable, l_flg_preparing, l_flg_countable
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply = i_supply(i)
                       AND (i_id_inst_dest IS NULL AND ssi.id_institution = i_prof.institution AND
                           i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies AND
                           ssi.id_software = pk_alert_constant.g_soft_oris);
                
            END;
        
            -- GENERATE NEW ID
            g_error := 'o_id_supply_workflow.extend / ' || 'i_prof=' || pk_utils.to_string(i_prof) ||
                       ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' || i_id_episode ||
                       ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' || i_supply.count ||
                       ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context || ' l_sup_int_wf=' ||
                       l_sup_int_wf;
            o_id_supply_workflow.extend;
            o_id_supply_workflow(o_id_supply_workflow.last) := ts_supply_workflow.next_key;
        
            IF i_dt_expiration IS NOT NULL
               AND i_dt_expiration.count > 0
            THEN
                l_dt_expiration := pk_date_utils.get_string_tstz(i_lang,
                                                                 i_prof,
                                                                 i_dt_expiration(i),
                                                                 pk_date_utils.get_timezone(i_lang, i_prof));
            END IF;
        
            -- INSERT SUPPLY_WORKFLOW DATA
            g_error := 'Call ts_supply_workflow.ins / ' || 'i_prof=' || pk_utils.to_string(i_prof) ||
                       ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' || i_id_episode ||
                       ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' || i_supply.count ||
                       ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context || ' l_sup_int_wf=' ||
                       l_sup_int_wf;
            ts_supply_workflow.ins(id_supply_workflow_in     => o_id_supply_workflow(o_id_supply_workflow.last),
                                   id_professional_in        => i_prof.id,
                                   id_episode_in             => i_id_episode,
                                   id_supply_request_in      => i_id_supply_request,
                                   id_supply_in              => i_supply(i),
                                   id_supply_set_in          => i_supply_set(i),
                                   id_sup_workflow_parent_in => i_sup_wkflow_parent,
                                   id_supply_location_in     => CASE
                                                                    WHEN l_sup_int_wf = pk_alert_constant.get_yes THEN
                                                                     NULL
                                                                    ELSE
                                                                     nvl(CASE
                                                                             WHEN i_supply_loc IS NULL
                                                                                  OR i_supply_loc.count = 0 THEN
                                                                              NULL
                                                                             ELSE
                                                                              i_supply_loc(i)
                                                                         END,
                                                                         pk_supplies_core.get_default_location(i_lang,
                                                                                                               i_prof,
                                                                                                               i_id_supply_area,
                                                                                                               nvl(i_supply_set(i),
                                                                                                                   i_supply(i)),
                                                                                                               i_id_inst_dest))
                                                                END,
                                   quantity_in               => i_supply_qty(i), --1,
                                   total_quantity_in         => i_supply_qty(i), --1,
                                   id_context_in             => i_id_context,
                                   flg_context_in            => i_flg_context,
                                   flg_status_in             => l_flg_status,
                                   dt_request_in             => nvl(l_dt_request, g_sysdate_tstz),
                                   dt_returned_in            => l_dt_return,
                                   dt_supply_workflow_in     => g_sysdate_tstz,
                                   id_req_reason_in          => CASE
                                                                    WHEN i_id_req_reason IS NULL
                                                                         OR i_id_req_reason.count = 0 THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_id_req_reason(i)
                                                                END,
                                   notes_in                  => CASE
                                                                    WHEN i_notes IS NULL
                                                                         OR i_notes.count = 0 THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_notes(i)
                                                                END,
                                   flg_cons_type_in          => l_flg_cons_type,
                                   flg_reusable_in           => l_flg_reusable,
                                   flg_editable_in           => l_flg_editable,
                                   flg_preparing_in          => l_flg_preparing,
                                   flg_countable_in          => l_flg_countable,
                                   id_supply_area_in         => i_id_supply_area,
                                   lot_in                    => CASE
                                                                    WHEN i_lot IS NULL
                                                                         OR i_lot.count = 0 THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_lot(i)
                                                                END,
                                   barcode_scanned_in        => CASE
                                                                    WHEN i_barcode_scanned IS NULL
                                                                         OR i_barcode_scanned.count = 0 THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_barcode_scanned(i)
                                                                END,
                                   flg_validation_in         => CASE
                                                                    WHEN i_flg_validation IS NULL
                                                                         OR i_flg_validation.count = 0 THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_flg_validation(i)
                                                                END,
                                   dt_expiration_in          => l_dt_expiration,
                                   rows_out                  => l_rows_out);
        
            IF l_flg_status != pk_supplies_constant.g_sww_predefined
               OR i_flg_context != pk_supplies_constant.g_context_procedure_req
            THEN
                g_error := 'Call pk_ia_event_common.supply_workflow_new / ' || 'i_prof=' || pk_utils.to_string(i_prof) ||
                           ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' || i_id_episode ||
                           ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' || i_supply.count ||
                           ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context || ' l_sup_int_wf=' ||
                           l_sup_int_wf;
                pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => o_id_supply_workflow(o_id_supply_workflow.last));
            END IF;
        
        END LOOP supply_qty;
        --  END LOOP supply_list;
    
        g_error := 'Call t_data_gov_mnt.process_insert / ' || 'i_prof=' || pk_utils.to_string(i_prof) ||
                   ' i_id_supply_area=' || i_id_supply_area || ' i_id_episode=' || i_id_episode ||
                   ' i_id_supply_request=' || i_id_supply_request || ' i_supply.count=' || i_supply.count ||
                   ' i_id_context=' || i_id_context || ' i_flg_context=' || i_flg_context || ' l_sup_int_wf=' ||
                   l_sup_int_wf;
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
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
                                              'CREATE_SUPPLY_WORKFLOW',
                                              o_error);
        
            RETURN FALSE;
    END create_supply_workflow;

    FUNCTION create_supply_rqt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_supply_area    IN supply_area.id_supply_area%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_reason_req    IN supply_request.flg_reason%TYPE DEFAULT 'O',
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_supply_dt_request IN supply_request.dt_request%TYPE,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_supply_rqt';
        l_params         VARCHAR2(1000 CHAR);
        l_supply_request supply_request%ROWTYPE;
        l_rows           table_varchar;
    BEGIN
        -- INIT
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_area=' || i_id_supply_area ||
                    ' i_id_episode=' || i_id_episode || ' i_flg_reason_req=' || i_flg_reason_req || ' i_id_context=' ||
                    i_id_context || ' i_flg_context=' || i_flg_context || ' i_supply_flg_status=' ||
                    i_supply_flg_status;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- SET SUPPLY_REQUEST DATA
        l_supply_request.id_professional := i_prof.id;
        l_supply_request.id_episode      := i_id_episode;
    
        g_sysdate_tstz := current_timestamp;
    
        g_error                      := 'SELECT id_room / ' || l_params;
        l_supply_request.id_room_req := pk_episode.get_epis_id_room(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_episode => i_id_episode);
    
        g_error                      := 'id_context / ' || l_params;
        l_supply_request.id_context := CASE
                                           WHEN i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                            NULL
                                           ELSE
                                            i_id_context
                                       END;
        l_supply_request.flg_context := CASE
                                            WHEN i_id_supply_area = pk_supplies_constant.g_area_surgical_supplies THEN
                                             NULL
                                            ELSE
                                             i_flg_context
                                        END;
        l_supply_request.dt_request  := i_supply_dt_request;
        l_supply_request.flg_status  := nvl(i_supply_flg_status, pk_supplies_constant.g_srt_requested);
        l_supply_request.flg_reason  := nvl(i_flg_reason_req, 'O');
    
        -- PRIMARY KEY
        g_error                            := 'GET NEXT REQUEST ID / ' || l_params;
        l_supply_request.id_supply_request := ts_supply_request.next_key;
    
        g_error := 'Call ts_supply_request.ins / ' || l_params;
        ts_supply_request.ins(id_supply_request_in => l_supply_request.id_supply_request,
                              id_professional_in   => l_supply_request.id_professional,
                              id_episode_in        => l_supply_request.id_episode,
                              id_room_req_in       => l_supply_request.id_room_req,
                              id_context_in        => l_supply_request.id_context,
                              flg_context_in       => l_supply_request.flg_context,
                              dt_request_in        => l_supply_request.dt_request,
                              flg_status_in        => l_supply_request.flg_status,
                              flg_reason_in        => l_supply_request.flg_reason,
                              rows_out             => l_rows);
    
        g_error := 'Call t_data_gov_mnt.process_insert / ' || l_params;
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_REQUEST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        o_id_supply_request := l_supply_request.id_supply_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SUPPLY_RQT',
                                              o_error);
        
            RETURN FALSE;
    END create_supply_rqt;

    PROCEDURE set_supply_request_hist(i_id_supply_request IN supply_request.id_supply_request%TYPE) IS
        l_id_supply_request_hist supply_request_hist.id_supply_request_hist%TYPE;
        r_supply_request         supply_request%ROWTYPE;
        l_rows                   table_varchar;
    
    BEGIN
        SELECT sr.*
          INTO r_supply_request
          FROM supply_request sr
         WHERE sr.id_supply_request = i_id_supply_request;
    
        l_id_supply_request_hist := ts_supply_request_hist.next_key;
    
        ts_supply_request_hist.ins(id_supply_request_hist_in => l_id_supply_request_hist,
                                   id_supply_request_in      => r_supply_request.id_supply_request,
                                   id_professional_in        => r_supply_request.id_professional,
                                   id_episode_in             => r_supply_request.id_episode,
                                   id_room_req_in            => r_supply_request.id_room_req,
                                   id_context_in             => r_supply_request.id_context,
                                   flg_context_in            => r_supply_request.flg_context,
                                   dt_request_in             => r_supply_request.dt_request,
                                   flg_status_in             => r_supply_request.flg_status,
                                   flg_reason_in             => r_supply_request.flg_reason,
                                   flg_prof_prep_in          => r_supply_request.flg_prof_prep,
                                   id_prof_cancel_in         => r_supply_request.id_prof_cancel,
                                   dt_cancel_in              => r_supply_request.dt_cancel,
                                   notes_in                  => r_supply_request.notes,
                                   rows_out                  => l_rows);
    END set_supply_request_hist;

    PROCEDURE set_supply_workflow_hist
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE
    ) IS
        l_id_supply_workflow_hist supply_workflow_hist.id_supply_workflow_hist%TYPE;
        r_supply_workflow         supply_workflow%ROWTYPE;
        l_rows                    table_varchar;
    
    BEGIN
        SELECT sw.*
          INTO r_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        SELECT MAX(swh.id_supply_workflow_hist)
          INTO l_id_supply_workflow_hist
          FROM supply_workflow_hist swh
         WHERE swh.id_supply_workflow = i_id_supply_workflow;
    
        IF l_id_supply_workflow_hist IS NOT NULL
           AND i_id_context IS NOT NULL
        THEN
            ts_supply_workflow_hist.upd(id_context_in  => i_id_context,
                                        flg_context_in => i_flg_context,
                                        where_in       => 'id_supply_workflow_hist = ' || l_id_supply_workflow_hist,
                                        rows_out       => l_rows);
        ELSE
        
            l_id_supply_workflow_hist := ts_supply_workflow_hist.next_key;
        
            ts_supply_workflow_hist.ins(id_supply_workflow_hist_in => l_id_supply_workflow_hist,
                                        id_supply_workflow_in      => r_supply_workflow.id_supply_workflow,
                                        id_professional_in         => r_supply_workflow.id_professional,
                                        id_episode_in              => r_supply_workflow.id_episode,
                                        id_supply_request_in       => r_supply_workflow.id_supply_request,
                                        id_supply_in               => r_supply_workflow.id_supply,
                                        id_supply_location_in      => r_supply_workflow.id_supply_location,
                                        barcode_req_in             => r_supply_workflow.barcode_req,
                                        barcode_scanned_in         => r_supply_workflow.barcode_scanned,
                                        quantity_in                => r_supply_workflow.quantity,
                                        id_unit_measure_in         => r_supply_workflow.id_unit_measure,
                                        id_context_in              => i_id_context,
                                        flg_context_in             => i_flg_context,
                                        flg_status_in              => r_supply_workflow.flg_status,
                                        dt_request_in              => r_supply_workflow.dt_request,
                                        dt_returned_in             => r_supply_workflow.dt_returned,
                                        notes_in                   => r_supply_workflow.notes,
                                        id_prof_cancel_in          => r_supply_workflow.id_prof_cancel,
                                        dt_cancel_in               => r_supply_workflow.dt_cancel,
                                        notes_cancel_in            => r_supply_workflow.notes_cancel,
                                        id_cancel_reason_in        => r_supply_workflow.id_cancel_reason,
                                        notes_reject_in            => r_supply_workflow.notes_reject,
                                        dt_reject_in               => r_supply_workflow.dt_reject,
                                        id_prof_reject_in          => r_supply_workflow.id_prof_reject,
                                        dt_supply_workflow_in      => r_supply_workflow.dt_supply_workflow,
                                        id_req_reason_in           => r_supply_workflow.id_req_reason,
                                        id_del_reason_in           => r_supply_workflow.id_del_reason,
                                        flg_outdated_in            => r_supply_workflow.flg_outdated,
                                        total_quantity_in          => r_supply_workflow.total_quantity,
                                        flg_cons_type_in           => r_supply_workflow.flg_cons_type,
                                        flg_reusable_in            => r_supply_workflow.flg_reusable,
                                        flg_editable_in            => r_supply_workflow.flg_editable,
                                        total_avail_quantity_in    => r_supply_workflow.total_avail_quantity,
                                        cod_table_in               => r_supply_workflow.cod_table,
                                        flg_preparing_in           => r_supply_workflow.flg_preparing,
                                        flg_countable_in           => r_supply_workflow.flg_countable,
                                        id_supply_area_in          => r_supply_workflow.id_supply_area,
                                        dt_expiration_in           => r_supply_workflow.dt_expiration,
                                        flg_validation_in          => r_supply_workflow.flg_validation,
                                        lot_in                     => r_supply_workflow.lot,
                                        rows_out                   => l_rows);
        END IF;
    END set_supply_workflow_hist;

    PROCEDURE set_supply_wf_hist_quant
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_status         IN supply_workflow.flg_status%TYPE DEFAULT NULL
    ) IS
        l_id_supply_workflow_hist supply_workflow_hist.id_supply_workflow_hist%TYPE;
        r_supply_workflow         supply_workflow%ROWTYPE;
        l_rows                    table_varchar;
    
    BEGIN
        SELECT sw.*
          INTO r_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        l_id_supply_workflow_hist := ts_supply_workflow_hist.next_key;
    
        ts_supply_workflow_hist.ins(id_supply_workflow_hist_in => l_id_supply_workflow_hist,
                                    id_supply_workflow_in      => r_supply_workflow.id_supply_workflow,
                                    id_professional_in         => r_supply_workflow.id_professional,
                                    id_episode_in              => r_supply_workflow.id_episode,
                                    id_supply_request_in       => r_supply_workflow.id_supply_request,
                                    id_supply_in               => r_supply_workflow.id_supply,
                                    id_supply_location_in      => r_supply_workflow.id_supply_location,
                                    barcode_req_in             => r_supply_workflow.barcode_req,
                                    barcode_scanned_in         => r_supply_workflow.barcode_scanned,
                                    quantity_in                => r_supply_workflow.total_quantity,
                                    id_unit_measure_in         => r_supply_workflow.id_unit_measure,
                                    id_context_in              => r_supply_workflow.id_context,
                                    flg_context_in             => r_supply_workflow.flg_context,
                                    flg_status_in              => nvl(i_flg_status, r_supply_workflow.flg_status),
                                    dt_request_in              => r_supply_workflow.dt_request,
                                    dt_returned_in             => r_supply_workflow.dt_returned,
                                    notes_in                   => r_supply_workflow.notes,
                                    id_prof_cancel_in          => r_supply_workflow.id_prof_cancel,
                                    dt_cancel_in               => r_supply_workflow.dt_cancel,
                                    notes_cancel_in            => r_supply_workflow.notes_cancel,
                                    id_cancel_reason_in        => r_supply_workflow.id_cancel_reason,
                                    notes_reject_in            => r_supply_workflow.notes_reject,
                                    dt_reject_in               => r_supply_workflow.dt_reject,
                                    id_prof_reject_in          => r_supply_workflow.id_prof_reject,
                                    dt_supply_workflow_in      => r_supply_workflow.dt_supply_workflow,
                                    id_req_reason_in           => r_supply_workflow.id_req_reason,
                                    id_del_reason_in           => r_supply_workflow.id_del_reason,
                                    flg_outdated_in            => r_supply_workflow.flg_outdated,
                                    total_quantity_in          => r_supply_workflow.total_quantity,
                                    total_avail_quantity_in    => r_supply_workflow.total_avail_quantity,
                                    cod_table_in               => r_supply_workflow.cod_table,
                                    flg_preparing_in           => r_supply_workflow.flg_preparing,
                                    flg_countable_in           => r_supply_workflow.flg_countable,
                                    id_supply_area_in          => r_supply_workflow.id_supply_area,
                                    rows_out                   => l_rows);
    END set_supply_wf_hist_quant;

    PROCEDURE set_supply_wf_hist_outd
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_status         IN supply_workflow.flg_status%TYPE DEFAULT NULL
    ) IS
        l_rows table_varchar;
    
    BEGIN
    
        ts_supply_workflow_hist.upd(flg_outdated_in => pk_supplies_constant.g_sww_outdated,
                                    where_in        => 'id_supply_workflow = ' || i_id_supply_workflow ||
                                                       ' and flg_status = ''' || i_flg_status ||
                                                       ''' and flg_outdated=''A''',
                                    rows_out        => l_rows);
    END set_supply_wf_hist_outd;

    FUNCTION set_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_edition        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_outdate        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_status         IN supply_workflow.flg_status%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_hist     PLS_INTEGER := 0;
        l_quantity       supply_workflow.quantity%TYPE;
        l_total_quantity supply_workflow.total_quantity%TYPE;
        l_status         supply_workflow.flg_outdated%TYPE;
        l_sw_status      supply_workflow.flg_status%TYPE;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
    
        SELECT sw.quantity, sw.total_quantity, sw.flg_outdated, sw.flg_status
          INTO l_quantity, l_total_quantity, l_status, l_sw_status
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        IF (i_flg_edition = pk_alert_constant.g_no)
        THEN
            g_error := 'CALL get_count_hist';
            IF NOT get_count_hist(i_lang               => i_lang,
                                  i_prof               => i_prof,
                                  i_id_supply_workflow => i_id_supply_workflow,
                                  o_count_hist         => l_count_hist,
                                  o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF (l_count_hist > 0 AND i_flg_outdate = pk_alert_constant.g_yes)
            THEN
                ts_supply_workflow.upd(flg_outdated_in => pk_supplies_constant.g_sww_active,
                                       where_in        => 'id_supply_workflow = ' || i_id_supply_workflow ||
                                                          ' and flg_status = ''' || i_flg_status || '''',
                                       rows_out        => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SUPPLY_WORKFLOW',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            ELSE
                --IT ONLY GOES TO THE HISTORY IF IT IS NOT YET THERE. ANY OTHER ACTION WAS ALREADY PERFORMED OVER THIS LOAN
                IF (l_count_hist < 1 OR l_status = pk_supplies_constant.g_sww_edited)
                THEN
                    set_supply_workflow_hist(i_id_supply_workflow, NULL, NULL);
                END IF;
            END IF;
        ELSE
        
            IF (l_quantity = l_total_quantity OR l_status = pk_supplies_constant.g_sww_edited OR
               l_sw_status = pk_supplies_constant.g_sww_deliver_institution)
            THEN
                set_supply_workflow_hist(i_id_supply_workflow, NULL, NULL);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HISTORY',
                                              o_error);
            RETURN FALSE;
    END set_history;

    FUNCTION set_edit_loans
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_supply_workflow  IN table_number,
        i_supply_qty       IN table_number,
        i_dt_return        IN table_varchar,
        i_barcode_scanned  IN table_varchar,
        i_asset_nr_scanned IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_return           supply_workflow.dt_returned%TYPE;
        l_rows_workflow       table_varchar;
        l_flg_status          supply_workflow.flg_status%TYPE;
        l_quantity            supply_workflow.quantity%TYPE;
        l_total_quantity      supply_workflow.total_quantity%TYPE;
        l_avail_units         supply_soft_inst.quantity%TYPE;
        l_ret                 BOOLEAN;
        l_id_supply           supply_workflow.id_supply%TYPE;
        l_tab_supply_workflow table_number := table_number();
        l_id_parent           supply_workflow.id_sup_workflow_parent%TYPE;
        l_id_supply_area      supply_area.id_supply_area%TYPE;
    
    BEGIN
        g_error        := 'GET TIMESTAMP';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET SUPPLY AREA';
        IF NOT pk_supplies_core.get_id_supply_area(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_supply          => NULL,
                                                   i_flg_type           => NULL,
                                                   i_id_supply_workflow => i_supply_workflow(1),
                                                   o_id_supply_area     => l_id_supply_area,
                                                   o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        FOR i IN 1 .. i_supply_workflow.count
        LOOP
            SELECT sw.flg_status, sw.quantity, sw.total_quantity, sw.id_supply, sw.id_sup_workflow_parent
              INTO l_flg_status, l_quantity, l_total_quantity, l_id_supply, l_id_parent
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_supply_workflow(i);
        
            g_error := 'CALL set_history for id_supply_workflow: ' || i_supply_workflow(i);
            IF NOT set_history(i_lang               => i_lang,
                               i_prof               => i_prof,
                               i_id_supply_workflow => i_supply_workflow(i),
                               i_flg_edition        => pk_alert_constant.g_yes,
                               o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            --IT IS ONLY POSSIBLE TO EDIT THE QUANTITY BETWEEN THE NR OF LOANED UNITS AND NR PREVIOUS LOANS + NR AVAIL
            l_avail_units := pk_supplies_core.get_nr_avail_units(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_supply_area => l_id_supply_area,
                                                                 i_id_supply      => l_id_supply,
                                                                 i_id_episode     => i_id_episode);
            IF (i_supply_qty(i) < (l_total_quantity - l_quantity) OR i_supply_qty(i) > l_quantity + l_avail_units)
            THEN
                RAISE g_user_exception;
            END IF;
        
            g_error     := 'CALL pk_date_utils.get_string_tstz for i_dt_return';
            l_dt_return := pk_date_utils.get_string_tstz(i_lang,
                                                         i_prof,
                                                         i_dt_return(i),
                                                         pk_date_utils.get_timezone(i_lang, i_prof));
        
            g_error := 'CALL ts_supply_workflow.upd for i_supply_workflow: ' || i_supply_workflow(i);
            ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow(i),
                                   id_professional_in    => i_prof.id,
                                   quantity_in           => CASE
                                                                WHEN l_quantity < l_total_quantity THEN --                                           
                                                                 CASE
                                                                     WHEN i_supply_qty(i) < l_total_quantity THEN
                                                                      l_quantity - (l_total_quantity - i_supply_qty(i))
                                                                     ELSE
                                                                      l_quantity + (i_supply_qty(i) - l_total_quantity)
                                                                 END --                                           
                                                                ELSE
                                                                 i_supply_qty(i)
                                                            END,
                                   total_quantity_in     => i_supply_qty(i),
                                   --FLG_STATUS_IN         =>PK_SUPPLIES_CONSTANT.G_SWW_LOANED_EDITED,
                                   dt_returned_in        => l_dt_return,
                                   barcode_scanned_nin   => FALSE,
                                   barcode_scanned_in    => i_barcode_scanned(i),
                                   asset_number_nin      => FALSE,
                                   asset_number_in       => i_asset_nr_scanned(i),
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   flg_outdated_in       => pk_supplies_constant.g_sww_edited,
                                   rows_out              => l_rows_workflow);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows_workflow,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                          'ID_PROFESSIONAL',
                                                                          'QUANTITY',
                                                                          'TOTAL_QUANTITY',
                                                                          'FLG_STATUS',
                                                                          'DT_RETURNED',
                                                                          'DT_SUPPLY_WORKFLOW'));
        
            --UPDATE TOTAL_QUANTITY IN ALL CHILDS
            SELECT sw.id_supply_workflow
              BULK COLLECT
              INTO l_tab_supply_workflow
              FROM supply_workflow sw
             WHERE sw.id_sup_workflow_parent = i_supply_workflow(i);
        
            FOR j IN 1 .. l_tab_supply_workflow.count
            LOOP
                g_error := 'CALL ts_supply_workflow.upd for i_supply_workflow: ' || l_tab_supply_workflow(j);
                ts_supply_workflow.upd(id_supply_workflow_in => l_tab_supply_workflow(j),
                                       total_quantity_in     => i_supply_qty(i),
                                       rows_out              => l_rows_workflow);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SET_EDIT_LOANS',
                                              i_rowids       => l_rows_workflow,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW', 'TOTAL_QUANTITY'));
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            l_ret := pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                         i_sqlcode     => '',
                                                         i_sqlerrm     => '',
                                                         i_message     => g_error,
                                                         i_owner       => g_package_owner,
                                                         i_package     => g_package_name,
                                                         i_function    => 'SET_EDIT_SUPPLY_WORKFLOW',
                                                         i_action_type => pk_act_therap_constant.g_warning,
                                                         i_action_msg  => pk_message.get_message(i_lang,
                                                                                                 pk_act_therap_constant.g_msg_error),
                                                         i_msg_title   => pk_message.get_message(i_lang,
                                                                                                 pk_act_therap_constant.g_msg_wrong_loan_units),
                                                         o_error       => o_error);
        
            RETURN l_ret;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EDIT_LOANS',
                                              o_error);
        
            RETURN FALSE;
    END set_edit_loans;

    FUNCTION set_active_wf_parent
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_wf_parent IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_quantity_parent  IN supply_workflow.quantity%TYPE,
        i_quantity_child   IN supply_workflow.quantity%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        i_flg_edition      IN VARCHAR2,
        i_dt_return        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        -- IF THE PARENT IS OUTDATED 
        --ACTIVATE IT AGAIN
        --UPDATE THE STATUS OF THE CURRENT REGISTRY
        g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || i_supply_wf_parent;
        ts_supply_workflow.upd(id_supply_workflow_in => i_supply_wf_parent,
                               quantity_in           => i_quantity_parent,
                               flg_status_in         => pk_supplies_constant.g_sww_loaned,
                               flg_outdated_in       => pk_supplies_constant.g_sww_active,
                               rows_out              => l_rows);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW', 'QUANTITY', 'FLG_OUTDATED'));
    
        set_supply_workflow_hist(i_supply_workflow, NULL, NULL);
    
        IF (i_flg_edition = pk_alert_constant.g_no)
        THEN
        
            g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || i_supply_workflow;
            ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow,
                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_cancelled,
                                   notes_cancel_in       => i_cancel_notes,
                                   id_cancel_reason_in   => i_id_cancel_reason,
                                   dt_cancel_in          => g_sysdate_tstz,
                                   id_prof_cancel_in     => i_prof.id,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                          'FLG_STATUS',
                                                                          'NOTES_CANCEL',
                                                                          'ID_CANCEL_REASON',
                                                                          'DT_CANCEL',
                                                                          'ID_PROF_CANCEL',
                                                                          'DT_SUPPLY_WORKFLOW'));
        ELSE
            g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || i_supply_workflow;
            ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow,
                                   quantity_in           => i_quantity_child,
                                   flg_outdated_in       => pk_supplies_constant.g_sww_edited,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   dt_returned_in        => i_dt_return,
                                   dt_returned_nin       => FALSE,
                                   rows_out              => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                          'FLG_STATUS',
                                                                          'NOTES_CANCEL',
                                                                          'ID_CANCEL_REASON',
                                                                          'DT_CANCEL',
                                                                          'ID_PROF_CANCEL',
                                                                          'DT_SUPPLY_WORKFLOW'),
                                          i_rowids       => l_rows,
                                          o_error        => o_error);
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
                                              'SET_ACTIVE_WF_PARENT',
                                              o_error);
        
            RETURN FALSE;
    END set_active_wf_parent;

    FUNCTION set_upd_and_insert
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN supply_workflow.id_episode%TYPE,
        i_supply_workflow_upd IN supply_workflow.id_supply_workflow%TYPE,
        i_quantity_upd        IN supply_workflow.quantity%TYPE,
        --INFO TO BE INSERTED        
        i_id_supply            IN supply_workflow.id_supply%TYPE,
        i_id_supply_set        IN supply_workflow.id_supply_set%TYPE,
        i_barcode_scanned      IN supply_workflow.barcode_scanned%TYPE,
        i_quantity             IN supply_workflow.quantity%TYPE,
        i_total_quantity       IN supply_workflow.total_quantity%TYPE,
        i_id_context           IN supply_workflow.id_context%TYPE,
        i_flg_context          IN supply_workflow.flg_context%TYPE,
        i_flg_status           IN supply_workflow.flg_status%TYPE,
        i_flg_edited           IN supply_workflow.flg_outdated%TYPE,
        i_dt_returned          IN supply_workflow.dt_returned%TYPE,
        i_notes                IN supply_workflow.notes%TYPE,
        i_notes_cancel         IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason     IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel            IN supply_workflow.dt_cancel%TYPE,
        i_total_avail_quantity IN supply_workflow.total_avail_quantity%TYPE,
        o_id_supply_workflow   OUT supply_workflow.id_supply_workflow%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows           table_varchar;
        l_dt_returned    supply_workflow_hist.dt_returned%TYPE;
        l_id_supply_area supply_area.id_supply_area%TYPE;
    
    BEGIN
    
        g_error := 'CALL get_hist_return_date for id_supply_workflow: ' || i_supply_workflow_upd;
        IF NOT get_hist_return_date(i_lang               => i_lang,
                                    i_prof               => i_prof,
                                    i_id_supply_workflow => i_supply_workflow_upd,
                                    o_return_date        => l_dt_returned,
                                    o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --UPDATE STATE
        set_supply_workflow_hist(i_supply_workflow_upd, NULL, NULL);
    
        g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || i_supply_workflow_upd;
        ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow_upd,
                               flg_status_in         => pk_supplies_constant.g_sww_loaned,
                               quantity_in           => i_quantity_upd,
                               dt_returned_in        => l_dt_returned,
                               id_professional_in    => i_prof.id,
                               id_prof_cancel_in     => NULL,
                               dt_cancel_in          => NULL,
                               notes_cancel_in       => NULL,
                               dt_reject_in          => NULL,
                               id_prof_reject_in     => NULL,
                               flg_outdated_in       => pk_supplies_constant.g_sww_active, --I_FLG_EDITED,
                               dt_supply_workflow_in => g_sysdate_tstz,
                               rows_out              => l_rows);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                      'FLG_STATUS',
                                                                      'QUANTITY',
                                                                      'dt_returned',
                                                                      'id_professional',
                                                                      'id_prof_cancel',
                                                                      'dt_cancel',
                                                                      'notes_cancel',
                                                                      'dt_reject',
                                                                      'id_prof_reject',
                                                                      'dt_supply_workflow'));
    
        g_error := 'GET SUPPLY AREA';
        IF NOT pk_supplies_core.get_id_supply_area(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_supply          => NULL,
                                                   i_flg_type           => NULL,
                                                   i_id_supply_workflow => i_supply_workflow_upd,
                                                   o_id_supply_area     => l_id_supply_area,
                                                   o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- INSERT CANCELLED DEVOLUTION
        o_id_supply_workflow := ts_supply_workflow.next_key;
    
        ts_supply_workflow.ins(id_supply_workflow_in     => o_id_supply_workflow,
                               id_professional_in        => i_prof.id,
                               id_episode_in             => i_id_episode,
                               id_supply_in              => i_id_supply,
                               id_supply_set_in          => i_id_supply_set,
                               barcode_scanned_in        => i_barcode_scanned,
                               quantity_in               => i_quantity,
                               total_quantity_in         => i_total_quantity,
                               id_context_in             => i_id_context,
                               flg_context_in            => i_flg_context,
                               flg_status_in             => i_flg_status,
                               dt_supply_workflow_in     => g_sysdate_tstz,
                               dt_returned_in            => i_dt_returned,
                               notes_in                  => i_notes,
                               notes_cancel_in           => i_notes_cancel,
                               id_cancel_reason_in       => i_id_cancel_reason,
                               dt_cancel_in              => i_dt_cancel,
                               id_prof_cancel_in         => i_prof.id,
                               id_sup_workflow_parent_in => i_supply_workflow_upd,
                               total_avail_quantity_in   => i_total_avail_quantity,
                               flg_outdated_in           => i_flg_edited,
                               id_supply_area_in         => l_id_supply_area,
                               rows_out                  => l_rows);
    
        IF i_flg_context != pk_supplies_constant.g_context_procedure_req
        THEN
            pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => o_id_supply_workflow);
        END IF;
    
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows,
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
                                              'SET_UPD_AND_INSERT',
                                              o_error);
        
            RETURN FALSE;
    END set_upd_and_insert;

    FUNCTION set_partial_deliver
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_wf_parent IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_qty          IN supply_workflow.quantity%TYPE,
        i_id_episode          IN supply_workflow.id_episode%TYPE,
        i_r_supply_workflow   IN supply_workflow%ROWTYPE,
        i_current_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_edition         IN VARCHAR2,
        i_old_quantity        IN supply_workflow.quantity%TYPE,
        i_dt_return           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_barcode_scanned     IN supply_workflow.barcode_scanned%TYPE,
        i_asset_nr_scanned    IN supply_workflow.asset_number%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows                   table_varchar;
        l_id_supply_workflow     supply_workflow.id_supply_workflow%TYPE;
        l_rows_ins               table_varchar;
        l_nr_units_not_delivered supply_workflow.quantity%TYPE;
        l_actual_prt_qty         supply_workflow.quantity%TYPE;
        l_id_supply_area         supply_area.id_supply_area%TYPE;
    
    BEGIN
    
        --IF THE NR OF LOANED UNITS ARE NOT ALL TO DELIVER  
        g_error := 'CALL set_history for id_supply_workflow: ' || i_id_supply_wf_parent;
        IF NOT set_history(i_lang               => i_lang,
                      i_prof               => i_prof,
                      i_id_supply_workflow => CASE
                                                  WHEN i_flg_edition = pk_alert_constant.g_no THEN
                                                   i_id_supply_wf_parent
                                                  ELSE
                                                   i_id_supply_workflow
                                              END,
                      i_flg_edition        => i_flg_edition,
                      o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF (i_id_supply_wf_parent != i_r_supply_workflow.id_supply_workflow)
        THEN
            SELECT s.quantity
              INTO l_actual_prt_qty
              FROM supply_workflow s
             WHERE s.id_supply_workflow = i_id_supply_wf_parent;
        ELSE
            l_actual_prt_qty := i_r_supply_workflow.quantity;
        END IF;
    
        IF (i_old_quantity IS NULL)
        THEN
            l_nr_units_not_delivered := l_actual_prt_qty - i_supply_qty;
        ELSIF (i_supply_qty > i_old_quantity)
        THEN
            l_nr_units_not_delivered := l_actual_prt_qty - (i_supply_qty - i_old_quantity);
        ELSE
            l_nr_units_not_delivered := l_actual_prt_qty + (i_old_quantity - i_supply_qty);
        END IF;
    
        --UPDATE THE 'L' REGISTRY
        g_error := 'UPDATE WORKFLOW NR of units for id_supply_workflow: ' || i_id_supply_wf_parent;
        ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_wf_parent,
                               id_professional_in    => i_prof.id,
                               quantity_in           => l_nr_units_not_delivered,
                               barcode_scanned_nin   => FALSE,
                               barcode_scanned_in    => i_barcode_scanned,
                               asset_number_nin      => FALSE,
                               asset_number_in       => i_asset_nr_scanned,
                               rows_out              => l_rows);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                      'ID_PROFESSIONAL',
                                                                      'QUANTITY'));
    
        IF i_flg_edition = pk_alert_constant.g_no
        THEN
            g_error := 'GET SUPPLY AREA';
            IF NOT pk_supplies_core.get_id_supply_area(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_id_supply          => NULL,
                                                       i_flg_type           => NULL,
                                                       i_id_supply_workflow => i_id_supply_wf_parent,
                                                       o_id_supply_area     => l_id_supply_area,
                                                       o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_id_supply_workflow := ts_supply_workflow.next_key;
        
            ts_supply_workflow.ins(id_supply_workflow_in     => l_id_supply_workflow,
                                   id_professional_in        => i_prof.id,
                                   id_episode_in             => i_id_episode,
                                   id_supply_request_in      => i_r_supply_workflow.id_supply_request,
                                   id_supply_in              => i_r_supply_workflow.id_supply,
                                   id_supply_set_in          => i_r_supply_workflow.id_supply_set,
                                   barcode_req_in            => i_r_supply_workflow.barcode_req,
                                   id_unit_measure_in        => i_r_supply_workflow.id_unit_measure,
                                   quantity_in               => i_supply_qty,
                                   total_quantity_in         => i_r_supply_workflow.total_quantity,
                                   id_context_in             => i_r_supply_workflow.id_context,
                                   flg_context_in            => i_r_supply_workflow.flg_context,
                                   flg_status_in             => pk_supplies_constant.g_sww_deliver_institution,
                                   dt_request_in             => i_r_supply_workflow.dt_request,
                                   dt_supply_workflow_in     => i_current_timestamp,
                                   dt_returned_in            => i_dt_return,
                                   notes_in                  => i_r_supply_workflow.notes,
                                   id_sup_workflow_parent_in => i_id_supply_wf_parent,
                                   barcode_scanned_in        => i_barcode_scanned,
                                   asset_number_in           => i_asset_nr_scanned,
                                   total_avail_quantity_in   => i_r_supply_workflow.total_avail_quantity,
                                   id_supply_area_in         => l_id_supply_area,
                                   rows_out                  => l_rows_ins);
        
            IF i_r_supply_workflow.flg_context != pk_supplies_constant.g_context_procedure_req
            THEN
                pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => l_id_supply_workflow);
            END IF;
        
            g_error := 'CALL t_data_gov_mnt.process_insert : inserted loaned registry';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUPPLY_WORKFLOW',
                                          i_rowids     => l_rows_ins,
                                          o_error      => o_error);
        ELSE
            --UPDATE THE REGISTRY BEING EDITED
            g_error := 'UPDATE WORKFLOW NR of units for id_supply_workflow: ' || i_id_supply_workflow;
            ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_workflow,
                                   id_professional_in    => i_prof.id,
                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_institution,
                                   quantity_in           => i_supply_qty,
                                   dt_returned_in        => i_dt_return,
                                   flg_outdated_in       => pk_supplies_constant.g_sww_edited,
                                   dt_supply_workflow_in => i_current_timestamp,
                                   barcode_scanned_in    => i_barcode_scanned,
                                   barcode_scanned_nin   => FALSE,
                                   asset_number_in       => i_asset_nr_scanned,
                                   asset_number_nin      => FALSE,
                                   rows_out              => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                          'ID_PROFESSIONAL',
                                                                          'QUANTITY',
                                                                          'DT_RETURNED'));
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
                                              'SET_PARTIAL_DELIVER',
                                              o_error);
        
            RETURN FALSE;
    END set_partial_deliver;

    FUNCTION set_complete_deliver
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_wf_parent IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_qty          IN supply_workflow.quantity%TYPE,
        i_current_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_edition         IN VARCHAR2,
        i_dt_return           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_barcode_scanned     IN supply_workflow.barcode_scanned%TYPE,
        i_asset_nr_scanned    IN supply_workflow.asset_number%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        g_error := 'CALL set_history for id_supply_workflow: ' || i_id_supply_workflow;
        IF NOT set_history(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_id_supply_workflow => i_id_supply_workflow,
                           i_flg_edition        => i_flg_edition,
                           o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF (i_flg_edition = pk_alert_constant.g_no)
        THEN
            g_error := 'UPDATE WORKFLOW STATUS';
            ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_wf_parent,
                                   id_professional_in    => i_prof.id,
                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_institution,
                                   dt_returned_in        => i_current_timestamp,
                                   dt_supply_workflow_in => i_current_timestamp,
                                   flg_outdated_in       => pk_supplies_constant.g_sww_active,
                                   barcode_scanned_nin   => FALSE,
                                   barcode_scanned_in    => i_barcode_scanned,
                                   asset_number_nin      => FALSE,
                                   asset_number_in       => i_asset_nr_scanned,
                                   rows_out              => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                          'ID_PROFESSIONAL',
                                                                          'FLG_STATUS',
                                                                          'DT_RETURNED'));
        
        ELSE
            IF (i_id_supply_wf_parent != i_id_supply_workflow)
            THEN
                --OUTDATE THE PARENT REGISTRY
                g_error := 'UPDATE WORKFLOW STATUS';
                ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_wf_parent,
                                       id_professional_in    => i_prof.id,
                                       flg_status_in         => pk_supplies_constant.g_sww_deliver_institution,
                                       flg_outdated_in       => pk_supplies_constant.g_sww_outdated,
                                       barcode_scanned_nin   => FALSE,
                                       barcode_scanned_in    => i_barcode_scanned,
                                       asset_number_nin      => FALSE,
                                       asset_number_in       => i_asset_nr_scanned,
                                       rows_out              => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SUPPLY_WORKFLOW',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                              'ID_PROFESSIONAL',
                                                                              'FLG_OUTDATED'));
            END IF;
        
            -- UPDATE THE CHILD RECORD (THAT IS BEING UPDATED).
            g_error := 'UPDATE WORKFLOW STATUS';
            ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_workflow,
                                   id_professional_in    => i_prof.id,
                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_institution,
                                   flg_outdated_in       => CASE
                                                                WHEN i_flg_edition = pk_alert_constant.g_no THEN
                                                                 pk_supplies_constant.g_sww_deliver_institution
                                                                ELSE
                                                                 pk_supplies_constant.g_sww_edited
                                                            END,
                                   dt_returned_in        => i_dt_return,
                                   dt_supply_workflow_in => i_current_timestamp,
                                   quantity_in           => i_supply_qty,
                                   barcode_scanned_nin   => FALSE,
                                   barcode_scanned_in    => i_barcode_scanned,
                                   asset_number_nin      => FALSE,
                                   asset_number_in       => i_asset_nr_scanned,
                                   rows_out              => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                          'ID_PROFESSIONAL',
                                                                          'FLG_OUTDATED'));
        
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
                                              'SET_COMPLETE_DELIVER',
                                              o_error);
        
            RETURN FALSE;
    END set_complete_deliver;

    FUNCTION set_cancel_deliver
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_supplies_workflow IN table_number,
        i_cancel_notes      IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason  IN supply_workflow.id_cancel_reason%TYPE,
        i_flg_edition       IN VARCHAR2,
        i_quantities        IN table_number,
        i_dt_return         IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_supply_workflow     supply_workflow.id_supply_workflow%TYPE;
        r_supply_workflow        supply_workflow%ROWTYPE;
        r_supply_workflow_parent supply_workflow%ROWTYPE;
        l_rows                   table_varchar;
    
        l_supply_wf_copy_parent supply_workflow.id_supply_workflow%TYPE := NULL;
    
        l_id_supply_workflow_cur supply_workflow.id_supply_workflow%TYPE;
        l_flg_status             supply_workflow.flg_status%TYPE;
        l_loaned_quantity        supply_workflow.quantity%TYPE;
        l_delivered_quantity     supply_workflow.quantity%TYPE;
        l_flg_edited             supply_workflow.flg_outdated%TYPE := pk_supplies_constant.g_sww_active;
    
        l_id_supplies table_number := table_number();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'update supply_workflow';
        FOR i IN 1 .. i_supplies_workflow.count
        LOOP
        
            SELECT *
              INTO r_supply_workflow
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_supplies_workflow(i);
        
            g_error := 'CALL check_cancel_deliver';
            IF NOT check_cancel_deliver(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_supply           => r_supply_workflow.id_supply,
                                        i_id_episode          => r_supply_workflow.id_episode,
                                        i_supply_workflow     => i_supplies_workflow,
                                        io_supplies_no_cancel => l_id_supplies,
                                        o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF l_id_supplies IS NOT NULL
               AND l_id_supplies.exists(1)
            THEN
                IF NOT get_canc_deliveries_msgs(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_supplies => l_id_supplies,
                                                o_flg_show    => o_flg_show,
                                                o_msg         => o_msg,
                                                o_msg_title   => o_msg_title,
                                                o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                RETURN TRUE;
            END IF;
        
            IF r_supply_workflow.id_sup_workflow_parent IS NULL
            THEN
                --CHECK IF THE PARENT ID WAS COPIED TO A CHILD RECORD 
                --(THIS HAPPENS WHEN THE PARENT WAS DELIVERED AND SOME DELIVERY WAS CANCELLED)
                IF (l_supply_wf_copy_parent IS NOT NULL) ---TODO: CHECK THIS!!!!!!!!!!!!!!!!!!!!!!!!!!
                THEN
                    SELECT *
                      INTO r_supply_workflow
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow = l_supply_wf_copy_parent;
                
                    l_id_supply_workflow_cur := l_supply_wf_copy_parent;
                ELSE
                    l_id_supply_workflow_cur := i_supplies_workflow(i);
                END IF;
            ELSE
                l_id_supply_workflow_cur := i_supplies_workflow(i);
            END IF;
        
            --IF NO PARENT EXISTS, THE DEVOLUTION GOES BACK TO THE LOANED STATE
            IF r_supply_workflow.id_sup_workflow_parent IS NULL
            THEN
            
                IF (i_flg_edition = pk_alert_constant.g_yes)
                THEN
                    l_flg_status         := pk_supplies_constant.g_sww_deliver_institution;
                    l_loaned_quantity    := r_supply_workflow.quantity - i_quantities(i);
                    l_delivered_quantity := i_quantities(i);
                    l_flg_edited         := pk_supplies_constant.g_sww_edited;
                ELSE
                    l_flg_status         := pk_supplies_constant.g_sww_deliver_cancelled;
                    l_loaned_quantity    := r_supply_workflow.quantity;
                    l_delivered_quantity := r_supply_workflow.quantity;
                    l_flg_edited         := pk_supplies_constant.g_sww_active;
                END IF;
            
                --UPDATES THE STATE EXISTING RECORD TO LOANED AND 
                --INSERTS A CHILD RECORD IN STATE 'Delivery cancelled' (WHEN CANCELLING THE DELIVERY)
                --INSERTS A CHILD RECORD IN STATE 'Delivered' (WHEN EDITING THE DELIVERY)
                g_error := 'CALL set_upd_and_insert';
                IF NOT set_upd_and_insert(i_lang                 => i_lang,
                                          i_prof                 => i_prof,
                                          i_id_episode           => r_supply_workflow.id_episode,
                                          i_supply_workflow_upd  => l_id_supply_workflow_cur,
                                          i_quantity_upd         => l_loaned_quantity,
                                          i_id_supply            => r_supply_workflow.id_supply,
                                          i_id_supply_set        => r_supply_workflow.id_supply_set,
                                          i_barcode_scanned      => r_supply_workflow.barcode_scanned,
                                          i_quantity             => l_delivered_quantity,
                                          i_total_quantity       => r_supply_workflow.total_quantity,
                                          i_id_context           => r_supply_workflow.id_context,
                                          i_flg_context          => r_supply_workflow.flg_context,
                                          i_flg_status           => l_flg_status,
                                          i_flg_edited           => l_flg_edited,
                                          i_dt_returned          => nvl(i_dt_return, r_supply_workflow.dt_returned),
                                          i_notes                => r_supply_workflow.notes,
                                          i_notes_cancel         => i_cancel_notes,
                                          i_id_cancel_reason     => i_id_cancel_reason,
                                          i_dt_cancel            => g_sysdate_tstz,
                                          i_total_avail_quantity => r_supply_workflow.total_avail_quantity,
                                          o_id_supply_workflow   => l_id_supply_workflow,
                                          o_error                => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
            ELSE
                SELECT *
                  INTO r_supply_workflow_parent
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = r_supply_workflow.id_sup_workflow_parent;
            
                IF r_supply_workflow_parent.flg_outdated != pk_supplies_constant.g_sww_outdated
                THEN
                    IF r_supply_workflow_parent.flg_status = pk_supplies_constant.g_sww_loaned
                    THEN
                        --IF A PARENT EXISTS(THE DELIVERED DID NOT INCLUDE ALL THE LOANED UNITS),
                        --UPDATES THE PARENT (REGISTRY IN STATE LOANED)                       
                        IF (i_flg_edition = pk_alert_constant.g_yes)
                        THEN
                            l_loaned_quantity := r_supply_workflow_parent.quantity +
                                                 (r_supply_workflow.quantity - i_quantities(i));
                            l_flg_edited      := pk_supplies_constant.g_sww_edited;
                        
                        ELSE
                            l_loaned_quantity := r_supply_workflow_parent.quantity + r_supply_workflow.quantity;
                        END IF;
                    
                        g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' ||
                                   r_supply_workflow.id_sup_workflow_parent;
                        ts_supply_workflow.upd(id_supply_workflow_in => r_supply_workflow.id_sup_workflow_parent,
                                               quantity_in           => l_loaned_quantity,
                                               dt_supply_workflow_in => g_sysdate_tstz,
                                               rows_out              => l_rows);
                    
                        g_error := 'CALL t_data_gov_mnt.process_update';
                        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                                      i_rowids       => l_rows,
                                                      o_error        => o_error,
                                                      i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW', 'QUANTITY'));
                    
                        set_supply_workflow_hist(l_id_supply_workflow_cur, NULL, NULL);
                    
                        -- IF ALL THE DELIVERYS ARE CANCELLED OUTDATE THE LOAN REGISTRY IN THE HISTORY
                        IF (l_loaned_quantity = r_supply_workflow.total_quantity)
                        THEN
                            g_error := 'CALL set_history for id_supply_workflow: ' ||
                                       r_supply_workflow.id_sup_workflow_parent;
                            IF NOT set_history(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_id_supply_workflow => r_supply_workflow.id_sup_workflow_parent,
                                               i_flg_edition        => pk_alert_constant.g_no,
                                               i_flg_outdate        => pk_alert_constant.g_yes,
                                               i_flg_status         => pk_supplies_constant.g_sww_loaned,
                                               o_error              => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                        END IF;
                    
                        --UPDATE THE CHILD RECORD TO THE STATE : DELIVER CANCELLED
                        -- OR UPDATE THE QUANTITY IN THE EDITION
                        IF (i_flg_edition = pk_alert_constant.g_no)
                        THEN
                            g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || l_id_supply_workflow_cur;
                            ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow_cur,
                                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_cancelled,
                                                   notes_cancel_in       => i_cancel_notes,
                                                   id_cancel_reason_in   => i_id_cancel_reason,
                                                   dt_cancel_in          => g_sysdate_tstz,
                                                   id_prof_cancel_in     => i_prof.id,
                                                   dt_supply_workflow_in => g_sysdate_tstz,
                                                   rows_out              => l_rows);
                        
                            g_error := 'CALL t_data_gov_mnt.process_update';
                            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                                          i_rowids       => l_rows,
                                                          o_error        => o_error,
                                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                                          'FLG_STATUS',
                                                                                          'NOTES_CANCEL',
                                                                                          'ID_CANCEL_REASON',
                                                                                          'DT_CANCEL',
                                                                                          'ID_PROF_CANCEL',
                                                                                          'DT_SUPPLY_WORKFLOW'));
                        ELSE
                        
                            g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || l_id_supply_workflow_cur;
                            ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow_cur,
                                                   quantity_in           => i_quantities(i),
                                                   dt_supply_workflow_in => g_sysdate_tstz,
                                                   flg_outdated_in       => pk_supplies_constant.g_sww_edited,
                                                   dt_returned_nin       => FALSE,
                                                   dt_returned_in        => i_dt_return,
                                                   rows_out              => l_rows);
                        
                            g_error := 'CALL t_data_gov_mnt.process_update';
                            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                                          i_rowids       => l_rows,
                                                          o_error        => o_error,
                                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                                          'QUANTITY'));
                        END IF;
                    ELSE
                        --THE PARENT HAD ALREADY BEEN DELIVERED    
                        --THE PARENT IS UPDATED TO STAY WITH THE NR OF LOANED UNITS
                        --IT IS CREATED A CHILD COPYING THE NR OF UNITS DELIVERED ON PARENT TO A CHILD
                        --UPDATES THE STATE EXISTING RECORD TO LOANED AND INSERTS A CHILD RECORD IN STATE 'Devolution cancelled'
                    
                        IF i_flg_edition = pk_alert_constant.g_yes
                        THEN
                            l_loaned_quantity := r_supply_workflow.quantity - i_quantities(i);
                            l_flg_edited      := pk_supplies_constant.g_sww_edited;
                        ELSE
                            l_loaned_quantity := r_supply_workflow.quantity;
                            l_flg_edited      := pk_supplies_constant.g_sww_active;
                        END IF;
                    
                        ---- UPDATE THE PARENT AND INSERT THE CHILD
                        g_error := 'CALL set_upd_and_insert';
                        IF NOT set_upd_and_insert(i_lang                 => i_lang,
                                                  i_prof                 => i_prof,
                                                  i_id_episode           => r_supply_workflow_parent.id_episode,
                                                  i_supply_workflow_upd  => r_supply_workflow_parent.id_supply_workflow,
                                                  i_quantity_upd         => l_loaned_quantity,
                                                  i_id_supply            => r_supply_workflow_parent.id_supply,
                                                  i_id_supply_set        => r_supply_workflow_parent.id_supply_set,
                                                  i_barcode_scanned      => r_supply_workflow_parent.barcode_scanned,
                                                  i_quantity             => r_supply_workflow_parent.quantity,
                                                  i_total_quantity       => r_supply_workflow_parent.total_quantity,
                                                  i_id_context           => r_supply_workflow_parent.id_context,
                                                  i_flg_context          => r_supply_workflow_parent.flg_context,
                                                  i_flg_status           => r_supply_workflow_parent.flg_status,
                                                  i_flg_edited           => l_flg_edited,
                                                  i_dt_returned          => i_dt_return,
                                                  i_notes                => r_supply_workflow_parent.notes,
                                                  i_notes_cancel         => r_supply_workflow_parent.notes_cancel,
                                                  i_id_cancel_reason     => r_supply_workflow_parent.id_cancel_reason,
                                                  i_dt_cancel            => g_sysdate_tstz,
                                                  i_total_avail_quantity => r_supply_workflow_parent.total_avail_quantity,
                                                  o_id_supply_workflow   => l_id_supply_workflow,
                                                  o_error                => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        --SAVE THE ID, BECAUSE WHEN CANCELLING A LIST OF IDS IT MAYBE CANCELLED THE PARENT 
                        --(THE ID THAT WAS COPIED TO THE NEW ID                                   
                        l_supply_wf_copy_parent := l_id_supply_workflow;
                    
                        --THE DEVOLUTION BEING CANCELLED IS UPDATED
                        set_supply_workflow_hist(l_id_supply_workflow_cur, NULL, NULL);
                    
                        IF i_flg_edition = pk_alert_constant.g_no
                        THEN
                            g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || l_id_supply_workflow_cur;
                            ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow_cur,
                                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_cancelled,
                                                   notes_cancel_in       => i_cancel_notes,
                                                   id_cancel_reason_in   => i_id_cancel_reason,
                                                   dt_cancel_in          => g_sysdate_tstz,
                                                   id_prof_cancel_in     => i_prof.id,
                                                   dt_supply_workflow_in => g_sysdate_tstz,
                                                   rows_out              => l_rows);
                        
                            g_error := 'CALL t_data_gov_mnt.process_update';
                            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                                          i_rowids       => l_rows,
                                                          o_error        => o_error,
                                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                                          'FLG_STATUS',
                                                                                          'NOTES_CANCEL',
                                                                                          'ID_CANCEL_REASON',
                                                                                          'DT_CANCEL',
                                                                                          'ID_PROF_CANCEL'));
                        ELSE
                            g_error := 'UPDATE WORKFLOW for id_supply_workflow: ' || l_id_supply_workflow_cur;
                            ts_supply_workflow.upd(id_supply_workflow_in => l_id_supply_workflow_cur,
                                                   id_professional_in    => i_prof.id,
                                                   flg_status_in         => pk_supplies_constant.g_sww_deliver_institution,
                                                   quantity_in           => i_quantities(i),
                                                   dt_supply_workflow_in => g_sysdate_tstz,
                                                   flg_outdated_in       => pk_supplies_constant.g_sww_edited,
                                                   dt_returned_in        => i_dt_return,
                                                   dt_returned_nin       => FALSE,
                                                   rows_out              => l_rows);
                        
                            g_error := 'CALL t_data_gov_mnt.process_update';
                            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                                          i_rowids       => l_rows,
                                                          o_error        => o_error,
                                                          i_list_columns => table_varchar('ID_SUPPLY_WORKFLOW',
                                                                                          'FLG_STATUS',
                                                                                          'QUANTITY',
                                                                                          'ID_PROFESSIONAL'));
                        END IF;
                    END IF;
                ELSE
                    -- IF THE PARENT IS OUTDATED 
                    --ACTIVATE IT AGAIN
                    --UPDATE THE STATUS OF THE CURRENT RECORD
                    g_error := 'CALL set_active_wf_parent for id_supply_workflow parent: ' ||
                               r_supply_workflow.id_sup_workflow_parent;
                    IF NOT set_active_wf_parent(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_supply_wf_parent => r_supply_workflow.id_sup_workflow_parent,
                                           i_supply_workflow  => l_id_supply_workflow_cur,
                                           i_quantity_parent  => CASE
                                                                     WHEN i_flg_edition = pk_alert_constant.g_no THEN
                                                                      r_supply_workflow.quantity
                                                                     ELSE
                                                                      r_supply_workflow.quantity - i_quantities(i)
                                                                 END,
                                           i_quantity_child   => CASE
                                                                     WHEN i_quantities IS NOT NULL THEN
                                                                      i_quantities(i)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           i_cancel_notes     => i_cancel_notes,
                                           i_id_cancel_reason => i_id_cancel_reason,
                                           i_flg_edition      => i_flg_edition,
                                           i_dt_return        => i_dt_return,
                                           o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
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
                                              'SET_CANCEL_DELIVER',
                                              o_error);
            RETURN FALSE;
    END set_cancel_deliver;

    FUNCTION set_delivery
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_workflow  IN table_number,
        i_supply_qty       IN table_number,
        i_dt_return        IN table_varchar DEFAULT NULL,
        i_id_episode       IN supply_workflow.id_episode%TYPE,
        i_flg_edition      IN VARCHAR2,
        i_barcode_scanned  IN table_varchar,
        i_asset_nr_scanned IN table_varchar,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_supply_workflow  supply_workflow.id_supply_workflow%TYPE;
        l_id_parent            supply_workflow.id_supply_workflow%TYPE;
        r_supply_workflow      supply_workflow%ROWTYPE;
        l_old_quantity         supply_workflow.quantity%TYPE;
        l_max_units_to_deliver supply_workflow.quantity%TYPE;
        l_delivered_units      supply_workflow.quantity%TYPE;
        l_flg_status           supply_workflow.flg_status%TYPE;
        l_has_parent           BOOLEAN := TRUE;
        l_editable_units       supply_workflow.quantity%TYPE;
        l_not_delivered_units  supply_workflow.quantity%TYPE := 0;
        l_dt_return            TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        FOR i IN 1 .. i_supply_workflow.count
        LOOP
        
            IF (i_dt_return IS NOT NULL)
            THEN
                g_error     := 'CALL pk_date_utils.get_string_tstz for i_dt_return';
                l_dt_return := pk_date_utils.get_string_tstz(i_lang,
                                                             i_prof,
                                                             i_dt_return(i),
                                                             pk_date_utils.get_timezone(i_lang, i_prof));
            END IF;
            l_dt_return := nvl(l_dt_return, g_sysdate_tstz);
        
            -- IN THE EDITION CASE THE NR OF UNITS THAT STILL ARE TO BE DELIVERED ARE SAVED IN THE PARENT
            IF (i_flg_edition = pk_alert_constant.g_yes)
            THEN
                SELECT sw.id_sup_workflow_parent, sw.quantity
                  INTO l_cur_supply_workflow, l_old_quantity
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_supply_workflow(i);
            
                l_id_parent := nvl(l_cur_supply_workflow, i_supply_workflow(i));
            
                IF (l_cur_supply_workflow IS NOT NULL)
                THEN
                    SELECT s.flg_status, decode(s.flg_status, pk_supplies_constant.g_sww_loaned, s.quantity, 0)
                      INTO l_flg_status, l_not_delivered_units
                      FROM supply_workflow s
                     WHERE s.id_supply_workflow = l_cur_supply_workflow;
                END IF;
            
                IF (l_flg_status != pk_supplies_constant.g_sww_loaned OR l_cur_supply_workflow IS NULL)
                THEN
                    l_cur_supply_workflow := i_supply_workflow(i);
                    l_has_parent          := FALSE;
                END IF;
            
                --GET THE NR OF UNITS THAT STAY AVAILABLE DUE TO THE DECREASE OF THE QUANTITY IN OTHER EDITIONS
                -- ASSOCIATED TO THE SAME LOAN. THIS IS USEFUL WHEN EDITING MULTIPLE DEVOLUTIONS ASSOCIATED TO THE 
                -- SAME LOAN
                g_error := 'CALL get_nr_editable_units';
                IF NOT get_nr_editable_units(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_supply_workflow_prt => l_cur_supply_workflow,
                                             i_id_supply_workflow  => i_supply_workflow(i),
                                             i_supply_workflow     => i_supply_workflow,
                                             i_supply_qty          => i_supply_qty,
                                             o_nr_units            => l_editable_units,
                                             o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
                l_editable_units := nvl(l_editable_units, 0);
            ELSE
                l_cur_supply_workflow := i_supply_workflow(i);
                l_id_parent           := i_supply_workflow(i);
            END IF;
        
            --GET NR OF LOANED UNITS
            g_error := 'GET LOANED UNITS';
            SELECT *
              INTO r_supply_workflow
              FROM supply_workflow s
             WHERE s.id_supply_workflow = l_cur_supply_workflow;
        
            --EDITING A DELIVERY TO A GREATER NR OF UNITS IS SIMILAR TO DELIVER UNITS           
            IF ((i_flg_edition = pk_alert_constant.g_yes AND l_old_quantity - l_editable_units <= i_supply_qty(i)) OR
               (i_flg_edition = pk_alert_constant.g_no))
            THEN
            
                --CALCULATE THE NUMBER OF UNITS THAT IT IS POSSIBLE TO DELIVER                                
                IF (i_flg_edition = pk_alert_constant.g_yes)
                THEN
                    l_delivered_units := l_not_delivered_units + l_old_quantity;
                
                    IF (l_old_quantity <= i_supply_qty(i))
                    THEN
                        l_max_units_to_deliver := l_delivered_units + l_editable_units;
                    ELSE
                        l_max_units_to_deliver := l_delivered_units - l_editable_units;
                    END IF;
                ELSE
                    l_max_units_to_deliver := r_supply_workflow.quantity;
                END IF;
            
                --IF THE NR OF LOANED UNITS ARE NOT ALL TO DELIVER
                IF (i_supply_qty(i) < l_max_units_to_deliver AND i_supply_qty(i) IS NOT NULL AND i_supply_qty(i) != 0 AND
                   ((i_flg_edition = pk_alert_constant.g_yes) OR i_flg_edition = pk_alert_constant.g_no))
                THEN
                    g_error := 'CALL set_partial_deliver for id_supply_workflow: ' || l_cur_supply_workflow;
                    IF NOT set_partial_deliver(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_supply_wf_parent => l_id_parent,
                                               i_id_supply_workflow  => i_supply_workflow(i),
                                               i_supply_qty          => i_supply_qty(i),
                                               i_id_episode          => i_id_episode,
                                               i_r_supply_workflow   => r_supply_workflow,
                                               i_current_timestamp   => g_sysdate_tstz,
                                               i_flg_edition         => i_flg_edition,
                                               i_old_quantity        => l_old_quantity,
                                               i_dt_return           => l_dt_return,
                                               i_barcode_scanned     => i_barcode_scanned(i),
                                               i_asset_nr_scanned    => i_asset_nr_scanned(i),
                                               o_error               => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    --ALL THE LOANED UNITS ARE BEING DELIVERED
                ELSIF (i_supply_qty(i) = l_max_units_to_deliver)
                THEN
                    g_error := 'CALL set_complete_deliver for id_supply_workflow: ' || l_cur_supply_workflow;
                    IF NOT set_complete_deliver(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_supply_wf_parent => l_id_parent,
                                                i_id_supply_workflow  => i_supply_workflow(i),
                                                i_supply_qty          => i_supply_qty(i),
                                                i_current_timestamp   => g_sysdate_tstz,
                                                i_flg_edition         => i_flg_edition,
                                                i_dt_return           => l_dt_return,
                                                i_barcode_scanned     => i_barcode_scanned(i),
                                                i_asset_nr_scanned    => i_asset_nr_scanned(i),
                                                o_error               => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                ELSE
                    RAISE g_user_exception;
                END IF;
            
                --EDITING A DELIVERY TO A LOWER NR OF UNITS IS SIMILAR TO CANCEL A DELIVERY
            ELSIF (i_flg_edition = pk_alert_constant.g_yes AND l_old_quantity > i_supply_qty(i))
            THEN
                g_error := 'CALL set_cancel_deliver';
                IF NOT set_cancel_deliver(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_supplies_workflow => table_number(i_supply_workflow(i)),
                                          i_cancel_notes      => NULL,
                                          i_id_cancel_reason  => NULL,
                                          i_flg_edition       => i_flg_edition,
                                          i_quantities        => table_number(i_supply_qty(i)),
                                          i_dt_return         => l_dt_return,
                                          o_flg_show          => o_flg_show,
                                          o_msg               => o_msg,
                                          o_msg_title         => o_msg_title,
                                          o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END LOOP;
    
        --IF THE PATIENT HAS NOT MORE LOANED SUPPLIES AND THE PARENT EPISODE IS INACTIVE, THE CHILD EPISODE
        -- SHOULD ALSO STAY INACTIVE    
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
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              pk_act_therap_constant.g_msg_wrong_del_units,
                                              pk_message.get_message(i_lang,
                                                                     i_prof,
                                                                     pk_act_therap_constant.g_msg_wrong_del_units),
                                              pk_message.get_message(i_lang,
                                                                     i_prof,
                                                                     pk_act_therap_constant.g_msg_wrong_del_units),
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DELIVERY',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DELIVERY',
                                              o_error);
            RETURN FALSE;
    END set_delivery;

    FUNCTION get_supply_by_context
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_context IN supply_request.id_context%TYPE,
        o_supply     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        BEGIN
            g_error := 'getting supply request context';
            OPEN o_supply FOR
                SELECT sr.id_supply_request, sr.flg_context
                  FROM supply_request sr
                 WHERE sr.id_context = i_id_context
                   AND sr.flg_status != pk_supplies_constant.g_sww_cancelled;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
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
                                              'GET_SUPPLY_BY_CONTEXT',
                                              o_error);
            pk_types.open_cursor_if_closed(o_supply);
            RETURN NULL;
    END get_supply_by_context;

    FUNCTION get_status_req
    (
        i_prof               IN profissional,
        i_id_supply_location IN supply_location.id_supply_location%TYPE
    ) RETURN supply_workflow.flg_status%TYPE IS
    
        l_flg_status supply_workflow.flg_status%TYPE;
    
    BEGIN
        SELECT decode(sl.flg_stock_type,
                      pk_supplies_constant.g_supply_local_stock,
                      pk_supplies_constant.g_sww_request_local,
                      pk_supplies_constant.g_supply_central_stock,
                      pk_supplies_constant.g_sww_request_central)
          INTO l_flg_status
          FROM supply_location sl
         WHERE sl.id_supply_location = i_id_supply_location
           AND nvl(sl.id_institution, 0) IN (0, i_prof.institution);
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_status_req;

    FUNCTION get_ini_status_supply_wf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_id_supply_location IN supply_location.id_supply_location%TYPE,
        i_id_supply_set      IN supply_workflow.id_supply_set%TYPE,
        i_id_supply          IN supply_workflow.id_supply%TYPE,
        i_sup_interface      IN sys_config.value%TYPE,
        i_id_inst_dest       IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN supply_workflow.flg_status%TYPE IS
    
        l_params     VARCHAR2(1000 CHAR);
        l_flg_status supply_workflow.flg_status%TYPE;
        l_sup_loc_blood_bank CONSTANT supply_location.id_supply_location%TYPE := 1002;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_area)=' || i_id_supply_area ||
                    ' i_id_supply_location=' || i_id_supply_location || ' i_id_supply_set=' || i_id_supply_set ||
                    ' i_id_supply=' || i_id_supply || ' i_sup_interface=' || i_sup_interface;
    
        IF i_sup_interface = pk_alert_constant.get_yes --THE WORKFLOW OF MATERIALS IS DONE BY INTERFACE? I_SUP_INTERFACE='Y'
           AND i_id_supply_location != l_sup_loc_blood_bank
        THEN
            l_flg_status := pk_supplies_constant.g_sww_request_wait;
        ELSE
            g_error      := 'Call get_status_req / ' || l_params;
            l_flg_status := get_status_req(i_prof,
                                           nvl(i_id_supply_location,
                                               pk_supplies_core.get_default_location(i_lang,
                                                                                     i_prof,
                                                                                     i_id_supply_area,
                                                                                     nvl(i_id_supply_set, i_id_supply),
                                                                                     i_id_inst_dest)));
        END IF;
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ini_status_supply_wf;

    FUNCTION get_total_avail_quantity
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        i_flg_cons_type  IN supply_soft_inst.flg_cons_type%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
    ) RETURN supply_soft_inst.total_avail_quantity%TYPE IS
        l_quantity supply_soft_inst.total_avail_quantity%TYPE;
        l_error    t_error_out;
    BEGIN
        g_error := 'GET total_avail_quantity';
        SELECT s.total_avail_quantity
          INTO l_quantity
          FROM supply_soft_inst s
         INNER JOIN supply_sup_area ssa
            ON ssa.id_supply_soft_inst = s.id_supply_soft_inst
           AND ssa.flg_available = pk_alert_constant.g_yes
           AND ssa.id_supply_area = i_id_supply_area
         WHERE s.id_supply = i_id_supply
           AND s.id_institution = i_prof.institution
           AND s.id_software = i_prof.software
           AND nvl(s.id_dept, 0) IN (0,
                                     (SELECT e.id_dept_requested
                                        FROM episode e
                                       WHERE e.id_episode = i_id_episode))
           AND s.flg_cons_type = i_flg_cons_type
           AND rownum = 1;
    
        RETURN l_quantity;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOTAL_AVAIL_QUANTITY',
                                              l_error);
            RETURN NULL;
    END get_total_avail_quantity;

    FUNCTION get_count_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        o_count_hist         OUT PLS_INTEGER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET count nr history for id_supply_workflow: ' || i_id_supply_workflow;
        SELECT COUNT(1)
          INTO o_count_hist
          FROM supply_workflow_hist sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_COUNT_HIST',
                                              o_error);
            RETURN FALSE;
    END get_count_hist;

    FUNCTION get_nr_editable_units
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_supply_workflow_prt IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_workflow     IN table_number,
        i_supply_qty          IN table_number,
        o_nr_units            OUT supply_workflow.quantity%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    
    BEGIN
    
        g_error := 'SELECT expected return date';
        SELECT SUM(tqt.val_qt - sw.quantity)
          INTO o_nr_units
          FROM supply_workflow sw
          JOIN (SELECT /*+opt_estimate(table t1 rows=1)*/
                 column_value val_sw, rownum nr_sw
                  FROM TABLE(i_supply_workflow) t1) tsw
            ON tsw.val_sw = sw.id_supply_workflow
          JOIN (SELECT /*+opt_estimate(table t2 rows=1)*/
                 column_value val_qt, rownum nr_qt
                  FROM TABLE(i_supply_qty) t2) tqt
            ON tqt.nr_qt = tsw.nr_sw
         WHERE (sw.id_supply_workflow = i_supply_workflow_prt OR sw.id_sup_workflow_parent = i_supply_workflow_prt)
           AND sw.quantity < tqt.val_qt
           AND sw.id_supply_workflow != i_id_supply_workflow;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_nr_units := 0;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NR_EDITABLE_UNITS',
                                              o_error);
            RETURN FALSE;
    END get_nr_editable_units;

    FUNCTION get_desc_supplies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_supplies   IN table_number,
        o_desc_supplies OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_supplies    pk_translation.t_desc_translation;
        l_code_supplies    table_varchar;
        l_code_translation pk_translation.t_desc_translation;
        l_desc_translation pk_translation.t_desc_translation;
        l_ind              PLS_INTEGER := 0;
        c_desc_supplies    pk_types.cursor_type;
    
    BEGIN
    
        SELECT DISTINCT s.code_supply
          BULK COLLECT
          INTO l_code_supplies
          FROM supply s
         WHERE s.id_supply IN (SELECT column_value
                                 FROM TABLE(i_id_supplies));
    
        IF NOT pk_translation.get_translation_array(i_lang         => i_lang,
                                                    i_code_msg_arr => l_code_supplies,
                                                    o_desc_msg_arr => c_desc_supplies)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --OPEN C_DESC_SUPPLIES;
        LOOP
            FETCH c_desc_supplies
                INTO l_code_translation, l_desc_translation;
            EXIT WHEN c_desc_supplies%NOTFOUND;
        
            l_desc_supplies := l_desc_supplies || CASE
                                   WHEN l_ind = 0
                                        OR l_desc_translation IS NULL THEN
                                    NULL
                                   ELSE
                                    ', '
                               END || l_desc_translation;
        
            IF (l_desc_translation IS NOT NULL)
            THEN
                l_ind := l_ind + 1;
            END IF;
        END LOOP;
    
        CLOSE c_desc_supplies;
    
        o_desc_supplies := l_desc_supplies;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DESC_SUPPLIES',
                                              o_error);
        
            RETURN FALSE;
    END get_desc_supplies;

    FUNCTION get_canc_deliveries_msgs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_supplies IN table_number,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_message VARCHAR2(4000);
    BEGIN
    
        IF NOT get_desc_supplies(i_lang          => i_lang,
                                 i_prof          => i_prof,
                                 i_id_supplies   => i_id_supplies,
                                 o_desc_supplies => l_desc_message,
                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_msg       := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                      i_code_mess => pk_act_therap_constant.g_msg_wrong_cancel_del),
                               pk_act_therap_constant.g_1st_replace,
                               l_desc_message);
        o_flg_show  := pk_act_therap_constant.g_flg_show_r;
        o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_act_therap_constant.g_msg_cancel_del);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CANC_DELIVERIES_MSGS',
                                              o_error);
        
            RETURN FALSE;
    END get_canc_deliveries_msgs;

    FUNCTION get_hist_return_date
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow_hist.id_supply_workflow%TYPE,
        o_return_date        OUT supply_workflow_hist.dt_returned%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SELECT expected return date';
        SELECT swh.dt_returned
          INTO o_return_date
          FROM supply_workflow_hist swh
         WHERE swh.id_supply_workflow = i_id_supply_workflow
           AND swh.flg_status = pk_supplies_constant.g_sww_loaned
           AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HIST_RETURN_DATE',
                                              o_error);
            RETURN FALSE;
    END get_hist_return_date;

    FUNCTION get_supply_soft_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_soft_inst IN table_number,
        o_flg_cons_type    OUT table_varchar,
        o_flg_reusable     OUT table_varchar,
        o_flg_editable     OUT table_varchar,
        o_flg_preparing    OUT table_varchar,
        o_flg_countable    OUT table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_flg_cons_type := table_varchar();
        o_flg_reusable  := table_varchar();
        o_flg_editable  := table_varchar();
        o_flg_preparing := table_varchar();
        o_flg_countable := table_varchar();
    
        o_flg_cons_type.extend(i_supply_soft_inst.count);
        o_flg_editable.extend(i_supply_soft_inst.count);
        o_flg_reusable.extend(i_supply_soft_inst.count);
        o_flg_preparing.extend(i_supply_soft_inst.count);
        o_flg_countable.extend(i_supply_soft_inst.count);
    
        FOR i IN 1 .. i_supply_soft_inst.count
        LOOP
            BEGIN
                g_error := 'SELECT SUPPLY_SOFT_INST - i_supply_soft_inst: ' || i_supply_soft_inst(i);
                SELECT ssi.flg_cons_type, ssi.flg_reusable, ssi.flg_editable, ssi.flg_preparing, ssi.flg_countable
                  INTO o_flg_cons_type(i), o_flg_reusable(i), o_flg_editable(i), o_flg_preparing(i), o_flg_countable(i)
                  FROM supply_soft_inst ssi
                 WHERE ssi.id_supply_soft_inst = i_supply_soft_inst(i);
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_flg_cons_type(i) := NULL;
                    o_flg_reusable(i) := NULL;
                    o_flg_editable(i) := NULL;
                    o_flg_preparing(i) := NULL;
                    o_flg_countable(i) := NULL;
            END;
        END LOOP;
    
        RETURN TRUE;
    
    END get_supply_soft_inst;

    FUNCTION check_edit_reopen_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply_qty      IN table_number,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status supply_workflow.flg_status%TYPE;
        l_count      PLS_INTEGER := 0;
    
    BEGIN
        g_error        := 'GET TIMESTAMP';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL pk_episode.get_flg_status for episode: ' || i_id_episode;
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_id_episode,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --IF THE EPISODE IS INACTIVE, CHECK IF THERE IS EDITION OF DEVOLUTIONS THAT WILL ACTIVATE 'Loans'.
        IF (l_flg_status = pk_alert_constant.g_epis_status_inactive)
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM supply_workflow sw
              JOIN (SELECT /*+opt_estimate(table t1 rows=1)*/
                     column_value val_sw, rownum nr_sw
                      FROM TABLE(i_supply_workflow) t1) tsw
                ON tsw.val_sw = sw.id_supply_workflow
              JOIN (SELECT /*+opt_estimate(table t2 rows=1)*/
                     column_value val_qt, rownum nr_qt
                      FROM TABLE(i_supply_qty) t2) tqt
                ON tqt.nr_qt = tsw.nr_sw
             WHERE sw.flg_status = pk_supplies_constant.g_sww_deliver_institution
               AND tqt.val_qt < sw.quantity;
        
            IF l_count > 0
            THEN
                g_error := 'CALL PK_ACTIVITY_THERAPIST.GET_EPIS_REOPEN_MSGS';
                IF NOT pk_activity_therapist.get_epis_reopen_msgs(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_id_episode,
                                                                  o_flg_show   => o_flg_show,
                                                                  o_msg        => o_msg,
                                                                  o_msg_title  => o_msg_title,
                                                                  o_error      => o_error)
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
                                              'CHECK_EDIT_REOPEN_EPIS',
                                              o_error);
        
            RETURN FALSE;
    END check_edit_reopen_epis;

    FUNCTION check_cancel_deliver
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply           IN supply.id_supply%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_supply_workflow     IN table_number,
        io_supplies_no_cancel /*NOCOPY*/ IN OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_avail_units    supply_workflow.quantity%TYPE;
        l_quantities     supply_workflow.quantity%TYPE;
        l_id_supply_area supply_area.id_supply_area%TYPE;
    
    BEGIN
    
        g_error := 'GET SUPPLY AREA';
        IF NOT pk_supplies_core.get_id_supply_area(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_supply          => NULL,
                                                   i_flg_type           => NULL,
                                                   i_id_supply_workflow => i_supply_workflow(1),
                                                   o_id_supply_area     => l_id_supply_area,
                                                   o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error       := 'CALL get_nr_avail_units';
        l_avail_units := pk_supplies_core.get_nr_avail_units(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_supply_area => l_id_supply_area,
                                                             i_id_supply      => i_id_supply,
                                                             i_id_episode     => i_id_episode);
    
        SELECT SUM(s.quantity)
          INTO l_quantities
          FROM supply_workflow s
         WHERE s.id_supply_workflow IN (SELECT column_value
                                          FROM TABLE(i_supply_workflow))
           AND s.id_supply = i_id_supply;
    
        IF (l_avail_units < l_quantities)
        THEN
            io_supplies_no_cancel.extend(1);
            io_supplies_no_cancel(io_supplies_no_cancel.last) := i_id_supply;
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
                                              'CHECK_CANCEL_DELIVER',
                                              o_error);
        
            RETURN FALSE;
    END check_cancel_deliver;

    PROCEDURE get_supplies_init_parameters
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
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_req_loan        sys_config.value%TYPE;
        l_cons_loan       sys_config.value%TYPE;
        l_req_local       sys_config.value%TYPE;
        l_cons_local      sys_config.value%TYPE;
        l_id_inst_dest    institution.id_institution%TYPE;
        l_id_supply_area  supply_area.id_supply_area%TYPE;
        l_flg_consumption VARCHAR2(1 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_context_vals IS NOT NULL
           AND i_context_vals.count > 0
        THEN
        
            l_flg_consumption := i_context_vals(2);
            l_id_supply_area  := i_context_vals(1);
        END IF;
    
        IF l_id_inst_dest IS NULL
        THEN
            l_req_loan   := pk_sysconfig.get_config('SUPPLIES_LOAN_REQ_AVILABLE', l_prof);
            l_cons_loan  := pk_sysconfig.get_config('SUPPLIES_LOAN_CONSUMPTION_AVILABLE', l_prof);
            l_req_local  := pk_sysconfig.get_config('SUPPLIES_LOCAL_REQ_AVILABLE', l_prof);
            l_cons_local := pk_sysconfig.get_config('SUPPLIES_LOCAL_CONSUMPTION_AVILABLE', l_prof);
        ELSE
            l_req_loan   := pk_sysconfig.get_config('SUPPLIES_LOAN_REQ_AVILABLE',
                                                    l_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
            l_cons_loan  := pk_sysconfig.get_config('SUPPLIES_LOAN_CONSUMPTION_AVILABLE',
                                                    l_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
            l_req_local  := pk_sysconfig.get_config('SUPPLIES_LOCAL_REQ_AVILABLE',
                                                    l_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
            l_cons_local := pk_sysconfig.get_config('SUPPLIES_LOCAL_CONSUMPTION_AVILABLE',
                                                    l_id_inst_dest,
                                                    pk_sr_planning.g_software_oris);
        END IF;
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
        pk_context_api.set_parameter('i_id_supply_area', l_id_supply_area);
        --pk_context_api.set_parameter('i_value',i_value);
        pk_context_api.set_parameter('i_id_inst_dest', l_id_inst_dest);
        pk_context_api.set_parameter('i_flg_consumption', l_flg_consumption);
        pk_context_api.set_parameter('l_cons_loan', l_cons_loan);
        pk_context_api.set_parameter('l_cons_local', l_cons_local);
        pk_context_api.set_parameter('l_req_loan', l_req_loan);
        pk_context_api.set_parameter('l_req_local', l_req_local);
    
        pk_context_api.set_parameter('i_value',
                                     CASE WHEN i_filter_name = 'ProceduresSearch' THEN i_context_vals(3) ELSE NULL END);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_id := l_lang;
            WHEN 'l_id_inst_dest' THEN
                o_id := NULL;
            WHEN 'l_episode' THEN
                o_id := l_episode;
            ELSE
                NULL;
        END CASE;
    
    END get_supplies_init_parameters;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_supplies_utils;
/
