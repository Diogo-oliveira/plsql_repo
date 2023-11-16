/*-- Last Change Revision: $Rev: 2045843 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:24:49 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_api_db IS

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_supply            IN table_number,
        i_supply_set        IN table_number,
        i_supply_qty        IN table_number,
        i_dt_request        IN table_varchar,
        i_dt_return         IN table_varchar,
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_lot               IN table_varchar DEFAULT NULL,
        i_barcode_scanned   IN table_varchar DEFAULT NULL,
        i_dt_expiration     IN table_varchar DEFAULT NULL,
        i_flg_validation    IN table_varchar DEFAULT NULL,
        i_supply_loc        IN table_number DEFAULT NULL,
        o_supply_request    OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_supply_t_number  table_number := table_number();
        l_supply_t_varchar table_varchar := table_varchar();
        l_tbl_supply_loc   table_number := table_number();
    
    BEGIN
    
        g_error := 'GETTING SUPPLY LOCATION AND NOTES';
        IF i_supply_loc.exists(1)
           AND i_supply_loc.count = i_supply.count
        THEN
            SELECT NULL interv_t_number, NULL interv_t_varchar
              BULK COLLECT
              INTO l_supply_t_number, l_supply_t_varchar
              FROM supply_soft_inst ssi
             INNER JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                          t.*
                           FROM TABLE(i_supply) t) b
                ON b.column_value = ssi.id_supply
             WHERE ssi.id_supply IN (SELECT /*+opt_estimate (table t rows=1)*/
                                      t.column_value
                                       FROM TABLE(i_supply) t)
               AND ssi.id_institution = i_prof.institution
               AND ssi.id_software = i_prof.software;
        
            l_tbl_supply_loc := i_supply_loc;
        ELSE
            SELECT NULL interv_t_number, NULL interv_t_varchar, NULL supply_loc
              BULK COLLECT
              INTO l_supply_t_number, l_supply_t_varchar, l_tbl_supply_loc
              FROM supply_soft_inst ssi
             INNER JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                          t.*
                           FROM TABLE(i_supply) t) b
                ON b.column_value = ssi.id_supply
             WHERE ssi.id_supply IN (SELECT /*+opt_estimate (table t rows=1)*/
                                      t.column_value
                                       FROM TABLE(i_supply) t)
               AND ssi.id_institution = i_prof.institution
               AND ssi.id_software = i_prof.software;
        END IF;
    
        g_error := 'CALL pk_supplies_core.CREATE_REQUEST';
        IF NOT pk_supplies_core.create_supply_order(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_supply_area    => pk_supplies_constant.g_area_supplies,
                                                    i_id_episode        => i_episode,
                                                    i_supply            => i_supply,
                                                    i_supply_set        => i_supply_set,
                                                    i_supply_qty        => i_supply_qty,
                                                    i_supply_loc        => l_tbl_supply_loc,
                                                    i_dt_request        => i_dt_request,
                                                    i_dt_return         => i_dt_return,
                                                    i_id_req_reason     => l_supply_t_number,
                                                    i_id_context        => table_number(i_id_context),
                                                    i_flg_context       => table_varchar(i_flg_context),
                                                    i_notes             => l_supply_t_varchar,
                                                    i_supply_flg_status => i_supply_flg_status,
                                                    i_id_inst_dest      => NULL,
                                                    i_lot               => i_lot,
                                                    i_barcode_scanned   => i_barcode_scanned,
                                                    i_dt_expiration     => i_dt_expiration,
                                                    i_flg_validation    => i_flg_validation,
                                                    o_id_supply_request => o_supply_request,
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
                                              'CREATE_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_supply_order;

    FUNCTION create_supply_order
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_content_supply     IN table_varchar,
        i_id_content_supply_set IN table_varchar,
        i_supply_qty            IN table_number,
        i_dt_request            IN table_varchar,
        i_dt_return             IN table_varchar,
        i_id_context            IN supply_request.id_context%TYPE,
        i_flg_context           IN supply_request.flg_context%TYPE,
        i_notes                 IN table_varchar,
        i_type_request          IN VARCHAR2,
        o_supply_request        OUT supply_request.id_supply_request%TYPE,
        o_supply_workflow       OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_supply_t_number  table_number := table_number();
        l_supply_t_varchar table_varchar := table_varchar();
    
        l_supply_workflow  table_number := table_number();
        l_flg_supply_type  table_varchar := table_varchar();
        l_barcode_scanned  table_varchar := table_varchar();
        l_dt_expiration    table_varchar := table_varchar();
        l_flg_validation   table_varchar := table_varchar();
        l_lot              table_varchar := table_varchar();
        l_dt_expected_date table_varchar := table_varchar();
        l_deliver_needed   table_varchar := table_varchar();
    
        l_supp_workflow_out table_number := table_number();
    
        l_id_supply     table_number := table_number();
        l_id_supply_set table_number := table_number();
    
        l_flg_show  VARCHAR2(200 CHAR);
        l_msg_title VARCHAR2(200 CHAR);
        l_msg       VARCHAR2(200 CHAR);
    
    BEGIN
    
        FOR i IN i_id_content_supply.first .. i_id_content_supply.last
        LOOP
            l_id_supply.extend;
            IF i_id_content_supply(i) IS NULL
            THEN
                l_id_supply(i) := NULL;
            ELSE
                SELECT s.id_supply
                  INTO l_id_supply(i)
                  FROM supply s
                 WHERE s.id_content = i_id_content_supply(i)
                   AND s.flg_available = 'Y'
                   AND rownum = 1;
            END IF;
        END LOOP;
    
        FOR i IN i_id_content_supply_set.first .. i_id_content_supply_set.last
        LOOP
            l_id_supply_set.extend;
            IF i_id_content_supply_set(i) IS NULL
            THEN
                l_id_supply_set(i) := NULL;
            ELSE
                SELECT s.id_supply
                  INTO l_id_supply_set(i)
                  FROM supply s
                 WHERE s.id_content = i_id_content_supply_set(i)
                   AND s.flg_available = 'Y'
                   AND rownum = 1;
            END IF;
        END LOOP;
    
        SELECT NULL interv_t_number, NULL interv_t_varchar
          BULK COLLECT
          INTO l_supply_t_number, l_supply_t_varchar
          FROM supply_soft_inst ssi
         WHERE ssi.id_supply IN (SELECT column_value
                                   FROM TABLE(l_id_supply))
           AND ssi.id_institution = i_prof.institution
           AND ssi.id_software = i_prof.software;
    
        FOR i IN l_id_supply.first .. l_id_supply.last
        LOOP
            l_supply_workflow.extend();
            l_supply_workflow(i) := NULL;
        
            l_flg_supply_type.extend();
            BEGIN
                SELECT s.flg_type
                  INTO l_flg_supply_type(i)
                  FROM supply s
                 WHERE s.id_supply = l_id_supply(i);
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_supply_type(i) := NULL;
            END;
        
            l_barcode_scanned.extend();
            l_barcode_scanned(i) := NULL;
        
            l_dt_expiration.extend();
            l_dt_expiration(i) := NULL;
        
            l_flg_validation.extend();
            l_flg_validation(i) := NULL;
        
            l_lot.extend();
            l_lot(i) := NULL;
        
            l_dt_expected_date.extend();
            l_dt_expected_date(i) := NULL;
        
            l_deliver_needed.extend();
            l_deliver_needed(i) := NULL;
        
        END LOOP;
    
        IF i_type_request = pk_supplies_constant.g_sww_request_local
        THEN
            g_error := 'CALL pk_supplies_core.CREATE_REQUEST';
            IF NOT pk_supplies_core.create_supply_order(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_supply_area    => pk_supplies_constant.g_area_supplies,
                                                        i_id_episode        => i_episode,
                                                        i_supply            => l_id_supply,
                                                        i_supply_set        => l_id_supply_set,
                                                        i_supply_qty        => i_supply_qty,
                                                        i_supply_loc        => l_supply_t_number,
                                                        i_dt_request        => i_dt_request,
                                                        i_dt_return         => i_dt_return,
                                                        i_id_req_reason     => l_supply_t_number,
                                                        i_id_context        => table_number(i_id_context),
                                                        i_flg_context       => table_varchar(i_flg_context),
                                                        i_notes             => i_notes,
                                                        i_supply_flg_status => NULL,
                                                        i_id_inst_dest      => NULL,
                                                        o_id_supply_request => o_supply_request,
                                                        o_error             => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            SELECT sw.id_supply_workflow
              BULK COLLECT
              INTO o_supply_workflow
              FROM supply_workflow sw
             WHERE sw.id_supply_request = o_supply_request;
        
        ELSIF i_type_request = pk_supplies_constant.g_sww_consumed
        THEN
            g_error := 'CALL PK_SUPPLIES_CORE.CREATE_SUPPLY_WITH_CONSUMPTION';
            IF NOT pk_supplies_core.create_supply_with_consumption(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_episode         => i_episode,
                                                                   i_id_context         => i_id_context,
                                                                   i_flg_context        => i_flg_context,
                                                                   i_id_supply_workflow => l_supply_workflow,
                                                                   i_supply             => l_id_supply,
                                                                   i_supply_set         => l_id_supply_set,
                                                                   i_supply_qty         => i_supply_qty,
                                                                   i_flg_supply_type    => l_flg_supply_type,
                                                                   i_barcode_scanned    => l_barcode_scanned,
                                                                   i_fixed_asset_number => NULL,
                                                                   i_deliver_needed     => l_deliver_needed,
                                                                   i_flg_cons_type      => l_supply_t_varchar,
                                                                   i_notes              => i_notes,
                                                                   i_dt_expected_date   => l_dt_expected_date,
                                                                   i_check_quantities   => pk_alert_constant.g_no,
                                                                   i_dt_expiration      => l_dt_expiration,
                                                                   i_flg_validation     => l_flg_validation,
                                                                   i_lot                => l_lot,
                                                                   i_test               => pk_supplies_constant.g_no,
                                                                   o_flg_show           => l_flg_show,
                                                                   o_msg_title          => l_msg_title,
                                                                   o_msg                => l_msg,
                                                                   o_error              => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            BEGIN
            
                FOR i IN l_id_supply.first .. l_id_supply.last
                LOOP
                    l_supp_workflow_out.extend;
                
                    SELECT t.*
                      INTO l_supp_workflow_out(i)
                      FROM (SELECT sw.id_supply_workflow
                              FROM supply_workflow sw
                             WHERE sw.id_episode = i_episode
                               AND sw.id_professional = i_prof.id
                               AND sw.id_supply_request IS NULL
                               AND sw.quantity = i_supply_qty(i)
                             ORDER BY sw.create_time DESC) t
                     WHERE rownum = 1;
                
                END LOOP;
            
                o_supply_workflow := l_supp_workflow_out;
            
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
            END;
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

    FUNCTION cancel_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_workflow  IN table_number,
        i_notes            IN table_clob,
        i_id_cancel_reason IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN i_supply_workflow.first .. i_supply_workflow.last
        LOOP
        
            IF NOT pk_supplies_core.cancel_supply_order(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_supplies         => table_number(i_supply_workflow(i)),
                                                        i_id_prof_cancel   => NULL,
                                                        i_cancel_notes     => i_notes(i),
                                                        i_id_cancel_reason => i_id_cancel_reason(i),
                                                        i_dt_cancel        => NULL,
                                                        o_error            => o_error)
            THEN
                RAISE g_other_exception;
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
                                              'CANCEL_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_supply_order;

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
    
        l_supply_order   pk_types.cursor_type;
        l_supply_request supply_request.id_supply_request%TYPE;
        l_flg_context    supply_request.flg_context%TYPE;
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_UTILS.GET_SUPPLY_BY_CONTEXT';
        IF NOT pk_supplies_utils.get_supply_by_context(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_context => i_id_context,
                                                       o_supply     => l_supply_order,
                                                       o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        LOOP
            FETCH l_supply_order
                INTO l_supply_request, l_flg_context;
            EXIT WHEN l_supply_order%NOTFOUND;
        
            IF l_flg_context = i_flg_context
            THEN
                g_error := 'CALL PK_SUPPLIES_CORE.CANCEL_SUPPLY_REQUEST';
                IF NOT pk_supplies_core.cancel_supply_request(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_supply_request   => l_supply_request,
                                                              i_notes            => i_cancel_notes,
                                                              i_id_cancel_reason => i_cancel_reason,
                                                              o_error            => o_error)
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
                                              'CANCEL_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_supply_order;

    FUNCTION cancel_request --cancel_supply_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_request   IN supply_request.id_supply_request%TYPE,
        i_notes            IN supply_request.notes%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.cancel_supply_request(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_supply_request   => i_supply_request,
                                                      i_notes            => i_notes,
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
                                              'CANCEL_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_request;

    FUNCTION create_request
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
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_notes             IN table_varchar,
        i_flg_cons_type     IN table_varchar,
        i_flg_reusable      IN table_varchar,
        i_flg_editable      IN table_varchar,
        i_flg_preparing     IN table_varchar,
        i_flg_countable     IN table_varchar,
        i_supply_soft_inst  IN table_number,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_id_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_cons_type table_varchar;
        l_flg_reusable  table_varchar;
        l_flg_editable  table_varchar;
        l_flg_preparing table_varchar;
        l_flg_countable table_varchar;
    
    BEGIN
    
        IF NOT pk_supplies_core.create_supply_order(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_supply_area    => i_id_supply_area,
                                                    i_id_episode        => i_id_episode,
                                                    i_supply            => i_supply,
                                                    i_supply_set        => i_supply_set,
                                                    i_supply_qty        => i_supply_qty,
                                                    i_supply_loc        => i_supply_loc,
                                                    i_dt_request        => i_dt_request,
                                                    i_dt_return         => i_dt_return,
                                                    i_id_req_reason     => i_id_req_reason,
                                                    i_flg_reason_req    => i_flg_reason_req,
                                                    i_id_context        => table_number(i_id_context),
                                                    i_flg_context       => table_varchar(i_flg_context),
                                                    i_notes             => i_notes,
                                                    i_supply_flg_status => i_supply_flg_status,
                                                    i_id_inst_dest      => i_id_inst_dest,
                                                    o_id_supply_request => o_id_supply_request,
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
                                              'CREATE_REQUEST',
                                              o_error);
            RETURN FALSE;
    END create_request;

    FUNCTION set_supply_consumption --create_supply_with_consumption
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
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_show  VARCHAR2(200 CHAR);
        l_msg_title VARCHAR2(200 CHAR);
        l_msg       VARCHAR2(200 CHAR);
    
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
                                                               i_fixed_asset_number => i_fixed_asset_number,
                                                               i_deliver_needed     => i_deliver_needed,
                                                               i_flg_cons_type      => i_flg_cons_type,
                                                               i_notes              => i_notes,
                                                               i_dt_expected_date   => i_dt_expected_date,
                                                               i_check_quantities   => i_check_quantities,
                                                               i_dt_expiration      => NULL,
                                                               i_flg_validation     => i_flg_validation,
                                                               i_lot                => i_lot,
                                                               i_test               => pk_supplies_constant.g_no,
                                                               o_flg_show           => l_flg_show,
                                                               o_msg_title          => l_msg_title,
                                                               o_msg                => l_msg,
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
    
    BEGIN
    
        IF NOT pk_supplies_core.cancel_supply_order(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_supplies         => i_supplies,
                                                    i_id_prof_cancel   => i_id_prof_cancel,
                                                    i_cancel_notes     => i_cancel_notes,
                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                    i_dt_cancel        => i_dt_cancel,
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
                                              'CANCEL_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_supply_order;

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

    FUNCTION set_supply_preparation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_supplies     IN table_number,
        i_id_patient   IN patient.id_patient%TYPE,
        i_unic_id      IN table_number,
        i_prepared_by  IN table_varchar,
        i_prep_notes   IN table_varchar,
        i_new_supplies IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.set_supply_preparation(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_supplies     => i_supplies,
                                                       i_id_patient   => i_id_patient,
                                                       i_unic_id      => i_unic_id,
                                                       i_prepared_by  => i_prepared_by,
                                                       i_prep_notes   => i_prep_notes,
                                                       i_new_supplies => i_new_supplies,
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
                                              'SET_SUPPLY_PREPARATION',
                                              o_error);
            RETURN FALSE;
    END set_supply_preparation;

    FUNCTION set_pharmacy_delivery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_supplies_core.set_pharmacy_delivery(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_pha_dispense => i_id_pha_dispense,
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
                                              'SET_PHARMACY_DELIVERY',
                                              o_error);
            RETURN FALSE;
    END set_pharmacy_delivery;

    PROCEDURE set_supply_workflow_hist
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE
    ) IS
    
    BEGIN
    
        pk_supplies_utils.set_supply_workflow_hist(i_id_supply_workflow => i_id_supply_workflow,
                                                   i_id_context         => i_id_context,
                                                   i_flg_context        => i_flg_context);
    END set_supply_workflow_hist;

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

    FUNCTION update_supply_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.update_supply_request(i_lang               => i_lang,
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
    
    BEGIN
    
        IF NOT pk_supplies_core.update_supply_workflow_status(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_supplies         => i_supplies,
                                                              i_id_prof_cancel   => i_id_prof_cancel,
                                                              i_cancel_notes     => i_cancel_notes,
                                                              i_id_cancel_reason => i_id_cancel_reason,
                                                              i_dt_cancel        => i_dt_cancel,
                                                              i_flg_status       => i_flg_status,
                                                              i_notes            => i_notes,
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
                                              'UPDATE_SUPPLY_WORKFLOW_STATUS',
                                              o_error);
            RETURN FALSE;
    END update_supply_workflow_status;

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
    
    BEGIN
    
        RETURN pk_supplies_core.get_attributes(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_id_supply_area     => i_id_supply_area,
                                               i_supply             => i_supply,
                                               i_supply_location    => i_supply_location,
                                               i_id_inst_dest       => i_id_inst_dest,
                                               i_id_supply_workflow => i_id_supply_workflow);
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_attributes;

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
    
    BEGIN
    
        IF NOT pk_supplies_core.get_id_supply_area(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_supply          => i_id_supply,
                                                   i_flg_type           => i_flg_type,
                                                   i_id_supply_workflow => i_id_supply_workflow,
                                                   o_id_supply_area     => o_id_supply_area,
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
                                              'GET_ID_SUPPLY_AREA',
                                              o_error);
            RETURN FALSE;
    END get_id_supply_area;

    FUNCTION get_id_workflow
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_workflow.id_supply_area%TYPE
    ) RETURN wf_workflow.id_workflow%TYPE IS
    
    BEGIN
    
        RETURN pk_supplies_core.get_id_workflow(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_id_supply_area => i_id_supply_area);
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_id_workflow;

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
            RETURN FALSE;
    END get_supply_for_selection;

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
            RETURN FALSE;
    END get_supply_listview;

    FUNCTION get_list_req_cons_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN episode.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN supply.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_list_req_cons_report(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_patient  => i_patient,
                                                         i_episode  => i_episode,
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
                                              'GET_LIST_REQ_CONS_REPORT',
                                              o_error);
            RETURN FALSE;
    END get_list_req_cons_report;

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
            RETURN FALSE;
    END get_supply_selection_list;

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
            RETURN FALSE;
    END get_sup_by_barcode;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN table_varchar,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_supplies_core.get_supplies_by_context(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_context    => i_id_context,
                                                        i_flg_context   => i_flg_context,
                                                        i_dep_clin_serv => i_dep_clin_serv,
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
            RETURN FALSE;
    END get_supplies_by_context;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context_m  IN table_varchar,
        i_id_context_p  IN table_varchar,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_supplies pk_types.cursor_type;
    
        l_supplies_record supplies_type;
        l_tbl_supplies    tbl_supplies_type := tbl_supplies_type();
    BEGIN
    
        g_error := 'CALLING PK_SUPPLIES_CORE.GET_SUPPLIES_BY_CONTEXT';
        IF NOT pk_supplies_core.get_supplies_by_context(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_context    => i_id_context_p,
                                                        i_flg_context   => pk_supplies_constant.g_context_procedure_req,
                                                        i_dep_clin_serv => i_dep_clin_serv,
                                                        o_supplies      => c_supplies,
                                                        o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCHING C_SUPPLIES FOR CONTEXT ''P''';
        LOOP
            FETCH c_supplies
                INTO l_supplies_record;
            EXIT WHEN c_supplies%NOTFOUND;
        
            l_tbl_supplies.extend();
            l_tbl_supplies(l_tbl_supplies.count) := l_supplies_record;
        END LOOP;
    
        g_error := 'CALLING PK_SUPPLIES_CORE.GET_SUPPLIES_BY_CONTEXT';
        IF NOT pk_supplies_core.get_supplies_by_context(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_context    => i_id_context_m,
                                                        i_flg_context   => pk_supplies_constant.g_context_medication,
                                                        i_dep_clin_serv => i_dep_clin_serv,
                                                        o_supplies      => c_supplies,
                                                        o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCHING C_SUPPLIES FOR CONTEXT ''M''';
        LOOP
            FETCH c_supplies
                INTO l_supplies_record;
            EXIT WHEN c_supplies%NOTFOUND;
        
            l_tbl_supplies.extend();
            l_tbl_supplies(l_tbl_supplies.count) := l_supplies_record;
        END LOOP;
    
        OPEN o_supplies FOR
            SELECT DISTINCT (t.id_supply_soft_inst),
                            t.id_supply,
                            t.id_parent_supply,
                            t.desc_supply,
                            t.desc_supply_attrib,
                            t.desc_cons_type,
                            t.flg_cons_type,
                            t.quantity,
                            t.dt_return,
                            t.id_supply_location,
                            t.desc_supply_location,
                            t.flg_type,
                            t.id_context,
                            t.rank,
                            pk_alert_constant.g_no flg_consumed
              FROM TABLE(l_tbl_supplies) t
             ORDER BY t.desc_supply;
    
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
            RETURN FALSE;
    END get_supplies_by_context;

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
            RETURN FALSE;
    END get_supply_patients;

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
            RETURN FALSE;
    END get_supply_detail;

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
            RETURN FALSE;
    END get_supply_wf_grid_detail;

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
        i_id_episode         IN supply_workflow.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_supplies_core.get_supply_wf_status_string(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_flg_status         => i_flg_status,
                                                            i_id_sys_shortcut    => i_id_sys_shortcut,
                                                            i_id_workflow        => i_id_workflow,
                                                            i_id_supply_area     => i_id_supply_area,
                                                            i_id_category        => i_id_category,
                                                            i_dt_returned        => i_dt_returned,
                                                            i_dt_request         => i_dt_request,
                                                            i_dt_supply_workflow => i_dt_supply_workflow,
                                                            i_id_episode         => i_id_episode);
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_supply_wf_status_string;

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
            RETURN FALSE;
    END get_type_consumption_list;

    FUNCTION get_epis_max_supply_delay
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_supplies_core.get_epis_max_supply_delay(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_patient     => i_id_patient,
                                                          i_phar_main_grid => i_phar_main_grid);
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END get_epis_max_supply_delay;

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
            RETURN FALSE;
    END get_supplies_consumed_counted;

    FUNCTION get_supplies_for_modal_window
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_supplies IN pk_supplies_core.tbl_supplies_by_context
    ) RETURN VARCHAR2 IS
    
        l_id_supply     VARCHAR2(4000 CHAR) := NULL;
        l_id_supply_set VARCHAR2(4000 CHAR) := NULL;
        l_quantity      VARCHAR2(4000 CHAR) := NULL;
        l_dt_return     VARCHAR2(4000 CHAR) := NULL;
        l_supply_loc    VARCHAR2(4000 CHAR) := NULL;
    
        l_ret VARCHAR2(4000 CHAR);
    
    BEGIN
    
        IF i_supplies.exists(1)
        THEN
            FOR i IN i_supplies.first .. i_supplies.last
            LOOP
                l_id_supply := l_id_supply || CASE
                                   WHEN i > 1 THEN
                                    '|'
                               END || i_supplies(i).id_supply;
            
                l_id_supply_set := l_id_supply_set || CASE
                                       WHEN i > 1 THEN
                                        '|'
                                   END || i_supplies(i).id_parent_supply;
            
                l_quantity := l_quantity || CASE
                                  WHEN i > 1 THEN
                                   '|'
                              END || i_supplies(i).quantity;
            
                l_dt_return := l_dt_return || CASE
                                   WHEN i > 1 THEN
                                    '|'
                               END || i_supplies(i).dt_return;
            
                l_supply_loc := l_supply_loc || CASE
                                    WHEN i > 1 THEN
                                     '|'
                                END || i_supplies(i).id_supply_location;
            END LOOP;
        END IF;
    
        l_ret := l_id_supply || ',' || l_id_supply_set || ',' || l_quantity || ',' || l_dt_return || ',' ||
                 l_supply_loc;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supplies_for_modal_window;

    FUNCTION get_supplies_procedure_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies      IN VARCHAR2,
        o_supplies_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*#################################################################
        The input parameter (i_supplies) is a string with concatenated data,
        and will have the following structure:
        
        [ID_SUPPLY_1|ID_SUPPLY_2|...,
         ID_PARENT_SUPPLY_1|ID_PARENT_SUPPLY_2|...,
         QUANTITY_1|QUANTITY_2|...,
         DT_RETURN_1|DT_RETURN_2|...,
         ID_SUPPLY_LOC_1|ID_SUPPLY_LOC_2|...]
        ###################################################################*/
    
        l_tbl_aux table_varchar := table_varchar();
    
        l_tbl_supply           table_number := table_number();
        l_tbl_set              table_number := table_number();
        l_tbl_quantity         table_number := table_number();
        l_tbl_dt_return        table_varchar := table_varchar();
        l_tbl_supply_loc       table_number := table_number();
        l_tbl_cons_type        table_varchar := table_varchar();
        l_tbl_supply_soft_inst table_number := table_number();
        l_tbl_reusable         table_varchar := table_varchar();
    BEGIN
    
        IF i_supplies IS NOT NULL
        THEN
            l_tbl_aux := pk_string_utils.str_split(i_list => i_supplies, i_delim => ',');
        
            l_tbl_supply     := pk_utils.str_split_n(i_list => l_tbl_aux(1), i_delim => '|');
            l_tbl_set        := pk_utils.str_split_n(i_list => l_tbl_aux(2), i_delim => '|');
            l_tbl_quantity   := pk_utils.str_split_n(i_list => l_tbl_aux(3), i_delim => '|');
            l_tbl_dt_return  := pk_string_utils.str_split(i_list => l_tbl_aux(4), i_delim => '|');
            l_tbl_supply_loc := pk_utils.str_split_n(i_list => l_tbl_aux(5), i_delim => '|');
        
            FOR i IN l_tbl_supply.first .. l_tbl_supply.last
            LOOP
                IF NOT l_tbl_set.exists(i)
                THEN
                    l_tbl_set.extend();
                    l_tbl_set(l_tbl_set.count) := NULL;
                END IF;
                IF NOT l_tbl_quantity.exists(i)
                THEN
                    l_tbl_quantity.extend();
                    l_tbl_quantity(l_tbl_quantity.count) := NULL;
                END IF;
                IF NOT l_tbl_dt_return.exists(i)
                THEN
                    l_tbl_dt_return := table_varchar();
                    l_tbl_dt_return.extend();
                    l_tbl_dt_return(l_tbl_dt_return.count) := NULL;
                END IF;
                IF NOT l_tbl_supply_loc.exists(i)
                THEN
                    l_tbl_supply_loc.extend();
                    l_tbl_supply_loc(l_tbl_supply_loc.count) := NULL;
                END IF;
            
                BEGIN
                    l_tbl_cons_type.extend();
                    l_tbl_supply_soft_inst.extend();
                    l_tbl_reusable.extend();
                
                    SELECT ssi.flg_cons_type, ssi.id_supply_soft_inst, ssi.flg_reusable
                      INTO l_tbl_cons_type(l_tbl_cons_type.count),
                           l_tbl_supply_soft_inst(l_tbl_supply_soft_inst.count),
                           l_tbl_reusable(l_tbl_reusable.count)
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply = coalesce(l_tbl_set(i), l_tbl_supply(i))
                       AND ssi.id_software = i_prof.software
                       AND ssi.id_institution = i_prof.institution;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_tbl_cons_type(l_tbl_cons_type.count) := NULL;
                        l_tbl_supply_soft_inst(l_tbl_supply_soft_inst.count) := NULL;
                        l_tbl_reusable(l_tbl_reusable.count) := NULL;
                END;
            END LOOP;
        
            OPEN o_supplies_info FOR
                SELECT t_supply.id_supply,
                       pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                       t_set.id_set,
                       (SELECT pk_translation.get_translation(i_lang, s_set.code_supply)
                          FROM dual) set_desc,
                       t_quantity.quantity,
                       t_return.dt_return,
                       t_supply_loc.id_supply_loc,
                       (SELECT pk_translation.get_translation(i_lang, sl.code_supply_location)
                          FROM dual) supply_loc_desc,
                       t_cons_type.flg_cons_type flg_consumption_type,
                       (SELECT pk_sysdomain.get_domain(i_code_dom => 'SUPPLY_SOFT_INST.FLG_CONS_TYPE',
                                                       i_val      => t_cons_type.flg_cons_type,
                                                       i_lang     => i_lang)
                          FROM dual) desc_consumption_type,
                       t_supply_soft_inst.id_supply_soft_inst,
                       t_reusable.flg_reusable,
                       CASE t_reusable.flg_reusable
                           WHEN pk_alert_constant.g_no THEN
                            (SELECT pk_message.get_message(i_lang, 'SUPPLIES_T095')
                               FROM dual)
                           WHEN pk_alert_constant.g_yes THEN
                            (SELECT pk_message.get_message(i_lang, 'SUPPLIES_T096')
                               FROM dual)
                       END desc_supply_attrib
                  FROM (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value id_supply, rownum rn
                          FROM TABLE(l_tbl_supply) t) t_supply
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS id_set, rownum rn
                          FROM TABLE(l_tbl_set) t) t_set
                    ON t_set.rn = t_supply.rn
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS quantity, rownum rn
                          FROM TABLE(l_tbl_quantity) t) t_quantity
                    ON t_quantity.rn = t_supply.rn
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS dt_return, rownum rn
                          FROM TABLE(l_tbl_dt_return) t) t_return
                    ON t_return.rn = t_supply.rn
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS id_supply_loc, rownum rn
                          FROM TABLE(l_tbl_supply_loc) t) t_supply_loc
                    ON t_supply_loc.rn = t_supply.rn
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS flg_cons_type, rownum rn
                          FROM TABLE(l_tbl_cons_type) t) t_cons_type
                    ON t_cons_type.rn = t_supply.rn
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS id_supply_soft_inst, rownum rn
                          FROM TABLE(l_tbl_supply_soft_inst) t) t_supply_soft_inst
                    ON t_supply_soft_inst.rn = t_supply.rn
                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                         t.column_value AS flg_reusable, rownum rn
                          FROM TABLE(l_tbl_reusable) t) t_reusable
                    ON t_reusable.rn = t_supply.rn
                  JOIN supply s
                    ON s.id_supply = t_supply.id_supply
                  LEFT JOIN supply s_set
                    ON s_set.id_supply = t_set.id_set
                  LEFT JOIN supply_location sl
                    ON sl.id_supply_location = t_supply_loc.id_supply_loc;
        ELSE
            pk_types.open_my_cursor(o_supplies_info);
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

    FUNCTION check_supply_wf_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_workflow.id_supply_area%TYPE,
        i_flg_status     IN supply_workflow.flg_status%TYPE,
        i_quantity       IN supply_workflow.quantity%TYPE,
        i_total_quantity IN supply_workflow.total_quantity%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_supplies_core.check_supply_wf_cancel(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_supply_area => i_id_supply_area,
                                                       i_flg_status     => i_flg_status,
                                                       i_quantity       => i_quantity,
                                                       i_total_quantity => i_total_quantity);
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE g_other_exception;
    END check_supply_wf_cancel;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_supplies_api_db;
/
