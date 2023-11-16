CREATE OR REPLACE PACKAGE BODY pk_cpoe IS

    -- Purpose : Computerized Prescription Order Entry (CPOE) database package

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    e_next_presc_wo_active_presc EXCEPTION;

    -- task bounds, according to start timestamps vs cpoe process timestamps
    g_task_bound_out        CONSTANT VARCHAR2(1) := 'O'; -- timestamps out of bounds for this task
    g_task_bound_no_presc   CONSTANT VARCHAR2(1) := 'N'; -- no prescription needed for this task
    g_task_bound_curr_presc CONSTANT VARCHAR2(1) := 'C'; -- task belongs to current process    
    g_task_bound_next_presc CONSTANT VARCHAR2(1) := 'X'; -- task belongs to next process   

    -- timestamp thresholds
    g_tstz_create_threshold        CONSTANT NUMBER := 30 / 1440; -- to remove 30 minutes from current_timestamp to avoid blocked task creations in new cpoe processes
    g_tstz_presc_limit_threshold   CONSTANT NUMBER := 1 / 86400; -- to remove 1 second in prescription end limit
    g_hour_without_planning_period CONSTANT NUMBER := 3;

    /********************************************************************************************
    * function to return the contents of a professional structure in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a professional structure in a string 
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_prof_str(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        IF i_prof IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
        END IF;
    END get_prof_str;

    /********************************************************************************************
    * function to return the contents of a table number in a string
    *
    * @param       i_table                table_number
    *   
    * @return      varchar2               the contents of a table number in a string 
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabnum_str(i_table IN table_number) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'table_number(' || pk_utils.concat_table(i_tab => i_table, i_delim => ',') || ')';
        END IF;
    END get_tabnum_str;

    /********************************************************************************************
    * function to return the contents of a table varchar in a string
    *
    * @param       i_table                table_varchar
    *   
    * @return      varchar2               the contents of a table varchar in a string
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabvar_str(i_table IN table_varchar) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'table_varchar(' || pk_utils.concat_table(i_tab => i_table, i_delim => ',') || ')';
        END IF;
    END get_tabvar_str;

    /********************************************************************************************
    * function to return the contents of a table varchar in a string
    *
    * @param       i_table                table_varchar
    *   
    * @return      varchar2               the contents of a table varchar in a string
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabtsz_str(i_table IN table_timestamp_tstz) RETURN VARCHAR2 IS
        l_table_aux table_varchar := table_varchar();
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            FOR i IN 1 .. i_table.count
            LOOP
                l_table_aux.extend;
                l_table_aux(i) := to_char(i_table(i));
            END LOOP;
            RETURN 'table_timestamp_tstz(' || pk_utils.concat_table(i_tab => l_table_aux, i_delim => ',') || ')';
        END IF;
    END get_tabtsz_str;

    /********************************************************************************************
    * function to return the contents of a t_tbl_cpoe_task_req collection in a string
    *
    * @param      i_tbl_cpoe_task_req     t_tbl_cpoe_process_tasks collection
    *   
    * @return     varchar2                the contents of a t_tbl_cpoe_task_req collection in a string
    *
    * @author                             Carlos Loureiro
    * @since                              31-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tbl_cpoe_task_req_str(i_tbl_cpoe_task_req IN t_tbl_cpoe_task_req) RETURN VARCHAR2 IS
        l_rec t_rec_cpoe_task_req;
        l_str VARCHAR2(4000);
    BEGIN
        IF i_tbl_cpoe_task_req IS NULL
        THEN
            l_str := NULL;
        ELSIF i_tbl_cpoe_task_req.count = 0
        THEN
            l_str := 't_tbl_cpoe_task_req()';
        ELSE
            l_str := 't_tbl_cpoe_task_req(';
            FOR i IN 1 .. i_tbl_cpoe_task_req.count
            LOOP
                l_rec := i_tbl_cpoe_task_req(i);
                l_str := l_str || 't_rec_cpoe_task_req(' || l_rec.id_task_type || ',' || l_rec.id_request || ',''' ||
                         l_rec.flg_status || '''),';
            END LOOP;
            l_str := substr(l_str, 1, length(l_str) - 1) || ')'; -- it removes the last comma and close the collection
        END IF;
        RETURN l_str;
    END get_tbl_cpoe_task_req_str;

    /********************************************************************************************
    * process current cpoe counter   
    *
    * @param       i_task_types           array of task types associated with the current cpoe
    * @param       i_task_requests        array of task requests associated with the current cpoe
    * @param       i_task_type            id of cpoe task type
    * @param       i_task_request         id of the task request
    * @param       o_flg_current          flag that indicates if task belongs to the current prescription
    *
    * @author                             Carlos Loureiro
    * @since                              2009/11/24
    ********************************************************************************************/
    PROCEDURE process_current_counter
    (
        i_task_types         IN table_number,
        i_task_requests      IN table_number,
        i_task_cpoe_status   IN table_varchar,
        i_task_type          IN cpoe_task_type.id_task_type%TYPE,
        i_task_request       IN cpoe_process_task.id_task_request%TYPE,
        i_prescription_tasks IN t_tbl_cpoe_task_req,
        o_flg_current        OUT VARCHAR2,
        o_flg_next           OUT VARCHAR2
    ) IS
    
    BEGIN
        -- check if task is in current cpoe task arrays
        o_flg_current := pk_alert_constant.g_no; -- assume that task is not in current cpoe process
    
        /*IF i_task_types IS NOT NULL
           AND i_task_types.count != 0
        THEN
            FOR i IN i_task_types.first .. i_task_types.last
            LOOP
                IF i_task_type = i_task_types(i)
                   AND i_task_request = i_task_requests(i)
                THEN
                    IF i_task_cpoe_status(i) != g_flg_status_n THEN
                        o_flg_current := pk_alert_constant.g_yes; -- task is in current cpoe process
                    ELSE
                       o_flg_next := pk_alert_constant.g_yes;
                    END IF;
                    --EXIT; -- exit loop
                END IF;
            END LOOP;
        END IF;*/
    
        -- check if task is in current or next cpoe process
        o_flg_current := pk_alert_constant.g_no; -- assume that task is not in current cpoe process
        o_flg_next    := pk_alert_constant.g_no; -- assume that task is not in next cpoe process
    
        IF i_prescription_tasks IS NOT NULL
           AND i_prescription_tasks.count != 0
        THEN
            FOR i IN 1 .. i_prescription_tasks.count
            LOOP
                IF i_task_type = i_prescription_tasks(i).id_task_type
                   AND i_task_request = i_prescription_tasks(i).id_request
                THEN
                    IF i_prescription_tasks(i).flg_status != g_flg_status_n
                    THEN
                        -- assume this task type/request belongs to the current cpoe process
                        o_flg_current := pk_alert_constant.g_yes; -- task is in current cpoe process
                    ELSE
                        o_flg_next := pk_alert_constant.g_yes; -- task is in next cpoe process
                    END IF;
                    -- the following "exit" was removed to allow same task requests in current and next prescriptions simultaneously
                    -- EXIT; -- exit loop - record was found
                END IF;
            END LOOP;
        END IF;
    
    END process_current_counter;

    /********************************************************************************************
    * get all tasks lists by type 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_task_type               cpoe task type id
    * @param       i_flg_report              indicates if task list APIs should return additional report fields
    * @param       o_task_list               task list
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @value       i_flg_report              {*} 'Y' additional report columns should be considered by task list APIs
    *                                        {*} 'N' additional report columns should be discarded by task list    
    *
    * @author                                Carlos Loureiro
    * @since                                 25-OCT-2009
    ********************************************************************************************/
    FUNCTION get_task_list_by_type
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_process_tasks           IN t_tbl_cpoe_task_req,
        i_closed_task_filter_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_task_type               IN cpoe_task_type.id_task_type%TYPE,
        i_flg_report              IN VARCHAR2,
        i_tab_type                IN VARCHAR2,
        i_process                 IN cpoe_process.id_cpoe_process%TYPE,
        i_task_ids                IN table_number DEFAULT NULL,
        i_task_type_ids           IN table_number DEFAULT NULL,
        i_dt_start                IN VARCHAR2 DEFAULT NULL,
        i_dt_end                  IN VARCHAR2 DEFAULT NULL,
        o_task_list               OUT pk_types.cursor_type,
        o_execution               OUT pk_types.cursor_type,
        o_med_admin               OUT pk_types.cursor_type,
        o_proc_plan               OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tn_reqs table_number; -- table of requests to hold specific process tasks (null to get all tasks available)
        l_exception EXCEPTION;
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_flg_cpoe_status cpoe_process.flg_status%TYPE;
        l_id_professional cpoe_process.id_professional%TYPE;
    
        -- get target status values for a given task type
        FUNCTION get_closed_task_status_filter RETURN table_varchar IS
            l_return_status table_varchar;
        BEGIN
            SELECT flg_status
              BULK COLLECT
              INTO l_return_status
              FROM cpoe_task_type_status_filter
             WHERE id_task_type = i_task_type
               AND flg_filter_tab IN (g_filter_cancelled, g_filter_inactive);
            RETURN l_return_status;
        END get_closed_task_status_filter;
    
        -- get an array with all requests from a given task type
        FUNCTION get_requests_by_task_type RETURN table_number IS
            l_tn_requests table_number := table_number();
            l_task_type   table_number := table_number();
        BEGIN
        
            IF i_task_type_ids IS NOT NULL
               AND i_task_type_ids.count > 0
            THEN
            
                IF i_task_type = g_task_type_diet
                THEN
                    l_task_type := table_number(g_task_type_diet_inst,
                                                g_task_type_diet_spec,
                                                g_task_type_diet_predefined);
                ELSIF i_task_type = g_task_type_hidric
                THEN
                    l_task_type := table_number(g_task_type_hidric_in_out,
                                                g_task_type_hidric_out,
                                                g_task_type_hidric_drain,
                                                g_task_type_hidric_in,
                                                g_task_type_hidric_out_all,
                                                g_task_type_hidric_irrigations);
                ELSE
                    l_task_type := table_number(i_task_type);
                END IF;
            
                FOR i IN 1 .. i_task_type_ids.count
                LOOP
                    FOR j IN 1 .. l_task_type.count
                    LOOP
                        IF i_task_type_ids(i) = l_task_type(j)
                        THEN
                            l_tn_requests.extend;
                            l_tn_requests(l_tn_requests.count) := i_task_ids(i);
                        END IF;
                    END LOOP;
                END LOOP;
            
                /*IF l_tn_requests.count = 0
                THEN
                    RETURN NULL;
                END IF;*/
                RETURN l_tn_requests;
            ELSE
            
                IF i_process_tasks IS NOT NULL
                THEN
                    SELECT req.id_request
                      BULK COLLECT
                      INTO l_tn_requests
                      FROM TABLE(CAST(i_process_tasks AS t_tbl_cpoe_task_req)) req
                     WHERE req.id_task_type = i_task_type;
                    RETURN l_tn_requests;
                ELSE
                    RETURN NULL;
                END IF;
            END IF;
        END get_requests_by_task_type;
    
    BEGIN
    
        pk_types.open_cursor_if_closed(o_med_admin);
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.get_task_list_by_type called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_patient=' || i_patient ||
                                  chr(10) || 'i_episode=' || i_episode || chr(10) || 'i_process_tasks=' ||
                                  get_tbl_cpoe_task_req_str(i_process_tasks) || chr(10) ||
                                  'i_closed_task_filter_tstz=' || i_closed_task_filter_tstz || chr(10) ||
                                  'i_task_type=' || i_task_type || chr(10) || chr(10) || 'context info:' || chr(10) ||
                                  'get_closed_task_status_filter()=' ||
                                  get_tabvar_str(get_closed_task_status_filter()),
                                  g_package_name);
        END IF;
    
        IF i_process IS NOT NULL
        THEN
            SELECT a.dt_cpoe_proc_start, a.dt_cpoe_proc_end
              INTO l_start_date, l_end_date
              FROM cpoe_process a
             WHERE a.id_cpoe_process = i_process;
        ELSE
        
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_start_date,
                                      l_end_date,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            /*IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_start_date,
                                                     o_error         => o_error)
            THEN
                l_start_date := current_timestamp;
            END IF;
            
            l_end_date := pk_date_utils.add_days_to_tstz(i_timestamp => current_timestamp, i_days => 1);*/
        
        END IF;
    
        -- for given task type    
        CASE i_task_type
        -- #######################################
        -- ## NOTES ABOUT THIS PROCESSING BLOCK ##
        -- #######################################
        -- all task types are processed following this behavior:
        -- if get_requests_by_task_type() returns a null array, then the API should be called to get all available tasks
        -- if get_requests_by_task_type() returns a non-null array with requests, then the API should return only that requests 
        -- if get_requests_by_task_type() returns a non-null array with zero elements, then the API should never be called
        
            WHEN g_task_type_monitorization THEN
                -- get monitorization tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type(); -- if l_tn_reqs is null, then get all available tasks
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any monitorization tasks inside
                ELSE
                    IF NOT pk_monitorization.get_task_list(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_patient       => i_patient,
                                                      i_episode       => i_episode,
                                                      i_task_request  => l_tn_reqs, -- 'null' l_tn_reqs gets all available monitorizations
                                                      i_filter_tstz   => CASE
                                                                             WHEN l_tn_reqs IS NULL THEN
                                                                              i_closed_task_filter_tstz
                                                                             ELSE
                                                                              NULL
                                                                         END,
                                                      i_filter_status => CASE
                                                                             WHEN l_tn_reqs IS NULL THEN
                                                                              get_closed_task_status_filter()
                                                                             ELSE
                                                                              NULL
                                                                         END,
                                                      i_flg_report    => i_flg_report,
                                                      i_dt_begin      => CASE
                                                                             WHEN i_dt_start IS NULL THEN
                                                                              l_start_date
                                                                             ELSE
                                                                              pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL)
                                                                         END,
                                                      i_dt_end        => CASE
                                                                             WHEN i_dt_end IS NULL THEN
                                                                              l_end_date
                                                                             ELSE
                                                                              pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL)
                                                                         END,
                                                      o_plan_list     => o_execution,
                                                      o_grid          => o_task_list,
                                                      o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_positioning THEN
                -- get positioning tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
            
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any positioning tasks inside
                ELSE
                    IF NOT pk_pbl_inp_positioning.get_task_list(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_patient       => i_patient,
                                                           i_episode       => i_episode,
                                                           i_task_request  => l_tn_reqs, -- 'null' l_tn_reqs gets all available positionings
                                                           i_filter_tstz   => CASE
                                                                                  WHEN l_tn_reqs IS NULL THEN
                                                                                   i_closed_task_filter_tstz
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                                           i_filter_status => CASE
                                                                                  WHEN l_tn_reqs IS NULL THEN
                                                                                   get_closed_task_status_filter()
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                                           i_flg_report    => i_flg_report,
                                                           i_dt_begin      => CASE
                                                                                  WHEN i_dt_start IS NULL THEN
                                                                                   l_start_date
                                                                                  ELSE
                                                                                   pk_date_utils.get_string_tstz(i_lang,
                                                                                                                 i_prof,
                                                                                                                 i_dt_start,
                                                                                                                 NULL)
                                                                              END,
                                                           i_dt_end        => CASE
                                                                                  WHEN i_dt_end IS NULL THEN
                                                                                   l_end_date
                                                                                  ELSE
                                                                                   pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL)
                                                                              END,
                                                           o_plan_list     => o_execution,
                                                           o_grid          => o_task_list,
                                                           o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_hidric THEN
                -- get hidric tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any hidric tasks inside
                ELSE
                    IF NOT pk_inp_hidrics_pbl.get_task_list(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_patient       => i_patient,
                                                       i_episode       => i_episode,
                                                       i_task_request  => l_tn_reqs, -- 'null' l_tn_reqs gets all available hidrics
                                                       i_filter_tstz   => CASE
                                                                              WHEN l_tn_reqs IS NULL THEN
                                                                               i_closed_task_filter_tstz
                                                                              ELSE
                                                                               NULL
                                                                          END,
                                                       i_filter_status => CASE
                                                                              WHEN l_tn_reqs IS NULL THEN
                                                                               get_closed_task_status_filter()
                                                                              ELSE
                                                                               NULL
                                                                          END,
                                                       i_flg_report    => i_flg_report,
                                                       i_dt_begin      => CASE
                                                                              WHEN i_dt_start IS NULL THEN
                                                                               l_start_date
                                                                              ELSE
                                                                               pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL)
                                                                          END,
                                                       i_dt_end        => CASE
                                                                              WHEN i_dt_end IS NULL THEN
                                                                               l_end_date
                                                                              ELSE
                                                                               pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL)
                                                                          END,
                                                       o_plan_list     => o_execution,
                                                       o_grid          => o_task_list,
                                                       o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_diet THEN
                -- get diet tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any diet tasks inside
                ELSE
                
                    IF NOT pk_diet.get_task_list(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_patient       => i_patient,
                                            i_episode       => i_episode,
                                            i_task_request  => l_tn_reqs, -- 'null' l_tn_reqs gets all available diets
                                            i_filter_tstz   => CASE
                                                                   WHEN l_tn_reqs IS NULL THEN
                                                                    i_closed_task_filter_tstz
                                                                   ELSE
                                                                    NULL
                                                               END,
                                            i_filter_status => CASE
                                                                   WHEN l_tn_reqs IS NULL THEN
                                                                    get_closed_task_status_filter()
                                                                   ELSE
                                                                    NULL
                                                               END,
                                            i_flg_report    => i_flg_report,
                                            i_dt_begin      => CASE
                                                                   WHEN i_dt_start IS NULL THEN
                                                                    l_start_date
                                                                   ELSE
                                                                    pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL)
                                                               END,
                                            i_dt_end        => CASE
                                                                   WHEN i_dt_end IS NULL THEN
                                                                    l_end_date
                                                                   ELSE
                                                                    pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL)
                                                               END,
                                            o_plan_list     => o_execution,
                                            o_task_list     => o_task_list,
                                            o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            
            WHEN g_task_type_procedure THEN
                -- get procedure tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any procedure tasks inside
                ELSE
                    IF NOT pk_procedures_external_api_db.get_cpoe_task_list(i_lang          => i_lang,
                                                                       i_prof          => i_prof,
                                                                       i_patient       => i_patient,
                                                                       i_episode       => i_episode,
                                                                       i_task_request  => l_tn_reqs, -- 'null' l_tn_reqs gets all available procedures
                                                                       i_filter_tstz   => CASE
                                                                                              WHEN l_tn_reqs IS NULL THEN
                                                                                               i_closed_task_filter_tstz
                                                                                              ELSE
                                                                                               NULL
                                                                                          END,
                                                                       i_filter_status => CASE
                                                                                              WHEN l_tn_reqs IS NULL THEN
                                                                                               get_closed_task_status_filter()
                                                                                              ELSE
                                                                                               NULL
                                                                                          END,
                                                                       i_flg_report    => i_flg_report,
                                                                       i_dt_begin      => CASE
                                                                                              WHEN i_dt_start IS NULL THEN
                                                                                               l_start_date
                                                                                              ELSE
                                                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                                                             i_prof,
                                                                                                                             i_dt_start,
                                                                                                                             NULL)
                                                                                          END,
                                                                       i_dt_end        => CASE
                                                                                              WHEN i_dt_end IS NULL THEN
                                                                                               l_end_date
                                                                                              ELSE
                                                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                                                             i_prof,
                                                                                                                             i_dt_end,
                                                                                                                             NULL)
                                                                                          END,
                                                                       o_plan_list     => o_execution,
                                                                       o_task_list     => o_task_list,
                                                                       o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_analysis THEN
                -- get analysis tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
            
                IF i_task_ids IS NOT NULL
                   AND i_task_ids.count > 0
                   AND l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL;
                ELSIF l_tn_reqs IS NOT NULL
                      AND l_tn_reqs.count = 0
                      AND (task_out_of_cpoe_process(i_lang, i_prof, g_task_type_analysis) = pk_alert_constant.g_no)
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any procedure tasks inside
                ELSE
                    IF NOT pk_lab_tests_external_api_db.get_cpoe_task_list(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_patient         => i_patient,
                                                                      i_episode         => i_episode,
                                                                      i_task_request    => l_tn_reqs, -- 'null' l_tn_reqs gets all available procedures
                                                                      i_filter_tstz     => CASE
                                                                                               WHEN l_tn_reqs IS NULL THEN
                                                                                                i_closed_task_filter_tstz
                                                                                               ELSE
                                                                                                NULL
                                                                                           END,
                                                                      i_filter_status   => CASE
                                                                                               WHEN l_tn_reqs IS NULL THEN
                                                                                                get_closed_task_status_filter()
                                                                                               ELSE
                                                                                                NULL
                                                                                           END,
                                                                      i_flg_out_of_cpoe => task_out_of_cpoe_process(i_lang,
                                                                                                                    i_prof,
                                                                                                                    g_task_type_analysis),
                                                                      i_flg_report      => i_flg_report,
                                                                      i_dt_begin        => CASE
                                                                                               WHEN i_dt_start IS NULL THEN
                                                                                                l_start_date
                                                                                               ELSE
                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                              i_prof,
                                                                                                                              i_dt_start,
                                                                                                                              NULL)
                                                                                           END,
                                                                      i_dt_end          => CASE
                                                                                               WHEN i_dt_end IS NULL THEN
                                                                                                l_end_date
                                                                                               ELSE
                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                              i_prof,
                                                                                                                              i_dt_end,
                                                                                                                              NULL)
                                                                                           END,
                                                                      i_flg_print_items => CASE
                                                                                               WHEN i_task_ids IS NOT NULL
                                                                                                    AND i_task_ids.count > 0 THEN
                                                                                                pk_alert_constant.g_yes
                                                                                               ELSE
                                                                                                pk_alert_constant.g_no
                                                                                           END,
                                                                      i_cpoe_tab        => i_tab_type,
                                                                      o_task_list       => o_task_list,
                                                                      o_plan_list       => o_execution,
                                                                      o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_bp THEN
                -- get image tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
            
                IF i_task_ids IS NOT NULL
                   AND i_task_ids.count > 0
                   AND l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL;
                ELSIF (l_tn_reqs IS NOT NULL AND l_tn_reqs.count = 0 AND
                      (task_out_of_cpoe_process(i_lang, i_prof, g_task_type_bp) = pk_alert_constant.g_no))
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any procedure tasks inside
                ELSE
                    IF NOT pk_bp_external_api_db.get_cpoe_task_list(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_patient         => i_patient,
                                                               i_episode         => i_episode,
                                                               i_task_request    => l_tn_reqs, -- 'null' l_tn_reqs gets all available procedures
                                                               i_filter_tstz     => CASE
                                                                                        WHEN l_tn_reqs IS NULL THEN
                                                                                         i_closed_task_filter_tstz
                                                                                        ELSE
                                                                                         NULL
                                                                                    END,
                                                               i_filter_status   => CASE
                                                                                        WHEN l_tn_reqs IS NULL THEN
                                                                                         get_closed_task_status_filter()
                                                                                        ELSE
                                                                                         NULL
                                                                                    END,
                                                               i_flg_report      => i_flg_report,
                                                               i_dt_begin        => CASE
                                                                                        WHEN i_dt_start IS NULL THEN
                                                                                         l_start_date
                                                                                        ELSE
                                                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                                                       i_prof,
                                                                                                                       i_dt_start,
                                                                                                                       NULL)
                                                                                    END,
                                                               i_dt_end          => CASE
                                                                                        WHEN i_dt_end IS NULL THEN
                                                                                         l_end_date
                                                                                        ELSE
                                                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                                                       i_prof,
                                                                                                                       i_dt_end,
                                                                                                                       NULL)
                                                                                    END,
                                                               i_flg_type        => pk_exam_constant.g_type_img,
                                                               i_flg_out_of_cpoe => task_out_of_cpoe_process(i_lang, i_prof, g_task_type_bp),
                                                               i_flg_print_items => CASE
                                                                                        WHEN i_task_ids IS NOT NULL
                                                                                             AND i_task_ids.count > 0 THEN
                                                                                         pk_alert_constant.g_yes
                                                                                        ELSE
                                                                                         pk_alert_constant.g_no
                                                                                    END,
                                                               o_task_list       => o_task_list,
                                                               o_plan_list       => o_execution,
                                                               o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            WHEN g_task_type_image_exam THEN
                -- get image tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
            
                IF i_task_ids IS NOT NULL
                   AND i_task_ids.count > 0
                   AND l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL;
                ELSIF (l_tn_reqs IS NOT NULL AND l_tn_reqs.count = 0 AND
                      (task_out_of_cpoe_process(i_lang, i_prof, g_task_type_image_exam) = pk_alert_constant.g_no))
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any procedure tasks inside
                ELSE
                    IF NOT pk_exams_external_api_db.get_cpoe_task_list(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_patient         => i_patient,
                                                                  i_episode         => i_episode,
                                                                  i_task_request    => l_tn_reqs, -- 'null' l_tn_reqs gets all available procedures
                                                                  i_filter_tstz     => CASE
                                                                                           WHEN l_tn_reqs IS NULL THEN
                                                                                            i_closed_task_filter_tstz
                                                                                           ELSE
                                                                                            NULL
                                                                                       END,
                                                                  i_filter_status   => CASE
                                                                                           WHEN l_tn_reqs IS NULL THEN
                                                                                            get_closed_task_status_filter()
                                                                                           ELSE
                                                                                            NULL
                                                                                       END,
                                                                  i_flg_report      => i_flg_report,
                                                                  i_dt_begin        => CASE
                                                                                           WHEN i_dt_start IS NULL THEN
                                                                                            l_start_date
                                                                                           ELSE
                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                          i_prof,
                                                                                                                          i_dt_start,
                                                                                                                          NULL)
                                                                                       END,
                                                                  i_dt_end          => CASE
                                                                                           WHEN i_dt_end IS NULL THEN
                                                                                            l_end_date
                                                                                           ELSE
                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                          i_prof,
                                                                                                                          i_dt_end,
                                                                                                                          NULL)
                                                                                       END,
                                                                  i_flg_type        => pk_exam_constant.g_type_img,
                                                                  i_flg_out_of_cpoe => task_out_of_cpoe_process(i_lang,
                                                                                                                i_prof,
                                                                                                                g_task_type_image_exam),
                                                                  i_flg_print_items => CASE
                                                                                           WHEN i_task_ids IS NOT NULL
                                                                                                AND i_task_ids.count > 0 THEN
                                                                                            pk_alert_constant.g_yes
                                                                                           ELSE
                                                                                            pk_alert_constant.g_no
                                                                                       END,
                                                                  i_cpoe_tab        => i_tab_type,
                                                                  o_task_list       => o_task_list,
                                                                  o_plan_list       => o_execution,
                                                                  o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_other_exam THEN
                -- get other exam tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
            
                IF i_task_ids IS NOT NULL
                   AND i_task_ids.count > 0
                   AND l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL;
                ELSIF l_tn_reqs IS NOT NULL
                      AND l_tn_reqs.count = 0
                      AND (task_out_of_cpoe_process(i_lang, i_prof, g_task_type_other_exam) = pk_alert_constant.g_no)
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any procedure tasks inside
                ELSE
                    IF NOT pk_exams_external_api_db.get_cpoe_task_list(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_patient         => i_patient,
                                                                  i_episode         => i_episode,
                                                                  i_task_request    => l_tn_reqs, -- 'null' l_tn_reqs gets all available procedures
                                                                  i_filter_tstz     => CASE
                                                                                           WHEN l_tn_reqs IS NULL THEN
                                                                                            i_closed_task_filter_tstz
                                                                                           ELSE
                                                                                            NULL
                                                                                       END,
                                                                  i_filter_status   => CASE
                                                                                           WHEN l_tn_reqs IS NULL THEN
                                                                                            get_closed_task_status_filter()
                                                                                           ELSE
                                                                                            NULL
                                                                                       END,
                                                                  i_flg_report      => i_flg_report,
                                                                  i_dt_begin        => CASE
                                                                                           WHEN i_dt_start IS NULL THEN
                                                                                            l_start_date
                                                                                           ELSE
                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                          i_prof,
                                                                                                                          i_dt_start,
                                                                                                                          NULL)
                                                                                       END,
                                                                  i_dt_end          => CASE
                                                                                           WHEN i_dt_end IS NULL THEN
                                                                                            l_end_date
                                                                                           ELSE
                                                                                            pk_date_utils.get_string_tstz(i_lang,
                                                                                                                          i_prof,
                                                                                                                          i_dt_end,
                                                                                                                          NULL)
                                                                                       END,
                                                                  i_flg_type        => pk_exam_constant.g_type_exm,
                                                                  i_flg_out_of_cpoe => task_out_of_cpoe_process(i_lang,
                                                                                                                i_prof,
                                                                                                                g_task_type_other_exam),
                                                                  i_flg_print_items => CASE
                                                                                           WHEN i_task_ids IS NOT NULL
                                                                                                AND i_task_ids.count > 0 THEN
                                                                                            pk_alert_constant.g_yes
                                                                                           ELSE
                                                                                            pk_alert_constant.g_no
                                                                                       END,
                                                                  i_cpoe_tab        => i_tab_type,
                                                                  o_task_list       => o_task_list,
                                                                  o_plan_list       => o_execution,
                                                                  o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_nursing THEN
                -- get nursing tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any nursing tasks inside
                ELSE
                    IF NOT pk_patient_education_cpoe.get_task_list(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_patient       => i_patient,
                                                              i_episode       => i_episode,
                                                              i_task_request  => l_tn_reqs, -- 'null' l_tn_reqs gets all available nursings
                                                              i_filter_tstz   => CASE
                                                                                     WHEN l_tn_reqs IS NULL THEN
                                                                                      i_closed_task_filter_tstz
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                              i_filter_status => CASE
                                                                                     WHEN l_tn_reqs IS NULL THEN
                                                                                      get_closed_task_status_filter()
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                              i_flg_report    => i_flg_report,
                                                              i_dt_begin      => CASE
                                                                                     WHEN i_dt_start IS NULL THEN
                                                                                      l_start_date
                                                                                     ELSE
                                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    i_dt_start,
                                                                                                                    NULL)
                                                                                 END,
                                                              i_dt_end        => CASE
                                                                                     WHEN i_dt_end IS NULL THEN
                                                                                      l_end_date
                                                                                     ELSE
                                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    i_dt_end,
                                                                                                                    NULL)
                                                                                 END,
                                                              o_plan_list     => o_execution,
                                                              o_task_list     => o_task_list,
                                                              o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_medication THEN
                -- get medication tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any medication tasks inside
                ELSE
                    IF NOT pk_api_pfh_ordertools_in.get_medication_list_cpoe(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_patient         => i_patient,
                                                                        i_episode         => i_episode,
                                                                        i_task_request    => l_tn_reqs, -- 'null' l_tn_reqs gets all available medication tasks
                                                                        i_filter_tstz     => CASE
                                                                                                 WHEN l_tn_reqs IS NULL THEN
                                                                                                  i_closed_task_filter_tstz
                                                                                                 ELSE
                                                                                                  NULL
                                                                                             END,
                                                                        i_filter_status   => CASE
                                                                                                 WHEN l_tn_reqs IS NULL THEN
                                                                                                  get_closed_task_status_filter()
                                                                                                 ELSE
                                                                                                  NULL
                                                                                             END,
                                                                        i_flg_report      => i_flg_report,
                                                                        i_flg_out_of_cpoe => task_out_of_cpoe_process(i_lang,
                                                                                                                      i_prof,
                                                                                                                      g_task_type_medication),
                                                                        i_dt_begin        => CASE
                                                                                                 WHEN i_dt_start IS NULL THEN
                                                                                                  l_start_date
                                                                                                 ELSE
                                                                                                  pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                i_prof,
                                                                                                                                i_dt_start,
                                                                                                                                NULL)
                                                                                             END,
                                                                        i_dt_end          => CASE
                                                                                                 WHEN i_dt_end IS NULL THEN
                                                                                                  l_end_date
                                                                                                 ELSE
                                                                                                  pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                i_prof,
                                                                                                                                i_dt_end,
                                                                                                                                NULL)
                                                                                             END,
                                                                        o_task_list       => o_task_list,
                                                                        o_admin_list      => o_execution,
                                                                        o_error           => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            
            WHEN g_task_type_com_order THEN
                -- get communication order tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any communication order tasks inside
                ELSE
                
                    IF NOT pk_comm_orders_cpoe.get_comm_order_list(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_patient        => i_patient,
                                                              i_episode        => i_episode,
                                                              i_task_request   => l_tn_reqs, -- 'null' l_tn_reqs gets all available communication order tasks
                                                              i_filter_tstz    => CASE
                                                                                      WHEN l_tn_reqs IS NULL THEN
                                                                                       i_closed_task_filter_tstz
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                              i_filter_status  => CASE
                                                                                      WHEN l_tn_reqs IS NULL THEN
                                                                                       get_closed_task_status_filter()
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                              i_flg_report     => i_flg_report,
                                                              i_cpoe_task_type => g_task_type_com_order,
                                                              i_dt_begin       => CASE
                                                                                      WHEN i_dt_start IS NULL THEN
                                                                                       l_start_date
                                                                                      ELSE
                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_dt_start,
                                                                                                                     NULL)
                                                                                  END,
                                                              i_dt_end         => CASE
                                                                                      WHEN i_dt_end IS NULL THEN
                                                                                       l_end_date
                                                                                      ELSE
                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_dt_end,
                                                                                                                     NULL)
                                                                                  END,
                                                              o_plan_list      => o_execution,
                                                              o_task_list      => o_task_list,
                                                              o_error          => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            WHEN g_task_type_medical_orders THEN
                -- get communication order tasks from given process tasks
                l_tn_reqs := get_requests_by_task_type();
                IF l_tn_reqs IS NOT NULL
                   AND l_tn_reqs.count = 0
                THEN
                    o_task_list := NULL; -- the given i_process_tasks array doesn't have any communication order tasks inside
                ELSE
                
                    IF NOT pk_comm_orders_cpoe.get_comm_order_list(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_patient        => i_patient,
                                                              i_episode        => i_episode,
                                                              i_task_request   => l_tn_reqs, -- 'null' l_tn_reqs gets all available communication order tasks
                                                              i_filter_tstz    => CASE
                                                                                      WHEN l_tn_reqs IS NULL THEN
                                                                                       i_closed_task_filter_tstz
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                              i_filter_status  => CASE
                                                                                      WHEN l_tn_reqs IS NULL THEN
                                                                                       get_closed_task_status_filter()
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                              i_flg_report     => i_flg_report,
                                                              i_cpoe_task_type => g_task_type_medical_orders,
                                                              i_dt_begin       => CASE
                                                                                      WHEN i_dt_start IS NULL THEN
                                                                                       l_start_date
                                                                                      ELSE
                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_dt_start,
                                                                                                                     NULL)
                                                                                  END,
                                                              i_dt_end         => CASE
                                                                                      WHEN i_dt_end IS NULL THEN
                                                                                       l_end_date
                                                                                      ELSE
                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_dt_end,
                                                                                                                     NULL)
                                                                                  END,
                                                              o_plan_list      => o_execution,
                                                              o_task_list      => o_task_list,
                                                              o_error          => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            ELSE
                o_task_list := NULL; -- nothing to return (task type not found in case statement)
        
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
                                              'GET_TASK_LIST_BY_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_task_list_by_type;

    /********************************************************************************************
    * get group task id for a given task type
    *
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      number                    task group type id
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_task_group_id
    (
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN NUMBER IS
        l_task_group_id NUMBER(6);
    BEGIN
        SELECT id_task_group_parent
          INTO l_task_group_id
          FROM (SELECT decode(i_task_type, 46, 46, 51, 51, tsi.id_task_group_parent) id_task_group_parent
                  FROM cpoe_task_soft_inst tsi
                 WHERE tsi.id_task_type = i_task_type
                   AND tsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND tsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                 ORDER BY tsi.id_institution DESC, tsi.id_software DESC)
         WHERE rownum = 1;
        RETURN l_task_group_id;
    END get_task_group_id;

    /********************************************************************************************
    * get group task name for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      varchar2                  task group type name
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_task_group_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_show_out_msg IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
    
        l_msg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CPOE_M037');
    
        l_task_name            pk_translation.t_desc_translation;
        l_task_in_cpoe_process VARCHAR(1 CHAR);
    
    BEGIN
    
        l_task_in_cpoe_process := task_out_of_cpoe_process(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_task_type => i_task_type);
    
        SELECT pk_translation.get_translation(i_lang, tt.code_task_type)
          INTO l_task_name
          FROM cpoe_task_type tt
         WHERE tt.id_task_type = get_task_group_id(i_prof, i_task_type);
        RETURN l_task_name;
    END get_task_group_name;

    /********************************************************************************************
    * get task type name for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      varchar2                  task type name
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_task_type_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_task_type_name pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_translation.get_translation(i_lang, tt.code_task_type)
          INTO l_task_type_name
          FROM cpoe_task_type tt
         WHERE tt.id_task_type = i_task_type;
        RETURN l_task_type_name;
    END get_task_type_name;

    /********************************************************************************************
    * get group task rank for a given task type
    *
    * @param       i_prof           professional id structure
    * @param       i_id_task_type   Task type ID
    *
    * @return      task group type rank
    *
    * @author      Tiago Silva
    * @since       2009/10/28
    ********************************************************************************************/
    FUNCTION get_task_group_rank
    (
        i_prof         IN profissional,
        i_id_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN NUMBER IS
        l_task_type_rank cpoe_task_soft_inst.rank%TYPE;
    BEGIN
    
        g_error := 'Get group task rank';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- group task rank
        SELECT rank
          INTO l_task_type_rank
          FROM (SELECT ctsi.rank
                  FROM cpoe_task_soft_inst ctsi
                 WHERE ctsi.id_task_type = get_task_group_id(i_prof, i_id_task_type)
                   AND ctsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                 ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC)
         WHERE rownum = 1;
    
        -- return task type rank
        RETURN l_task_type_rank;
    
    END get_task_group_rank;

    /********************************************************************************************
    * get task rank for a given task type
    *
    * @param       i_prof           professional id structure
    * @param       i_id_task_type   Task type ID
    *
    * @return      task type rank
    *
    * @author      Tiago Silva
    * @since       2014/01/31
    ********************************************************************************************/
    FUNCTION get_task_type_rank
    (
        i_prof         IN profissional,
        i_id_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN NUMBER IS
        l_task_type_rank cpoe_task_soft_inst.rank%TYPE;
    BEGIN
    
        g_error := 'Get task type rank';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT rank
          INTO l_task_type_rank
          FROM (SELECT ctsi.rank
                  FROM cpoe_task_soft_inst ctsi
                 WHERE ctsi.id_task_type = i_id_task_type
                   AND ctsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                 ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC)
         WHERE rownum = 1;
    
        -- return task type rank
        RETURN l_task_type_rank;
    
    END get_task_type_rank;

    /********************************************************************************************
    * get task type icon name for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      varchar2                  task type icon name
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_task_type_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_task_icon_name cpoe_task_type.icon%TYPE;
    BEGIN
        SELECT icon
          INTO l_task_icon_name
          FROM cpoe_task_type tt
         WHERE tt.id_task_type = i_task_type;
        RETURN l_task_icon_name;
    END get_task_type_icon;

    /********************************************************************************************
    * get all task types that can be requested in CPOE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode
    * @param       i_task_types              task types id of the episode 
    * @param       o_task_type_list_frequent cursor with all task types (for most frequent search)
    * @param       o_task_type_list_search   cursor with all task types (for advanced search)
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/19
    ********************************************************************************************/
    FUNCTION get_task_type_list
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_task_types              IN table_number,
        i_filter                  IN VARCHAR2,
        o_task_type_list_frequent OUT pk_types.cursor_type,
        o_task_type_list_search   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        l_task_type_out_proc    VARCHAR2(1 CHAR);
        l_task_type_in_proc     VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_flg_profile           profile_template.flg_profile%TYPE;
        l_task_type_next_active VARCHAR2(1 CHAR);
        l_can_req_next          VARCHAR2(1 CHAR);
    
    BEGIN
        g_error := 'call get_cpoe_mode';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        l_can_req_next := check_next_presc_can_req(i_lang, i_prof, i_episode);
    
        IF l_can_req_next = pk_alert_constant.g_no
           AND i_filter = pk_cpoe.g_filter_next
        THEN
            l_task_type_next_active := pk_alert_constant.g_no;
        END IF;
    
        -- flg for task types 
        FOR i IN 1 .. i_task_types.count
        LOOP
            l_task_type_out_proc := task_out_of_cpoe_process(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_task_type => i_task_types(i));
        
            IF l_task_type_out_proc = pk_alert_constant.g_no
            THEN
                l_task_type_in_proc := pk_alert_constant.g_yes;
            END IF;
        
        END LOOP;
    
        -- get cpoe mode to evaluate if the new prescription options is available or not
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'get o_task_type_list_frequent cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_type_list_frequent FOR
            SELECT g_refresh_presc_id AS id_action,
                   NULL AS id_parent,
                   1 AS "LEVEL",
                   NULL AS to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) AS desc_action,
                   NULL AS icon,
                   NULL AS flg_default,
                   decode(l_task_type_next_active,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_inactive,
                          decode(l_task_type_in_proc,
                                 pk_alert_constant.g_no,
                                 pk_alert_constant.g_inactive,
                                 check_presc_action_avail(i_lang, i_prof, a.id_action))) AS flg_active,
                   NULL AS action,
                   NULL AS id_target_task_type,
                   g_refresh_presc_rank AS rank,
                   g_task_filter_current AS flg_filter
              FROM action a
             WHERE a.id_action = g_cpoe_presc_refresh_action
               AND l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
               AND l_flg_profile != pk_cpoe.g_flg_profile_template_student
            UNION ALL
            SELECT id_task_type AS id_action,
                   id_task_type_parent AS id_parent,
                   "LEVEL",
                   NULL AS to_state,
                   desc_action,
                   icon,
                   NULL AS flg_default,
                   decode(l_task_type_next_active, pk_alert_constant.g_no, pk_alert_constant.g_inactive, flg_active),
                   NULL AS action,
                   id_target_task_type,
                   rank,
                   decode(l_flg_cpoe_mode,
                          g_cfg_cpoe_mode_advanced,
                          g_task_filter_current || g_task_filter_draft || g_task_filter_next,
                          g_task_filter_active || g_task_filter_draft || g_task_filter_next) AS flg_filter
              FROM (SELECT tt.id_task_type,
                           tsi.id_task_type_parent,
                           LEVEL,
                           pk_translation.get_translation(i_lang, tt.code_task_type) AS desc_action,
                           tt.icon,
                           check_task_action_avail(i_lang,
                                                   i_prof,
                                                   tt.id_task_type,
                                                   g_cpoe_task_request_action,
                                                   i_episode) AS flg_active,
                           tsi.rank,
                           tt.id_target_task_type
                      FROM cpoe_task_type tt
                      JOIN (SELECT *
                             FROM (SELECT ctp_f.id_task_type,
                                          ctp_f.rank,
                                          ctp_f.id_task_type_parent,
                                          decode(ctsi_f.flg_available,
                                                 pk_alert_constant.g_no,
                                                 pk_alert_constant.g_no,
                                                 ctp_f.flg_available) AS flg_available
                                     FROM (SELECT DISTINCT ctsi.id_task_type,
                                                           first_value(ctsi.rank) over(PARTITION BY ctsi.id_task_type ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC) AS rank,
                                                           first_value(ctsi.id_task_type_parent) over(PARTITION BY ctsi.id_task_type ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC) AS id_task_type_parent,
                                                           first_value(ctp.flg_available) over(PARTITION BY ctsi.id_task_type ORDER BY ctp.id_profile_template DESC, ctsi.id_institution DESC, ctsi.id_software DESC, ctp.flg_available DESC) AS flg_available
                                             FROM cpoe_task_soft_inst ctsi
                                            INNER JOIN cpoe_task_permission ctp
                                               ON ctsi.id_task_type = ctp.id_task_type
                                            WHERE ctsi.id_institution IN
                                                  (i_prof.institution, pk_alert_constant.g_inst_all)
                                              AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                              AND ctsi.flg_search_type IN (g_access_type_frequent, g_access_type_both)
                                              AND ctp.id_category =
                                                  (SELECT pc.id_category
                                                     FROM prof_cat pc
                                                    WHERE pc.id_professional = i_prof.id
                                                      AND pc.id_institution = i_prof.institution)
                                              AND ctp.id_profile_template IN
                                                  (SELECT ppt.id_profile_template
                                                     FROM prof_profile_template ppt
                                                    WHERE ppt.id_professional = i_prof.id
                                                      AND ppt.id_institution = i_prof.institution
                                                      AND ppt.id_software = i_prof.software
                                                   UNION ALL
                                                   SELECT 0 AS id_profile_template
                                                     FROM dual)) ctp_f
                                    INNER JOIN (SELECT DISTINCT ctsi.id_task_type,
                                                               first_value(ctsi.flg_available) over(PARTITION BY ctsi.id_task_type ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC) AS flg_available
                                                 FROM cpoe_task_soft_inst ctsi
                                                WHERE ctsi.id_institution IN
                                                      (i_prof.institution, pk_alert_constant.g_inst_all)
                                                  AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)) ctsi_f
                                       ON ctsi_f.id_task_type = ctp_f.id_task_type)
                            WHERE flg_available = pk_alert_constant.g_yes) tsi
                        ON tsi.id_task_type = tt.id_task_type
                     START WITH tsi.id_task_type_parent IS NULL
                    CONNECT BY PRIOR tsi.id_task_type = tsi.id_task_type_parent)
             WHERE l_flg_profile != g_flg_profile_template_student
                OR (l_flg_profile = g_flg_profile_template_student AND i_filter = g_filter_draft)
             ORDER BY "LEVEL", rank, desc_action;
    
        g_error := 'get o_task_type_list_search cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_type_list_search FOR
            SELECT id_task_type AS id_action,
                   id_task_type_parent AS id_parent,
                   "LEVEL",
                   NULL AS to_state,
                   desc_action,
                   icon,
                   NULL AS flg_default,
                   flg_active,
                   NULL AS action,
                   id_action_target,
                   rank,
                   decode(l_flg_cpoe_mode,
                          g_cfg_cpoe_mode_advanced,
                          g_task_filter_current || g_task_filter_draft,
                          g_task_filter_active || g_task_filter_draft) AS flg_filter
              FROM (SELECT tt.id_task_type,
                           tsi.id_task_type_parent,
                           LEVEL,
                           pk_translation.get_translation(i_lang, tt.code_task_type) AS desc_action,
                           tt.icon,
                           check_task_action_avail(i_lang,
                                                   i_prof,
                                                   tt.id_task_type,
                                                   g_cpoe_task_request_action,
                                                   i_episode) AS flg_active,
                           tsi.rank,
                           tt.id_target_task_type AS id_action_target
                      FROM cpoe_task_type tt
                      JOIN (SELECT *
                             FROM (SELECT ctp_f.id_task_type,
                                          ctp_f.rank,
                                          ctp_f.id_task_type_parent,
                                          decode(ctsi_f.flg_available,
                                                 pk_alert_constant.g_no,
                                                 pk_alert_constant.g_no,
                                                 ctp_f.flg_available) AS flg_available
                                     FROM (SELECT DISTINCT ctsi.id_task_type,
                                                           first_value(ctsi.rank) over(PARTITION BY ctsi.id_task_type ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC) AS rank,
                                                           first_value(ctsi.id_task_type_parent) over(PARTITION BY ctsi.id_task_type ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC) AS id_task_type_parent,
                                                           first_value(ctp.flg_available) over(PARTITION BY ctsi.id_task_type ORDER BY ctp.id_profile_template DESC, ctsi.id_institution DESC, ctsi.id_software DESC, ctp.flg_available DESC) AS flg_available
                                             FROM cpoe_task_soft_inst ctsi
                                            INNER JOIN cpoe_task_permission ctp
                                               ON ctsi.id_task_type = ctp.id_task_type
                                            WHERE ctsi.id_institution IN
                                                  (i_prof.institution, pk_alert_constant.g_inst_all)
                                              AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                              AND ctsi.flg_search_type IN (g_access_type_search, g_access_type_both)
                                              AND ctp.id_category =
                                                  (SELECT pc.id_category
                                                     FROM prof_cat pc
                                                    WHERE pc.id_professional = i_prof.id
                                                      AND pc.id_institution = i_prof.institution)
                                              AND ctp.id_profile_template IN
                                                  (SELECT ppt.id_profile_template
                                                     FROM prof_profile_template ppt
                                                    WHERE ppt.id_professional = i_prof.id
                                                      AND ppt.id_institution = i_prof.institution
                                                      AND ppt.id_software = i_prof.software
                                                   UNION ALL
                                                   SELECT 0 AS id_profile_template
                                                     FROM dual)) ctp_f
                                    INNER JOIN (SELECT DISTINCT ctsi.id_task_type,
                                                               first_value(ctsi.flg_available) over(PARTITION BY ctsi.id_task_type ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC) AS flg_available
                                               
                                                 FROM cpoe_task_soft_inst ctsi
                                                WHERE ctsi.id_institution IN
                                                      (i_prof.institution, pk_alert_constant.g_inst_all)
                                                  AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)) ctsi_f
                                       ON ctsi_f.id_task_type = ctp_f.id_task_type)
                            WHERE flg_available = pk_alert_constant.g_yes) tsi
                        ON tsi.id_task_type = tt.id_task_type
                     START WITH tsi.id_task_type_parent IS NULL
                    CONNECT BY PRIOR tsi.id_task_type = tsi.id_task_type_parent)
             WHERE l_flg_profile != g_flg_profile_template_student
                OR (l_flg_profile = g_flg_profile_template_student AND i_filter = g_filter_draft)
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
                                              'GET_TASK_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_type_list_frequent);
            pk_types.open_my_cursor(o_task_type_list_search);
            RETURN FALSE;
        
    END get_task_type_list;

    /********************************************************************************************
    * check if a task action can be performed for a given professional and environment
    *
    * @param   i_lang        preferred language id for this professional
    * @param   i_prof        professional id structure
    * @param   i_task_type   cpoe task type id
    * @param   i_action      action id  
    * @param   i_episode     episode id
    *
    * @return  varchar2:    'A': task action available, 'I': task action not available
    *
    * @author               Carlos Loureiro
    * @since                2009/10/19
    ********************************************************************************************/
    FUNCTION check_task_action_avail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE,
        i_action    IN cpoe_task_permission.id_action%TYPE,
        i_episode   IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c_ehr_area IS
            SELECT tt.ehr_access_area
              FROM cpoe_task_type tt
             WHERE tt.id_task_type = i_task_type;
        l_ehr_area             ehr_access_area_def.area%TYPE;
        l_ehr_avail            VARCHAR2(1 CHAR);
        l_availability         VARCHAR2(1 CHAR);
        l_flg_out_cpoe_process cpoe_task_soft_inst.flg_out_of_cpoe_process%TYPE;
        l_error                t_error_out;
        l_unexpected_exception EXCEPTION;
    BEGIN
        -- check task create permission (ehr access)
        g_error := 'check ehr access create permission';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF i_action IN (g_cpoe_task_request_action, g_cpoe_task_activ_draft_action)
           AND i_episode IS NOT NULL
        THEN
            -- get task type ehr_area
            OPEN c_ehr_area;
            FETCH c_ehr_area
                INTO l_ehr_area;
            CLOSE c_ehr_area;
            -- check if task can be created or not 
            IF l_ehr_area IS NOT NULL
            THEN
                IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_episode => i_episode,
                                                                  i_area    => l_ehr_area,
                                                                  o_val     => l_ehr_avail,
                                                                  o_error   => l_error)
                THEN
                    g_error := 'error found while calling pk_ehr_access.check_area_create_permission function';
                    RAISE l_unexpected_exception;
                END IF;
                -- if task type's create permission was denied, then disable this task type 
                IF l_ehr_avail = pk_alert_constant.g_no
                THEN
                    RETURN g_flg_inactive;
                END IF;
            END IF;
        END IF;
    
        -- check task action availability
        g_error := 'check task action availability';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT nvl((SELECT decode(flg_available, pk_alert_constant.g_yes, g_flg_active, g_flg_inactive)
                     FROM (SELECT actp.flg_available
                             FROM action act, cpoe_task_permission actp
                            WHERE act.id_action = actp.id_action
                              AND actp.id_category = (SELECT pc.id_category
                                                        FROM prof_cat pc
                                                       WHERE pc.id_professional = i_prof.id
                                                         AND pc.id_institution = i_prof.institution)
                              AND actp.id_profile_template IN (SELECT ppt.id_profile_template
                                                                 FROM prof_profile_template ppt
                                                                WHERE ppt.id_professional = i_prof.id
                                                                  AND ppt.id_institution = i_prof.institution
                                                                  AND ppt.id_software = i_prof.software
                                                               UNION ALL
                                                               SELECT g_all_profile_template AS id_profile_template
                                                                 FROM dual)
                              AND actp.id_action = i_action
                              AND actp.id_task_type = i_task_type
                              AND actp.id_institution IN (g_all_institution, i_prof.institution)
                              AND actp.id_software IN (g_all_software, i_prof.software)
                            ORDER BY actp.id_institution      DESC,
                                     actp.id_software         DESC,
                                     actp.id_profile_template DESC,
                                     actp.flg_available)
                    WHERE rownum = 1),
                   g_flg_inactive) AS flg_available
          INTO l_availability
          FROM dual;
    
        RETURN l_availability; -- available
    
    END check_task_action_avail;

    /********************************************************************************************
    * check if a prescription action can be performed for a given professional
    *
    * @param   i_lang        preferred language id for this professional
    * @param   i_prof        professional id structure
    * @param   i_action      action id  
    *
    * @return  varchar2:     'A': prescription action available, 'I': prescription action not available
    *
    * @author                Carlos Loureiro
    * @since                 2010/08/31
    ********************************************************************************************/
    FUNCTION check_presc_action_avail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.id_action%TYPE
    ) RETURN VARCHAR2 IS
        l_cat category.id_category%TYPE;
        l_cnt NUMBER;
    
    BEGIN
        g_error := 'check prescription action availability for professional category';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get professional's category id
        l_cat := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        -- switch for each prescription action    
        CASE
            WHEN i_action = g_cpoe_presc_refresh_action
                 OR i_action = g_cpoe_presc_create_action THEN
                SELECT COUNT(1)
                  INTO l_cnt
                  FROM TABLE(pk_string_utils.str_split(pk_sysconfig.get_config(g_cfg_cpoe_presc_action_cat, i_prof),
                                                       '|')) cat
                 WHERE cat.column_value = to_char(l_cat);
            
            ELSE
                l_cnt := 0;
        END CASE;
    
        IF l_cnt = 0
        THEN
            RETURN g_flg_inactive;
        ELSE
            RETURN g_flg_active;
        END IF;
    END check_presc_action_avail;

    /********************************************************************************************
    * get detailed cpoe task type based on target task type (crossmapping between systems)
    *
    * @param       i_task_type            task type id
    * @param       i_target_task_type     target task type id    
    *
    * @return      cpoe task type id
    *
    * @author      Carlos Loureiro
    * @since       2009/10/28
    ********************************************************************************************/
    FUNCTION get_task_type_match
    (
        i_task_type        IN cpoe_task_type.id_task_type%TYPE,
        i_target_task_type IN cpoe_task_type.id_target_task_type%TYPE
    ) RETURN NUMBER IS
        l_domain table_number;
        -- internal function to get the task type within a domain of allowed values
        FUNCTION get_task_type_domain
        (
            i_task_type        IN cpoe_task_type.id_task_type%TYPE,
            i_target_task_type IN cpoe_task_type.id_target_task_type%TYPE,
            i_domain           IN table_number
        ) RETURN NUMBER IS
            l_task_type_ret cpoe_task_type.id_task_type%TYPE;
        BEGIN
            SELECT /*+OPT_ESTIMATE (table d rows=1)*/
             d.column_value
              INTO l_task_type_ret
              FROM TABLE(i_domain) d
              JOIN cpoe_task_type tt
                ON tt.id_task_type = d.column_value
             WHERE tt.id_target_task_type = i_target_task_type;
            RETURN l_task_type_ret;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_task_type;
        END;
    BEGIN
    
        CASE i_task_type
        
            WHEN g_task_type_diet THEN
                l_domain := table_number(g_task_type_diet_inst, g_task_type_diet_spec, g_task_type_diet_predefined);
                RETURN get_task_type_domain(i_task_type, i_target_task_type, l_domain);
            
            WHEN g_task_type_hidric THEN
                l_domain := table_number(g_task_type_hidric_in_out,
                                         g_task_type_hidric_out,
                                         g_task_type_hidric_drain,
                                         g_task_type_hidric_in,
                                         g_task_type_hidric_out_all,
                                         g_task_type_hidric_irrigations);
                RETURN get_task_type_domain(i_task_type, i_target_task_type, l_domain);
            
            ELSE
                RETURN i_task_type;
            
        END CASE;
    
    END get_task_type_match;

    /********************************************************************************************
    * get cpoe task type (reverse) for other modules API usage
    *
    * @param       i_task_type            task type id
    *
    * @return      reversed cpoe task type id
    *
    * @author      Carlos Loureiro
    * @since       2010/07/10
    ********************************************************************************************/
    FUNCTION get_reverse_task_type_map(i_task_type IN cpoe_task_type.id_task_type%TYPE) RETURN NUMBER IS
    BEGIN
        CASE
        
            WHEN i_task_type IN (g_task_type_diet_inst, g_task_type_diet_spec, g_task_type_diet_predefined) THEN
                RETURN g_task_type_diet;
            
            WHEN i_task_type IN (g_task_type_hidric_in_out,
                                 g_task_type_hidric_out,
                                 g_task_type_hidric_drain,
                                 g_task_type_hidric_in,
                                 g_task_type_hidric_out_all,
                                 g_task_type_hidric_irrigations) THEN
                RETURN g_task_type_hidric;
            
            ELSE
                RETURN i_task_type;
            
        END CASE;
    END get_reverse_task_type_map;

    /********************************************************************************************
    * get task status filter to enable or not records to be shown in selected tab 
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_prof                    professional id structure
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    * @param    i_flg_need_ack            task needs acknowledge
    * @param    i_prev_task_status        previous task status
    *
    * @value    i_cpoe_mode               {*} 'S' simple mode 
    *                                     {*} 'A' advanced mode 
    *
    * @return   varchar2                  filter tab
    *
    * @author                             Carlos Loureiro
    * @since                              2009/10/27
    ********************************************************************************************/
    FUNCTION get_task_status_filter
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_type        IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status       IN VARCHAR2,
        i_flg_need_ack     IN VARCHAR2,
        i_prev_task_status IN VARCHAR2
    ) RETURN cpoe_task_type_status_filter.flg_filter_tab%TYPE IS
        l_filter_def  cpoe_task_type_status_filter.flg_filter_tab%TYPE;
        l_filter_prev cpoe_task_type_status_filter.flg_filter_tab%TYPE;
        l_return      cpoe_task_type_status_filter.flg_filter_tab%TYPE;
    
        FUNCTION get_task_filter
        (
            i_lang       IN language.id_language%TYPE,
            i_prof       IN profissional,
            i_task_type  IN VARCHAR2,
            i_flg_status IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_return VARCHAR2(1 CHAR);
        BEGIN
            SELECT flg_filter_tab
              INTO l_return
              FROM (SELECT sf.flg_filter_tab
                      FROM cpoe_task_type_status_filter sf
                     WHERE sf.id_task_type = i_task_type
                       AND sf.flg_status = i_flg_status
                       AND NOT EXISTS (SELECT 1
                              FROM (SELECT ctse.flg_filter_tab,
                                           ctse.flg_add_remove,
                                           row_number() over(PARTITION BY id_task_type, flg_status, flg_filter_tab ORDER BY id_institution DESC, id_software DESC) rn
                                      FROM cpoe_tt_status_exception ctse
                                     WHERE ctse.id_task_type = i_task_type
                                       AND ctse.flg_status = i_flg_status
                                       AND ctse.id_software IN (i_prof.software, 0)
                                       AND ctse.id_institution IN (i_prof.institution, 0))
                             WHERE rn = 1
                               AND flg_add_remove = pk_access.g_flg_type_remove));
        
            RETURN l_return;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END get_task_filter;
    
    BEGIN
        g_error := 'get filter status';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- getting default filter
        -- get filter where this task should appear
        l_filter_def := get_task_filter(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_task_type  => i_task_type,
                                        i_flg_status => i_flg_status);
    
        IF l_filter_def IS NULL
        THEN
            l_return := NULL;
        
        ELSIF l_filter_def NOT IN (g_filter_draft, g_filter_cancelled)
              AND i_flg_need_ack = pk_alert_constant.g_yes
        THEN
            -- needs acknowledge, previous status must be checked
            IF i_prev_task_status IS NOT NULL
            THEN
                l_filter_prev := get_task_filter(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_task_type  => i_task_type,
                                                 i_flg_status => i_prev_task_status);
            
                IF l_filter_prev != g_filter_draft
                THEN
                    l_return := l_filter_prev;
                ELSE
                    l_return := l_filter_def;
                END IF;
            ELSE
                l_return := l_filter_def;
            END IF;
        ELSE
            l_return := l_filter_def;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_task_status_filter;

    PROCEDURE process_prescription_counters
    (
        i_task_type          IN cpoe_task_type.id_task_type%TYPE,
        i_task_request       IN cpoe_process_task.id_task_request%TYPE,
        i_prescription_tasks IN t_tbl_cpoe_task_req, -- table of t_rec_cpoe_task_req
        io_cnt_current       IN OUT NOCOPY PLS_INTEGER,
        io_cnt_next          IN OUT NOCOPY PLS_INTEGER,
        o_flg_current        OUT VARCHAR2,
        o_flg_next           OUT VARCHAR2
    ) IS
    BEGIN
        -- check if task is in current or next cpoe process
        o_flg_current := pk_alert_constant.g_no; -- assume that task is not in current cpoe process
        o_flg_next    := pk_alert_constant.g_no; -- assume that task is not in next cpoe process
    
        IF i_prescription_tasks IS NOT NULL
           AND i_prescription_tasks.count != 0
        THEN
            FOR i IN 1 .. i_prescription_tasks.count
            LOOP
                IF i_task_type = i_prescription_tasks(i).id_task_type
                   AND i_task_request = i_prescription_tasks(i).id_request
                THEN
                    IF i_prescription_tasks(i).flg_status != g_flg_status_n
                    THEN
                        -- assume this task type/request belongs to the current cpoe process
                        io_cnt_current := io_cnt_current + 1;
                        o_flg_current  := pk_alert_constant.g_yes; -- task is in current cpoe process
                    ELSE
                        io_cnt_next := io_cnt_next + 1;
                        o_flg_next  := pk_alert_constant.g_yes; -- task is in next cpoe process
                    END IF;
                    -- the following "exit" was removed to allow same task requests in current and next prescriptions simultaneously
                    -- EXIT; -- exit loop - record was found
                END IF;
            END LOOP;
        END IF;
    END process_prescription_counters;

    /**
    * Get all tabs where this task is visible
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_prof                    professional id structure
    * @param    i_cpoe_mode               current cpoe mode (simple or advanced)
    * @param    i_id_task_type            Task type identifier
    * @param    i_flg_need_ack            Task needs acknowledge
    * @param    i_flg_status              Task status
    * @param    i_previous_status         Task previous status
    * @param    i_cur_task_types          Array of task types associated with the current cpoe
    * @param    i_cur_task_requests       Array of task requests associated with the current cpoe
    * @param    i_task_request            Id of the task request
    * @param    io_cnt_all                Count of <all> filter tab tasks
    * @param    io_cnt_current            Count of <current> filter tab tasks
    * @param    io_cnt_active             Count of <active> filter tab tasks
    * @param    io_cnt_draft              Count of <draft> filter tab tasks
    * @param    io_cnt_to_ack             Count of <to acknowledge> filter tab tasks    
    * @param    o_visible_tabs            Array with all tabs where this task is visible
    * @param    o_error                   Error message
    *
    * @value    i_flg_need_ack            {*} 'Y' needs acknowledge
    *                                     {*} 'N' otherwise
    *
    * @return   boolean                   true or false on success or error
    *
    * @author                             ana.monteiro
    * @since                              05-12-2014
    */
    FUNCTION get_visible_tabs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_cpoe_mode          IN sys_config.value%TYPE,
        i_cur_task_types     IN table_number,
        i_cur_task_requests  IN table_number,
        i_task_cpoe_status   IN table_varchar,
        i_task_request       IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type       IN cpoe_task_type.id_task_type%TYPE,
        i_flg_need_ack       IN VARCHAR2,
        i_flg_status         IN VARCHAR2,
        i_previous_status    IN VARCHAR2,
        i_cpoe_status        IN VARCHAR2,
        i_prescription_tasks IN t_tbl_cpoe_task_req,
        i_dt_begin           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        io_cnt_all           IN OUT NOCOPY NUMBER,
        io_cnt_current       IN OUT NOCOPY NUMBER,
        io_cnt_next          IN OUT NOCOPY NUMBER,
        io_cnt_active        IN OUT NOCOPY NUMBER,
        io_cnt_draft         IN OUT NOCOPY NUMBER,
        io_cnt_to_ack        IN OUT NOCOPY NUMBER,
        
        o_visible_tabs OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_filter_tab  cpoe_task_type_status_filter.flg_filter_tab%TYPE;
        l_flg_current VARCHAR2(1 CHAR);
        l_flg_next    VARCHAR2(1 CHAR);
    
        l_flg_type VARCHAR2(1 CHAR);
        l_dt       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_out_process VARCHAR2(2 CHAR) := task_out_of_cpoe_process(i_lang, i_prof, i_id_task_type);
    BEGIN
    
        o_visible_tabs := table_varchar();
        o_visible_tabs.extend;
    
        l_filter_tab := get_task_status_filter(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_task_type        => i_id_task_type,
                                               i_flg_status       => i_flg_status,
                                               i_prev_task_status => i_previous_status,
                                               i_flg_need_ack     => i_flg_need_ack);
    
        IF l_filter_tab IS NOT NULL
        THEN
            -- add task to filter "All"   
            o_visible_tabs(o_visible_tabs.count) := g_filter_all;
            io_cnt_all := io_cnt_all + 1;
        
            IF l_filter_tab = g_filter_cancelled
            THEN
                RETURN TRUE;
            END IF;
        
            -- check if task is shown in filter "Acknowledge"
            IF i_flg_need_ack = pk_alert_constant.g_yes
            THEN
                o_visible_tabs.extend;
                o_visible_tabs(o_visible_tabs.count) := g_filter_to_ack;
                io_cnt_to_ack := io_cnt_to_ack + 1;
            END IF;
        
            o_visible_tabs.extend;
            IF l_filter_tab != g_filter_draft
            THEN
                o_visible_tabs(o_visible_tabs.count) := g_filter_active;
            ELSE
                o_visible_tabs(o_visible_tabs.count) := l_filter_tab;
            END IF;
        
            CASE l_filter_tab
                WHEN g_filter_active THEN
                    IF i_cpoe_status != g_flg_status_n
                       OR i_cpoe_status IS NULL
                    THEN
                        io_cnt_active := io_cnt_active + 1;
                        --RETURN TRUE;
                    END IF;
                WHEN g_filter_inactive THEN
                
                    IF i_cpoe_status != g_flg_status_n
                       OR i_cpoe_status IS NULL
                    THEN
                        io_cnt_active := io_cnt_active + 1;
                        --RETURN TRUE;
                    END IF;
                WHEN g_filter_cancelled THEN
                
                    IF i_cpoe_status NOT IN (g_flg_status_n, g_flg_status_a)
                       OR i_cpoe_status IS NULL
                    THEN
                        io_cnt_active := io_cnt_active + 1;
                        --RETURN TRUE;
                    END IF;
                WHEN g_filter_draft THEN
                    io_cnt_draft := io_cnt_draft + 1;
                    RETURN TRUE;
                ELSE
                    NULL;
            END CASE;
        END IF;
    
        IF l_out_process = pk_alert_constant.g_yes
        THEN
        
            IF i_cpoe_mode = g_cfg_cpoe_mode_advanced
            THEN
                IF pk_cpoe.exclude_task_status(i_id_task_type, i_flg_status)
                THEN
                    RETURN TRUE;
                END IF;
            
                /*o_visible_tabs.extend;
                IF i_cpoe_status = g_flg_status_n
                THEN*/
            
                IF i_id_task_type = pk_cpoe.g_task_type_analysis
                THEN
                
                    SELECT ltea.dt_target
                      INTO l_dt
                      FROM lab_tests_ea ltea
                     WHERE ltea.id_analysis_req_det = i_task_request;
                ELSIF i_id_task_type IN (pk_cpoe.g_task_type_image_exam, pk_cpoe.g_task_type_other_exam)
                THEN
                    SELECT ee.dt_begin
                      INTO l_dt
                      FROM exams_ea ee
                     WHERE ee.id_exam_req_det = i_task_request;
                
                END IF;
            
                IF (((l_dt >= i_dt_end AND i_cpoe_status != 'N') OR (l_dt >= i_dt_begin AND i_cpoe_status = 'N')) AND
                   i_cpoe_status != 'E' AND i_cpoe_status IS NOT NULL)
                THEN
                    l_flg_type := g_flg_status_n;
                END IF;
            
                IF l_flg_type = g_flg_status_n
                THEN
                    o_visible_tabs(o_visible_tabs.count) := g_filter_next;
                    io_cnt_next := io_cnt_next + 1;
                ELSE
                
                    o_visible_tabs(o_visible_tabs.count) := g_filter_current;
                    io_cnt_current := io_cnt_current + 1;
                END IF;
            
                /*ELSE
                o_visible_tabs.extend;
                o_visible_tabs(o_visible_tabs.count) := g_filter_active;
                io_cnt_active := io_cnt_active + 1;*/
            END IF;
        
            RETURN TRUE;
        END IF;
    
        IF i_cpoe_mode = g_cfg_cpoe_mode_advanced
           AND l_filter_tab IS NOT NULL
        THEN
        
            -- current cpoe task classification
            process_current_counter(i_task_types         => i_cur_task_types,
                                    i_task_requests      => i_cur_task_requests,
                                    i_task_cpoe_status   => i_task_cpoe_status,
                                    i_task_type          => i_id_task_type,
                                    i_task_request       => i_task_request,
                                    i_prescription_tasks => i_prescription_tasks,
                                    o_flg_current        => l_flg_current,
                                    o_flg_next           => l_flg_next);
        
            IF l_flg_current = pk_alert_constant.g_yes
              -- special medication case, where the presciption in state "To be expired" should appear in active state 
              -- despite independently of the cpoe_process state:
               OR (i_id_task_type = pk_cpoe.g_task_type_medication -- medication task
               AND i_flg_status = pk_rt_med_pfh.st_expired_ongoing -- presc in state "To be expired"
               AND l_filter_tab = pk_cpoe.g_filter_active) -- the selected tab is the active
            THEN
                o_visible_tabs.extend;
                o_visible_tabs(o_visible_tabs.count) := g_filter_current;
                io_cnt_current := io_cnt_current + 1;
            END IF;
        
            IF l_flg_next = pk_alert_constant.g_yes
            THEN
                o_visible_tabs.extend;
                o_visible_tabs(o_visible_tabs.count) := g_filter_next;
                io_cnt_next := io_cnt_next + 1;
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
                                              'GET_VISIBLE_TABS',
                                              o_error);
            RETURN FALSE;
    END get_visible_tabs;

    FUNCTION exclude_task_status
    (
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status IN VARCHAR2
        
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        CASE i_task_type
            WHEN pk_cpoe.g_task_type_analysis THEN
                IF i_flg_status IN (pk_lab_tests_constant.g_analysis_cancel, pk_lab_tests_constant.g_analysis_read)
                THEN
                    RETURN TRUE;
                END IF;
            WHEN pk_cpoe.g_task_type_image_exam THEN
                IF i_flg_status IN (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_read)
                THEN
                    RETURN TRUE;
                END IF;
            WHEN pk_cpoe.g_task_type_other_exam THEN
                IF i_flg_status IN (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_read)
                THEN
                    RETURN TRUE;
                END IF;
            ELSE
                RETURN FALSE;
        END CASE;
    
        RETURN FALSE;
    
    END exclude_task_status;

    /********************************************************************************************
    * get task filter based in task type status  
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_prof                    professional id structure
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   varchar2                  {*} 'C' Current 
    *                                     {*} 'A' Active 
    *                                     {*} 'I' Inactive 
    *                                     {*} 'D' Draft 
    *                                     {*} 'X' Cancelled
    *
    * @author                             Carlos Loureiro
    * @since                              2009/11/13
    ********************************************************************************************/
    FUNCTION get_task_filter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN VARCHAR2,
        i_flg_status IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR);
    BEGIN
        SELECT sf.flg_filter_tab
          INTO l_return
          FROM cpoe_task_type_status_filter sf
         WHERE sf.id_task_type = i_task_type
           AND sf.flg_status = i_flg_status
           AND check_task_action_avail(i_lang, i_prof, i_task_type, g_cpoe_task_view_action, i_episode) = g_flg_active;
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_task_filter;

    /********************************************************************************************
    * increment filter counters by one  
    *
    * @param    i_filter_tab              task filter where the count increment will happen
    * @param    io_cnt_all                all task filter counter
    * @param    io_cnt_active             active task filter counter
    * @param    io_cnt_draft              draft task filter counter
    *
    * @author                             Carlos Loureiro
    * @since                              2009/11/16
    ********************************************************************************************/
    PROCEDURE increment_filter_counters
    (
        i_filter_tab  IN VARCHAR2,
        io_cnt_all    IN OUT NOCOPY NUMBER,
        io_cnt_active IN OUT NOCOPY NUMBER,
        io_cnt_draft  IN OUT NOCOPY NUMBER
    ) IS
    BEGIN
        CASE i_filter_tab
            WHEN g_filter_active THEN
                io_cnt_active := io_cnt_active + 1;
            WHEN g_filter_inactive THEN
                NULL;
            WHEN g_filter_draft THEN
                io_cnt_draft := io_cnt_draft + 1;
            WHEN g_filter_cancelled THEN
                NULL;
            ELSE
                io_cnt_active := io_cnt_active + 1;
                io_cnt_draft  := io_cnt_draft + 1;
        END CASE;
        io_cnt_all := io_cnt_all + 1;
    END increment_filter_counters;

    /********************************************************************************************
    * get all tasks to be pipelined to CPOE grid
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_cpoe_mode               current cpoe mode (simple or advanced)
    * @param       i_patient                 internal id of the patient
    * @param       i_episode                 internal id of the episode
    * @param       i_cpoe_start_tstz         start timestamp of last cpoe process created (null if none was created)
    * @param       i_flg_report              indicates if task list APIs should return additional report fields
    * @param       o_tasks                   list of all tasks gathered from apis
    * @param       o_cnt_all                 total count of <all> filter tab tasks
    * @param       o_cnt_current             total count of <current> filter tab tasks
    * @param       o_cnt_active              total count of <active> filter tab tasks
    * @param       o_cnt_draft               total count of <draft> filter tab tasks
    * @param       o_cnt_to_ack              total count of <to acknowledge> filter tab tasks    
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @value       i_flg_report              {*} 'Y' additional report columns should be considered by task list APIs
    *                                        {*} 'N' additional report columns should be discarded by task list APIs
    *
    * @author                                Carlos Loureiro
    * @since                                 16-NOV-2009
    ********************************************************************************************/
    FUNCTION get_task_list_all
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cpoe_mode       IN sys_config.value%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_process_tasks   IN t_tbl_cpoe_task_req,
        i_cpoe_start_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_report      IN VARCHAR2,
        i_process         IN cpoe_process.id_cpoe_process%TYPE,
        i_tab_type        IN VARCHAR2 DEFAULT 'A',
        i_task_ids        IN table_number DEFAULT NULL,
        i_task_type_ids   IN table_number DEFAULT NULL,
        i_dt_start        IN VARCHAR2 DEFAULT NULL,
        i_dt_end          IN VARCHAR2 DEFAULT NULL,
        i_cpoe_status     IN cpoe_process.flg_status%TYPE,
        o_tasks           OUT t_tbl_cpoe_task_list,
        o_task_types      OUT table_number,
        o_cnt_all         OUT NUMBER,
        o_cnt_current     OUT NUMBER,
        o_cnt_next        OUT NUMBER,
        o_cnt_active      OUT NUMBER,
        o_cnt_draft       OUT NUMBER,
        o_cnt_to_ack      OUT NUMBER,
        o_execution       OUT t_tbl_cpoe_execution,
        o_med_admin       OUT pk_types.cursor_type,
        o_proc_plan       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_task_list pk_types.cursor_type;
        l_med_admin pk_types.cursor_type;
        l_proc_plan pk_types.cursor_type;
        l_execution pk_types.cursor_type;
    
        l_rec       t_rec_cpoe_task_list := t_rec_cpoe_task_list();
        l_rec_index PLS_INTEGER := 0;
    
        l_rec_execution       t_rec_cpoe_execution := t_rec_cpoe_execution();
        l_rec_execution_index PLS_INTEGER := 0;
    
        CURSOR c_task_type IS
            SELECT id_task_type
              FROM (SELECT DISTINCT first_value(id_task_type) over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) AS id_task_type,
                                    first_value(flg_available) over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) AS flg_available
                      FROM cpoe_task_soft_inst
                     WHERE id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND id_software IN (i_prof.software, pk_alert_constant.g_soft_all))
             WHERE flg_available = pk_alert_constant.g_yes;
    
        CURSOR c_current_cpoe_tasks IS
            SELECT pt.id_task_type, pt.id_task_request, p.flg_status
              FROM cpoe_process p
              JOIN cpoe_process_task pt
                ON pt.id_cpoe_process = p.id_cpoe_process
             WHERE p.id_cpoe_process = (SELECT id_cpoe_process
                                          FROM (SELECT cp2.id_cpoe_process
                                                  FROM cpoe_process cp2
                                                  JOIN episode e1
                                                    ON e1.id_episode = cp2.id_episode
                                                  JOIN episode e2
                                                    ON e2.id_visit = e1.id_visit
                                                 WHERE e2.id_episode = i_episode
                                                   AND cp2.flg_status = decode(i_tab_type, 'N', 'N', 'A')
                                                 ORDER BY cp2.dt_cpoe_proc_start DESC)
                                         WHERE rownum = 1);
    
        CURSOR c_cpoe_process_tasks IS
            SELECT t_rec_cpoe_task_req(pt.id_task_type, pt.id_task_request, p.flg_status)
              FROM cpoe_process p
              JOIN cpoe_process_task pt
                ON pt.id_cpoe_process = p.id_cpoe_process
             WHERE p.id_cpoe_process IN (SELECT id_cpoe_process
                                           FROM (SELECT cp2.id_cpoe_process
                                                   FROM cpoe_process cp2
                                                   JOIN episode e1
                                                     ON e1.id_episode = cp2.id_episode
                                                   JOIN episode e2
                                                     ON e2.id_visit = e1.id_visit
                                                  WHERE e2.id_episode = i_episode
                                                    AND cp2.flg_status != g_flg_status_n
                                                  ORDER BY cp2.dt_cpoe_proc_start DESC)
                                          WHERE rownum = 1
                                         UNION ALL
                                         SELECT cp2.id_cpoe_process
                                           FROM cpoe_process cp2
                                           JOIN episode e1
                                             ON e1.id_episode = cp2.id_episode
                                           JOIN episode e2
                                             ON e2.id_visit = e1.id_visit
                                          WHERE e2.id_episode = i_episode
                                            AND cp2.flg_status = g_flg_status_n);
    
        l_cur_task_types          table_number;
        l_cur_requests            table_number;
        l_cur_cpoe_status         table_varchar;
        l_cpoe_status             VARCHAR2(2 CHAR);
        l_cfg_closed_task_filter  sys_config.value%TYPE;
        l_closed_task_filter_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_filter_tab              cpoe_task_type_status_filter.flg_filter_tab%TYPE;
        l_cpoe_proc_task_filter   t_tbl_cpoe_task_req;
        l_dt_end                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin                TIMESTAMP WITH LOCAL TIME ZONE;
    
        val1 table_number := table_number();
        val2 table_varchar := table_varchar();
        val3 table_varchar := table_varchar();
        val4 table_varchar := table_varchar();
        val5 table_varchar := table_varchar();
    
    BEGIN
        -- init variables
        o_tasks       := t_tbl_cpoe_task_list();
        o_execution   := t_tbl_cpoe_execution();
        o_task_types  := table_number();
        o_cnt_all     := 0;
        o_cnt_current := 0;
        o_cnt_next    := 0;
        o_cnt_active  := 0;
        o_cnt_draft   := 0;
        o_cnt_to_ack  := 0;
    
        -- get closed task filter interval in days
        g_error := 'get CPOE_CLOSED_TASK_FILTER_INTERVAL sys_config';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_closed_task_filter, i_prof, l_cfg_closed_task_filter)
        THEN
            RAISE l_exception;
        END IF;
    
        -- get minimum timestamp for closed tasks filter (in days)
        l_closed_task_filter_tstz := current_timestamp - numtodsinterval(to_number(l_cfg_closed_task_filter), 'DAY');
        IF i_cpoe_start_tstz IS NOT NULL
           AND i_cpoe_start_tstz < l_closed_task_filter_tstz
        THEN
            l_closed_task_filter_tstz := i_cpoe_start_tstz;
        END IF;
    
        -- get current tasks
        g_error := 'open c_current_cpoe_tasks cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- we only need filter counters in main cpoe grid (not used in reports or history)
        IF i_cpoe_mode = g_cfg_cpoe_mode_advanced
           AND i_process_tasks IS NULL
        THEN
            OPEN c_current_cpoe_tasks;
            FETCH c_current_cpoe_tasks BULK COLLECT
                INTO l_cur_task_types, l_cur_requests, l_cur_cpoe_status;
            CLOSE c_current_cpoe_tasks;
            OPEN c_cpoe_process_tasks;
            FETCH c_cpoe_process_tasks BULK COLLECT
                INTO l_cpoe_proc_task_filter;
            CLOSE c_cpoe_process_tasks;
        
        END IF;
    
        IF i_process IS NOT NULL
        THEN
            SELECT cp.dt_cpoe_proc_start, cp.dt_cpoe_proc_end
              INTO l_dt_begin, l_dt_end
              FROM cpoe_process cp
             WHERE cp.id_cpoe_process = i_process;
        END IF;
    
        g_error := 'build o_tasks table';
        pk_alertlog.log_debug(g_error, g_package_name);
        pk_types.open_cursor_if_closed(o_med_admin);
        FOR rec IN c_task_type
        LOOP
        
            IF NOT get_task_list_by_type(i_lang                    => i_lang,
                                         i_prof                    => i_prof,
                                         i_patient                 => i_patient,
                                         i_episode                 => i_episode,
                                         i_process_tasks           => i_process_tasks,
                                         i_closed_task_filter_tstz => l_closed_task_filter_tstz,
                                         i_task_type               => rec.id_task_type,
                                         i_flg_report              => i_flg_report,
                                         i_tab_type                => i_tab_type,
                                         i_process                 => i_process,
                                         i_task_ids                => i_task_ids,
                                         i_task_type_ids           => i_task_type_ids,
                                         i_dt_start                => i_dt_start,
                                         i_dt_end                  => i_dt_end,
                                         o_task_list               => l_task_list,
                                         o_execution               => l_execution,
                                         o_med_admin               => l_med_admin,
                                         o_proc_plan               => l_proc_plan,
                                         o_error                   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            LOOP
                IF l_execution IS NOT NULL
                THEN
                    l_rec_execution := t_rec_cpoe_execution();
                    BEGIN
                        FETCH l_execution
                            INTO l_rec_execution.id_prescription,
                                 l_rec_execution.planned_date,
                                 l_rec_execution.exec_date,
                                 l_rec_execution.exec_notes,
                                 l_rec_execution.out_of_period;
                        EXIT WHEN l_execution%NOTFOUND;
                    EXCEPTION
                        WHEN OTHERS THEN
                            pk_types.open_my_cursor(l_execution);
                            EXIT;
                    END;
                ELSE
                    pk_types.open_my_cursor(l_execution);
                    EXIT;
                END IF;
            
                IF rec.id_task_type = pk_cpoe.g_task_type_hidric
                THEN
                    l_rec_execution.id_task_type := get_task_type_match(i_task_type        => rec.id_task_type,
                                                                        i_target_task_type => pk_inp_hidrics.get_epis_hidrics_type(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   l_rec_execution.id_prescription));
                
                ELSIF rec.id_task_type = g_task_type_diet
                THEN
                    l_rec_execution.id_task_type := get_task_type_match(i_task_type        => rec.id_task_type,
                                                                        i_target_task_type => rec.id_task_type);
                ELSE
                    l_rec_execution.id_task_type := rec.id_task_type;
                END IF;
            
                o_execution.extend;
                l_rec_execution_index := l_rec_execution_index + 1;
                o_execution(l_rec_execution_index) := l_rec_execution;
            END LOOP;
        
            -- open l_task_list; (cursor l_task_list is already open)
            LOOP
            
                IF l_task_list IS NOT NULL
                THEN
                
                    l_rec := t_rec_cpoe_task_list();
                
                    FETCH l_task_list
                        INTO l_rec.id_target_task_type,
                             l_rec.task_description,
                             l_rec.id_profissional,
                             l_rec.icon_warning,
                             l_rec.status_str,
                             l_rec.id_request,
                             l_rec.start_date_tstz,
                             l_rec.end_date_tstz,
                             l_rec.creation_date_tstz,
                             l_rec.flg_status,
                             l_rec.flg_cancel,
                             l_rec.flg_conflict,
                             l_rec.id_task,
                             l_rec.task_title,
                             l_rec.task_instructions,
                             l_rec.task_notes,
                             l_rec.generic_text1,
                             l_rec.generic_text2,
                             l_rec.generic_text3,
                             l_rec.task_status,
                             l_rec.instr_bg_color,
                             l_rec.instr_bg_alpha,
                             l_rec.task_icon,
                             l_rec.flg_need_ack,
                             l_rec.edit_icon,
                             l_rec.action_desc,
                             l_rec.previous_status,
                             l_rec.id_task_type_source,
                             l_rec.id_task_dependency,
                             l_rec.flg_rep_cancel,
                             l_rec.flg_prn_conditional;
                    EXIT WHEN l_task_list%NOTFOUND;
                ELSE
                    pk_types.open_my_cursor(l_task_list);
                    EXIT;
                END IF;
            
                -- update cpoe task type based on target task type
                l_rec.id_task_type := get_task_type_match(i_task_type        => rec.id_task_type,
                                                          i_target_task_type => l_rec.id_target_task_type);
            
                -- we only need filter counters in main cpoe grid (not used in reports or history)
                IF i_process_tasks IS NULL
                THEN
                
                    -- check if there is view permissions for this task type
                    IF pk_cpoe.check_task_action_avail(i_lang,
                                                       i_prof,
                                                       l_rec.id_task_type,
                                                       g_cpoe_task_view_action,
                                                       NULL) = g_flg_active
                    THEN
                        BEGIN
                        
                            IF i_cpoe_status IS NULL
                            THEN
                                SELECT cp.flg_status
                                  INTO l_cpoe_status
                                  FROM cpoe_process cp
                                 INNER JOIN cpoe_process_task cpt
                                    ON cpt.id_cpoe_process = cp.id_cpoe_process
                                 WHERE id_task_type = l_rec.id_task_type
                                   AND id_task_request = l_rec.id_request
                                   AND rownum = 1;
                            ELSE
                                l_cpoe_status := i_cpoe_status;
                            END IF;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_cpoe_status := i_tab_type;
                        END;
                    
                        -- getting tabs where this task is visible, incrementing filter counters
                        g_error := 'Call get_visible_tabs / i_task_request=' || l_rec.id_task_type;
                        IF NOT get_visible_tabs(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_cpoe_mode          => i_cpoe_mode,
                                                i_cur_task_types     => l_cur_task_types,
                                                i_cur_task_requests  => l_cur_requests,
                                                i_task_cpoe_status   => l_cur_cpoe_status,
                                                i_task_request       => l_rec.id_request,
                                                i_id_task_type       => l_rec.id_task_type,
                                                i_flg_need_ack       => l_rec.flg_need_ack,
                                                i_flg_status         => l_rec.flg_status,
                                                i_previous_status    => l_rec.previous_status,
                                                i_cpoe_status        => l_cpoe_status,
                                                i_prescription_tasks => l_cpoe_proc_task_filter,
                                                i_dt_begin           => l_dt_begin,
                                                i_dt_end             => l_dt_end,
                                                io_cnt_all           => o_cnt_all,
                                                io_cnt_current       => o_cnt_current,
                                                io_cnt_next          => o_cnt_next,
                                                io_cnt_active        => o_cnt_active,
                                                io_cnt_draft         => o_cnt_draft,
                                                io_cnt_to_ack        => o_cnt_to_ack,
                                                o_visible_tabs       => l_rec.visible_tabs,
                                                o_error              => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        IF l_rec.id_task_type IS NOT NULL
                           AND l_rec.visible_tabs(l_rec.visible_tabs.count) = g_filter_current
                        THEN
                            o_task_types.extend;
                            o_task_types(o_task_types.count) := l_rec.id_task_type;
                        END IF;
                        -- extend and associates the new record into l_tab            
                        o_tasks.extend;
                        l_rec_index := l_rec_index + 1;
                        l_rec.rank := l_rec_index; -- set rank for order by clause in main function
                        o_tasks(l_rec_index) := l_rec;
                    
                    END IF;
                
                ELSE
                    -- extend and associates the new record into l_tab            
                    o_tasks.extend;
                    l_rec_index := l_rec_index + 1;
                    l_rec.rank := l_rec_index; -- set rank for order by clause in main function
                    o_tasks(l_rec_index) := l_rec;
                
                END IF;
            
            END LOOP;
        
            CLOSE l_task_list;
        
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
                                              'GET_TASK_LIST_ALL',
                                              o_error);
            RETURN FALSE;
    END get_task_list_all;

    /********************************************************************************************
    * get default filter
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_prof                    professional id structure
    * @param    i_flg_cpoe_mode           current cpoe mode (simple or advanced)    
    * @param    i_cnt_all                 total count of <all> filter tab tasks
    * @param    i_cnt_current             total count of <current> filter tab tasks
    * @param    i_cnt_active              total count of <active> filter tab tasks
    * @param    i_cnt_draft               total count of <draft> filter tab tasks
    * @param    i_cnt_to_ack              total count of <to acknowledge> filter tab tasks
    * @param    i_flg_default_filter      default filter tab
    * @param    o_error                   error message
    *
    * @value    i_flg_cpoe_mode           {*} 'S' simple mode 
    *                                     {*} 'A' advanced mode 
    *
    * @return   boolean                   true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2014/12/10
    ********************************************************************************************/
    FUNCTION get_default_filter
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_cat           IN category.flg_type%TYPE,
        i_flg_cpoe_mode      IN VARCHAR2,
        i_cnt_to_ack         IN NUMBER DEFAULT NULL,
        o_flg_default_filter OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get default filter';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF i_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            o_flg_default_filter := g_filter_current;
        ELSE
            IF i_prof_cat = pk_alert_constant.g_cat_type_nurse
               AND i_cnt_to_ack != 0
            THEN
                o_flg_default_filter := g_filter_to_ack;
            ELSE
                o_flg_default_filter := g_filter_active;
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
                                              'GET_DEFAULT_FILTER',
                                              o_error);
            RETURN FALSE;
    END get_default_filter;

    /********************************************************************************************
    * get next prescription process information
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       o_cpoe_process            cpoe process id
    * @param       o_dt_start                cpoe start timestamp
    * @param       o_dt_end                  cpoe end timestamp
    *   
    * @author                                Carlos Loureiro
    * @since                                 24-JUL-2012
    ********************************************************************************************/
    PROCEDURE get_next_presc_process
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_cpoe_process OUT cpoe_process.id_cpoe_process%TYPE,
        o_dt_start     OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end       OUT cpoe_process.dt_cpoe_proc_end%TYPE
    ) IS
    BEGIN
        -- get next prescrition process information
        SELECT cp.id_cpoe_process, cp.dt_cpoe_proc_start, cp.dt_cpoe_proc_end
          INTO o_cpoe_process, o_dt_start, o_dt_end
          FROM cpoe_process cp
         WHERE cp.id_cpoe_process = (SELECT cp2.id_cpoe_process -- it can only return one row!
                                       FROM cpoe_process cp2
                                       JOIN episode e1
                                         ON e1.id_episode = cp2.id_episode
                                       JOIN episode e2
                                         ON e2.id_visit = e1.id_visit
                                      WHERE e2.id_episode = i_episode
                                        AND cp2.flg_status = g_flg_status_n);
    EXCEPTION
        WHEN no_data_found THEN
            o_cpoe_process := NULL;
            o_dt_start     := NULL;
            o_dt_end       := NULL;
    END get_next_presc_process;

    /********************************************************************************************
    * get prescription limits to lock prescription start/end dates
    *
    * @param       i_lang                    preferred lanonal id structure
    * @param       i_episode                 episguage id for this professional
    * @param       i_prof                    professiode id 
    * @param       i_filter                  filter to select active or next prescription
    * @param       o_ts_presc_start          start timestamp to limit prescription request screen
    * @param       o_ts_presc_end            end timestamp to limit prescription request screen
    * @param       o_ts_next_presc           next prescription availability timestamp
    * @param       o_proc_exists             boolean that indicates if process already exists
    *        
    * @value       i_filter                  {*} 'C'  get limits for current active prescription
    *                                        {*} 'N'  get limits for next prescription
    *                                        {*} 'D'  get limits when in drafts area
    *                                        {*} NULL when calling outside of CPOE functionality
    *
    * @author                                Carlos Loureiro
    * @since                                 24-JUL-2012  
    ********************************************************************************************/
    PROCEDURE get_presc_limits
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_filter         IN VARCHAR2,
        i_from_ux        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_task_type      IN task_type.id_task_type%TYPE,
        o_ts_presc_start OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_ts_presc_end   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_ts_next_presc  OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_proc_exists    OUT BOOLEAN
    ) IS
        l_exception EXCEPTION;
        l_flg_cpoe_mode           VARCHAR2(1 CHAR);
        l_flg_cpoe_status         VARCHAR2(1 CHAR);
        l_cpoe_process            cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start           cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end             cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh         cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_presc      cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_id_professional         professional.id_professional%TYPE;
        l_flg_out_of_cpoe_process cpoe_task_soft_inst.flg_out_of_cpoe_process%TYPE := pk_alert_constant.g_no;
        l_error                   t_error_out;
    
        l_is_hidric VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        IF i_task_type IN (g_task_type_hidric,
                           g_task_type_hidric_in_out,
                           g_task_type_hidric_out,
                           g_task_type_hidric_drain,
                           g_task_type_hidric_in,
                           g_task_type_hidric_out_group,
                           g_task_type_hidric_out_all,
                           g_task_type_hidric_irrigations)
        THEN
            l_is_hidric := pk_alert_constant.g_yes;
        END IF;
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.get_presc_limits called with:' || chr(10) || 'i_lang=' || i_lang || chr(10) ||
                                  'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode || chr(10) ||
                                  'i_filter=' || i_filter,
                                  g_package_name);
        END IF;
    
        -- init vars
        o_proc_exists := FALSE; -- assume that no process exists
    
        -- get cpoe mode to evaluate if we should limit prescription dates
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, l_error)
        THEN
            --g_error := 'error found while calling pk_cpoe.get_cpoe_mode function' || chr(10) || l_error.err_desc;
            RAISE l_exception;
            --raise_unexpected_error(i_error => l_error);
        END IF;
    
        --The UX layer only calls get_presc_limits for the HIDRICS area
        --If the hidrics are configured to be outside the CPOE process, no date limits should be sent
        IF i_from_ux = pk_alert_constant.g_yes
        THEN
            SELECT flg_out_of_cpoe_process
              INTO l_flg_out_of_cpoe_process
              FROM (SELECT ctsi.flg_out_of_cpoe_process
                      FROM cpoe_task_soft_inst ctsi
                     WHERE ctsi.id_task_type = 22 --HIDRICS
                       AND ctsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND ctsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                     ORDER BY ctsi.id_institution DESC, ctsi.id_software DESC)
             WHERE rownum = 1;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
           AND l_flg_out_of_cpoe_process = pk_alert_constant.g_no
        THEN
        
            -- get last cpoe information to check if an active prescription exists
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      l_error)
            THEN
                --g_error := 'error found while calling pk_cpoe.get_last_cpoe_info function' || chr(10) ||
                --           l_error.err_desc;
                RAISE l_exception;
                --raise_unexpected_error(i_error => l_error);
            END IF;
        
            -- check if user is in current active prescription
            IF i_filter = g_task_filter_current
            THEN
                -- if current prescription is active
                IF l_flg_cpoe_status = g_flg_status_a
                THEN
                    -- prescription limits for the current active prescription
                    o_ts_presc_start := CASE
                                            WHEN l_is_hidric = pk_alert_constant.g_yes THEN
                                             l_ts_cpoe_start - numtodsinterval(3, 'DAY')
                                            ELSE
                                             l_ts_cpoe_start
                                        END;
                    o_ts_presc_end   := l_ts_cpoe_end;
                    o_proc_exists    := TRUE; -- current active process exists
                
                    -- if current prescription is not active (l_flg_cpoe_status != g_flg_status_a)
                ELSE
                    -- get next cpoe creation period
                    IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_dt_start      => NULL,
                                              o_dt_start      => l_ts_cpoe_start,
                                              o_dt_end        => l_ts_cpoe_end,
                                              o_dt_refresh    => l_ts_cpoe_refresh,
                                              o_dt_next_presc => l_ts_cpoe_next_presc,
                                              o_error         => l_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    -- prescription limits will belong to the prescription about to be created
                    o_ts_presc_start := l_ts_cpoe_start;
                    o_ts_presc_end   := l_ts_cpoe_end;
                
                END IF;
            
                -- check if user is in next prescription
            ELSIF i_filter = g_task_filter_next
            THEN
            
                -- get next prescription process
                get_next_presc_process(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => i_episode,
                                       o_cpoe_process => l_cpoe_process,
                                       o_dt_start     => o_ts_presc_start,
                                       o_dt_end       => o_ts_presc_end);
            
                -- if next prescription process doesn't exist, then calculate start/end timestamps, 
                -- starting from previous current active prescription
                IF l_cpoe_process IS NULL
                THEN
                
                    -- if current prescription is not active (l_flg_cpoe_status != g_flg_status_a)
                    -- get prescription limits that will belong to the prescription about to be created
                    IF l_flg_cpoe_status <> g_flg_status_a
                    THEN
                        -- get next cpoe creation period
                        IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_episode       => i_episode,
                                                  i_dt_start      => NULL,
                                                  o_dt_start      => l_ts_cpoe_start,
                                                  o_dt_end        => l_ts_cpoe_end,
                                                  o_dt_refresh    => l_ts_cpoe_refresh,
                                                  o_dt_next_presc => l_ts_cpoe_next_presc,
                                                  o_error         => l_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END IF;
                
                    -- get next cpoe period, after the active current cpoe
                    -- the start timestamp of next cpoe is the end timestamp of the prescription process about to be created
                    IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_dt_start      => l_ts_cpoe_end,
                                              o_dt_start      => o_ts_presc_start, -- is equal to l_ts_cpoe_end
                                              o_dt_end        => o_ts_presc_end, -- calculated value
                                              o_dt_refresh    => l_ts_cpoe_refresh,
                                              o_dt_next_presc => o_ts_next_presc,
                                              o_error         => l_error) -- calculated value
                    THEN
                        RAISE l_exception;
                    END IF;
                
                ELSE
                    o_proc_exists := TRUE; -- next process exists
                END IF;
            
            ELSE
                -- nothing to limit
                o_ts_presc_start := NULL;
                o_ts_presc_end   := NULL;
                o_ts_next_presc  := NULL;
            
            END IF;
        END IF;
    
        -- if cpoe mode is not in advanced mode, then the following variables will be null:
        --  * o_ts_presc_start
        --  * o_ts_presc_end
        --  * o_ts_next_presc
        --  * o_proc_exists := false; -- assume that no process exists        
        -- in this case, the application shouldn't apply the timestamp limits      
    
        -- output parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.get_presc_limits processing results:' || chr(10) || 'o_ts_presc_start=' ||
                                  o_ts_presc_start || chr(10) || 'o_ts_presc_end=' || o_ts_presc_end || chr(10) ||
                                  'o_ts_next_presc' || o_ts_next_presc || chr(10) || 'o_proc_exists=' || CASE WHEN
                                  o_proc_exists THEN 'true' ELSE 'false' END,
                                  g_package_name);
        END IF;
    END get_presc_limits;

    PROCEDURE init_params_cpoe_grid
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
    
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_filter             VARCHAR2(2 CHAR);
        l_flg_default_filter VARCHAR2(2 CHAR);
    
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_prof_cat      category.flg_type%TYPE := pk_prof_utils.get_category(l_lang, l_prof);
        l_episode       episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_exception EXCEPTION;
    
        o_error t_error_out;
    BEGIN
    
        IF i_context_vals IS NOT NULL
        THEN
            IF i_context_vals.count > 0
            THEN
                l_filter := i_context_vals(1);
            ELSE
                l_filter := NULL;
            END IF;
        ELSE
            l_filter := NULL;
        END IF;
    
        IF NOT get_cpoe_mode(l_lang, l_prof, l_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_filter IS NULL
        THEN
            IF NOT get_default_filter(i_lang               => l_lang,
                                      i_prof               => l_prof,
                                      i_prof_cat           => l_prof_cat,
                                      i_flg_cpoe_mode      => l_flg_cpoe_mode,
                                      i_cnt_to_ack         => 0,
                                      o_flg_default_filter => l_flg_default_filter,
                                      o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_flg_default_filter := l_filter;
        END IF;
    
        pk_context_api.set_parameter('l_lang', l_lang);
        pk_context_api.set_parameter('l_prof_id', l_prof.id);
        pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('l_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_patient', i_context_ids(g_patient));
        pk_context_api.set_parameter('l_episode', i_context_ids(g_episode));
        pk_context_api.set_parameter('l_filter', l_filter);
        pk_context_api.set_parameter('l_flg_default_filter', l_flg_default_filter);
    
        CASE i_name
            WHEN 'l_filter' THEN
                o_vc2 := nvl(l_filter, l_flg_default_filter);
            WHEN 'l_sign_off_t034' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, 'SIGN_OFF_T034');
            WHEN 'l_flg_default_filter' THEN
                o_vc2 := l_flg_default_filter;
            WHEN 'l_ts_cpoe_start' THEN
                o_tstz := NULL;
            WHEN 'l_ts_cpoe_end' THEN
                o_tstz := NULL;
            WHEN 'l_flg_profile' THEN
                o_vc2 := nvl(pk_hand_off_core.get_flg_profile(l_lang, l_prof, NULL), '#');
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_id_prof' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_id_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_id_software' THEN
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
                                              i_package  => 'PK_CPOE',
                                              i_function => 'INIT_PARAMS_CPOE_GRID',
                                              o_error    => o_error);
    END init_params_cpoe_grid;

    FUNCTION get_tasks_relation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_tasks_relation.id_task_type%TYPE,
        i_task_request IN cpoe_tasks_relation.id_task_orig%TYPE,
        i_flg_filter   IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_ret       VARCHAR2(5 CHAR);
        l_all_tasks table_number := table_number();
        l_t         table_varchar;
        l_inst      NUMBER;
        l_a         VARCHAR2(1 CHAR);
        l_n         VARCHAR2(1 CHAR);
        l_d         VARCHAR2(1 CHAR);
        l_error     t_error_out;
    BEGIN
    
        FOR ROW IN (SELECT *
                      FROM cpoe_tasks_relation a
                     WHERE a.id_task_type = i_task_type
                       AND (a.id_task_orig = i_task_request OR a.id_task_dest = i_task_request))
        LOOP
        
            l_all_tasks.extend;
            l_all_tasks(l_all_tasks.count) := row.id_task_orig;
            l_all_tasks.extend;
            l_all_tasks(l_all_tasks.count) := row.id_task_dest;
        END LOOP;
    
        /*CASE i_flg_filter WHEN 'N' THEN l_n := 'P';
        WHEN 'D' THEN l_d := 'R';
        ELSE l_a := 'A'; 
        END CASE;*/
    
        SELECT a.flg_type
          BULK COLLECT
          INTO l_t
          FROM cpoe_tasks_relation a
         WHERE a.id_task_type = i_task_type
           AND (a.id_task_orig IN (SELECT column_value
                                     FROM TABLE(l_all_tasks)) OR
               a.id_task_dest IN (SELECT column_value
                                     FROM TABLE(l_all_tasks)));
    
        FOR i IN 1 .. l_t.count
        LOOP
            l_inst := instr(l_t(i), 'A');
            IF l_inst > 0
               AND l_a IS NULL
            --AND i_flg_filter NOT IN ('C', 'A')
            THEN
                l_a := pk_message.get_message(i_lang, 'CPOE_RELATION_A');
            END IF;
        
            l_inst := instr(l_t(i), 'N');
            IF l_inst > 0
               AND l_n IS NULL
            --AND i_flg_filter NOT IN ('N')
            THEN
                l_n := pk_message.get_message(i_lang, 'CPOE_RELATION_N');
            END IF;
        
            l_inst := instr(l_t(i), 'D');
            IF l_inst > 0
               AND l_d IS NULL
            --AND i_flg_filter NOT IN ('D')
            THEN
                l_d := pk_message.get_message(i_lang, 'CPOE_RELATION_D');
            END IF;
        
            l_inst := instr(l_t(i), 'REP');
            IF l_inst > 0
            THEN
                IF l_a IS NULL
                --AND i_flg_filter NOT IN ('C', 'A')
                THEN
                    l_a := pk_message.get_message(i_lang, 'CPOE_RELATION_A');
                END IF;
                IF l_n IS NULL
                --AND i_flg_filter NOT IN ('N')
                THEN
                    l_n := pk_message.get_message(i_lang, 'CPOE_RELATION_N');
                END IF;
            
            END IF;
        
        END LOOP;
    
        l_ret := l_a || l_n || l_d;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CPOE',
                                              i_function => 'GET_TASKS_RELATION',
                                              o_error    => l_error);
            RETURN '';
    END get_tasks_relation;

    FUNCTION get_tasks_relation_tooltip
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_tasks_relation.id_task_type%TYPE,
        i_task_request IN cpoe_tasks_relation.id_task_orig%TYPE,
        i_flg_filter   IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_ret       VARCHAR2(200 CHAR);
        l_all_tasks table_number := table_number();
        l_t         table_varchar;
        l_inst      NUMBER;
        l_a         VARCHAR2(1 CHAR);
        l_n         VARCHAR2(1 CHAR);
        l_d         VARCHAR2(1 CHAR);
        l_error     t_error_out;
    BEGIN
    
        FOR ROW IN (SELECT *
                      FROM cpoe_tasks_relation a
                     WHERE a.id_task_type = i_task_type
                       AND (a.id_task_orig = i_task_request OR a.id_task_dest = i_task_request))
        LOOP
        
            l_all_tasks.extend;
            l_all_tasks(l_all_tasks.count) := row.id_task_orig;
            l_all_tasks.extend;
            l_all_tasks(l_all_tasks.count) := row.id_task_dest;
        END LOOP;
    
        SELECT a.flg_type
          BULK COLLECT
          INTO l_t
          FROM cpoe_tasks_relation a
         WHERE a.id_task_type = i_task_type
           AND (a.id_task_orig IN (SELECT column_value
                                     FROM TABLE(l_all_tasks)) OR
               a.id_task_dest IN (SELECT column_value
                                     FROM TABLE(l_all_tasks)));
    
        /*CASE i_flg_filter WHEN 'N' THEN l_n := 'P';
        WHEN 'D' THEN l_d := 'R';
        ELSE l_a := 'A'; 
        END CASE;*/
    
        FOR i IN 1 .. l_t.count
        LOOP
            l_inst := instr(l_t(i), 'A');
            IF l_inst > 0
            --AND i_flg_filter NOT IN ('C', 'A')
            THEN
                l_a := 'A';
            END IF;
        
            l_inst := instr(l_t(i), 'N');
            IF l_inst > 0
            --AND i_flg_filter NOT IN ('N')
            THEN
                l_n := 'P';
            END IF;
        
            l_inst := instr(l_t(i), 'D');
            IF l_inst > 0
            --AND i_flg_filter NOT IN ('D')
            THEN
                l_d := 'R';
            END IF;
        
            l_inst := instr(l_t(i), 'REP');
            IF l_inst > 0
            THEN
                IF l_a IS NULL
                --AND i_flg_filter NOT IN ('C', 'A')
                THEN
                    l_a := 'A';
                END IF;
                IF l_n IS NULL
                --AND i_flg_filter NOT IN ('N')
                THEN
                    l_n := 'P';
                END IF;
            
            END IF;
        
        END LOOP;
    
        IF l_a IS NOT NULL
           AND l_n IS NOT NULL
           AND l_d IS NOT NULL
        THEN
            l_ret := pk_message.get_message(i_lang, 'CPOE_RELATION_TAND');
        ELSIF l_a IS NOT NULL
              AND l_n IS NOT NULL
        THEN
            l_ret := pk_message.get_message(i_lang, 'CPOE_RELATION_TAN');
        ELSIF l_a IS NOT NULL
              AND l_d IS NOT NULL
        THEN
            l_ret := pk_message.get_message(i_lang, 'CPOE_RELATION_TAD');
        ELSIF l_n IS NOT NULL
              AND l_d IS NOT NULL
        THEN
            l_ret := pk_message.get_message(i_lang, 'CPOE_RELATION_TND');
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CPOE',
                                              i_function => 'GET_TASKS_RELATION_TOOLTIP',
                                              o_error    => l_error);
            RETURN '';
    END get_tasks_relation_tooltip;

    FUNCTION group_close_open
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 AS
        l_task_type_parent cpoe_task_type.id_task_type%TYPE;
        l_flg_close_open   VARCHAR2(1 CHAR);
    BEGIN
        SELECT z.task_type_id
          INTO l_task_type_parent
          FROM (SELECT nvl(a.id_task_type_parent, a.id_task_type) task_type_id
                  FROM cpoe_task_soft_inst a
                 WHERE a.id_task_type = i_task_type
                   AND a.id_institution IN (0, i_prof.institution)
                   AND a.id_software IN (0, i_prof.software)
                 ORDER BY a.id_institution DESC, a.id_software DESC) z
         WHERE rownum = 1;
    
        SELECT z.flg_open_close_by_group_parent
          INTO l_flg_close_open
          FROM (SELECT a. flg_open_close_by_group_parent
                  FROM cpoe_task_soft_inst a
                 WHERE a.id_task_type = l_task_type_parent
                   AND a.id_institution IN (0, i_prof.institution)
                   AND a.id_software IN (0, i_prof.software)
                 ORDER BY a.id_institution DESC, a.id_software DESC) z
         WHERE rownum = 1;
    
        RETURN l_flg_close_open;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'E';
    END group_close_open;

    FUNCTION get_cpoe_grid
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_filter  IN VARCHAR2
    ) RETURN t_tbl_cpoe_task_list IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_cpoe_grid';
        l_params VARCHAR2(1000 CHAR);
        l_exception EXCEPTION;
        l_all_tasks       t_tbl_cpoe_task_list;
        l_cnt_all         NUMBER;
        l_cnt_current     NUMBER;
        l_cnt_active      NUMBER;
        l_cnt_draft       NUMBER;
        l_cnt_to_ack      NUMBER;
        l_flg_cpoe_mode   VARCHAR2(1 CHAR);
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        l_cfg_closed_task_filter sys_config.value%TYPE;
        l_sign_off_t034          sys_message.desc_message%TYPE;
        l_prof_cat               category.flg_type%TYPE;
        l_flg_default_filter     cpoe_task_type_status_filter.flg_filter_tab%TYPE;
    
        l_cnt_next             NUMBER;
        l_id_cpoe_process_rep  cpoe_process.id_cpoe_process%TYPE;
        l_dt_next_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_dt_next_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh      cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_flg_next_presc_avail VARCHAR2(1 CHAR);
    
        l_flg_profile profile_template.flg_profile%TYPE;
    
        l_med_admin pk_types.cursor_type;
        l_proc_plan pk_types.cursor_type;
        l_execution t_tbl_cpoe_execution;
    
        l_task_types table_number;
        l_error      t_error_out;
    
    BEGIN
    
        l_params := 'i_lang=' || i_lang || 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_filter=' || i_filter;
    
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        l_sign_off_t034 := pk_message.get_message(i_lang, i_prof, 'SIGN_OFF_T034');
        l_prof_cat      := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'get cpoe working mode' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- check current cpoe mode (o_cpoe_info is only used in advanced cpoe mode)
        g_error := 'get o_cpoe_info cursor' || ' / ' || l_params;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            -- get last cpoe information
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      l_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        g_error := 'get l_all_tasks and filter counters from get_task_list_all function' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_task_list_all(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_cpoe_mode       => l_flg_cpoe_mode,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_process_tasks   => NULL, -- main cpoe grid will never specify task requests
                                 i_cpoe_start_tstz => l_ts_cpoe_start,
                                 i_flg_report      => pk_alert_constant.g_no, -- discard report columns
                                 i_process         => NULL,
                                 i_tab_type        => i_filter,
                                 i_cpoe_status     => l_flg_cpoe_status,
                                 o_tasks           => l_all_tasks,
                                 o_task_types      => l_task_types,
                                 o_cnt_all         => l_cnt_all,
                                 o_cnt_current     => l_cnt_current,
                                 o_cnt_next        => l_cnt_next,
                                 o_cnt_active      => l_cnt_active,
                                 o_cnt_draft       => l_cnt_draft,
                                 o_cnt_to_ack      => l_cnt_to_ack,
                                 o_execution       => l_execution,
                                 o_med_admin       => l_med_admin,
                                 o_proc_plan       => l_proc_plan,
                                 o_error           => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN l_all_tasks;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_cpoe_grid;

    /********************************************************************************************
    * get all task types to be presented in main CPOE grid
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_filter                  task status filter for CPOE
    * @param       o_cpoe_grid               grid containing all task types
    * @param       o_cpoe_tabs               tabs containing descriptions and task counters
    * @param       o_cpoe_info               cursor containing information about current CPOE
    * @param       o_error                   error message
    *
    * @value       i_filter                  {*} 'C' Current
    *                                        {*} 'A' Active   
    *                                        {*} 'I' Inactive 
    *                                        {*} 'D' Draft
    *                                        {*} '*' All   
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_cpoe_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_filter       IN VARCHAR2,
        o_cpoe_grid    OUT pk_types.cursor_type,
        o_cpoe_tabs    OUT pk_types.cursor_type,
        o_cpoe_info    OUT pk_types.cursor_type,
        o_task_types   OUT table_number,
        o_can_req_next OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_cpoe_grid';
        l_params VARCHAR2(1000 CHAR);
        l_exception EXCEPTION;
        l_all_tasks       t_tbl_cpoe_task_list;
        l_cnt_all         NUMBER;
        l_cnt_current     NUMBER;
        l_cnt_active      NUMBER;
        l_cnt_draft       NUMBER;
        l_cnt_to_ack      NUMBER;
        l_flg_cpoe_mode   VARCHAR2(1 CHAR);
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        l_cfg_closed_task_filter sys_config.value%TYPE;
        l_sign_off_t034          sys_message.desc_message%TYPE;
        l_prof_cat               category.flg_type%TYPE;
        l_flg_default_filter     cpoe_task_type_status_filter.flg_filter_tab%TYPE;
    
        l_cnt_next             NUMBER;
        l_id_cpoe_process_rep  cpoe_process.id_cpoe_process%TYPE;
        l_dt_next_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_dt_next_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh      cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_flg_next_presc_avail VARCHAR2(1 CHAR);
    
        l_flg_profile profile_template.flg_profile%TYPE;
    
        l_med_admin                pk_types.cursor_type;
        l_proc_plan                pk_types.cursor_type;
        l_execution                t_tbl_cpoe_execution;
        l_flg_warning_out_of_stock VARCHAR2(1 CHAR);
    
    BEGIN
    
        l_params := 'i_lang=' || i_lang || 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_filter=' || i_filter;
    
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        l_sign_off_t034 := pk_message.get_message(i_lang, i_prof, 'SIGN_OFF_T034');
        l_prof_cat      := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'get cpoe working mode' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- check current cpoe mode (o_cpoe_info is only used in advanced cpoe mode)
        g_error := 'get o_cpoe_info cursor' || ' / ' || l_params;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            -- get last cpoe information
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- check if the warning for medications suspended by lack of stock is visible     
            l_flg_warning_out_of_stock := pk_api_pfh_in.get_pharm_show_alert_out_of_stock(i_lang       => i_lang,
                                                                                          i_prof       => i_prof,
                                                                                          i_id_episode => i_episode,
                                                                                          i_id_patient => i_patient);
        
            -- check if next prescription is available            
            l_flg_next_presc_avail := check_next_presc_availability(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_episode => i_episode);
        
            -- if next filter is selected and next prescription exists
            IF i_filter = g_filter_next
               AND l_flg_next_presc_avail = pk_alert_constant.g_yes
            THEN
                -- select next cpoe process for reporting
                get_next_presc_process(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => i_episode,
                                       o_cpoe_process => l_id_cpoe_process_rep,
                                       o_dt_start     => l_dt_next_start,
                                       o_dt_end       => l_dt_next_end);
            ELSE
                -- select current/last cpoe process for reporting
                l_id_cpoe_process_rep := l_cpoe_process;
            END IF;
        
            -- open o_cpoe_info cursor if a cpoe process exists
            IF l_flg_cpoe_status = g_flg_status_no_cpoe
               OR (l_flg_next_presc_avail = pk_alert_constant.g_no AND i_filter = g_filter_next)
            THEN
                -- in advanced mode, when no cpoe_process is created, the o_cpoe_info only contains one single line cpoe header
                OPEN o_cpoe_info FOR
                    SELECT NULL AS cpoe_status,
                           NULL AS cpoe_status_desc,
                           NULL AS cpoe_effectiveness,
                           NULL AS requested_by,
                           NULL AS id_cpoe_process,
                           pk_alert_constant.g_no flg_advanced_mode,
                           pk_message.get_message(i_lang, 'CPOE_T022') AS cpoe_header,
                           check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action) AS flg_create_cpoe_tasks
                      FROM dual;
            
            ELSE
                IF i_filter = g_filter_next
                THEN
                
                    OPEN o_cpoe_info FOR
                        SELECT l_flg_cpoe_status AS cpoe_status,
                               
                               pk_sysdomain.get_domain(g_domain_cpoe_flg_status, l_flg_cpoe_status, i_lang) AS cpoe_status_desc,
                               get_cpoe_message(i_lang,
                                                'CPOE_M008',
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_dt_next_start,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_dt_next_start,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_dt_next_end,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_dt_next_end,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                NULL) AS cpoe_effectiveness,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_professional) AS requested_by,
                               l_id_cpoe_process_rep AS id_cpoe_process,
                               pk_alert_constant.g_yes flg_advanced_mode,
                               pk_message.get_message(i_lang, 'CPOE_T000') AS cpoe_header,
                               decode(l_flg_cpoe_status,
                                      g_flg_status_a,
                                      g_flg_active,
                                      check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action)) AS flg_create_cpoe_tasks
                          FROM dual;
                
                ELSE
                    OPEN o_cpoe_info FOR
                        SELECT l_flg_cpoe_status AS cpoe_status,
                               pk_sysdomain.get_domain(g_domain_cpoe_flg_status, l_flg_cpoe_status, i_lang) AS cpoe_status_desc,
                               get_cpoe_message(i_lang,
                                                'CPOE_M008',
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_ts_cpoe_start,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_ts_cpoe_start,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_ts_cpoe_end,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_ts_cpoe_end,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                NULL) AS cpoe_effectiveness,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_professional) AS requested_by,
                               l_cpoe_process AS id_cpoe_process,
                               pk_alert_constant.g_yes flg_advanced_mode,
                               pk_message.get_message(i_lang, 'CPOE_T000') AS cpoe_header,
                               decode(l_flg_cpoe_status,
                                      g_flg_status_a,
                                      g_flg_active,
                                      check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action)) AS flg_create_cpoe_tasks
                          FROM dual;
                END IF;
            END IF;
        
        ELSE
            -- in simple mode, the o_cpoe_info only contains single line cpoe header
            OPEN o_cpoe_info FOR
                SELECT NULL AS cpoe_status,
                       NULL AS cpoe_status_desc,
                       NULL AS cpoe_effectiveness,
                       NULL AS requested_by,
                       NULL AS id_cpoe_process,
                       pk_message.get_message(i_lang, 'CPOE_T022') AS cpoe_header,
                       g_flg_active AS flg_create_cpoe_tasks
                  FROM dual;
        
        END IF;
    
        g_error := 'get l_all_tasks and filter counters from get_task_list_all function' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_task_list_all(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_cpoe_mode       => l_flg_cpoe_mode,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_process_tasks   => NULL, -- main cpoe grid will never specify task requests
                                 i_cpoe_start_tstz => l_ts_cpoe_start,
                                 i_flg_report      => pk_alert_constant.g_no, -- discard report columns
                                 i_process         => nvl(l_id_cpoe_process_rep, l_cpoe_process),
                                 i_tab_type        => i_filter,
                                 i_cpoe_status     => l_flg_cpoe_status,
                                 o_tasks           => l_all_tasks,
                                 o_task_types      => o_task_types,
                                 o_cnt_all         => l_cnt_all,
                                 o_cnt_current     => l_cnt_current,
                                 o_cnt_next        => l_cnt_next,
                                 o_cnt_active      => l_cnt_active,
                                 o_cnt_draft       => l_cnt_draft,
                                 o_cnt_to_ack      => l_cnt_to_ack,
                                 o_execution       => l_execution,
                                 o_med_admin       => l_med_admin,
                                 o_proc_plan       => l_proc_plan,
                                 o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- get default filter tab
        IF i_filter IS NULL
        THEN
            g_error := 'call to GET_DEFAULT_FILTER function' || ' / ' || l_params;
            IF NOT get_default_filter(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_prof_cat           => l_prof_cat,
                                      i_flg_cpoe_mode      => l_flg_cpoe_mode,
                                      i_cnt_to_ack         => l_cnt_to_ack,
                                      o_flg_default_filter => l_flg_default_filter,
                                      o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_flg_default_filter := i_filter;
        END IF;
    
        g_error := 'get o_cpoe_grid cursor' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN o_cpoe_grid FOR
            SELECT get_task_group_id(i_prof, all_tasks.id_task_type) AS group_type_id,
                   get_task_group_name(i_lang,
                                       i_prof,
                                       all_tasks.id_task_type,
                                       decode(i_filter,
                                              g_filter_current,
                                              pk_alert_constant.g_yes,
                                              pk_alert_constant.g_no)) AS task_group_desc,
                   get_task_group_rank(i_prof, all_tasks.id_task_type) AS task_group_rank,
                   all_tasks.id_task_type AS task_type_id,
                   all_tasks.id_target_task_type AS id_target_task_type,
                   get_task_type_rank(i_prof, all_tasks.id_task_type) AS task_type_rank,
                   get_task_group_id(i_prof, all_tasks.id_task_type) AS id_task_type_group,
                   all_tasks.rank AS task_rank,
                   all_tasks.task_description AS task_desc,
                   all_tasks.task_title AS task_title,
                   -- A procedure order with co-sign of an external professional 
                   decode(all_tasks.id_profissional,
                          -2,
                          l_sign_off_t034,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, all_tasks.id_profissional)) AS prof,
                   pk_date_utils.date_send_tsz(i_lang, all_tasks.start_date_tstz, i_prof) AS start_date,
                   pk_date_utils.date_send_tsz(i_lang, all_tasks.end_date_tstz, i_prof) AS end_date,
                   pk_date_utils.date_char_tsz(i_lang,
                                               all_tasks.creation_date_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS date_desc,
                   all_tasks.status_str AS status_string,
                   nvl(all_tasks.task_icon, get_task_type_icon(i_lang, i_prof, all_tasks.id_task_type)) AS icon,
                   all_tasks.icon_warning,
                   all_tasks.id_request,
                   all_tasks.flg_status,
                   decode(l_flg_profile,
                          pk_cpoe.g_flg_profile_template_student,
                          (decode(i_filter, g_filter_draft, all_tasks.flg_cancel, pk_alert_constant.g_no)),
                          all_tasks.flg_cancel) flg_cancel,
                   (CASE
                        WHEN l_flg_default_filter IN (g_filter_draft, g_task_filter_all) THEN
                         all_tasks.flg_conflict
                        ELSE
                         pk_alert_constant.g_no
                    END) AS flg_conflict,
                   nvl((SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                        pk_alert_constant.g_yes
                         FROM TABLE(all_tasks.visible_tabs) t
                        WHERE t.column_value = g_filter_draft),
                       pk_alert_constant.g_no) AS flg_draft,
                   decode(i_filter,
                          g_filter_draft,
                          decode(set_task_bounds(i_lang,
                                                 i_prof,
                                                 all_tasks.id_task_type,
                                                 all_tasks.start_date_tstz,
                                                 all_tasks.end_date_tstz,
                                                 l_ts_cpoe_start,
                                                 l_ts_cpoe_end,
                                                 NULL,
                                                 NULL),
                                 g_task_bound_curr_presc,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_no),
                          all_tasks.flg_current) AS flg_current,
                   all_tasks.flg_next,
                   all_tasks.id_task,
                   get_cds_task_type(id_task_type) AS cds_id_task_type,
                   all_tasks.instr_bg_color AS instr_bg_color,
                   all_tasks.instr_bg_alpha AS instr_bg_alpha,
                   all_tasks.flg_need_ack AS flg_need_ack,
                   all_tasks.edit_icon AS edit_icon,
                   all_tasks.action_desc AS action_desc,
                   all_tasks.id_task_type_source AS id_task_type_source,
                   all_tasks.id_task_dependency AS id_task_dependency,
                   all_tasks.flg_rep_cancel AS flg_rep_cancel,
                   get_tasks_relation(i_lang, i_prof, all_tasks.id_task_type, all_tasks.id_request, i_filter) tasks_relation,
                   get_tasks_relation_tooltip(i_lang, i_prof, all_tasks.id_task_type, all_tasks.id_request, i_filter) tasks_relation_tooltip,
                   group_close_open(i_lang, i_prof, all_tasks.id_task_type) group_close_open
              FROM TABLE(CAST(l_all_tasks AS t_tbl_cpoe_task_list)) all_tasks
             WHERE EXISTS (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                     *
                      FROM TABLE(all_tasks.visible_tabs) t
                     WHERE t.column_value = l_flg_default_filter)
             ORDER BY task_group_rank, task_type_rank, all_tasks.rank;
    
        -- get closed task filter interval in days
        g_error := 'get CPOE_CLOSED_TASK_FILTER_INTERVAL sys_config' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_closed_task_filter, i_prof, l_cfg_closed_task_filter)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'get o_cpoe_tabs cursor' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN o_cpoe_tabs FOR
            SELECT g_filter_current AS filter,
                   l_cnt_current AS counter,
                   pk_message.get_message(i_lang, g_tab_desc_current) || ' (' || l_cnt_current || ')' AS tab_desc,
                   decode(l_flg_warning_out_of_stock,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) AS flg_tab_warning,
                   decode(l_flg_warning_out_of_stock,
                          pk_alert_constant.g_yes,
                          pk_message.get_message(i_lang, 'CPOE_M043'),
                          NULL) AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_current, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
            UNION ALL
            SELECT g_filter_active AS filter,
                   l_cnt_active AS counter,
                   pk_message.get_message(i_lang, g_tab_desc_active) || ' (' || l_cnt_active || ')' AS tab_desc,
                   decode(l_flg_cpoe_mode, g_cfg_cpoe_mode_advanced, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_tab_warning,
                   REPLACE(pk_message.get_message(i_lang, g_inactive_tasks_warning), '@1', l_cfg_closed_task_filter) AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_active, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_flg_cpoe_mode = g_cfg_cpoe_mode_simple
            -- next prescription (advanced mode)
            UNION ALL
            SELECT g_filter_next AS filter,
                   l_cnt_next AS counter,
                   pk_message.get_message(i_lang, g_tab_desc_next) || ' (' || l_cnt_next || ')' AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_next, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
            --AND l_flg_next_presc_avail = pk_alert_constant.g_yes
            UNION ALL
            SELECT g_filter_to_ack AS filter,
                   l_cnt_to_ack AS counter,
                   pk_message.get_message(i_lang, g_tab_desc_to_ack) || ' (' || l_cnt_to_ack || ')' AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_to_ack, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_prof_cat = pk_alert_constant.g_cat_type_nurse
            UNION ALL
            SELECT g_filter_draft AS filter,
                   l_cnt_draft AS counter,
                   decode(l_flg_cpoe_mode,
                          g_cfg_cpoe_mode_advanced,
                          pk_message.get_message(i_lang, g_tab_desc_draft_presc),
                          pk_message.get_message(i_lang, g_tab_desc_draft)) || ' (' || l_cnt_draft || ')' AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_draft, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
            UNION ALL
            -- SELECT g_filter_inactive AS filter,
            --        l_cnt_inactive AS counter,
            --        pk_message.get_message(i_lang, g_tab_desc_inactive) || ' (' || l_cnt_inactive || ')' AS tab_desc,
            --        pk_alert_constant.g_yes AS flg_tab_warning,
            --        REPLACE(pk_message.get_message(i_lang, g_inactive_tasks_warning), '@1', l_cfg_closed_task_filter) AS tab_warning_label,
            --        decode(l_default_filter, g_filter_inactive, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
            --   FROM dual
            -- UNION ALL
            SELECT g_filter_all AS filter,
                   l_cnt_all AS counter,
                   pk_message.get_message(i_lang, g_tab_desc_all) || ' (' || l_cnt_all || ')' AS tab_desc,
                   pk_alert_constant.g_yes AS flg_tab_warning,
                   REPLACE(pk_message.get_message(i_lang, g_inactive_tasks_warning), '@1', l_cfg_closed_task_filter) AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_all, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual;
    
        o_can_req_next := check_next_presc_can_req(i_lang, i_prof, i_episode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_grid);
            pk_types.open_my_cursor(o_cpoe_tabs);
            pk_types.open_my_cursor(o_cpoe_info);
            RETURN FALSE;
        
    END get_cpoe_grid;

    FUNCTION get_cpoe_info_grid
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_filter    IN VARCHAR2,
        o_cpoe_tabs OUT pk_types.cursor_type,
        o_cpoe_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_cpoe_info_grid';
        l_params VARCHAR2(1000 CHAR);
        l_exception EXCEPTION;
    
        l_flg_cpoe_mode   VARCHAR2(1 CHAR);
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        l_cfg_closed_task_filter sys_config.value%TYPE;
        l_prof_cat               category.flg_type%TYPE;
        l_flg_default_filter     cpoe_task_type_status_filter.flg_filter_tab%TYPE;
    
        l_cnt_next             NUMBER;
        l_id_cpoe_process_rep  cpoe_process.id_cpoe_process%TYPE;
        l_dt_next_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_dt_next_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_flg_next_presc_avail VARCHAR2(1 CHAR);
    
    BEGIN
    
        l_params := 'i_lang=' || i_lang || 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_filter=' || i_filter;
    
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'get cpoe working mode' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- check current cpoe mode (o_cpoe_info is only used in advanced cpoe mode)
        g_error := 'get o_cpoe_info cursor' || ' / ' || l_params;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            -- get last cpoe information
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- check if next prescription is available            
            l_flg_next_presc_avail := check_next_presc_availability(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_episode => i_episode);
            --l_flg_next_presc_avail := 'Y';
            -- if next filter is selected and next prescription exists
            IF i_filter = g_filter_next
               AND l_flg_next_presc_avail = pk_alert_constant.g_yes
            THEN
                -- select next cpoe process for reporting
                get_next_presc_process(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => i_episode,
                                       o_cpoe_process => l_id_cpoe_process_rep,
                                       o_dt_start     => l_dt_next_start,
                                       o_dt_end       => l_dt_next_end);
            ELSE
                -- select current/last cpoe process for reporting
                l_id_cpoe_process_rep := l_cpoe_process;
            END IF;
        
            -- open o_cpoe_info cursor if a cpoe process exists
            IF l_flg_cpoe_status = g_flg_status_no_cpoe
            THEN
                -- in advanced mode, when no cpoe_process is created, the o_cpoe_info only contains one single line cpoe header
                OPEN o_cpoe_info FOR
                    SELECT NULL AS cpoe_status,
                           NULL AS cpoe_status_desc,
                           NULL AS cpoe_effectiveness,
                           NULL AS requested_by,
                           NULL AS id_cpoe_process,
                           pk_message.get_message(i_lang, 'CPOE_T022') AS cpoe_header,
                           check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action) AS flg_create_cpoe_tasks
                      FROM dual;
            
            ELSE
                IF i_filter = g_filter_next
                THEN
                    OPEN o_cpoe_info FOR
                        SELECT l_flg_cpoe_status AS cpoe_status,
                               
                               pk_sysdomain.get_domain(g_domain_cpoe_flg_status, l_flg_cpoe_status, i_lang) AS cpoe_status_desc,
                               get_cpoe_message(i_lang,
                                                'CPOE_M008',
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_dt_next_start,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_dt_next_start,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_dt_next_end,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_dt_next_end,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                NULL) AS cpoe_effectiveness,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_professional) AS requested_by,
                               l_id_cpoe_process_rep AS id_cpoe_process,
                               pk_message.get_message(i_lang, 'CPOE_T000') AS cpoe_header,
                               decode(l_flg_cpoe_status,
                                      g_flg_status_a,
                                      g_flg_active,
                                      check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action)) AS flg_create_cpoe_tasks
                          FROM dual;
                
                ELSE
                    OPEN o_cpoe_info FOR
                        SELECT l_flg_cpoe_status AS cpoe_status,
                               pk_sysdomain.get_domain(g_domain_cpoe_flg_status, l_flg_cpoe_status, i_lang) AS cpoe_status_desc,
                               get_cpoe_message(i_lang,
                                                'CPOE_M008',
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_ts_cpoe_start,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_ts_cpoe_start,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 l_ts_cpoe_end,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                                pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                      l_ts_cpoe_end,
                                                                                      i_prof.institution,
                                                                                      i_prof.software),
                                                NULL) AS cpoe_effectiveness,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_professional) AS requested_by,
                               l_cpoe_process AS id_cpoe_process,
                               pk_message.get_message(i_lang, 'CPOE_T000') AS cpoe_header,
                               decode(l_flg_cpoe_status,
                                      g_flg_status_a,
                                      g_flg_active,
                                      check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action)) AS flg_create_cpoe_tasks
                          FROM dual;
                END IF;
            END IF;
        
        ELSE
            -- in simple mode, the o_cpoe_info only contains single line cpoe header
            OPEN o_cpoe_info FOR
                SELECT NULL AS cpoe_status,
                       NULL AS cpoe_status_desc,
                       NULL AS cpoe_effectiveness,
                       NULL AS requested_by,
                       NULL AS id_cpoe_process,
                       pk_message.get_message(i_lang, 'CPOE_T022') AS cpoe_header,
                       g_flg_active AS flg_create_cpoe_tasks
                  FROM dual;
        
        END IF;
    
        -- get default filter tab
        IF i_filter IS NULL
        THEN
            g_error := 'call to GET_DEFAULT_FILTER function' || ' / ' || l_params;
            IF NOT get_default_filter(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_prof_cat           => l_prof_cat,
                                      i_flg_cpoe_mode      => l_flg_cpoe_mode,
                                      o_flg_default_filter => l_flg_default_filter,
                                      o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_flg_default_filter := i_filter;
        END IF;
    
        -- get closed task filter interval in days
        g_error := 'get CPOE_CLOSED_TASK_FILTER_INTERVAL sys_config' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_closed_task_filter, i_prof, l_cfg_closed_task_filter)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'get o_cpoe_tabs cursor' || ' / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN o_cpoe_tabs FOR
            SELECT g_filter_current AS filter,
                   pk_message.get_message(i_lang, g_tab_desc_current) AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_current, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
            UNION ALL
            SELECT g_filter_active AS filter,
                   pk_message.get_message(i_lang, g_tab_desc_active) AS tab_desc,
                   decode(l_flg_cpoe_mode, g_cfg_cpoe_mode_advanced, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_tab_warning,
                   REPLACE(pk_message.get_message(i_lang, g_inactive_tasks_warning), '@1', l_cfg_closed_task_filter) AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_active, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_flg_cpoe_mode = g_cfg_cpoe_mode_simple
            -- next prescription (advanced mode)
            UNION ALL
            SELECT g_filter_next AS filter,
                   pk_message.get_message(i_lang, g_tab_desc_next) AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_next, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
            
              FROM dual
             WHERE l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
               AND l_flg_next_presc_avail = pk_alert_constant.g_yes
            UNION ALL
            SELECT g_filter_to_ack AS filter,
                   pk_message.get_message(i_lang, g_tab_desc_to_ack) AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_to_ack, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
             WHERE l_prof_cat = pk_alert_constant.g_cat_type_nurse
            UNION ALL
            SELECT g_filter_draft AS filter,
                   decode(l_flg_cpoe_mode,
                          g_cfg_cpoe_mode_advanced,
                          pk_message.get_message(i_lang, g_tab_desc_draft_presc),
                          pk_message.get_message(i_lang, g_tab_desc_draft)) AS tab_desc,
                   pk_alert_constant.g_no AS flg_tab_warning,
                   NULL AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_draft, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual
            UNION ALL
            SELECT g_filter_all AS filter,
                   pk_message.get_message(i_lang, g_tab_desc_all) AS tab_desc,
                   pk_alert_constant.g_yes AS flg_tab_warning,
                   REPLACE(pk_message.get_message(i_lang, g_inactive_tasks_warning), '@1', l_cfg_closed_task_filter) AS tab_warning_label,
                   decode(l_flg_default_filter, g_filter_all, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_INFO_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_tabs);
            pk_types.open_my_cursor(o_cpoe_info);
            RETURN FALSE;
        
    END get_cpoe_info_grid;

    /********************************************************************************************
    * check if the next prescription should be available ot not
    *
    * @param   i_lang        preferred language id for this professional
    * @param   i_prof        professional id structure
    * @param   i_episode     episode id  
    *
    * @return  varchar2      availability of next prescription
    *
    * @value   return        {*} 'Y' next prescription actions should be available
    *                        {*} 'N' next prescription actions shouldn't be available
    *    
    * @author                Carlos Loureiro
    * @since                 26-JUL-2012
    ********************************************************************************************/
    FUNCTION check_next_presc_availability
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ts_cpoe_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_next_proc_exists     BOOLEAN;
        o_error                t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang,
                                                        i_prof.institution,
                                                        current_timestamp,
                                                        l_ts_current_timestamp,
                                                        o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.check_next_presc_availability called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' ||
                                  i_episode,
                                  g_package_name);
        END IF;
    
        -- get prescription limits, based in selected filter
        get_presc_limits(i_lang           => i_lang,
                         i_prof           => i_prof,
                         i_episode        => i_episode,
                         i_filter         => g_filter_next,
                         i_task_type      => NULL,
                         o_ts_presc_start => l_ts_cpoe_start,
                         o_ts_presc_end   => l_ts_cpoe_end,
                         o_ts_next_presc  => l_ts_cpoe_next_presc,
                         o_proc_exists    => l_next_proc_exists);
    
        -- output parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.check_next_presc_availability processed values:' || chr(10) ||
                                  'l_ts_cpoe_start=' || l_ts_cpoe_start || chr(10) || 'l_ts_cpoe_end=' ||
                                  l_ts_cpoe_end || chr(10) || 'l_ts_cpoe_next_presc=' || l_ts_cpoe_next_presc ||
                                  chr(10) || 'l_ts_current_timestamp=' || l_ts_current_timestamp,
                                  g_package_name);
        END IF;
    
        -- check if next prescription filter should be available or not                                
        IF l_next_proc_exists
           OR l_ts_current_timestamp >= l_ts_cpoe_next_presc
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        -- when is not possible to calculate next prescription timestamp availability
        WHEN e_next_presc_wo_active_presc THEN
            IF g_debug
            THEN
                pk_alertlog.log_debug('pk_cpoe.check_next_presc_availability couldn''t calculate next prescription timestamp: assume that is not possible to create next prescription',
                                      g_package_name);
            END IF;
            RETURN pk_alert_constant.g_no;
        
    END check_next_presc_availability;

    /********************************************************************************************
    * get task status refresh flag to indicate if task should be copied to draft prescription 
    *
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   varchar2                  refresh flag
    *
    * @value    get_task_status_refresh   {*} 'Y' task should be refreshed to draft area
    *                                     {*} 'N' do not refresh task to draft area    
    *
    * @author                             Carlos Loureiro
    * @since                              07-Sep-2010
    ********************************************************************************************/
    FUNCTION get_task_status_refresh
    (
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_flg_refresh VARCHAR2(1 CHAR);
    BEGIN
        SELECT sf.flg_cpoe_proc_refresh
          INTO l_flg_refresh
          FROM cpoe_task_type_status_filter sf
         WHERE sf.id_task_type = i_task_type
           AND sf.flg_status = i_flg_status;
        RETURN l_flg_refresh;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
    END get_task_status_refresh;

    /********************************************************************************************
    * get task status new prescription flag to indicate if task should be considered in new prescription
    *
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   varchar2                  new process flag
    *
    * @value    get_task_status_refresh   {*} 'Y' task should be considered in new prescription
    *                                     {*} 'N' do not consider task in new prescription
    *
    * @author                             Carlos Loureiro
    * @since                              13-Sep-2010
    ********************************************************************************************/
    FUNCTION get_task_status_new_presc
    (
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_flg_new_presc VARCHAR2(1 CHAR);
    BEGIN
        SELECT sf.flg_cpoe_proc_new
          INTO l_flg_new_presc
          FROM cpoe_task_type_status_filter sf
         WHERE sf.id_task_type = i_task_type
           AND sf.flg_status = i_flg_status;
        RETURN l_flg_new_presc;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
    END get_task_status_new_presc;

    /********************************************************************************************
    * verify CPOE working mode for given institution or software
    *
    * @param       i_lang            preferred language id for this professional    
    * @param       i_prof            professional id structure
    * @param       o_flg_mode        CPOE working mode 
    * @param       o_error           error message
    *
    * @value       o_flg_mode        {*} 'S' working in simple mode 
    *                                {*} 'A' working in advanced mode
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         2009/11/06
    ********************************************************************************************/
    FUNCTION get_cpoe_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_mode OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_tbl_cfg t_tbl_config_table;
    BEGIN
    
        g_error := 'get CPOE_MODE sys_config';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        /*IF NOT pk_sysconfig.get_config(g_cfg_cpoe_mode, i_prof, o_flg_mode)
        THEN
            RAISE l_exception;
        END IF;*/
    
        g_error   := 'CALL PK_CORE_CONFIG.TF_CONFIG';
        l_tbl_cfg := pk_core_config.tf_config(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_config_table => g_cfg_cpoe_mode,
                                              i_prof_dcs     => table_number(NULL),
                                              i_episode      => i_episode);
    
        IF l_tbl_cfg IS NULL
           OR l_tbl_cfg.count = 0
        THEN
            o_flg_mode := g_cfg_cpoe_mode_simple;
        ELSE
            o_flg_mode := l_tbl_cfg(1).field_01;
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
                                              'GET_CPOE_MODE',
                                              o_error);
            RETURN FALSE;
    END get_cpoe_mode;

    /********************************************************************************************
    * verify if draft prescription refresh should delete or not draft tasks before refresh action
    *
    * @param       i_lang            preferred language id for this professional    
    * @param       i_prof            professional id structure
    * @param       i_auto_mode       indicates if this function is called by an automatic job
    * @param       o_flg_del         flag that indicates if draft task should be deleted before 
    *                                prescription refresh
    * @param       o_error           error message
    *
    * @value       i_auto_mode       {*} 'Y' this function is being called by the system
    *                                {*} 'N' this function is being called by the user
    *
    * @value       o_flg_del         {*} 'Y' drafts should be deleted
    *                                {*} 'N' drafts shouldn't be deleted
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         03-Set-2010
    ********************************************************************************************/
    FUNCTION get_delete_on_refresh
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_auto_mode IN VARCHAR2,
        o_flg_del   OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'get CPOE_DEL_DRAFT_IN_..._REFRESH_PRESC sys_config';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT pk_sysconfig.get_config(CASE i_auto_mode WHEN pk_alert_constant.g_yes THEN g_cfg_cpoe_del_auto_refresh ELSE
                                       g_cfg_cpoe_del_manual_refresh END,
                                       i_prof,
                                       o_flg_del)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_flg_del IS NULL
        THEN
            o_flg_del := pk_alert_constant.g_no;
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
                                              'GET_DELETE_ON_REFRESH',
                                              o_error);
            RETURN FALSE;
    END get_delete_on_refresh;

    /********************************************************************************************
    * verify if draft prescription activation should delete or not draft tasks that weren't used
    *
    * @param       i_lang            preferred language id for this professional    
    * @param       i_prof            professional id structure
    * @param       o_flg_del         flag that indicates if draft tasks should be deleted after 
    *                                draft prescription activation
    * @param       o_error           error message
    *
    * @value       o_flg_del         {*} 'Y' drafts should be deleted
    *                                {*} 'N' drafts shouldn't be deleted
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         14-Set-2010
    ********************************************************************************************/
    FUNCTION get_delete_on_activate
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_flg_del OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'get CPOE_DEL_DRAFT_IN_PRESC_ACTIVATION sys_config';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_del_presc_activ, i_prof, o_flg_del)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_flg_del IS NULL
        THEN
            o_flg_del := pk_alert_constant.g_no;
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
                                              'GET_DELETE_ON_ACTIVATE',
                                              o_error);
            RETURN FALSE;
    END get_delete_on_activate;

    /********************************************************************************************
    * verify if creation of a new cpoe process or prescription should be confirmed by the user
    *
    * @param       i_lang            preferred language id for this professional    
    * @param       i_prof            professional id structure
    * @param       o_flg_confirm     flag that indicates creation of a new process should be confirmed by the user
    * @param       o_error           error message
    *
    * @value       o_flg_confirm     {*} 'Y' creation of a new process should be confirmed by the user
    *                                {*} 'N' no confirmation needed for new process creation
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         16-Set-2010
    ********************************************************************************************/
    FUNCTION get_confirm_on_cpoe_creation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_flg_confirm OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'get CPOE_NEW_PRESC_CONFIRMATION sys_config';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_confirm_creation, i_prof, o_flg_confirm)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_flg_confirm IS NULL
        THEN
            o_flg_confirm := pk_alert_constant.g_yes;
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
                                              'GET_CONFIRM_ON_CPOE_CREATION',
                                              o_error);
            RETURN FALSE;
    END get_confirm_on_cpoe_creation;

    /********************************************************************************************
    * verify if draft prescription refresh should delete or not draft tasks before refresh action
    *
    * @param       i_lang                  preferred language id for this professional    
    * @param       i_prof                  professional id structure
    * @param       o_flg_copy_to_new_presc flag that indicates if draft task should be deleted before 
    *                                      prescription refresh
    * @param       o_error                 error message
    *
    * @value       o_flg_copy_to_new_presc {*} 'Y' drafts should be deleted
    *                                      {*} 'N' drafts shouldn't be deleted
    *
    * @return      boolean                 true or false on success or error
    *
    * @author                              Carlos Loureiro
    * @since                               13-Set-2010
    ********************************************************************************************/
    FUNCTION get_cfg_copy_active_new_presc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_flg_copy_to_new_presc OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'get CPOE_NEW_PRESC_COPY_ACTIVE sys_config';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_copy_active_presc, i_prof, o_flg_copy_to_new_presc)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_flg_copy_to_new_presc IS NULL
        THEN
            o_flg_copy_to_new_presc := pk_alert_constant.g_no;
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
                                              'GET_CFG_COPY_ACTIVE_NEW_PRESC',
                                              o_error);
            RETURN FALSE;
    END get_cfg_copy_active_new_presc;

    /********************************************************************************************
    * get all actions of a task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               type of the task
    * @param       i_task_requests           List of task requisition identifiers
    * @param       o_task_actions            list of task actions 
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_type     IN cpoe_task_type.id_task_type%TYPE,
        i_task_requests IN table_number,
        o_task_actions  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'get o_task_actions cursor for i_task_type=' || to_char(i_task_type) || ', i_task_request.count' ||
                   i_task_requests.count || ', i_episode=' || i_episode;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE
        -- monitorization
            WHEN i_task_type = g_task_type_monitorization THEN
            
                IF NOT pk_monitorization.get_task_actions(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_episode      => i_episode,
                                                          i_task_request => i_task_requests,
                                                          o_actions_list => o_task_actions,
                                                          o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- positioning
            WHEN i_task_type = g_task_type_positioning THEN
            
                IF NOT pk_pbl_inp_positioning.get_task_actions(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_episode      => i_episode,
                                                               i_task_request => i_task_requests(1),
                                                               o_actions_list => o_task_actions,
                                                               o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- hidric
            WHEN i_task_type = g_task_type_hidric_in_out
                 OR i_task_type = g_task_type_hidric_out
                 OR i_task_type = g_task_type_hidric_drain
                 OR i_task_type = g_task_type_hidric_in
                 OR i_task_type = g_task_type_hidric_out_all
                 OR i_task_type = g_task_type_hidric_irrigations THEN
            
                IF NOT pk_inp_hidrics_pbl.get_task_actions(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_episode      => i_episode,
                                                           i_task_request => i_task_requests(1),
                                                           o_actions_list => o_task_actions,
                                                           o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- diet
            WHEN i_task_type = g_task_type_diet_inst
                 OR i_task_type = g_task_type_diet_spec
                 OR i_task_type = g_task_type_diet_predefined THEN
            
                IF NOT pk_diet.get_task_actions(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_task_request => i_task_requests(1),
                                                o_actions      => o_task_actions,
                                                o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- procedure
            WHEN i_task_type = g_task_type_procedure THEN
            
                IF NOT pk_procedures_external_api_db.get_task_actions(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_episode      => i_episode,
                                                                      i_task_request => i_task_requests(1),
                                                                      o_action       => o_task_actions,
                                                                      o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            WHEN i_task_type = g_task_type_bp THEN
            
                IF NOT pk_bp_external_api_db.get_task_actions(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_episode      => i_episode,
                                                              i_task_request => i_task_requests(1),
                                                              o_action       => o_task_actions,
                                                              o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type = g_task_type_analysis THEN
            
                IF NOT pk_lab_tests_external_api_db.get_task_actions(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_episode      => i_episode,
                                                                     i_task_request => i_task_requests(1),
                                                                     o_action       => o_task_actions,
                                                                     o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type IN (g_task_type_image_exam, g_task_type_other_exam) THEN
            
                IF NOT pk_exams_external_api_db.get_task_actions(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_episode      => i_episode,
                                                                 i_task_request => i_task_requests(1),
                                                                 o_action       => o_task_actions,
                                                                 o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- nurse teaching
            WHEN i_task_type = g_task_type_nursing THEN
            
                IF NOT pk_patient_education_cpoe.get_task_actions(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_episode      => i_episode,
                                                                  i_task_request => i_task_requests(1),
                                                                  o_action       => o_task_actions,
                                                                  o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- medication
            WHEN i_task_type = g_task_type_medication THEN
            
                IF NOT pk_api_pfh_ordertools_in.get_medication_actions(i_lang   => i_lang,
                                                                       i_prof   => i_prof,
                                                                       i_presc  => i_task_requests(1),
                                                                       o_action => o_task_actions,
                                                                       o_error  => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- communication order
            WHEN i_task_type IN (g_task_type_com_order, g_task_type_medical_orders) THEN
            
                IF NOT pk_comm_orders_cpoe.get_task_actions(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_episode      => i_episode,
                                                            i_task_request => i_task_requests,
                                                            i_task_type    => i_task_type,
                                                            o_action       => o_task_actions,
                                                            o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSE
                o_task_actions := NULL;
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
                                              'GET_TASK_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_task_actions);
            RETURN FALSE;
    END get_task_actions;

    /********************************************************************************************
    * get all tasks actions
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               array of task type IDs
    * @param       i_id_request              array of task requisition IDs
    * @param       o_task_actions            list of tasks actions
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION get_task_actions_all
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN table_number,
        i_task_request IN table_number,
        o_task_actions OUT t_tbl_cpoe_actions_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_exception EXCEPTION;
    
        l_task_actions pk_types.cursor_type;
    
        l_rec_task_type    cpoe_task_type.id_task_type%TYPE;
        l_rec_task_request cpoe_process_task.id_task_request%TYPE;
        l_rec              t_rec_cpoe_actions_list := t_rec_cpoe_actions_list(NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL);
    
        l_rec_index PLS_INTEGER := 0;
    
        l_task_type table_number;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode ||
                    ' i_task_type.count=' || i_task_type.count || ' i_task_request.count=' || i_task_request.count;
        g_error  := 'verify how many tasks were selected / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- if was selected more than one task type, does not return actions
        g_error     := 'SET(i_task_type) / ' || l_params;
        l_task_type := SET(i_task_type);
        IF l_task_type.count > 1
        THEN
            RETURN TRUE;
        END IF;
    
        -- if was selected more than one task (other than comm orders), does not return actions
        -- note: comm orders is the only task type that supports multiple selection
        IF ((i_task_type.count > 1 OR i_task_request.count > 1) AND
           i_task_type(1) NOT IN (g_task_type_com_order, g_task_type_monitorization, g_task_type_nursing))
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'build o_actions table / ' || l_params;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- init actions table
        o_task_actions := t_tbl_cpoe_actions_list();
    
        -- get task type
        l_rec_task_type := i_task_type(1);
    
        IF NOT get_task_actions(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_episode       => i_episode,
                                i_task_type     => l_rec_task_type,
                                i_task_requests => i_task_request,
                                o_task_actions  => l_task_actions,
                                o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- open l_task_actions; (cursor l_task_actions is already open)
        LOOP
            g_error := 'fetch record from l_task_actions cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- if this task type support actions then fetch them
            IF l_task_actions IS NOT NULL
            THEN
                FETCH l_task_actions
                    INTO l_rec.id_action,
                         l_rec.id_parent,
                         l_rec.level_num,
                         l_rec.from_state,
                         l_rec.to_state,
                         l_rec.desc_action,
                         l_rec.icon,
                         l_rec.flg_default,
                         l_rec.flg_active,
                         l_rec.internal_name;
                EXIT WHEN l_task_actions%NOTFOUND;
            ELSE
                pk_types.open_my_cursor(l_task_actions);
                EXIT;
            END IF;
        
            -- extend and associates the new record into actions table
            o_task_actions.extend;
            l_rec_index := l_rec_index + 1;
            o_task_actions(l_rec_index) := l_rec;
        
        END LOOP;
    
        CLOSE l_task_actions;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_ACTIONS_ALL',
                                              o_error);
            RETURN FALSE;
    END get_task_actions_all;

    /********************************************************************************************
    * get CPOE actions
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id     
    * @param       i_filter                  task status filter for CPOE
    * @param       i_task_type               array with the selected task types
    * @param       i_task_request            array with the selected task requisition IDs    
    * @param       i_task_conflict           array with the conflicts indicator of the selected tasks (used for drafts only)
    * @param       i_task_draft              array with the drafts indicator of the selected tasks
    * @param       o_actions                 list of CPOE actions
    * @param       o_error                   error message
    *
    * @value       i_filter                  {*} 'C' Current
    *                                        {*} 'A' Active   
    *                                        {*} 'I' Inactive 
    *                                        {*} 'D' Draft
    *                                        {*} '*' All
    *                                        {*} 'H' History
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_filter        IN VARCHAR2,
        i_task_type     IN table_number,
        i_task_request  IN table_number,
        i_task_conflict IN table_varchar,
        i_task_draft    IN table_varchar,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_task_actions            t_tbl_cpoe_actions_list;
        l_num_tasks               PLS_INTEGER := i_task_type.count;
        l_flg_cpoe_mode           VARCHAR2(1 CHAR);
        l_flg_profile             profile_template.flg_profile%TYPE;
        l_flg_out_of_cpoe_process cpoe_task_soft_inst.flg_out_of_cpoe_process%TYPE;
        l_same_out_of_cpoe_proc   VARCHAR2(1) := pk_alert_constant.g_yes;
    
        l_can_req_next VARCHAR2(1 CHAR);
    BEGIN
    
        l_flg_profile  := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
        l_can_req_next := check_next_presc_can_req(i_lang, i_prof, i_episode);
    
        g_error := 'get cpoe working mode';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'get l_actions from get_task_list_function';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_task_actions_all(i_lang, i_prof, i_episode, i_task_type, i_task_request, l_task_actions, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --Check if all the tasks have the same flg_out_of_cpoe_process
        FOR i IN i_task_type.first .. i_task_type.last
        LOOP
            IF i = 1
            THEN
                l_flg_out_of_cpoe_process := task_out_of_cpoe_process(i_lang      => i_lang,
                                                                      i_prof      => i_prof,
                                                                      i_task_type => i_task_type(i));
            ELSE
                IF l_flg_out_of_cpoe_process !=
                   task_out_of_cpoe_process(i_lang => i_lang, i_prof => i_prof, i_task_type => i_task_type(i))
                THEN
                    l_same_out_of_cpoe_proc := pk_alert_constant.g_no;
                    EXIT;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'get o_actions cursor with cpoe actions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_actions FOR
        -- specific actions for the selected tasks
        -- returns external actions for tasks that are not drafts
            SELECT task_action.id_action     AS id_action,
                   task_action.desc_action   AS desc_action,
                   task_action.internal_name AS action,
                   task_action.flg_active    AS flg_active,
                   task_action.icon          AS icon,
                   a.rank                    AS rank,
                   task_action.to_state      AS to_state,
                   task_action.id_parent     AS id_parent,
                   task_action.level_num     AS "LEVEL"
              FROM TABLE(CAST(l_task_actions AS t_tbl_cpoe_actions_list)) task_action, action a
             WHERE i_filter NOT IN (g_filter_draft, g_filter_history) -- remark: history filter discards normal task actions
                  -- no one of the selected tasks is a draft
               AND NOT EXISTS (SELECT 1
                      FROM TABLE(i_task_draft) tsk_draft
                     WHERE tsk_draft.column_value = pk_alert_constant.g_yes)
               AND task_action.id_action = a.id_action
               AND l_flg_profile != pk_cpoe.g_flg_profile_template_student
            UNION ALL
            -- returns internal CPOE actions for draft tasks
            SELECT act.id_action,
                   pk_message.get_message(i_lang, i_prof, code_action) AS desc_action,
                   act.internal_name AS action,
                   -- if was selected at least one task without permissions
                   -- to perform the action then it must be inactive
                   decode((SELECT COUNT(1)
                            FROM TABLE(i_task_type) tsk_type
                           WHERE check_task_action_avail(i_lang,
                                                         i_prof,
                                                         tsk_type.column_value,
                                                         act.id_action,
                                                         i_episode) = g_flg_inactive),
                          0,
                          decode(act.id_action,
                                 -- if was selected more than one task then
                                 -- edit draft action must be inactive  
                                 g_cpoe_task_edit_draft_action,
                                 decode(i_task_type(1),
                                        g_task_type_nursing,
                                        (decode(act.from_state,
                                                pk_alert_constant.g_cancelled,
                                                (decode(l_num_tasks, 1, g_flg_active, g_flg_inactive)),
                                                g_flg_active)),
                                        decode(l_num_tasks, 1, g_flg_active, g_flg_inactive)),
                                 -- if was selected more than one task and
                                 -- and they do not present the same flg_out_of_cpoe_process
                                 -- activate draft action must be inactive  
                                 g_cpoe_task_activ_draft_action,
                                 decode(l_same_out_of_cpoe_proc,
                                        pk_alert_constant.g_no,
                                        g_flg_inactive,
                                        -- if was selected at least one draft with conflicts then
                                        -- activate draft action must be inactive                                               
                                        decode((SELECT COUNT(1)
                                                 FROM TABLE(i_task_conflict) tc
                                                WHERE tc.column_value = pk_alert_constant.g_yes),
                                               0,
                                               g_flg_active,
                                               g_flg_inactive),
                                        g_flg_active)),
                          g_flg_inactive) AS flg_active,
                   act.icon,
                   rank,
                   act.to_state,
                   NULL AS id_parent,
                   1 AS "LEVEL"
              FROM action act
             WHERE act.subject = g_cpoe_draft_actions
               AND act.id_action != g_cpoe_task_copy2draft_action
               AND (act.flg_status IS NULL OR act.flg_status != g_flg_inactive)
                  -- when working in simple mode, the g_cpoe_task_a_draft_new_action and g_cpoe_task_a_draft_cur_action are not available
                  -- when working in advanced mode, the g_cpoe_task_activ_draft_action is not available
               AND ((l_flg_cpoe_mode = g_cfg_cpoe_mode_simple AND
                   act.id_action NOT IN (g_cpoe_task_a_draft_new_action, g_cpoe_task_a_draft_cur_action)) OR
                   (l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced))
                  -- all selected tasks are drafts
               AND ((l_flg_profile = pk_cpoe.g_flg_profile_template_student AND
                   act.id_action != g_cpoe_task_activ_draft_action) OR
                   l_flg_profile != pk_cpoe.g_flg_profile_template_student)
               AND NOT EXISTS (SELECT 1
                      FROM TABLE(i_task_draft) tsk_draft
                     WHERE tsk_draft.column_value = pk_alert_constant.g_no)
            UNION ALL
            -- returns internal CPOE actions for all tasks except drafts
            SELECT act.id_action,
                   pk_message.get_message(i_lang, i_prof, code_action) AS desc_action,
                   act.internal_name AS action,
                   -- if was selected at least one task without permissions to perform
                   -- copy to draft action then it must be inactive
                   decode((SELECT COUNT(1)
                            FROM TABLE(i_task_type) tsk_type
                           WHERE check_task_action_avail(i_lang,
                                                         i_prof,
                                                         tsk_type.column_value,
                                                         act.id_action,
                                                         i_episode) = g_flg_inactive),
                          0,
                          g_flg_active,
                          g_flg_inactive) AS flg_active,
                   act.icon,
                   rank,
                   act.to_state,
                   NULL AS id_parent,
                   1 AS "LEVEL"
              FROM action act
             WHERE act.subject = g_cpoe_draft_actions
               AND act.id_action = g_cpoe_task_copy2draft_action
               AND i_filter != g_filter_draft
                  -- no one of the selected tasks is a draft
               AND NOT EXISTS (SELECT 1
                      FROM TABLE(i_task_draft) tsk_draft
                     WHERE tsk_draft.column_value = pk_alert_constant.g_yes)
            UNION ALL
            SELECT act.id_action,
                   pk_message.get_message(i_lang, i_prof, code_action) AS desc_action,
                   act.internal_name AS action,
                   -- if was selected at least one task without permissions to perform
                   -- copy to draft action then it must be inactive
                   decode(l_can_req_next, pk_alert_constant.g_no, g_flg_inactive, g_flg_active) AS flg_active,
                   act.icon,
                   1000 rank,
                   act.to_state,
                   NULL AS id_parent,
                   1 AS "LEVEL"
              FROM action act
             WHERE act.subject = g_cpoe_presc_actions
               AND act.id_action = g_cpoe_task_copy_next_presc
               AND i_filter NOT IN (g_filter_draft, g_filter_next)
               AND act.flg_status = pk_alert_constant.g_active
               AND l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
             ORDER BY rank, desc_action DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    /********************************************************************************************
    * check conflicts upon CPOE task drafts (verify if drafts can be requested or not)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               array of task type IDs
    * @param       i_draft                   list of draft ids
    * @param       o_flg_conflict            array of action conflicts indicators
    * @param       o_msg_template            array of message/pop-up templates
    * @param       o_msg_title               array of message titles
    * @param       o_msg_body                array of message bodies
    * @param       o_error                   error message
    *
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts
    *                                        {*} 'N' no conflicts found
    *
    * @value       o_msg_template            {*} 'WARNING_READ' Warning Read
    *                                        {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                                        {*} 'WARNING_CANCEL' Warning Cancel
    *                                        {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                                        {*} 'WARNING_SECURITY' Warning Security
    *                                        {*} 'CONFIRMATION' Confirmation
    *                                        {*} 'DETAIL' Detail
    *                                        {*} 'HELP' Help
    *                                        {*} 'WIZARD' Wizard
    *                                        {*} 'ADVANCED_INPUT' Advanced Input
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/25
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN table_number,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
        l_rec_task_type cpoe_task_type.id_task_type%TYPE;
        l_draft         table_number;
    
        l_new_conflict_index PLS_INTEGER := 0;
    
        l_flg_conflict table_varchar;
        l_msg_template table_varchar;
        l_msg_title    table_varchar;
        l_msg_body     table_varchar;
    
        l_flg_exist_conflicts BOOLEAN := FALSE;
    
    BEGIN
    
        -- init output variables that will collect conflicts
        o_flg_conflict := table_varchar();
        o_msg_template := table_varchar();
        o_msg_title    := table_varchar();
        o_msg_body     := table_varchar();
    
        g_error := 'check drafts conflicts';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop to check conflicts of each CPOE task draft
        FOR i IN i_task_type.first .. i_task_type.last
        LOOP
        
            -- init local variables that will collect conflicts
            l_flg_conflict := table_varchar();
            l_msg_template := table_varchar();
            l_msg_title    := table_varchar();
            l_msg_body     := table_varchar();
        
            -- get task type
            l_rec_task_type := i_task_type(i);
        
            -- get draft
            l_draft := table_number(i_draft(i));
        
            g_error := 'check if CPOE task draft has conflicts: i_task_type=' || to_char(l_rec_task_type) ||
                       ', i_draft=' || l_draft(1) || ', i_episode=' || i_episode;
            pk_alertlog.log_debug(g_error, g_package_name);
        
            CASE
            -- monitorization
                WHEN l_rec_task_type = g_task_type_monitorization THEN
                
                    IF NOT pk_monitorization.check_drafts_conflicts(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    l_draft,
                                                                    l_flg_conflict,
                                                                    l_msg_title,
                                                                    l_msg_body,
                                                                    l_msg_template,
                                                                    o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- positioning
                WHEN l_rec_task_type = g_task_type_positioning THEN
                
                    IF NOT pk_pbl_inp_positioning.check_drafts_conflicts(i_lang,
                                                                         i_prof,
                                                                         i_episode,
                                                                         l_draft,
                                                                         l_flg_conflict,
                                                                         l_msg_title,
                                                                         l_msg_body,
                                                                         l_msg_template,
                                                                         o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- hidric
                WHEN l_rec_task_type = g_task_type_hidric_in_out
                     OR l_rec_task_type = g_task_type_hidric_out
                     OR l_rec_task_type = g_task_type_hidric_drain
                     OR l_rec_task_type = g_task_type_hidric_in
                     OR l_rec_task_type = g_task_type_hidric_out_all
                     OR l_rec_task_type = g_task_type_hidric_irrigations THEN
                
                    IF NOT pk_inp_hidrics_pbl.check_drafts_conflicts(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_episode      => i_episode,
                                                                     i_draft        => l_draft,
                                                                     o_flg_conflict => l_flg_conflict,
                                                                     o_msg_title    => l_msg_title,
                                                                     o_msg_body     => l_msg_body,
                                                                     o_msg_template => l_msg_template,
                                                                     o_error        => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- diet
                WHEN l_rec_task_type = g_task_type_diet_inst
                     OR l_rec_task_type = g_task_type_diet_spec
                     OR l_rec_task_type = g_task_type_diet_predefined THEN
                
                    l_flg_conflict.extend;
                    l_msg_title.extend;
                    l_msg_body.extend;
                    l_msg_template.extend;
                
                    IF NOT pk_diet.check_drafts_conflicts(i_lang,
                                                          i_prof,
                                                          i_episode,
                                                          l_draft(1),
                                                          l_flg_conflict(1),
                                                          l_msg_title(1),
                                                          l_msg_body(1),
                                                          l_msg_template(1),
                                                          o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- procedure
                WHEN l_rec_task_type = g_task_type_procedure THEN
                
                    IF NOT pk_procedures_external_api_db.check_draft_conflicts(i_lang,
                                                                               i_prof,
                                                                               i_episode,
                                                                               l_draft,
                                                                               l_flg_conflict,
                                                                               l_msg_title,
                                                                               l_msg_body,
                                                                               l_msg_template,
                                                                               o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_bp THEN
                
                    IF NOT pk_bp_external_api_db.check_draft_conflicts(i_lang,
                                                                       i_prof,
                                                                       i_episode,
                                                                       l_draft,
                                                                       l_flg_conflict,
                                                                       l_msg_title,
                                                                       l_msg_body,
                                                                       l_msg_template,
                                                                       o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_analysis THEN
                    IF NOT pk_lab_tests_external_api_db.check_draft_conflicts(i_lang,
                                                                              i_prof,
                                                                              i_episode,
                                                                              l_draft,
                                                                              l_flg_conflict,
                                                                              l_msg_title,
                                                                              l_msg_body,
                                                                              l_msg_template,
                                                                              o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_image_exam THEN
                    IF NOT pk_exams_external_api_db.check_draft_conflicts(i_lang,
                                                                          i_prof,
                                                                          i_episode,
                                                                          l_draft,
                                                                          l_flg_conflict,
                                                                          l_msg_title,
                                                                          l_msg_body,
                                                                          l_msg_template,
                                                                          o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_other_exam THEN
                    IF NOT pk_exams_external_api_db.check_draft_conflicts(i_lang,
                                                                          i_prof,
                                                                          i_episode,
                                                                          l_draft,
                                                                          l_flg_conflict,
                                                                          l_msg_title,
                                                                          l_msg_body,
                                                                          l_msg_template,
                                                                          o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- nurse teaching
                WHEN l_rec_task_type = g_task_type_nursing THEN
                
                    IF NOT pk_patient_education_cpoe.check_draft_conflicts(i_lang,
                                                                           i_prof,
                                                                           i_episode,
                                                                           l_draft,
                                                                           l_flg_conflict,
                                                                           l_msg_title,
                                                                           l_msg_body,
                                                                           l_msg_template,
                                                                           o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- medication
                WHEN l_rec_task_type = g_task_type_medication THEN
                
                    NULL; -- check_draft_conflicts is not needed for new medication task type (will be handled in cds)
            
            -- communication order
                WHEN l_rec_task_type = g_task_type_com_order THEN
                
                    IF NOT pk_comm_orders_cpoe.check_draft_conflicts(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_episode      => i_episode,
                                                                     i_draft        => l_draft,
                                                                     o_flg_conflict => l_flg_conflict,
                                                                     o_msg_title    => l_msg_title,
                                                                     o_msg_body     => l_msg_body,
                                                                     o_msg_template => l_msg_template,
                                                                     o_error        => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                ELSE
                    NULL;
            END CASE;
        
            -- collect conflicts
            IF l_flg_conflict.count != 0
               AND l_flg_conflict(1) IS NOT NULL
            THEN
                FOR j IN l_flg_conflict.first .. l_flg_conflict.last
                LOOP
                
                    -- verify if at least one conflict was detected
                    IF l_flg_conflict(j) = pk_alert_constant.g_yes
                    THEN
                        l_flg_exist_conflicts := TRUE;
                    END IF;
                
                    o_flg_conflict.extend;
                    o_msg_template.extend;
                    o_msg_title.extend;
                    o_msg_body.extend;
                
                    l_new_conflict_index := l_new_conflict_index + 1;
                
                    o_flg_conflict(l_new_conflict_index) := l_flg_conflict(j);
                    o_msg_template(l_new_conflict_index) := l_msg_template(j);
                    o_msg_title(l_new_conflict_index) := l_msg_title(j);
                    o_msg_body(l_new_conflict_index) := l_msg_body(j);
                END LOOP;
            END IF;
        
        END LOOP;
    
        -- set o_flg_coflict variable equal to null
        -- if not conflicts were detected
        IF NOT l_flg_exist_conflicts
        THEN
            o_flg_conflict := NULL;
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
                                              'CHECK_DRAFTS_CONFLICTS',
                                              o_error);
            RETURN FALSE;
    END check_drafts_conflicts;

    /********************************************************************************************
    * activate CPOE task drafts
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               array of task type IDs
    * @param       i_draft                   list of draft ids
    * @param       i_flg_conflict_answer     array with the answers of the conflicts pop-ups
    * @param       i_cdr_call                clinical decision rules call id    
    * @param       o_new_task_request        array with the new generated requisition IDs
    * @param       o_error                   error message
    *
    * @value       i_flg_conflict_answer     {*} 'Y' draft must be activated even if it has conflicts
    *                                        {*} 'N' draft shouldn't be activated 
    *                                        {*} NULL there are no conflicts
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/24
    ********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_task_type           IN table_number,
        i_draft               IN table_number,
        i_flg_conflict_answer IN table_varchar,
        i_cdr_call            IN cdr_call.id_cdr_call%TYPE,
        o_new_task_request    OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
        l_rec_task_type cpoe_task_type.id_task_type%TYPE;
        l_draft         table_number;
    
        l_count        PLS_INTEGER := 0;
        l_created_reqs table_number;
    
    BEGIN
        -- init table
        o_new_task_request := table_number();
    
        g_error := 'activate drafts';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop to activate each CPOE task draft
        FOR i IN i_task_type.first .. i_task_type.last
        LOOP
        
            -- new draft request
            o_new_task_request.extend;
            l_count := l_count + 1;
        
            -- get task type
            l_rec_task_type := i_task_type(i);
        
            -- get draft
            l_draft := table_number(i_draft(i));
        
            g_error := 'check if CPOE task draft must be activated: i_task_type=' || to_char(l_rec_task_type) ||
                       ', i_draft=' || l_draft(1) || ', i_episode=' || i_episode;
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- activates draft if there are no conflicts or 
            -- if the conflict answer indicates that this draft must be activated
            IF i_flg_conflict_answer IS NULL
               OR i_flg_conflict_answer.count = 0
               OR i_flg_conflict_answer(i) = pk_alert_constant.g_yes
            THEN
                g_error := 'activates CPOE task draft: i_task_type=' || to_char(l_rec_task_type) || ', i_draft=' ||
                           l_draft(1) || ', i_episode=' || i_episode;
                pk_alertlog.log_debug(g_error, g_package_name);
            
                CASE
                -- monitorization
                    WHEN l_rec_task_type = g_task_type_monitorization THEN
                    
                        IF NOT pk_monitorization.activate_drafts(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_episode       => i_episode,
                                                                 i_draft         => l_draft,
                                                                 i_flg_commit    => pk_alert_constant.g_no,
                                                                 o_created_tasks => l_created_reqs,
                                                                 o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- positioning
                    WHEN l_rec_task_type = g_task_type_positioning THEN
                    
                        IF NOT pk_pbl_inp_positioning.activate_drafts(i_lang          => i_lang,
                                                                      i_prof          => i_prof,
                                                                      i_episode       => i_episode,
                                                                      i_draft         => l_draft,
                                                                      i_flg_commit    => pk_alert_constant.g_no,
                                                                      o_created_tasks => l_created_reqs,
                                                                      o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- hidric
                    WHEN l_rec_task_type = g_task_type_hidric_in_out
                         OR l_rec_task_type = g_task_type_hidric_out
                         OR l_rec_task_type = g_task_type_hidric_drain
                         OR l_rec_task_type = g_task_type_hidric_in
                         OR l_rec_task_type = g_task_type_hidric_out_all
                         OR l_rec_task_type = g_task_type_hidric_irrigations THEN
                    
                        IF NOT pk_inp_hidrics_pbl.activate_drafts(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_episode       => i_episode,
                                                                  i_draft         => l_draft,
                                                                  i_flg_commit    => pk_alert_constant.g_no,
                                                                  o_created_tasks => l_created_reqs,
                                                                  o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- diet
                    WHEN l_rec_task_type = g_task_type_diet_inst
                         OR l_rec_task_type = g_task_type_diet_spec
                         OR l_rec_task_type = g_task_type_diet_predefined THEN
                    
                        IF NOT pk_diet.activate_drafts(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_episode       => i_episode,
                                                       i_draft         => l_draft,
                                                       i_flg_commit    => pk_alert_constant.g_no,
                                                       o_created_tasks => l_created_reqs,
                                                       o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- procedure
                    WHEN l_rec_task_type = g_task_type_procedure THEN
                    
                        IF NOT pk_procedures_external_api_db.activate_drafts(i_lang          => i_lang,
                                                                             i_prof          => i_prof,
                                                                             i_episode       => i_episode,
                                                                             i_draft         => l_draft,
                                                                             i_flg_commit    => pk_alert_constant.g_no,
                                                                             i_id_cdr_call   => i_cdr_call,
                                                                             o_created_tasks => l_created_reqs,
                                                                             o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    WHEN l_rec_task_type = g_task_type_bp THEN
                    
                        IF NOT pk_bp_external_api_db.activate_drafts(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_episode       => i_episode,
                                                                     i_draft         => l_draft,
                                                                     i_flg_commit    => pk_alert_constant.g_no,
                                                                     i_id_cdr_call   => i_cdr_call,
                                                                     o_created_tasks => l_created_reqs,
                                                                     o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    WHEN l_rec_task_type = g_task_type_analysis THEN
                    
                        IF NOT pk_lab_tests_external_api_db.activate_drafts(i_lang          => i_lang,
                                                                            i_prof          => i_prof,
                                                                            i_episode       => i_episode,
                                                                            i_draft         => l_draft,
                                                                            i_flg_commit    => pk_alert_constant.g_no,
                                                                            i_id_cdr_call   => i_cdr_call,
                                                                            o_created_tasks => l_created_reqs,
                                                                            o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    WHEN l_rec_task_type = g_task_type_image_exam THEN
                    
                        IF NOT pk_exams_external_api_db.activate_drafts(i_lang          => i_lang,
                                                                        i_prof          => i_prof,
                                                                        i_episode       => i_episode,
                                                                        i_draft         => l_draft,
                                                                        i_flg_commit    => pk_alert_constant.g_no,
                                                                        i_id_cdr_call   => i_cdr_call,
                                                                        o_created_tasks => l_created_reqs,
                                                                        o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    WHEN l_rec_task_type = g_task_type_other_exam THEN
                    
                        IF NOT pk_exams_external_api_db.activate_drafts(i_lang          => i_lang,
                                                                        i_prof          => i_prof,
                                                                        i_episode       => i_episode,
                                                                        i_draft         => l_draft,
                                                                        i_flg_commit    => pk_alert_constant.g_no,
                                                                        i_id_cdr_call   => i_cdr_call,
                                                                        o_created_tasks => l_created_reqs,
                                                                        o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- nurse teaching
                    WHEN l_rec_task_type = g_task_type_nursing THEN
                    
                        IF NOT pk_patient_education_cpoe.activate_drafts(i_lang          => i_lang,
                                                                         i_prof          => i_prof,
                                                                         i_episode       => i_episode,
                                                                         i_draft         => l_draft,
                                                                         i_flg_commit    => pk_alert_constant.g_no,
                                                                         o_created_tasks => l_created_reqs,
                                                                         o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- medication
                    WHEN l_rec_task_type = g_task_type_medication THEN
                    
                        IF NOT pk_api_pfh_ordertools_in.activate_medication_drafts(i_lang          => i_lang,
                                                                                   i_prof          => i_prof,
                                                                                   i_episode       => i_episode,
                                                                                   i_draft_presc   => l_draft,
                                                                                   i_cdr_call      => i_cdr_call,
                                                                                   o_created_presc => l_created_reqs,
                                                                                   o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                -- communication order
                    WHEN l_rec_task_type IN (g_task_type_com_order, g_task_type_medical_orders) THEN
                    
                        IF NOT pk_comm_orders_cpoe.activate_drafts(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_episode       => i_episode,
                                                                   i_draft         => l_draft,
                                                                   i_flg_commit    => pk_alert_constant.g_no,
                                                                   o_created_tasks => l_created_reqs,
                                                                   o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    ELSE
                        NULL;
                END CASE;
            
                -- indicate the task request for the activated task
                IF l_created_reqs IS NOT NULL
                   AND l_created_reqs.count > 0
                THEN
                    o_new_task_request(l_count) := l_created_reqs(1);
                END IF;
            ELSE
                -- indicate that this draft wasn't activated
                o_new_task_request(l_count) := NULL;
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
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END activate_drafts;

    /********************************************************************************************
    * delete CPOE task drafts
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               array of task type IDs
    * @param       i_draft                   list of draft ids
    * @param       o_flg_conflict            array of action conflicts indicators (only used in some actions)
    * @param       o_msg_template            array of message/pop-up templates (only used in some actions)
    * @param       o_msg_title               array of message titles (only used in some actions)
    * @param       o_msg_body                array of message bodies (only used in some actions)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/24
    ********************************************************************************************/
    FUNCTION delete_draft
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN table_number,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_rec_task_type cpoe_task_type.id_task_type%TYPE;
        l_draft         table_number;
    
        l_flg_conflict VARCHAR2(1);
        l_msg_title    sys_message.desc_message%TYPE;
        l_msg_body     sys_message.desc_message%TYPE;
    
    BEGIN
        -- init output variables that will collect conflicts
        o_flg_conflict := table_varchar();
        o_msg_template := table_varchar();
        o_msg_title    := table_varchar();
        o_msg_body     := table_varchar();
    
        g_error := 'delete draft';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop to delete each CPOE task draft
        FOR i IN i_task_type.first .. i_task_type.last
        LOOP
        
            -- get task type
            l_rec_task_type := i_task_type(i);
        
            -- get draft
            l_draft := table_number(i_draft(i));
        
            g_error := 'delete CPOE task draft: i_task_type=' || to_char(l_rec_task_type) || ', i_draft=' || l_draft(1) ||
                       ', i_episode=' || i_episode;
            pk_alertlog.log_debug(g_error, g_package_name);
        
            CASE
            -- monitorization
                WHEN l_rec_task_type = g_task_type_monitorization THEN
                
                    IF NOT pk_monitorization.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- positioning
                WHEN l_rec_task_type = g_task_type_positioning THEN
                
                    IF NOT pk_pbl_inp_positioning.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- hidric
                WHEN l_rec_task_type = g_task_type_hidric_in_out
                     OR l_rec_task_type = g_task_type_hidric_out
                     OR l_rec_task_type = g_task_type_hidric_drain
                     OR l_rec_task_type = g_task_type_hidric_in
                     OR l_rec_task_type = g_task_type_hidric_out_all
                     OR l_rec_task_type = g_task_type_hidric_irrigations THEN
                
                    IF NOT pk_inp_hidrics_pbl.cancel_draft(i_lang,
                                                           i_prof,
                                                           i_episode,
                                                           l_draft,
                                                           l_flg_conflict,
                                                           l_msg_title,
                                                           l_msg_body,
                                                           o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    IF (l_flg_conflict = pk_alert_constant.get_yes)
                    THEN
                        o_msg_template.extend(1);
                        o_msg_template(o_msg_template.last) := pk_alert_constant.g_modal_win_warning_read;
                        o_flg_conflict.extend(1);
                        o_flg_conflict(o_flg_conflict.last) := l_flg_conflict;
                        o_msg_title.extend(1);
                        o_msg_title(o_msg_title.last) := l_msg_title;
                        o_msg_body.extend(1);
                        o_msg_body(o_msg_body.last) := l_msg_body;
                    
                    END IF;
                
            -- diet
                WHEN l_rec_task_type = g_task_type_diet_inst
                     OR l_rec_task_type = g_task_type_diet_spec
                     OR l_rec_task_type = g_task_type_diet_predefined THEN
                
                    IF NOT pk_diet.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- procedure
                WHEN l_rec_task_type = g_task_type_procedure THEN
                
                    IF NOT pk_procedures_external_api_db.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_image_exam THEN
                
                    IF NOT pk_exams_external_api_db.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_bp THEN
                
                    IF NOT pk_bp_external_api_db.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_other_exam THEN
                
                    IF NOT pk_exams_external_api_db.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                WHEN l_rec_task_type = g_task_type_analysis THEN
                
                    IF NOT pk_lab_tests_external_api_db.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- nurse teaching
                WHEN l_rec_task_type = g_task_type_nursing THEN
                
                    IF NOT pk_patient_education_cpoe.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- medication
                WHEN l_rec_task_type = g_task_type_medication THEN
                
                    IF NOT pk_api_pfh_ordertools_in.delete_medication_task(i_lang     => i_lang,
                                                                           i_prof     => i_prof,
                                                                           i_id_presc => l_draft,
                                                                           o_error    => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
            -- communication order
                WHEN l_rec_task_type IN (g_task_type_com_order, g_task_type_medical_orders) THEN
                
                    IF NOT pk_comm_orders_cpoe.cancel_draft(i_lang, i_prof, i_episode, l_draft, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                ELSE
                    NULL;
            END CASE;
        
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
                                              'DELETE_DRAFT',
                                              o_error);
            RETURN FALSE;
    END delete_draft;

    /********************************************************************************************
    * copy a list of cpoe tasks to draft (internal function)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               task type id
    * @param       i_id_request              task request id
    * @param       o_new_task_request        new generated request id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 07-Sep-2010
    ********************************************************************************************/

    /********************************************************************************************
    * copy a list of cpoe tasks to draft in an autonomous transaction
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               task type id
    * @param       i_id_request              task requisition id
    * @param       o_new_task_request        array with the new generated requisition IDs
    *
    * @author                                Carlos Loureiro
    * @since                                 07-Sep-2010
    ********************************************************************************************/

    /********************************************************************************************
    * Copy a list of CPOE tasks to draft
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               array of task type IDs
    * @param       i_id_request              array of task requisition IDs
    * @param       i_auto_trans              autonomous transaction flag
    * @param       o_new_task_request        array with the new generated requisition IDs
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @value       i_auto_trans              {*} 'Y' to be used by an autonomous transaction
    *                                        {*} 'N' to be used by an user action
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/

    /********************************************************************************************
    * delete all draft tasks
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 06-Sep-2010
    ********************************************************************************************/
    FUNCTION delete_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'cancelling all drafts for episode ' || i_episode;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- delete all positioning draft tasks
        IF NOT pk_pbl_inp_positioning.cancel_all_drafts(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode,
                                                        o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_pbl_inp_positioning.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all hidrics draft tasks
        IF NOT pk_inp_hidrics_pbl.cancel_all_drafts(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_episode => i_episode,
                                                    o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_inp_hidrics_pbl.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all monitorization draft tasks
        IF NOT pk_monitorization.cancel_all_drafts(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_episode => i_episode,
                                                   o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_monitorization.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all diet draft tasks    
        IF NOT pk_diet.cancel_all_drafts(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, o_error => o_error)
        THEN
            g_error := 'error found while calling pk_diet.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all procedure draft tasks
        IF NOT pk_procedures_external_api_db.cancel_all_drafts(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_episode => i_episode,
                                                               o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_procedures_external_api_db.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        IF NOT pk_lab_tests_external_api_db.cancel_all_drafts(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode,
                                                              o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_lab_tests_external_api_db.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        IF NOT pk_exams_external_api_db.cancel_all_drafts(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_exams_external_api_db.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all nurse teaching draft tasks
        IF NOT pk_patient_education_cpoe.cancel_all_drafts(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_episode => i_episode,
                                                           o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_patient_education_cpoe.cancel_all_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all medication draft tasks
        IF NOT pk_api_pfh_ordertools_in.delete_medication_drafts(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => table_number(i_episode),
                                                                 o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_api_pfh_ordertools_in.delete_medication_drafts function';
            RAISE l_exception;
        END IF;
    
        -- delete all communication order draft tasks
        IF NOT pk_comm_orders_cpoe.cancel_all_drafts(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_episode => i_episode,
                                                     o_error   => o_error)
        THEN
            g_error := 'error found while calling pk_comm_orders_cpoe.cancel_all_drafts function';
            RAISE l_exception;
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
                                              'DELETE_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END delete_all_drafts;

    /********************************************************************************************
    * delete all draft tasks (with autonomous transaction)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 06-Sep-2010
    ********************************************************************************************/
    PROCEDURE delete_all_drafts_auto_trans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) IS
        l_error t_error_out;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        g_error := 'cancelling all drafts with autonomous transaction for episode ' || i_episode;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- delete all positioning draft tasks
        IF NOT pk_pbl_inp_positioning.cancel_all_drafts(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode,
                                                        o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_pbl_inp_positioning.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all hidrics draft tasks
        IF NOT pk_inp_hidrics_pbl.cancel_all_drafts(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_episode => i_episode,
                                                    o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_inp_hidrics_pbl.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all monitorization draft tasks
        IF NOT pk_monitorization.cancel_all_drafts(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_episode => i_episode,
                                                   o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_monitorization.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all diet draft tasks
        IF NOT pk_diet.cancel_all_drafts(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, o_error => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_diet.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all procedure draft tasks
        IF NOT pk_procedures_external_api_db.cancel_all_drafts(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_episode => i_episode,
                                                               o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_procedures_external_api_db.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all nurse teaching draft tasks
        IF NOT pk_patient_education_cpoe.cancel_all_drafts(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_episode => i_episode,
                                                           o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_patient_education_cpoe.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all medication draft tasks
        IF NOT pk_api_pfh_ordertools_in.delete_medication_drafts(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => table_number(i_episode),
                                                                 o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_api_pfh_ordertools_in.delete_medication_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        IF NOT pk_lab_tests_external_api_db.cancel_all_drafts(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode,
                                                              o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_lab_tests_external_api_db.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        IF NOT pk_exams_external_api_db.cancel_all_drafts(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_exams_external_api_db.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
        -- delete all communication order draft tasks
        IF NOT pk_comm_orders_cpoe.cancel_all_drafts(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_episode => i_episode,
                                                     o_error   => l_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_comm_orders_cpoe.cancel_all_drafts function',
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DRAFTS_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
        ELSE
            COMMIT;
        END IF;
    
    END delete_all_drafts_auto_trans;

    /********************************************************************************************
    * perform a task action 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_action                  action id
    * @param       i_task_type               array of cpoe task type IDs
    * @param       i_task_request            array of task requisition IDs
    * @param       o_new_task_request        array with the new generated requisition IDs (only used in some actions)
    * @param       o_flg_show                Y- should be shown an error popup. N-otherwise
    * @param       o_msg_title               Title to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_msg                     Message to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_flg_validated           flag that indicates if user needs to validate the 
    *                                        resume action
    * @param       o_error                   error message
    *
    * @value       o_flg_validated           {*} 'Y' validated! no user inputs are needed
    *                                        {*} 'N' not validated! user needs to validare this action
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21   
    ********************************************************************************************/
    FUNCTION set_task_action
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_action           IN action.id_action%TYPE,
        i_task_type        IN table_number,
        i_task_request     IN table_number,
        o_new_task_request OUT table_number,
        o_flg_show         OUT VARCHAR2,
        o_msg_template     OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_body         OUT VARCHAR2,
        o_flg_validated    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_rec_task_type    cpoe_task_type.id_task_type%TYPE;
        l_rec_task_request cpoe_process_task.id_task_request%TYPE;
    BEGIN
    
        g_error := 'verify how many tasks were selected';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get task type
        l_rec_task_type := i_task_type(1);
    
        -- get task request
        l_rec_task_request := i_task_request(1);
    
        g_error := 'set task action (id_action = ' || i_action || ') for i_task_type=' || to_char(l_rec_task_type) ||
                   ', i_task_request.count=' || i_task_request.count || ', i_episode=' || i_episode;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE
        -- monitorization
            WHEN l_rec_task_type = g_task_type_monitorization THEN
                NULL;
            
        -- positioning
            WHEN l_rec_task_type = g_task_type_positioning THEN
                NULL;
            
        -- hidric
            WHEN l_rec_task_type = g_task_type_hidric_in_out
                 OR l_rec_task_type = g_task_type_hidric_out
                 OR l_rec_task_type = g_task_type_hidric_drain
                 OR l_rec_task_type = g_task_type_hidric_in
                 OR l_rec_task_type = g_task_type_hidric_out_all
                 OR l_rec_task_type = g_task_type_hidric_irrigations THEN
            
                IF NOT pk_inp_hidrics_pbl.set_action(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_action       => i_action,
                                                     i_task_request => l_rec_task_request,
                                                     o_flg_show     => o_flg_show,
                                                     o_msg_title    => o_msg_title,
                                                     o_msg          => o_msg_body,
                                                     o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF (o_flg_show = pk_alert_constant.get_yes)
                THEN
                    o_msg_template := pk_alert_constant.g_modal_win_warning_read;
                END IF;
            
        -- diet
            WHEN l_rec_task_type = g_task_type_diet_inst
                 OR l_rec_task_type = g_task_type_diet_spec
                 OR l_rec_task_type = g_task_type_diet_predefined THEN
            
                NULL;
            
        -- procedure
            WHEN l_rec_task_type = g_task_type_procedure THEN
            
                NULL;
            WHEN l_rec_task_type = g_task_type_bp THEN
                NULL;
            
            WHEN l_rec_task_type = g_task_type_analysis THEN
            
                NULL;
            
            WHEN l_rec_task_type = g_task_type_image_exam THEN
            
                NULL;
            
            WHEN l_rec_task_type = g_task_type_other_exam THEN
            
                NULL;
            
        -- nurse teaching
            WHEN l_rec_task_type = g_task_type_nursing THEN
            
                NULL;
            
        -- medication
            WHEN l_rec_task_type = g_task_type_medication THEN
            
                CASE
                -- resume action (may not need user interaction)
                    WHEN i_action = g_cpoe_task_med_resume_action THEN
                        IF NOT pk_api_pfh_ordertools_in.resume_medication(i_lang          => i_lang,
                                                                          i_prof          => i_prof,
                                                                          i_presc         => l_rec_task_request,
                                                                          o_flg_validated => o_flg_validated,
                                                                          o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    ELSE
                        NULL;
                END CASE;
            
        -- communication order
            WHEN l_rec_task_type IN (g_task_type_com_order, g_task_type_medical_orders) THEN
            
                IF NOT pk_comm_orders_cpoe.set_action(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_episode      => i_episode,
                                                      i_action       => i_action,
                                                      i_task_request => i_task_request,
                                                      o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSE
                NULL;
            
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
                                              'SET_TASK_ACTION',
                                              o_error);
            RETURN FALSE;
    END set_task_action;

    FUNCTION get_timestamp_day_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    BEGIN
        RETURN pk_date_utils.get_string_tstz(i_lang,
                                             i_prof,
                                             to_char(pk_date_utils.get_timestamp_insttimezone(i_lang,
                                                                                              i_prof.institution,
                                                                                              i_timestamp),
                                                     'YYYYMMDD') || '000000',
                                             NULL);
    END get_timestamp_day_tstz;

    PROCEDURE copy_to_draft_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN cpoe_process_task.id_task_type%TYPE,
        i_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_dt_draft_start   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_draft_end     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_via_job      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_new_task_request OUT cpoe_process_task.id_task_request%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.copy_to_draft_internal called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode ||
                                  chr(10) || 'i_task_type=' || i_task_type || chr(10) || 'i_task_request=' ||
                                  i_task_request || chr(10) || 'i_dt_draft_start=' || i_dt_draft_start || chr(10) ||
                                  'i_dt_draft_end=' || i_dt_draft_end,
                                  g_package_name);
        END IF;
    
        -- switch between supported task types
        CASE
        -- monitorization
            WHEN i_task_type = g_task_type_monitorization THEN
                IF NOT pk_monitorization.copy_to_draft(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_episode              => i_episode,
                                                       i_task_request         => i_task_request,
                                                       i_task_start_timestamp => i_dt_draft_start,
                                                       i_task_end_timestamp   => i_dt_draft_end,
                                                       o_draft                => o_new_task_request,
                                                       o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type = g_task_type_nursing THEN
                IF NOT pk_patient_education_cpoe.copy_to_draft(i_lang                 => i_lang,
                                                               i_prof                 => i_prof,
                                                               i_episode              => i_episode,
                                                               i_task_request         => i_task_request,
                                                               i_task_start_timestamp => i_dt_draft_start,
                                                               i_task_end_timestamp   => i_dt_draft_end,
                                                               o_draft                => o_new_task_request,
                                                               o_error                => o_error)
                THEN
                    g_error := g_error || ' error found while calling pk_patient_education_cpoe.copy_to_draft function';
                    RAISE l_exception;
                END IF;
            
        -- medication: local drug
            WHEN i_task_type = g_task_type_medication THEN
            
                IF NOT pk_api_pfh_ordertools_in.copy_medication_to_draft(i_lang                 => i_lang,
                                                                         i_prof                 => i_prof,
                                                                         i_id_episode           => i_episode,
                                                                         i_id_presc             => i_task_request,
                                                                         i_task_start_timestamp => i_dt_draft_start,
                                                                         i_task_end_timestamp   => i_dt_draft_end,
                                                                         i_flg_via_job          => i_flg_via_job,
                                                                         o_id_presc             => o_new_task_request,
                                                                         o_error                => o_error)
                THEN
                    g_error := g_error ||
                               ' error found while calling pk_api_pfh_ordertools_in.copy_medication_to_draft function';
                    RAISE l_exception;
                END IF;
            
        -- positioning
            WHEN i_task_type = g_task_type_positioning THEN
                IF NOT pk_pbl_inp_positioning.copy_to_draft(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_episode              => i_episode,
                                                            i_task_request         => i_task_request,
                                                            i_task_start_timestamp => i_dt_draft_start,
                                                            i_task_end_timestamp   => i_dt_draft_end,
                                                            o_draft                => o_new_task_request,
                                                            o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- hidric
            WHEN i_task_type = g_task_type_hidric_in_out
                 OR i_task_type = g_task_type_hidric_out
                 OR i_task_type = g_task_type_hidric_drain
                 OR i_task_type = g_task_type_hidric_in
                 OR i_task_type = g_task_type_hidric_out_all
                 OR i_task_type = g_task_type_hidric_irrigations THEN
                IF NOT pk_inp_hidrics_pbl.copy_to_draft(i_lang                 => i_lang,
                                                        i_prof                 => i_prof,
                                                        i_episode              => i_episode,
                                                        i_task_request         => i_task_request,
                                                        i_task_start_timestamp => i_dt_draft_start,
                                                        i_task_end_timestamp   => i_dt_draft_end,
                                                        o_draft                => o_new_task_request,
                                                        o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- diet
            WHEN i_task_type = g_task_type_diet_inst
                 OR i_task_type = g_task_type_diet_spec
                 OR i_task_type = g_task_type_diet_predefined THEN
                IF NOT pk_diet.copy_to_draft(i_lang                 => i_lang,
                                             i_prof                 => i_prof,
                                             i_episode              => i_episode,
                                             i_task_request         => i_task_request,
                                             i_task_start_timestamp => i_dt_draft_start,
                                             i_task_end_timestamp   => i_dt_draft_end,
                                             o_draft                => o_new_task_request,
                                             o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- procedure
            WHEN i_task_type = g_task_type_procedure THEN
                IF NOT pk_procedures_external_api_db.copy_to_draft(i_lang                 => i_lang,
                                                                   i_prof                 => i_prof,
                                                                   i_episode              => i_episode,
                                                                   i_task_request         => i_task_request,
                                                                   i_task_start_timestamp => i_dt_draft_start,
                                                                   i_task_end_timestamp   => i_dt_draft_end,
                                                                   o_draft                => o_new_task_request,
                                                                   o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type = g_task_type_bp THEN
            
                IF NOT pk_bp_external_api_db.copy_to_draft(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_episode              => i_episode,
                                                           i_task_request         => i_task_request,
                                                           i_task_start_timestamp => i_dt_draft_start,
                                                           i_task_end_timestamp   => i_dt_draft_end,
                                                           o_draft                => o_new_task_request,
                                                           o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type = g_task_type_analysis THEN
                IF NOT pk_lab_tests_external_api_db.copy_to_draft(i_lang                 => i_lang,
                                                                  i_prof                 => i_prof,
                                                                  i_episode              => i_episode,
                                                                  i_task_request         => i_task_request,
                                                                  i_task_start_timestamp => i_dt_draft_start,
                                                                  i_task_end_timestamp   => i_dt_draft_end,
                                                                  o_draft                => o_new_task_request,
                                                                  o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type IN (g_task_type_image_exam, g_task_type_other_exam) THEN
            
                IF NOT pk_exams_external_api_db.copy_to_draft(i_lang                 => i_lang,
                                                              i_prof                 => i_prof,
                                                              i_episode              => i_episode,
                                                              i_task_request         => i_task_request,
                                                              i_task_start_timestamp => i_dt_draft_start,
                                                              i_task_end_timestamp   => i_dt_draft_end,
                                                              o_draft                => o_new_task_request,
                                                              o_error                => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- nurse teaching
            WHEN i_task_type = g_task_type_nursing THEN
                IF NOT pk_patient_education_cpoe.copy_to_draft(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_episode      => i_episode,
                                                               i_task_request => i_task_request,
                                                               o_draft        => o_new_task_request,
                                                               o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type = g_task_type_com_order
                 OR i_task_type = g_task_type_medical_orders THEN
                IF NOT pk_comm_orders_cpoe.copy_to_draft(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_episode              => i_episode,
                                                         i_task_request         => i_task_request,
                                                         i_task_start_timestamp => i_dt_draft_start,
                                                         i_task_end_timestamp   => i_dt_draft_end,
                                                         i_task_type            => i_task_type,
                                                         o_draft                => o_new_task_request,
                                                         o_error                => o_error)
                THEN
                    g_error := g_error || ' error found while calling pk_comm_orders_cpoe.copy_to_draft function';
                    RAISE l_exception;
                END IF;
            
            ELSE
                NULL;
            
        END CASE;
    
    END copy_to_draft_internal;

    PROCEDURE copy_to_draft_auto_trans
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN cpoe_process_task.id_task_type%TYPE,
        i_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_dt_draft_start   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_draft_end     IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_new_task_request OUT cpoe_process_task.id_task_request%TYPE
    ) IS
        l_error t_error_out;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- copy to draft with autonomous transaction (for draft prescription refresh action or job)
        copy_to_draft_internal(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_episode          => i_episode,
                               i_task_type        => i_task_type,
                               i_task_request     => i_task_request,
                               i_dt_draft_start   => i_dt_draft_start,
                               i_dt_draft_end     => i_dt_draft_end,
                               i_flg_via_job      => pk_alert_constant.g_yes,
                               o_new_task_request => o_new_task_request,
                               o_error            => l_error);
        -- commit changes with an autonomous transaction
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'error found while calling pk_cpoe.copy_to_draft_internal procedure',
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_TO_DRAFT_AUTO_TRANS',
                                              l_error);
            pk_utils.undo_changes;
    END copy_to_draft_auto_trans;

    PROCEDURE copy_to_draft
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN table_number,
        i_task_request     IN table_number,
        i_auto_trans       IN VARCHAR2 DEFAULT 'N',
        i_dt_draft_start   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_draft_end     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_new_task_request OUT table_number
    ) IS
        l_draft cpoe_process_task.id_task_request%TYPE;
    
        l_rec_task_type    cpoe_task_type.id_task_type%TYPE;
        l_rec_task_request cpoe_process_task.id_task_request%TYPE;
    
        l_new_tsk_req_index PLS_INTEGER := 0;
    
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        l_exception EXCEPTION;
    
        l_error t_error_out;
    
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.copy_to_draft called with:' || chr(10) || 'i_lang=' || i_lang || chr(10) ||
                                  'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode || chr(10) ||
                                  'i_task_type=' || get_tabnum_str(i_task_type) || chr(10) || 'i_task_request=' ||
                                  get_tabnum_str(i_task_request) || chr(10) || 'i_auto_trans=' || i_auto_trans ||
                                  chr(10) || 'i_dt_draft_start=' || i_dt_draft_start || chr(10) || 'i_dt_draft_end=' ||
                                  i_dt_draft_end,
                                  g_package_name);
        END IF;
    
        -- init variable that will collect generated draft ids
        o_new_task_request := table_number();
    
        g_error := 'copy to draft';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop to copy each CPOE task
        FOR i IN i_task_type.first .. i_task_type.last
        LOOP
            -- get task type
            l_rec_task_type := i_task_type(i);
        
            -- get task request
            l_rec_task_request := i_task_request(i);
        
            IF i_auto_trans = pk_alert_constant.g_yes
            THEN
                copy_to_draft_auto_trans(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_episode          => i_episode,
                                         i_task_type        => l_rec_task_type,
                                         i_task_request     => l_rec_task_request,
                                         i_dt_draft_start   => i_dt_draft_start,
                                         i_dt_draft_end     => i_dt_draft_end,
                                         o_new_task_request => l_draft);
            ELSE
                copy_to_draft_internal(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_episode          => i_episode,
                                       i_task_type        => l_rec_task_type,
                                       i_task_request     => l_rec_task_request,
                                       i_dt_draft_start   => i_dt_draft_start,
                                       i_dt_draft_end     => i_dt_draft_end,
                                       i_flg_via_job      => pk_alert_constant.g_no,
                                       o_new_task_request => l_draft,
                                       o_error            => l_error);
            
            END IF;
        
            -- collect generated draft id
            o_new_task_request.extend;
            l_new_tsk_req_index := l_new_tsk_req_index + 1;
            o_new_task_request(l_new_tsk_req_index) := l_draft;
        
        END LOOP;
    
    END copy_to_draft;

    /********************************************************************************************
    * perform a CPOE action 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_action                  action id
    * @param       i_task_type               array of cpoe task type IDs
    * @param       i_task_request            array of task requisition IDs (also used for drafts)
    * @param       i_flg_conflict_answer     array with the answers of the conflicts pop-ups (only used in some actions)
    * @param       i_cdr_call                clinical decision rules call id
    * @param       o_action                  action id (required by the flash layer)
    * @param       o_task_type               array of cpoe task type IDs (required by the flash layer)
    * @param       o_task_request            array of task requisition IDs (also used for drafts) (required by the flash layer)
    * @param       o_new_task_request        array with the new generated requisition IDs (only used in some actions)
    * @param       o_flg_conflict            array of action conflicts indicators (only used in some actions)
    * @param       o_msg_template            array of message/pop-up templates (only used in some actions)
    * @param       o_msg_title               array of message titles (only used in some actions)
    * @param       o_msg_body                array of message bodies (only used in some actions)
    * @param       o_flg_validated           array of validated flags (which indicates if an auxiliary  screen should be loaded or not)
    * @param       o_error                   error message
    *
    * @value       i_flg_conflict_answer     {*} 'Y'  draft must be activated even if it has conflicts
    *                                        {*} 'N'  draft shouldn't be activated
    *                                        {*} NULL there are no conflicts
    *
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts
    *                                        {*} 'N' no conflicts found
    *
    * @value       o_msg_template            {*} 'WARNING_READ' Warning Read
    *                                        {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                                        {*} 'WARNING_CANCEL' Warning Cancel
    *                                        {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                                        {*} 'WARNING_SECURITY' Warning Security
    *                                        {*} 'CONFIRMATION' Confirmation
    *                                        {*} 'DETAIL' Detail
    *                                        {*} 'HELP' Help
    *                                        {*} 'WIZARD' Wizard
                *                                        {*} 'ADVANCED_INPUT' Advanced Input
    *
    * @value       o_flg_validated           {*} 'Y' validated! no user inputs are needed
    *                                        {*} 'N' not validated! user needs to validare this action
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION set_action
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_action              IN action.id_action%TYPE,
        i_task_type           IN table_number,
        i_task_request        IN table_number,
        i_flg_conflict_answer IN table_varchar,
        i_cdr_call            IN cdr_call.id_cdr_call%TYPE,
        i_flg_task_to_copy    IN table_varchar,
        o_action              OUT action.id_action%TYPE,
        o_task_type           OUT table_number,
        o_task_request        OUT table_number,
        o_new_task_request    OUT table_number,
        o_flg_conflict        OUT table_varchar,
        o_msg_template        OUT table_varchar,
        o_msg_title           OUT table_varchar,
        o_msg_body            OUT table_varchar,
        o_flg_validated       OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_del_draft sys_config.value%TYPE;
        l_exception EXCEPTION;
        l_flg_show     sys_message.desc_message%TYPE;
        l_msg_title    sys_message.desc_message%TYPE;
        l_msg_body     sys_message.desc_message%TYPE;
        l_msg_template sys_message.desc_message%TYPE;
    
        -- always assume that action doesn't need user interaction
        l_flg_validated VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        l_ts_task_start TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_task_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        l_draft_tasks table_number;
    
        l_flg_profile   profile_template.flg_profile%TYPE;
        l_id_patient    patient.id_patient%TYPE;
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_tasks         t_tbl_cpoe_task_list;
        l_task_types    table_number;
        l_cnt_all       NUMBER;
        l_cnt_current   NUMBER;
        l_cnt_next      NUMBER;
        l_cnt_active    NUMBER;
        l_cnt_draft     NUMBER;
        l_cnt_to_ack    NUMBER;
    
        l_med_admin pk_types.cursor_type;
        l_proc_plan pk_types.cursor_type;
        l_execution t_tbl_cpoe_execution;
        l_flg_cpoe  VARCHAR2(1 CHAR);
        l_status    table_varchar;
        l_rep       NUMBER;
    
        PROCEDURE calc_dates_for_draft_tasks
        (
            o_ts_task_start OUT TIMESTAMP WITH LOCAL TIME ZONE,
            o_ts_task_end   OUT TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            l_flg_cpoe_mode        VARCHAR2(1 CHAR);
            l_flg_cpoe_status      VARCHAR2(1 CHAR);
            l_id_cpoe_process      cpoe_process.id_cpoe_process%TYPE;
            l_ts_cpoe_start        cpoe_process.dt_cpoe_proc_start%TYPE;
            l_ts_cpoe_end          cpoe_process.dt_cpoe_proc_end%TYPE;
            l_ts_cpoe_refresh      cpoe_process.dt_cpoe_refreshed%TYPE;
            l_ts_cpoe_next_start   cpoe_process.dt_cpoe_proc_start%TYPE;
            l_ts_cpoe_next_end     cpoe_process.dt_cpoe_proc_end%TYPE;
            l_id_professional      professional.id_professional%TYPE;
            l_ts_cpoe_next_refresh cpoe_process.dt_cpoe_refreshed%TYPE;
            l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_start%TYPE;
        BEGIN
        
            -- get cpoe mode to evaluate if the task should be copied with dates or not or not
            IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- only sync tasks with cpoe process when working in advanced mode
            IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
            THEN
            
                -- get last cpoe information to check if an active prescription exists
                IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_episode         => i_episode,
                                          o_cpoe_process    => l_id_cpoe_process,
                                          o_dt_start        => l_ts_cpoe_start,
                                          o_dt_end          => l_ts_cpoe_end,
                                          o_flg_status      => l_flg_cpoe_status,
                                          o_id_professional => l_id_professional,
                                          o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- if last cpoe is not active
                IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    -- no cpoe process created so far. system will check if all tasks have the proper start timestamps 
                    -- by checking the cpoe automatic creation periods
                    IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_dt_start      => NULL,
                                              o_dt_start      => l_ts_cpoe_start,
                                              o_dt_end        => l_ts_cpoe_end,
                                              o_dt_refresh    => l_ts_cpoe_refresh,
                                              o_dt_next_presc => l_ts_cpoe_next_presc,
                                              o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                -- get next prescription process
                get_next_presc_process(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => i_episode,
                                       o_cpoe_process => l_id_cpoe_process,
                                       o_dt_start     => l_ts_cpoe_next_start,
                                       o_dt_end       => l_ts_cpoe_next_end);
            
                -- if next prescription process doesn't exist, then calculate start/end timestamps, 
                -- starting from previous current active prescription
                IF l_id_cpoe_process IS NULL
                   AND check_next_presc_availability(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode) =
                   pk_alert_constant.g_yes
                THEN
                    -- get next cpoe period, after the active current cpoe
                    -- the start timestamp of next cpoe is the end timestamp of current active prescription process
                    IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_dt_start      => l_ts_cpoe_end,
                                              o_dt_start      => l_ts_cpoe_next_start, -- is equal to l_ts_cpoe_end
                                              o_dt_end        => l_ts_cpoe_next_end, -- calculated value
                                              o_dt_refresh    => l_ts_cpoe_next_refresh,
                                              o_dt_next_presc => l_ts_cpoe_next_presc,
                                              o_error         => o_error) -- calculated value
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                o_ts_task_start := l_ts_cpoe_next_start;
                o_ts_task_end   := l_ts_cpoe_next_end - g_tstz_presc_limit_threshold;
            
            END IF;
        
        END calc_dates_for_draft_tasks;
    
    BEGIN
        -- required by the flash layer
        o_action       := i_action;
        o_task_type    := i_task_type;
        o_task_request := i_task_request;
    
        g_error := 'set action';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE
        -- cpoe action: copy to draft
            WHEN i_action = g_cpoe_task_copy2draft_action THEN
            
                calc_dates_for_draft_tasks(l_ts_task_start, l_ts_task_end);
            
                -- copy tasks to draft
                copy_to_draft(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_episode          => i_episode,
                              i_task_type        => i_task_type,
                              i_task_request     => i_task_request,
                              i_auto_trans       => 'N',
                              i_dt_draft_start   => l_ts_task_start,
                              i_dt_draft_end     => l_ts_task_end,
                              o_new_task_request => o_new_task_request);
            
                IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_episode         => i_episode,
                                          o_cpoe_process    => l_cpoe_process,
                                          o_dt_start        => l_ts_cpoe_start,
                                          o_dt_end          => l_ts_cpoe_end,
                                          o_flg_status      => l_flg_cpoe_status,
                                          o_id_professional => l_id_professional,
                                          o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_cpoe_process => l_cpoe_process,
                                             i_tasks_orig   => i_task_request,
                                             i_tasks_dest   => o_new_task_request,
                                             i_tasks_type   => i_task_type,
                                             i_flg_type     => 'AD',
                                             o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- cpoe action: activate draft
            WHEN i_action IN (g_cpoe_task_activ_draft_action,
                              g_cpoe_task_a_draft_cur_action,
                              g_cpoe_task_a_draft_new_action,
                              g_cpoe_task_a_draft_newpresc) THEN
            
                -- check if there are conflicts to drafts activation (first call of this function)
                IF i_flg_conflict_answer IS NULL
                   OR i_flg_conflict_answer.count = 0
                THEN
                    IF NOT check_drafts_conflicts(i_lang,
                                                  i_prof,
                                                  i_episode,
                                                  i_task_type,
                                                  i_task_request,
                                                  o_flg_conflict,
                                                  o_msg_template,
                                                  o_msg_title,
                                                  o_msg_body,
                                                  o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                ELSE
                    o_flg_conflict := NULL;
                END IF;
            
                -- if there are no conflicts or already exist answers to them 
                -- (first or second call of this function, respectively), then activate drafts 
                IF o_flg_conflict IS NULL
                THEN
                    -- activate draft tasks
                    IF NOT activate_drafts(i_lang,
                                           i_prof,
                                           i_episode,
                                           i_task_type,
                                           i_task_request,
                                           i_flg_conflict_answer,
                                           i_cdr_call,
                                           o_new_task_request,
                                           o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    -- clear remain draft tasks (the ones not selected in "create presc with selected" action)
                    IF i_action = g_cpoe_task_a_draft_new_action
                    THEN
                        -- check if drafts that weren't used should be removed
                        IF NOT get_delete_on_activate(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      o_flg_del => l_flg_del_draft,
                                                      o_error   => o_error)
                        THEN
                            g_error := 'error found while calling pk_cpoe.get_delete_on_activate function';
                            RAISE l_exception;
                        END IF;
                    
                        -- draft tasks removal before prescription refresh (only if configuration allows it)
                        IF l_flg_del_draft = pk_alert_constant.g_yes
                        THEN
                            IF NOT delete_all_drafts(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_episode => i_episode,
                                                     o_error   => o_error)
                            THEN
                                g_error := 'error found while calling pk_cpoe.delete_all_drafts function';
                                RAISE l_exception;
                            END IF;
                        END IF;
                    END IF;
                
                    -- get dates interval for draft tasks
                    calc_dates_for_draft_tasks(l_ts_task_start, l_ts_task_end);
                
                    -- create new drafts for tasks that were activated
                    FOR i IN 1 .. i_flg_task_to_copy.count
                    LOOP
                        IF i_flg_task_to_copy(i) = pk_alert_constant.g_yes
                        THEN
                        
                            -- copy task to draft
                            copy_to_draft(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_episode          => i_episode,
                                          i_task_type        => table_number(i_task_type(i)),
                                          i_task_request     => table_number(o_new_task_request(i)),
                                          i_dt_draft_start   => l_ts_task_start,
                                          i_dt_draft_end     => l_ts_task_end,
                                          o_new_task_request => l_draft_tasks);
                        
                            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_episode         => i_episode,
                                                      o_cpoe_process    => l_cpoe_process,
                                                      o_dt_start        => l_ts_cpoe_start,
                                                      o_dt_end          => l_ts_cpoe_end,
                                                      o_flg_status      => l_flg_cpoe_status,
                                                      o_id_professional => l_id_professional,
                                                      o_error           => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            UPDATE cpoe_tasks_relation b
                               SET flg_type = 'AN'
                             WHERE b.id_task_dest = i_task_request(i)
                               AND b.id_task_type = i_task_type(i)
                               AND NOT EXISTS (SELECT 1
                                      FROM cpoe_tasks_relation c
                                     WHERE c.id_task_type = i_task_type(i)
                                       AND c.flg_type = 'REP'
                                       AND c.id_task_orig = o_new_task_request(i));
                        
                            IF l_draft_tasks(1) IS NOT NULL
                            THEN
                                UPDATE cpoe_tasks_relation ctr
                                   SET ctr.id_task_dest = l_draft_tasks(1)
                                 WHERE ctr.id_task_orig = o_new_task_request(i)
                                   AND ctr.id_task_type = i_task_type(i)
                                   AND EXISTS (SELECT 1
                                          FROM cpoe_tasks_relation c
                                         WHERE c.id_task_type = i_task_type(i)
                                           AND c.flg_type = 'REP'
                                           AND c.id_task_orig = o_new_task_request(i));
                            END IF;
                            /*SELECT cp.flg_status
                              INTO l_flg_cpoe
                              FROM cpoe_process_task cpt
                             INNER JOIN cpoe_process cp
                                ON cpt.id_cpoe_process = cp.id_cpoe_process
                             WHERE cpt.id_task_type = i_task_type(i)
                               AND cpt.id_task_request = o_new_task_request(i);
                            */
                        
                            SELECT COUNT(*)
                              INTO l_rep
                              FROM cpoe_tasks_relation c
                             WHERE c.id_task_type = i_task_type(i)
                               AND c.flg_type = 'REP'
                               AND c.id_task_orig = o_new_task_request(i);
                        
                            SELECT b.flg_status
                              BULK COLLECT
                              INTO l_status
                              FROM cpoe_process_task a
                             INNER JOIN cpoe_process b
                                ON a.id_cpoe_process = b.id_cpoe_process
                             WHERE a.id_task_request = o_new_task_request(i)
                               AND a.id_task_type = i_task_type(i);
                            BEGIN
                                IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_cpoe_process => l_cpoe_process,
                                                        i_tasks_orig   => table_number(l_draft_tasks(1)),
                                                        i_tasks_dest   => table_number(o_new_task_request(i)),
                                                        i_tasks_type   => table_number(i_task_type(i)),
                                                        i_flg_type     => CASE
                                                                              WHEN l_status(1) = 'N'
                                                                                   OR l_rep > 0 THEN
                                                                               'DN'
                                                                              ELSE
                                                                               'DA'
                                                                          END,
                                                        o_error        => o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    NULL;
                            END;
                        
                        ELSE
                        
                            UPDATE cpoe_tasks_relation b
                               SET flg_type = 'AN'
                             WHERE b.id_task_dest = i_task_request(i)
                               AND b.id_task_type = i_task_type(i)
                               AND NOT EXISTS (SELECT 1
                                      FROM cpoe_tasks_relation c
                                     WHERE c.id_task_type = i_task_type(i)
                                       AND c.flg_type = 'REP'
                                       AND c.id_task_orig = o_new_task_request(i));
                        
                            /*IF NOT delete_from_rel_tasks(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_tasks      => table_number(o_new_task_request(i)),
                                                         i_tasks_type => table_number(i_task_type(i)),
                                                         i_flg_draft  => pk_alert_constant.g_yes,
                                                         o_error      => o_error)
                            
                            THEN
                                RAISE l_exception;
                            END IF;*/
                        
                        END IF;
                    END LOOP;
                
                END IF;
            
        -- cpoe action: delete draft
            WHEN i_action = g_cpoe_task_del_draft_action THEN
            
                IF NOT delete_draft(i_lang,
                                    i_prof,
                                    i_episode,
                                    i_task_type,
                                    i_task_request,
                                    o_flg_conflict,
                                    o_msg_template,
                                    o_msg_title,
                                    o_msg_body,
                                    o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF NOT delete_from_rel_tasks(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_tasks      => i_task_request,
                                             i_tasks_type => i_task_type,
                                             i_flg_draft  => pk_alert_constant.g_yes,
                                             o_error      => o_error)
                
                THEN
                    RAISE l_exception;
                END IF;
            
                l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
            
                IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
                THEN
                
                    l_id_patient := pk_episode.get_epis_patient(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_episode => i_episode);
                
                    IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    IF NOT get_task_list_all(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_cpoe_mode       => l_flg_cpoe_mode,
                                             i_patient         => l_id_patient,
                                             i_episode         => i_episode,
                                             i_process_tasks   => NULL,
                                             i_cpoe_start_tstz => current_timestamp,
                                             i_flg_report      => pk_alert_constant.g_no,
                                             i_process         => NULL,
                                             i_tab_type        => pk_cpoe.g_filter_draft,
                                             i_cpoe_status     => l_flg_cpoe_status,
                                             o_tasks           => l_tasks,
                                             o_task_types      => l_task_types,
                                             o_cnt_all         => l_cnt_all,
                                             o_cnt_current     => l_cnt_current,
                                             o_cnt_next        => l_cnt_next,
                                             o_cnt_active      => l_cnt_active,
                                             o_cnt_draft       => l_cnt_draft,
                                             o_cnt_to_ack      => l_cnt_to_ack,
                                             o_execution       => l_execution,
                                             o_med_admin       => l_med_admin,
                                             o_proc_plan       => l_proc_plan,
                                             o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_cpoe.get_cpoe_grid function';
                        RAISE l_exception;
                    END IF;
                
                    IF l_cnt_draft = 0
                    THEN
                    
                        IF NOT pk_alerts.delete_sys_alert_event_episode(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_episode => i_episode,
                                                                        i_delete  => pk_alert_constant.g_yes,
                                                                        o_error   => o_error)
                        THEN
                        
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                
                END IF;
            
        -- cpoe action: edit draft
            WHEN i_action = g_cpoe_task_edit_draft_action THEN
            
                -- this action must be performed on the flash layer
                NULL;
            WHEN i_action = g_cpoe_task_copy_next_presc THEN
                FOR i IN 1 .. i_task_request.count
                LOOP
                
                    IF i_task_type(1) IN (g_task_type_hidric,
                                          g_task_type_hidric_in_out,
                                          g_task_type_hidric_out,
                                          g_task_type_hidric_drain,
                                          g_task_type_hidric_in,
                                          g_task_type_hidric_out_group,
                                          g_task_type_hidric_out_all,
                                          g_task_type_hidric_irrigations,
                                          pk_cpoe.g_task_type_diet,
                                          pk_cpoe.g_task_type_diet_inst,
                                          pk_cpoe.g_task_type_diet_spec,
                                          pk_cpoe.g_task_type_diet_predefined)
                    THEN
                    
                        IF NOT sync_active_to_next(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_episode       => i_episode,
                                                   i_task_type     => i_task_type(i),
                                                   i_request       => i_task_request(i),
                                                   i_flg_copy_next => pk_alert_constant.g_yes,
                                                   o_error         => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    ELSE
                    
                        IF NOT request_task_to_next_presc(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_episode          => i_episode,
                                                          i_task_type        => table_number(i_task_type(i)),
                                                          i_task_request     => table_number(i_task_request(i)),
                                                          o_new_task_request => o_new_task_request,
                                                          o_error            => o_error)
                        THEN
                        
                            RAISE l_exception;
                        END IF;
                    END IF;
                END LOOP;
                -- other external task action
            ELSE
                IF NOT set_task_action(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_episode          => i_episode,
                                       i_action           => i_action,
                                       i_task_type        => i_task_type,
                                       i_task_request     => i_task_request,
                                       o_new_task_request => o_new_task_request,
                                       o_flg_show         => l_flg_show,
                                       o_msg_template     => l_msg_template,
                                       o_msg_title        => l_msg_title,
                                       o_msg_body         => l_msg_body,
                                       o_flg_validated    => l_flg_validated,
                                       o_error            => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- this is used to show a popup error when different users are performing conflicting 
                -- actions at the same time.
                IF (l_flg_show = pk_alert_constant.get_yes)
                THEN
                    o_flg_conflict := table_varchar(l_flg_show);
                    o_msg_template := table_varchar(l_msg_template);
                    o_msg_title    := table_varchar(l_msg_title);
                    o_msg_body     := table_varchar(l_msg_body);
                END IF;
                -- assign flag transition to array     
                o_flg_validated := table_varchar(l_flg_validated);
            
        END CASE;
    
        -- commit perfomed CPOE action
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
                                              'SET_ACTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_action;

    FUNCTION set_task_bounds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_task_type          IN cpoe_task_type.id_task_type%TYPE,
        i_ts_task_start      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_task_end        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_start      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_end        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_next_start IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_next_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_ts_task_start      TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_task_end        TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_cpoe_start      TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_cpoe_end        TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_cpoe_next_start TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_cpoe_next_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        -- to check if full date format should be used or not in timestamp boundary evaluation
        FUNCTION check_full_date_validation RETURN BOOLEAN IS
            l_flg_full_date_validation cpoe_task_type.flg_full_date_validation%TYPE;
        BEGIN
        
            SELECT flg_full_date_validation
              INTO l_flg_full_date_validation
              FROM (SELECT ctsi.flg_full_date_validation,
                           row_number() over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) rn
                      FROM cpoe_task_soft_inst ctsi
                     WHERE ctsi.id_task_type = i_task_type
                       AND ctsi.id_institution IN (0, i_prof.institution)
                       AND ctsi.id_software IN (0, i_prof.software))
             WHERE rn = 1;
        
            IF l_flg_full_date_validation = pk_alert_constant.g_yes
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END check_full_date_validation;
    
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.set_task_bounds called with:' || chr(10) || 'i_prof=' ||
                                  get_prof_str(i_prof) || chr(10) || 'i_task_type=' || i_task_type || chr(10) ||
                                  'i_ts_task_start=' || i_ts_task_start || chr(10) || 'i_ts_cpoe_start=' ||
                                  i_ts_cpoe_start || chr(10) || 'i_ts_cpoe_end=' || i_ts_cpoe_end || chr(10) ||
                                  'i_ts_cpoe_next_start=' || i_ts_cpoe_next_start || chr(10) || 'i_ts_cpoe_next_end=' ||
                                  i_ts_cpoe_next_end || chr(10) || chr(10) || 'full date validation ' || CASE WHEN
                                  check_full_date_validation THEN 'will be used' ELSE 'will not be used' END,
                                  g_package_name);
        END IF;
    
        pk_alertlog.log_error('pk_cpoe.set_task_bounds called with:' || chr(10) || 'i_prof=' || get_prof_str(i_prof) ||
                              chr(10) || 'i_task_type=' || i_task_type || chr(10) || 'i_ts_task_start=' ||
                              i_ts_task_start || chr(10) || 'i_ts_cpoe_start=' || i_ts_cpoe_start || chr(10) ||
                              'i_ts_cpoe_end=' || i_ts_cpoe_end || chr(10) || 'i_ts_cpoe_next_start=' ||
                              i_ts_cpoe_next_start || chr(10) || 'i_ts_cpoe_next_end=' || i_ts_cpoe_next_end ||
                              chr(10) || chr(10) || 'full date validation ' || CASE WHEN check_full_date_validation THEN
                              'will be used' ELSE 'will not be used' END,
                              g_package_name);
    
        -- check if task type requires an active cpoe process
        IF check_task_cpoe_requirement(i_prof, i_task_type) = pk_alert_constant.g_yes
        THEN
            -- check if full date format should be used or not in timestamp boundary evaluation
            IF check_full_date_validation
            THEN
                -- compare full timestamps 
            
                IF (pk_date_utils.compare_dates_tsz(i_prof, i_ts_task_start, i_ts_cpoe_start) IN
                   (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_greater) AND
                   pk_date_utils.compare_dates_tsz(i_prof, i_ts_task_start, i_ts_cpoe_end) =
                   pk_alert_constant.g_date_lower)
                   OR i_task_type = 33
                THEN
                    RETURN g_task_bound_curr_presc; -- task belongs to current process    
                ELSIF i_ts_cpoe_next_start IS NOT NULL
                      AND pk_date_utils.compare_dates_tsz(i_prof, i_ts_task_start, i_ts_cpoe_next_start) IN
                      (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_greater)
                      AND pk_date_utils.compare_dates_tsz(i_prof, i_ts_task_start, i_ts_cpoe_next_end) =
                      pk_alert_constant.g_date_lower
                THEN
                    RETURN g_task_bound_next_presc; -- task belongs to next process
                ELSE
                    RETURN g_task_bound_out; -- timestamps out of bounds for this task
                END IF;
            ELSE
            
                -- truncate timestamps to days
                l_ts_task_start      := get_timestamp_day_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_ts_task_start);
                l_ts_task_end        := get_timestamp_day_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_ts_task_end);
                l_ts_cpoe_start      := get_timestamp_day_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_ts_cpoe_start);
                l_ts_cpoe_end        := get_timestamp_day_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_ts_cpoe_end);
                l_ts_cpoe_next_start := get_timestamp_day_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_ts_cpoe_next_start);
                l_ts_cpoe_next_end   := get_timestamp_day_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_ts_cpoe_next_end);
                -- compare truncated timestamps 
                IF (pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_start) IN
                   (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_greater) AND
                   pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_end) =
                   pk_alert_constant.g_date_lower)
                   OR (i_task_type IN (g_task_type_hidric,
                                       g_task_type_hidric_in_out,
                                       g_task_type_hidric_out,
                                       g_task_type_hidric_drain,
                                       g_task_type_hidric_in,
                                       g_task_type_hidric_out_group,
                                       g_task_type_hidric_out_all,
                                       g_task_type_hidric_irrigations) AND
                   pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_end) =
                   pk_alert_constant.g_date_lower)
                   OR
                   (l_ts_task_end IS NULL AND (pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_start) =
                   pk_alert_constant.g_date_equal OR
                   pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_end) =
                   pk_alert_constant.g_date_equal))
                   OR ((pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_start) IN
                   (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_greater)) AND
                   pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_end) =
                   pk_alert_constant.g_date_equal AND
                   pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_task_end) =
                   pk_alert_constant.g_date_equal)
                THEN
                    RETURN g_task_bound_curr_presc; -- task belongs to current process    
                ELSIF l_ts_cpoe_next_start IS NOT NULL
                      AND ((pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_next_start) IN
                      (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_greater) AND
                      pk_date_utils.compare_dates_tsz(i_prof, i_ts_task_start, l_ts_cpoe_next_end) =
                      pk_alert_constant.g_date_lower) OR
                      ((l_ts_task_end IS NULL OR
                      pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_task_end) =
                      pk_alert_constant.g_date_equal) AND
                      (pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_next_start) =
                      pk_alert_constant.g_date_greater AND
                      pk_date_utils.compare_dates_tsz(i_prof, l_ts_task_start, l_ts_cpoe_next_end) =
                      pk_alert_constant.g_date_equal)))
                THEN
                    RETURN g_task_bound_next_presc; -- task belongs to next process
                ELSE
                    RETURN g_task_bound_out; -- timestamps out of bounds for this task
                END IF;
            END IF;
        ELSE
            RETURN g_task_bound_no_presc; -- no prescription needed for this task
        END IF;
    END set_task_bounds;

    /********************************************************************************************
    * synchronize requested task with cpoe processes in task creation or draft activation
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id (also used for draft activation)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 2009/11/23
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_type            IN cpoe_task_type.id_task_type%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'call sync_task function (no changes in task request)';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT sync_task(i_lang                 => i_lang,
                         i_prof                 => i_prof,
                         i_episode              => i_episode,
                         i_task_type            => i_task_type,
                         i_old_task_request     => NULL,
                         i_new_task_request     => i_task_request,
                         i_task_start_timestamp => i_task_start_timestamp,
                         i_task_end_timestamp   => i_task_end_timestamp,
                         o_error                => o_error)
        THEN
            RAISE l_exception;
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
                                              'SYNC_TASK',
                                              o_error);
            RETURN FALSE;
    END sync_task;

    FUNCTION sync_active_to_next
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_type     IN cpoe_task_type.id_task_type%TYPE,
        i_request       IN cpoe_process_task.id_task_request%TYPE,
        i_flg_copy_next IN VARCHAR2 DEFAULT 'N',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_cpoe_next_process cpoe_process.id_cpoe_process%TYPE;
        l_dt_start          cpoe_process.dt_cpoe_proc_start%TYPE;
        l_dt_end            cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_request        cpoe_process_task.id_task_request%TYPE;
        l_exception EXCEPTION;
    BEGIN
    
        BEGIN
            SELECT cp.id_cpoe_process
              INTO l_cpoe_next_process
              FROM cpoe_process cp
             WHERE cp.id_episode = i_episode
               AND cp.flg_status = 'N';
        EXCEPTION
            WHEN OTHERS THEN
                IF NOT get_next_cpoe_date(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_episode  => i_episode,
                                          o_dt_start => l_dt_start,
                                          o_dt_end   => l_dt_end,
                                          o_error    => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF NOT create_cpoe(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_episode           => i_episode,
                                   i_proc_start        => NULL,
                                   i_proc_end          => NULL,
                                   i_proc_refresh      => NULL,
                                   i_proc_next_start   => pk_date_utils.get_timestamp_str(i_lang, i_prof, l_dt_start, NULL),
                                   i_proc_next_end     => pk_date_utils.get_timestamp_str(i_lang, i_prof, l_dt_end, NULL),
                                   i_proc_next_refresh => NULL,
                                   i_proc_type         => g_flg_warning_new_next_cpoe,
                                   o_cpoe_process      => l_cpoe_next_process,
                                   o_error             => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        END;
    
        IF i_flg_copy_next = pk_alert_constant.g_no
        THEN
            SELECT a.id_task_orig
              INTO l_id_request
              FROM cpoe_tasks_relation a
             WHERE a.id_task_dest = i_request
               AND rownum = 1;
        ELSE
            l_id_request := i_request;
        END IF;
    
        BEGIN
            INSERT INTO cpoe_process_task
                (id_cpoe_process,
                 id_task_type,
                 id_task_request,
                 dt_proc_task_create,
                 id_professional,
                 id_institution,
                 id_software,
                 id_episode)
            VALUES
                (l_cpoe_next_process,
                 i_task_type,
                 l_id_request,
                 current_timestamp,
                 i_prof.id,
                 i_prof.institution,
                 i_prof.software,
                 i_episode);
        EXCEPTION
            -- this exception is here only to avoid tasks synchronization when target tasks are being changed
            WHEN dup_val_on_index THEN
                NULL;
        END;
    
        IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_cpoe_process => l_cpoe_next_process,
                                     i_tasks_orig   => table_number(l_id_request),
                                     i_tasks_dest   => table_number(l_id_request),
                                     i_tasks_type   => table_number(i_task_type),
                                     i_flg_type     => 'REP',
                                     o_error        => o_error)
        THEN
            RAISE l_exception;
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
                                              'SYNC_ACTIVE_TO_NEXT',
                                              o_error);
            RETURN FALSE;
    END sync_active_to_next;

    /********************************************************************************************
    * synchronize requested task with cpoe processes in task creation or draft activation
    * this overload is used for tasks that creates a new request for each statua transition
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_old_task_request        old task request id (also used for draft activation)
    * @param       i_new_task_request        new task request id (also used for draft activation)   
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 2009/12/09
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_type            IN cpoe_task_type.id_task_type%TYPE,
        i_old_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_new_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_noreqnext EXCEPTION;
        l_error                t_error_out;
        l_flg_cpoe_mode        VARCHAR2(1 CHAR);
        l_flg_cpoe_status      VARCHAR2(1 CHAR);
        l_cpoe_process         cpoe_process.id_cpoe_process%TYPE;
        l_cpoe_next_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_next_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional      professional.id_professional%TYPE;
        l_ts_cpoe_refresh      cpoe_process.dt_cpoe_proc_end%TYPE;
        l_dt_next_presc        cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_refresh cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_end%TYPE;
        l_task_boundary        VARCHAR2(1 CHAR);
        l_can_req_next         VARCHAR2(1 CHAR);
    
        l_final_day_date cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_current_timestamp TIMESTAMP WITH TIME ZONE;
    
        l_planning_period cpoe_period.planning_period%TYPE;
        l_expire_time     cpoe_period.expire_time%TYPE;
    
        l_hour   NUMBER;
        l_minute NUMBER;
    
        l_can_presc VARCHAR2(1 CHAR);
    
        l_ret BOOLEAN;
    BEGIN
    
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.sync_task called with:' || chr(10) || 'i_lang=' || i_lang || chr(10) ||
                                  'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode || chr(10) ||
                                  'i_task_type=' || i_task_type || chr(10) || 'i_old_task_request=' ||
                                  i_old_task_request || chr(10) || 'i_new_task_request=' || i_new_task_request ||
                                  chr(10) || 'i_task_start_timestamp=' || i_task_start_timestamp || chr(10) ||
                                  'i_task_end_timestamp=' || i_task_end_timestamp,
                                  g_package_name);
        END IF;
    
        l_can_req_next := check_next_presc_can_req(i_lang, i_prof, i_episode);
    
        --check_task_creation
    
        --create_cpoe
    
        IF task_out_of_cpoe_process(i_lang, i_prof, i_task_type) = pk_alert_constant.g_yes
        THEN
            RETURN TRUE;
        END IF;
    
        -- get cpoe mode to evaluate if the task should be created or not
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- only sync tasks with cpoe process when working in advanced mode
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
           AND check_task_cpoe_requirement(i_prof, i_task_type) = pk_alert_constant.g_yes
        THEN
            g_error := 'call get_last_cpoe_info';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get last cpoe information
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_cpoe_process,
                                      o_dt_start        => l_ts_cpoe_start,
                                      o_dt_end          => l_ts_cpoe_end,
                                      o_flg_status      => l_flg_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- get next prescription process
            get_next_presc_process(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   o_cpoe_process => l_cpoe_next_process,
                                   o_dt_start     => l_ts_cpoe_next_start,
                                   o_dt_end       => l_ts_cpoe_next_end);
        
            IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_episode       => i_episode,
                                      i_dt_start      => l_ts_cpoe_end,
                                      o_dt_start      => l_ts_cpoe_next_start, -- is equal to l_ts_cpoe_end
                                      o_dt_end        => l_ts_cpoe_next_end, -- calculated value
                                      o_dt_refresh    => l_ts_cpoe_next_refresh,
                                      o_dt_next_presc => l_ts_cpoe_next_presc,
                                      o_error         => o_error) -- calculated value
            THEN
                RAISE l_exception;
            END IF;
        
            -- get task boundary                         
            l_task_boundary := set_task_bounds(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_task_type          => i_task_type,
                                               i_ts_task_start      => i_task_start_timestamp,
                                               i_ts_task_end        => i_task_end_timestamp,
                                               i_ts_cpoe_start      => l_ts_cpoe_start,
                                               i_ts_cpoe_end        => l_ts_cpoe_end,
                                               i_ts_cpoe_next_start => l_ts_cpoe_next_start,
                                               i_ts_cpoe_next_end   => l_ts_cpoe_next_end);
        
            IF l_can_req_next = pk_alert_constant.g_no
               AND l_task_boundary = g_task_bound_next_presc
            THEN
                RAISE l_noreqnext;
            END IF;
        
            -- check if task boundary fits in current or next cpoe process
            IF l_task_boundary IN (g_task_bound_curr_presc, g_task_bound_next_presc)
            THEN
            
                IF l_flg_cpoe_status NOT IN (g_filter_active, g_filter_next)
                   OR l_flg_cpoe_status IS NULL
                THEN
                    IF NOT pk_cpoe.create_cpoe(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_episode           => i_episode,
                                               i_proc_start        => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ts_cpoe_start,
                                                                                                      NULL),
                                               i_proc_end          => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ts_cpoe_end,
                                                                                                      NULL),
                                               i_proc_refresh      => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ts_cpoe_refresh,
                                                                                                      NULL),
                                               i_proc_next_start   => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      NULL),
                                               i_proc_next_end     => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      NULL),
                                               i_proc_next_refresh => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ts_cpoe_next_presc,
                                                                                                      NULL),
                                               i_proc_type         => 'P',
                                               o_cpoe_process      => l_cpoe_process,
                                               o_error             => l_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
                -- check if is an insert or an update
                IF i_old_task_request IS NULL
                THEN
                
                    IF g_debug
                    THEN
                        pk_alertlog.log_debug('pk_cpoe.sync_task: insert new cpoe process task request [' ||
                                              i_new_task_request || '], for task type [' || i_task_type ||
                                              '], cpoe process [' || CASE l_task_boundary WHEN g_task_bound_curr_presc THEN
                                              l_cpoe_process ELSE l_cpoe_next_process
                                              END || '] and task boundary is [' || l_task_boundary || ']',
                                              g_package_name);
                    END IF;
                    -- insert new record in cpoe_process_task
                
                    IF NOT pk_cpoe.delete_cpoe_process(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => i_episode,
                                                       i_task_type    => i_task_type,
                                                       i_task_request => i_new_task_request,
                                                       o_error        => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    BEGIN
                        INSERT INTO cpoe_process_task
                            (id_cpoe_process,
                             id_task_type,
                             id_task_request,
                             dt_proc_task_create,
                             id_professional,
                             id_institution,
                             id_software,
                             id_episode)
                        VALUES
                            (CASE l_task_boundary WHEN g_task_bound_curr_presc THEN l_cpoe_process ELSE
                             l_cpoe_next_process END,
                             i_task_type,
                             i_new_task_request,
                             current_timestamp,
                             i_prof.id,
                             i_prof.institution,
                             i_prof.software,
                             i_episode);
                    EXCEPTION
                        -- this exception is here only to avoid tasks synchronization when target tasks are being changed
                        WHEN dup_val_on_index THEN
                            NULL;
                    END;
                
                    -- copy non-expirable tasks to next prescription also (if already created), 
                    -- if they're placed in current prescription
                    IF l_task_boundary = g_task_bound_curr_presc
                       AND check_task_cpoe_expire(i_prof, i_task_type) = pk_alert_constant.g_no
                       AND l_cpoe_next_process IS NOT NULL
                    THEN
                        IF g_debug
                        THEN
                            pk_alertlog.log_debug('pk_cpoe.sync_task: copy new non-expirable cpoe process task request [' ||
                                                  i_new_task_request || '], for task type [' || i_task_type ||
                                                  '], to next cpoe process [' || l_cpoe_next_process || ']',
                                                  g_package_name);
                        END IF;
                        -- insert new record in cpoe_process_task
                        BEGIN
                            INSERT INTO cpoe_process_task
                                (id_cpoe_process,
                                 id_task_type,
                                 id_task_request,
                                 dt_proc_task_create,
                                 id_professional,
                                 id_institution,
                                 id_software,
                                 id_episode)
                            VALUES
                                (l_cpoe_next_process,
                                 i_task_type,
                                 i_new_task_request,
                                 current_timestamp,
                                 i_prof.id,
                                 i_prof.institution,
                                 i_prof.software,
                                 i_episode);
                        EXCEPTION
                            -- this exception is here only to avoid tasks synchronization when target tasks are being changed
                            WHEN dup_val_on_index THEN
                                NULL;
                        END;
                    END IF;
                
                ELSE
                    IF g_debug
                    THEN
                        pk_alertlog.log_debug('pk_cpoe.sync_task: update id_task_request cpoe process task from [' ||
                                              i_old_task_request || '] to [' || i_new_task_request ||
                                              '], for task type [' || i_task_type || ']',
                                              g_package_name);
                    END IF;
                    -- update request
                    /*UPDATE cpoe_process_task
                      SET id_task_request = i_new_task_request
                    WHERE id_task_type = i_task_type
                      AND id_task_request = i_old_task_request;*/
                
                    IF NOT pk_cpoe.delete_cpoe_process(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => i_episode,
                                                       i_task_type    => i_task_type,
                                                       i_task_request => i_old_task_request,
                                                       o_error        => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    BEGIN
                        INSERT INTO cpoe_process_task
                            (id_cpoe_process,
                             id_task_type,
                             id_task_request,
                             dt_proc_task_create,
                             id_professional,
                             id_institution,
                             id_software,
                             id_episode)
                        VALUES
                            (CASE l_task_boundary WHEN g_task_bound_curr_presc THEN l_cpoe_process ELSE
                             l_cpoe_next_process END,
                             i_task_type,
                             i_new_task_request,
                             current_timestamp,
                             i_prof.id,
                             i_prof.institution,
                             i_prof.software,
                             i_episode);
                    EXCEPTION
                        -- this exception is here only to avoid tasks synchronization when target tasks are being changed
                        WHEN dup_val_on_index THEN
                            NULL;
                    END;
                
                    -- copy non-expirable tasks to next prescription also (if already created), 
                    -- if they're placed in current prescription
                    IF l_task_boundary = g_task_bound_curr_presc
                       AND check_task_cpoe_expire(i_prof, i_task_type) = pk_alert_constant.g_no
                       AND l_cpoe_next_process IS NOT NULL
                    THEN
                        IF g_debug
                        THEN
                            pk_alertlog.log_debug('pk_cpoe.sync_task: copy new non-expirable cpoe process task request [' ||
                                                  i_new_task_request || '], for task type [' || i_task_type ||
                                                  '], to next cpoe process [' || l_cpoe_next_process || ']',
                                                  g_package_name);
                        END IF;
                        -- insert new record in cpoe_process_task
                        BEGIN
                            INSERT INTO cpoe_process_task
                                (id_cpoe_process,
                                 id_task_type,
                                 id_task_request,
                                 dt_proc_task_create,
                                 id_professional,
                                 id_institution,
                                 id_software,
                                 id_episode)
                            VALUES
                                (l_cpoe_next_process,
                                 i_task_type,
                                 i_new_task_request,
                                 current_timestamp,
                                 i_prof.id,
                                 i_prof.institution,
                                 i_prof.software,
                                 i_episode);
                        EXCEPTION
                            -- this exception is here only to avoid tasks synchronization when target tasks are being changed
                            WHEN dup_val_on_index THEN
                                NULL;
                        END;
                    END IF;
                
                END IF;
            
                -- task boundary doesn't fit in current or next cpoe process
            ELSE
                pk_alert_exceptions.raise_error(error_name_in => 'sync_task',
                                                text_in       => 'pk_cpoe.sync_task: task boundary for task type [' ||
                                                                 i_task_type || '] and task request [' ||
                                                                 i_new_task_request ||
                                                                 '] doesn''t fit in current or next cpoe process');
            END IF;
        
        ELSIF l_flg_cpoe_mode = g_cfg_cpoe_mode_simple
              AND i_old_task_request IS NOT NULL
        THEN
            -- just try to update the new reference, if the old exists 
            -- (when other environments, that are not using advanced mode, updates tasks that mey belong to a cpoe process)
            IF g_debug
            THEN
                pk_alertlog.log_debug('pk_cpoe.sync_task: try to update id_task_request cpoe process task from [' ||
                                      i_old_task_request || '] to [' || i_new_task_request || '], for task type [' ||
                                      i_task_type || ']',
                                      g_package_name);
            END IF;
            -- try to update request
            UPDATE cpoe_process_task
               SET id_task_request = i_new_task_request
             WHERE id_task_type = i_task_type
               AND id_task_request = i_old_task_request;
        
        END IF;
        RETURN TRUE;
        -- no commit: no transaction control in this function (is done in the calling function)
    EXCEPTION
        WHEN l_noreqnext THEN
        
            l_current_timestamp := pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, SYSDATE);
            l_planning_period   := pk_cpoe.get_cpoe_planning_period(i_lang, i_prof, i_episode);
            l_expire_time       := pk_cpoe.get_cpoe_expire_time(i_lang, i_prof, i_episode);
        
            l_final_day_date := pk_date_utils.get_string_tstz(i_lang,
                                                              i_prof,
                                                              to_char(l_current_timestamp, 'YYYYMMDD') ||
                                                              substr(l_expire_time, 1, 2) || substr(l_expire_time, 4, 2) || '00',
                                                              NULL);
        
            --l_final_day_date := pk_date_utils.add_to_ltstz(l_final_day_date, l_planning_period, 'HOUR');
        
            l_hour   := extract(hour FROM(l_final_day_date - l_current_timestamp));
            l_minute := extract(minute FROM(l_final_day_date - l_current_timestamp));
            pk_alert_exceptions.reset_error_state;
            l_ret := pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                       i_sqlcode     => '',
                                                       i_sqlerrm     => pk_cpoe.get_cpoe_message(i_lang         => i_lang,
                                                                                                 i_code_message => 'CPOE_M050',
                                                                                                 i_param1       => CASE
                                                                                                                       WHEN l_hour = 0 THEN
                                                                                                                        l_minute || ' ' || pk_message.get_message(i_lang, 'SCH_T099')
                                                                                                                       ELSE
                                                                                                                        l_hour || ' ' || pk_message.get_message(i_lang, 'COMMON_M123') || ' ' ||
                                                                                                                        pk_message.get_message(i_lang, 'SCH_T103') || ' ' || l_minute || ' ' ||
                                                                                                                        pk_message.get_message(i_lang, 'SCH_T099')
                                                                                                                   END),
                                                       i_message     => NULL,
                                                       i_owner       => NULL,
                                                       i_package     => NULL,
                                                       i_function    => NULL,
                                                       i_action_type => 'U',
                                                       i_action_msg  => 'NOREQNEXT',
                                                       i_msg_title   => pk_message.get_message(i_lang, 'PRESC_WARNING_T001'),
                                                       i_msg_type    => NULL,
                                                       o_error       => o_error);
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sync_task',
                                              o_error);
            RETURN FALSE;
    END sync_task;

    FUNCTION delete_cpoe_process
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
    
        DELETE FROM cpoe_process_task
         WHERE id_task_type = i_task_type
           AND id_task_request = i_task_request
           AND id_episode = i_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'delete_cpoe_process',
                                              o_error);
            RETURN FALSE;
        
    END delete_cpoe_process;

    FUNCTION delete_create_cpoe_process
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cpoe_process IN cpoe_process.id_cpoe_process%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode episode.id_episode%TYPE;
    BEGIN
    
        SELECT id_episode
          INTO l_id_episode
          FROM cpoe_process
         WHERE id_cpoe_process = i_id_cpoe_process;
    
        DELETE FROM cpoe_process
         WHERE id_cpoe_process = i_id_cpoe_process
            OR (id_episode = l_id_episode AND flg_status = pk_cpoe.g_task_filter_active);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_CREATE_CPOE_PROCESS',
                                              o_error);
            RETURN FALSE;
        
    END delete_create_cpoe_process;

    /********************************************************************************************
    * get task list to be used in confirmation / out of bounds prompts
    *
    * @param       i_lang            preferred language id for this professional
    * @param       i_prof            professional id structure
    * @param       i_task_type       cpoe task type id
    * @param       i_tasks           list of task ids
    * @param       o_task_list       list of task to be used in prompt screen
    * @param       o_error           error message
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         2009/11/21
    ********************************************************************************************/
    FUNCTION get_task_prompt_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE,
        i_tasks     IN table_varchar,
        o_task_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ts_curr TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
        g_error := 'get o_task_list cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_list FOR
            SELECT /*+opt_estimate(table task_list rows=1)*/
             get_task_group_id(i_prof, i_task_type) AS group_type_id,
             get_task_group_name(i_lang, i_prof, i_task_type) AS task_group_desc,
             get_task_group_rank(i_prof, i_task_type) AS task_group_rank,
             i_task_type AS id_task_type,
             tt.id_target_task_type AS id_target_task_type,
             task_list.column_value AS id_task,
             tt.icon,
             pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
             pk_date_utils.date_char_hour_tsz(i_lang, l_ts_curr, i_prof.institution, i_prof.software) AS time_desc,
             pk_date_utils.date_chr_short_read_tsz(i_lang, l_ts_curr, i_prof.institution, i_prof.software) AS date_desc
              FROM TABLE(i_tasks) task_list
              JOIN cpoe_task_type tt
                ON tt.id_task_type = i_task_type
             ORDER BY id_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_PROMPT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_task_prompt_list;

    /********************************************************************************************
    * get draft tasks list to be used in confirmation / out of bounds prompts
    *
    * @param       i_lang            preferred language id for this professional
    * @param       i_prof            professional id structure
    * @param       i_task_type       list of cpoe task type id
    * @param       i_drafts          list of draft task ids
    * @param       o_task_list       list of task to be used in prompt screen
    * @param       o_error           error message
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         2009/11/26
    ********************************************************************************************/
    FUNCTION get_drafts_prompt_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN table_number,
        i_drafts    IN table_number,
        o_task_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ts_curr TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
        g_error := 'get o_task_list cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_list FOR
            SELECT get_task_group_id(i_prof, tt.id_task_type) AS group_type_id,
                   get_task_group_name(i_lang, i_prof, tt.id_task_type) AS task_group_desc,
                   get_task_group_rank(i_prof, tt.id_task_type) AS task_group_rank,
                   tt.id_task_type AS id_task_type,
                   tt.id_target_task_type AS id_target_task_type,
                   task_list.id_draft_request AS id_task,
                   tt.icon,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
                   pk_date_utils.date_char_hour_tsz(i_lang, l_ts_curr, i_prof.institution, i_prof.software) AS time_desc,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, l_ts_curr, i_prof.institution, i_prof.software) AS date_desc
              FROM (SELECT /*+opt_estimate(table a rows=1)*/
                     rownum AS rn, column_value AS id_draft_request
                      FROM TABLE(i_drafts) a) task_list
              JOIN (SELECT /*+opt_estimate(table b rows=1)*/
                     rownum AS rn, column_value AS id_task_type
                      FROM TABLE(i_task_type) b) task_type
                ON task_type.rn = task_list.rn
              JOIN cpoe_task_type tt
                ON tt.id_task_type = task_type.id_task_type
             ORDER BY task_group_rank, tt.id_task_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DRAFTS_PROMPT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_drafts_prompt_list;

    /********************************************************************************************
    * get tasks list to be used in confirmation / out of bounds prompts
    *
    * @param       i_lang            preferred language id for this professional
    * @param       i_prof            professional id structure
    * @param       i_task_type       list of cpoe task type id
    * @param       i_tasks           list of task ids
    * @param       o_task_list       list of task to be used in prompt screen
    * @param       o_error           error message
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         2009/11/26
    ********************************************************************************************/
    FUNCTION get_tasks_prompt_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN table_number,
        i_tasks     IN table_varchar,
        o_task_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ts_curr TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
        g_error := 'get o_task_list cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_list FOR
            SELECT get_task_group_id(i_prof, tt.id_task_type) AS group_type_id,
                   get_task_group_name(i_lang, i_prof, tt.id_task_type) AS task_group_desc,
                   get_task_group_rank(i_prof, tt.id_task_type) AS task_group_rank,
                   tt.id_task_type AS id_task_type,
                   tt.id_target_task_type AS id_target_task_type,
                   task_list.id_request AS id_task,
                   tt.icon,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
                   pk_date_utils.date_char_hour_tsz(i_lang, l_ts_curr, i_prof.institution, i_prof.software) AS time_desc,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, l_ts_curr, i_prof.institution, i_prof.software) AS date_desc
              FROM (SELECT /*+opt_estimate(table a rows=1)*/
                     rownum AS rn, column_value AS id_request
                      FROM TABLE(i_tasks) a) task_list
              JOIN (SELECT /*+opt_estimate(table b rows=1)*/
                     rownum AS rn, column_value AS id_task_type
                      FROM TABLE(i_task_type) b) task_type
                ON task_type.rn = task_list.rn
              JOIN cpoe_task_type tt
                ON tt.id_task_type = task_type.id_task_type
             ORDER BY task_group_rank, tt.id_task_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASKS_PROMPT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_tasks_prompt_list;

    FUNCTION task_out_of_cpoe_process
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN NUMBER
    ) RETURN VARCHAR2 IS
        l_flg_out_process VARCHAR2(1 CHAR);
    BEGIN
    
        SELECT flg_out_of_cpoe_process
          INTO l_flg_out_process
          FROM (SELECT ctsi.flg_out_of_cpoe_process,
                       row_number() over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) rn
                  FROM cpoe_task_soft_inst ctsi
                 WHERE ctsi.id_task_type = i_task_type
                   AND ctsi.id_institution IN (0, i_prof.institution)
                   AND ctsi.id_software IN (0, i_prof.software))
         WHERE rn = 1;
    
        IF l_flg_out_process = pk_alert_constant.g_yes
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END task_out_of_cpoe_process;

    /********************************************************************************************
    * checks within cpoe if the given tasks can be created or not (in tasks requests)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_dt_start                tasks start timestamps
    * @param       i_dt_end                  tasks end timestamps
    * @param       i_task_id                 task ids (can be used with drafts also)
    * @param       o_task_list               list of tasks, according to cpoe confirmation grid
    * @param       o_flg_warning_type        warning type flag
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body, according to warning type flag
    * @param       o_proc_start              cpoe process start timestamp (for new cpoe process)
    * @param       o_proc_end                cpoe process end timestamp (for new cpoe process)
    * @param       o_proc_refresh            cpoe refresh to draft prescription timestamp (for new cpoe process)
    * @param       o_error                   error message
    *        
    * @value       o_flg_warning_type        {*} 'O' timestamps out of bounds
    *                                        {*} 'C' confirm cpoe creation
    *                                        {*} NULL proceed task creation, without warnings
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 14-Sep-2010
    ********************************************************************************************/
    FUNCTION check_tasks_creation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN table_number,
        i_dt_start          IN table_varchar,
        i_dt_end            IN table_varchar,
        i_task_id           IN table_varchar,
        i_tab_type          IN VARCHAR2 DEFAULT NULL,
        o_task_list         OUT pk_types.cursor_type,
        o_flg_warning_type  OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_proc_start        OUT VARCHAR2,
        o_proc_end          OUT VARCHAR2,
        o_proc_refresh      OUT VARCHAR2,
        o_proc_next_start   OUT VARCHAR2,
        o_proc_next_end     OUT VARCHAR2,
        o_proc_next_refresh OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_flg_cpoe_mode        VARCHAR2(1 CHAR);
        l_flg_cpoe_status      VARCHAR2(1 CHAR);
        l_cpoe_process         cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh      cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_next_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_refresh cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_id_professional      professional.id_professional%TYPE;
        l_can_create_presc     VARCHAR2(1 CHAR) := g_flg_inactive;
    
        l_task_req_list        t_tbl_cpoe_task_create := t_tbl_cpoe_task_create(); -- t_rec_cpoe_task_create
        l_has_out_of_bounds    VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_no_presc_tasks   VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_curr_presc_tasks VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_next_presc_tasks VARCHAR2(1) := pk_alert_constant.g_no;
        l_out_of_cpoe_process  VARCHAR2(1) := pk_alert_constant.g_no;
        l_next_presc_exists    BOOLEAN := FALSE;
    
        l_ts_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_ts_task_end_date TIMESTAMP WITH LOCAL TIME ZONE;
    
        e_subscript_beyond_count EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_subscript_beyond_count, -06533);
    
    BEGIN
    
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.check_tasks_creation called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode ||
                                  chr(10) || 'i_task_type=' || get_tabnum_str(i_task_type) || chr(10) || 'i_dt_start=' ||
                                  get_tabvar_str(i_dt_start) || chr(10) || 'i_dt_end=' || get_tabvar_str(i_dt_end) ||
                                  chr(10) || 'i_task_id=' || get_tabvar_str(i_task_id),
                                  g_package_name);
        END IF;
    
        -- get cpoe mode to evaluate if the task should be created or not
        pk_alertlog.log_debug('get_cpoe_mode', g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
        
            -- check if professional is allowed to create prescriptions
            l_can_create_presc := check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action);
        
            -- get last cpoe information to check if an active prescription exists
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_cpoe_process,
                                      o_dt_start        => l_ts_cpoe_start,
                                      o_dt_end          => l_ts_cpoe_end,
                                      o_flg_status      => l_flg_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- if last cpoe is not active
            IF l_flg_cpoe_status <> g_flg_status_a
            THEN
                -- no cpoe process created so far. system will check if all tasks have the proper start timestamps 
                -- by checking the cpoe automatic creation periods
                IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_dt_start      => NULL,
                                          o_dt_start      => l_ts_cpoe_start,
                                          o_dt_end        => l_ts_cpoe_end,
                                          o_dt_refresh    => l_ts_cpoe_refresh,
                                          o_dt_next_presc => l_ts_cpoe_next_presc,
                                          o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            -- get next prescription process
            get_next_presc_process(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   o_cpoe_process => l_cpoe_process,
                                   o_dt_start     => l_ts_cpoe_next_start,
                                   o_dt_end       => l_ts_cpoe_next_end);
        
            IF l_cpoe_process IS NULL
            THEN
                -- no next prescription created so far
                l_next_presc_exists := FALSE;
            ELSE
                -- next prescription already exists
                l_next_presc_exists := TRUE;
            END IF;
        
            -- if next prescription process doesn't exist, then calculate start/end timestamps, 
            -- starting from previous current active prescription
            IF l_cpoe_process IS NULL
               AND check_next_presc_availability(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode) =
               pk_alert_constant.g_yes
            THEN
                -- get next cpoe period, after the active current cpoe
                -- the start timestamp of next cpoe is the end timestamp of current active prescription process
                IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_dt_start      => l_ts_cpoe_end,
                                          o_dt_start      => l_ts_cpoe_next_start, -- is equal to l_ts_cpoe_end
                                          o_dt_end        => l_ts_cpoe_next_end, -- calculated value
                                          o_dt_refresh    => l_ts_cpoe_next_refresh,
                                          o_dt_next_presc => l_ts_cpoe_next_presc,
                                          o_error         => o_error) -- calculated value
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            -- at this point we already know the valid cpoe period (actual or new)
            o_proc_start   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_start, i_prof);
            o_proc_end     := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_end, i_prof);
            o_proc_refresh := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_refresh, i_prof);
            -- these represent the next cpoe period
            o_proc_next_start   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_next_start, i_prof);
            o_proc_next_end     := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_next_end, i_prof);
            o_proc_next_refresh := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_next_refresh, i_prof);
        
            -- check if all start timestamps fits in the cpoe periods
            FOR i IN i_task_id.first .. i_task_id.last
            LOOP
            
                -- workaround to avoid end date null array for task types that doesn't have end dates or aren't handling this field
                BEGIN
                    IF i_dt_end IS NOT NULL
                    THEN
                        l_ts_task_end_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end(i), NULL);
                    ELSE
                        l_ts_task_end_date := NULL;
                    END IF;
                EXCEPTION
                    WHEN e_subscript_beyond_count THEN
                        l_ts_task_end_date := NULL;
                END;
            
                -- set task boundary type
                l_task_req_list.extend;
                l_task_req_list(i) := t_rec_cpoe_task_create(i_task_type(i),
                                                             i_task_id(i),
                                                             set_task_bounds(i_lang               => i_lang,
                                                                             i_prof               => i_prof,
                                                                             i_task_type          => i_task_type(i),
                                                                             i_ts_task_start      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   i_dt_start(i),
                                                                                                                                   NULL),
                                                                             i_ts_task_end        => l_ts_task_end_date,
                                                                             i_ts_cpoe_start      => l_ts_cpoe_start,
                                                                             i_ts_cpoe_end        => l_ts_cpoe_end,
                                                                             i_ts_cpoe_next_start => l_ts_cpoe_next_start,
                                                                             i_ts_cpoe_next_end   => l_ts_cpoe_next_end));
            
                -- set answer type
                IF task_out_of_cpoe_process(i_lang, i_prof, i_task_type(i)) = pk_alert_constant.g_yes
                THEN
                    l_out_of_cpoe_process := pk_alert_constant.g_yes;
                ELSIF l_task_req_list(i).flg_status = g_task_bound_curr_presc
                THEN
                    l_has_curr_presc_tasks := pk_alert_constant.g_yes;
                ELSIF l_task_req_list(i).flg_status = g_task_bound_next_presc
                THEN
                    l_has_next_presc_tasks := pk_alert_constant.g_yes;
                ELSIF l_task_req_list(i).flg_status = g_task_bound_out
                THEN
                    l_has_out_of_bounds := pk_alert_constant.g_yes;
                ELSE
                    -- if l_task_req_list(i).flg_status = g_task_bound_no_presc 
                    l_has_no_presc_tasks := pk_alert_constant.g_yes;
                END IF;
            END LOOP;
        
            IF l_out_of_cpoe_process = pk_alert_constant.g_yes
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_none;
            ELSIF
            -- if all tasks can be activated without the need of a prescription
             l_has_no_presc_tasks = pk_alert_constant.g_yes
             AND l_has_curr_presc_tasks = pk_alert_constant.g_no
             AND l_has_next_presc_tasks = pk_alert_constant.g_no
             AND l_has_out_of_bounds = pk_alert_constant.g_no
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_none; -- no warnings
            
                -- if a new prescription is needed and the professional category is not allowed to create it (including the next one)
            ELSIF l_can_create_presc = g_flg_inactive
                  AND (l_flg_cpoe_status <> g_flg_status_a OR
                  (l_flg_cpoe_status = g_flg_status_a AND NOT l_next_presc_exists AND
                  l_has_next_presc_tasks = pk_alert_constant.g_yes))
            THEN
                -- "new prescription creation" title 
                o_msg_title := pk_message.get_message(i_lang, 'CPOE_T015');
            
                -- "cannot create tasks without creating a new prescription" message
                o_msg_body := '<b>' || pk_message.get_message(i_lang, 'CPOE_M021') || '</b>';
            
                o_flg_warning_type := g_flg_warning_cpoe_blocked; -- block tasks creation
            
                pk_alertlog.log_debug('get o_task_list cursor for warning message', g_package_name);
                OPEN o_task_list FOR
                    SELECT /*+opt_estimate(table task_list rows=1)*/
                     pk_cpoe.get_task_group_id(i_prof, tt.id_task_type) AS group_type_id,
                     pk_cpoe.get_task_group_name(i_lang, i_prof, tt.id_task_type) AS task_group_desc,
                     pk_cpoe.get_task_group_rank(i_prof, tt.id_task_type) AS task_group_rank,
                     tt.id_task_type AS id_task_type,
                     tt.id_target_task_type AS id_target_task_type,
                     task_list.id_request AS id_task,
                     tt.icon,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
                     pk_date_utils.date_char_hour_tsz(i_lang,
                                                      l_ts_current_timestamp,
                                                      i_prof.institution,
                                                      i_prof.software) AS time_desc,
                     pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                           l_ts_current_timestamp,
                                                           i_prof.institution,
                                                           i_prof.software) AS date_desc,
                     task_list.flg_status AS flg_task_boundary_status
                      FROM TABLE(l_task_req_list) task_list
                      JOIN cpoe_task_type tt
                        ON tt.id_task_type = task_list.id_task_type
                     WHERE l_flg_cpoe_status <> g_flg_status_a
                        OR (l_flg_cpoe_status = g_flg_status_a AND task_list.flg_status = g_task_bound_next_presc)
                     ORDER BY task_group_rank, tt.id_task_type;
            
                -- if all start timestamps fits in the new cpoe period (there is no active cpoe)
            ELSIF l_has_curr_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_next_presc_tasks = pk_alert_constant.g_no
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
                  AND l_flg_cpoe_status <> g_flg_status_a
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_new_cpoe; -- create new cpoe 
            
                -- NOT USED ANYMORE: evaluate if get_confirm_on_cpoe_creation feature is really needed
                -- check if user should confirm the creation of a new cpoe process
                --IF NOT get_confirm_on_cpoe_creation(i_lang        => i_lang,
                --                                    i_prof        => i_prof,
                --                                    o_flg_confirm => l_confirm_presc_creation,
                --                                    o_error       => o_error)
                --THEN
                --    g_error := 'error found while calling pk_cpoe.get_confirm_on_cpoe_creation function';
                --    RAISE l_exception;
                --END IF;
            
                -- no active cpoe (confirm creation of new one)
                --IF l_confirm_presc_creation = pk_alert_constant.g_yes
                --THEN
                --    -- "new prescription creation" message
                --    o_msg_title := pk_message.get_message(i_lang, 'CPOE_T015');
                --    -- "no active prescription found. in order to request these tasks you will need to create a new prescription" message
                --    o_msg_body         := '<b>' || pk_message.get_message(i_lang, 'CPOE_M002') || '</b><br><br>' ||
                --                          get_cpoe_message(i_lang         => i_lang,
                --                                           i_code_message => 'CPOE_M003',
                --                                           i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                --                                                                                              l_ts_cpoe_start,
                --                                                                                              i_prof.institution,
                --                                                                                              i_prof.software),
                --                                           i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                --                                                                                                   l_ts_cpoe_start,
                --                                                                                                   i_prof.institution,
                --                                                                                                   i_prof.software),
                --                                           i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                --                                                                                              l_ts_cpoe_end,
                --                                                                                              i_prof.institution,
                --                                                                                              i_prof.software),
                --                                           i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                --                                                                                                   l_ts_cpoe_end,
                --                                                                                                   i_prof.institution,
                --                                                                                                   i_prof.software));
                --    o_flg_warning_type := g_flg_warning_no_cpoe;
                --
                --    g_error := 'get o_task_list cursor for confirmation message';
                --    pk_alertlog.log_debug(g_error, g_package_name);
                --    IF NOT get_tasks_prompt_list(i_lang, i_prof, i_task_type, i_task_id, o_task_list, o_error)
                --    THEN
                --        RAISE l_exception;
                --    END IF;
                --ELSE
                --    -- no confirmation message: create tasks in the new prescriptions
                --    o_flg_warning_type := g_flg_warning_new_cpoe; -- new cpoe creation is needed
                --    pk_types.open_my_cursor(o_task_list);
                --END IF;
            
                -- if all start timestamps fits in the next cpoe period (with an active cpoe)
            ELSIF l_has_next_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
            THEN
                -- if next prescription already exists
                IF l_next_presc_exists
                THEN
                    pk_types.open_my_cursor(o_task_list);
                    o_flg_warning_type := g_flg_warning_none; -- no warnings
                ELSE
                    pk_types.open_my_cursor(o_task_list);
                    o_flg_warning_type := g_flg_warning_new_next_cpoe; -- create new next cpoe 
                END IF;
            
                -- if all start timestamps fits in the current active cpoe period
            ELSIF l_has_curr_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
                  AND l_flg_cpoe_status = g_flg_status_a
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_none; -- no warnings
            
                -- some task dates are out of bounds    
            ELSE
                -- "prescription period" message
                o_msg_title := pk_message.get_message(i_lang, 'CPOE_T016');
            
                -- message is different regarding the actual state of cpoe
                -- if we don't have an active cpoe and out of bound tasks don't fit in active cpoe (about to be created)
                IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M022',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                
                    IF pk_utils.search_table_number(i_task_type, g_task_type_medication) > 0
                    THEN
                        o_msg_body := o_msg_body || '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M042');
                    END IF;
                
                    -- if we have an active cpoe and we are able to prescribe in the next one, with out of boundary tasks that don't fit in any cpoe process
                ELSE
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M025',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                
                    IF pk_utils.search_table_number(i_task_type, g_task_type_medication) > 0
                    THEN
                        o_msg_body := o_msg_body || '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M042');
                    END IF;
                END IF;
            
                -- out of boundary
                o_flg_warning_type := g_flg_warning_out_of_bounds;
            
                pk_alertlog.log_debug('get o_task_list cursor for warning message (boundary status = O)',
                                      g_package_name);
                OPEN o_task_list FOR
                    SELECT /*+opt_estimate(table task_list rows=1)*/
                     pk_cpoe.get_task_group_id(i_prof, tt.id_task_type) AS group_type_id,
                     pk_cpoe.get_task_group_name(i_lang, i_prof, tt.id_task_type) AS task_group_desc,
                     pk_cpoe.get_task_group_rank(i_prof, tt.id_task_type) AS task_group_rank,
                     tt.id_task_type AS id_task_type,
                     tt.id_target_task_type AS id_target_task_type,
                     task_list.id_request AS id_task,
                     tt.icon,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
                     pk_date_utils.date_char_hour_tsz(i_lang,
                                                      l_ts_current_timestamp,
                                                      i_prof.institution,
                                                      i_prof.software) AS time_desc,
                     pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                           l_ts_current_timestamp,
                                                           i_prof.institution,
                                                           i_prof.software) AS date_desc,
                     task_list.flg_status AS flg_task_boundary_status
                      FROM TABLE(l_task_req_list) task_list
                      JOIN cpoe_task_type tt
                        ON tt.id_task_type = task_list.id_task_type
                     WHERE task_list.flg_status = g_task_bound_out
                     ORDER BY task_group_rank, tt.id_task_type;
            
            END IF;
        
        ELSE
            -- g_cfg_cpoe_mode_simple or the task type does not need an active prescription: no validation needed here
            pk_types.open_my_cursor(o_task_list);
            o_flg_warning_type := g_flg_warning_none; -- no warnings
        
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
                                              'CHECK_TASKS_CREATION',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
        
    END check_tasks_creation;

    FUNCTION get_cpoe_message
    (
        i_lang         IN language.id_language%TYPE,
        i_code_message IN sys_message.code_message%TYPE,
        i_param1       IN VARCHAR2,
        i_param2       IN VARCHAR2,
        i_param3       IN VARCHAR2,
        i_param4       IN VARCHAR2,
        i_param5       IN VARCHAR2,
        i_param6       IN VARCHAR2,
        i_param7       IN VARCHAR2,
        i_param8       IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pk_message.get_message(i_lang,
                                                                                                      i_code_message),
                                                                               '@1',
                                                                               i_param1),
                                                                       '@2',
                                                                       i_param2),
                                                               '@3',
                                                               i_param3),
                                                       '@4',
                                                       i_param4),
                                               '@5',
                                               i_param5),
                                       '@6',
                                       i_param6),
                               '@7',
                               i_param7),
                       '@8',
                       i_param8);
    END get_cpoe_message;

    /********************************************************************************************
    * checks within cpoe if the given tasks can be created or not (in draft activations)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_dt_start                tasks start timestamps
    * @param       i_dt_end                  tasks end timestamps
    * @param       i_draft_request           draft task ids
    * @param       i_flg_new_presc           flag that indicates if a new prescription is needed
    * @param       o_task_list               list of tasks, according to cpoe confirmation grid
    * @param       o_flg_warning_type        warning type flag
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body, according to warning type flag
    * @param       o_proc_start              cpoe process start timestamp (for new cpoe process)
    * @param       o_proc_end                cpoe process end timestamp (for new cpoe process)
    * @param       o_proc_refresh            cpoe refresh to draft prescription timestamp (for new cpoe process)
    * @param       o_error                   error message
    *
    * @value       i_flg_new_presc           {*} 'Y' drafts will be activated in a new prescription
    *                                        {*} 'N' drafts will be activated in current prescription
    *        
    * @value       o_flg_warning_type        {*} 'O' timestamps out of bounds
    *                                        {*} 'C' confirm cpoe creation
    *                                        {*} 'P' force the creation of a new prescription
    *                                        {*} 'B' block the creation of a new prescription
    *                                        {*} NULL proceed task creation, without warnings
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 10-Sep-2010
    ********************************************************************************************/

    /********************************************************************************************
    * checks the creation of a new active cpoe (plus button action)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       o_dt_proc_start           start timestamp of new cpoe prescription
    * @param       o_dt_proc_end             end timestamp of new cpoe prescription
    * @param       o_msg_title               message title for confirmation dialog box
    * @param       o_msg_body                message body for confirmation dialog box
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/21   
    ********************************************************************************************/
    FUNCTION check_cpoe_creation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_dt_proc_start OUT VARCHAR2,
        o_dt_proc_end   OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_body      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_flg_cpoe_mode   VARCHAR2(1 CHAR);
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        o_dt_next_presc cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
    
    BEGIN
        g_error := 'call get_cpoe_mode';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get cpoe mode to evaluate if the task should be created or not
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            g_error := 'call get_last_cpoe_info';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get last cpoe information to check if an active prescription exists
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'call get_next_cpoe_info';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get next cpoe creation period
            IF NOT get_next_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      NULL,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_ts_cpoe_refresh,
                                      o_dt_next_presc,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- "this prescription will be valid from @1 of @2 to @3 of @4" message
            o_msg_body := get_cpoe_message(i_lang         => i_lang,
                                           i_code_message => 'CPOE_M010',
                                           i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                              l_ts_cpoe_start,
                                                                                              i_prof.institution,
                                                                                              i_prof.software),
                                           i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                   l_ts_cpoe_start,
                                                                                                   i_prof.institution,
                                                                                                   i_prof.software),
                                           i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                              l_ts_cpoe_end,
                                                                                              i_prof.institution,
                                                                                              i_prof.software),
                                           i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                   l_ts_cpoe_end,
                                                                                                   i_prof.institution,
                                                                                                   i_prof.software));
        
            IF l_flg_cpoe_status <> g_flg_status_a
            THEN
                -- "do you wish to create a new prescription?" message
                o_msg_body := '<b>' || pk_message.get_message(i_lang, 'CPOE_M009') || '</b><br><br>' || o_msg_body;
            
            ELSE
                -- "an existing prescription already exists. do you wish to create a new prescription?" message
                o_msg_body := '<b>' || pk_message.get_message(i_lang, 'CPOE_M011') || '</b><br><br>' || o_msg_body;
            
            END IF;
        
            -- "prescription creation" message
            o_msg_title := pk_message.get_message(i_lang, 'CPOE_T015');
        
            -- new cpoe period output variables
            o_dt_proc_start := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            o_dt_proc_end   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_end, i_prof);
        
            g_error := 'check cpoe creation for i_episode=' || i_episode || ', from ' || o_dt_proc_start || ' to ' ||
                       o_dt_proc_end;
            pk_alertlog.log_debug(g_error, g_package_name);
        
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
                                              'CHECK_CPOE_CREATION',
                                              o_error);
            RETURN FALSE;
    END check_cpoe_creation;

    /********************************************************************************************
    * get tasks status based in process task requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_type            task type id
    * @param       i_task_request         array of requests that identifies the tasks
    * @param       o_task_status          cursor with all requested task status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_process_task.id_task_type%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        CASE
        -- monitorization
            WHEN i_task_type = g_task_type_monitorization THEN
                IF NOT pk_monitorization.get_task_status(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_episode      => i_episode,
                                                         i_task_request => i_task_request,
                                                         o_task_status  => o_task_status,
                                                         o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_monitorization.get_task_status function';
                    RAISE l_exception;
                END IF;
            
        -- positioning
            WHEN i_task_type = g_task_type_positioning THEN
                IF NOT pk_pbl_inp_positioning.get_task_status(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_episode      => i_episode,
                                                              i_task_request => i_task_request,
                                                              o_task_status  => o_task_status,
                                                              o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_pbl_inp_positioning.get_task_status function';
                    RAISE l_exception;
                END IF;
            
        -- hidric
            WHEN i_task_type = g_task_type_hidric_in_out
                 OR i_task_type = g_task_type_hidric_out
                 OR i_task_type = g_task_type_hidric_drain
                 OR i_task_type = g_task_type_hidric_in
                 OR i_task_type = g_task_type_hidric_out_all
                 OR i_task_type = g_task_type_hidric_irrigations THEN
                IF NOT pk_inp_hidrics_pbl.get_task_status(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_episode      => i_episode,
                                                          i_task_request => i_task_request,
                                                          o_task_status  => o_task_status,
                                                          o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_inp_hidrics_pbl.get_task_status function';
                    RAISE l_exception;
                END IF;
            
        -- diet
            WHEN i_task_type = g_task_type_diet_inst
                 OR i_task_type = g_task_type_diet_spec
                 OR i_task_type = g_task_type_diet_predefined THEN
                IF NOT pk_diet.get_task_status(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               i_task_request => i_task_request,
                                               o_task_status  => o_task_status,
                                               o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_diet.get_task_status function';
                    RAISE l_exception;
                END IF;
            
        -- procedure
            WHEN i_task_type = g_task_type_procedure THEN
                IF NOT pk_procedures_external_api_db.get_task_status(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_episode      => i_episode,
                                                                     i_task_request => i_task_request,
                                                                     o_task_status  => o_task_status,
                                                                     o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_procedures_external_api_db.get_task_status function';
                    RAISE l_exception;
                END IF;
            
            WHEN i_task_type = g_task_type_bp THEN
                IF NOT pk_bp_external_api_db.get_task_status(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_episode      => i_episode,
                                                             i_task_request => i_task_request,
                                                             o_task_status  => o_task_status,
                                                             o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_bp_external_api_db.get_task_status function';
                    RAISE l_exception;
                END IF;
                -- nurse teaching
            WHEN i_task_type = g_task_type_nursing THEN
                IF NOT pk_patient_education_cpoe.get_task_status(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_episode      => i_episode,
                                                                 i_task_request => i_task_request,
                                                                 o_task_status  => o_task_status,
                                                                 o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_patient_education_cpoe.get_task_status function';
                    RAISE l_exception;
                END IF;
            
        -- medication
            WHEN i_task_type = g_task_type_medication THEN
                IF NOT pk_api_pfh_ordertools_in.get_medication_task_status(i_lang         => i_lang,
                                                                           i_prof         => i_prof,
                                                                           i_id_episode   => i_episode,
                                                                           i_id_presc     => i_task_request,
                                                                           o_presc_status => o_task_status,
                                                                           o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_api_pfh_ordertools_in.get_medication_task_status function';
                    RAISE l_exception;
                END IF;
            
        -- communication order
            WHEN i_task_type = g_task_type_com_order THEN
                IF NOT pk_comm_orders_cpoe.get_task_status(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_episode      => i_episode,
                                                           i_task_request => i_task_request,
                                                           o_task_status  => o_task_status,
                                                           o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_comm_orders_cpoe.get_task_status function';
                    RAISE l_exception;
                END IF;
            
            ELSE
                o_task_status := NULL;
            
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
                                              'GET_TASK_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_task_status;

    /********************************************************************************************
    * refresh the draft prescription based in current active/expired prescription
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_cpoe_process            current cpoe process id
    * @param       i_auto_mode               indicates if this function is called by an automatic job
    * @param       o_draft_task_type         array of created draft task types
    * @param       o_draft_task_request      array of created draft task requests  
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @value       i_auto_mode               {*} 'Y' this function is being called by the system
    *                                        {*} 'N' this function is being called by the user
    *
    * @author                                Carlos Loureiro
    * @since                                 01-Set-2010   
    ********************************************************************************************/
    FUNCTION refresh_draft_prescription
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_cpoe_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_auto_mode          IN VARCHAR2,
        o_draft_task_type    OUT table_number,
        o_draft_task_request OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_del_draft          sys_config.value%TYPE;
        l_task_requests          table_number;
        l_task_status            pk_types.cursor_type;
        l_refresh_task_reqs      table_number;
        l_recpt                  t_rec_cpoe_task_req := t_rec_cpoe_task_req(NULL, NULL, NULL);
        l_tbl_cpoe_process_tasks t_tbl_cpoe_task_req := t_tbl_cpoe_task_req();
        l_tbl_index              NUMBER := 0;
        l_return                 BOOLEAN;
        l_ts_refresh             TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        -- get task types that can be refreshed to draft prescription
        CURSOR c_refreshable_types IS
            SELECT DISTINCT pt.id_task_type, pt.id_episode
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_cpoe_process
               AND EXISTS (SELECT 1
                      FROM cpoe_task_type_status_filter sf
                     WHERE sf.id_task_type = pt.id_task_type
                       AND sf.flg_cpoe_proc_refresh = pk_alert_constant.g_yes);
    
        -- refreshable tasks
        CURSOR c_refreshable_tasks
        (
            in_task_type    IN cpoe_process_task.id_task_type%TYPE,
            in_task_episode IN cpoe_process_task.id_episode%TYPE
        ) IS
            SELECT pt.id_task_request
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_cpoe_process
               AND pt.id_task_type = in_task_type
               AND pt.id_episode = in_task_episode;
    
        -- set of refreshable task requests for "copy2draft" action process
        CURSOR c_refresh_proc_tasks IS
            SELECT id_task_type, id_request
              FROM (SELECT id_task_type, id_request, get_task_status_refresh(id_task_type, flg_status) AS flg_refresh
                      FROM TABLE(CAST(l_tbl_cpoe_process_tasks AS t_tbl_cpoe_task_req)) task)
             WHERE flg_refresh = pk_alert_constant.g_yes;
    
        l_exception EXCEPTION;
    
    BEGIN
        -- check if existing drafts should be removed before refreshing draft prescription
        IF NOT get_delete_on_refresh(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_auto_mode => i_auto_mode,
                                     o_flg_del   => l_flg_del_draft,
                                     o_error     => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_delete_on_refresh function';
            RAISE l_exception;
        END IF;
    
        -- draft tasks removal before prescription refresh (only if configuration allows it)
        IF l_flg_del_draft = pk_alert_constant.g_yes
        THEN
            IF i_auto_mode = pk_alert_constant.g_yes
            THEN
                -- delete all drafts with autonomous transactions
                delete_all_drafts_auto_trans(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
            ELSE
                -- delete all drafts without autonomous transactions
                IF NOT delete_all_drafts(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, o_error => o_error)
                THEN
                    g_error := 'error found while calling pk_cpoe.delete_all_drafts function';
                    RAISE l_exception;
                END IF;
            END IF;
        END IF;
    
        -- copy 2 draft all eligible tasks from one given cpoe process (only expirable tasks are processed)
        FOR rec_type IN c_refreshable_types
        LOOP
            -- get all task requests for a given task type and episode
            OPEN c_refreshable_tasks(rec_type.id_task_type, rec_type.id_episode);
            FETCH c_refreshable_tasks BULK COLLECT
                INTO l_task_requests;
            CLOSE c_refreshable_tasks;
        
            -- get task status
            IF NOT get_task_status(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => rec_type.id_episode,
                                   i_task_type    => rec_type.id_task_type,
                                   i_task_request => l_task_requests,
                                   o_task_status  => l_task_status,
                                   o_error        => o_error)
            THEN
                g_error := 'error found while calling pk_cpoe.get_task_status function';
                RAISE l_exception;
            END IF;
        
            -- open l_task_status; (cursor l_task_status is already open)
            LOOP
                IF l_task_status IS NOT NULL
                THEN
                    FETCH l_task_status
                        INTO l_recpt.id_task_type, l_recpt.id_request, l_recpt.flg_status;
                    EXIT WHEN l_task_status%NOTFOUND;
                ELSE
                    EXIT;
                END IF;
            
                -- update cpoe task type based on target task type returned from get_task_status function
                l_recpt.id_task_type := get_task_type_match(rec_type.id_task_type, l_recpt.id_task_type);
            
                -- extend and associates the new record into l_tbl_cpoe_process_tasks            
                l_tbl_cpoe_process_tasks.extend;
                l_tbl_index := l_tbl_index + 1;
                l_tbl_cpoe_process_tasks(l_tbl_index) := l_recpt;
            END LOOP;
        
        END LOOP;
    
        -- get all task types/requests to be refreshed
        OPEN c_refresh_proc_tasks;
        FETCH c_refresh_proc_tasks BULK COLLECT
            INTO o_draft_task_type, l_refresh_task_reqs;
        CLOSE c_refresh_proc_tasks;
    
        IF l_refresh_task_reqs.count > 0
        THEN
            IF i_auto_mode = pk_alert_constant.g_yes
            THEN
                -- refresh draft prescription with processed task types/requests with autonomous transactions
                copy_to_draft(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_episode          => i_episode,
                              i_task_type        => o_draft_task_type,
                              i_task_request     => l_refresh_task_reqs,
                              i_auto_trans       => pk_alert_constant.g_yes,
                              i_dt_draft_start   => NULL,
                              i_dt_draft_end     => NULL,
                              o_new_task_request => o_draft_task_request);
            ELSE
                -- refresh draft prescription with processed task types/requests
                copy_to_draft(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_episode          => i_episode,
                              i_task_type        => o_draft_task_type,
                              i_task_request     => l_refresh_task_reqs,
                              i_auto_trans       => pk_alert_constant.g_no,
                              o_new_task_request => o_draft_task_request);
            
            END IF;
        
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_cpoe_process,
                                      o_dt_start        => l_ts_cpoe_start,
                                      o_dt_end          => l_ts_cpoe_end,
                                      o_flg_status      => l_flg_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_cpoe_process => l_cpoe_process,
                                         i_tasks_orig   => l_refresh_task_reqs,
                                         i_tasks_dest   => o_draft_task_request,
                                         i_tasks_type   => o_draft_task_type,
                                         i_flg_type     => 'AD',
                                         o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSE
            o_draft_task_type    := table_number();
            o_draft_task_request := table_number();
        END IF;
    
        -- update cpoe process refresh status
        g_error := 'update cpoe process with refresh info';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE cpoe_process cp
           SET cp.dt_last_update             = l_ts_refresh,
               cp.dt_cpoe_refreshed          = l_ts_refresh,
               cp.flg_cpoe_proc_auto_refresh = decode(cp.flg_cpoe_proc_auto_refresh,
                                                      g_flg_rfs_status_no_refresh,
                                                      g_flg_rfs_status_refreshed,
                                                      g_flg_rfs_status_refresh,
                                                      decode(i_auto_mode,
                                                             pk_alert_constant.g_yes,
                                                             g_flg_rfs_status_refreshed,
                                                             cp.flg_cpoe_proc_auto_refresh),
                                                      cp.flg_cpoe_proc_auto_refresh)
         WHERE cp.id_cpoe_process = i_cpoe_process;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REFRESH_DRAFT_PRESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END refresh_draft_prescription;

    /********************************************************************************************
    * refresh the draft prescription based in current active/expired prescription
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_cpoe_process            current cpoe process id
    * @param       o_draft_task_type         array of created draft task types
    * @param       o_draft_task_request      array of created draft task requests  
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 01-Set-2010   
    ********************************************************************************************/
    FUNCTION refresh_draft_prescription
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_cpoe_process       IN cpoe_process.id_cpoe_process%TYPE,
        o_draft_task_type    OUT table_number,
        o_draft_task_request OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call draft refresh function
        IF NOT refresh_draft_prescription(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_episode            => i_episode,
                                          i_cpoe_process       => i_cpoe_process,
                                          i_auto_mode          => pk_alert_constant.g_no,
                                          o_draft_task_type    => o_draft_task_type,
                                          o_draft_task_request => o_draft_task_request,
                                          o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- commit the changes
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
                                              'REFRESH_DRAFT_PRESCRIPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END refresh_draft_prescription;

    /********************************************************************************************
    * expire a requested task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               type of the task
    * @param       i_task_request            task requisition id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false 
    *
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 2009/11/23
    ********************************************************************************************/
    FUNCTION expire_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_process_task.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_status VARCHAR2(1000);
        l_count  NUMBER;
    BEGIN
    
        --Se uma tarefa do CPOE é para continuar , então não podemos expirar
        SELECT COUNT(*)
          INTO l_count
          FROM cpoe_tasks_relation a
         WHERE a.id_task_orig = i_task_request
           AND a.id_task_type = i_task_type
           AND a.flg_type = 'REP';
        IF l_count > 0
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'set cpoe task as expired: i_task_type=' || to_char(i_task_type) || ', i_task_request' ||
                   i_task_request || ', i_episode=' || i_episode;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE
        -- monitorization
            WHEN i_task_type = g_task_type_monitorization THEN
                IF NOT pk_monitorization.expire_task(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_task_request => table_number(i_task_request),
                                                     o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- positioning
            WHEN i_task_type = g_task_type_positioning THEN
                IF NOT pk_pbl_inp_positioning.expire_task(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_episode       => i_episode,
                                                          i_task_requests => table_number(i_task_request),
                                                          o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- hidric
            WHEN i_task_type = g_task_type_hidric_in_out
                 OR i_task_type = g_task_type_hidric_out
                 OR i_task_type = g_task_type_hidric_drain
                 OR i_task_type = g_task_type_hidric_in
                 OR i_task_type = g_task_type_hidric_out_all
                 OR i_task_type = g_task_type_hidric_irrigations THEN
                IF NOT pk_inp_hidrics_pbl.expire_task(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_episode       => i_episode,
                                                      i_task_requests => table_number(i_task_request),
                                                      o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- diet
            WHEN i_task_type = g_task_type_diet_inst
                 OR i_task_type = g_task_type_diet_spec
                 OR i_task_type = g_task_type_diet_predefined THEN
                IF NOT pk_diet.expire_task(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_episode      => i_episode,
                                           i_task_request => i_task_request,
                                           o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                SELECT r.flg_status
                  INTO l_status
                  FROM epis_diet_req r
                 WHERE r.id_epis_diet_req = i_task_request;
            
        -- procedure
            WHEN i_task_type = g_task_type_procedure THEN
                IF NOT pk_procedures_external_api_db.expire_task(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_episode       => i_episode,
                                                                 i_task_requests => table_number(i_task_request),
                                                                 o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                SELECT r.flg_status
                  INTO l_status
                  FROM interv_presc_det r
                 WHERE r.id_interv_presc_det = i_task_request;
            
            WHEN i_task_type = g_task_type_bp THEN
                IF NOT pk_bp_external_api_db.expire_task(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_episode       => i_episode,
                                                         i_task_requests => table_number(i_task_request),
                                                         o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                SELECT r.flg_status
                  INTO l_status
                  FROM interv_presc_det r
                 WHERE r.id_interv_presc_det = i_task_request;
                -- nurse teaching
            WHEN i_task_type = g_task_type_nursing THEN
                IF NOT pk_patient_education_cpoe.expire_task(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_episode       => i_episode,
                                                             i_task_requests => table_number(i_task_request),
                                                             o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- medication
            WHEN i_task_type = g_task_type_medication THEN
                IF NOT pk_api_pfh_ordertools_in.expire_medication_tasks(i_lang => i_lang,
                                                                        i_prof => i_prof,
                                                                        -- i_id_patient can be null in this api
                                                                        i_id_episode => i_episode,
                                                                        i_id_presc   => table_number(i_task_request),
                                                                        o_error      => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- communication order
            WHEN i_task_type IN (g_task_type_com_order, g_task_type_medical_orders) THEN
                IF NOT pk_comm_orders_cpoe.expire_task(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_episode       => i_episode,
                                                       i_task_requests => table_number(i_task_request),
                                                       o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSE
                NULL;
            
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
                                              'EXPIRE_TASK',
                                              o_error);
            RETURN FALSE;
    END expire_task;

    /********************************************************************************************
    * expire a requested task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_cpoe_process            cpoe process id
    * @param       i_commit_each_task        commit flag that controls transactions between successful task expirations
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false 
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/05
    ********************************************************************************************/
    FUNCTION expire_cpoe_tasks
    (
        i_lang             IN language.id_language%TYPE,
        i_cpoe_process     IN cpoe_process_task.id_cpoe_process%TYPE,
        i_commit_each_task IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        -- cursor with all tasks from given cpoe process
        CURSOR c_tasks IS
            SELECT pt.id_task_type,
                   pt.id_task_request,
                   pt.id_episode,
                   pt.id_professional,
                   pt.id_institution,
                   pt.id_software
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_cpoe_process
               AND check_task_cpoe_expire(profissional(pt.id_professional, pt.id_institution, pt.id_software),
                                          pt.id_task_type) = pk_alert_constant.g_yes;
    
        -- internal procedure to enable autonomous transactions
        PROCEDURE expire_task_with_auto_trans
        (
            in_lang         IN language.id_language%TYPE,
            in_prof         IN profissional,
            in_episode      IN episode.id_episode%TYPE,
            in_task_type    IN cpoe_process_task.id_task_type%TYPE,
            in_task_request IN cpoe_process_task.id_task_request%TYPE
        ) IS
        
            l_error t_error_out;
        
            PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
            IF NOT expire_task(in_lang, in_prof, in_episode, in_task_type, in_task_request, l_error)
            THEN
                pk_utils.undo_changes;
            ELSE
                COMMIT;
            END IF;
        END;
    
    BEGIN
        g_error := 'expire cpoe process tasks';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop all tasks from cpoe process    
        FOR rec IN c_tasks
        LOOP
            -- expire task
            IF i_commit_each_task = pk_alert_constant.g_yes
            THEN
                expire_task_with_auto_trans(i_lang,
                                            profissional(rec.id_professional, rec.id_institution, rec.id_software),
                                            rec.id_episode,
                                            rec.id_task_type,
                                            rec.id_task_request);
            ELSE
                IF NOT expire_task(i_lang,
                                   profissional(rec.id_professional, rec.id_institution, rec.id_software),
                                   rec.id_episode,
                                   rec.id_task_type,
                                   rec.id_task_request,
                                   o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
            IF NOT delete_from_rel_tasks(i_lang       => i_lang,
                                         i_prof       => profissional(rec.id_professional,
                                                                      rec.id_institution,
                                                                      rec.id_software),
                                         i_tasks      => table_number(rec.id_task_request),
                                         i_tasks_type => table_number(rec.id_task_type),
                                         o_error      => o_error)
            
            THEN
                RAISE l_exception;
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
                                              'EXPIRE_CPOE_TASKS',
                                              o_error);
        
            RETURN FALSE;
        
    END expire_cpoe_tasks;

    /********************************************************************************************
    * discontinues or interrupts an active cpoe (internal function) 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_cpoe_process            active cpoe to discontinue
    * @param       i_ts_cpoe_int             last update timestamp
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/22
    ********************************************************************************************/
    FUNCTION interrupt_cpoe
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_cpoe_process IN cpoe_process.id_cpoe_process%TYPE,
        i_ts_cpoe_int  IN cpoe_process.dt_last_update%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_new_cpoe_process_hist cpoe_process_hist.id_cpoe_process_hist%TYPE;
        l_episode               episode.id_episode%TYPE;
        l_id_dep_clin_serv      dep_clin_serv.id_dep_clin_serv%TYPE;
    
    BEGIN
        g_error := 'interrupt current cpoe process';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- interrupt cpoe process
        UPDATE cpoe_process p
           SET p.flg_status                 = g_flg_status_i,
               p.dt_last_update             = i_ts_cpoe_int,
               p.dt_cpoe_proc_end           = i_ts_cpoe_int,
               p.dt_cpoe_expired            = i_ts_cpoe_int,
               p.flg_cpoe_proc_auto_refresh = decode(p.flg_cpoe_proc_auto_refresh,
                                                     g_flg_rfs_status_refresh,
                                                     g_flg_rfs_status_interrupted,
                                                     p.flg_cpoe_proc_auto_refresh)
         WHERE p.id_cpoe_process = i_cpoe_process
        RETURNING p.id_episode, p.id_dep_clin_serv INTO l_episode, l_id_dep_clin_serv;
    
        g_error := 'update cpoe process history';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get new sequence for seq_cpoe_process_hist
        SELECT seq_cpoe_process_hist.nextval
          INTO l_new_cpoe_process_hist
          FROM dual;
    
        -- insert new history record in cpoe_process_hist
        INSERT INTO cpoe_process_hist
            (id_cpoe_process_hist,
             id_cpoe_process,
             id_cpoe_process_prev,
             flg_status,
             id_episode,
             id_professional,
             id_institution,
             id_software,
             dt_proc_history,
             id_dep_clin_serv)
        VALUES
            (l_new_cpoe_process_hist,
             i_cpoe_process,
             i_cpoe_process,
             g_flg_status_i,
             l_episode,
             i_prof.id,
             i_prof.institution,
             i_prof.software,
             i_ts_cpoe_int,
             l_id_dep_clin_serv);
    
        -- expire interrupted process tasks
        IF NOT expire_cpoe_tasks(i_lang, i_cpoe_process, pk_alert_constant.g_no, o_error)
        THEN
            RAISE l_exception;
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
                                              'INTERRUPT_CPOE',
                                              o_error);
            RETURN FALSE;
        
    END interrupt_cpoe;

    /********************************************************************************************
    * copy running and non expirable tasks from previous prescription to new one
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_old_proc                old cpoe process to copy tasks "from"
    * @param       i_new_proc                new cpoe process to copy tasks "to"
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 13-Sep-2010  
    ********************************************************************************************/

    FUNCTION update_new_process
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_old_proc IN cpoe_process.id_cpoe_process%TYPE,
        i_new_proc IN cpoe_process.id_cpoe_process%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_copy_active_new_pres sys_config.value%TYPE;
        l_task_requests            table_number;
        l_task_status              pk_types.cursor_type;
        l_recpt                    t_rec_cpoe_task_req := t_rec_cpoe_task_req(NULL, NULL, NULL);
        l_tbl_cpoe_process_tasks   t_tbl_cpoe_task_req := t_tbl_cpoe_task_req();
        l_tbl_index                NUMBER := 0;
        l_task_type                table_number;
        l_task_req                 table_number;
        --l_task_epis table_number;
    
        -- get task types that can be copied to new prescription
        CURSOR c_new_presc_types IS
            SELECT DISTINCT pt.id_task_type, pt.id_episode
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_old_proc
               AND EXISTS (SELECT 1
                      FROM cpoe_task_type_status_filter sf
                     WHERE sf.id_task_type = pt.id_task_type
                       AND sf.flg_cpoe_proc_new = pk_alert_constant.g_yes);
    
        -- cursor with all tasks belonging to old cpoe process that can be considered in new prescription
        CURSOR c_old_cpoe_tasks
        (
            in_task_type    IN cpoe_process_task.id_task_type%TYPE,
            in_task_episode IN cpoe_process_task.id_episode%TYPE
        ) IS
            SELECT pt.id_task_request
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_old_proc
               AND pt.id_task_type = in_task_type
               AND pt.id_episode = in_task_episode;
    
        -- set of task requests of old cpoe process that will be considered in new prescription
        CURSOR c_new_proc_tasks IS
            SELECT id_task_type, id_request
              FROM (SELECT id_task_type,
                           id_request,
                           get_task_status_new_presc(id_task_type, flg_status) AS flg_new_presc
                      FROM TABLE(CAST(l_tbl_cpoe_process_tasks AS t_tbl_cpoe_task_req)) task) pt
             WHERE pt.flg_new_presc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM cpoe_task_type_status_filter sf
                     WHERE sf.id_task_type = pt.id_task_type
                       AND sf.flg_cpoe_proc_refresh = pk_alert_constant.g_no);
    
        l_exception EXCEPTION;
    
    BEGIN
        -- check if existing drafts should be removed before refreshing draft prescription
        IF NOT get_cfg_copy_active_new_presc(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             o_flg_copy_to_new_presc => l_flg_copy_active_new_pres,
                                             o_error                 => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cfg_copy_active_new_presc function';
            RAISE l_exception;
        END IF;
    
        -- only perform this function's main objective is configuration allows it
        IF l_flg_copy_active_new_pres = pk_alert_constant.g_yes
        THEN
            -- for all tasks belonging to old cpoe process, check if it can be considered in new cpoe process (by its status)
            FOR rec_type IN c_new_presc_types
            LOOP
                -- get all task requests for a given task type and episode
                OPEN c_old_cpoe_tasks(rec_type.id_task_type, rec_type.id_episode);
                FETCH c_old_cpoe_tasks BULK COLLECT
                    INTO l_task_requests;
                CLOSE c_old_cpoe_tasks;
            
                -- get task status
                IF NOT get_task_status(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => rec_type.id_episode,
                                       i_task_type    => rec_type.id_task_type,
                                       i_task_request => l_task_requests,
                                       o_task_status  => l_task_status,
                                       o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_cpoe.get_task_status function';
                    RAISE l_exception;
                END IF;
            
                -- open l_task_status; (cursor l_task_status is already open)
                LOOP
                    IF l_task_status IS NOT NULL
                    THEN
                        FETCH l_task_status
                            INTO l_recpt.id_task_type, l_recpt.id_request, l_recpt.flg_status;
                        EXIT WHEN l_task_status%NOTFOUND;
                    ELSE
                        EXIT;
                    END IF;
                
                    -- update cpoe task type based on target task type returned from get_task_status function
                    l_recpt.id_task_type := get_task_type_match(rec_type.id_task_type, l_recpt.id_task_type);
                
                    -- extend and associates the new record into l_tbl_cpoe_process_tasks            
                    l_tbl_cpoe_process_tasks.extend;
                    l_tbl_index := l_tbl_index + 1;
                    l_tbl_cpoe_process_tasks(l_tbl_index) := l_recpt;
                
                END LOOP;
            
            END LOOP;
        
            -- get all task types/requests to be refreshed
            OPEN c_new_proc_tasks;
            FETCH c_new_proc_tasks BULK COLLECT
                INTO l_task_type, l_task_req;
            CLOSE c_new_proc_tasks;
        
            -- associate tasks to the new cpoe process
            FORALL i IN l_task_req.first .. l_task_req.last
                INSERT INTO cpoe_process_task
                    (id_cpoe_process,
                     id_task_type,
                     id_task_request,
                     dt_proc_task_create,
                     id_professional,
                     id_institution,
                     id_software,
                     id_episode)
                    SELECT i_new_proc,
                           l_task_type(i),
                           l_task_req(i),
                           dt_proc_task_create,
                           id_professional,
                           id_institution,
                           id_software,
                           id_episode
                      FROM cpoe_process_task pt
                     WHERE pt.id_cpoe_process = i_old_proc
                       AND pt.id_task_type = l_task_type(i)
                       AND pt.id_task_request = l_task_req(i);
        
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
                                              'UPDATE_NEW_PROCESS',
                                              o_error);
            RETURN FALSE;
    END update_new_process;

    PROCEDURE expire_cpoe
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_cpoe_process  IN cpoe_process.id_cpoe_process%TYPE,
        o_flg_next_proc OUT VARCHAR2
    ) IS
        l_ts_cpoe_exp           TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_new_cpoe_process_hist cpoe_process_hist.id_cpoe_process_hist%TYPE;
    
        l_next_cpoe_process cpoe_process.id_cpoe_process%TYPE;
        l_dt_start          cpoe_process.dt_cpoe_proc_start%TYPE;
        l_dt_end            cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_error t_error_out;
    
        l_exception EXCEPTION;
        l_task_status   pk_types.cursor_type;
        l_recpt         t_rec_cpoe_task_req := t_rec_cpoe_task_req(NULL, NULL, NULL);
        flg_status_task VARCHAR2(10 CHAR);
        status_canceled BOOLEAN;
    
        CURSOR c_tasks(id_next_cpoe_process cpoe_process.id_cpoe_process%TYPE) IS
            SELECT pt.id_task_type,
                   pt.id_task_request,
                   pt.id_episode,
                   pt.id_professional,
                   pt.id_institution,
                   pt.id_software
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = id_next_cpoe_process;
    
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.expire_cpoe called with:' || chr(10) || 'i_lang=' || i_lang || chr(10) ||
                                  'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode || chr(10) ||
                                  'i_cpoe_process=' || i_cpoe_process,
                                  g_package_name);
        END IF;
    
        g_error := 'expire cpoe process';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- expire cpoe process
        UPDATE cpoe_process cp
           SET cp.flg_status = g_flg_status_e, cp.dt_cpoe_expired = l_ts_cpoe_exp, cp.dt_last_update = l_ts_cpoe_exp
         WHERE cp.id_cpoe_process = i_cpoe_process;
    
        g_error := 'update cpoe process history';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get new sequence for seq_cpoe_process_hist
        SELECT seq_cpoe_process_hist.nextval
          INTO l_new_cpoe_process_hist
          FROM dual;
    
        -- insert new history record in cpoe_process_hist
        INSERT INTO cpoe_process_hist
            (id_cpoe_process_hist,
             id_cpoe_process,
             id_cpoe_process_prev,
             flg_status,
             id_episode,
             id_professional,
             id_institution,
             id_software,
             dt_proc_history)
        VALUES
            (l_new_cpoe_process_hist,
             i_cpoe_process,
             i_cpoe_process,
             g_flg_status_e,
             i_episode,
             i_prof.id,
             i_prof.institution,
             i_prof.software,
             l_ts_cpoe_exp);
    
        -- check if the next prescription exists 
        get_next_presc_process(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_episode      => i_episode,
                               o_cpoe_process => l_next_cpoe_process,
                               o_dt_start     => l_dt_start,
                               o_dt_end       => l_dt_end);
    
        IF l_next_cpoe_process IS NOT NULL
        THEN
            g_error := 'activate next cpoe process';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- activate next cpoe process
            UPDATE cpoe_process cp
               SET cp.flg_status = g_flg_status_a, cp.dt_last_update = l_ts_cpoe_exp
             WHERE cp.id_cpoe_process = l_next_cpoe_process;
        
            FOR rec IN c_tasks(l_next_cpoe_process)
            LOOP
            
                IF NOT get_task_status(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => rec.id_episode,
                                       i_task_type    => rec.id_task_type,
                                       i_task_request => table_number(rec.id_task_request),
                                       o_task_status  => l_task_status,
                                       o_error        => l_error)
                THEN
                    g_error := 'error found while calling pk_cpoe.get_task_status function';
                    RAISE l_exception;
                END IF;
            
                LOOP
                    IF l_task_status IS NOT NULL
                    THEN
                        FETCH l_task_status
                            INTO l_recpt.id_task_type, l_recpt.id_request, l_recpt.flg_status;
                        EXIT WHEN l_task_status%NOTFOUND;
                    ELSE
                        EXIT;
                    END IF;
                
                    BEGIN
                        SELECT flg_status
                          INTO flg_status_task
                          FROM cpoe_task_type_status_filter
                         WHERE status_internal_code IN ('CANCELLED')
                           AND id_task_type = rec.id_task_type;
                    EXCEPTION
                        WHEN no_data_found THEN
                            flg_status_task := NULL;
                    END;
                
                    IF flg_status_task = l_recpt.flg_status
                    THEN
                        DELETE FROM cpoe_process_task
                         WHERE id_cpoe_process = l_next_cpoe_process
                           AND id_task_request = rec.id_task_request;
                    END IF;
                
                    BEGIN
                        SELECT flg_status
                          INTO flg_status_task
                          FROM cpoe_task_type_status_filter
                         WHERE status_internal_code IN ('SUSPENDED')
                           AND id_task_type = rec.id_task_type;
                    EXCEPTION
                        WHEN no_data_found THEN
                            flg_status_task := NULL;
                    END;
                
                    IF flg_status_task = l_recpt.flg_status
                    THEN
                        DELETE FROM cpoe_process_task
                         WHERE id_cpoe_process = l_next_cpoe_process
                           AND id_task_request = rec.id_task_request;
                    END IF;
                
                    BEGIN
                        SELECT flg_status
                          INTO flg_status_task
                          FROM cpoe_task_type_status_filter
                         WHERE status_internal_code IN ('DISCONTINUED')
                           AND id_task_type = rec.id_task_type;
                    EXCEPTION
                        WHEN no_data_found THEN
                            flg_status_task := NULL;
                    END;
                
                    IF flg_status_task = l_recpt.flg_status
                    THEN
                        DELETE FROM cpoe_process_task
                         WHERE id_cpoe_process = l_next_cpoe_process
                           AND id_task_request = rec.id_task_request;
                    END IF;
                
                END LOOP;
            
            END LOOP;
        
            g_error := 'update next cpoe process history';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get new sequence for seq_cpoe_process_hist
            SELECT seq_cpoe_process_hist.nextval
              INTO l_new_cpoe_process_hist
              FROM dual;
        
            -- insert new history record in cpoe_process_hist
            INSERT INTO cpoe_process_hist
                (id_cpoe_process_hist,
                 id_cpoe_process,
                 id_cpoe_process_prev,
                 flg_status,
                 id_episode,
                 id_professional,
                 id_institution,
                 id_software,
                 dt_proc_history)
            VALUES
                (l_new_cpoe_process_hist,
                 l_next_cpoe_process,
                 l_next_cpoe_process,
                 g_flg_status_a,
                 i_episode,
                 i_prof.id,
                 i_prof.institution,
                 i_prof.software,
                 l_ts_cpoe_exp);
        
            -- copy running and non expirable tasks from previous prescription to new one
            IF NOT update_new_process(i_lang     => i_lang,
                                      i_prof     => i_prof,
                                      i_episode  => i_episode,
                                      i_old_proc => i_cpoe_process, -- previous cpoe process
                                      i_new_proc => l_next_cpoe_process,
                                      o_error    => l_error) -- next cpoe process                
            THEN
                RAISE l_exception;
            END IF;
        
            -- next prescription exist
            o_flg_next_proc := pk_alert_constant.g_yes;
        ELSE
            -- next prescription doesn't exist
            o_flg_next_proc := pk_alert_constant.g_no;
        END IF;
    
    END expire_cpoe;

    /********************************************************************************************
    * set a CPOE process as expired
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_cpoe_process            cpoe process id
    * @param       o_error                   date end of next prescription
    *
    * @return      boolean                   true on success, otherwise false 
    *
    * @author                                Filipe Machado
    * @since                                 2009/11/23
    ********************************************************************************************/

    /********************************************************************************************
    * create active cpoe 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_proc_start              new cpoe process start timestamp
    * @param       i_proc_end                new cpoe process end timestamp
    * @param       i_proc_refresh            new cpoe refresh to draft prescription timestamp
    * @param       o_cpoe_process            created cpoe process id
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 10-Sep-2010   
    *
    * Added new column to CPOE_PROCESS, id_dep_clin_serv
    * @author                                Joao Reis
    * @since                                 21-Sep-2011
    ********************************************************************************************/
    FUNCTION create_cpoe
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_proc_start        IN VARCHAR2,
        i_proc_end          IN VARCHAR2,
        i_proc_refresh      IN VARCHAR2,
        i_proc_next_start   IN VARCHAR2,
        i_proc_next_end     IN VARCHAR2,
        i_proc_next_refresh IN VARCHAR2,
        i_proc_type         IN VARCHAR2,
        o_cpoe_process      OUT cpoe_process.id_cpoe_process%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_cpoe_mode        VARCHAR2(1 CHAR);
        l_flg_prev_cpoe_status VARCHAR2(1 CHAR);
        l_prev_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_prev_cpoe_start      cpoe_process.dt_cpoe_proc_start%TYPE;
        l_prev_cpoe_end        cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional      professional.id_professional%TYPE;
        l_exception EXCEPTION;
        l_new_cpoe_process_hist cpoe_process_hist.id_cpoe_process_hist%TYPE;
    
        PROCEDURE create_cpoe_internal
        (
            i_cpoe_proc_start   IN VARCHAR2,
            i_cpoe_proc_end     IN VARCHAR2,
            i_cpoe_proc_refresh IN VARCHAR2,
            i_cpoe_proc_status  IN VARCHAR2,
            i_prev_cpoe_proc    IN cpoe_process.id_cpoe_process%TYPE,
            o_new_cpoe_process  OUT cpoe_process.id_cpoe_process%TYPE
        ) IS
            l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
            l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
            l_ts_cpoe_refresh cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        
        BEGIN
            -- use i_proc_start and i_proc_end for new cpoe period start
            l_ts_cpoe_start   := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_string_tstz(i_lang,
                                                                                                i_prof,
                                                                                                
                                                                                                i_cpoe_proc_start,
                                                                                                
                                                                                                NULL),
                                                                  'MI');
            l_ts_cpoe_end     := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_string_tstz(i_lang,
                                                                                                i_prof,
                                                                                                i_cpoe_proc_end,
                                                                                                NULL),
                                                                  'MI');
            l_ts_cpoe_refresh := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_string_tstz(i_lang,
                                                                                                i_prof,
                                                                                                i_cpoe_proc_refresh,
                                                                                                NULL),
                                                                  'MI');
        
            -- check if refresh period is not in cpoe process valid period
            IF pk_date_utils.compare_dates_tsz(i_prof, l_ts_cpoe_refresh, l_ts_cpoe_start) IN
               (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_lower)
            THEN
                l_ts_cpoe_refresh := NULL; -- don't refresh cpoe process
            END IF;
        
            IF l_ts_cpoe_start IS NOT NULL
            THEN
                -- get new sequence for cpoe_process
                SELECT seq_cpoe_process.nextval
                  INTO o_new_cpoe_process -- new cpoe process id is stored in o_cpoe_process
                  FROM dual;
            
                -- insert new record in cpoe_process
                INSERT INTO cpoe_process
                    (id_cpoe_process,
                     dt_cpoe_proc_start,
                     dt_cpoe_proc_end,
                     flg_status,
                     id_episode,
                     id_professional,
                     id_institution,
                     id_software,
                     dt_last_update,
                     flg_cpoe_proc_auto_refresh,
                     dt_cpoe_proc_auto_refresh)
                VALUES
                    (o_new_cpoe_process,
                     l_ts_cpoe_start,
                     l_ts_cpoe_end,
                     i_cpoe_proc_status,
                     i_episode,
                     i_prof.id,
                     i_prof.institution,
                     i_prof.software,
                     current_timestamp,
                     decode(l_ts_cpoe_refresh, NULL, g_flg_rfs_status_no_refresh, g_flg_rfs_status_refresh),
                     l_ts_cpoe_refresh);
                -- refresh to draft prescription is only considered if refresh date is not null
            
                -- get new sequence for seq_cpoe_process_hist
                SELECT seq_cpoe_process_hist.nextval
                  INTO l_new_cpoe_process_hist
                  FROM dual;
            
                -- insert new history record in cpoe_process
                INSERT INTO cpoe_process_hist
                    (id_cpoe_process_hist,
                     id_cpoe_process,
                     id_cpoe_process_prev,
                     flg_status,
                     id_episode,
                     id_professional,
                     id_institution,
                     id_software,
                     dt_proc_history)
                VALUES
                    (l_new_cpoe_process_hist,
                     o_new_cpoe_process, -- new cpoe process
                     i_prev_cpoe_proc, -- previous cpoe process
                     i_cpoe_proc_status,
                     i_episode,
                     i_prof.id,
                     i_prof.institution,
                     i_prof.software,
                     current_timestamp);
            
                -- NOT NEEDED ANYMORE: expired cpoe process alerts can only be cleared in alerts area
                ---- delete expired process alert
                IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_sys_alert => g_sys_alert_expired_cpoe,
                                                        i_id_record    => l_prev_cpoe_process,
                                                        o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- copy running and non expirable tasks from previous prescription to new one
                IF (i_prev_cpoe_proc IS NOT NULL)
                THEN
                    IF NOT update_new_process(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_old_proc => i_prev_cpoe_proc,
                                              i_new_proc => o_new_cpoe_process,
                                              o_error    => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                IF NOT
                    upd_into_rel_tasks(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, o_error => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
        END create_cpoe_internal;
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.create_cpoe called with:' || chr(10) || 'i_lang=' || i_lang || chr(10) ||
                                  'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode || chr(10) ||
                                  'i_proc_start=' || i_proc_start || chr(10) || 'i_proc_end=' || i_proc_end || chr(10) ||
                                  'i_proc_refresh=' || i_proc_refresh || chr(10) || 'i_proc_next_start=' ||
                                  i_proc_next_start || chr(10) || 'i_proc_next_end=' || i_proc_next_end || chr(10) ||
                                  'i_proc_next_refresh=' || i_proc_next_refresh || chr(10) || 'i_proc_type=' ||
                                  i_proc_type,
                                  g_package_name);
        END IF;
    
        -- get cpoe mode to evaluate if the system can create cpoe processes
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
        
            -- get last cpoe information to process history record changes
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_prev_cpoe_process,
                                      o_dt_start        => l_prev_cpoe_start,
                                      o_dt_end          => l_prev_cpoe_end,
                                      o_flg_status      => l_flg_prev_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF i_proc_type IN (g_flg_warning_no_cpoe, g_flg_warning_new_cpoe)
            THEN
            
                -- create new CPOE
                create_cpoe_internal(i_cpoe_proc_start   => i_proc_start,
                                     i_cpoe_proc_end     => i_proc_end,
                                     i_cpoe_proc_refresh => i_proc_refresh,
                                     i_cpoe_proc_status  => g_flg_status_a,
                                     i_prev_cpoe_proc    => l_prev_cpoe_process,
                                     o_new_cpoe_process  => o_cpoe_process);
            
                -- new cpoe created
                COMMIT;
            ELSIF i_proc_type IN (g_flg_warning_new_next_cpoe)
            THEN
            
                -- if last cpoe is not active
                IF l_flg_prev_cpoe_status <> g_flg_status_a
                THEN
                
                    -- create new CPOE
                    create_cpoe_internal(i_cpoe_proc_start   => i_proc_start,
                                         i_cpoe_proc_end     => i_proc_end,
                                         i_cpoe_proc_refresh => i_proc_refresh,
                                         i_cpoe_proc_status  => g_flg_status_a,
                                         i_prev_cpoe_proc    => l_prev_cpoe_process,
                                         o_new_cpoe_process  => o_cpoe_process);
                
                    -- update last cpoe process id
                    l_prev_cpoe_process := o_cpoe_process;
                END IF;
            
                -- create new next CPOE
                create_cpoe_internal(i_cpoe_proc_start   => i_proc_next_start,
                                     i_cpoe_proc_end     => i_proc_next_end,
                                     i_cpoe_proc_refresh => i_proc_next_refresh,
                                     i_cpoe_proc_status  => g_flg_status_n,
                                     i_prev_cpoe_proc    => l_prev_cpoe_process,
                                     o_new_cpoe_process  => o_cpoe_process);
            
                -- next cpoe created
                COMMIT;
            ELSE
                g_error := 'pk_cpoe.create_cpoe: invalid cpoe process type [' || i_proc_type || ']';
                RAISE l_exception;
            END IF;
        
        ELSE
            o_cpoe_process := -1; -- do nothing
        
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
                                              'CREATE_CPOE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_cpoe;

    /********************************************************************************************
    * set cpoe expired alert
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_cpoe_process            cpoe process id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Filipe Machado
    * @since                                 2009/11/24
    ********************************************************************************************/
    FUNCTION set_expired_proc_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_cpoe_process IN cpoe_process.id_cpoe_process%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'set expired process alert';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => g_sys_alert_expired_cpoe,
                                                i_id_episode          => i_episode,
                                                i_id_record           => i_cpoe_process,
                                                i_dt_record           => current_timestamp,
                                                i_id_professional     => i_prof.id,
                                                i_id_room             => NULL,
                                                i_id_clinical_service => NULL,
                                                i_flg_type_dest       => 'C',
                                                i_replace1            => NULL,
                                                o_error               => o_error)
        THEN
            RAISE l_exception;
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
                                              'SET_EXPIRED_PROC_ALERT',
                                              o_error);
            RETURN FALSE;
    END set_expired_proc_alert;

    /********************************************************************************************
    * handling alerts for professional of the same category
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_task                 task id
    * @param       o_error                   date end of next prescription
    *
    * @return      boolean                   true on success, otherwise false 
    *
    * @author                                Filipe Machado
    * @since                                 2009/11/25
    ********************************************************************************************/

    FUNCTION handling_alerts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_process   IN cpoe_process.id_cpoe_process%TYPE,
        i_prof_list IN table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        FOR i IN 1 .. i_prof_list.count
        LOOP
            IF NOT
                set_expired_proc_alert(i_lang         => i_lang,
                                       i_prof         => profissional(i_prof_list(i), i_prof.institution, i_prof.software),
                                       i_episode      => i_episode,
                                       i_cpoe_process => i_process,
                                       o_error        => o_error)
            THEN
                RAISE l_exception;
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
                                              'HANDLING_ALERTS',
                                              o_error);
            RETURN FALSE;
    END handling_alerts;

    PROCEDURE refresh_draft_prescription
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_cpoe_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_auto_mode          IN VARCHAR2,
        i_dt_proc_next_start IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_proc_next_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_draft_task_type    OUT table_number,
        o_draft_task_request OUT table_number
    ) IS
        l_flg_del_draft          sys_config.value%TYPE;
        l_task_requests          table_number;
        l_task_status            pk_types.cursor_type;
        l_refresh_task_reqs      table_number;
        l_recpt                  t_rec_cpoe_task_req := t_rec_cpoe_task_req(NULL, NULL, NULL);
        l_tbl_cpoe_process_tasks t_tbl_cpoe_task_req := t_tbl_cpoe_task_req();
        l_tbl_index              NUMBER := 0;
        l_ts_refresh             TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
        o_error t_error_out;
        l_exception EXCEPTION;
        -- get task types that can be refreshed to draft prescription
        CURSOR c_refreshable_types IS
            SELECT DISTINCT pt.id_task_type, pt.id_episode
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_cpoe_process
               AND EXISTS (SELECT 1
                      FROM cpoe_task_type_status_filter sf
                     WHERE sf.id_task_type = pt.id_task_type
                       AND sf.flg_cpoe_proc_refresh = pk_alert_constant.g_yes);
    
        -- refreshable tasks
        CURSOR c_refreshable_tasks
        (
            in_task_type    IN cpoe_process_task.id_task_type%TYPE,
            in_task_episode IN cpoe_process_task.id_episode%TYPE
        ) IS
            SELECT pt.id_task_request
              FROM cpoe_process_task pt
             WHERE pt.id_cpoe_process = i_cpoe_process
               AND pt.id_task_type = in_task_type
               AND pt.id_episode = in_task_episode;
    
        -- set of refreshable task requests for "copy2draft" action process
        CURSOR c_refresh_proc_tasks IS
            SELECT id_task_type, id_request
              FROM (SELECT id_task_type, id_request, get_task_status_refresh(id_task_type, flg_status) AS flg_refresh
                      FROM TABLE(CAST(l_tbl_cpoe_process_tasks AS t_tbl_cpoe_task_req)) task)
             WHERE flg_refresh = pk_alert_constant.g_yes;
    
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.refresh_draft_prescription called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode ||
                                  chr(10) || 'i_cpoe_process=' || i_cpoe_process || chr(10) || 'i_auto_mode=' ||
                                  i_auto_mode || chr(10) || 'i_dt_proc_next_start=' || i_dt_proc_next_start || chr(10) ||
                                  'i_dt_proc_next_end=' || i_dt_proc_next_end,
                                  g_package_name);
        END IF;
    
        -- check if existing drafts should be removed before refreshing draft prescription
        IF NOT get_delete_on_refresh(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_auto_mode => i_auto_mode,
                                     o_flg_del   => l_flg_del_draft,
                                     o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- draft tasks removal before prescription refresh (only if configuration allows it)
        IF l_flg_del_draft = pk_alert_constant.g_yes
        THEN
            IF i_auto_mode = pk_alert_constant.g_yes
            THEN
                -- delete all drafts with autonomous transactions
                delete_all_drafts_auto_trans(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
            ELSE
                -- delete all drafts without autonomous transactions
                IF NOT delete_all_drafts(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, o_error => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        END IF;
    
        -- copy 2 draft all eligible tasks from one given cpoe process (only expirable tasks are processed)
        FOR rec_type IN c_refreshable_types
        LOOP
            -- get all task requests for a given task type and episode
            OPEN c_refreshable_tasks(rec_type.id_task_type, rec_type.id_episode);
            FETCH c_refreshable_tasks BULK COLLECT
                INTO l_task_requests;
            CLOSE c_refreshable_tasks;
        
            -- get task status
            IF NOT get_task_status(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => rec_type.id_episode,
                                   i_task_type    => rec_type.id_task_type,
                                   i_task_request => l_task_requests,
                                   o_task_status  => l_task_status,
                                   o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- open l_task_status; (cursor l_task_status is already open)
            LOOP
                IF l_task_status IS NOT NULL
                THEN
                    FETCH l_task_status
                        INTO l_recpt.id_task_type, l_recpt.id_request, l_recpt.flg_status;
                    EXIT WHEN l_task_status%NOTFOUND;
                ELSE
                    EXIT;
                END IF;
            
                -- update cpoe task type based on target task type returned from get_task_status function
                l_recpt.id_task_type := get_task_type_match(rec_type.id_task_type, l_recpt.id_task_type);
            
                -- extend and associates the new record into l_tbl_cpoe_process_tasks            
                l_tbl_cpoe_process_tasks.extend;
                l_tbl_index := l_tbl_index + 1;
                l_tbl_cpoe_process_tasks(l_tbl_index) := l_recpt;
            END LOOP;
        
        END LOOP;
    
        -- get all task types/requests to be refreshed
        OPEN c_refresh_proc_tasks;
        FETCH c_refresh_proc_tasks BULK COLLECT
            INTO o_draft_task_type, l_refresh_task_reqs;
        CLOSE c_refresh_proc_tasks;
    
        IF l_refresh_task_reqs.count > 0
        THEN
            -- refresh draft prescription with processed task types/requests with autonomous transactions/normal transaction
            -- (defined by i_auto_mode)
            copy_to_draft(i_lang             => i_lang,
                          i_prof             => i_prof,
                          i_episode          => i_episode,
                          i_task_type        => o_draft_task_type,
                          i_task_request     => l_refresh_task_reqs,
                          i_auto_trans       => i_auto_mode,
                          i_dt_draft_start   => i_dt_proc_next_start,
                          i_dt_draft_end     => i_dt_proc_next_end,
                          o_new_task_request => o_draft_task_request);
        
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_cpoe_process,
                                      o_dt_start        => l_ts_cpoe_start,
                                      o_dt_end          => l_ts_cpoe_end,
                                      o_flg_status      => l_flg_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_cpoe_process => l_cpoe_process,
                                         i_tasks_orig   => l_refresh_task_reqs,
                                         i_tasks_dest   => o_draft_task_request,
                                         i_tasks_type   => o_draft_task_type,
                                         i_flg_type     => 'AD',
                                         o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSE
            o_draft_task_type    := table_number();
            o_draft_task_request := table_number();
        END IF;
    
        -- update cpoe process refresh status
        g_error := 'update cpoe process with refresh info';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE cpoe_process cp
           SET cp.dt_last_update             = l_ts_refresh,
               cp.dt_cpoe_refreshed          = l_ts_refresh,
               cp.flg_cpoe_proc_auto_refresh = decode(cp.flg_cpoe_proc_auto_refresh,
                                                      g_flg_rfs_status_no_refresh,
                                                      g_flg_rfs_status_refreshed,
                                                      g_flg_rfs_status_refresh,
                                                      decode(i_auto_mode,
                                                             pk_alert_constant.g_yes,
                                                             g_flg_rfs_status_refreshed,
                                                             cp.flg_cpoe_proc_auto_refresh),
                                                      cp.flg_cpoe_proc_auto_refresh)
         WHERE cp.id_cpoe_process = i_cpoe_process;
    
    END refresh_draft_prescription;

    /********************************************************************************************
    * this procedure performs cpoe specific tasks (to be called by an oracle job)
    *
    * tasks performed here:
    * -> refresh all refreshable tasks into draft prescriptions, according to each institution config
    *
    * @author                                Carlos Loureiro
    * @since                                 17-Sep-2010
    ********************************************************************************************/
    PROCEDURE cpoe_job_draft_refresh IS
        l_lang               language.id_language%TYPE;
        l_prof               profissional;
        l_error              t_error_out;
        l_draft_task_type    table_number;
        l_draft_task_request table_number;
    
        CURSOR c_process_to_refresh IS
            SELECT cp.id_cpoe_process,
                   cp.id_episode,
                   cp.id_professional,
                   cp.id_institution,
                   cp.id_software,
                   cp.dt_cpoe_proc_end
              FROM cpoe_process cp
             WHERE cp.flg_cpoe_proc_auto_refresh = g_flg_rfs_status_refresh
               AND cp.dt_cpoe_proc_auto_refresh <= current_timestamp
             ORDER BY cp.id_institution, cp.id_software; -- to guarantee that all inst/sw will be processed in group
    
        l_exception EXCEPTION;
    
        l_dt_start      cpoe_process.dt_cpoe_proc_start%TYPE;
        l_dt_end        cpoe_process.dt_cpoe_proc_end%TYPE;
        l_dt_refresh    cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_dt_next_presc cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
    
        o_error t_error_out;
    
    BEGIN
        g_error := 'cpoe job - refresh draft prescriptions - begin';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop all marked to refresh cpoe processes for draft prescription update
        FOR proc IN c_process_to_refresh
        LOOP
            l_lang := to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                        proc.id_institution,
                                                        proc.id_software));
        
            l_prof := profissional(proc.id_professional, proc.id_institution, proc.id_software);
        
            -- get next cpoe info, starting from the end of process that is being refreshed now
            IF NOT get_next_cpoe_info(i_lang          => l_lang,
                                      i_prof          => l_prof,
                                      i_episode       => proc.id_episode,
                                      i_dt_start      => proc.dt_cpoe_proc_end,
                                      o_dt_start      => l_dt_start,
                                      o_dt_end        => l_dt_end,
                                      o_dt_refresh    => l_dt_refresh,
                                      o_dt_next_presc => l_dt_next_presc,
                                      o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- refresh draft prescription, setting the start/end dates in line with next cpoe process
            refresh_draft_prescription(i_lang               => l_lang,
                                       i_prof               => l_prof,
                                       i_episode            => proc.id_episode,
                                       i_cpoe_process       => proc.id_cpoe_process,
                                       i_auto_mode          => pk_alert_constant.g_yes,
                                       i_dt_proc_next_start => l_dt_start,
                                       i_dt_proc_next_end   => l_dt_end - g_tstz_presc_limit_threshold,
                                       o_draft_task_type    => l_draft_task_type,
                                       o_draft_task_request => l_draft_task_request);
        
            COMMIT;
        
        END LOOP;
    
        g_error := 'cpoe job - refresh draft prescriptions - end';
        pk_alertlog.log_debug(g_error, g_package_name);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                                                pk_alert_constant.g_inst_all,
                                                                                pk_alert_constant.g_soft_all)),
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CPOE_JOB_DRAFT_REFRESH',
                                              l_error);
            pk_utils.undo_changes;
        
    END cpoe_job_draft_refresh;

    /********************************************************************************************
    * this procedure performs cpoe specific tasks (to be called by an oracle job)
    *
    * tasks performed here:
    * -> expire all cpoe processes (and tasks), according to each institution config 
    *
    * @author                                Tiago Silva
    * @since                                 25-Nov-2009
    ********************************************************************************************/
    PROCEDURE cpoe_job_expire IS
        l_physician table_number;
        l_nurse     table_number;
        l_lang      language.id_language%TYPE;
        l_prof      profissional;
        l_error     t_error_out;
    
        CURSOR c_process_to_expire IS
            SELECT cp.id_cpoe_process, cp.id_episode, cp.id_professional, cp.id_institution, cp.id_software
              FROM cpoe_process cp
             WHERE cp.flg_status = g_flg_status_a
               AND cp.dt_cpoe_proc_end <= current_timestamp
            --AND id_Episode = 2797069
             ORDER BY cp.id_institution, cp.id_software; -- to guarantee that all inst/sw will be processed in order
    
        TYPE t_process_to_expire IS TABLE OF c_process_to_expire%ROWTYPE INDEX BY PLS_INTEGER;
        ibt_expired_processes t_process_to_expire;
    
        l_has_next_presc VARCHAR2(1 CHAR);
        l_flg_cpoe_mode  VARCHAR2(1 CHAR);
    
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'cpoe job - expire processes and tasks - begin';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- loop all active cpoe processes that are about to be expired
        FOR proc IN c_process_to_expire
        LOOP
        
            BEGIN
            
                l_lang := to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                            proc.id_institution,
                                                            proc.id_software));
            
                l_prof := profissional(proc.id_professional, proc.id_institution, proc.id_software);
            
                -- expire active cpoe process
                expire_cpoe(i_lang          => l_lang,
                            i_prof          => l_prof,
                            i_episode       => proc.id_episode,
                            i_cpoe_process  => proc.id_cpoe_process,
                            o_flg_next_proc => l_has_next_presc);
            
                -- if a next prescription doesn't exist for this patient, then raise an alert for each responsible professional
                IF l_has_next_presc = pk_alert_constant.g_no
                THEN
                    g_error := 'get responsible list of physicians and alert handling';
                    pk_alertlog.log_debug(g_error, g_package_name);
                
                    l_physician := pk_hand_off_core.get_responsibles_id(i_lang          => l_lang,
                                                                        i_prof          => l_prof,
                                                                        i_id_episode    => proc.id_episode,
                                                                        i_prof_cat      => pk_alert_constant.g_cat_type_doc,
                                                                        i_hand_off_type => pk_hand_off.g_handoff_normal);
                    IF NOT handling_alerts(l_lang, l_prof, proc.id_episode, proc.id_cpoe_process, l_physician, l_error)
                    THEN
                        g_error := 'error found while calling pk_cpoe.handling_alerts function for physicians';
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'get responsible list of nurses and alert handling';
                    pk_alertlog.log_debug(g_error, g_package_name);
                
                    l_nurse := pk_hand_off_core.get_responsibles_id(i_lang          => l_lang,
                                                                    i_prof          => l_prof,
                                                                    i_id_episode    => proc.id_episode,
                                                                    i_prof_cat      => pk_alert_constant.g_cat_type_nurse,
                                                                    i_hand_off_type => pk_hand_off.g_handoff_normal);
                    IF NOT handling_alerts(l_lang, l_prof, proc.id_episode, proc.id_cpoe_process, l_nurse, l_error)
                    THEN
                        g_error := 'error found while calling pk_cpoe.handling_alerts function for nurses';
                        RAISE l_exception;
                    END IF;
                END IF;
            
                -- commit the changes for this cpoe process
                COMMIT;
            
                -- add cpoe process to the expired processes list
                ibt_expired_processes(ibt_expired_processes.count) := proc;
            
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                                                        pk_alert_constant.g_inst_all,
                                                                                        pk_alert_constant.g_soft_all)),
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'CPOE_JOB_EXPIRE',
                                                      l_error);
                    pk_utils.undo_changes;
            END;
        
        END LOOP;
    
        -- loop all active cpoe processes that are about to be expired
        IF ibt_expired_processes.count > 0
        THEN
        
            FOR i IN ibt_expired_processes.first .. ibt_expired_processes.last
            LOOP
            
                l_lang := to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                            ibt_expired_processes                      (i).id_institution,
                                                            ibt_expired_processes                      (i).id_software));
            
                l_prof := profissional(ibt_expired_processes(i).id_professional,
                                       ibt_expired_processes(i).id_institution,
                                       ibt_expired_processes(i).id_software);
            
                -- check if tasks should be expired by checking the current cpoe mode configuration
                -- this code block is here to handle the cpoe mode transition from (A)dvanced to (S)imple
                -- in this situation, only the process is expired, not the associated tasks, to avoid the
                -- unwanted tasks expiration
                IF NOT get_cpoe_mode(l_lang, l_prof, ibt_expired_processes(i).id_episode, l_flg_cpoe_mode, l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
                THEN
                    BEGIN
                    
                        -- expire process tasks
                        IF NOT expire_cpoe_tasks(l_lang,
                                                 ibt_expired_processes(i).id_cpoe_process,
                                                 pk_alert_constant.g_yes,
                                                 l_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        -- commit the changes for this cpoe process tasks
                        COMMIT;
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            pk_alert_exceptions.process_error(to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                                                                pk_alert_constant.g_inst_all,
                                                                                                pk_alert_constant.g_soft_all)),
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'CPOE_JOB_EXPIRE',
                                                              l_error);
                            pk_utils.undo_changes;
                    END;
                
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'cpoe job - expire processes and tasks - end';
        pk_alertlog.log_debug(g_error, g_package_name);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                                                pk_alert_constant.g_inst_all,
                                                                                pk_alert_constant.g_soft_all)),
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CPOE_JOB_EXPIRE',
                                              l_error);
            pk_utils.undo_changes;
        
    END cpoe_job_expire;

    /********************************************************************************************
    * get cpoe current status and warning messages (to be called by reports)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_flg_cpoe_status         cpoe status flag
    * @param       o_cpoe_warning_message    cpoe warning message
    * @param       o_error                   error message    
    *
    * @return      boolean                   true on success, otherwise false   
    *
    * @author                                Tiago Silva
    * @since                                 2011/08/01
    ********************************************************************************************/
    FUNCTION get_cpoe_warning_messages
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        o_flg_cpoe_status      OUT VARCHAR2,
        o_cpoe_warning_message OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_flg_cpoe_status VARCHAR2(1 CHAR);
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional professional.id_professional%TYPE;
    
    BEGIN
        g_error := 'call get_cpoe_warning_messages';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get last cpoe information
        IF NOT get_last_cpoe_info(i_lang,
                                  i_prof,
                                  i_episode,
                                  l_cpoe_process,
                                  l_ts_cpoe_start,
                                  l_ts_cpoe_end,
                                  l_flg_cpoe_status,
                                  l_id_professional,
                                  o_error)
        THEN
            g_error := 'error found while calling get_last_cpoe_info function';
            RAISE l_exception;
        END IF;
    
        -- last cpoe has expired
        IF l_flg_cpoe_status = g_flg_status_e
        THEN
            -- "cpoe expired" warning message
            o_flg_cpoe_status      := l_flg_cpoe_status;
            o_cpoe_warning_message := pk_message.get_message(i_lang, 'CPOE_M014');
        
        ELSE
            -- nothing to warn about
            o_flg_cpoe_status      := NULL;
            o_cpoe_warning_message := NULL;
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
                                              'GET_CPOE_WARNING_MESSAGES',
                                              o_error);
            RETURN FALSE;
    END get_cpoe_warning_messages;

    /********************************************************************************************
    * check the current cpoe status (to be called on patient's ehr access)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_flg_warning             warning flag to show (or not) message
    * @param       o_msg_template            message/pop-up template
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body
    * @param       o_error                   error message
    *
    * @value       o_flg_warning             {*} 'Y' show expired cpoe message 
    *                                        {*} 'N' proceed without showing any message
    *
    * @value       o_msg_template            {*} 'WARNING_READ' warning read
    *                                        {*} 'WARNING_SECURITY' warning security
    *
    * @return      boolean                   true on success, otherwise false   
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/28
    ********************************************************************************************/
    FUNCTION check_cpoe_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_flg_warning  OUT VARCHAR2,
        o_msg_template OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_body     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_flg_cpoe_mode         VARCHAR2(1 CHAR);
        l_flg_cpoe_status       VARCHAR2(1 CHAR);
        l_cpoe_process          cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start         cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end           cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional       professional.id_professional%TYPE;
        l_ts                    TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_expire_warning        NUMBER;
        l_flg_exp_prompt        VARCHAR2(1 CHAR);
        l_current_episode_state episode.flg_status%TYPE;
    
        l_hour        NUMBER;
        l_minute      NUMBER;
        l_dt_deceased patient.dt_deceased%TYPE;
    
    BEGIN
        g_error := 'call get_cpoe_mode';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_episode IS NOT NULL)
        THEN
        
            DELETE FROM cpoe_episode a
             WHERE a.id_episode = i_episode
               AND flg_type = 'SP';
            -- get cpoe mode to evaluate current cpoe status
            IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- process current cpoe status only if cpoe mode is configured in advanced and current professional has a clinical category
            IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
               AND pk_prof_utils.get_clinical_cat(i_lang, i_prof) = pk_alert_constant.g_yes
            THEN
            
                g_error := 'get current episode state';
                pk_alertlog.log_debug(g_error, g_package_name);
                SELECT ep.flg_status, p.dt_deceased
                  INTO l_current_episode_state, l_dt_deceased
                  FROM episode ep
                 INNER JOIN patient p
                    ON p.id_patient = ep.id_patient
                 WHERE ep.id_episode = i_episode;
            
                g_error := 'get CPOE_EXPIRE_WARNING_PROMPT sys config';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_flg_exp_prompt := nvl(pk_sysconfig.get_config(g_cfg_cpoe_wrn_exp_prmpt, i_prof),
                                        g_cfg_cpoe_wrn_exp_prmpt_b);
            
                -- show warning only for active/temporary/pending episodes
                IF l_current_episode_state IN (pk_alert_constant.g_epis_status_active,
                                               pk_alert_constant.g_epis_status_temp,
                                               pk_alert_constant.g_epis_status_pendent)
                   AND l_flg_exp_prompt <> g_cfg_cpoe_wrn_exp_prmpt_n
                   AND l_dt_deceased IS NULL
                THEN
                    g_error := 'call get_last_cpoe_info';
                    pk_alertlog.log_debug(g_error, g_package_name);
                
                    -- get last cpoe information
                    IF NOT get_last_cpoe_info(i_lang,
                                              i_prof,
                                              i_episode,
                                              l_cpoe_process,
                                              l_ts_cpoe_start,
                                              l_ts_cpoe_end,
                                              l_flg_cpoe_status,
                                              l_id_professional,
                                              o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    -- last cpoe has expired
                    IF l_flg_cpoe_status = g_flg_status_e
                    THEN
                        -- "cpoe expired" warning message
                        o_flg_warning  := pk_alert_constant.g_yes;
                        o_msg_template := pk_alert_constant.g_modal_win_warning_security;
                        --o_msg_title    := pk_message.get_message(i_lang, 'CPOE_T019');
                        o_msg_body := ' ';
                    
                        o_msg_title := pk_message.get_message(i_lang, 'CPOE_M014') || '</b><br><br>' ||
                                       pk_message.get_message(i_lang, 'CPOE_M015');
                    
                    ELSIF l_flg_cpoe_status = g_flg_status_a
                          AND l_flg_exp_prompt = g_cfg_cpoe_wrn_exp_prmpt_b
                    THEN
                        -- last cpoe is still active: check if is near to expiration period
                        l_expire_warning := to_number(nvl(pk_sysconfig.get_config(g_cfg_cpoe_wrn_exp_time, i_prof),
                                                          g_default_expire_time));
                        IF pk_date_utils.compare_dates_tsz(i_prof,
                                                           l_ts_cpoe_end,
                                                           pk_date_utils.add_to_ltstz(l_ts,
                                                                                      l_expire_warning / 1440,
                                                                                      'DAY')) =
                           pk_alert_constant.g_date_lower
                        THEN
                            -- "cpoe is about to expire" message
                            o_flg_warning  := pk_alert_constant.g_yes;
                            o_msg_template := pk_alert_constant.g_modal_win_warning_security;
                            --o_msg_title    := pk_message.get_message(i_lang, 'CPOE_T018');
                            o_msg_body := ' ';
                        
                            l_hour   := extract(hour FROM(l_ts_cpoe_end - current_timestamp));
                            l_minute := extract(minute FROM(l_ts_cpoe_end - current_timestamp));
                        
                            -- O </b> é para forçar a retirar o negrito que o Flash usa.
                            o_msg_title := '</b>' || get_cpoe_message(i_lang         => i_lang,
                                                                      i_code_message => 'CPOE_M013',
                                                                      i_param1       => pk_date_utils.date_char_tsz(i_lang,
                                                                                                                    l_ts_cpoe_end,
                                                                                                                    i_prof.institution,
                                                                                                                    i_prof.software),
                                                                      i_param2       => CASE
                                                                                            WHEN l_hour = 0 THEN
                                                                                             l_minute || ' ' || pk_message.get_message(i_lang, 'SCH_T099')
                                                                                            ELSE
                                                                                             l_hour || ' ' || pk_message.get_message(i_lang, 'COMMON_M123') || ' ' ||
                                                                                             pk_message.get_message(i_lang, 'SCH_T103') || ' ' || l_minute || ' ' ||
                                                                                             pk_message.get_message(i_lang, 'SCH_T099')
                                                                                        END);
                        ELSE
                            -- nothing to warn about (still active, no overlap in warning period)
                            o_flg_warning := pk_alert_constant.g_no;
                        END IF;
                    
                    ELSE
                        -- nothing to warn about (process not yet started)
                        o_flg_warning := pk_alert_constant.g_no;
                    END IF;
                
                ELSE
                    -- nothing to warn about (disabled warnings)
                    o_flg_warning := pk_alert_constant.g_no;
                END IF;
            
            ELSE
                -- nothing to warn about (working in simple mode)
                o_flg_warning := pk_alert_constant.g_no;
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
                                              'CHECK_CPOE_STATUS',
                                              o_error);
            RETURN FALSE;
    END check_cpoe_status;

    /********************************************************************************************
    * get task report filter based in task type status  
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_prof                    professional id structure
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   boolean                   indicates if task is visible in reports 
    *
    * @author                             Carlos Loureiro
    * @since                              2009/12/10
    ********************************************************************************************/
    FUNCTION get_task_report_filter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN VARCHAR2,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_flag_report VARCHAR2(1 CHAR);
    BEGIN
        SELECT sf.flg_cpoe_proc_report
          INTO l_flag_report
          FROM cpoe_task_type_status_filter sf
         WHERE sf.id_task_type = i_task_type
           AND sf.flg_status = i_flg_status
           AND check_task_action_avail(i_lang, i_prof, i_task_type, g_cpoe_task_view_action, NULL) = g_flg_active;
        RETURN l_flag_report;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
    END get_task_report_filter;

    /********************************************************************************************
    * get last cpoe information
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       o_cpoe_process            cpoe process id
    * @param       o_dt_start                cpoe start timestamp
    * @param       o_dt_end                  cpoe end timestamp
    * @param       o_flg_status              cpoe status flag
    * @param       o_id_professional         creator id (professional id)
    * @param       o_error                   error message
    *        
    * @value       o_flg_status              {*} 'A' cpoe is currently active
    *                                        {*} 'E' last cpoe is expired 
    *                                        {*} 'N' no cpoe created so far
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/11/17
    ********************************************************************************************/
    FUNCTION get_last_cpoe_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_cpoe_process    OUT cpoe_process.id_cpoe_process%TYPE,
        o_dt_start        OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_flg_status      OUT cpoe_process.flg_status%TYPE,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get last cpoe information from patient''s episodes';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT cp1.id_cpoe_process, cp1.dt_cpoe_proc_start, cp1.dt_cpoe_proc_end, cp1.flg_status, cp1.id_professional
          INTO o_cpoe_process, o_dt_start, o_dt_end, o_flg_status, o_id_professional
          FROM cpoe_process cp1
         WHERE cp1.id_cpoe_process = (SELECT id_cpoe_process
                                        FROM (SELECT cp2.id_cpoe_process
                                                FROM cpoe_process cp2
                                                JOIN episode e1
                                                  ON e1.id_episode = cp2.id_episode
                                                JOIN episode e2
                                                  ON e2.id_visit = e1.id_visit
                                               WHERE e2.id_episode = i_episode
                                                 AND cp2.flg_status != g_flg_status_n
                                               ORDER BY cp2.dt_cpoe_proc_start DESC)
                                       WHERE rownum = 1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- no cpoe created so far
            o_flg_status   := g_flg_status_no_cpoe;
            o_cpoe_process := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_last_cpoe_info;

    /********************************************************************************************
    * get cpoe information, based in given process id
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_process                 cpoe process id 
    * @param       o_dt_start                cpoe start timestamp
    * @param       o_dt_end                  cpoe end timestamp
    * @param       o_flg_status              cpoe status flag
    * @param       o_id_professional         creator id (professional id)
    * @param       o_error                   error message
    *        
    * @value       o_flg_status              {*} 'A' cpoe is active
    *                                        {*} 'E' cpoe is expired 
    *                                        {*} 'I' cpoe is expired (interrupted)
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_cpoe_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_process         IN cpoe_process.id_cpoe_process%TYPE,
        o_dt_start        OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_flg_status      OUT cpoe_process.flg_status%TYPE,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get cpoe information for given process id';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT cp.dt_cpoe_proc_start, cp.dt_cpoe_proc_end, cp.flg_status, cp.id_professional
          INTO o_dt_start, o_dt_end, o_flg_status, o_id_professional
          FROM cpoe_process cp
         WHERE cp.id_cpoe_process = i_process;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_cpoe_info;

    /********************************************************************************************
    * get next cpoe information (get data input for new cpoe prescriprion action)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       o_dt_start                cpoe start timestamp
    * @param       o_dt_end                  cpoe end timestamp
    * @param       o_dt_refresh              cpoe "refresh to draft prescription" timestamp
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/11/18
    *
    * The CPOE Period will be dependent of the episode clinical service associated with it.
    * The id_episode will be needed in order to get the id_dep_clin_serv from the EPIS_INFO
    * @author                                Joao Reis
    * @since                                 2011/09/21
    ********************************************************************************************/
    FUNCTION get_next_cpoe_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_dt_start      IN cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_start      OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end        OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_dt_refresh    OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_dt_next_presc OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_refresh sys_config.value%TYPE;
        l_exception EXCEPTION;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := NULL;
    
        l_dt_start cpoe_process.dt_cpoe_proc_start%TYPE;
    
        l_cpoe_episode_special_case VARCHAR2(5 CHAR);
    
    BEGIN
        g_error := 'get next cpoe information';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
            SELECT a.varchar_aux
              INTO l_cpoe_episode_special_case
              FROM cpoe_episode a
             WHERE a.id_episode = i_episode
               AND a.flg_type = 'SP';
        EXCEPTION
            WHEN OTHERS THEN
                l_cpoe_episode_special_case := NULL;
        END;
    
        IF i_dt_start IS NULL
        THEN
            l_dt_start := current_timestamp;
            o_dt_start := current_timestamp; -- always remove X minutes from current_timestamp to avoid blocked task creations in new cpoe processes
        ELSE
            l_dt_start := i_dt_start;
            o_dt_start := i_dt_start;
            --o_dt_start := current_timestamp;
        END IF;
    
        -- get id_dep_clin_serv from EPIS_INFO
        IF NOT pk_episode.get_epis_dep_clin_serv(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_episode          => i_episode,
                                                 o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                 o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- get prescription expire timestamp, according to the planning period. the planning period can change the 
        -- behavior of the prescription validation period, by postponing the expire timestamp to the next period in 
        -- sequence
    
        SELECT dt_end,
               pk_date_utils.add_to_ltstz(dt_end, -refresh_period, 'HOUR'),
               pk_date_utils.add_to_ltstz(l_dt_start, -next_presc_period, 'HOUR')
          INTO o_dt_end, o_dt_refresh, o_dt_next_presc
          FROM (SELECT decode(decode(pk_date_utils.compare_dates_tsz(i_prof, o_dt_start, plan_start),
                                     pk_alert_constant.g_date_lower,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_yes),
                              pk_alert_constant.g_yes,
                              decode(l_cpoe_episode_special_case, pk_alert_constant.g_yes, after_next_period, next_period),
                              next_period) AS dt_end,
                       refresh_period,
                       next_presc_period
                  FROM (SELECT next_period,
                               pk_date_utils.add_to_ltstz(next_period, -planning_period, 'HOUR') AS plan_start,
                               -- nvl function is needed here to work with only one record / "one-day" configurations
                               -- lead function will get the next rownum, overriding the "rownum=1" condition. the rownum=2
                               -- gets the next timeslot available after "next_period" timestamp
                               nvl(lead(next_period, 1) over(ORDER BY next_period),
                                   pk_date_utils.add_to_ltstz(next_period, 1, 'DAY')) AS after_next_period,
                               refresh_period,
                               next_presc_period
                          FROM (SELECT decode(pk_date_utils.compare_dates_tsz(i_prof, o_dt_start, today),
                                              pk_alert_constant.g_date_lower,
                                              today,
                                              tomorrow) next_period,
                                       planning_period,
                                       refresh_period,
                                       next_presc_period
                                  FROM (SELECT DISTINCT first_value(pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  to_char(o_dt_start,
                                                                                                          'YYYYMMDD') ||
                                                                                                  substr(cp.expire_time,
                                                                                                         1,
                                                                                                         2) ||
                                                                                                  substr(cp.expire_time,
                                                                                                         4,
                                                                                                         2) || '00',
                                                                                                  NULL)) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS today,
                                                        first_value(pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  to_char(o_dt_start + 1,
                                                                                                          'YYYYMMDD') ||
                                                                                                  substr(cp.expire_time,
                                                                                                         1,
                                                                                                         2) ||
                                                                                                  substr(cp.expire_time,
                                                                                                         4,
                                                                                                         2) || '00',
                                                                                                  NULL)) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS tomorrow,
                                                        first_value(cp.planning_period) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS planning_period,
                                                        first_value(cp.refresh_period) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS refresh_period,
                                                        first_value(cp.next_presc_period) over(ORDER BY cp.id_institution DESC, cp.id_software DESC) AS next_presc_period,
                                                        first_value(cp.flg_available) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS flg_available
                                          FROM cpoe_period cp
                                         WHERE cp.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                           AND cp.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                           AND (cp.id_dep_clin_serv = l_id_dep_clin_serv OR cp.id_dep_clin_serv IS NULL))
                                 WHERE flg_available = pk_alert_constant.g_yes
                                 ORDER BY next_period))
                 WHERE rownum = 1);
    
        IF i_dt_start IS NULL
        THEN
            o_dt_start := current_timestamp - g_tstz_create_threshold; -- always remove X minutes from current_timestamp to avoid blocked task creations in new cpoe processes
        END IF;
    
        -- check if it is supposed to automatically refresh draft prescriptions through a job
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_auto_refresh_presc, i_prof, l_flg_refresh)
        THEN
            g_error := 'error found while calling pk_sysconfig.get_config function';
            RAISE l_exception;
        END IF;
        IF l_flg_refresh IS NULL
           OR l_flg_refresh = pk_alert_constant.g_no
        THEN
            o_dt_refresh := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'No CPOE configurations found in CPOE_PERIOD table';
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_next_cpoe_info;

    /********************************************************************************************
    * get complete messages by replacing wildcards by context values  
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_code_message            code message from sys_message
    * @param    i_param1                  replacing string @1
    * @param    i_param2                  replacing string @2
    * @param    i_param3                  replacing string @3
    * @param    i_param4                  replacing string @4
    * @param    i_param5                  replacing string @5
    *
    * @return   varchar2                  message with replaced wildcards 
    *
    * @author                             Carlos Loureiro
    * @since                              2009/11/21
    ********************************************************************************************/
    FUNCTION get_cpoe_message
    (
        i_lang         IN language.id_language%TYPE,
        i_code_message IN sys_message.code_message%TYPE,
        i_param1       IN VARCHAR2,
        i_param2       IN VARCHAR2 DEFAULT NULL,
        i_param3       IN VARCHAR2 DEFAULT NULL,
        i_param4       IN VARCHAR2 DEFAULT NULL,
        i_param5       IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pk_message.get_message(i_lang, i_code_message), '@1', i_param1),
                                               '@2',
                                               i_param2),
                                       '@3',
                                       i_param3),
                               '@4',
                               i_param4),
                       '@5',
                       i_param5);
    END get_cpoe_message;

    /********************************************************************************************
    * check if task type requires an active cpoe (task creation / activation requirement)  
    *
    * @param    i_lang                       preferred language id for this professional
    * @param    i_prof                       professional id structure
    * @param    i_task_type                  cpoe task type id
    *
    * @return   varchar2                     flag that indicates if task type requires or not an 
    *                                        active cpoe
    *
    * @value    check_task_cpoe_requirement  {*} 'Y' active cpoe is needed to create this type
    *                                        {*} 'N' no actived cpoe needed to create this type
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION check_task_cpoe_requirement
    (
        i_prof      profissional,
        i_task_type cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'check_task_cpoe_requirement';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT flg_need_presc
          INTO l_ret
          FROM (SELECT DISTINCT first_value(flg_need_presc) over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) AS flg_need_presc,
                                first_value(flg_available) over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) AS flg_available
                  FROM cpoe_task_soft_inst
                 WHERE id_task_type = i_task_type
                   AND id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND id_software IN (i_prof.software, pk_alert_constant.g_soft_all))
         WHERE flg_available = pk_alert_constant.g_yes;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
        
    END check_task_cpoe_requirement;

    /********************************************************************************************
    * check if task type expires for the given institution/software environment  
    *
    * @param    i_prof                       professional id structure
    * @param    i_task_type                  cpoe task type id
    *
    * @return   varchar2                     flag that indicates if task type requires or not an 
    *                                        active cpoe
    *
    * @value    check_task_cpoe_expire       {*} 'Y' task expires with prescription
    *                                        {*} 'N' task doesn't expire with prescription
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/12/05
    ********************************************************************************************/
    FUNCTION check_task_cpoe_expire
    (
        i_prof      profissional,
        i_task_type cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'check_task_cpoe_expire';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT flg_expirable
          INTO l_ret
          FROM (SELECT DISTINCT first_value(flg_expirable) over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) AS flg_expirable,
                                first_value(flg_available) over(PARTITION BY id_task_type ORDER BY id_institution DESC, id_software DESC) AS flg_available
                  FROM cpoe_task_soft_inst
                 WHERE id_task_type = i_task_type
                   AND id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND id_software IN (i_prof.software, pk_alert_constant.g_soft_all))
         WHERE flg_available = pk_alert_constant.g_yes;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
        
    END check_task_cpoe_expire;

    /********************************************************************************************
    * get all patient's prescriptions history
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       o_cpoe_hist               cursor containing information about all prescriptions 
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/02
    ********************************************************************************************/
    FUNCTION get_cpoe_history
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_cpoe_hist OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get o_cpoe_hist cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_cpoe_hist FOR
            SELECT p.id_cpoe_process,
                   p.flg_status,
                   get_cpoe_message(i_lang,
                                    'CPOE_T011',
                                    to_char(row_number() over(ORDER BY p.dt_cpoe_proc_start)),
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL) AS cpoe_process_msg,
                   pk_sysdomain.get_domain(g_domain_cpoe_flg_status, p.flg_status, i_lang) AS cpoe_status_desc,
                   pk_message.get_message(i_lang, 'CPOE_T012') || ' ' ||
                   get_cpoe_message(i_lang,
                                    'CPOE_M008',
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     p.dt_cpoe_proc_start,
                                                                     i_prof.institution,
                                                                     i_prof.software),
                                    pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          p.dt_cpoe_proc_start,
                                                                          i_prof.institution,
                                                                          i_prof.software),
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     p.dt_cpoe_proc_end,
                                                                     i_prof.institution,
                                                                     i_prof.software),
                                    pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          p.dt_cpoe_proc_end,
                                                                          i_prof.institution,
                                                                          i_prof.software),
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)) AS cpoe_effectiveness
              FROM cpoe_process p
             WHERE p.id_episode IN (SELECT e1.id_episode
                                      FROM episode e1
                                      JOIN episode e2
                                        ON e2.id_visit = e1.id_visit
                                     WHERE e2.id_episode = i_episode)
             ORDER BY p.dt_cpoe_proc_start DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_hist);
            RETURN FALSE;
        
    END get_cpoe_history;

    /********************************************************************************************
    * set all process tasks into a collection
    *
    * @param       i_cpoe_process            preferred language id for this professional
    * @param       o_tbl_cpoe_process_tasks  professional id structure
    *
    * @author                                Carlos Loureiro
    * @since                                 2010/07/10
    ********************************************************************************************/
    PROCEDURE set_process_tasks
    (
        i_cpoe_process           IN cpoe_process.id_cpoe_process%TYPE,
        o_tbl_cpoe_process_tasks OUT t_tbl_cpoe_task_req
    ) IS
    BEGIN
        -- cpoe process task data debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.set_process_tasks called with:' || chr(10) || 'i_cpoe_process=' ||
                                  i_cpoe_process,
                                  g_package_name);
        END IF;
    
        -- get cpoe process tasks
        SELECT t_rec_cpoe_task_req(get_reverse_task_type_map(pt.id_task_type), pt.id_task_request, NULL)
          BULK COLLECT
          INTO o_tbl_cpoe_process_tasks
          FROM cpoe_process_task pt
         WHERE pt.id_cpoe_process = i_cpoe_process;
    
    END set_process_tasks;

    PROCEDURE set_process_tasks_all
    (
        i_id_episode             IN episode.id_episode%TYPE,
        o_tbl_cpoe_process_tasks OUT t_tbl_cpoe_task_req
    ) IS
    BEGIN
        -- cpoe process task data debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.set_process_tasks called with:' || chr(10) || 'i_cpoe_process=' ||
                                  i_id_episode,
                                  g_package_name);
        END IF;
    
        -- get cpoe process tasks
        SELECT t_rec_cpoe_task_req(get_reverse_task_type_map(pt.id_task_type), pt.id_task_request, NULL)
          BULK COLLECT
          INTO o_tbl_cpoe_process_tasks
          FROM cpoe_process_task pt
         WHERE pt.id_episode = i_id_episode;
    
    END set_process_tasks_all;

    /********************************************************************************************
    * get a patient's prescription tasks history (cpoe process detail)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_process                 internal id of the cpoe process 
    * @param       o_cpoe_task               cursor containing information about prescription's tasks 
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/02
    ********************************************************************************************/
    FUNCTION get_cpoe_task_history
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_process   IN cpoe_process.id_cpoe_process%TYPE,
        o_cpoe_task OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_all_tasks t_tbl_cpoe_task_list;
        l_exception EXCEPTION;
        l_cnt_all                NUMBER;
        l_cnt_current            NUMBER;
        l_cnt_active             NUMBER;
        l_cnt_next               NUMBER;
        l_cnt_draft              NUMBER;
        l_cnt_to_ack             NUMBER;
        l_task_types             table_number;
        l_proc_episode           episode.id_episode%TYPE;
        l_tbl_cpoe_process_tasks t_tbl_cpoe_task_req;
    
        l_flg_status VARCHAR(1 CHAR);
    
        l_med_admin pk_types.cursor_type;
        l_proc_plan pk_types.cursor_type;
        l_execution t_tbl_cpoe_execution;
    
    BEGIN
        g_error := 'get episode from cpoe process';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT p.id_episode, p.flg_status
          INTO l_proc_episode, l_flg_status
          FROM cpoe_process p
         WHERE p.id_cpoe_process = i_process;
    
        -- get all tasks for a given cpoe process
        set_process_tasks(i_process, l_tbl_cpoe_process_tasks);
    
        g_error := 'get l_all_tasks and filter counters from get_task_list_all function';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_task_list_all(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_cpoe_mode       => g_cfg_cpoe_mode_advanced, -- history is only available when working in advanced mode,
                                 i_patient         => i_patient,
                                 i_episode         => l_proc_episode,
                                 i_process_tasks   => l_tbl_cpoe_process_tasks, -- array with requests from given cpoe process
                                 i_cpoe_start_tstz => NULL, -- start tstz filter is not needed for cpoe history (task requests are addressed directly)
                                 i_process         => NULL,
                                 i_flg_report      => pk_alert_constant.g_no, -- discard report columns in history grid     
                                 i_cpoe_status     => NULL,
                                 o_tasks           => l_all_tasks,
                                 o_task_types      => l_task_types,
                                 o_cnt_all         => l_cnt_all,
                                 o_cnt_current     => l_cnt_current,
                                 o_cnt_next        => l_cnt_next,
                                 o_cnt_active      => l_cnt_active,
                                 o_cnt_draft       => l_cnt_draft,
                                 o_cnt_to_ack      => l_cnt_to_ack,
                                 o_execution       => l_execution,
                                 o_med_admin       => l_med_admin,
                                 o_proc_plan       => l_proc_plan,
                                 o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'get o_cpoe_task cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN o_cpoe_task FOR
            SELECT get_task_group_id(i_prof, all_tasks.id_task_type) AS group_type_id,
                   get_task_group_name(i_lang, i_prof, all_tasks.id_task_type) AS task_group_desc,
                   get_task_group_rank(i_prof, all_tasks.id_task_type) AS task_group_rank,
                   all_tasks.id_task_type AS task_type_id,
                   all_tasks.id_target_task_type AS id_target_task_type,
                   all_tasks.task_description AS task_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, all_tasks.id_profissional) AS prof,
                   pk_date_utils.date_send_tsz(i_lang, all_tasks.start_date_tstz, i_prof) AS start_date,
                   pk_date_utils.date_send_tsz(i_lang, all_tasks.end_date_tstz, i_prof) AS end_date,
                   pk_date_utils.date_char_tsz(i_lang,
                                               all_tasks.creation_date_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS date_desc,
                   all_tasks.status_str AS status_string,
                   get_task_type_icon(i_lang, i_prof, all_tasks.id_task_type) AS icon,
                   all_tasks.icon_warning,
                   all_tasks.id_request,
                   all_tasks.flg_status,
                   all_tasks.flg_cancel,
                   all_tasks.flg_conflict,
                   all_tasks.id_task,
                   all_tasks.instr_bg_color AS instr_bg_color,
                   all_tasks.instr_bg_alpha AS instr_bg_alpha,
                   all_tasks.flg_need_ack AS flg_need_ack
              FROM TABLE(CAST(l_all_tasks AS t_tbl_cpoe_task_list)) all_tasks
             WHERE (task_out_of_cpoe_process(i_lang, i_prof, all_tasks.id_task_type) = pk_alert_constant.g_no)
                OR ((task_out_of_cpoe_process(i_lang, i_prof, all_tasks.id_task_type) = pk_alert_constant.g_yes) AND
                   pk_cpoe.g_flg_status_a = l_flg_status)
             ORDER BY task_group_rank, task_type_id, all_tasks.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_TASK_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_task);
            RETURN FALSE;
        
    END get_cpoe_task_history;

    FUNCTION get_flg_status_final
    (
        i_id_task_type cpoe_task_type.id_task_type%TYPE,
        i_flg_status   cpoe_task_type_status_filter.flg_status%TYPE
    ) RETURN VARCHAR2 AS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        SELECT flg_final_status
          INTO l_ret
          FROM cpoe_task_type_status_filter
         WHERE id_task_type = i_id_task_type
           AND flg_status = i_flg_status;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            --AlertLog..error('pedro - ' || id_task_type || ' - ' || flg_status);
            RETURN 'N';
    END get_flg_status_final;

    /********************************************************************************************
    * get a patient's prescription tasks report
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_process                 internal id of the cpoe process 
    * @param       o_cpoe_info               cursor containing information about prescription information
    * @param       o_cpoe_task               cursor containing information about prescription's tasks 
    * @param       o_error                   error message
    *
    * @value       i_process                 {*} <ID>   cursors will have given process information
    *                                        {*} <NULL> cursors will have last/current process information 
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_cpoe_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_task_ids      IN table_number DEFAULT NULL,
        i_task_type_ids IN table_number DEFAULT NULL,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_cpoe_info     OUT pk_types.cursor_type,
        o_cpoe_task     OUT pk_types.cursor_type,
        o_execution     OUT pk_types.cursor_type,
        o_med_admin     OUT pk_types.cursor_type,
        o_proc_plan     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_execution t_tbl_cpoe_execution;
        l_all_tasks t_tbl_cpoe_task_list;
        l_exception EXCEPTION;
        l_cnt_all                NUMBER;
        l_cnt_current            NUMBER;
        l_cnt_next               NUMBER;
        l_cnt_active             NUMBER;
        l_cnt_draft              NUMBER;
        l_cnt_to_ack             NUMBER;
        l_task_types             table_number;
        l_proc_episode           episode.id_episode%TYPE;
        l_cpoe_process           cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start          cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end            cpoe_process.dt_cpoe_proc_end%TYPE;
        l_flg_cpoe_status        cpoe_process.flg_status%TYPE;
        l_id_professional        cpoe_process.id_professional%TYPE;
        l_tbl_cpoe_process_tasks t_tbl_cpoe_task_req;
    
        l_id_process cpoe_process.id_cpoe_process%TYPE;
    
        l_med_admin pk_types.cursor_type;
        l_proc_plan pk_types.cursor_type;
    
        l_ctx_handle dbms_xmlgen.ctxhandle;
        l_clob       CLOB;
        l_num_rows   PLS_INTEGER;
    
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
    
        l_tbl_cpoe_process      table_number := table_number();
        l_cpoe_process_id       cpoe_process.id_cpoe_process%TYPE;
        l_count_cpoe_process_id NUMBER;
        l_tasks_id_process      VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
        l_id_process := i_process;
    
        IF i_process IS NULL
           AND i_task_ids IS NOT NULL
           AND i_task_ids.count > 0
        THEN
        
            FOR i IN 1 .. i_task_ids.count
            LOOP
                BEGIN
                    SELECT a.id_cpoe_process
                      INTO l_cpoe_process_id
                      FROM cpoe_process_task a
                     WHERE a.id_task_request = i_task_ids(i)
                       AND a.id_task_type = i_task_type_ids(i);
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                l_tbl_cpoe_process.extend;
                l_tbl_cpoe_process(l_tbl_cpoe_process.count) := l_cpoe_process_id;
            
            END LOOP;
        
            SELECT COUNT(*)
              INTO l_count_cpoe_process_id
              FROM (SELECT DISTINCT t.column_value
                      FROM TABLE(l_tbl_cpoe_process) t);
        
            IF l_count_cpoe_process_id = 1
            THEN
                l_tasks_id_process := pk_alert_constant.g_yes;
                l_id_process       := l_tbl_cpoe_process(1);
            END IF;
        
        END IF;
    
        -- if cpoe process is not null, then use the given process to find the associated episode
        IF l_id_process IS NULL
        THEN
            -- get last cpoe information and process id
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- use given episode
            l_proc_episode := i_episode;
        
        ELSE
        
            l_tasks_id_process := pk_alert_constant.g_yes;
            -- get last cpoe information and process id
            IF NOT get_cpoe_info(i_lang,
                                 i_prof,
                                 l_id_process,
                                 l_ts_cpoe_start,
                                 l_ts_cpoe_end,
                                 l_flg_cpoe_status,
                                 l_id_professional,
                                 o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'get episode from cpoe process';
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT p.id_episode
              INTO l_proc_episode
              FROM cpoe_process p
             WHERE p.id_cpoe_process = l_id_process;
        
            l_cpoe_process := l_id_process;
        
        END IF;
    
        -- remark: from this point, l_cpoe_process is the one to be used in o_cpoe_task query
    
        -- get all tasks for a given cpoe process
    
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_id_process IS NOT NULL
           AND (i_task_ids IS NULL OR i_task_ids.count = 0)
        THEN
            set_process_tasks(l_cpoe_process, l_tbl_cpoe_process_tasks);
            g_error := 'get l_all_tasks and filter counters from get_task_list_all function';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT get_task_list_all(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_cpoe_mode       => g_cfg_cpoe_mode_advanced, -- report is only available when working in advanced mode
                                     i_patient         => i_patient,
                                     i_episode         => l_proc_episode,
                                     i_process_tasks   => l_tbl_cpoe_process_tasks, -- array with requests from given cpoe process
                                     i_cpoe_start_tstz => NULL, -- start tstz filter is not needed for cpoe reports (task requests are addressed directly)
                                     i_flg_report      => pk_alert_constant.g_yes, -- consider report columns 
                                     i_process         => l_cpoe_process,
                                     i_task_ids        => i_task_ids,
                                     i_task_type_ids   => i_task_type_ids,
                                     i_dt_start        => nvl(i_dt_start,
                                                              pk_date_utils.get_timestamp_str(i_lang,
                                                                                              i_prof,
                                                                                              l_ts_cpoe_start,
                                                                                              NULL)),
                                     i_dt_end          => nvl(i_dt_end,
                                                              pk_date_utils.get_timestamp_str(i_lang,
                                                                                              i_prof,
                                                                                              l_ts_cpoe_end,
                                                                                              NULL)),
                                     i_cpoe_status     => l_flg_cpoe_status,
                                     o_tasks           => l_all_tasks,
                                     o_task_types      => l_task_types,
                                     o_cnt_all         => l_cnt_all,
                                     o_cnt_current     => l_cnt_current,
                                     o_cnt_next        => l_cnt_next,
                                     o_cnt_active      => l_cnt_active,
                                     o_cnt_draft       => l_cnt_draft,
                                     o_cnt_to_ack      => l_cnt_to_ack,
                                     o_execution       => l_execution,
                                     o_med_admin       => o_med_admin,
                                     o_proc_plan       => o_proc_plan,
                                     o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSE
            --set_process_tasks_all(i_episode, l_tbl_cpoe_process_tasks);
        
            IF NOT get_task_list_all(i_lang            => i_lang,
                                i_prof            => i_prof,
                                i_cpoe_mode       => l_flg_cpoe_mode,
                                i_patient         => i_patient,
                                i_episode         => i_episode,
                                i_process_tasks   => NULL, -- main cpoe grid will never specify task requests
                                i_cpoe_start_tstz => pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL),
                                i_flg_report      => pk_alert_constant.g_yes, -- discard report columns
                                i_process         => CASE
                                                         WHEN l_tasks_id_process = pk_alert_constant.g_yes THEN
                                                          l_id_process
                                                         ELSE
                                                          NULL
                                                     END,
                                i_tab_type        => '*',
                                i_task_ids        => i_task_ids,
                                i_task_type_ids   => i_task_type_ids,
                                i_dt_start        => nvl(i_dt_start,
                                                         pk_date_utils.get_timestamp_str(i_lang, i_prof, l_ts_cpoe_start, NULL)),
                                i_dt_end          => nvl(i_dt_end,
                                                         pk_date_utils.get_timestamp_str(i_lang, i_prof, l_ts_cpoe_end, NULL)),
                                i_cpoe_status     => l_flg_cpoe_status,
                                o_tasks           => l_all_tasks,
                                o_task_types      => l_task_types,
                                o_cnt_all         => l_cnt_all,
                                o_cnt_current     => l_cnt_current,
                                o_cnt_next        => l_cnt_next,
                                o_cnt_active      => l_cnt_active,
                                o_cnt_draft       => l_cnt_draft,
                                o_cnt_to_ack      => l_cnt_to_ack,
                                o_execution       => l_execution,
                                o_med_admin       => o_med_admin,
                                o_proc_plan       => o_proc_plan,
                                o_error           => o_error)
            THEN
            
                RAISE l_exception;
            END IF;
        
        END IF;
        g_error := 'get o_cpoe_task cursor';
        OPEN o_cpoe_task FOR
            SELECT (SELECT get_task_group_id(i_prof, all_tasks.id_task_type)
                      FROM dual) AS group_type_id,
                   (SELECT get_task_group_name(i_lang, i_prof, all_tasks.id_task_type)
                      FROM dual) AS task_group_desc,
                   (SELECT get_task_group_rank(i_prof, all_tasks.id_task_type)
                      FROM dual) AS task_group_rank,
                   all_tasks.id_task_type AS task_type_id,
                   get_task_type_name(i_lang, i_prof, all_tasks.id_task_type) AS task_type_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, all_tasks.id_profissional) AS prof,
                   pk_date_utils.date_char_tsz(i_lang,
                                               all_tasks.creation_date_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS creation_date,
                   get_date_char_by_task_type(i_lang, i_prof, all_tasks.id_task_type, all_tasks.start_date_tstz) AS start_date,
                   get_date_char_by_task_type(i_lang, i_prof, all_tasks.id_task_type, all_tasks.end_date_tstz) AS end_date,
                   all_tasks.id_request,
                   all_tasks.task_description task_title,
                   all_tasks.task_instructions,
                   all_tasks.task_notes,
                   all_tasks.generic_text1,
                   all_tasks.generic_text2,
                   all_tasks.generic_text3,
                   all_tasks.task_status,
                   all_tasks.id_profissional,
                   all_tasks.flg_rep_cancel,
                   all_tasks.flg_prn_conditional
              FROM TABLE(CAST(l_all_tasks AS t_tbl_cpoe_task_list)) all_tasks
             WHERE (all_tasks.start_date_tstz <=
                   decode(i_dt_end, NULL, l_ts_cpoe_end, pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL)))
               AND all_tasks.flg_rep_cancel != pk_alert_constant.g_yes
               AND get_flg_status_final(all_tasks.id_task_type, all_tasks.flg_status) = pk_alert_constant.g_no
               AND ((get_task_report_filter(i_lang, i_prof, all_tasks.id_task_type, all_tasks.flg_status) =
                   pk_alert_constant.g_yes AND i_process IS NOT NULL) OR
                   (EXISTS (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                              *
                               FROM TABLE(all_tasks.visible_tabs) t
                              WHERE t.column_value = 'A')) OR
                   (task_out_of_cpoe_process(i_lang => i_lang, i_prof => i_prof, i_task_type => all_tasks.id_task_type) =
                   pk_alert_constant.g_yes) AND all_tasks.flg_status != 'DF')
             ORDER BY task_group_rank, task_type_id, all_tasks.rank;
    
        OPEN o_execution FOR
            SELECT *
              FROM TABLE(CAST(l_execution AS t_tbl_cpoe_execution));
    
        g_error := 'get o_cpoe_info cursor';
        OPEN o_cpoe_info FOR
            SELECT l_flg_cpoe_status AS cpoe_status,
                   (SELECT pk_sysdomain.get_domain(g_domain_cpoe_flg_status, l_flg_cpoe_status, i_lang)
                      FROM dual) AS cpoe_status_desc,
                   decode(l_tasks_id_process,
                          pk_alert_constant.g_yes,
                          get_cpoe_message(i_lang,
                                           'CPOE_M016',
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       decode(i_dt_start,
                                                                              NULL,
                                                                              l_ts_cpoe_start,
                                                                              pk_date_utils.get_string_tstz(i_lang,
                                                                                                            i_prof,
                                                                                                            i_dt_start,
                                                                                                            NULL)),
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       decode(i_dt_end,
                                                                              NULL,
                                                                              l_ts_cpoe_end,
                                                                              pk_date_utils.get_string_tstz(i_lang,
                                                                                                            i_prof,
                                                                                                            i_dt_end,
                                                                                                            NULL)),
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       decode(i_dt_end,
                                                                              NULL,
                                                                              l_ts_cpoe_end,
                                                                              pk_date_utils.get_string_tstz(i_lang,
                                                                                                            i_prof,
                                                                                                            i_dt_end,
                                                                                                            NULL)),
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                           NULL,
                                           NULL),
                          get_cpoe_message(i_lang,
                                           'CPOE_M016',
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_dt_start,
                                                                                                     NULL),
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_dt_end,
                                                                                                     NULL),
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_dt_end,
                                                                                                     NULL),
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                           
                                           NULL,
                                           NULL)) AS cpoe_period,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_professional)
                      FROM dual) AS cpoe_author,
                   decode(l_flg_cpoe_mode, g_cfg_cpoe_mode_advanced, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_advanced_mode
              FROM dual
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_REPORT',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_info);
            pk_types.open_my_cursor(o_cpoe_task);
            RETURN FALSE;
        
    END get_cpoe_report;

    /********************************************************************************************
    * clear specific cpoe processes or clear all cpoe processes related with a list of patients
    *
    * @param       i_lang              preferred language id for this professional
    * @param       i_prof              professional id structure
    * @param       i_patients          patients array
    * @param       i_cpoe_processes    cpoe processes array         
    * @param       o_error             error message
    *        
    * @return      boolean             true on success, otherwise false    
    *   
    * @author                          Tiago Silva
    * @since                           2010/11/02
    ********************************************************************************************/
    FUNCTION clear_cpoe_processes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patients       IN table_number DEFAULT NULL,
        i_cpoe_processes IN table_number DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cpoe IS
            SELECT /*+ OPT_ESTIMATE(table cp rows = 1)*/
             cp.id_cpoe_process
              FROM cpoe_process cp
             INNER JOIN episode epis
                ON (cp.id_episode = epis.id_episode)
             WHERE epis.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                        column_value AS VALUE
                                         FROM TABLE(i_patients) pat)
                OR cp.id_cpoe_process IN (SELECT /*+ OPT_ESTIMATE(table cpoe_procs rows = 1)*/
                                           column_value AS VALUE
                                            FROM TABLE(i_cpoe_processes) cpoe_procs);
    
        l_cpoe_processes table_number;
    
    BEGIN
    
        g_error := 'GET ALL CPOE PROCESSES TO REMOVE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN c_cpoe;
        FETCH c_cpoe BULK COLLECT
            INTO l_cpoe_processes;
        CLOSE c_cpoe;
    
        g_error := 'DEL CPOE_PROCESS_TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_cpoe_processes.last
            DELETE cpoe_process_task cpt
             WHERE cpt.id_cpoe_process = l_cpoe_processes(i);
    
        g_error := 'DEL CPOE_PROCESS_HIST';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_cpoe_processes.last
            DELETE cpoe_process_hist cpt
             WHERE cpt.id_cpoe_process = l_cpoe_processes(i);
    
        g_error := 'DEL CPOE_PROCESSES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_cpoe_processes.last
            DELETE cpoe_process cp
             WHERE cp.id_cpoe_process = l_cpoe_processes(i);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CLEAR_CPOE_PROCESSES',
                                              o_error);
            RETURN FALSE;
    END clear_cpoe_processes;

    /********************************************************************************************
    * get the closed task filter timestamp (with local tiome zone) used by CPOE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_closed_task_filter_tstz closed task filter timestamp (with local tiome zone)
    *                                        note: if null, no cpoe was created or cpoe is not  
    *                                              working in advanced mode
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 25-Jan-2011
    ********************************************************************************************/
    FUNCTION get_closed_task_filter_tstz
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        o_closed_task_filter_tstz OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_cpoe_mode           VARCHAR2(1 CHAR);
        l_flg_cpoe_status         VARCHAR2(1 CHAR);
        l_cpoe_process            cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start           cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end             cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional         professional.id_professional%TYPE;
        l_cfg_closed_task_filter  sys_config.value%TYPE;
        l_closed_task_filter_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'get cpoe working mode';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            -- get last cpoe information
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
            -- get closed task filter interval in days
            g_error := 'get CPOE_CLOSED_TASK_FILTER_INTERVAL sys_config';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT pk_sysconfig.get_config(g_cfg_cpoe_closed_task_filter, i_prof, l_cfg_closed_task_filter)
            THEN
                RAISE l_exception;
            END IF;
            -- get minimum timestamp for closed tasks filter (in days)
            l_closed_task_filter_tstz := current_timestamp -
                                         numtodsinterval(to_number(l_cfg_closed_task_filter), 'DAY');
            IF l_ts_cpoe_start IS NOT NULL
               AND l_ts_cpoe_start < l_closed_task_filter_tstz
            THEN
                l_closed_task_filter_tstz := l_ts_cpoe_start;
            END IF;
            -- get the oldest date, when comparing CPOE's start date and configuration
            o_closed_task_filter_tstz := l_closed_task_filter_tstz;
        ELSE
            -- simple mode doesn't have active CPOEs
            o_closed_task_filter_tstz := NULL;
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
                                              'GET_CLOSED_TASK_FILTER_TSTZ',
                                              o_error);
            RETURN FALSE;
    END get_closed_task_filter_tstz;

    /********************************************************************************************
    * get date char string properly formatted from a timestamp, for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               episode id
    * @param       i_timestamp               closed task filter timestamp (with local tiome zone)
    *
    * @return      varchar2                  formatted date char timestamp, related to given task type    
    *
    * @author                                Carlos Loureiro
    * @since                                 11-OCT-2011
    ********************************************************************************************/
    FUNCTION get_date_char_by_task_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    BEGIN
        CASE
            WHEN i_task_type IN (g_task_type_diet_inst, g_task_type_diet_spec, g_task_type_diet_predefined) THEN
                -- return only formatted date string (DATE_FORMAT)
                RETURN pk_date_utils.dt_chr_tsz(i_lang, i_timestamp, i_prof.institution, i_prof.software);
            ELSE
                -- return formatted date / time string (DATE_HOUR_FORMAT)
                RETURN pk_date_utils.date_char_tsz(i_lang, i_timestamp, i_prof.institution, i_prof.software);
        END CASE;
    END get_date_char_by_task_type;

    /********************************************************************************************
    * get cpoe end date timestamp for a given task type/request
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id 
    * @param       o_end_date                cpoe end date timestamp
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 10-NOV-2011
    ********************************************************************************************/
    FUNCTION get_cpoe_end_date_by_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_end_date     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
    
        l_id_episode episode.id_episode%TYPE;
    BEGIN
        -- debug message function call
    
        SELECT a.id_episode
          INTO l_id_episode
          FROM cpoe_process_task a
         WHERE a.id_task_request = i_task_request;
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.get_cpoe_end_date_by_task called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_task_type=' ||
                                  i_task_type || chr(10) || 'i_task_request=' || i_task_request,
                                  g_package_name);
        END IF;
        -- get cpoe mode to evaluate if cpoe end date should be evaluated or not
        IF NOT get_cpoe_mode(i_lang, i_prof, l_id_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
        -- only sync tasks with cpoe process when working in advanced mode
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            BEGIN
                g_error := 'get cpoe end date with task type/request';
                SELECT cp.dt_cpoe_proc_end
                  INTO o_end_date
                  FROM cpoe_process cp
                  JOIN cpoe_process_task cpt
                    ON cpt.id_cpoe_process = cp.id_cpoe_process
                 WHERE cpt.id_task_type = i_task_type
                   AND cpt.id_task_request = i_task_request;
            EXCEPTION
                WHEN no_data_found THEN
                    o_end_date := NULL;
            END;
        ELSE
            o_end_date := NULL;
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
                                              'GET_CPOE_END_DATE_BY_TASK',
                                              o_error);
            RETURN FALSE;
    END get_cpoe_end_date_by_task;

    /********************************************************************************************
    * get cds task type for given cpoe task type
    *
    * @param       i_prof                    professional id structure
    *
    * @return      number                    cds task type id  
    * 
    * @author                                Carlos Loureiro
    * @since                                 21-NOV-2011
    ********************************************************************************************/
    FUNCTION get_cds_task_type(i_task_type IN cpoe_task_type.id_task_type%TYPE) RETURN cpoe_task_type.id_task_type_cds%TYPE IS
        l_ret cpoe_task_type.id_task_type_cds%TYPE;
    BEGIN
        SELECT id_task_type_cds
          INTO l_ret
          FROM cpoe_task_type
         WHERE id_task_type = i_task_type;
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_cds_task_type;

    /********************************************************************************************
    * set intake and output (hidric) references in cpoe_task_type table (to be executed only by DEFAULT)
    *
    * @author                                Carlos Loureiro
    * @since                                 12-JUN-2012
    ********************************************************************************************/
    PROCEDURE set_cpoe_hidric_references IS
    BEGIN
    
        -- intake task type
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'I')
         WHERE ctt.id_task_type = g_task_type_hidric_in; -- hidrics (intake)
    
        -- intake and output
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'H')
         WHERE ctt.id_task_type = g_task_type_hidric_in_out; -- hidrics (intake and output)
    
        -- output
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'O')
         WHERE ctt.id_task_type = g_task_type_hidric_out_group; -- hidrics (output group)
    
        -- drainage records
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'R')
         WHERE ctt.id_task_type = g_task_type_hidric_drain; -- hidrics (drainage)
    
        -- urinary output
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'D')
         WHERE ctt.id_task_type = g_task_type_hidric_out; -- hidrics (urinary output)
    
        -- all outputs
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'A')
         WHERE ctt.id_task_type = g_task_type_hidric_out_all; -- hidrics (output all)
    
        -- irrigations
        UPDATE cpoe_task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'G')
         WHERE ctt.id_task_type = g_task_type_hidric_irrigations; -- hidrics (irrigations)         
    
    END set_cpoe_hidric_references;

    /********************************************************************************************
    * get cpoe start date timestamp for a given task type/episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               cpoe task type id
    * @param       i_episode                 episode id 
    * @param       o_start_date              cpoe start date timestamp
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                CRISTINA.OLIVEIRA
    * @since                                 20-05-2016
    ********************************************************************************************/
    FUNCTION get_cpoe_start_date_by_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_episode    IN cpoe_process_task.id_episode%TYPE,
        o_start_date OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
    BEGIN
        -- debug message function call
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.get_cpoe_start_date_by_task called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_task_type=' ||
                                  i_task_type || chr(10) || 'i_episode=' || i_episode,
                                  g_package_name);
        END IF;
        -- get cpoe mode to evaluate if cpoe start date should be evaluated or not
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
        -- only sync tasks with cpoe process when working in advanced mode
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            BEGIN
                g_error := 'get cpoe end date with task type/request';
                SELECT DISTINCT cp.dt_cpoe_proc_start
                  INTO o_start_date
                  FROM cpoe_process cp
                  JOIN cpoe_process_task cpt
                    ON cpt.id_cpoe_process = cp.id_cpoe_process
                 WHERE cpt.id_task_type = i_task_type
                   AND cp.id_episode = i_episode
                   AND cp.flg_status = g_flg_status_a;
            EXCEPTION
                WHEN no_data_found THEN
                    o_start_date := NULL;
            END;
        ELSE
            o_start_date := NULL;
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
                                              'GET_CPOE_START_DATE_BY_TASK',
                                              o_error);
            RETURN FALSE;
    END get_cpoe_start_date_by_task;

    /*FUNCTION get_next_cpoe_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_start   IN cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_start   OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_dt_refresh OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_refresh sys_config.value%TYPE;
        l_exception EXCEPTION;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := NULL;
    
    BEGIN
        g_error := 'get next cpoe information';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF i_dt_start IS NULL
        THEN
            o_dt_start := current_timestamp - g_tstz_create_threshold; -- always remove X minutes from current_timestamp to avoid blocked task creations in new cpoe processes
        ELSE
            o_dt_start := i_dt_start;
        END IF;
    
        -- get id_dep_clin_serv from EPIS_INFO
        IF NOT pk_episode.get_epis_dep_clin_serv(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_episode          => i_episode,
                                                 o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                 o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- get prescription expire timestamp, according to the planning period. the planning period can change the 
        -- behavior of the prescription validation period, by postponing the expire timestamp to the next period in 
        -- sequence
        SELECT dt_end, pk_date_utils.add_to_ltstz(dt_end, -refresh_period, 'HOUR')
          INTO o_dt_end, o_dt_refresh
          FROM (SELECT decode(decode(pk_date_utils.compare_dates_tsz(i_prof, o_dt_start, plan_start),
                                     pk_alert_constant.g_date_lower,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_yes),
                              pk_alert_constant.g_yes,
                              after_next_period,
                              next_period) AS dt_end,
                       refresh_period
                  FROM (SELECT next_period,
                               pk_date_utils.add_to_ltstz(next_period, -planning_period, 'HOUR') AS plan_start,
                               -- nvl function is needed here to work with only one record / "one-day" configurations
                               -- lead function will get the next rownum, overriding the "rownum=1" condition. the rownum=2
                               -- gets the next timeslot available after "next_period" timestamp
                               nvl(lead(next_period, 1) over(ORDER BY next_period),
                                   pk_date_utils.add_to_ltstz(next_period, 1, 'DAY')) AS after_next_period,
                               refresh_period
                          FROM (SELECT decode(pk_date_utils.compare_dates_tsz(i_prof, o_dt_start, today),
                                              pk_alert_constant.g_date_lower,
                                              today,
                                              tomorrow) next_period,
                                       planning_period,
                                       refresh_period
                                  FROM (SELECT DISTINCT pk_date_utils.get_string_tstz(i_lang,
                                                                                      i_prof,
                                                                                      to_char(o_dt_start, 'YYYYMMDD') ||
                                                                                      substr(cp.expire_time, 1, 2) ||
                                                                                      substr(cp.expire_time, 4, 2) || '00',
                                                                                      NULL) today,
                                                        pk_date_utils.get_string_tstz(i_lang,
                                                                                      i_prof,
                                                                                      to_char(o_dt_start + 1, 'YYYYMMDD') ||
                                                                                      substr(cp.expire_time, 1, 2) ||
                                                                                      substr(cp.expire_time, 4, 2) || '00',
                                                                                      NULL) tomorrow,
                                                        first_value(cp.planning_period) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS planning_period,
                                                        first_value(cp.refresh_period) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS refresh_period,
                                                        first_value(cp.flg_available) over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS flg_available
                                          FROM cpoe_period cp
                                         WHERE cp.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                           AND cp.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                           AND (cp.id_dep_clin_serv = l_id_dep_clin_serv OR cp.id_dep_clin_serv IS NULL))
                                 WHERE flg_available = pk_alert_constant.g_yes
                                 ORDER BY next_period))
                 WHERE rownum = 1);
    
        -- check if it is supposed to automatically refresh draft prescriptions through a job
        IF NOT pk_sysconfig.get_config(g_cfg_cpoe_auto_refresh_presc, i_prof, l_flg_refresh)
        THEN
            g_error := 'error found while calling pk_sysconfig.get_config function';
            RAISE l_exception;
        END IF;
        IF l_flg_refresh IS NULL
           OR l_flg_refresh = pk_alert_constant.g_no
        THEN
            o_dt_refresh := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'No CPOE configurations found in CPOE_PERIOD table';
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_next_cpoe_info;*/

    FUNCTION check_drafts_activation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN table_number,
        i_dt_start          IN table_varchar,
        i_dt_end            IN table_varchar,
        i_draft_request     IN table_number,
        o_task_list         OUT pk_types.cursor_type,
        o_flg_warning_type  OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_proc_start        OUT VARCHAR2,
        o_proc_end          OUT VARCHAR2,
        o_proc_refresh      OUT VARCHAR2,
        o_proc_next_start   OUT VARCHAR2,
        o_proc_next_end     OUT VARCHAR2,
        o_proc_next_refresh OUT VARCHAR2,
        o_cpoe_process      OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_flg_cpoe_mode        VARCHAR2(1 CHAR);
        l_flg_cpoe_status      VARCHAR2(1 CHAR);
        l_cpoe_process         cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start        cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_next_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end          cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh      cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_refresh cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_id_professional      professional.id_professional%TYPE;
        l_can_create_presc     VARCHAR2(1 CHAR) := g_flg_active;
    
        l_task_req_list        t_tbl_cpoe_task_create := t_tbl_cpoe_task_create(); -- t_rec_cpoe_task_create
        l_has_out_of_bounds    VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_no_presc_tasks   VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_curr_presc_tasks VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_next_presc_tasks VARCHAR2(1) := pk_alert_constant.g_no;
        l_out_of_cpoe_process  VARCHAR2(1) := pk_alert_constant.g_no;
        l_next_presc_exists    BOOLEAN := FALSE;
    
        l_ts_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_cpoe.check_drafts_activation called with:' || chr(10) || 'i_lang=' || i_lang ||
                                  chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' || i_episode ||
                                  chr(10) || 'i_task_type=' || get_tabnum_str(i_task_type) || chr(10) || 'i_dt_start=' ||
                                  get_tabvar_str(i_dt_start) || chr(10) || 'i_dt_end=' || get_tabvar_str(i_dt_end) ||
                                  chr(10) || 'i_draft_request=' || get_tabnum_str(i_draft_request),
                                  g_package_name);
        END IF;
    
        -- get cpoe mode to evaluate if the task should be created or not
        pk_alertlog.log_debug('get_cpoe_mode', g_package_name);
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            -- check if professional is allowed to create prescriptions
            l_can_create_presc := check_presc_action_avail(i_lang, i_prof, g_cpoe_presc_create_action);
        
            -- get last cpoe information to check if an active prescription exists
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_cpoe_process,
                                      o_dt_start        => l_ts_cpoe_start,
                                      o_dt_end          => l_ts_cpoe_end,
                                      o_flg_status      => l_flg_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            o_cpoe_process := l_cpoe_process;
            -- if last cpoe is not active
            IF l_flg_cpoe_status <> g_flg_status_a
            THEN
                -- no cpoe process created so far. system will check if all tasks have the proper start timestamps 
                -- by checking the cpoe automatic creation periods
                IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_dt_start      => NULL,
                                          o_dt_start      => l_ts_cpoe_start,
                                          o_dt_end        => l_ts_cpoe_end,
                                          o_dt_refresh    => l_ts_cpoe_refresh,
                                          o_dt_next_presc => l_ts_cpoe_next_presc,
                                          o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            -- get next prescription process
            get_next_presc_process(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   o_cpoe_process => l_cpoe_process,
                                   o_dt_start     => l_ts_cpoe_next_start,
                                   o_dt_end       => l_ts_cpoe_next_end);
        
            IF l_cpoe_process IS NULL
            THEN
                -- no next prescription created so far
                l_next_presc_exists := FALSE;
            ELSE
                -- next prescription already exists
                l_next_presc_exists := TRUE;
            END IF;
        
            -- if next prescription process doesn't exist, then calculate start/end timestamps, 
            -- starting from previous current active prescription
            IF l_cpoe_process IS NULL
            THEN
                -- get next cpoe period, after the active current cpoe
                -- the start timestamp of next cpoe is the end timestamp of current active prescription process
                IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_dt_start      => l_ts_cpoe_end,
                                          o_dt_start      => l_ts_cpoe_next_start, -- is equal to l_ts_cpoe_end
                                          o_dt_end        => l_ts_cpoe_next_end, -- calculated value
                                          o_dt_refresh    => l_ts_cpoe_next_refresh,
                                          o_dt_next_presc => l_ts_cpoe_next_presc,
                                          o_error         => o_error) -- calculated value
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            -- at this point we already know the valid cpoe period (actual or new)
            o_proc_start   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_start, i_prof);
            o_proc_end     := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_end, i_prof);
            o_proc_refresh := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_refresh, i_prof);
            -- these represent the next cpoe period
            o_proc_next_start   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_next_start, i_prof);
            o_proc_next_end     := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_next_end, i_prof);
            o_proc_next_refresh := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_next_refresh, i_prof);
        
            -- check if all start timestamps fits in the cpoe periods
            FOR i IN i_draft_request.first .. i_draft_request.last
            LOOP
                -- set task boundary type
                l_task_req_list.extend;
                l_task_req_list(i) := t_rec_cpoe_task_create(i_task_type(i),
                                                             to_char(i_draft_request(i)),
                                                             set_task_bounds(i_lang               => i_lang,
                                                                             i_prof               => i_prof,
                                                                             i_task_type          => i_task_type(i),
                                                                             i_ts_task_start      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   i_dt_start(i),
                                                                                                                                   NULL),
                                                                             i_ts_task_end        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   i_dt_end(i),
                                                                                                                                   NULL),
                                                                             i_ts_cpoe_start      => l_ts_cpoe_start,
                                                                             i_ts_cpoe_end        => l_ts_cpoe_end,
                                                                             i_ts_cpoe_next_start => l_ts_cpoe_next_start,
                                                                             i_ts_cpoe_next_end   => l_ts_cpoe_next_end));
                -- set answer type
                IF task_out_of_cpoe_process(i_lang, i_prof, i_task_type(i)) = pk_alert_constant.g_yes
                THEN
                    l_out_of_cpoe_process := pk_alert_constant.g_yes;
                ELSIF l_task_req_list(i).flg_status = g_task_bound_curr_presc
                THEN
                    l_has_curr_presc_tasks := pk_alert_constant.g_yes;
                ELSIF l_task_req_list(i).flg_status = g_task_bound_next_presc
                THEN
                    l_has_next_presc_tasks := pk_alert_constant.g_yes;
                ELSIF l_task_req_list(i).flg_status = g_task_bound_out
                THEN
                    l_has_out_of_bounds := pk_alert_constant.g_yes;
                ELSE
                    -- if l_task_req_list(i).flg_status = g_task_bound_no_presc 
                    l_has_no_presc_tasks := pk_alert_constant.g_yes;
                END IF;
            END LOOP;
        
            IF l_out_of_cpoe_process = pk_alert_constant.g_yes
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_none;
            ELSIF l_has_no_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_curr_presc_tasks = pk_alert_constant.g_no
                  AND l_has_next_presc_tasks = pk_alert_constant.g_no
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_none; -- no warnings
            
                -- if a new prescription is needed and the professional category is not allowed to create it (including the next one)
            ELSIF l_can_create_presc = g_flg_inactive
                  AND (l_flg_cpoe_status <> g_flg_status_a OR
                  (l_flg_cpoe_status = g_flg_status_a AND NOT l_next_presc_exists AND
                  l_has_next_presc_tasks = pk_alert_constant.g_yes))
            THEN
                -- "new prescription creation" title 
                o_msg_title := pk_message.get_message(i_lang, 'CPOE_T015');
            
                -- "cannot activate tasks without creating a new prescription" message
                o_msg_body := '<b>' || pk_message.get_message(i_lang, 'CPOE_M026') || '</b>';
            
                o_flg_warning_type := g_flg_warning_cpoe_blocked; -- block tasks creation
            
                pk_alertlog.log_debug('get o_task_list cursor for warning message', g_package_name);
                OPEN o_task_list FOR
                    SELECT /*+opt_estimate(table task_list rows=1)*/
                     pk_cpoe.get_task_group_id(i_prof, tt.id_task_type) AS group_type_id,
                     pk_cpoe.get_task_group_name(i_lang, i_prof, tt.id_task_type) AS task_group_desc,
                     pk_cpoe.get_task_group_rank(i_prof, tt.id_task_type) AS task_group_rank,
                     tt.id_task_type AS id_task_type,
                     tt.id_target_task_type AS id_target_task_type,
                     task_list.id_request AS id_task,
                     tt.icon,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
                     pk_date_utils.date_char_hour_tsz(i_lang,
                                                      l_ts_current_timestamp,
                                                      i_prof.institution,
                                                      i_prof.software) AS time_desc,
                     pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                           l_ts_current_timestamp,
                                                           i_prof.institution,
                                                           i_prof.software) AS date_desc,
                     task_list.flg_status AS flg_task_boundary_status
                      FROM TABLE(l_task_req_list) task_list
                      JOIN cpoe_task_type tt
                        ON tt.id_task_type = task_list.id_task_type
                     WHERE l_flg_cpoe_status <> g_flg_status_a
                        OR (l_flg_cpoe_status = g_flg_status_a AND task_list.flg_status = g_task_bound_next_presc)
                     ORDER BY task_group_rank, tt.id_task_type;
            
                -- if all start timestamps fits in the new cpoe period (there is no active cpoe)
            ELSIF l_has_curr_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_next_presc_tasks = pk_alert_constant.g_no
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
                  AND l_flg_cpoe_status <> g_flg_status_a
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_new_cpoe; -- create new cpoe 
            
                -- NOT USED ANYMORE: evaluate if get_confirm_on_cpoe_creation feature is really needed
                ---- no active cpoe (confirm creation of new one)
                ---- "new prescription creation" message
                --o_msg_title := pk_message.get_message(i_lang, 'CPOE_T015');
                ---- "no active prescription found. in order to activate these tasks you will need to create a new prescription" message
                --o_msg_body         := '<b>' || pk_message.get_message(i_lang, 'CPOE_M012') || '</b><br><br>' ||
                --                      get_cpoe_message(i_lang         => i_lang,
                --                                       i_code_message => 'CPOE_M003',
                --                                       i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                --                                                                                          l_ts_cpoe_start,
                --                                                                                          i_prof.institution,
                --                                                                                          i_prof.software),
                --                                       i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                --                                                                                               l_ts_cpoe_start,
                --                                                                                               i_prof.institution,
                --                                                                                               i_prof.software),
                --                                       i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                --                                                                                          l_ts_cpoe_end,
                --                                                                                          i_prof.institution,
                --                                                                                          i_prof.software),
                --                                       i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                --                                                                                               l_ts_cpoe_end,
                --                                                                                               i_prof.institution,
                --                                                                                               i_prof.software));
                --o_flg_warning_type := g_flg_warning_no_cpoe;
                --
                --g_error := 'get o_task_list cursor for confirmation message';
                --pk_alertlog.log_debug(g_error, g_package_name);
                --IF NOT get_drafts_prompt_list(i_lang, i_prof, i_task_type, i_draft_request, o_task_list, o_error)
                --THEN
                --    RAISE l_exception;
                --END IF;
            
                -- if all start timestamps fits in the next cpoe period (with an active cpoe)
            ELSIF l_has_next_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
            THEN
                -- if next prescription already exists
                IF l_next_presc_exists
                THEN
                    pk_types.open_my_cursor(o_task_list);
                    o_flg_warning_type := g_flg_warning_none; -- no warnings
                ELSE
                    pk_types.open_my_cursor(o_task_list);
                    o_flg_warning_type := g_flg_warning_new_next_cpoe; -- create new next cpoe 
                END IF;
            
                -- if all start timestamps fits in the current active cpoe period
            ELSIF l_has_curr_presc_tasks = pk_alert_constant.g_yes
                  AND l_has_out_of_bounds = pk_alert_constant.g_no
                  AND l_flg_cpoe_status = g_flg_status_a
            THEN
                pk_types.open_my_cursor(o_task_list);
                o_flg_warning_type := g_flg_warning_none; -- no warnings                
            
                -- some task dates are out of bounds 
            ELSIF l_has_out_of_bounds = pk_alert_constant.g_yes
                  AND l_next_presc_exists = FALSE
            THEN
            
                IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M022',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                
                    -- if we have an active cpoe and we are able to prescribe in the next one, with out of boundary tasks that don't fit in any cpoe process
                ELSE
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M025',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                END IF;
            
                /*IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M005',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M004');
                ELSE
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M006',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M004');
                END IF;*/
            
                IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M022',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                
                    -- if we have an active cpoe and we are able to prescribe in the next one, with out of boundary tasks that don't fit in any cpoe process
                ELSE
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M025',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                END IF;
            
                o_flg_warning_type := g_flg_warning_out_of_bounds;
            ELSE
            
                -- "prescription period" message
                o_msg_title := pk_message.get_message(i_lang, 'CPOE_T016');
            
                -- message is different regarding the actual state of cpoe
                -- if we don't have an active cpoe and out of bound tasks don't fit in active cpoe (about to be created)
                IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M022',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                
                    -- if we have an active cpoe and we are able to prescribe in the next one, with out of boundary tasks that don't fit in any cpoe process
                ELSE
                    o_msg_body := '<b>' ||
                                  get_cpoe_message(i_lang         => i_lang,
                                                   i_code_message => 'CPOE_M025',
                                                   i_param1       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param2       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param3       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param4       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param5       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_start,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param6       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_start,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software),
                                                   i_param7       => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                      l_ts_cpoe_next_end,
                                                                                                      i_prof.institution,
                                                                                                      i_prof.software),
                                                   i_param8       => pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                                           l_ts_cpoe_next_end,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software)) ||
                                  '</b><br><br>' || pk_message.get_message(i_lang, 'CPOE_M023');
                END IF;
            
                -- out of boundary
                o_flg_warning_type := g_flg_warning_out_of_bounds;
            
                pk_alertlog.log_debug('get o_task_list cursor for warning message (boundary status = O)',
                                      g_package_name);
                OPEN o_task_list FOR
                    SELECT /*+opt_estimate(table task_list rows=1)*/
                     pk_cpoe.get_task_group_id(i_prof, tt.id_task_type) AS group_type_id,
                     pk_cpoe.get_task_group_name(i_lang, i_prof, tt.id_task_type) AS task_group_desc,
                     pk_cpoe.get_task_group_rank(i_prof, tt.id_task_type) AS task_group_rank,
                     tt.id_task_type AS id_task_type,
                     tt.id_target_task_type AS id_target_task_type,
                     task_list.id_request AS id_task,
                     tt.icon,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) AS prof,
                     pk_date_utils.date_char_hour_tsz(i_lang,
                                                      l_ts_current_timestamp,
                                                      i_prof.institution,
                                                      i_prof.software) AS time_desc,
                     pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                           l_ts_current_timestamp,
                                                           i_prof.institution,
                                                           i_prof.software) AS date_desc,
                     task_list.flg_status AS flg_task_boundary_status
                      FROM TABLE(l_task_req_list) task_list
                      JOIN cpoe_task_type tt
                        ON tt.id_task_type = task_list.id_task_type
                     WHERE task_list.flg_status = g_task_bound_out
                     ORDER BY task_group_rank, tt.id_task_type;
            
            END IF;
        
        ELSE
            -- g_cfg_cpoe_mode_simple or the task type does not need an active prescription: no validation needed here
            pk_types.open_my_cursor(o_task_list);
            o_flg_warning_type := g_flg_warning_none; -- no warnings
        
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
                                              'CHECK_DRAFTS_ACTIVATION',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END check_drafts_activation;

    FUNCTION request_task_to_next_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN table_number,
        i_task_request     IN table_number,
        o_new_task_request OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_ts_task_start      TIMESTAMP WITH LOCAL TIME ZONE;
        l_ts_task_end        TIMESTAMP WITH LOCAL TIME ZONE;
        l_draft_tasks        table_number;
        l_tbl_start_date_str table_varchar := table_varchar();
        l_tbl_end_date_str   table_varchar := table_varchar();
        l_start_date_str     VARCHAR2(30);
        l_end_date_str       VARCHAR2(30);
    
        l_task_list         pk_types.cursor_type;
        l_flg_warning_type  VARCHAR2(1 CHAR);
        l_msg_title         sys_message.desc_message%TYPE;
        l_msg_body          sys_message.desc_message%TYPE;
        l_proc_start        VARCHAR2(30);
        l_proc_end          VARCHAR2(30);
        l_proc_refresh      VARCHAR2(30);
        l_proc_next_start   VARCHAR2(30);
        l_proc_next_end     VARCHAR2(30);
        l_proc_next_refresh VARCHAR2(30);
    
        l_cpoe_process   cpoe_process.id_cpoe_process%TYPE;
        l_cpoe_process_c cpoe_process.id_cpoe_process%TYPE;
    
        PROCEDURE calc_dates_for_draft_tasks
        (
            o_ts_task_start OUT TIMESTAMP WITH LOCAL TIME ZONE,
            o_ts_task_end   OUT TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            l_flg_cpoe_mode        VARCHAR2(1 CHAR);
            l_flg_cpoe_status      VARCHAR2(1 CHAR);
            l_id_cpoe_process      cpoe_process.id_cpoe_process%TYPE;
            l_ts_cpoe_start        cpoe_process.dt_cpoe_proc_start%TYPE;
            l_ts_cpoe_end          cpoe_process.dt_cpoe_proc_end%TYPE;
            l_ts_cpoe_refresh      cpoe_process.dt_cpoe_refreshed%TYPE;
            l_ts_cpoe_next_start   cpoe_process.dt_cpoe_proc_start%TYPE;
            l_ts_cpoe_next_end     cpoe_process.dt_cpoe_proc_end%TYPE;
            l_id_professional      professional.id_professional%TYPE;
            l_ts_cpoe_next_refresh cpoe_process.dt_cpoe_refreshed%TYPE;
            l_ts_cpoe_next_presc   cpoe_process.dt_cpoe_proc_start%TYPE;
        BEGIN
        
            -- get cpoe mode to evaluate if the task should be copied with dates or not or not
            IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- only sync tasks with cpoe process when working in advanced mode
            IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
            THEN
            
                -- get last cpoe information to check if an active prescription exists
                IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_episode         => i_episode,
                                          o_cpoe_process    => l_id_cpoe_process,
                                          o_dt_start        => l_ts_cpoe_start,
                                          o_dt_end          => l_ts_cpoe_end,
                                          o_flg_status      => l_flg_cpoe_status,
                                          o_id_professional => l_id_professional,
                                          o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- if last cpoe is not active
                IF l_flg_cpoe_status <> g_flg_status_a
                THEN
                    -- no cpoe process created so far. system will check if all tasks have the proper start timestamps 
                    -- by checking the cpoe automatic creation periods
                    IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_dt_start      => NULL,
                                              o_dt_start      => l_ts_cpoe_start,
                                              o_dt_end        => l_ts_cpoe_end,
                                              o_dt_refresh    => l_ts_cpoe_refresh,
                                              o_dt_next_presc => l_ts_cpoe_next_presc,
                                              o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                -- get next prescription process
                get_next_presc_process(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => i_episode,
                                       o_cpoe_process => l_id_cpoe_process,
                                       o_dt_start     => l_ts_cpoe_next_start,
                                       o_dt_end       => l_ts_cpoe_next_end);
            
                -- if next prescription process doesn't exist, then calculate start/end timestamps, 
                -- starting from previous current active prescription
                IF l_id_cpoe_process IS NULL
                   AND check_next_presc_availability(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode) =
                   pk_alert_constant.g_yes
                THEN
                    -- get next cpoe period, after the active current cpoe
                    -- the start timestamp of next cpoe is the end timestamp of current active prescription process
                    IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_dt_start      => l_ts_cpoe_end,
                                              o_dt_start      => l_ts_cpoe_next_start, -- is equal to l_ts_cpoe_end
                                              o_dt_end        => l_ts_cpoe_next_end, -- calculated value
                                              o_dt_refresh    => l_ts_cpoe_next_refresh,
                                              o_dt_next_presc => l_ts_cpoe_next_presc,
                                              o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                o_ts_task_start := l_ts_cpoe_next_start;
                o_ts_task_end   := l_ts_cpoe_next_end - g_tstz_presc_limit_threshold;
            
            END IF;
        
        END calc_dates_for_draft_tasks;
    
    BEGIN
    
        g_error := 'request task to next prescription';
        pk_alertlog.log_debug(g_error, g_package_name);
        --raise_application_error(-20001,'Teste');
        -- get dates interval for draft tasks
        calc_dates_for_draft_tasks(l_ts_task_start, l_ts_task_end);
    
        -- copy tasks to draft
        copy_to_draft(i_lang             => i_lang,
                      i_prof             => i_prof,
                      i_episode          => i_episode,
                      i_task_type        => i_task_type,
                      i_task_request     => i_task_request,
                      i_auto_trans       => 'N',
                      i_dt_draft_start   => l_ts_task_start,
                      i_dt_draft_end     => l_ts_task_end,
                      o_new_task_request => l_draft_tasks);
    
        -- prepare collection with dates for draft tasks
        l_tbl_start_date_str.extend(l_draft_tasks.count);
        l_tbl_end_date_str.extend(l_draft_tasks.count);
        l_start_date_str := pk_date_utils.date_send_tsz(i_lang, l_ts_task_start, i_prof);
        l_end_date_str   := pk_date_utils.date_send_tsz(i_lang, l_ts_task_end, i_prof);
    
        FOR i IN 1 .. l_draft_tasks.count
        LOOP
            l_tbl_start_date_str(i) := l_start_date_str;
            l_tbl_end_date_str(i) := l_end_date_str;
        END LOOP;
    
        -- check if it's necessary to create the next prescription
        IF NOT check_drafts_activation(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_episode           => i_episode,
                                       i_task_type         => i_task_type,
                                       i_dt_start          => l_tbl_start_date_str,
                                       i_dt_end            => l_tbl_end_date_str,
                                       i_draft_request     => l_draft_tasks,
                                       o_task_list         => l_task_list,
                                       o_flg_warning_type  => l_flg_warning_type,
                                       o_msg_title         => l_msg_title,
                                       o_msg_body          => l_msg_body,
                                       o_proc_start        => l_proc_start,
                                       o_proc_end          => l_proc_end,
                                       o_proc_refresh      => l_proc_refresh,
                                       o_proc_next_start   => l_proc_next_start,
                                       o_proc_next_end     => l_proc_next_end,
                                       o_proc_next_refresh => l_proc_next_refresh,
                                       o_cpoe_process      => l_cpoe_process_c,
                                       o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- create next cpoe if necessary
        IF l_flg_warning_type = g_flg_warning_new_next_cpoe
        THEN
        
            IF NOT create_cpoe(i_lang              => i_lang,
                               i_prof              => i_prof,
                               i_episode           => i_episode,
                               i_proc_start        => l_proc_start,
                               i_proc_end          => l_proc_end,
                               i_proc_refresh      => l_proc_refresh,
                               i_proc_next_start   => l_proc_next_start,
                               i_proc_next_end     => l_proc_next_end,
                               i_proc_next_refresh => l_proc_next_refresh,
                               i_proc_type         => g_flg_warning_new_next_cpoe,
                               o_cpoe_process      => l_cpoe_process,
                               o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        -- activate draft tasks
        IF NOT activate_drafts(i_lang                => i_lang,
                               i_prof                => i_prof,
                               i_episode             => i_episode,
                               i_task_type           => i_task_type,
                               i_draft               => l_draft_tasks,
                               i_flg_conflict_answer => NULL,
                               i_cdr_call            => NULL,
                               o_new_task_request    => o_new_task_request,
                               o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_cpoe_process => l_cpoe_process_c,
                                     i_tasks_orig   => i_task_request,
                                     i_tasks_dest   => o_new_task_request,
                                     i_tasks_type   => i_task_type,
                                     i_flg_type     => 'AN',
                                     o_error        => o_error)
        THEN
            RAISE l_exception;
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
                                              'REQUEST_TASK_TO_NEXT_PRESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END request_task_to_next_presc;

    FUNCTION upd_into_rel_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN AS
        l_tbl_cpoe_p table_number;
    BEGIN
    
        SELECT a.id_cpoe_process
          BULK COLLECT
          INTO l_tbl_cpoe_p
          FROM cpoe_process a
         WHERE a.id_episode = i_episode
           AND a.flg_status NOT IN (g_flg_status_a, g_flg_status_n);
    
        DELETE FROM cpoe_tasks_relation a
         WHERE a.id_cpoe_process IN (SELECT t.column_value /*+opt_estimate (table t rows=1)*/
                                       FROM TABLE(l_tbl_cpoe_p) t);
    
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
                                              'INSERT_INTO_REL_TASKS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_into_rel_tasks;

    FUNCTION insert_into_rel_tasks
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_cpoe_process IN NUMBER,
        i_tasks_orig   IN table_number,
        i_tasks_dest   IN table_number,
        i_tasks_type   IN table_number,
        i_flg_type     IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        FOR i IN 1 .. i_tasks_orig.count
        LOOP
            IF i_tasks_orig(i) IS NOT NULL
               AND i_tasks_dest(i) IS NOT NULL
            THEN
                INSERT INTO cpoe_tasks_relation
                    (id_cpoe_process, id_task_orig, id_task_dest, id_task_type, flg_type)
                VALUES
                    (i_cpoe_process, i_tasks_orig(i), i_tasks_dest(i), i_tasks_type(i), i_flg_type);
            END IF;
        END LOOP;
    
        DELETE FROM cpoe_tasks_relation
         WHERE id_task_dest IS NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_INTO_REL_TASKS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END insert_into_rel_tasks;

    FUNCTION delete_from_rel_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tasks      IN table_number,
        i_tasks_type IN table_number,
        i_flg_draft  IN VARCHAR2 DEFAULT 'N',
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
        l_ret   NUMBER;
        l_ret_1 NUMBER;
        l_td    table_number;
        l_to    table_number;
        l_p     table_number;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        FOR i IN 1 .. i_tasks.count
        LOOP
        
            SELECT COUNT(*)
              INTO l_ret
              FROM cpoe_tasks_relation ctr
             WHERE (ctr.id_task_dest = i_tasks(i) OR ctr.id_task_orig = i_tasks(i))
               AND ctr.id_task_type = i_tasks_type(i);
        
            SELECT COUNT(*)
              INTO l_ret_1
              FROM cpoe_process_task a
             WHERE a.id_task_request = i_tasks(i)
               AND a.id_task_type = i_tasks_type(i);
        
            IF l_ret > 1
               AND l_ret_1 = 0
            THEN
                SELECT z.a, z.c
                  BULK COLLECT
                  INTO l_to, l_p
                  FROM (
                        
                        SELECT ctr.id_task_orig a, ctr.id_cpoe_process c
                          FROM cpoe_tasks_relation ctr
                         WHERE ctr.id_task_dest = i_tasks(i)
                           AND ctr.id_task_type = i_tasks_type(i)
                        UNION ALL
                        SELECT ctr.id_task_dest a, ctr.id_cpoe_process c
                          FROM cpoe_tasks_relation ctr
                         WHERE ctr.id_task_orig = i_tasks(i)
                           AND ctr.id_task_type = i_tasks_type(i)) z;
            
                SELECT DISTINCT column_value
                  BULK COLLECT
                  INTO l_td
                  FROM TABLE(l_to);
                IF l_td.count > 1
                THEN
                    IF NOT insert_into_rel_tasks(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_cpoe_process => l_p(1),
                                                 i_tasks_orig   => table_number(l_td(1)),
                                                 i_tasks_dest   => table_number(l_td(2)),
                                                 i_tasks_type   => table_number(i_tasks_type(i)),
                                                 i_flg_type     => 'NA',
                                                 o_error        => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            END IF;
        
            IF i_flg_draft = 'N'
            THEN
                DELETE FROM cpoe_tasks_relation ctr
                 WHERE (ctr.id_task_dest = i_tasks(i) OR ctr.id_task_orig = i_tasks(i))
                   AND ctr.id_task_type = i_tasks_type(i);
            ELSE
                DELETE FROM cpoe_tasks_relation ctr
                 WHERE (ctr.id_task_dest = i_tasks(i) OR ctr.id_task_orig = i_tasks(i))
                   AND ctr.id_task_type = i_tasks_type(i)
                   AND ctr.flg_type != 'REP';
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
                                              'DELETE_FROM_REL_TASKS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END delete_from_rel_tasks;

    FUNCTION activate_drafts_popup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_types IN table_number,
        o_msg        OUT sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exists_task_out     BOOLEAN := FALSE;
        l_not_exists_task_out BOOLEAN := FALSE;
        l_result              VARCHAR2(1 CHAR);
    BEGIN
    
        FOR i IN 1 .. i_task_types.count
        LOOP
            l_result := task_out_of_cpoe_process(i_lang => i_lang, i_prof => i_prof, i_task_type => i_task_types(i));
            IF l_result = pk_alert_constant.g_yes
            THEN
                l_exists_task_out := TRUE;
            ELSE
                l_not_exists_task_out := TRUE;
            END IF;
        
        END LOOP;
    
        IF l_not_exists_task_out
        THEN
            o_msg := pk_message.get_message(i_lang, i_code_mess => 'CPOE_M028');
        ELSE
            o_msg := pk_message.get_message(i_lang, i_code_mess => 'CPOE_M036');
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
                                              'ACTIVATE_DRAFTS_POPUP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END activate_drafts_popup;

    FUNCTION show_popup_epi_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_show_popup OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_profile profile_template.flg_profile%TYPE;
        l_epis_resp   NUMBER;
    BEGIN
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        l_epis_resp := pk_hand_off.get_prof_resp(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_episode       => i_episode,
                                                 i_flg_type      => pk_alert_constant.g_flg_doctor,
                                                 i_hand_off_type => NULL,
                                                 i_flg_profile   => NULL,
                                                 i_id_speciality => NULL);
    
        IF (l_epis_resp = -1 OR l_epis_resp IS NULL)
           AND l_flg_profile = pk_cpoe.g_flg_profile_template_student
        THEN
            o_show_popup := pk_alert_constant.g_yes;
        ELSE
            o_show_popup := pk_alert_constant.g_no;
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
                                              'SHOW_POPUP_EPI_RESP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END show_popup_epi_resp;

    /*FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_tbl_task_types  IN table_number,
        i_tbl_task_ids    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
    
        l_tbl_task_id_verify table_number := table_number();
        l_verify             VARCHAR2(1 CHAR);
    
        FUNCTION verify_task_type
        (
            id_task_type  NUMBER,
            tbl_task_type table_number
        ) RETURN VARCHAR2 AS
            l_found VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        BEGIN
        
            IF tbl_task_type IS NULL
               OR tbl_task_type.count = 0
            THEN
                RETURN l_found;
            END IF;
        
            FOR i IN 1 .. tbl_task_type.count
            LOOP
                IF tbl_task_type(i) = id_task_type
                THEN
                    l_found := pk_alert_constant.g_yes;
                    RETURN l_found;
                END IF;
            END LOOP;
        
            RETURN l_found;
        
        END verify_task_type;
    
        FUNCTION get_tasks_ids
        (
            id_task_type  NUMBER,
            tbl_task_type table_number,
            tbl_task_id   table_number
        ) RETURN table_number AS
            l_tbl   table_number := table_number();
            len_tbl NUMBER;
        BEGIN
            FOR i IN 1 .. tbl_task_type.count
            LOOP
                IF tbl_task_type(i) = id_task_type
                THEN
                    len_tbl := l_tbl.count;
                    l_tbl.extend;
                    l_tbl(len_tbl + 1) := tbl_task_id(i);
                END IF;
            END LOOP;
        
            RETURN l_tbl;
        EXCEPTION
            WHEN OTHERS THEN
                l_tbl := table_number();
                RETURN l_tbl;
        END get_tasks_ids;
    
        FUNCTION get_tasks_ids_v
        (
            id_task_type  NUMBER,
            tbl_task_type table_number,
            tbl_task_id   table_number
        ) RETURN table_varchar AS
            l_tbl   table_varchar := table_varchar();
            len_tbl NUMBER;
        BEGIN
            FOR i IN 1 .. tbl_task_type.count
            LOOP
                IF tbl_task_type(i) = id_task_type
                THEN
                    len_tbl := l_tbl.count;
                    l_tbl.extend;
                    l_tbl(len_tbl + 1) := tbl_task_id(i);
                END IF;
            END LOOP;
        
            RETURN l_tbl;
        EXCEPTION
            WHEN OTHERS THEN
                l_tbl := table_varchar();
                RETURN l_tbl;
        END get_tasks_ids_v;
    
    BEGIN
    
        IF i_tbl_task_types IS NULL
           OR i_tbl_task_ids IS NULL
           OR i_tbl_task_types.count = 0
           OR i_tbl_task_ids.count = 0
           OR i_tbl_task_types.count != i_tbl_task_ids.count
        THEN
            g_error := 'Problem in Task Types or Task Ids';
            RETURN FALSE;
        END IF;
    
        FOR i IN 1 .. i_tbl_task_types.count
        LOOP
            CASE i_tbl_task_types(i)
                WHEN g_task_type_monitorization THEN
                    NULL;
                WHEN g_task_type_positioning THEN
                    NULL;
                WHEN g_task_type_hidric THEN
                    NULL;
                WHEN g_task_type_diet THEN
                    NULL;
                WHEN g_task_type_procedure THEN
                
                    l_verify := verify_task_type(id_task_type  => i_tbl_task_types(i),
                                                 tbl_task_type => l_tbl_task_id_verify);
                
                    IF l_verify = pk_alert_constant.g_no
                    THEN
                    
                        l_tbl_task_id_verify.extend;
                        l_tbl_task_id_verify(i) := i_tbl_task_types(i);
                    
                        IF NOT pk_procedures_external_api_db.add_print_list_jobs(i_lang             => i_lang,
                                                                                 i_prof             => i_prof,
                                                                                 i_patient          => i_patient,
                                                                                 i_episode          => i_episode,
                                                                                 i_interv_presc_det => get_tasks_ids(id_task_type  => i_tbl_task_types(i),
                                                                                                                     tbl_task_type => i_tbl_task_types,
                                                                                                                     tbl_task_id   => i_tbl_task_ids),
                                                                                 i_print_arguments  => i_print_arguments,
                                                                                 o_print_list_job   => o_print_list_job,
                                                                                 o_error            => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                
                WHEN g_task_type_analysis THEN
                
                    l_verify := verify_task_type(id_task_type  => i_tbl_task_types(i),
                                                 tbl_task_type => l_tbl_task_id_verify);
                
                    IF l_verify = pk_alert_constant.g_no
                    THEN
                    
                        l_tbl_task_id_verify.extend;
                        l_tbl_task_id_verify(i) := i_tbl_task_types(i);
                    
                        IF NOT pk_lab_tests_external_api_db.add_print_list_jobs(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_patient          => i_patient,
                                                                                i_episode          => i_episode,
                                                                                i_analysis_req_det => get_tasks_ids(id_task_type  => i_tbl_task_types(i),
                                                                                                                    tbl_task_type => i_tbl_task_types,
                                                                                                                    tbl_task_id   => i_tbl_task_ids),
                                                                                i_print_arguments  => i_print_arguments,
                                                                                o_print_list_job   => o_print_list_job,
                                                                                o_error            => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                
                WHEN g_task_type_image_exam THEN
                    l_verify := verify_task_type(id_task_type  => i_tbl_task_types(i),
                                                 tbl_task_type => l_tbl_task_id_verify);
                
                    IF l_verify = pk_alert_constant.g_no
                    THEN
                    
                        l_tbl_task_id_verify.extend;
                        l_tbl_task_id_verify(i) := i_tbl_task_types(i);
                    
                        IF NOT pk_exams_external_api_db.add_print_list_jobs(i_lang            => i_lang,
                                                                            i_prof            => i_prof,
                                                                            i_patient         => i_patient,
                                                                            i_episode         => i_episode,
                                                                            i_exam_req_det    => get_tasks_ids(id_task_type  => i_tbl_task_types(i),
                                                                                                               tbl_task_type => i_tbl_task_types,
                                                                                                               tbl_task_id   => i_tbl_task_ids),
                                                                            i_print_arguments => i_print_arguments,
                                                                            o_print_list_job  => o_print_list_job,
                                                                            o_error           => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                WHEN g_task_type_other_exam THEN
                    l_verify := verify_task_type(id_task_type  => i_tbl_task_types(i),
                                                 tbl_task_type => l_tbl_task_id_verify);
                
                    IF l_verify = pk_alert_constant.g_no
                    THEN
                    
                        l_tbl_task_id_verify.extend;
                        l_tbl_task_id_verify(i) := i_tbl_task_types(i);
                    
                        IF NOT pk_exams_external_api_db.add_print_list_jobs(i_lang            => i_lang,
                                                                            i_prof            => i_prof,
                                                                            i_patient         => i_patient,
                                                                            i_episode         => i_episode,
                                                                            i_exam_req_det    => get_tasks_ids(id_task_type  => i_tbl_task_types(i),
                                                                                                               tbl_task_type => i_tbl_task_types,
                                                                                                               tbl_task_id   => i_tbl_task_ids),
                                                                            i_print_arguments => i_print_arguments,
                                                                            o_print_list_job  => o_print_list_job,
                                                                            o_error           => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                WHEN g_task_type_nursing THEN
                    NULL;
                WHEN g_task_type_medication THEN
                    l_verify := verify_task_type(id_task_type  => i_tbl_task_types(i),
                                                 tbl_task_type => l_tbl_task_id_verify);
                
                    IF l_verify = pk_alert_constant.g_no
                    THEN
                    
                        l_tbl_task_id_verify.extend;
                        l_tbl_task_id_verify(i) := i_tbl_task_types(i);
                    
                        IF NOT pk_api_pfh_in.add_print_list_jobs(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_patient                 => i_patient,
                                                                 i_episode                 => i_episode,
                                                                 i_id_presc                => get_tasks_ids_v(id_task_type  => i_tbl_task_types(i),
                                                                                                              tbl_task_type => i_tbl_task_types,
                                                                                                              tbl_task_id   => i_tbl_task_ids),
                                                                 i_json_list               => i_print_arguments,
                                                                 i_prescription_print_type => NULL,
                                                                 o_print_list_job          => o_print_list_job,
                                                                 o_error                   => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                WHEN g_task_type_com_order THEN
                    NULL;
                ELSE
                    NULL;
            END CASE;
        
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
                                              'SHOW_POPUP_EPI_RESP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END add_print_list_jobs;*/

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_tbl_task_types  IN table_number,
        i_tbl_task_ids    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
        l_context_data     table_clob;
        l_print_list_areas table_number;
    
    BEGIN
    
        IF i_tbl_task_types IS NULL
           OR i_tbl_task_ids IS NULL
           OR i_tbl_task_types.count = 0
           OR i_tbl_task_ids.count = 0
           OR i_tbl_task_types.count != i_tbl_task_ids.count
        THEN
            g_error := 'Problem in Task Types or Task Ids';
            RETURN FALSE;
        END IF;
    
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
    
        l_context_data.extend;
        l_print_list_areas.extend;
    
        SELECT table_clob(concatenate(ipd.column_value || '|'))
          INTO l_context_data
          FROM TABLE(i_tbl_task_ids) ipd;
    
        l_print_list_areas(1) := 15;
    
        -- call function to add job to the print list
        g_error := 'CALL PK_PRINT_LIST_DB.ADD_PRINT_JOBS';
        IF NOT pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_episode          => i_episode,
                                               i_print_list_areas => l_print_list_areas,
                                               i_context_data     => l_context_data,
                                               i_print_arguments  => i_print_arguments,
                                               o_print_list_jobs  => o_print_list_job,
                                               o_error            => o_error)
        THEN
            RAISE l_exception;
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
                                              'SHOW_POPUP_EPI_RESP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END add_print_list_jobs;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
    
        l_result t_rec_print_list_job := t_rec_print_list_job();
    
        l_print_list_area print_list_job.id_print_list_area%TYPE;
        l_count           NUMBER(24);
    
    BEGIN
    
        g_error := 'GETTING CONTEXT DATA AND AREA OF THIS PRINT LIST JOB';
        WITH t AS
         (SELECT v.context_data, v.id_print_list_area
            FROM v_print_list_context_data v
           WHERE v.id_print_list_job = i_id_print_list_job)
        SELECT length(regexp_replace(context_data, '[^|]')) / length('|') count_context_data, id_print_list_area
          INTO l_count, l_print_list_area
          FROM t;
    
        l_result.id_print_list_job := i_id_print_list_job;
        l_result.title_desc        := pk_translation.get_translation(i_lang, 'REPORTS.CODE_REPORTS_TITLE.211');
    
        IF l_count = 1
        THEN
            l_result.subtitle_desc := l_count || ' ' ||
                                      lower(pk_translation.get_translation(i_lang, 'REPORTS.CODE_REPORTS_TITLE.211'));
        ELSE
            l_result.subtitle_desc := l_count || ' ' ||
                                      lower(pk_translation.get_translation(i_lang, 'REPORTS.CODE_REPORTS.7'));
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_get_print_job_info;

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number IS
    
        l_result table_number := table_number();
    
    BEGIN
    
        g_error := 'GETTING SIMMILAR PRINTING LIST JOBS | PRINT_JOB_CONTEXT_DATA - ' || i_print_job_context_data;
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v.id_print_list_job
                  FROM v_print_list_context_data v
                  JOIN TABLE(CAST(i_tbl_print_list_jobs AS table_number)) t
                    ON t.column_value = v.id_print_list_job
                 WHERE dbms_lob.instr(v.context_data, i_print_job_context_data) > 0) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_compare_print_jobs;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_next_cpoe_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_dt_start OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end   OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_flg_cpoe_mode      VARCHAR2(1 CHAR);
        l_flg_cpoe_status    VARCHAR2(1 CHAR);
        l_cpoe_process       cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start      cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end        cpoe_process.dt_cpoe_proc_end%TYPE;
        l_id_professional    professional.id_professional%TYPE;
        l_ts_cpoe_refresh    cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_ts_cpoe_next_presc cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
    
    BEGIN
        g_error := 'get next cpoe information';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
            -- get last cpoe information to check if an active prescription exists
            IF NOT get_last_cpoe_info(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      o_cpoe_process    => l_cpoe_process,
                                      o_dt_start        => l_ts_cpoe_start,
                                      o_dt_end          => l_ts_cpoe_end,
                                      o_flg_status      => l_flg_cpoe_status,
                                      o_id_professional => l_id_professional,
                                      o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- get next prescription process
            get_next_presc_process(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   o_cpoe_process => l_cpoe_process,
                                   o_dt_start     => o_dt_start,
                                   o_dt_end       => o_dt_end);
        
            -- if next prescription process doesn't exist, then calculate start/end timestamps, 
            -- starting from previous current active prescription
            IF l_cpoe_process IS NULL
               AND check_next_presc_availability(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode) =
               pk_alert_constant.g_yes
            THEN
                -- no cpoe process created so far. system will check if all tasks have the proper start timestamps 
                -- by checking the cpoe automatic creation periods
                IF NOT get_next_cpoe_info(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_dt_start      => l_ts_cpoe_end,
                                          o_dt_start      => o_dt_start,
                                          o_dt_end        => o_dt_end,
                                          o_dt_refresh    => l_ts_cpoe_refresh,
                                          o_dt_next_presc => l_ts_cpoe_next_presc,
                                          o_error         => o_error)
                THEN
                    RAISE l_exception;
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
                                              'GET_NEXT_CPOE_DATE',
                                              o_error);
            RETURN FALSE;
    END get_next_cpoe_date;

    PROCEDURE init_params_history
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
    
        l_episode episode.id_episode%TYPE;
    
        o_error t_error_out;
    
    BEGIN
    
        l_episode := i_context_ids(5);
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('i_episode', l_episode);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_id := l_lang;
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
                                              i_package  => 'PK_CPOE',
                                              i_function => 'INIT_PARAMS_HISTORY',
                                              o_error    => o_error);
    END init_params_history;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_process_end_date_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'get_process_end_date_per_task';
        SELECT cp.dt_cpoe_proc_end
          INTO o_dt_end
          FROM cpoe_process_task cpt
          JOIN cpoe_process cp
            ON cp.id_cpoe_process = cpt.id_cpoe_process
         WHERE cpt.id_task_request = i_id_task_request
           AND cpt.id_task_type = i_id_task_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_error('get_process_end_date_per_task: ' || i_id_task_request || ', ' || i_id_task_type);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCESS_END_DATE_PER_TASK',
                                              o_error);
            RETURN FALSE;
    END get_process_end_date_per_task;

    FUNCTION get_process_status_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_status cpoe_process.flg_status%TYPE;
    
    BEGIN
    
        SELECT cp.flg_status
          INTO l_status
          FROM cpoe_process_task cpt
          JOIN cpoe_process cp
            ON cp.id_cpoe_process = cpt.id_cpoe_process
         WHERE cpt.id_task_request = i_id_task_request
           AND cpt.id_task_type = i_id_task_type;
    
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_process_status_per_task;

    FUNCTION check_next_presc_can_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 AS
        l_ret         VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_dt_end_cpoe cpoe_process.dt_cpoe_proc_end%TYPE;
    
    BEGIN
    
        SELECT a.dt_cpoe_proc_end
          INTO l_dt_end_cpoe
          FROM cpoe_process a
         WHERE a.id_episode = i_episode
           AND a.flg_status = pk_cpoe.g_task_filter_active;
    
        IF SYSDATE + 1 < l_dt_end_cpoe
        THEN
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_yes;
    END check_next_presc_can_req;

    FUNCTION get_special_create_popup
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN NUMBER,
        i_task_type IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_mode      OUT VARCHAR2,
        o_title     OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_btn1      OUT VARCHAR2,
        o_btn2      OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_count         NUMBER(24);
    
        l_final_day_date cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_cpoe_process  cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end   cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_init_planning  TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_professional professional.id_professional%TYPE;
        l_flg_cpoe_status cpoe_process.flg_status%TYPE;
        l_planning_period cpoe_period.planning_period%TYPE;
        l_expire_time     cpoe_period.expire_time%TYPE;
    
        l_hour   NUMBER;
        l_minute NUMBER;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        o_btn1 := pk_message.get_message(i_lang, 'CPOE_M044');
        o_btn2 := pk_message.get_message(i_lang, 'CPOE_M045');
    
        l_current_timestamp := pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, SYSDATE);
    
        SELECT COUNT(*)
          INTO l_count
          FROM cpoe_episode a
         WHERE a.id_episode = i_episode
           AND a.flg_type = 'SP';
    
        IF l_count > 0
        THEN
            o_flg_show := pk_alert_constant.g_no;
            RETURN TRUE;
        END IF;
    
        IF NOT get_cpoe_mode(i_lang, i_prof, i_episode, l_flg_cpoe_mode, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_simple
        THEN
            o_flg_show := pk_alert_constant.g_no;
            RETURN TRUE;
        END IF;
    
        IF l_flg_cpoe_mode = g_cfg_cpoe_mode_advanced
        THEN
        
            -- get last cpoe information
            IF NOT get_last_cpoe_info(i_lang,
                                      i_prof,
                                      i_episode,
                                      l_cpoe_process,
                                      l_ts_cpoe_start,
                                      l_ts_cpoe_end,
                                      l_flg_cpoe_status,
                                      l_id_professional,
                                      o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_flg_cpoe_status IN (pk_cpoe.g_flg_status_n, pk_cpoe.g_flg_status_a)
               AND l_cpoe_process IS NOT NULL
            THEN
                o_flg_show := pk_alert_constant.g_no;
                RETURN TRUE;
            END IF;
        
            IF task_out_of_cpoe_process(i_lang, i_prof, i_task_type(1)) = pk_alert_constant.g_yes
            THEN
                o_flg_show := pk_alert_constant.g_no;
                RETURN TRUE;
            END IF;
        
            l_planning_period := get_cpoe_planning_period(i_lang, i_prof, i_episode);
            l_expire_time     := get_cpoe_expire_time(i_lang, i_prof, i_episode);
        
            l_final_day_date := pk_date_utils.get_string_tstz(i_lang,
                                                              i_prof,
                                                              to_char(l_current_timestamp, 'YYYYMMDD') ||
                                                              substr(l_expire_time, 1, 2) || substr(l_expire_time, 4, 2) || '00',
                                                              NULL);
        
            l_hour   := extract(hour FROM(l_final_day_date - l_current_timestamp));
            l_minute := extract(minute FROM(l_final_day_date - l_current_timestamp));
        
            IF l_planning_period = 0
               AND pk_date_utils.compare_dates_tsz(i_prof,
                                                   l_current_timestamp,
                                                   pk_date_utils.add_to_ltstz(l_final_day_date,
                                                                              -g_hour_without_planning_period,
                                                                              'HOUR')) = 'G'
               AND l_current_timestamp < l_final_day_date
            THEN
                o_flg_show := pk_alert_constant.g_yes;
                o_mode     := 'S';
            
                o_title := pk_message.get_message(i_lang, 'CPOE_M046');
                o_msg := get_cpoe_message(i_lang         => i_lang,
                                          i_code_message => 'CPOE_M047',
                                          i_param1       => pk_date_utils.date_char_tsz(i_lang,
                                                                                        l_final_day_date,
                                                                                        i_prof.institution,
                                                                                        i_prof.software),
                                          i_param2       => CASE
                                                                WHEN l_hour = 0 THEN
                                                                 l_minute || ' ' || pk_message.get_message(i_lang, 'SCH_T099')
                                                                ELSE
                                                                 l_hour || ' ' || pk_message.get_message(i_lang, 'COMMON_M123') || ' ' ||
                                                                 pk_message.get_message(i_lang, 'SCH_T103') || ' ' || l_minute || ' ' ||
                                                                 pk_message.get_message(i_lang, 'SCH_T099')
                                                            END);
            
                RETURN TRUE;
            
            END IF;
        
            l_dt_init_planning := pk_date_utils.get_string_tstz(i_lang,
                                                                i_prof,
                                                                to_char(l_current_timestamp, 'YYYYMMDD') ||
                                                                substr(l_expire_time, 1, 2) ||
                                                                substr(l_expire_time, 4, 2) || '00',
                                                                NULL);
        
            IF pk_date_utils.add_to_ltstz(l_dt_init_planning, -l_planning_period, 'HOUR') < l_current_timestamp
               AND l_current_timestamp < l_final_day_date
            THEN
                o_flg_show := pk_alert_constant.g_yes;
                o_mode     := 'C';
            
                l_hour   := extract(hour FROM(l_final_day_date - l_current_timestamp));
                l_minute := extract(minute FROM(l_final_day_date - l_current_timestamp));
            
                o_title := pk_message.get_message(i_lang, 'CPOE_M048');
                o_msg := get_cpoe_message(i_lang         => i_lang,
                                          i_code_message => 'CPOE_M049',
                                          i_param1       => l_expire_time,
                                          i_param2       => CASE
                                                                WHEN l_hour = 0 THEN
                                                                 l_minute || ' ' || pk_message.get_message(i_lang, 'SCH_T099')
                                                                ELSE
                                                                 l_hour || ' ' || pk_message.get_message(i_lang, 'COMMON_M123') || ' ' ||
                                                                 pk_message.get_message(i_lang, 'SCH_T103') || ' ' || l_minute || ' ' ||
                                                                 pk_message.get_message(i_lang, 'SCH_T099')
                                                            END,
                                          i_param3       => pk_date_utils.date_char_tsz(i_lang,
                                                                                        l_final_day_date + 1,
                                                                                        i_prof.institution,
                                                                                        i_prof.software));
                RETURN TRUE;
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        
        ELSE
            NULL;
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
                                              'GET_SPECIAL_CREATE_POPUP',
                                              o_error);
            RETURN FALSE;
    END get_special_create_popup;

    FUNCTION get_next_special_create_popup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN NUMBER,
        o_flg_show OUT VARCHAR2,
        o_mode     OUT VARCHAR2,
        o_title    OUT VARCHAR2,
        o_msg      OUT VARCHAR2,
        o_btn1     OUT VARCHAR2,
        o_btn2     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_count         NUMBER(24);
    
        l_final_day_date cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_cpoe_process  cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end   cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_current_timestamp TIMESTAMP WITH TIME ZONE;
    
        l_id_professional professional.id_professional%TYPE;
        l_flg_cpoe_status cpoe_process.flg_status%TYPE;
        l_planning_period cpoe_period.planning_period%TYPE;
        l_expire_time     cpoe_period.expire_time%TYPE;
    
        l_hour   NUMBER;
        l_minute NUMBER;
    
        l_can_presc VARCHAR2(1 CHAR);
    
        l_exception EXCEPTION;
    
    BEGIN
    
        l_can_presc := check_next_presc_can_req(i_lang, i_prof, i_episode);
    
        IF l_can_presc = pk_alert_constant.g_no
        THEN
        
            l_current_timestamp := pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, SYSDATE);
            l_planning_period   := get_cpoe_planning_period(i_lang, i_prof, i_episode);
            l_expire_time       := get_cpoe_expire_time(i_lang, i_prof, i_episode);
        
            l_final_day_date := pk_date_utils.get_string_tstz(i_lang,
                                                              i_prof,
                                                              to_char(l_current_timestamp, 'YYYYMMDD') ||
                                                              substr(l_expire_time, 1, 2) || substr(l_expire_time, 4, 2) || '00',
                                                              NULL);
        
            --l_final_day_date := pk_date_utils.add_to_ltstz(l_final_day_date, l_planning_period, 'HOUR');
        
            l_hour   := extract(hour FROM(l_final_day_date - l_current_timestamp));
            l_minute := extract(minute FROM(l_final_day_date - l_current_timestamp));
        
            o_flg_show := pk_alert_constant.g_yes;
            o_mode     := 'S';
            o_title    := pk_message.get_message(i_lang, 'PRESC_WARNING_T001');
            o_msg := get_cpoe_message(i_lang         => i_lang,
                                      i_code_message => 'CPOE_M050',
                                      i_param1       => CASE
                                                            WHEN l_hour = 0 THEN
                                                             l_minute || ' ' || pk_message.get_message(i_lang, 'SCH_T099')
                                                            ELSE
                                                             l_hour || ' ' || pk_message.get_message(i_lang, 'COMMON_M123') || ' ' ||
                                                             pk_message.get_message(i_lang, 'SCH_T103') || ' ' || l_minute || ' ' ||
                                                             pk_message.get_message(i_lang, 'SCH_T099')
                                                        END);
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
                                              'GET_NEXT_SPECIAL_CREATE_POPUP',
                                              o_error);
            RETURN FALSE;
    END get_next_special_create_popup;

    FUNCTION set_special_create_popup
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_option  IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        INSERT INTO cpoe_episode
            (id_episode, flg_type, num_aux, varchar_aux)
        VALUES
            (i_episode, 'SP', NULL, i_option);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SPECIAL_CREATE_POPUP',
                                              o_error);
            RETURN FALSE;
    END set_special_create_popup;

    FUNCTION get_cpoe_expire_time
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 AS
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_expire_time      cpoe_period.expire_time%TYPE;
        l_error            t_error_out;
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_episode.get_epis_dep_clin_serv(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_episode          => i_episode,
                                                 o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                 o_error            => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        SELECT z.expire_time
          INTO l_expire_time
          FROM (SELECT cp.expire_time,
                       row_number() over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS rn
                  FROM cpoe_period cp
                 WHERE cp.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND cp.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                   AND (cp.id_dep_clin_serv = l_id_dep_clin_serv OR cp.id_dep_clin_serv IS NULL)) z
         WHERE z.rn = 1;
        RETURN l_expire_time;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cpoe_expire_time;

    FUNCTION get_cpoe_planning_period
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN NUMBER AS
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_planning         cpoe_period.planning_period%TYPE;
        l_error            t_error_out;
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_episode.get_epis_dep_clin_serv(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_episode          => i_episode,
                                                 o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                 o_error            => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        SELECT z.planning_period
          INTO l_planning
          FROM (SELECT cp.planning_period,
                       row_number() over(ORDER BY cp.id_institution DESC, cp.id_software DESC, cp.id_dep_clin_serv DESC NULLS LAST) AS rn
                  FROM cpoe_period cp
                 WHERE cp.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND cp.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                   AND (cp.id_dep_clin_serv = l_id_dep_clin_serv OR cp.id_dep_clin_serv IS NULL)) z
         WHERE z.rn = 1;
        RETURN l_planning;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_cpoe_planning_period;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);

END pk_cpoe;
/
