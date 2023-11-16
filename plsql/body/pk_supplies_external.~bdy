/*-- Last Change Revision: $Rev: 2051359 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-28 09:41:24 +0000 (seg, 28 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_external IS

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

    FUNCTION get_supply_by_context
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_context IN supply_request.id_context%TYPE,
        o_supply     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_UTILS.GET_SUPPLY_BY_CONTEXT';
        IF NOT pk_supplies_utils.get_supply_by_context(i_lang       => i_lang,
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

    FUNCTION get_supply_priority_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_supply_priority_task
        PIPELINED IS
    
        l_param                table_varchar := table_varchar();
        l_supply_priority_task t_supply_priority_task;
        l_limit                NUMBER := 1000;
    
        CURSOR c_get_priority_task IS
            SELECT dt_supply_workflow, flg_status, id_status, flg_display_type
              FROM (SELECT dt_supply_workflow,
                           flg_status,
                           id_status,
                           flg_display_type,
                           rank() over(ORDER BY num_rank, dt_supply_workflow) rank_number,
                           row_number() over(ORDER BY num_rank, dt_supply_workflow) row_number
                      FROM (SELECT sw.dt_supply_workflow,
                                   sw.flg_status,
                                   sws.id_status,
                                   sws.flg_display_type,
                                   pk_workflow.get_status_rank(i_lang,
                                                               i_prof,
                                                               pk_supplies_constant.g_id_workflow_sr,
                                                               sws.id_status,
                                                               pk_prof_utils.get_id_category(i_lang, i_prof),
                                                               NULL,
                                                               NULL,
                                                               l_param) num_rank
                              FROM supply_workflow sw
                             INNER JOIN supplies_wf_status sws
                                ON sws.flg_status = sw.flg_status
                             WHERE sw.id_episode = i_id_episode
                               AND sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                               AND sws.id_category = pk_prof_utils.get_id_category(i_lang, i_prof)
                               AND sw.flg_status IN (pk_supplies_constant.g_sww_request_local,
                                                     pk_supplies_constant.g_sww_request_central,
                                                     pk_supplies_constant.g_sww_prepared_pharmacist,
                                                     pk_supplies_constant.g_sww_in_transit,
                                                     pk_supplies_constant.g_sww_transport_concluded,
                                                     pk_supplies_constant.g_sww_prep_sup_for_surg)))
            
             WHERE rank_number = 1
               AND row_number = 1;
    
    BEGIN
    
        g_error := 'GET THE OLDEST SUPPLY REQUISITION FOR ID_EPISODE ' || i_id_episode;
        OPEN c_get_priority_task;
        LOOP
            FETCH c_get_priority_task BULK COLLECT
                INTO l_supply_priority_task LIMIT l_limit;
        
            FOR i IN 1 .. l_supply_priority_task.count
            LOOP
                PIPE ROW(l_supply_priority_task(i));
            END LOOP;
            EXIT WHEN c_get_priority_task%NOTFOUND;
        END LOOP;
    
        CLOSE c_get_priority_task;
    
        RETURN;
    END get_supply_priority_task;

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

    FUNCTION check_max_delay_sup_pharmacist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_supply_workflow IN supply_workflow.dt_supply_workflow%TYPE,
        i_phar_main_grid     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_surgery_date        schedule_sr.dt_target_tstz%TYPE;
        l_surgery_with_margin schedule_sr.dt_target_tstz%TYPE;
        l_date                schedule_sr.dt_target_tstz%TYPE;
        l_sr_time_margin      NUMBER;
        l_compare_date        VARCHAR2(1 CHAR);
        l_error               t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error          := 'GET TIME LIMIT FOR PHARMACIST GRID';
        l_sr_time_margin := to_number(pk_sysconfig.get_config('SR_SUPPLIES_PH_GRID_TIME', i_prof));
        l_sr_time_margin := -l_sr_time_margin;
    
        g_error := 'GET SURGERY DATE FOR ID_EPISODE ' || i_id_episode;
        BEGIN
            SELECT sr.dt_target_tstz
              INTO l_surgery_date
              FROM schedule_sr sr
             WHERE sr.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
            
                l_surgery_date := NULL;
        END;
    
        IF l_surgery_date IS NOT NULL
        THEN
            g_error := 'ADD SURGERY DATE WITH VALUE DEFINED IN SR_SUPPLIES_PH_GRID_TIME SYSCONFIG';
        
            l_surgery_with_margin := pk_date_utils.add_to_ltstz(l_surgery_date, l_sr_time_margin, 'HOUR');
        
            g_error := 'COMPARE DATE WITH TIMESTAMP';
        
            --check if the surgery date with margin (defined in sr_supplies_ph_grid_time sysconfig) is more recent or not
            -- with current timestamp
            l_compare_date := pk_date_utils.compare_dates_tsz(i_prof, l_surgery_with_margin, g_sysdate_tstz);
        
            IF l_compare_date = pk_sr_planning.g_flg_time_g
            THEN
                IF i_phar_main_grid = pk_alert_constant.g_yes
                THEN
                    -- if if the surgery date with margin is greatest than current timestamp so this requisition should not appear
                    --pharmacist grid
                    l_date := NULL;
                ELSE
                    l_date := l_surgery_with_margin;
                END IF;
            ELSE
                g_error := 'COMPARE DATE WITH VALUE DEFINED IN SR_SUPPLIES_PH_GRID_TIME SYSCONFIG AND REQUISITION DATE ';
            
                l_compare_date := pk_date_utils.compare_dates_tsz(i_prof, l_surgery_with_margin, i_dt_supply_workflow);
            
                -- if if the surgery date with margin is greatest than requisition date so is the surgery date with margin should
                -- be send otherwise is the requisition date
                IF l_compare_date != pk_sr_planning.g_flg_time_g
                THEN
                    l_date := i_dt_supply_workflow;
                ELSE
                    l_date := l_surgery_with_margin;
                END IF;
            
            END IF;
        
        ELSE
            l_date := l_surgery_date;
        END IF;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_MAX_DELAY_SUP_PHARMACIST',
                                              l_error);
        
            RETURN NULL;
    END check_max_delay_sup_pharmacist;

    /********************************************************************************************
    * get status info for surgical supplies tasks
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID
    * @param i_id_episode       ORIS episode ID
    * @param i_date             Request date
    * @param i_phar_main_grid   (Y) - function called by pharmacist main grids; (N) otherwise 
    * @param io_icon_info        WF_STATUS_CONFIG data
    * @param io_icon_type       Icon type
    *
    * @param o_status_info      WF_STATUS_CONFIG data
    * @param o_surgery_date     Surgery date
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Filipe Silva
    * @since                    2010/10/29
    ********************************************************************************************/

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
    
        l_surgery_date       schedule_sr.dt_interv_preview_tstz%TYPE;
        l_icon_disp_type     supplies_wf_status.flg_display_type%TYPE;
        l_check_surgery_date VARCHAR2(1 CHAR);
        l_id_workflow        wf_status_config.id_workflow%TYPE;
        l_status             wf_status_config.id_status%TYPE;
        l_param              table_varchar;
        l_id_category        category.id_category%TYPE;
    
    BEGIN
    
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
        --if the id_workflow belongs to surgical supplies workflow and the icon is date type
        IF io_icon_type IN (pk_alert_constant.g_display_type_date_icon, pk_alert_constant.g_display_type_date)
        THEN
        
            IF l_id_category != pk_supplies_constant.g_pharmacist
            THEN
                --get the surgery date with margin defined in sys_config 
                l_surgery_date := pk_sr_planning.get_surg_dt_margin(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_episode           => i_id_episode,
                                                                    i_dt_req_tstz       => i_date,
                                                                    o_surg_date_is_null => l_check_surgery_date);
            
                --if there aren't surgery date, the icon type is I
                IF l_check_surgery_date = pk_alert_constant.g_yes
                THEN
                    l_icon_disp_type := pk_alert_constant.g_display_type_icon;
                END IF;
            
            ELSIF l_id_category = pk_supplies_constant.g_pharmacist
            THEN
                l_surgery_date := check_max_delay_sup_pharmacist(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_episode         => i_id_episode,
                                                                 i_dt_supply_workflow => i_date,
                                                                 i_phar_main_grid     => i_phar_main_grid);
            
                IF l_surgery_date IS NULL
                THEN
                    l_icon_disp_type     := pk_alert_constant.g_display_type_icon;
                    l_check_surgery_date := pk_alert_constant.g_yes;
                ELSE
                    l_check_surgery_date := pk_alert_constant.g_no;
                END IF;
            
            END IF;
        END IF;
    
        --Check if there are function defined in wf_status_config
        IF io_icon_info.function IS NOT NULL
        THEN
            l_id_workflow := io_icon_info.id_workflow;
            l_status      := io_icon_info.id_status;
        
            --if the id_workflow belongs to surgical supplies workflow so the i_param is defined with the
            -- flag check surgery_date
            IF io_icon_info.id_workflow = pk_supplies_constant.g_id_workflow_sr
            THEN
                l_param := table_varchar(l_check_surgery_date);
            END IF;
        
            IF NOT pk_workflow.get_status_info(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_workflow         => l_id_workflow,
                                               i_id_status           => l_status,
                                               i_id_category         => l_id_category,
                                               i_id_profile_template => pk_prof_utils.get_prof_profile_template(i_prof),
                                               i_id_functionality    => NULL,
                                               i_param               => l_param,
                                               o_status_info         => io_icon_info,
                                               o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        --if the professional is pharmacist and the icon is for the pharmacist main grid is necessary
        --to force the background color because theses grids don't have workflow cellrender
        IF l_id_category = pk_supplies_constant.g_pharmacist
           AND i_phar_main_grid = pk_alert_constant.g_yes
        THEN
            io_icon_info.color := pk_alert_constant.g_color_red;
        END IF;
    
        -- Force the icon color for Request central stock status
        IF l_status = pk_supplies_constant.g_wfs_req_local_stock
           AND io_icon_info.icon != pk_supplies_constant.g_icon_waiting_req
        THEN
            o_icon_color := pk_alert_constant.g_color_icon_light_grey;
        END IF;
    
        o_surgery_date := l_surgery_date;
        io_icon_type   := nvl(l_icon_disp_type, io_icon_type);
    
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

    FUNCTION get_surg_supplies_reg
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_material_req IN grid_task.material_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_surgery_date          schedule_sr.dt_interv_preview_tstz%TYPE;
        l_material_req          grid_task.material_req%TYPE;
        l_id_category           category.id_category%TYPE;
        l_dt_supply_workflow    supply_workflow.dt_supply_workflow%TYPE;
        l_icon_info             t_rec_wf_status_info;
        l_id_status             supplies_wf_status.id_status%TYPE;
        l_icon_disp_type        supplies_wf_status.flg_display_type%TYPE;
        l_icon_color            VARCHAR2(8 CHAR);
        l_icon_background_color VARCHAR2(1 CHAR) := '';
        l_error                 t_error_out;
    
    BEGIN
    
        l_material_req := i_material_req;
    
        IF l_material_req IS NOT NULL
        THEN
            g_error := 'GET ID CATEGORY';
        
            l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'get supply priority task for id_episode ' || i_id_episode;
            BEGIN
                SELECT dt_supply_workflow, id_status, flg_display_type
                  INTO l_dt_supply_workflow, l_id_status, l_icon_disp_type
                  FROM TABLE(pk_supplies_external.get_supply_priority_task(i_lang, i_prof, i_id_episode));
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_supply_workflow := NULL;
                    l_id_status          := NULL;
                    l_icon_disp_type     := NULL;
            END;
            --get information for supply status  
            IF NOT pk_sup_status.get_status_config(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_workflow        => pk_supplies_constant.g_id_workflow_sr,
                                                   i_id_status          => l_id_status,
                                                   i_id_category        => l_id_category,
                                                   o_status_config_info => l_icon_info,
                                                   o_error              => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            --Surgical supplies logic
            IF NOT get_sr_status_info(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_id_episode   => i_id_episode,
                                      i_date         => l_dt_supply_workflow,
                                      io_icon_info   => l_icon_info,
                                      io_icon_type   => l_icon_disp_type,
                                      o_surgery_date => l_surgery_date,
                                      o_icon_color   => l_icon_color,
                                      o_error        => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            --ICON background color replace
        
            IF l_icon_disp_type IN (pk_alert_constant.g_display_type_date_icon, pk_alert_constant.g_display_type_date)
            THEN
                -- flash calcule the background color 
                l_material_req := REPLACE(l_material_req, '@2', l_icon_background_color);
            ELSE
                l_material_req := REPLACE(l_material_req, '@2', l_icon_info.color);
            END IF;
        
            -- ICON display type replace
            l_material_req := REPLACE(l_material_req, '@1', l_icon_disp_type);
            -- ICON replace
            l_material_req := REPLACE(l_material_req, '$1', l_icon_info.icon);
        
            -- DATE replace
            l_material_req := REPLACE(l_material_req, '#', pk_date_utils.date_send_tsz(i_lang, l_surgery_date, i_prof));
        
            --Icon color replace
            l_material_req := REPLACE(l_material_req, '$2', l_icon_color);
            -- Current date replace
            l_material_req := REPLACE(l_material_req,
                                      '&',
                                      pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof));
        END IF;
    
        RETURN l_material_req;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURG_SUPPLIES_MAX_DELAY',
                                              l_error);
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
    
        l_sup_int_wf         sys_config.value%TYPE;
        l_rows               table_varchar;
        l_rows_update        table_varchar;
        l_rows_insert        table_varchar;
        l_supply_wf_tab      ts_supply_workflow.supply_workflow_ntt;
        l_id_area_prev       supply_area.id_supply_area%TYPE;
        l_id_supply_request  supply_request.id_supply_request%TYPE;
        l_supply_qty         supply_workflow.quantity%TYPE;
        l_supply_wf_row      supply_workflow%ROWTYPE;
        l_id_supply_workflow table_number;
    
    BEGIN
    
        g_sysdate_tstz       := current_timestamp;
        o_id_supply_request  := table_number();
        o_id_supply_workflow := table_table_number();
        l_id_supply_workflow := table_number();
    
        -- config
        g_error      := 'GET CONFIG SUPPLIES_INTERFACE_WORKFLOW';
        l_sup_int_wf := pk_sysconfig.get_config('SUPPLIES_INTERFACE_WORKFLOW', i_prof);
    
        -- func
        -- get supply_workflow data
        g_error := 'SELECT * BULK COLLECT';
        SELECT /*+opt_estimate(table t rows=1)*/
         sw.*
          BULK COLLECT
          INTO l_supply_wf_tab
          FROM supply_workflow sw
          JOIN TABLE(CAST(i_supply_workflow AS table_number)) t
            ON (t.column_value = sw.id_supply_workflow)
           AND sw.id_supply_request IS NULL
           AND sw.flg_status = pk_supplies_constant.g_sww_predefined;
    
        -- check if all supply_workflows have no supply_requests related
        IF l_supply_wf_tab.count != i_supply_workflow.count
        THEN
            g_error := 'There is at least one supply_workflow related to one request or not in a predefined state';
            RAISE g_other_exception;
        END IF;
    
        l_rows        := table_varchar();
        l_rows_update := table_varchar();
        l_rows_insert := table_varchar();
    
        g_error := 'FOR i IN 1 .. ' || l_supply_wf_tab.count;
        <<supply_wf_data>>
        FOR i IN 1 .. l_supply_wf_tab.count
        LOOP
        
            l_supply_wf_row := l_supply_wf_tab(i);
        
            -- creates a supply_request record for each supply_area identifier (this code is ready for the merging of supplies and surgical)
            IF l_id_area_prev IS NULL
               OR l_id_area_prev != l_supply_wf_row.id_supply_area
            THEN
            
                g_error := 'Call create_supply_rqt';
                IF NOT pk_supplies_utils.create_supply_rqt(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_supply_area    => l_supply_wf_row.id_supply_area,
                                                           i_id_episode        => i_id_episode,
                                                           i_flg_reason_req    => NULL,
                                                           i_id_context        => l_supply_wf_row.id_context,
                                                           i_flg_context       => l_supply_wf_row.flg_context,
                                                           i_supply_flg_status => pk_supplies_constant.g_srt_requested,
                                                           i_supply_dt_request => g_sysdate_tstz,
                                                           o_id_supply_request => l_id_supply_request,
                                                           o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            -- sets supply_workflow data (divide by quantity - this will be reformulated in the near future)
            l_supply_qty         := nvl(l_supply_wf_row.quantity, 1);
            l_id_supply_workflow := table_number();
        
            FOR j IN 1 .. l_supply_qty
            LOOP
            
                g_error                            := 'sets supply_workflow data ';
                l_supply_wf_row.quantity           := 1; -- (divide by quantity - this will be reformulated in the near future)
                l_supply_wf_row.total_quantity     := 1;
                l_supply_wf_row.id_episode         := i_id_episode;
                l_supply_wf_row.flg_outdated       := pk_supplies_constant.g_sww_active;
                l_supply_wf_row.id_supply_request  := l_id_supply_request;
                l_supply_wf_row.id_professional    := i_prof.id;
                l_supply_wf_row.dt_supply_workflow := g_sysdate_tstz;
            
                -- gets new status of supply_workflow
                g_error                    := 'Call get_ini_status_supply_wf';
                l_supply_wf_row.flg_status := pk_supplies_utils.get_ini_status_supply_wf(i_lang               => i_lang,
                                                                                         i_prof               => i_prof,
                                                                                         i_id_supply_area     => l_supply_wf_row.id_supply_area,
                                                                                         i_id_supply_location => l_supply_wf_row.id_supply_location,
                                                                                         i_id_supply_set      => l_supply_wf_row.id_supply_set,
                                                                                         i_id_supply          => l_supply_wf_row.id_supply,
                                                                                         i_sup_interface      => l_sup_int_wf);
            
                IF j = 1
                THEN
                    -- update supply_workflow data (preserve the first record)
                    g_error := 'Call set_supply_workflow_hist';
                    pk_supplies_utils.set_supply_workflow_hist(i_id_supply_workflow => l_supply_wf_row.id_supply_workflow,
                                                               i_id_context         => NULL,
                                                               i_flg_context        => NULL);
                
                    l_rows  := table_varchar();
                    g_error := 'Call ts_supply_workflow.upd';
                    ts_supply_workflow.upd(id_supply_workflow_in => l_supply_wf_row.id_supply_workflow,
                                           quantity_in           => l_supply_wf_row.quantity,
                                           total_quantity_in     => l_supply_wf_row.total_quantity,
                                           id_episode_in         => l_supply_wf_row.id_episode,
                                           flg_outdated_in       => l_supply_wf_row.flg_outdated,
                                           id_supply_request_in  => l_supply_wf_row.id_supply_request,
                                           flg_status_in         => l_supply_wf_row.flg_status,
                                           id_professional_in    => l_supply_wf_row.id_professional,
                                           dt_supply_workflow_in => l_supply_wf_row.dt_supply_workflow,
                                           handle_error_in       => TRUE,
                                           rows_out              => l_rows);
                
                    l_rows_update := l_rows_update MULTISET UNION l_rows;
                ELSE
                    -- insert supply_workflow data (insert all records except the first)
                    l_rows                             := table_varchar();
                    l_supply_wf_row.id_supply_workflow := ts_supply_workflow.next_key;
                
                    g_error := 'Call ts_supply_workflow.ins';
                    ts_supply_workflow.ins(rec_in          => l_supply_wf_row,
                                           gen_pky_in      => FALSE,
                                           handle_error_in => TRUE,
                                           rows_out        => l_rows);
                
                    l_rows_insert := l_rows_insert MULTISET UNION l_rows;
                
                END IF;
            
                -- integration with inter-alert (this is the same as requesting a supply in supplies area)
                IF l_supply_wf_row.flg_context != pk_supplies_constant.g_context_procedure_req
                THEN
                    g_error := 'Call pk_ia_event_common.supply_workflow_new';
                    pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => l_supply_wf_row.id_supply_workflow);
                END IF;
            
                -- update output vars with supply_workflow IDs created
                g_error := 'o_id_supply_workflow';
                l_id_supply_workflow.extend;
                l_id_supply_workflow(l_id_supply_workflow.last) := l_supply_wf_row.id_supply_workflow;
            
            END LOOP supply_qty;
        
            -- update output vars with request IDs created
            g_error := 'o_id_supply_request';
            o_id_supply_request.extend;
            o_id_supply_workflow.extend;
        
            o_id_supply_request(o_id_supply_request.last) := l_id_supply_request;
            o_id_supply_workflow(o_id_supply_workflow.last) := l_id_supply_workflow;
        
            -- update this var
            l_id_area_prev := l_supply_wf_row.id_supply_area;
        
        END LOOP supply_wf_data;
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_update,
                                      o_error      => o_error);
    
        g_error := 'Call t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows_insert,
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
    
        l_empty_array_varchar table_varchar := table_varchar();
        l_empty_array_number  table_number := table_number();
        l_flg_context         table_varchar := table_varchar();
    
    BEGIN
    
        IF i_supply_workflow IS NOT NULL
           AND i_supply_workflow.count > 0
        THEN
            g_error := 'INITIALIZING COLLECTIONS';
        
            l_empty_array_varchar.extend(i_supply_workflow.count);
            l_empty_array_number.extend(i_supply_workflow.count);
            l_flg_context.extend(i_supply_workflow.count);
        
            FOR i IN 1 .. i_supply_workflow.count
            LOOP
                l_flg_context(i) := NULL;
                IF i_id_context IS NOT NULL
                   AND i_id_context.count > 0
                THEN
                    IF i_id_context(i) IS NOT NULL
                    THEN
                        l_flg_context(i) := pk_supplies_constant.g_context_surgery;
                    END IF;
                END IF;
            END LOOP;
        
        END IF;
    
        g_error := 'CALL PK_SUPPLIES_API_DB.UPDATE_SUPPLY_WORKFLOW';
    
        IF NOT pk_supplies_api_db.update_supply_workflow(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_episode      => i_id_episode,
                                                         i_supply_workflow => i_supply_workflow,
                                                         i_supply          => i_supply,
                                                         i_supply_set      => l_empty_array_number,
                                                         i_supply_qty      => i_supply_qty,
                                                         i_supply_loc      => i_supply_loc,
                                                         i_dt_request      => l_empty_array_varchar,
                                                         i_dt_return       => i_dt_return,
                                                         i_id_req_reason   => i_id_req_reason,
                                                         i_id_context      => i_id_context,
                                                         i_flg_context     => l_flg_context,
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
    
        l_supply_wf_row supply_workflow%ROWTYPE;
    
        l_supplies_t107 CONSTANT sys_message.code_message%TYPE := 'SUPPLIES_T107'; -- Order for:
        l_supplies_t135 CONSTANT sys_message.code_message%TYPE := 'SUPPLIES_T135'; -- Ordered to:
        l_supplies_t136 CONSTANT sys_message.code_message%TYPE := 'SUPPLIES_T136'; -- Expected return date:
        l_supplies_t105 CONSTANT sys_message.code_message%TYPE := 'SUPPLIES_T105'; -- Quantity:
        l_supplies_t106 CONSTANT sys_message.code_message%TYPE := 'SUPPLIES_T106'; -- Reason:
    
        l_sm_desc pk_types.vc2_hash_table;
    
    BEGIN
    
        -- func
        g_error := 'SELECT';
        SELECT *
          INTO l_supply_wf_row
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_task_request;
    
        -- get messages (all at a time)
        g_error := 'Call pk_message.get_message_array ';
        IF NOT pk_message.get_message_array(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_code_msg_arr        => table_varchar(l_supplies_t107,
                                                                                   l_supplies_t135,
                                                                                   l_supplies_t136,
                                                                                   l_supplies_t105,
                                                                                   l_supplies_t106),
                                            io_desc_msg_hashtable => l_sm_desc)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- Ordered to:
        IF l_supply_wf_row.id_supply_location IS NOT NULL
        THEN
            o_task_instr := o_task_instr || l_sm_desc(l_supplies_t135) || pk_supplies_constant.g_str_sep_space ||
                            pk_translation.get_translation(i_lang      => i_lang,
                                                           i_code_mess => 'SUPPLY_LOCATION.CODE_SUPPLY_LOCATION.' ||
                                                                          l_supply_wf_row.id_supply_location) ||
                            pk_supplies_constant.g_str_separator;
        END IF;
    
        -- Quantity:
        IF l_supply_wf_row.quantity IS NOT NULL
        THEN
            o_task_instr := o_task_instr || l_sm_desc(l_supplies_t105) || pk_supplies_constant.g_str_sep_space ||
                            l_supply_wf_row.quantity || pk_supplies_constant.g_str_separator;
        END IF;
    
        -- Reason:
        IF l_supply_wf_row.id_req_reason IS NOT NULL
        THEN
            o_task_instr := o_task_instr || l_sm_desc(l_supplies_t106) || pk_supplies_constant.g_str_sep_space ||
                            pk_translation.get_translation(i_lang,
                                                           'SUPPLY_REASON.CODE_SUPPLY_REASON.' ||
                                                           l_supply_wf_row.id_req_reason) ||
                            pk_supplies_constant.g_str_separator;
        END IF;
    
        -- Order for:
        IF l_supply_wf_row.dt_request IS NOT NULL
        THEN
            o_task_instr := o_task_instr || l_sm_desc(l_supplies_t107) || pk_supplies_constant.g_str_sep_space ||
                            pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_supply_wf_row.dt_request, i_prof) ||
                            pk_supplies_constant.g_str_separator;
        END IF;
    
        -- Expected return date:
        IF l_supply_wf_row.dt_returned IS NOT NULL
        THEN
            o_task_instr := o_task_instr || l_sm_desc(l_supplies_t136) || pk_supplies_constant.g_str_sep_space ||
                            pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_supply_wf_row.dt_request, i_prof) ||
                            pk_supplies_constant.g_str_separator;
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
    
        g_error := 'CALL PK_SUPPLIES_API_DB.SET_CANCEL_SUPPLY';
    
        IF NOT pk_supplies_api_db.cancel_supply_order(i_lang             => i_lang,
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
                   nvl(ssc.qty_added, 0) qty_added,
                   aa_code_messages('SR_SUPPLIES_M044') qty_final_label,
                   ssc.qty_final_count qty_final,
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
    
        l_empty_array_varchar table_varchar := table_varchar();
        l_id_supply_request   supply_request.id_supply_request%TYPE;
        l_flg_reusable        table_varchar := table_varchar();
        l_flg_editable        table_varchar := table_varchar();
        l_flg_preparing       table_varchar := table_varchar();
        l_flg_countable       table_varchar := table_varchar();
    
    BEGIN
        g_error := 'GET TIMESTAMP';
    
        -- insert the supplies associated with surgical procedure               
    
        IF i_supply IS NOT NULL
        THEN
            FOR i IN 1 .. i_supply.count
            LOOP
            
                IF i_supply(i) IS NOT NULL
                THEN
                    l_empty_array_varchar.extend(i_supply(i).count);
                
                    g_error := 'CALL GET_SUPPLY_ATTRIBUTS';
                
                    IF NOT pk_supplies_core.get_supply_attributs(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_supply_soft_inst => i_supply_soft_inst(i),
                                                                 o_flg_reusable     => l_flg_reusable,
                                                                 o_flg_editable     => l_flg_editable,
                                                                 o_flg_preparing    => l_flg_preparing,
                                                                 o_flg_countable    => l_flg_countable,
                                                                 o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    g_error := 'CALL PK_SUPPLIES_API_DB.CREATE_REQUEST';
                
                    IF NOT pk_supplies_api_db.create_request(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_supply_area    => pk_supplies_constant.g_area_surgical_supplies,
                                                        i_id_episode        => i_id_episode,
                                                        i_supply            => i_supply(i),
                                                        i_supply_set        => i_supply_set(i),
                                                        i_supply_qty        => i_supply_qty(i),
                                                        i_supply_loc        => CASE
                                                                                   WHEN i_supply_loc.count = 0
                                                                                        OR i_supply_loc.count < i THEN
                                                                                    NULL
                                                                                   ELSE
                                                                                    i_supply_loc(i)
                                                                               END,
                                                        i_dt_request        => l_empty_array_varchar,
                                                        i_dt_return         => CASE
                                                                                   WHEN i_dt_return.count = 0
                                                                                        OR i_dt_return.count < i THEN
                                                                                    NULL
                                                                                   ELSE
                                                                                    i_dt_return(i)
                                                                               END,
                                                        i_id_req_reason     => CASE
                                                                                   WHEN i_id_req_reason.count = 0
                                                                                        OR i_id_req_reason.count < i THEN
                                                                                    NULL
                                                                                   ELSE
                                                                                    i_id_req_reason(i)
                                                                               END,
                                                        i_id_context        => CASE
                                                                                   WHEN i_id_sr_epis_interv.count = 0
                                                                                        OR i_id_sr_epis_interv.count < i THEN
                                                                                    NULL
                                                                                   ELSE
                                                                                    i_id_sr_epis_interv(i)
                                                                               END,
                                                        i_flg_context       => CASE
                                                                                   WHEN i_id_sr_epis_interv.count > 0 THEN
                                                                                    pk_supplies_constant.g_context_surgery
                                                                                   ELSE
                                                                                    NULL
                                                                               END,
                                                        i_notes             => CASE
                                                                                   WHEN i_notes.count = 0
                                                                                        OR i_notes.count < i THEN
                                                                                    NULL
                                                                                   ELSE
                                                                                    i_notes(i)
                                                                               END,
                                                        i_flg_cons_type     => i_flg_cons_type(i),
                                                        i_flg_editable      => l_flg_editable,
                                                        i_flg_reusable      => l_flg_reusable,
                                                        i_flg_preparing     => l_flg_preparing,
                                                        i_flg_countable     => l_flg_countable,
                                                        i_supply_soft_inst  => NULL,
                                                        i_supply_flg_status => NULL,
                                                        i_id_inst_dest      => i_id_inst_dest,
                                                        o_id_supply_request => l_id_supply_request,
                                                        o_error             => o_error)
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
                                              'GET_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END set_supplies_surg_proc;

    FUNCTION get_has_supplies_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
    
        l_yes   sys_domain.desc_val%TYPE;
        l_no    sys_domain.desc_val%TYPE;
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL pk_sysdomain.get_domain';
        l_yes   := pk_sysdomain.get_domain(i_code_dom => pk_act_therap_constant.g_domain_yes_no,
                                           i_val      => pk_alert_constant.g_yes,
                                           i_lang     => i_lang);
        l_no    := pk_sysdomain.get_domain(i_code_dom => pk_act_therap_constant.g_domain_yes_no,
                                           i_val      => pk_alert_constant.g_no,
                                           i_lang     => i_lang);
    
        g_error := 'pk_supplies_core.check_loaned_supplies';
        IF (check_loaned_supplies(i_lang, i_prof, i_id_episode) = pk_alert_constant.g_yes)
        THEN
            RETURN l_yes;
        ELSE
            RETURN l_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HAS_SUPPLIES_DESC',
                                              l_error);
            RETURN NULL;
    END get_has_supplies_desc;

    FUNCTION check_loaned_supplies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_has_supplies VARCHAR2(1) := pk_alert_constant.g_no;
        l_error        t_error_out;
    
    BEGIN
    
        g_error := 'GET L_HAS_SUPPLIES';
        SELECT pk_alert_constant.g_yes
          INTO l_has_supplies
          FROM supply_workflow sw
         WHERE sw.id_episode = i_id_episode
           AND sw.flg_status = pk_supplies_constant.g_sww_loaned
           AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
           AND sw.id_supply_area = pk_supplies_constant.g_area_activity_therapy --this function is only used by Activity Therapist
           AND rownum = 1;
    
        RETURN l_has_supplies;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_has_supplies;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_LOANED_SUPPLIES',
                                              l_error);
            RETURN NULL;
    END check_loaned_supplies;

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
    
        l_supply_workflow     supply_workflow%ROWTYPE;
        l_rows                table_varchar;
        l_id_supply_soft_inst supply_soft_inst.id_supply_soft_inst%TYPE;
        l_id_dept_requested   episode.id_dept_requested%TYPE;
        l_flg_cons_type       table_varchar;
        l_flg_reusable        table_varchar;
        l_flg_editable        table_varchar;
        l_flg_preparing       table_varchar;
        l_flg_countable       table_varchar;
    
    BEGIN
        -- Note: do not copy the following information: 
        -- cancelation data (id_prof_cancel, dt_cancel, notes_cancel, id_cancel_reason)
        -- rejection data (id_prof_reject, dt_reject, notes_reject)
    
        g_sysdate_tstz := current_timestamp;
        l_rows         := table_varchar();
    
        -- func    
        -- getting data to copy
        BEGIN
            SELECT *
              INTO l_supply_workflow
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_id_supply_workflow;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'There is no supply_workflow with id ' || i_id_supply_workflow;
                RAISE g_other_exception;
        END;
    
        -- set vars to insert
        g_error                              := 'Set vars ';
        l_supply_workflow.id_episode         := nvl(i_id_episode, l_supply_workflow.id_episode);
        l_supply_workflow.dt_supply_workflow := g_sysdate_tstz;
        l_supply_workflow.id_professional    := i_prof.id;
    
        IF l_supply_workflow.id_supply_area != pk_supplies_constant.g_area_surgical_supplies
        THEN
            l_supply_workflow.dt_request := nvl(i_dt_request, l_supply_workflow.dt_request);
        END IF;
    
        -- getting id_supply_soft_inst in order to update flag values
        BEGIN
            SELECT e.id_dept_requested
              INTO l_id_dept_requested
              FROM episode e
             WHERE e.id_episode = l_supply_workflow.id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_dept_requested := NULL;
        END;
    
        IF i_id_episode IS NOT NULL
        THEN
            -- patient area, so get supply_soft_inst configurations        
            g_error               := 'Call get_id_supply_soft_inst ';
            l_id_supply_soft_inst := pk_supplies_core.get_id_supply_soft_inst(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_id_supply_area   => l_supply_workflow.id_supply_area,
                                                                              i_id_dept          => l_id_dept_requested,
                                                                              i_consumption_type => l_supply_workflow.flg_cons_type,
                                                                              i_id_supply        => l_supply_workflow.id_supply);
        
            -- update all flags 
            g_error := 'Call get_supply_soft_inst ';
            IF NOT pk_supplies_utils.get_supply_soft_inst(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_supply_soft_inst => table_number(l_id_supply_soft_inst),
                                                          o_flg_cons_type    => l_flg_cons_type,
                                                          o_flg_reusable     => l_flg_reusable,
                                                          o_flg_editable     => l_flg_editable,
                                                          o_flg_preparing    => l_flg_preparing,
                                                          o_flg_countable    => l_flg_countable,
                                                          o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error                         := 'Update flags ';
            l_supply_workflow.flg_cons_type := l_flg_cons_type(1);
            l_supply_workflow.flg_reusable  := l_flg_reusable(1);
            l_supply_workflow.flg_editable  := l_flg_editable(1);
            l_supply_workflow.flg_preparing := l_flg_preparing(1);
            l_supply_workflow.flg_countable := l_flg_countable(1);
        END IF;
    
        -- cancellation data
        g_error                            := 'cancellation data ';
        l_supply_workflow.id_prof_cancel   := NULL;
        l_supply_workflow.dt_cancel        := NULL;
        l_supply_workflow.notes_cancel     := NULL;
        l_supply_workflow.id_cancel_reason := NULL;
    
        -- rejection data
        g_error                          := 'rejection data ';
        l_supply_workflow.id_prof_reject := NULL;
        l_supply_workflow.dt_reject      := NULL;
        l_supply_workflow.notes_reject   := NULL;
    
        -- primary key
        g_error                              := 'Primary key ';
        l_supply_workflow.id_supply_workflow := ts_supply_workflow.next_key;
    
        -- inserts the new supply_workflow
        g_error := 'Call ts_supply_workflow.ins ';
        ts_supply_workflow.ins(rec_in          => l_supply_workflow,
                               gen_pky_in      => FALSE,
                               handle_error_in => TRUE,
                               rows_out        => l_rows);
    
        g_error := 'Call t_data_gov_mnt.process_insert ';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- integration with inter-alert
        IF l_supply_workflow.flg_status != pk_supplies_constant.g_sww_predefined
           OR l_supply_workflow.flg_context != pk_supplies_constant.g_context_procedure_req
        THEN
            g_error := 'Call pk_ia_event_common.supply_workflow_new ';
            pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => l_supply_workflow.id_supply_workflow);
        END IF;
    
        o_id_supply_workflow := l_supply_workflow.id_supply_workflow;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'copy_supply_wf',
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
    
        l_supply_workflow supply_workflow%ROWTYPE;
        l_sup_int_wf      VARCHAR2(1 CHAR);
        l_rows            table_varchar;
        l_rows_workflow   table_varchar;
    
    BEGIN
    
        l_rows          := table_varchar();
        l_rows_workflow := table_varchar();
        g_sysdate_tstz  := current_timestamp;
    
        -- val
        IF i_supply.count = 0
           OR i_supply.count != i_supply_set.count
           OR i_supply.count != i_supply_qty.count
           OR i_supply.count != i_supply_loc.count
           OR i_supply.count != i_id_req_reason.count
           OR i_supply.count != i_notes.count
           OR i_supply.count != i_supply_soft_inst.count
           OR i_supply.count != i_flg_cons_type.count
           OR i_id_supply_area IS NULL
        THEN
            g_error := 'Invalid parameters ';
            RAISE g_other_exception;
        END IF;
    
        l_sup_int_wf := pk_sysconfig.get_config('SUPPLIES_INTERFACE_WORKFLOW', i_prof);
    
        g_error              := 'o_id_supply_workflow ';
        o_id_supply_workflow := table_number();
        o_id_supply_workflow.extend(i_supply.count);
    
        -- create a supply_workflow record (without a supply_request)
        -- note: this is not done with function create_supply_workflow because field quantity must keep a value greater than 1
        g_error := 'FOR i IN 1 .. ' || i_supply.count || ' ';
        FOR i IN 1 .. i_supply.count
        LOOP
        
            -- sets supply_workflow data
            g_error                              := 'sets supply_workflow data ';
            l_supply_workflow.id_professional    := i_prof.id;
            l_supply_workflow.id_episode         := NULL;
            l_supply_workflow.id_supply_request  := NULL; -- there is no request related to predefined supply_workflows
            l_supply_workflow.id_supply          := i_supply(i);
            l_supply_workflow.id_supply_set      := i_supply_set(i);
            l_supply_workflow.id_supply_location := CASE
                                                        WHEN l_sup_int_wf = pk_alert_constant.get_yes THEN
                                                         NULL
                                                        ELSE
                                                         nvl(i_supply_loc(i),
                                                             pk_supplies_core.get_default_location(i_lang,
                                                                                                   i_prof,
                                                                                                   i_id_supply_area,
                                                                                                   nvl(i_supply_set(i),
                                                                                                       i_supply(i))))
                                                    END;
            l_supply_workflow.quantity           := i_supply_qty(i); -- can be more than 1
            l_supply_workflow.total_quantity     := i_supply_qty(i);
            l_supply_workflow.id_context         := NULL; -- there is no context in order sets
            l_supply_workflow.flg_context        := NULL;
            l_supply_workflow.flg_status         := pk_supplies_constant.g_sww_predefined;
            l_supply_workflow.dt_request         := NULL; -- dates no set in order set
            l_supply_workflow.dt_returned        := NULL; -- dates no set in order set
            l_supply_workflow.dt_supply_workflow := g_sysdate_tstz;
            l_supply_workflow.id_req_reason      := i_id_req_reason(i);
            l_supply_workflow.notes              := i_notes(i);
            l_supply_workflow.flg_cons_type      := i_flg_cons_type(i);
            --l_supply_workflow.flg_reusable       := l_flg_reusable(i);
            --l_supply_workflow.flg_editable       := l_flg_editable(i);
            --l_supply_workflow.flg_preparing      := l_flg_preparing(i);
            --l_supply_workflow.flg_countable      := l_flg_countable(i);
            l_supply_workflow.id_supply_area := i_id_supply_area;
        
            -- primary key
            l_supply_workflow.id_supply_workflow := ts_supply_workflow.next_key;
        
            -- insert supply_workflow data
            g_error := 'Call ts_supply_workflow.ins ';
            ts_supply_workflow.ins(rec_in          => l_supply_workflow,
                                   gen_pky_in      => FALSE,
                                   handle_error_in => TRUE,
                                   rows_out        => l_rows_workflow);
        
            l_rows := l_rows MULTISET UNION l_rows_workflow;
            o_id_supply_workflow(i) := l_supply_workflow.id_supply_workflow;
        
        END LOOP;
    
        g_error := 'Call t_data_gov_mnt.process_insert ';
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
    
        l_count  PLS_INTEGER;
        l_rowids table_varchar;
    
    BEGIN
    
        -- val
        SELECT /*+opt_estimate(table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM supply_workflow sw
          JOIN TABLE(CAST(i_supply_workflow AS table_number)) t
            ON (t.column_value = sw.id_supply_workflow)
         WHERE sw.flg_status NOT IN (pk_supplies_constant.g_sww_predefined, pk_supplies_constant.g_srt_draft);
    
        -- double check
        g_error := 'IF l_count > 0 ';
        IF l_count > 0
        THEN
            g_error := 'Cannot delete this supply_workflow in this status';
            RAISE g_other_exception;
        END IF;
    
        -- remove from supply_workflow_hist
        g_error  := 'Call ts_supply_workflow_hist.del_by ';
        l_rowids := table_varchar();
        ts_supply_workflow_hist.del_by(where_clause_in => 'id_supply_workflow in (' ||
                                                          pk_utils.concat_table(i_tab   => i_supply_workflow,
                                                                                i_delim => ',') || ')');
    
        g_error := 'Call t_data_gov_mnt.process_delete ';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- remove from supply_workflow
        g_error  := 'Call ts_supply_workflow.del_by ';
        l_rowids := table_varchar();
        ts_supply_workflow.del_by(where_clause_in => 'id_supply_workflow in (' ||
                                                     pk_utils.concat_table(i_tab => i_supply_workflow, i_delim => ',') || ')');
    
        g_error := 'Call t_data_gov_mnt.process_delete ';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SUPPLY_WORKFLOW',
                                      i_rowids     => l_rowids,
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
                                              'DELETE_SUPPLY_WORKFLOW',
                                              o_error);
            RETURN FALSE;
    END delete_supply_workflow;

    FUNCTION delete_supplies_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_supply_workflow table_number := table_number();
    
    BEGIN
    
        SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO l_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context;
    
        g_error := 'CALL pk_supplies_core.DELETE_SUPPLY_WORKFLOW';
        IF l_supply_workflow.count > 0
        THEN
            IF NOT delete_supply_workflow(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_supply_workflow => l_supply_workflow,
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
                                              'DELETE_SUPPLIES_BY_CONTEXT',
                                              o_error);
            RETURN FALSE;
    END delete_supplies_by_context;

    FUNCTION get_context_supplies_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE,
        i_flg_status  IN table_varchar DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_str VARCHAR2(4000);
    BEGIN
        g_error := 'GET SUPPLIES TO STRING';
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_str
          FROM (SELECT pk_translation.get_translation(i_lang, si.code_supply) || ' [' ||
                       pk_string_utils.chop(concatenate(pk_translation.get_translation(i_lang, s.code_supply) || ' (' ||
                                                        pk_utils.to_str(sw.quantity) || '), '),
                                            2) || ']' description,
                       sw.id_supply_set id_supply_set,
                       0 rank
                  FROM supply_workflow sw
                  JOIN supply s
                    ON s.id_supply = sw.id_supply
                  LEFT JOIN supply si
                    ON si.id_supply = sw.id_supply_set
                 WHERE sw.id_context = i_id_context
                   AND sw.flg_context = i_flg_context
                   AND sw.id_supply_set IS NOT NULL
                   AND (i_flg_status IS NULL OR
                       sw.flg_status NOT IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                               t1.column_value
                                                FROM TABLE(i_flg_status) t1))
                 GROUP BY si.code_supply, sw.quantity, sw.id_supply_set
                UNION
                SELECT pk_translation.get_translation(i_lang, s.code_supply) || ' (' ||
                       pk_utils.to_str(SUM(sw.quantity)) || ')' description,
                       sw.id_supply_set id_supply_set,
                       1 rank
                  FROM supply_workflow sw
                  JOIN supply s
                    ON s.id_supply = sw.id_supply
                 WHERE sw.id_context = i_id_context
                   AND sw.flg_context = i_flg_context
                   AND sw.id_supply_set IS NULL
                   AND (i_flg_status IS NULL OR
                       sw.flg_status NOT IN (SELECT /*+opt_estimate(table t2 rows=1)*/
                                               t2.column_value
                                                FROM TABLE(i_flg_status) t2))
                   AND ((s.flg_type = pk_supplies_constant.g_supply_set_type AND
                       s.id_supply NOT IN (SELECT nvl(sw1.id_supply_set, 0)
                                               FROM supply_workflow sw1
                                              WHERE sw1.id_context IN (i_id_context))) OR
                       (s.flg_type IS NULL OR s.flg_type != pk_supplies_constant.g_supply_set_type))
                 GROUP BY s.code_supply, sw.quantity, sw.id_supply_set
                 ORDER BY rank)
         ORDER BY description;
    
        RETURN l_str;
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
    
        l_str VARCHAR2(4000);
    
    BEGIN
        g_error := 'GET SUPPLIES TO STRING';
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_str
          FROM (SELECT CASE
                            WHEN i_flg_show_set_description = pk_alert_constant.g_yes THEN
                             pk_translation.get_translation(i_lang, si.code_supply) || ' ['
                            ELSE
                             NULL
                        END || listagg(pk_translation.get_translation(i_lang, s.code_supply) || ' (' ||
                                       pk_utils.to_str(sw.quantity) || ')',
                                       ', ') within GROUP(ORDER BY pk_translation.get_translation(i_lang, s.code_supply)) ||CASE
                           WHEN i_flg_show_set_description =
                                pk_alert_constant.g_yes THEN
                            ']'
                           ELSE
                            NULL
                       END description,
                       sw.id_supply_set id_supply_set,
                       0 rank
                  FROM supply_workflow sw
                  JOIN supply s
                    ON s.id_supply = sw.id_supply
                  LEFT JOIN supply si
                    ON si.id_supply = sw.id_supply_set
                 WHERE sw.id_supply_set IS NOT NULL
                   AND sw.id_context = i_id_context
                   AND sw.flg_context = i_flg_context
                   AND sw.flg_status != pk_supplies_constant.g_sww_updated
                   AND (i_flg_filter_type = 'A' OR (i_flg_filter_type = 'D' AND sw.id_supply_request IS NOT NULL) OR
                       (i_flg_filter_type = 'C' AND sw.id_supply_request IS NULL))
                   AND (i_flg_status IS NULL OR
                       (i_flg_status = 'NC' AND sw.flg_status NOT IN pk_supplies_constant.g_sww_cancelled) OR
                       (i_flg_status IS NOT NULL AND i_flg_status != 'NC' AND sw.flg_status = i_flg_status))
                 GROUP BY si.code_supply, sw.quantity, sw.id_supply_set
                UNION
                SELECT pk_translation.get_translation(i_lang, s.code_supply) || ' (' ||
                       pk_utils.to_str(SUM(sw.quantity)) || ')' description,
                       sw.id_supply_set id_supply_set,
                       1 rank
                  FROM supply_workflow sw
                  JOIN supply s
                    ON s.id_supply = sw.id_supply
                 WHERE sw.id_supply_set IS NULL
                   AND sw.id_context = i_id_context
                   AND sw.flg_context = i_flg_context
                   AND sw.flg_status != pk_supplies_constant.g_sww_updated
                   AND (i_flg_filter_type = 'A' OR (i_flg_filter_type = 'D' AND sw.id_supply_request IS NOT NULL) OR
                       (i_flg_filter_type = 'C' AND sw.id_supply_request IS NULL))
                   AND (i_flg_status IS NULL OR
                       (i_flg_status = 'NC' AND sw.flg_status NOT IN pk_supplies_constant.g_sww_cancelled) OR
                       (i_flg_status IS NOT NULL AND i_flg_status != 'NC' AND sw.flg_status = i_flg_status))
                 GROUP BY s.code_supply, sw.quantity, sw.id_supply_set
                 ORDER BY rank)
         ORDER BY description;
    
        RETURN l_str;
    END get_count_supplies_str_all;

    FUNCTION get_supplies_descr_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A' --C--only consumptions (do not have request), D-only dispenses (has request), A-all
    ) RETURN VARCHAR2 IS
    
        l_str VARCHAR2(4000);
    
    BEGIN
        g_error := 'GET SUPPLIES TO STRING';
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_str
          FROM (SELECT pk_translation.get_translation(i_lang, si.code_supply) || ' [' ||
                       listagg(pk_translation.get_translation(i_lang, s.code_supply) || ' (' ||
                               pk_utils.to_str(sw.quantity) || ')',
                               ', ') within GROUP(ORDER BY pk_translation.get_translation(i_lang, s.code_supply)) || ']' description,
                       sw.id_supply_set id_supply_set,
                       0 rank
                  FROM supply_workflow sw
                  JOIN supply s
                    ON s.id_supply = sw.id_supply
                  LEFT JOIN supply si
                    ON si.id_supply = sw.id_supply_set
                 WHERE sw.id_supply_set IS NOT NULL
                   AND sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                  column_value
                                                   FROM TABLE(i_supply_workflow) t)
                   AND (i_flg_filter_type = 'A' OR (i_flg_filter_type = 'D' AND sw.id_supply_request IS NOT NULL) OR
                       (i_flg_filter_type = 'C' AND sw.id_supply_request IS NULL))
                 GROUP BY si.code_supply, sw.quantity, sw.id_supply_set
                UNION
                SELECT pk_translation.get_translation(i_lang, s.code_supply) || ' (' ||
                       pk_utils.to_str(SUM(sw.quantity)) || ')' description,
                       sw.id_supply_set id_supply_set,
                       1 rank
                  FROM supply_workflow sw
                  JOIN supply s
                    ON s.id_supply = sw.id_supply
                 WHERE sw.id_supply_set IS NULL
                   AND sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                  column_value
                                                   FROM TABLE(i_supply_workflow) t)
                   AND (i_flg_filter_type = 'A' OR (i_flg_filter_type = 'D' AND sw.id_supply_request IS NOT NULL) OR
                       (i_flg_filter_type = 'C' AND sw.id_supply_request IS NULL))
                 GROUP BY s.code_supply, sw.quantity, sw.id_supply_set
                 ORDER BY rank)
         ORDER BY description;
    
        RETURN l_str;
    END get_supplies_descr_by_id;

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
    
        l_id_supply_workflow table_number := table_number();
        l_id_supply          table_number := table_number();
    
    BEGIN
    
        g_error := 'GET INFORMATION SUPPLY WORKFLOW';
    
        -- if i_id_supply is not null so is necessary get the id_supply_workflow and id_supply
        IF i_id_supply IS NOT NULL
           AND i_id_supply.count > 0
        THEN
            SELECT sw.id_supply_workflow, sw.id_supply
              BULK COLLECT
              INTO l_id_supply_workflow, l_id_supply
              FROM supply_workflow sw
             WHERE sw.id_context = i_id_context
               AND sw.flg_context = i_flg_context
               AND sw.flg_status IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                      t1.column_value
                                       FROM TABLE(i_flg_status) t1)
               AND sw.id_supply IN (SELECT /*+opt_estimate(table t2 rows=1)*/
                                     t2.column_value
                                      FROM TABLE(i_id_supply) t2);
        
        ELSE
            -- if i_id_supply is null so is to check if there're supplies for this id_context and flg_context
            SELECT sw.id_supply_workflow, sw.id_supply
              BULK COLLECT
              INTO l_id_supply_workflow, l_id_supply
              FROM supply_workflow sw
             WHERE sw.id_context = i_id_context
               AND sw.flg_context = i_flg_context
               AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled);
        END IF;
    
        --if there no exists element in the collection l_id_supply so there aren't supplies to be cancelled
        IF l_id_supply.count > 0
        THEN
            o_has_supplies := pk_alert_constant.g_yes;
        ELSE
            o_has_supplies := pk_alert_constant.g_no;
        END IF;
    
        o_id_supply_workflow := l_id_supply_workflow;
        o_id_supply          := l_id_supply;
    
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
    
        g_error := 'OPEN O_SUPPLIES';
        OPEN o_supplies FOR
            SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || id_supply) desc_supply,
                   lot,
                   barcode_scanned barcode,
                   pk_date_utils.date_send_tsz(i_lang, dt_expiration, i_prof) dt_expiration
              FROM (SELECT sw.id_supply, sw.lot, sw.barcode_scanned, sw.dt_expiration
                      FROM supply_workflow sw
                     WHERE sw.id_context = i_id_context
                       AND sw.id_supply_set IS NULL
                       AND sw.flg_status NOT IN
                           (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                       AND i_flg_context IN
                           (pk_supplies_constant.g_context_procedure_req, pk_supplies_constant.g_context_surgery)
                    UNION ALL
                    SELECT sw.id_supply, sw.lot, sw.barcode_scanned, sw.dt_expiration
                      FROM supply_workflow sw
                     WHERE sw.id_context = i_id_context
                       AND sw.id_supply_set IS NULL
                       AND sw.flg_context = i_flg_context
                       AND sw.flg_status NOT IN
                           (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                       AND i_flg_context IN (pk_supplies_constant.g_context_procedure_exec,
                                             pk_supplies_constant.g_context_procedure_exec_edit,
                                             'I'));
    
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
    
        l_desc_supplies VARCHAR2(1000 CHAR);
    
    BEGIN
    
        g_error := 'GET SUPPLIES TO STRING';
        SELECT listagg(desc_supply, '; ') within GROUP(ORDER BY 1) desc_supply
          INTO l_desc_supplies
          FROM (SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) ||
                       decode((SELECT COUNT(*)
                                FROM supply_workflow
                               WHERE id_sup_workflow_parent = sw.id_supply_workflow
                                 AND id_supply_set = sw.id_supply),
                              0,
                              ' (' || pk_utils.to_str(SUM(sw.quantity)) || ')',
                              (' [' || pk_supplies_external.get_supply_set_description(i_lang,
                                                                                       i_prof,
                                                                                       sw.id_supply_workflow,
                                                                                       sw.id_supply) || ']')) desc_supply
                  FROM supply_workflow sw
                 WHERE sw.id_context = i_id_context
                   AND sw.id_supply_set IS NULL
                   AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                   AND i_flg_context IN
                       (pk_supplies_constant.g_context_procedure_req, pk_supplies_constant.g_context_surgery)
                 GROUP BY sw.id_supply_workflow, sw.id_supply, sw.id_supply_request, sw.id_supply_set, sw.dt_request
                UNION ALL
                SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) || ' (' ||
                       pk_utils.to_str(SUM(sw.quantity)) || ')' desc_supply
                  FROM supply_workflow sw
                 WHERE sw.id_context = i_id_context
                   AND sw.id_supply_set IS NULL
                   AND sw.flg_context = i_flg_context
                   AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                   AND i_flg_context IN (pk_supplies_constant.g_context_procedure_exec,
                                         pk_supplies_constant.g_context_procedure_exec_edit,
                                         'I')
                 GROUP BY sw.id_supply_workflow, sw.id_supply, sw.id_supply_request, sw.dt_request);
    
        RETURN l_desc_supplies;
    
    END get_supplies_request;

    FUNCTION get_supplies_request_history
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_supplies VARCHAR2(1000 CHAR);
    
    BEGIN
        g_error := 'GET SUPPLIES TO STRING HISTORY';
        SELECT listagg(desc_supply, '; ') within GROUP(ORDER BY 1) desc_supply
          INTO l_desc_supplies
          FROM (SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply_set) || ' [' ||
                       pk_string_utils.chop(concatenate(pk_translation.get_translation(i_lang,
                                                                                       'SUPPLY.CODE_SUPPLY.' ||
                                                                                       sw.id_supply) || ' (' ||
                                                        pk_utils.to_str(sw.quantity) || '), '),
                                            2) || ']' desc_supply,
                       sw.id_supply_set id_supply_set,
                       0 rank
                  FROM supply_workflow_hist sw
                 WHERE ((sw.id_supply_request IS NOT NULL AND
                       sw.id_supply_request =
                       (SELECT MAX(sw.id_supply_request)
                            FROM supply_workflow_hist sw
                           WHERE sw.id_context = i_id_context
                             AND (sw.flg_context = i_flg_context OR i_flg_context IS NULL)) AND
                       sw.id_context = i_id_context) OR (sw.id_supply_request IS NULL AND sw.id_context = i_id_context))
                   AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                 GROUP BY sw.quantity, sw.id_supply_set
                 ORDER BY rank)
         ORDER BY desc_supply;
    
        RETURN l_desc_supplies;
    
    END get_supplies_request_history;

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

    FUNCTION get_supply_set_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply       IN supply_workflow.id_supply%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_supplies pk_translation.t_desc_translation;
    BEGIN
    
        SELECT listagg(desc_supply, '; ') within GROUP(ORDER BY desc_supply) desc_supply
          INTO l_desc_supplies
          FROM (SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) || ' (' ||
                       pk_utils.to_str(SUM(sw.quantity)) || ')' desc_supply
                  FROM supply_workflow sw
                 WHERE sw.id_supply_set IS NOT NULL
                   AND sw.id_sup_workflow_parent = i_supply_workflow
                   AND sw.id_supply_set = i_id_supply
                 GROUP BY sw.id_supply, sw.id_supply_request, sw.dt_request);
    
        RETURN l_desc_supplies;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supply_set_description;

    FUNCTION get_supply_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A' --C--only consumptions (do not have request), D-only dispenses (has request), A-all
    ) RETURN VARCHAR2 IS
    
        l_desc_supplies pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT listagg(desc_supply, '; ') within GROUP(ORDER BY desc_supply) desc_supply
          INTO l_desc_supplies
          FROM (SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) ||
                       decode((SELECT COUNT(*)
                                FROM supply_workflow
                               WHERE id_sup_workflow_parent = sw.id_supply_workflow
                                 AND id_supply_set = sw.id_supply),
                              0,
                              ' (' || pk_utils.to_str(SUM(sw.quantity)) || ')',
                              ' [' || pk_supplies_external.get_supply_set_description(i_lang,
                                                                                      i_prof,
                                                                                      sw.id_supply_workflow,
                                                                                      sw.id_supply) || ']') desc_supply
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                  column_value
                                                   FROM TABLE(i_supply_workflow))
                   AND sw.id_supply_set IS NULL
                   AND (i_flg_filter_type = 'A' OR (i_flg_filter_type = 'D' AND sw.id_supply_request IS NOT NULL) OR
                       (i_flg_filter_type = 'C' AND sw.id_supply_request IS NULL) OR
                       (i_flg_filter_type = 'X' AND
                       sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)))
                 GROUP BY sw.id_supply, sw.id_supply_workflow, sw.id_supply_set, sw.dt_request);
    
        RETURN l_desc_supplies;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supply_description;

    FUNCTION get_supply_quantity
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE
    ) RETURN supply_soft_inst.quantity%TYPE IS
        l_quantity supply_soft_inst.quantity%TYPE := 0;
        l_error    t_error_out;
    BEGIN
        g_error := 'CALC quantity';
        SELECT SUM(ssi.total_avail_quantity)
          INTO l_quantity
          FROM supply_soft_inst ssi
         INNER JOIN supply_sup_area ssa
            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
           AND ssa.flg_available = pk_alert_constant.g_yes
           AND ssa.id_supply_area = i_id_supply_area
         WHERE ssi.id_institution = i_prof.institution
           AND ssi.id_software = i_prof.software
           AND ssi.id_professional IN (0, i_prof.id)
           AND ssi.id_supply = i_id_supply;
        RETURN l_quantity;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_QUANTITY',
                                              l_error);
            RETURN l_quantity;
    END get_supply_quantity;

    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_supply_workflow    IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
        l_ret         CLOB;
        l_supply_desc pk_translation.t_desc_translation;
        l_start_date  VARCHAR2(50 CHAR) := NULL;
        l_token_list  table_varchar;
    
        CURSOR c_desc IS
            SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) supply_desc,
                   pk_date_utils.date_char_tsz(i_lang, sw.dt_supply_workflow, i_prof.institution, i_prof.software) start_date
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_id_supply_workflow;
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_supply_desc, l_start_date;
        CLOSE c_desc;
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'START-DATE'
                   AND l_start_date IS NOT NULL
                THEN
                    IF l_ret IS NULL
                    THEN
                        l_ret := l_start_date;
                    ELSE
                        l_ret := l_ret || pk_prog_notes_constants.g_comma || l_start_date;
                    END IF;
                    IF i = 1
                    THEN
                        l_ret := l_ret || pk_prog_notes_constants.g_space;
                    END IF;
                ELSIF l_token_list(i) = 'DESCRIPTION'
                      AND l_supply_desc IS NOT NULL
                THEN
                    l_ret := l_ret || l_supply_desc;
                END IF;
            END LOOP;
        ELSE
            l_ret := l_start_date || pk_prog_notes_constants.g_comma || l_supply_desc;
        END IF;
    
        RETURN l_ret;
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
        l_internal_error EXCEPTION;
        l_msg_return sys_message.desc_message%TYPE;
        l_msg_loan   sys_message.desc_message%TYPE;
    
        l_msg_oper_add         sys_message.desc_message%TYPE;
        l_msg_oper_edit        sys_message.desc_message%TYPE;
        l_msg_oper_canc        sys_message.desc_message%TYPE;
        l_msg_supply           sys_message.desc_message%TYPE;
        l_msg_supply_type      sys_message.desc_message%TYPE;
        l_msg_delivered_units  sys_message.desc_message%TYPE;
        l_msg_loan_units       sys_message.desc_message%TYPE;
        l_msg_delivery_date    sys_message.desc_message%TYPE;
        l_msg_delivery_canc    sys_message.desc_message%TYPE;
        l_msg_loan_canc        sys_message.desc_message%TYPE;
        l_msg_pr_delivery_date sys_message.desc_message%TYPE;
        l_canc_rea_title       sys_message.desc_message%TYPE;
        l_canc_not_title       sys_message.desc_message%TYPE;
    
        l_msg_reg             sys_message.desc_message%TYPE;
        l_ids_supply_workflow table_number;
    BEGIN
        g_error := 'GET Messages';
    
        l_msg_return    := pk_act_therap_constant.g_open_bold_html ||
                           pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_return) ||
                           pk_act_therap_constant.g_close_bold_html;
        l_msg_loan      := pk_act_therap_constant.g_open_bold_html ||
                           pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_loan) ||
                           pk_act_therap_constant.g_close_bold_html;
        l_msg_oper_add  := pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_oper_add);
        l_msg_oper_edit := pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_oper_edit);
        l_msg_oper_canc := pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_oper_canc);
    
        l_msg_delivered_units := pk_act_therap_constant.g_open_bold_html ||
                                 pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_delivered_units) ||
                                 pk_act_therap_constant.g_close_bold_html;
    
        l_msg_loan_units := pk_act_therap_constant.g_open_bold_html ||
                            pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_loan_units) ||
                            pk_act_therap_constant.g_close_bold_html;
    
        l_msg_pr_delivery_date := pk_act_therap_constant.g_open_bold_html ||
                                  pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_pr_delivery_date) ||
                                  pk_act_therap_constant.g_close_bold_html;
    
        l_msg_delivery_date := pk_act_therap_constant.g_open_bold_html ||
                               pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_delivery_date) ||
                               pk_act_therap_constant.g_close_bold_html;
    
        l_msg_delivery_canc := pk_act_therap_constant.g_open_bold_html ||
                               pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_delivery_canc) ||
                               pk_act_therap_constant.g_close_bold_html;
    
        l_msg_loan_canc := pk_act_therap_constant.g_open_bold_html ||
                           pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_loan_canc) ||
                           pk_act_therap_constant.g_close_bold_html;
    
        l_msg_reg := pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_reg);
    
        l_canc_rea_title := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => pk_message.get_message(i_lang,
                                                                                                               i_prof,
                                                                                                               'COMMON_M072'));
        l_canc_not_title := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => pk_message.get_message(i_lang,
                                                                                                               i_prof,
                                                                                                               'COMMON_M073'));
    
        IF (i_flg_screen = pk_act_therap_constant.g_screen_ehr)
        THEN
            l_msg_supply := pk_act_therap_constant.g_open_bold_html ||
                            pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_supply) ||
                            pk_act_therap_constant.g_close_bold_html;
        
            l_msg_supply_type := pk_act_therap_constant.g_open_bold_html ||
                                 pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_supply_type) ||
                                 pk_act_therap_constant.g_close_bold_html;
        END IF;
    
        -- get the supply workflow ids
        IF (i_id_supply_workflow IS NULL)
        THEN
            --going by supply or by all the patient supplies (i_id_supply = null)        
            SELECT t.id_supply_workflow
              BULK COLLECT
              INTO l_ids_supply_workflow
              FROM (SELECT sw.id_supply_workflow
                      FROM supply_workflow_hist sw
                     WHERE sw.id_episode IN (SELECT column_value
                                               FROM TABLE(i_id_episode))
                       AND (sw.id_supply = i_id_supply OR i_id_supply IS NULL)
                       AND (i_start_date IS NULL OR sw.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR sw.dt_supply_workflow < i_end_date)
                       AND sw.id_supply_area = i_id_supply_area
                    
                    UNION ALL
                    
                    SELECT sw.id_supply_workflow
                      FROM supply_workflow sw
                     WHERE sw.id_episode IN (SELECT column_value
                                               FROM TABLE(i_id_episode))
                       AND (sw.id_supply = i_id_supply OR i_id_supply IS NULL)
                       AND (i_start_date IS NULL OR sw.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR sw.dt_supply_workflow < i_end_date)
                       AND sw.id_supply_area = i_id_supply_area) t;
        
        ELSE
        
            SELECT t.id_supply_workflow
              BULK COLLECT
              INTO l_ids_supply_workflow
              FROM (SELECT sw.id_supply_workflow
                      FROM supply_workflow_hist sw
                     WHERE sw.id_episode IN (SELECT column_value
                                               FROM TABLE(i_id_episode))
                       AND (i_start_date IS NULL OR sw.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR sw.dt_supply_workflow < i_end_date)
                       AND (sw.id_supply_workflow = i_id_supply_workflow OR
                           sw.id_sup_workflow_parent = i_id_supply_workflow)
                    
                    UNION ALL
                    
                    SELECT sw.id_supply_workflow
                      FROM supply_workflow sw
                     WHERE sw.id_episode IN (SELECT column_value
                                               FROM TABLE(i_id_episode))
                       AND (i_start_date IS NULL OR sw.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR sw.dt_supply_workflow < i_end_date)
                       AND (sw.id_supply_workflow = i_id_supply_workflow OR
                           sw.id_sup_workflow_parent = i_id_supply_workflow)) t;
        
        END IF;
    
        OPEN o_sup_workflow_prof FOR
            SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_supply_workflow, i_prof) dt,
                   pk_tools.get_prof_description_cat(i_lang,
                                                     i_prof,
                                                     t.id_professional,
                                                     t.dt_supply_workflow,
                                                     t.id_episode) ||
                   pk_episode.get_epis_institution(i_lang, i_prof, t.id_episode) prof_sign,
                   decode(t.flg_status,
                          pk_supplies_constant.g_sww_cancelled,
                          l_msg_oper_canc,
                          pk_supplies_constant.g_sww_deliver_cancelled,
                          l_msg_oper_canc,
                          
                          decode(t.flg_outdated,
                                 pk_supplies_constant.g_sww_edited,
                                 l_msg_oper_edit,
                                 
                                 l_msg_oper_add)) desc_status
            
              FROM (SELECT sw.id_supply_workflow,
                           NULL id_supply_workflow_hist,
                           sw.flg_status,
                           sw.dt_supply_workflow,
                           sw.id_professional,
                           sw.id_episode,
                           sw.flg_outdated
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow IN (SELECT column_value
                                                       FROM TABLE(l_ids_supply_workflow))
                       AND ((sw.quantity = sw.total_quantity AND sw.flg_status = pk_supplies_constant.g_sww_loaned) OR
                           sw.flg_status != pk_supplies_constant.g_sww_loaned OR
                           sw.flg_outdated = pk_supplies_constant.g_sww_edited)
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND (i_start_date IS NULL OR sw.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR sw.dt_supply_workflow < i_end_date)
                    
                    UNION ALL
                    SELECT swh.id_supply_workflow,
                           swh.id_supply_workflow_hist,
                           swh.flg_status,
                           swh.dt_supply_workflow,
                           swh.id_professional,
                           swh.id_episode,
                           swh.flg_outdated
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow IN (SELECT column_value
                                                        FROM TABLE(l_ids_supply_workflow))
                       AND ((swh.quantity = swh.total_quantity AND swh.flg_status = pk_supplies_constant.g_sww_loaned) OR
                           swh.flg_status != pk_supplies_constant.g_sww_loaned OR
                           swh.flg_outdated = pk_supplies_constant.g_sww_edited)
                       AND swh.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND (i_start_date IS NULL OR swh.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR swh.dt_supply_workflow < i_end_date)) t
            
             ORDER BY t.dt_supply_workflow DESC, id_supply_workflow;
    
        g_error := 'GET SUPLIES DATA';
    
        OPEN o_sup_workflow FOR
            SELECT pk_activity_therapist.get_epis_parent(i_lang, i_prof, t.id_episode) id_episode_origin,
                   decode(t.flg_status,
                          pk_supplies_constant.g_sww_loaned,
                          l_msg_loan,
                          pk_supplies_constant.g_sww_deliver_institution,
                          l_msg_return,
                          pk_supplies_constant.g_sww_deliver_cancelled,
                          l_msg_delivery_canc,
                          pk_supplies_constant.g_sww_cancelled,
                          l_msg_loan_canc) desc_title,
                   
                   decode(i_flg_screen,
                           pk_act_therap_constant.g_screen_detail,
                           NULL,
                           l_msg_supply || pk_translation.get_translation(i_lang, s.code_supply) || --
                           CASE
                               WHEN supply_attrib IS NOT NULL THEN
                                pk_act_therap_constant.g_open_parenthesis || supply_attrib || --
                                pk_act_therap_constant.g_close_parenthesis
                           END) desc_supply,
                   decode(i_flg_screen,
                          pk_act_therap_constant.g_screen_detail,
                          NULL,
                          l_msg_supply_type ||
                          nvl(i_supply_desc, pk_translation.get_translation(i_lang, st.code_supply_type))) desc_supply_type,
                   
                   decode(t.flg_status,
                           pk_supplies_constant.g_sww_loaned,
                           l_msg_loan_units,
                           pk_supplies_constant.g_sww_deliver_institution,
                           l_msg_delivered_units, --
                           pk_supplies_constant.g_sww_cancelled,
                           l_msg_loan_units,
                           pk_supplies_constant.g_sww_deliver_cancelled,
                           l_msg_delivered_units) || --                  
                    nvl(CASE
                            WHEN t.flg_status = pk_supplies_constant.g_sww_loaned THEN
                             t.total_quantity
                            ELSE
                             t.quantity
                        END,
                        pk_act_therap_constant.g_supplies_default_qt) AS quantity_desc,
                   CASE
                        WHEN t.flg_status IN (pk_supplies_constant.g_sww_loaned, pk_supplies_constant.g_sww_cancelled) THEN
                         l_msg_pr_delivery_date
                        ELSE
                         l_msg_delivery_date
                    END || pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_returned, i_prof) return_date_desc,
                   CASE
                        WHEN t.flg_status IN
                             (pk_supplies_constant.g_sww_cancelled, pk_supplies_constant.g_sww_deliver_cancelled) THEN
                         l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                        ELSE
                         NULL
                    END desc_cancel_reason,
                   decode(to_char(t.notes_cancel), NULL, NULL, l_canc_not_title || to_char(t.notes_cancel)) desc_cancel_notes,
                   pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                     i_prof,
                                                                     t.dt_supply_workflow,
                                                                     t.id_professional,
                                                                     t.dt_supply_workflow,
                                                                     NULL,
                                                                     l_msg_reg) last_update_info
            
              FROM (SELECT sw.id_supply_workflow,
                           NULL id_supply_workflow_hist,
                           sw.flg_status,
                           sw.dt_supply_workflow,
                           sw.id_professional,
                           sw.id_episode,
                           sw.flg_outdated,
                           sw.id_supply,
                           sw.dt_returned,
                           sw.quantity,
                           sw.total_quantity,
                           sw.id_cancel_reason,
                           sw.notes_cancel,
                           pk_supplies_core.get_attributes(i_lang, i_prof, sw.id_supply_area, sw.id_supply) supply_attrib
                      FROM supply_workflow sw
                     WHERE sw.id_supply_workflow IN (SELECT column_value
                                                       FROM TABLE(l_ids_supply_workflow))
                       AND ((sw.quantity = sw.total_quantity AND sw.flg_status = pk_supplies_constant.g_sww_loaned) OR
                           sw.flg_status != pk_supplies_constant.g_sww_loaned OR
                           sw.flg_outdated = pk_supplies_constant.g_sww_edited)
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND (i_start_date IS NULL OR sw.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR sw.dt_supply_workflow < i_end_date)
                    UNION ALL
                    SELECT swh.id_supply_workflow,
                           swh.id_supply_workflow_hist,
                           swh.flg_status,
                           swh.dt_supply_workflow,
                           swh.id_professional,
                           swh.id_episode,
                           swh.flg_outdated,
                           swh.id_supply,
                           swh.dt_returned,
                           swh.quantity,
                           swh.total_quantity,
                           swh.id_cancel_reason,
                           swh.notes_cancel,
                           pk_supplies_core.get_attributes(i_lang, i_prof, swh.id_supply_area, swh.id_supply) supply_attrib
                      FROM supply_workflow_hist swh
                     WHERE swh.id_supply_workflow IN (SELECT column_value
                                                        FROM TABLE(l_ids_supply_workflow))
                       AND ((swh.quantity = swh.total_quantity AND swh.flg_status = pk_supplies_constant.g_sww_loaned) OR
                           swh.flg_status != pk_supplies_constant.g_sww_loaned OR
                           swh.flg_outdated = pk_supplies_constant.g_sww_edited)
                       AND swh.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND (i_start_date IS NULL OR swh.dt_supply_workflow > i_start_date)
                       AND (i_end_date IS NULL OR swh.dt_supply_workflow < i_end_date)) t
              JOIN supply s
                ON s.id_supply = t.id_supply
              JOIN supply_type st
                ON st.id_supply_type = s.id_supply_type
              LEFT JOIN cancel_reason cr
                ON t.id_cancel_reason = cr.id_cancel_reason
             WHERE t.id_supply_workflow IN (SELECT column_value
                                              FROM TABLE(l_ids_supply_workflow))
             ORDER BY t.dt_supply_workflow DESC, id_supply_workflow;
    
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
            pk_types.open_my_cursor(o_sup_workflow_prof);
            pk_types.open_my_cursor(o_sup_workflow);
            RETURN FALSE;
    END get_workflow_history;

    FUNCTION get_workflow_parent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN supply_workflow.id_supply_workflow%TYPE IS
    
        l_id_supply_workflow supply_workflow.id_supply_workflow%TYPE;
        l_error              t_error_out;
    
    BEGIN
    
        g_error := 'GET THE ID_SUPPLY_WORKFLOW PARENT FOR id_supply_workflow: ' || i_id_supply_workflow;
        SELECT sw.id_sup_workflow_parent
          INTO l_id_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        RETURN l_id_supply_workflow;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WORKFLOW_PARENT',
                                              l_error);
            RETURN NULL;
    END get_workflow_parent;

    FUNCTION set_independent_supply
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        g_error := 'UPDATE SUPPLY_WORKFLOW TABLE TO REMOVE THE ASSOCIATION WITH ID_CONTEXT';
        FOR i IN 1 .. i_id_supply_workflow.count
        LOOP
            pk_supplies_api_db.set_supply_workflow_hist(i_id_supply_workflow(i), NULL, NULL);
            ts_supply_workflow.upd(id_supply_workflow_in => i_id_supply_workflow(i),
                                   id_professional_in    => i_prof.id,
                                   id_context_in         => NULL,
                                   id_context_nin        => FALSE,
                                   flg_context_in        => NULL,
                                   flg_context_nin       => FALSE,
                                   rows_out              => l_rows);
        
            g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SUPPLY_WORKFLOW',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_CONTEXT', 'FLG_CONTEXT'));
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
    
        l_supply_workflow table_number := table_number();
        l_flg_cons_type   table_varchar := table_varchar();
        l_flg_reusable    table_varchar := table_varchar();
        l_flg_editable    table_varchar := table_varchar();
        l_flg_preparing   table_varchar := table_varchar();
        l_flg_countable   table_varchar := table_varchar();
    
        l_supply_t_number  table_number := table_number();
        l_supply_t_varchar table_varchar := table_varchar();
        l_rows_upd         table_varchar := table_varchar();
    BEGIN
    
        SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO l_supply_workflow
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context;
    
        FOR j IN 1 .. l_supply_workflow.count
        LOOP
            g_error := 'CALL pk_supplies_core.SET_SUPPLY_WORKFLOW_HIST';
            pk_supplies_utils.set_supply_workflow_hist(l_supply_workflow(j), NULL, NULL);
        
            g_error := 'UPDATE SUPPLY_WORKFLOW';
            ts_supply_workflow.upd(id_supply_workflow_in => l_supply_workflow(j),
                                   flg_status_in         => pk_supplies_constant.g_sww_updated,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows_upd);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUPPLY_WORKFLOW',
                                          i_rowids     => l_rows_upd,
                                          o_error      => o_error);
        
        END LOOP;
    
        SELECT ssi.flg_cons_type,
               ssi.flg_reusable,
               ssi.flg_editable,
               ssi.flg_preparing,
               ssi.flg_countable,
               NULL              interv_t_number,
               NULL              interv_t_varchar
          BULK COLLECT
          INTO l_flg_cons_type,
               l_flg_reusable,
               l_flg_editable,
               l_flg_preparing,
               l_flg_countable,
               l_supply_t_number,
               l_supply_t_varchar
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 t.column_value
                  FROM TABLE(i_supply) t) tt
          LEFT JOIN supply_soft_inst ssi
            ON ssi.id_supply = tt.column_value
           AND ssi.id_institution = i_prof.institution
           AND ssi.id_software = i_prof.software;
    
        g_error := 'CALL pk_supplies_core.CREATE_REQUEST';
        IF NOT pk_supplies_core.create_supply_order(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_supply_area    => pk_supplies_constant.g_area_supplies,
                                                    i_id_episode        => i_episode,
                                                    i_supply            => i_supply,
                                                    i_supply_set        => i_supply_set,
                                                    i_supply_qty        => i_supply_qty,
                                                    i_supply_loc        => l_supply_t_number,
                                                    i_dt_request        => i_dt_request,
                                                    i_dt_return         => i_dt_return,
                                                    i_id_req_reason     => l_supply_t_number,
                                                    i_id_context        => table_number(i_id_context),
                                                    i_flg_context       => table_varchar(i_flg_context),
                                                    i_notes             => l_supply_t_varchar,
                                                    i_supply_flg_status => NULL,
                                                    i_id_inst_dest      => NULL,
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
                                              'UPDATE_SUPPLY_ORDER',
                                              o_error);
            RETURN FALSE;
    END update_supply_order;

    FUNCTION get_requested_supplies_per_context
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_id_context      IN supply_workflow.id_context%TYPE,
        i_flg_default_qty IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_context_m    IN table_varchar DEFAULT NULL,
        i_id_context_p    IN table_varchar DEFAULT NULL,
        o_supplies        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET SUPPLIES REQUESTED i_flg_context: ' || i_flg_context || ' i_id_context: ' || i_id_context;
        OPEN o_supplies FOR
            SELECT sw.id_supply_workflow id_supply_workflow,
                   s.id_supply id_supply,
                   s.flg_type,
                   pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                   CASE
                        WHEN i_flg_default_qty = pk_alert_constant.g_yes THEN
                         pk_supplies_external.get_supply_default_qty(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_id_supply     => s.id_supply,
                                                                     i_id_supply_set => sw.id_supply_set,
                                                                     i_id_context_m  => i_id_context_m,
                                                                     i_id_context_p  => i_id_context_p)
                        ELSE
                         sw.quantity
                    END quantity,
                   sw.flg_status flg_status,
                   sw.barcode_req barcode_req,
                   sw.flg_reusable,
                   sw.id_supply_set id_set,
                   pk_translation.get_translation(i_lang, sd.code_supply) set_description,
                   sw.flg_cons_type flg_comsumption_type,
                   pk_supplies_core.get_attributes(i_lang, i_prof, NULL, s.id_supply) desc_supply_attrib,
                   sd.id_supply id_parent_supply,
                   CASE
                        WHEN sw.id_supply_request IS NOT NULL THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_dispensed,
                   sw.barcode_scanned barcode_id,
                   sw.lot lot_id,
                   sw.dt_expiration expiration_date
              FROM supply_workflow sw
              JOIN supply s
                ON s.id_supply = sw.id_supply
              LEFT JOIN supply sd
                ON sw.id_supply_set = sd.id_supply
             WHERE sw.id_context = i_id_context
               AND sw.flg_context = i_flg_context
               AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
               AND ((i_flg_default_qty = pk_alert_constant.g_no) OR
                   --in the administration only should appear the records ready for consumption
                   (i_flg_default_qty = pk_alert_constant.g_yes AND sw.id_supply_request IS NOT NULL AND
                   sw.flg_status = pk_supplies_constant.g_sww_transport_concluded))
             ORDER BY desc_supply;
    
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

    /*
    Get the default supplies: 
    the already requested to the given context + the configured ones that were not requested yet
    */
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
        l_supplies_req             pk_types.cursor_type;
        l_supplies_cfg             pk_types.cursor_type;
        l_supplies_record_cfg      supplies_type_cfg;
        l_tbl_supplies_cfg         tbl_supplies_type_cfg := tbl_supplies_type_cfg();
        l_tbl_supplies_cfg_not_req tbl_supplies_type_cfg := tbl_supplies_type_cfg();
    
        l_supplies_record_req supplies_type_req;
        l_tbl_supplies_req    tbl_supplies_type_req := tbl_supplies_type_req();
    BEGIN
    
        g_error := 'Call get_requested_supplies_per_context. i_id_context_d: ' || i_id_context_d;
        IF NOT get_requested_supplies_per_context(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_flg_context     => i_flg_context_d,
                                                  i_id_context      => i_id_context_d,
                                                  i_flg_default_qty => i_flg_default_qty,
                                                  i_id_context_m    => i_id_context_m,
                                                  i_id_context_p    => i_id_context_p,
                                                  o_supplies        => l_supplies_req,
                                                  o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'Call pk_supplies_api_db.get_supplies_by_contex.';
        IF NOT pk_supplies_api_db.get_supplies_by_context(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_context_m => i_id_context_m,
                                                          i_id_context_p => i_id_context_p,
                                                          o_supplies     => l_supplies_cfg,
                                                          o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCHING l_supplies_req';
        LOOP
            FETCH l_supplies_req
                INTO l_supplies_record_req;
            EXIT WHEN l_supplies_req%NOTFOUND;
        
            l_tbl_supplies_req.extend();
            l_tbl_supplies_req(l_tbl_supplies_req.count) := l_supplies_record_req;
        END LOOP;
    
        g_error := 'FETCHING l_supplies_cfg';
        LOOP
            FETCH l_supplies_cfg
                INTO l_supplies_record_cfg;
            EXIT WHEN l_supplies_cfg%NOTFOUND;
        
            l_tbl_supplies_cfg.extend();
            l_tbl_supplies_cfg(l_tbl_supplies_cfg.count) := l_supplies_record_cfg;
        END LOOP;
    
        -- the configured supplies are only considered if the id_supply were not requested yet
        g_error := 'Exclude already requested supplies';
        SELECT l.*
          BULK COLLECT
          INTO l_tbl_supplies_cfg_not_req
          FROM TABLE(l_tbl_supplies_cfg) l
         WHERE l.id_supply NOT IN (SELECT tr.id_supply
                                     FROM TABLE(l_tbl_supplies_req) tr);
    
        g_error := 'o_supplies cursor';
        OPEN o_supplies FOR
            SELECT DISTINCT (t.id_supply_soft_inst),
                            NULL id_supply_workflow,
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
                            pk_alert_constant.g_no flg_consumed,
                            NULL flg_status,
                            NULL barcode_req,
                            NULL flg_reusable,
                            NULL id_supply_set,
                            pk_translation.get_translation(i_lang, sset.code_supply) desc_set,
                            NULL flg_dispensed,
                            NULL barcode_verification,
                            NULL lot_verification,
                            NULL expiration_date
              FROM TABLE(l_tbl_supplies_cfg_not_req) t
              LEFT JOIN supply sset
                ON sset.id_supply = t.id_parent_supply
            UNION
            SELECT NULL id_supply_soft_inst,
                   t.id_supply_workflow,
                   t.id_supply,
                   t.id_parent_supply,
                   t.desc_supply,
                   t.desc_supply_attrib,
                   NULL desc_cons_type,
                   t.flg_cons_type,
                   t.quantity,
                   NULL dt_return,
                   NULL id_supply_location,
                   NULL desc_supply_location,
                   t.flg_type,
                   NULL id_context,
                   NULL rank,
                   CASE
                       WHEN i_flg_default_qty = pk_alert_constant.g_yes THEN
                       --in the administration when it is a record dispensed in pharmacy
                       -- should be to consume by default
                        CASE
                            WHEN t.flg_dispensed = pk_alert_constant.g_yes THEN
                             pk_alert_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END
                       ELSE
                        CASE
                            WHEN t.flg_dispensed = pk_alert_constant.g_no THEN
                             pk_alert_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END
                   END flg_consumed,
                   t.flg_status,
                   t.barcode_req,
                   t.flg_reusable,
                   t.id_supply_set,
                   t.set_description desc_set,
                   CASE
                       WHEN i_flg_default_qty = pk_alert_constant.g_yes THEN
                        pk_alert_constant.g_no
                       ELSE
                        t.flg_dispensed
                   END fld_dispensed,
                   barcode_scanned barcode_verification,
                   lot lot_verification,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => dt_expiration, i_prof => i_prof) expiration_date
              FROM TABLE(l_tbl_supplies_req) t
             ORDER BY desc_supply;
    
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
    
        g_error := 'get_supply_workflow_lst i_flg_context: ' || i_flg_context || ' i_id_context: ' || i_id_context;
        SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO o_supply_wokflow_lst
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context
           AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_WORKFLOW_LST',
                                              o_error);
            RETURN FALSE;
    END get_supply_workflow_lst;

    FUNCTION get_supply_default_qty
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_supply     IN supply_workflow.id_supply%TYPE,
        i_id_supply_set IN supply_workflow.id_supply_set%TYPE,
        i_id_context_m  IN table_varchar DEFAULT NULL,
        i_id_context_p  IN table_varchar DEFAULT NULL
    ) RETURN supply_workflow.quantity%TYPE IS
        l_error    t_error_out;
        l_quantity supply_workflow.quantity%TYPE;
    BEGIN
        IF (cardinality(i_id_context_p) > 0)
        THEN
            IF (i_id_supply_set IS NOT NULL)
            THEN
                SELECT MAX(decode(nvl(sr.quantity, s.quantity), 0, 1, nvl(sr.quantity, s.quantity)))
                  INTO l_quantity
                  FROM supply_context s
                  JOIN supply_relation sr
                    ON sr.id_supply = s.id_supply
                 WHERE s.id_supply = i_id_supply_set
                   AND s.flg_context = pk_supplies_constant.g_context_procedure_req
                   AND sr.id_supply_item = i_id_supply
                   AND nvl(s.id_institution, 0) IN (i_prof.institution, 0)
                   AND nvl(s.id_software, 0) IN (i_prof.software, 0)
                   AND nvl(s.id_professional, 0) IN (i_prof.id, 0)
                   AND s.id_context IN (SELECT column_value
                                          FROM TABLE(i_id_context_p));
            ELSE
                SELECT MAX(s.quantity)
                  INTO l_quantity
                  FROM supply_context s
                 WHERE s.id_supply = i_id_supply
                   AND s.flg_context = pk_supplies_constant.g_context_procedure_req
                   AND nvl(s.id_institution, 0) IN (i_prof.institution, 0)
                   AND nvl(s.id_software, 0) IN (i_prof.software, 0)
                   AND nvl(s.id_professional, 0) IN (i_prof.id, 0)
                   AND s.id_context IN (SELECT column_value
                                          FROM TABLE(i_id_context_p));
            
            END IF;
        END IF;
        IF (l_quantity IS NULL AND cardinality(i_id_context_m) > 0)
        THEN
            IF (i_id_supply_set IS NOT NULL)
            THEN
                SELECT MAX(decode(nvl(sr.quantity, s.quantity), 0, 1, nvl(sr.quantity, s.quantity)))
                  INTO l_quantity
                  FROM supply_context s
                  JOIN supply_relation sr
                    ON sr.id_supply = s.id_supply
                 WHERE s.id_supply = i_id_supply_set
                   AND s.flg_context = pk_supplies_constant.g_context_medication
                   AND sr.id_supply_item = i_id_supply
                   AND nvl(s.id_institution, 0) IN (i_prof.institution, 0)
                   AND nvl(s.id_software, 0) IN (i_prof.software, 0)
                   AND nvl(s.id_professional, 0) IN (i_prof.id, 0)
                   AND s.id_context IN (SELECT column_value
                                          FROM TABLE(i_id_context_m));
            ELSE
                SELECT MAX(s.quantity)
                  INTO l_quantity
                  FROM supply_context s
                 WHERE s.id_supply = i_id_supply
                   AND s.flg_context = pk_supplies_constant.g_context_medication
                   AND nvl(s.id_institution, 0) IN (i_prof.institution, 0)
                   AND nvl(s.id_software, 0) IN (i_prof.software, 0)
                   AND nvl(s.id_professional, 0) IN (i_prof.id, 0)
                   AND s.id_context IN (SELECT column_value
                                          FROM TABLE(i_id_context_m));
            END IF;
        END IF;
    
        IF (l_quantity IS NULL)
        THEN
            g_error := 'get_supply_default_qty. i_id_supply: ' || i_id_supply;
            SELECT MAX(ssi.quantity)
              INTO l_quantity
              FROM supply_soft_inst ssi
             WHERE ssi.id_institution IN (i_prof.institution, 0)
               AND ssi.id_software IN (i_prof.software, 0)
               AND nvl(ssi.id_professional, 0) IN (i_prof.id, 0)
               AND ssi.id_supply = i_id_supply;
        END IF;
    
        RETURN l_quantity;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_DEFAULT_QTY',
                                              l_error);
            RETURN NULL;
    END get_supply_default_qty;

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
        l_supply_workflow_inact table_number := table_number();
        l_rows_upd              table_varchar := table_varchar();
    
        l_flg_status supply_workflow.flg_status%TYPE;
    
    BEGIN
        --1-Inativate the supplies previously associated to this context that do not come from ux layer any more
        --Only updates records in the inicial states generated in the pharmacy dispense
        --, if some action was already performed in the supplies deepnav
        --do not set the record in the 'updated' status
        SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO l_supply_workflow_inact
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context
           AND sw.flg_status IN (pk_supplies_constant.g_sww_transport_concluded,
                                 pk_supplies_constant.g_sww_loaned,
                                 pk_supplies_constant.g_sww_consumed)
           AND sw.id_supply_workflow NOT IN (SELECT column_value
                                               FROM TABLE(i_supply_workflow));
    
        FOR j IN 1 .. l_supply_workflow_inact.count
        LOOP
            g_error := 'CALL pk_supplies_core.SET_SUPPLY_WORKFLOW_HIST';
            pk_supplies_utils.set_supply_workflow_hist(l_supply_workflow_inact(j), NULL, NULL);
        
            g_error := 'GET STATUS';
            SELECT sw.flg_status
              INTO l_flg_status
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = l_supply_workflow_inact(j);
        
            g_error := 'UPDATE SUPPLY_WORKFLOW';
            ts_supply_workflow.upd(id_supply_workflow_in => l_supply_workflow_inact(j),
                                   flg_status_in         => pk_supplies_constant.g_sww_updated,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows_upd);
        
            IF l_flg_status <> pk_supplies_constant.g_sww_consumed
            THEN
                pk_ia_event_common.supply_wf_dispense_cancel(i_id_supply_workflow => l_supply_workflow_inact(j));
            ELSE
                pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => l_supply_workflow_inact(j));
            END IF;
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUPPLY_WORKFLOW',
                                          i_rowids     => l_rows_upd,
                                          o_error      => o_error);
        
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
                                              'INACTIVATE_RECORDS_BY_CONTEXT',
                                              o_error);
            RETURN FALSE;
    END inactivate_records_by_context;

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
    
        l_supply_workflow       table_number := table_number();
        l_supply_workflow_inact table_number := table_number();
        l_flg_cons_type         table_varchar := table_varchar();
        l_flg_reusable          table_varchar := table_varchar();
        l_flg_editable          table_varchar := table_varchar();
        l_flg_preparing         table_varchar := table_varchar();
        l_flg_countable         table_varchar := table_varchar();
    
        l_supply_t_number  table_number := table_number();
        l_supply_t_varchar table_varchar := table_varchar();
        l_rows_upd         table_varchar := table_varchar();
    
        l_id_supply          supply_workflow.id_supply_workflow%TYPE;
        l_id_supply_set      supply_workflow.id_supply_set%TYPE;
        l_dt_expiration      pk_translation.t_desc_translation;
        l_quantity           supply_workflow.quantity%TYPE;
        l_sw_barcode_scanned supply_workflow.barcode_scanned%TYPE;
        l_lot                supply_workflow.lot%TYPE;
        l_id_supply_request  supply_workflow.id_supply_request%TYPE;
    
        l_supply             table_number := table_number();
        l_supply_set         table_number := table_number();
        l_supply_qty         table_number := table_number();
        l_supply_lot         table_varchar := table_varchar();
        l_barcode_scanned    table_varchar := table_varchar();
        l_supp_dt_expiration table_varchar := table_varchar();
        l_flg_validation     table_varchar := table_varchar();
        l_flg_consumption    table_varchar := table_varchar();
        l_supp_dt_request    table_varchar := table_varchar();
    
        l_supply_cons          table_number := table_number();
        l_supply_set_cons      table_number := table_number();
        l_supply_qty_cons      table_number := table_number();
        l_supply_lot_cons      table_varchar := table_varchar();
        l_barcode_scanned_cons table_varchar := table_varchar();
        l_dt_expiration_cons   table_varchar := table_varchar();
        l_flg_validation_cons  table_varchar := table_varchar();
        l_supp_dt_request_cons table_varchar := table_varchar();
        l_empty_array_varchar  table_varchar := table_varchar();
    
        l_current_date   pk_translation.t_desc_translation;
        l_supp_dt_return table_varchar := table_varchar();
        l_supply_count   PLS_INTEGER;
    BEGIN
        --1-Inativate the supplies previously associated to this context that do not come from ux layer any more
        --Only updates records in the inicial states generated in the pharmacy dispense
        --, if some action was already performed in the supplies deepnav
        --do not set the record in the 'updated' status
        /*SELECT sw.id_supply_workflow
          BULK COLLECT
          INTO l_supply_workflow_inact
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context
           AND sw.flg_status IN (pk_supplies_constant.g_sww_transport_concluded,
                                 pk_supplies_constant.g_sww_loaned,
                                 pk_supplies_constant.g_sww_consumed)
           AND sw.id_supply_workflow NOT IN (SELECT column_value
                                               FROM TABLE(i_supply_workflow));
        
        FOR j IN 1 .. l_supply_workflow_inact.count
        LOOP
            g_error := 'CALL pk_supplies_core.SET_SUPPLY_WORKFLOW_HIST';
            pk_supplies_utils.set_supply_workflow_hist(l_supply_workflow_inact(j), NULL, NULL);
        
            g_error := 'UPDATE SUPPLY_WORKFLOW';
            ts_supply_workflow.upd(id_supply_workflow_in => l_supply_workflow_inact(j),
                                   flg_status_in         => pk_supplies_constant.g_sww_updated,
                                   dt_supply_workflow_in => g_sysdate_tstz,
                                   rows_out              => l_rows_upd);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUPPLY_WORKFLOW',
                                          i_rowids     => l_rows_upd,
                                          o_error      => o_error);
        
        END LOOP;*/
    
        g_error := 'Call inactivate_records_by_context';
        IF NOT inactivate_records_by_context(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_episode         => i_episode,
                                             i_supply_workflow => i_supply_workflow,
                                             i_id_context      => i_id_context,
                                             i_flg_context     => i_flg_context,
                                             o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --2-For the records that still are associated to the context that are not new, check if they were updated.
        --If not, mantain them as they are. Otherwise update them
        IF (cardinality(i_supply_workflow) > 0)
        THEN
            l_current_date := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                          i_date => current_timestamp,
                                                          i_prof => i_prof);
            FOR i IN 1 .. i_supply_workflow.count
            LOOP
                --check if the supply workflow was edited
                g_error := 'check if the supply workflow was edited';
                SELECT sw.id_supply,
                       sw.id_supply_set,
                       pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => sw.dt_expiration, i_prof => i_prof),
                       sw.quantity,
                       sw.barcode_scanned,
                       sw.lot,
                       sw.id_supply_request
                  INTO l_id_supply,
                       l_id_supply_set,
                       l_dt_expiration,
                       l_quantity,
                       l_sw_barcode_scanned,
                       l_lot,
                       l_id_supply_request
                  FROM supply_workflow sw
                 WHERE sw.id_supply_workflow = i_supply_workflow(i);
            
                IF (l_id_supply = i_supply(i) AND
                   (l_id_supply_set = i_supply_set(i) OR (l_id_supply_set IS NULL AND i_supply_set(i) IS NULL)) AND
                   (l_dt_expiration = i_dt_expiration(i) OR (l_dt_expiration IS NULL AND i_dt_expiration(i) IS NULL)) AND
                   l_quantity = i_supply_qty(i) AND (l_sw_barcode_scanned = i_barcode_scanned(i) OR
                   (l_sw_barcode_scanned IS NULL AND i_barcode_scanned(i) IS NULL)) AND
                   (l_lot = i_supply_lot(i) OR (l_lot IS NULL AND i_supply_lot(i) IS NULL)))
                THEN
                    IF (i_flg_consumption(i) = 'Y' AND l_id_supply_request IS NULL)
                    THEN
                        --no changes
                        CONTINUE;
                    ELSIF (i_flg_consumption(i) = 'N' AND l_id_supply_request IS NOT NULL)
                    THEN
                        --no changes
                        CONTINUE;
                    ELSE
                        --record was changed from dispensed to consumed or from consumed to dispensed
                        --inativate it and create a new one
                        g_error := 'CALL pk_supplies_core.SET_SUPPLY_WORKFLOW_HIST';
                        pk_supplies_utils.set_supply_workflow_hist(i_supply_workflow(i), NULL, NULL);
                    
                        g_error := 'UPDATE SUPPLY_WORKFLOW';
                        ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow(i),
                                               flg_status_in         => pk_supplies_constant.g_sww_updated,
                                               dt_supply_workflow_in => g_sysdate_tstz,
                                               rows_out              => l_rows_upd);
                    
                        g_error := 'CALL t_data_gov_mnt.process_update';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUPPLY_WORKFLOW',
                                                      i_rowids     => l_rows_upd,
                                                      o_error      => o_error);
                    
                        IF (i_flg_consumption(i) = pk_alert_constant.g_no)
                        THEN
                            l_supply.extend;
                            l_supply_set.extend;
                            l_supply_qty.extend;
                            l_supply_lot.extend;
                            l_barcode_scanned.extend;
                            l_supp_dt_expiration.extend;
                            --l_flg_consumption.extend;
                            l_flg_validation.extend;
                            l_supp_dt_request.extend;
                            l_supp_dt_return.extend;
                        
                            l_supply(l_supply.last) := i_supply(i);
                            l_supply_set(l_supply_set.last) := i_supply_set(i);
                            l_supply_qty(l_supply_qty.last) := i_supply_qty(i);
                            l_supply_lot(l_supply_lot.last) := i_supply_lot(i);
                            l_barcode_scanned(l_barcode_scanned.last) := i_barcode_scanned(i);
                            l_supp_dt_expiration(l_supp_dt_expiration.last) := i_dt_expiration(i);
                            l_flg_validation(l_flg_validation.last) := i_flg_validation(i);
                            l_supp_dt_request(l_supp_dt_request.last) := l_current_date;
                            l_supp_dt_return(l_supp_dt_return.last) := NULL;
                        ELSE
                            l_supply_cons.extend;
                            l_supply_set_cons.extend;
                            l_supply_qty_cons.extend;
                            l_supply_lot_cons.extend;
                            l_barcode_scanned_cons.extend;
                            l_dt_expiration_cons.extend;
                            --l_flg_consumption.extend;
                            l_flg_validation_cons.extend;
                            l_supp_dt_request_cons.extend;
                            --l_supp_dt_return_cons.extend;
                        
                            l_supply_cons(l_supply_cons.last) := i_supply(i);
                            l_supply_set_cons(l_supply_set_cons.last) := i_supply_set(i);
                            l_supply_qty_cons(l_supply_qty_cons.last) := i_supply_qty(i);
                            l_supply_lot_cons(l_supply_lot_cons.last) := i_supply_lot(i);
                            l_barcode_scanned_cons(l_barcode_scanned_cons.last) := i_barcode_scanned(i);
                            l_dt_expiration_cons(l_dt_expiration_cons.last) := i_dt_expiration(i);
                            l_flg_validation_cons(l_flg_validation_cons.last) := i_flg_validation(i);
                            l_supp_dt_request_cons(l_supp_dt_request_cons.last) := l_current_date;
                            --l_supp_dt_return_cons(l_supp_dt_return_cons.last) := NULL;
                        END IF;
                    END IF;
                ELSE
                    --some field in the screen was updated, barcode, lot, quantity, expiration date
                    g_error := 'CALL pk_supplies_core.SET_SUPPLY_WORKFLOW_HIST';
                    pk_supplies_utils.set_supply_workflow_hist(i_supply_workflow(i), NULL, NULL);
                
                    g_error := 'UPDATE SUPPLY_WORKFLOW';
                    ts_supply_workflow.upd(id_supply_workflow_in => i_supply_workflow(i),
                                           --flg_status_in         => pk_supplies_constant.g_sww_updated,
                                           quantity_in           => i_supply_qty(i),
                                           lot_in                => i_supply_lot(i),
                                           barcode_scanned_in    => i_barcode_scanned(i),
                                           dt_expiration_in      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_dt_expiration(i),
                                                                                                  pk_date_utils.get_timezone(i_lang,
                                                                                                                             i_prof)),
                                           dt_supply_workflow_in => g_sysdate_tstz,
                                           rows_out              => l_rows_upd);
                
                    g_error := 'CALL t_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SUPPLY_WORKFLOW',
                                                  i_rowids     => l_rows_upd,
                                                  o_error      => o_error);
                END IF;
            
            END LOOP;
        
            IF (cardinality(l_supply) > 0)
            THEN
                --create the records in status ready from consumption
                g_error := 'CALL PK_SUPPLIES_API_DB.create_supply_order';
                IF NOT pk_supplies_api_db.create_supply_order(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_episode           => i_episode,
                                                              i_supply            => l_supply,
                                                              i_supply_set        => l_supply_set,
                                                              i_supply_qty        => l_supply_qty,
                                                              i_dt_request        => l_supp_dt_request,
                                                              i_dt_return         => l_supp_dt_return,
                                                              i_id_context        => i_id_context,
                                                              i_flg_context       => i_flg_context,
                                                              i_supply_flg_status => 'P',
                                                              i_lot               => l_supply_lot,
                                                              i_barcode_scanned   => l_barcode_scanned,
                                                              i_dt_expiration     => l_supp_dt_expiration,
                                                              i_flg_validation    => l_flg_validation,
                                                              o_supply_request    => o_supply_request,
                                                              o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            --supply consumptions
            l_supply_count := cardinality(l_supply_cons);
            IF l_supply_count > 0
            THEN
                l_empty_array_varchar.extend(l_supply_count);
                l_supply_workflow.extend(l_supply_count);
                g_error := 'Call pk_supplies_api_db.set_supply_consumption';
                IF NOT pk_supplies_api_db.set_supply_consumption(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_episode         => i_episode,
                                                                 i_id_context         => i_id_context,
                                                                 i_flg_context        => i_flg_context,
                                                                 i_id_supply_workflow => l_supply_workflow,
                                                                 i_supply             => l_supply_cons,
                                                                 i_supply_set         => l_supply_set_cons,
                                                                 i_supply_qty         => l_supply_qty_cons,
                                                                 i_flg_supply_type    => i_flg_supply_type,
                                                                 i_barcode_scanned    => l_barcode_scanned_cons,
                                                                 i_fixed_asset_number => NULL,
                                                                 i_deliver_needed     => i_deliver_needed,
                                                                 i_flg_cons_type      => i_flg_cons_type,
                                                                 i_notes              => l_empty_array_varchar,
                                                                 i_dt_expected_date   => NULL,
                                                                 i_check_quantities   => pk_alert_constant.g_no,
                                                                 i_dt_expiration      => l_dt_expiration_cons,
                                                                 i_flg_validation     => l_flg_validation_cons,
                                                                 i_lot                => l_supply_lot_cons,
                                                                 o_error              => o_error)
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
                                              'UPDATE_SUPPLY_RECORD',
                                              o_error);
            RETURN FALSE;
    END update_supply_record;

    FUNCTION check_supplies_not_in_inicial_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN supply_request.flg_context%TYPE,
        i_id_context       IN supply_workflow.id_context%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
        l_count PLS_INTEGER := 0;
    BEGIN
        g_error := 'CHECK_SUPPLIES_NOT_IN_INICIAL_STATUS. i_id_context: ' || i_id_context || ' i_flg_context:' ||
                   i_flg_context;
        SELECT COUNT(1)
          INTO l_count
          FROM supply_workflow sw
         WHERE sw.id_context = i_id_context
           AND sw.flg_context = i_flg_context
           AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
              /*AND (sw.flg_status != pk_supplies_constant.g_sww_cancelled OR
              (sw.flg_status = pk_supplies_constant.g_sww_cancelled AND sw.id_cancel_reason != i_id_cancel_reason))*/
           AND ((sw.id_supply_request IS NULL AND
               sw.flg_status NOT IN (pk_supplies_constant.g_sww_consumed, pk_supplies_constant.g_sww_loaned)) OR
               (sw.id_supply_request IS NOT NULL AND
               sw.flg_status NOT IN (pk_supplies_constant.g_sww_transport_concluded)));
    
        IF (l_count > 0)
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SUPPLIES_NOT_IN_INICIAL_STATUS',
                                              l_error);
            RETURN NULL;
    END check_supplies_not_in_inicial_status;

    FUNCTION inactivate_supplies_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config('INACTIVATE_CANCEL_REASON', i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(NULL,
                                                                                    profissional(0, i_inst, 0),
                                                                                    'SUPPLIES_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_supply_workflow table_number;
        l_final_status    table_varchar;
    
        l_tbl_error_ids table_number := table_number();
    
        l_rows_out table_varchar;
    
        l_error t_error_out;
    
        --The cursor will not fetch the records for the ids (id_exam_req_det) sent in i_ids_exclude
        CURSOR c_supply_workflow(ids_exclude IN table_number) IS
            SELECT sw.id_supply_workflow, cfg.field_04 final_status
              FROM supply_workflow sw
              JOIN episode e
                ON e.id_episode = sw.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = sw.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = sw.id_supply_workflow
             WHERE e.id_institution = i_inst
               AND (e.dt_end_tstz IS NOT NULL AND
                   (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                     pk_date_utils.add_to_ltstz(e.dt_end_tstz,
                                                                                cfg.field_02,
                                                                                cfg.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp))
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
    BEGIN
    
        OPEN c_supply_workflow(i_ids_exclude);
        FETCH c_supply_workflow BULK COLLECT
            INTO l_supply_workflow, l_final_status;
        CLOSE c_supply_workflow;
    
        o_has_error := FALSE;
    
        IF l_supply_workflow.count > 0
        THEN
            FOR i IN 1 .. l_supply_workflow.count
            LOOP
                CASE l_final_status(i)
                    WHEN pk_exam_constant.g_exam_cancel THEN
                        SAVEPOINT init_cancel;
                        IF NOT pk_supplies_core.cancel_supply_order(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_supplies         => table_number(l_supply_workflow(i)),
                                                                    i_id_prof_cancel   => NULL,
                                                                    i_cancel_notes     => NULL,
                                                                    i_id_cancel_reason => l_cancel_id,
                                                                    i_dt_cancel        => NULL,
                                                                    o_error            => o_error)
                        THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_exam_req_det, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_exam_req_det that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_EXAM_EXTERNAL.CANCEL_EXAM_TASK FOR RECORD ' ||
                                       l_supply_workflow(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_SUPPLIES_TASKS',
                                                              o_error);
                        
                            --The array for the ids (id_exam_req_det) that raised the error is incremented
                            l_tbl_error_ids.extend();
                            l_tbl_error_ids(l_tbl_error_ids.count) := l_supply_workflow(i);
                        
                            CONTINUE;
                        END IF;
                END CASE;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_exam_req_det has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_exam_req_det) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_supplies_external.inactivate_supplies_tasks(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_inst        => i_inst,
                                                                      i_ids_exclude => i_ids_exclude,
                                                                      o_has_error   => o_has_error,
                                                                      o_error       => o_error)
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
                                              'INACTIVATE_SUPPLIES_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_supplies_tasks;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_supplies_external;
/
