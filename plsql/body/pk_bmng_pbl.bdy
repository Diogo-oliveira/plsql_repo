/*-- Last Change Revision: $Rev: 2026833 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_bmng_pbl IS

    /********************************************************************************************
    * Returns number os blocked beds and NCH houres for an institution or list of departments
    *
    * @param IN   i_lang                Language ID
    * @param IN   i_prof                Professional ID
    * @param IN   i_department          Department ID -- either "i_department" or "i_institution" must be filled otherwise function returns FALSE
    * @param IN   i_institution         Institution ID
    * @param IN   i_dt_request          Requested Date
    
    * @param OUT  o_dep_info            Output cursor containing the id_department, beds_blocked and nch_total
    * @param OUT  o_default_dep_nch     Output variable with default value of NCH of each department in current institution
    *
    * @return     Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_total_department_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_department  IN table_number, -- either "i_department" or "i_institution" must be filled otherwise function returns FALSE
        i_institution IN institution.id_institution%TYPE,
        i_dt_request  IN bmng_action.dt_begin_action%TYPE,
        o_dep_info    OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BMNG.GET_TOTAL_DEPARTMENT_INFO';
        IF NOT pk_bmng.get_total_department_info(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_department  => i_department,
                                                 i_institution => i_institution,
                                                 i_dt_request  => i_dt_request,
                                                 o_dep_info    => o_dep_info,
                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_TOTAL_DEPARTMENT_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_dep_info);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns all allocations for a specific department to specified day
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID -- either "i_patient" or "i_department" must be filled otherwise function returns FALSE
    * @param IN   i_department   Department ID
    * @param IN   i_dt_request   Requested Date
    *    
    * @param OUT  o_pat_info      Output cursor containing the id_patient, id_department and nch_total
    * @param OUT  o_def_nch_value Output variable with default value of NCH of each patient in current institution
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_patients_nch
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number, -- either "i_patient" or "i_department" must be filled otherwise function returns FALSE
        i_department    IN department.id_department%TYPE,
        i_dt_request    IN bmng_action.dt_begin_action%TYPE, -- not allowed nulls
        o_pat_info      OUT NOCOPY pk_types.cursor_type,
        o_def_nch_value OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BMNG.GET_PATIENTS_NCH';
        IF NOT pk_bmng.get_patients_nch(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_episode       => i_episode,
                                        i_department    => i_department,
                                        i_dt_request    => i_dt_request,
                                        o_pat_info      => o_pat_info,
                                        o_def_nch_value => o_def_nch_value,
                                        o_error         => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_PATIENTS_NCH',
                                              o_error);
            pk_types.open_my_cursor(o_pat_info);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns all allocations for a specific department where discharge sched end date is greater
    * than requested date
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID -- either "i_patient" or "i_department" must be filled otherwise function returns FALSE
    * @param IN   i_department   Department ID
    * @param IN   i_dt_request   Requested Date
    
    * @param OUT  o_alloc_list     Output cursor containing the id_patient, id_department and nch_total
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_future_allocations_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_department  IN table_number, -- either "i_department" or "i_institution" must be filled otherwise function returns FALSE
        i_institution IN institution.id_institution%TYPE,
        i_dt_request  IN bmng_action.dt_begin_action%TYPE,
        o_alloc_list  OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_BMNG.GET_FUTURE_ALLOCATIONS_LIST';
        IF NOT pk_bmng.get_future_allocations_list(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_department  => i_department,
                                                   i_institution => i_institution,
                                                   i_dt_request  => i_dt_request,
                                                   o_alloc_list  => o_alloc_list,
                                                   o_error       => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_FUTURE_ALLOCATIONS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_alloc_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns all allocations for a specific department to specified day
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID -- either "i_patient" or "i_department" must be filled otherwise function returns FALSE
    * @param IN   i_department   Department ID
    * @param IN   i_dt_request   Requested Date
    
    * @param OUT  o_pat_info     Output cursor containing the id_patient, id_department and nch_total
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_date_allocations
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_department      IN table_number, -- either "i_department" or "i_institution" must be filled otherwise function returns FALSE
        i_institution     IN institution.id_institution%TYPE,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_effective_alloc OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_BMNG.GET_DATE_ALLOCATIONS';
        IF NOT pk_bmng.get_date_allocations(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_department      => i_department,
                                            i_institution     => i_institution,
                                            i_dt_begin        => i_dt_begin,
                                            i_dt_end          => i_dt_end,
                                            o_effective_alloc => o_effective_alloc,
                                            o_error           => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_DATE_ALLOCATIONS',
                                              o_error);
            pk_types.open_my_cursor(o_effective_alloc);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get total ammount of NCH hours for a department, in a certain date.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_dt           Date to check for the available NCH hours.
    * @param IN   i_dep           Department ID   
    *
    * @param OUT  o_nch             Total ammount of NCH hours available for the provided department.
    * @param OUT  o_error        
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Ricardo Nuno Almeida
    * @version                  2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_nch_total_occupation
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dt    IN VARCHAR2,
        i_dep   IN department.id_department%TYPE,
        o_nch   OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_bmng_core.get_nch_service_level(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_department => i_dep,
                                                  i_dt_request => i_dt,
                                                  o_nch_level  => o_nch,
                                                  o_error      => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BEDS_SERVICE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_nch_total_occupation;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_dt_begin          Interval begin date (nullable)
    * @param IN   i_dt_end            Interval end date (nullable)
    *
    * @param OUT  o_intervals         Output cursor containing the intervals
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  2.5.0.5
    * @since                    29/07/2009
    ********************************************************************************************/
    FUNCTION get_bmng_nch_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN department.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_request_date      IN bmng_action.dt_begin_action%TYPE,
        o_intervals         OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_bmng_core.get_bmng_intervals(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_flg_target_action => i_flg_target_action,
                                               i_department        => i_department,
                                               i_request_type      => i_request_type,
                                               i_request_date      => i_request_date,
                                               i_origin_action     => pk_bmng_constant.g_bmng_intervals_orig_act_n, -- only NCH
                                               o_intervals         => o_intervals,
                                               o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_intervals);
            RETURN FALSE;
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
                                              'GET_BMNG_NCH_INTERVALS',
                                              o_error);
            pk_types.open_my_cursor(o_intervals);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * For a provided episode, loads all related BMNG actions and updates them.
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_epis              ALERT ID of the episode to check
    * @param IN   i_transaction_id    remote transaction identifier
    *
    * @param OUT  o_error         
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Ricardo Nuno Almeida
    * @version                  2.5.0.5
    * @since                    30/07/2009
    ********************************************************************************************/
    FUNCTION set_bmng_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.set_bmng_discharge(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_epis           => i_epis,
                                          i_transaction_id => l_transaction_id,
                                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'SET_BMNG_DISCHARGE',
                                              o_error);
        
            RETURN FALSE;
    END set_bmng_discharge;

    /**********************************************************************************************
    * SET_MATCH_BMNG                         For a provided episode, match it to other episode.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier
    * @param i_transaction_id                remote transaction identifier
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Luís Maia
    * @version                  2.5.0.7.6
    * @since                    07/01/2009
    ********************************************************************************************/
    FUNCTION set_match_bmng
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_temp   IN episode.id_episode%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_patient_temp   IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL PK_BMNG.SET_MATCH_BMNG';
        IF NOT pk_bmng.set_match_bmng(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_episode_temp   => i_episode_temp,
                                      i_episode        => i_episode,
                                      i_patient        => i_patient,
                                      i_patient_temp   => i_patient_temp,
                                      i_transaction_id => l_transaction_id,
                                      o_error          => o_error)
        THEN
            RETURN FALSE;
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
                                              'SET_MATCH_BMNG',
                                              o_error);
        
            RETURN FALSE;
    END set_match_bmng;

    /********************************************************************************************************************************************
    * SET_BED_MANAGEMENT                  Function that update an bed allocation information if that allocation exists, otherwise create one new bed allocation
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BMNG_ACTION            ARRAY of Bed management action identifier
    * @param  I_ID_DEPARTMENT             ARRAY of Department identifier
    * @param  I_ID_ROOM                   ARRAY of Room identifier
    * @param  I_ID_BED                    ARRAY of Bed identifier
    * @param  I_ID_BMNG_REASON            ARRAY of Reason identifier associated with current action
    * @param  I_ID_BMNG_ALLOCATION_BED    ARRAY of Bed management allocation identifier that should be updated or created in this function
    * @param  I_FLG_TARGET_ACTION         Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS                Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_NCH_CAPACITY              ARRAY of NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES              ARRAY of Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION           ARRAY of STRINGS correspondent to dates in which these action start counting
    * @param  I_DT_END_ACTION             ARRAY of STRINGS correspondent to dates in which these action became outdated
    * @param  I_ID_EPISODE                ARRAY of Episode identifier
    * @param  I_ID_PATIENT                ARRAY of Patient identifier
    * @param  I_NCH_HOURS                 Number of NCH associated with current allocation
    * @param  I_FLG_ALLOCATION_NCH        STRINGS informing if this NCH information is definitive or automatically updated with NCH_LEVEL information
    * @param  I_DESC_BED                  Description associated with this bed
    * @param  I_ID_BED_TYPE               ARRAY of Bed type identifier of this bed
    * @param  I_DT_DICHARGE_SCHEDULE      Episode expected discharge
    * @param  I_FLG_ORIGIN_ACTION_UX      Type of action: FLAG defined in flash layer
    * @param  i_transaction_id            remote transaction identifier
    * @param  O_ID_BMNG_ALLOCATION_BED    Return allocation identifier if one patient is allocated to a new bed
    * @param  O_BED_ALLOCATION            Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param  O_EXCEPTION_INFO            Error message to be displayed to the user. 
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TARGET_ACTION         {*} 'S'- Service {*} 'R'- Room {*} 'B'- Bed
    * @value  I_FLG_STATUS                {*} 'A'- Active {*} 'C'- Cancelled {*} 'O'- Outdated
    * @value  I_FLG_ALLOCATION_NCH        {*} 'D'- Definitive {*} 'U'- Updatable
    * @value  I_FLG_ORIGIN_ACTION_UX      {*} 'B'-  BLOCK
    *                                     {*} 'U'-  UNBLOCK
    *                                     {*} 'V'-  FREE
    *                                     {*} 'O'-  OCCUPY (desreservar)
    *                                     {*} 'T'-  OCCUPY TEMPORARY BED (allocate / re-allocate)
    *                                     {*} 'P'-  OCCUPY DEFINITIVE BED (allocate / re-allocate)
    *                                     {*} 'S'-  SCHEDULE
    *                                     {*} 'R'-  RESERVE
    *                                     {*} 'D'-  DIRTY
    *                                     {*} 'C'-  CONTAMINED
    *                                     {*} 'I'-  CLEANING IN PROCESS
    *                                     {*} 'L'-  CLEANING CONCLUDED
    *                                     {*} 'E'-  EDIT BED ASSIGNMENT
    *                                     {*} 'ND'- UPDATE NCH PATIENT (DIRECTLY IN GRID)
    *                                     {*} 'NT'- NCH TOOLS
    *                                     {*} 'BT'- BLOCK TOOLS
    *                                     {*} 'UT'- UNBLOCK TOOLS
    * 
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   23-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_bed_management
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_bmng_action         IN table_number,
        i_id_department          IN table_number,
        i_id_room                IN table_number,
        i_id_bed                 IN table_number,
        i_id_bmng_reason         IN table_number,
        i_id_bmng_allocation_bed IN table_number,
        i_flg_target_action      IN bmng_action.flg_target_action%TYPE,
        i_flg_status             IN bmng_action.flg_status%TYPE,
        i_nch_capacity           IN table_number,
        i_action_notes           IN table_varchar,
        i_dt_begin_action        IN table_varchar,
        i_dt_end_action          IN table_varchar,
        i_id_episode             IN table_number,
        i_id_patient             IN table_number,
        i_nch_hours              IN epis_nch.nch_value%TYPE,
        i_flg_allocation_nch     IN epis_nch.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_id_bed_type            IN table_number,
        i_dt_discharge_schedule  IN VARCHAR2,
        i_flg_hour_origin        IN VARCHAR2 DEFAULT 'DH',
        i_bed_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_origin_action_ux   IN VARCHAR2,
        i_reason_notes           IN epis_nch.reason_notes%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_dt_creation            IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL TO FUNCTION PK_BMNG.SET_BED_MANAGEMENT';
        IF NOT pk_bmng.set_bed_management(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_bmng_action         => i_id_bmng_action,
                                          i_id_department          => i_id_department,
                                          i_id_room                => i_id_room,
                                          i_id_bed                 => i_id_bed,
                                          i_id_bmng_reason         => i_id_bmng_reason,
                                          i_id_bmng_allocation_bed => i_id_bmng_allocation_bed,
                                          i_flg_target_action      => i_flg_target_action,
                                          i_flg_status             => i_flg_status,
                                          i_nch_capacity           => i_nch_capacity,
                                          i_action_notes           => i_action_notes,
                                          i_dt_begin_action        => i_dt_begin_action,
                                          i_dt_end_action          => i_dt_end_action,
                                          i_id_episode             => i_id_episode,
                                          i_id_patient             => i_id_patient,
                                          i_nch_hours              => i_nch_hours,
                                          i_flg_allocation_nch     => i_flg_allocation_nch,
                                          i_desc_bed               => i_desc_bed,
                                          i_id_bed_type            => i_id_bed_type,
                                          i_dt_discharge_schedule  => i_dt_discharge_schedule,
                                          i_flg_hour_origin        => i_flg_hour_origin,
                                          i_id_bed_dep_clin_serv   => i_bed_dep_clin_serv,
                                          i_flg_origin_action_ux   => i_flg_origin_action_ux,
                                          i_reason_notes           => i_reason_notes,
                                          i_transaction_id         => l_transaction_id,
                                          i_dt_creation            => i_dt_creation,
                                          o_id_bmng_allocation_bed => o_id_bmng_allocation_bed,
                                          o_id_bed                 => o_id_bed,
                                          o_bed_allocation         => o_bed_allocation,
                                          o_exception_info         => o_exception_info,
                                          o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_MANAGEMENT',
                                              o_error);
            RETURN FALSE;
    END set_bed_management;

    /********************************************************************************************************************************************
    * SET_BED_MNG_REALOCATION
    * Function that performs a realocation, simply by setting the origin bed to a free status and setting the destination
    * bed to a occupied status. 
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  i_transaction_id            remote transaction identifier
    * @param  I_ID_BMNG_ACTION_OLD        (For the origin bed) ARRAY of Bed management action identifier 
    * @param  I_ID_DEPARTMENT_OLD         (For the origin bed)   ARRAY of Department identifier
    * @param  I_ID_ROOM_OLD                (For the origin bed)   ARRAY of Room identifier
    * @param  I_ID_BED_OLD                  (For the origin bed)  ARRAY of Bed identifier
    * @param  I_ID_BMNG_REASON_OLD           (For the origin bed) ARRAY of Reason identifier associated with current action
    * @param  I_ID_BMNG_ALLOCATION_BED_OLD   (For the origin bed) ARRAY of Bed management allocation identifier that should be updated or created in this function
    * @param  I_FLG_TARGET_ACTION_OLD         (For the origin bed) Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS_OLD               (For the origin bed)  Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_NCH_CAPACITY_OLD              (For the origin bed) ARRAY of NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES_OLD             (For the origin bed)  ARRAY of Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION_OLD           (For the origin bed) ARRAY of STRINGS correspondent to dates in which these action start counting
    * @param  I_DT_END_ACTION_OLD             (For the origin bed) ARRAY of STRINGS correspondent to dates in which these action became outdated
    * @param  I_ID_EPISODE_OLD                (For the origin bed) ARRAY of Episode identifier
    * @param  I_ID_PATIENT_OLD                (For the origin bed) ARRAY of Patient identifier
    * @param  I_NCH_HOURS_OLD                 (For the origin bed) Number of NCH associated with current allocation
    * @param  I_FLG_ALLOCATION_NCH_OLD        (For the origin bed) STRINGS informing if this NCH information is definitive or automatically updated with NCH_LEVEL information
    * @param  I_DESC_BED_OLD                  (For the origin bed) Description associated with this bed
    * @param  I_ID_BED_TYPE_OLD               (For the origin bed) ARRAY of Bed type identifier of this bed
    * @param  I_DT_DICHARGE_SCHEDULE_OLD      (For the origin bed) Episode expected discharge
    * @param  I_FLG_ORIGIN_ACTION_UX_OLD      (For the origin bed) Type of action: FLAG defined in flash layer
    
    * @param  I_ID_BMNG_ACTION            (For the destination bed) ARRAY of Bed management action identifier
    * @param  I_ID_DEPARTMENT             (For the destination bed) ARRAY of Department identifier
    * @param  I_ID_ROOM                   (For the destination bed) ARRAY of Room identifier
    * @param  I_ID_BED                    (For the destination bed) ARRAY of Bed identifier
    * @param  I_ID_BMNG_REASON            (For the destination bed) ARRAY of Reason identifier associated with current action
    * @param  I_ID_BMNG_ALLOCATION_BED    (For the destination bed) ARRAY of Bed management allocation identifier that should be updated or created in this function
    * @param  I_FLG_TARGET_ACTION         (For the destination bed) Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS                (For the destination bed) Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_NCH_CAPACITY              (For the destination bed) ARRAY of NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES              (For the destination bed) ARRAY of Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION           (For the destination bed) ARRAY of STRINGS correspondent to dates in which these action start counting
    * @param  I_DT_END_ACTION             (For the destination bed) ARRAY of STRINGS correspondent to dates in which these action became outdated
    * @param  I_ID_EPISODE                (For the destination bed) ARRAY of Episode identifier
    * @param  I_ID_PATIENT                (For the destination bed) ARRAY of Patient identifier
    * @param  I_NCH_HOURS                 (For the destination bed) Number of NCH associated with current allocation
    * @param  I_FLG_ALLOCATION_NCH        (For the destination bed) STRINGS informing if this NCH information is definitive or automatically updated with NCH_LEVEL information
    * @param  I_DESC_BED                  (For the destination bed) Description associated with this bed
    * @param  I_ID_BED_TYPE               (For the destination bed) ARRAY of Bed type identifier of this bed
    * @param  I_DT_DICHARGE_SCHEDULE      (For the destination bed) Episode expected discharge
    * @param  I_FLG_ORIGIN_ACTION_UX      (For the destination bed) Type of action: FLAG defined in flash layer
    * @param  O_BED_ALLOCATION            Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param  O_EXCEPTION_INFO            Error message to be displayed to the user.
    * @param  O_ID_BMNG_ALLOCATION_BED    Return allocation identifier if one patient is allocated to a new bed
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TARGET_ACTION         {*} 'S'- Service {*} 'R'- Room {*} 'B'- Bed
    * @value  I_FLG_STATUS                {*} 'A'- Active {*} 'C'- Cancelled {*} 'O'- Outdated
    * @value  I_FLG_ALLOCATION_NCH        {*} 'D'- Definitive {*} 'U'- Updatable
    * @value  I_FLG_ORIGIN_ACTION_UX      {*} 'B'-  BLOCK
    *                                     {*} 'U'-  UNBLOCK
    *                                     {*} 'V'-  FREE
    *                                     {*} 'O'-  OCCUPY (desreservar)
    *                                     {*} 'T'-  OCCUPY TEMPORARY BED (allocate / re-allocate)
    *                                     {*} 'P'-  OCCUPY DEFINITIVE BED (allocate / re-allocate)
    *                                     {*} 'S'-  SCHEDULE
    *                                     {*} 'R'-  RESERVE
    *                                     {*} 'D'-  DIRTY
    *                                     {*} 'C'-  CONTAMINED
    *                                     {*} 'I'-  CLEANING IN PROCESS
    *                                     {*} 'L'-  CLEANING CONCLUDED
    *                                     {*} 'E'-  EDIT BED ASSIGNMENT
    *                                     {*} 'ND'- UPDATE NCH PATIENT (DIRECTLY IN GRID)
    *                                     {*} 'NT'- NCH TOOLS
    *                                     {*} 'BT'- BLOCK TOOLS
    *                                     {*} 'UT'- UNBLOCK TOOLS
    * 
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   23-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_bed_mng_realocation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        -- OLD
        i_id_bmng_action_old         IN table_number,
        i_id_department_old          IN table_number,
        i_id_room_old                IN table_number,
        i_id_bed_old                 IN table_number,
        i_id_bmng_reason_old         IN table_number,
        i_id_bmng_allocation_bed_old IN table_number,
        i_flg_target_action_old      IN bmng_action.flg_target_action%TYPE,
        i_flg_status_old             IN bmng_action.flg_status%TYPE, --10
        i_nch_capacity_old           IN table_number,
        i_action_notes_old           IN table_varchar,
        i_dt_begin_action_old        IN table_varchar,
        i_dt_end_action_old          IN table_varchar,
        i_id_episode_old             IN table_number,
        i_id_patient_old             IN table_number,
        i_nch_hours_old              IN epis_nch.nch_value%TYPE,
        i_flg_allocation_nch_old     IN epis_nch.flg_type%TYPE,
        i_desc_bed_old               IN bed.desc_bed%TYPE,
        i_id_bed_type_old            IN table_number, --20
        i_dt_discharge_schedule_old  IN VARCHAR2,
        i_flg_hour_origin_old        IN VARCHAR2 DEFAULT 'DH',
        i_bed_dep_clin_serv_old      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_origin_action_ux_old   IN VARCHAR2,
        -- NEW
        i_id_bmng_action         IN table_number,
        i_id_department          IN table_number,
        i_id_room                IN table_number,
        i_id_bed                 IN table_number,
        i_id_bmng_reason         IN table_number,
        i_id_bmng_allocation_bed IN table_number,
        i_flg_target_action      IN bmng_action.flg_target_action%TYPE, --30
        i_flg_status             IN bmng_action.flg_status%TYPE,
        i_nch_capacity           IN table_number,
        i_action_notes           IN table_varchar,
        i_dt_begin_action        IN table_varchar,
        i_dt_end_action          IN table_varchar,
        i_id_episode             IN table_number,
        i_id_patient             IN table_number,
        i_nch_hours              IN epis_nch.nch_value%TYPE,
        i_flg_allocation_nch     IN epis_nch.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE, --40
        i_id_bed_type            IN table_number,
        i_dt_discharge_schedule  IN VARCHAR2,
        i_flg_hour_origin        IN VARCHAR2 DEFAULT 'DH',
        i_bed_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_origin_action_ux   IN VARCHAR2,
        i_reason_notes           IN epis_nch.reason_notes%TYPE,
        --
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        g_error := 'CALL TO FUNCTION PK_BMNG.SET_BED_MANAGEMENT FOR FREE';
        IF NOT pk_bmng.set_bed_management(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_bmng_action         => i_id_bmng_action_old,
                                          i_id_department          => i_id_department_old,
                                          i_id_room                => i_id_room_old,
                                          i_id_bed                 => i_id_bed_old,
                                          i_id_bmng_reason         => i_id_bmng_reason_old,
                                          i_id_bmng_allocation_bed => i_id_bmng_allocation_bed_old,
                                          i_flg_target_action      => i_flg_target_action_old,
                                          i_flg_status             => i_flg_status_old,
                                          i_nch_capacity           => i_nch_capacity_old,
                                          i_action_notes           => i_action_notes_old,
                                          i_dt_begin_action        => i_dt_begin_action_old,
                                          i_dt_end_action          => i_dt_end_action_old,
                                          i_id_episode             => i_id_episode_old,
                                          i_id_patient             => i_id_patient_old,
                                          i_nch_hours              => i_nch_hours_old,
                                          i_flg_allocation_nch     => i_flg_allocation_nch_old,
                                          i_desc_bed               => i_desc_bed_old,
                                          i_id_bed_type            => i_id_bed_type_old,
                                          i_dt_discharge_schedule  => i_dt_discharge_schedule_old,
                                          i_flg_hour_origin        => i_flg_hour_origin_old,
                                          i_id_bed_dep_clin_serv   => i_bed_dep_clin_serv_old,
                                          i_flg_origin_action_ux   => i_flg_origin_action_ux_old,
                                          i_reason_notes           => i_reason_notes,
                                          i_transaction_id         => l_transaction_id,
                                          o_id_bmng_allocation_bed => o_id_bmng_allocation_bed,
                                          o_id_bed                 => o_id_bed,
                                          o_bed_allocation         => o_bed_allocation,
                                          o_exception_info         => o_exception_info,
                                          o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO FUNCTION PK_BMNG.SET_BED_MANAGEMENT FOR OCCUPY';
        IF NOT pk_bmng.set_bed_management(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_bmng_action         => i_id_bmng_action,
                                          i_id_department          => i_id_department,
                                          i_id_room                => i_id_room,
                                          i_id_bed                 => i_id_bed,
                                          i_id_bmng_reason         => i_id_bmng_reason,
                                          i_id_bmng_allocation_bed => i_id_bmng_allocation_bed,
                                          i_flg_target_action      => i_flg_target_action,
                                          i_flg_status             => i_flg_status,
                                          i_nch_capacity           => i_nch_capacity,
                                          i_action_notes           => i_action_notes,
                                          i_dt_begin_action        => i_dt_begin_action,
                                          i_dt_end_action          => i_dt_end_action,
                                          i_id_episode             => i_id_episode,
                                          i_id_patient             => i_id_patient,
                                          i_nch_hours              => i_nch_hours,
                                          i_flg_allocation_nch     => i_flg_allocation_nch,
                                          i_desc_bed               => i_desc_bed,
                                          i_id_bed_type            => i_id_bed_type,
                                          i_dt_discharge_schedule  => i_dt_discharge_schedule,
                                          i_flg_hour_origin        => i_flg_hour_origin,
                                          i_id_bed_dep_clin_serv   => i_bed_dep_clin_serv,
                                          i_flg_origin_action_ux   => i_flg_origin_action_ux,
                                          i_reason_notes           => i_reason_notes,
                                          i_transaction_id         => l_transaction_id,
                                          o_id_bmng_allocation_bed => o_id_bmng_allocation_bed,
                                          o_id_bed                 => o_id_bed,
                                          o_bed_allocation         => o_bed_allocation,
                                          o_exception_info         => o_exception_info,
                                          o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    END set_bed_mng_realocation;

    /***************************************************************************************************************
    *
    *   Simplified version of SET_BED_MANAGEMENT, specifically for usage in the Tools menus. 
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param  I_ID_BMNG_ACTION            ARRAY of Bed management action identifier
    * @param  I_ID_DEPARTMENT             ARRAY of Department identifier
    * @param  I_FLG_TARGET_ACTION         Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS                Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_NCH_CAPACITY              ARRAY of NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES              ARRAY of Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION           ARRAY of STRINGS correspondent to dates in which these action start counting
    * @param  I_DT_END_ACTION             ARRAY of STRINGS correspondent to dates in which these action became outdated
    * @param  I_FLG_ORIGIN_ACTION_UX      Type of action: FLAG defined in flash layer
    * @param  i_transaction_id            remote transaction identifier
    * @param  O_ID_BMNG_ALLOCATION_BED    Return allocation identifier if one patient is allocated to a new bed
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   23-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_bed_management_tools
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_bmng_action       IN table_number,
        i_id_department        IN table_number,
        i_flg_target_action    IN bmng_action.flg_target_action%TYPE,
        i_flg_status           IN bmng_action.flg_status%TYPE,
        i_nch_capacity         IN table_number,
        i_action_notes         IN table_varchar,
        i_dt_begin_action      IN table_varchar,
        i_dt_end_action        IN table_varchar,
        i_flg_origin_action_ux IN VARCHAR2,
        i_transaction_id       IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        --
        g_error := 'CALL TO FUNCTION PK_BMNG.SET_BED_MANAGEMENT';
        IF NOT pk_bmng.set_bed_management(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_bmng_action         => i_id_bmng_action,
                                          i_id_department          => i_id_department,
                                          i_flg_target_action      => i_flg_target_action,
                                          i_flg_status             => i_flg_status,
                                          i_nch_capacity           => i_nch_capacity,
                                          i_action_notes           => i_action_notes,
                                          i_dt_begin_action        => i_dt_begin_action,
                                          i_dt_end_action          => i_dt_end_action,
                                          i_flg_origin_action_ux   => i_flg_origin_action_ux,
                                          i_transaction_id         => l_transaction_id,
                                          o_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                          o_id_bed                 => l_id_bed,
                                          o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_MANAGEMENT',
                                              o_error);
            RETURN FALSE;
    END set_bed_management_tools;

    /***************************************************************************************************************
    *
    * Fills the services dashboard's grid with occupational information (NCH and beds) regarding each or all services.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_admission_type    ID of the admission type, if any.
    * @param      o_deps              Cursor with all information
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   22-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_dashboard_serv_grid
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_admission_type IN table_number,
        o_deps           OUT NOCOPY pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_bmng.get_dashboard_serv_grid(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_admission_type => i_admission_type,
                                               o_deps           => o_deps,
                                               o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DASHBOARD_SERV_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_deps);
            RETURN FALSE;
    END get_dashboard_serv_grid;

    /***************************************************************************************************************
    *
    * Returns the number of available beds and if all of them share the same clinical specialty, it appends the abbreviation
    * of said specialty.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_dep               ID of the department to searc.
    *
    *
    * @RETURN  VARCHAR2
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   22-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_available_spec_beds
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dep  IN department.id_department%TYPE
    ) RETURN VARCHAR2 IS
        l_err t_error_out;
    BEGIN
        RETURN pk_bmng.get_available_spec_beds(i_lang => i_lang, i_prof => i_prof, i_dep => i_dep);
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAILABLE_SPEC_BEDS',
                                              l_err);
        
            pk_alert_exceptions.reset_error_state;
            RETURN '';
        
    END get_available_spec_beds;

    /***************************************************************************************************************
    *
    * Provides the data to be displayed in the Insight grid: Beds, patients, allocations, reservations, icons. It also 
    * returns a cursor with some information of the departments in the institution. 
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_dep               Array containing all departments to consider, when querying the database.
    * @param      o_deps              Cursor with a list of departments and their NCH info. Doesn't depend on the i_dep argument.
    * @param      o_beds              Cursor with all bed information for the departments provided.
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   22-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_beds_service_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN table_number,
        o_deps  OUT NOCOPY pk_types.cursor_type,
        o_beds  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.get_beds_service_grid(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_dep   => i_dep,
                                             o_deps  => o_deps,
                                             o_beds  => o_beds,
                                             o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BEDS_SERVICE',
                                              o_error);
            pk_types.open_my_cursor(o_deps);
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_beds_service_grid;

    /***************************************************************************************************************
    *
    * Returns a set of information to be displayed in the Viewer area.
    *
    * Note that all cursors returned have a specific structure in order to be properly interpreted by the UX layer.
    * Each line of these must have: title: Section title (redundantly repeated)
    *                               label: Line title;
    *                               data: Line content;
    *                               flg_total: (Y/N) to indicate if the record is a total, which flash uses to set the title in bold.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_deps              Array of departments. If null all departments in the institution are taken in account. 
    * @param      o_serv              Cursor containing the information regarding the service(s) considered.
    * @param      o_un_beds           Cursor containing the information regarding unavaible beds.
    * @param      o_av_beds           Cursor containing the information regarding avaible beds.
    * @param      o_cap               Cursor containing information regarding NCH capacity.
    * @param      o_room_types        Cursor containing  a list of room types and respective occupation rate.      
    * @param      o_date_server       Formatted current date to be displayed in the Viewer's title.               
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_viewer_summary
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_deps        IN table_number,
        o_serv        OUT NOCOPY pk_types.cursor_type,
        o_un_beds     OUT NOCOPY pk_types.cursor_type,
        o_av_beds     OUT NOCOPY pk_types.cursor_type,
        o_cap         OUT NOCOPY pk_types.cursor_type,
        o_room_types  OUT NOCOPY pk_types.cursor_type,
        o_date_server OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.get_viewer_summary(i_lang,
                                          i_prof,
                                          i_deps,
                                          o_serv,
                                          o_un_beds,
                                          o_av_beds,
                                          o_cap,
                                          o_room_types,
                                          o_date_server,
                                          o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BEDS_SERVICE',
                                              o_error);
            pk_types.open_my_cursor(o_serv);
            pk_types.open_my_cursor(o_un_beds);
            pk_types.open_my_cursor(o_av_beds);
            pk_types.open_my_cursor(o_cap);
            pk_types.open_my_cursor(o_room_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_viewer_summary;

    /***************************************************************************************************************
    *
    * Function for UX: returns information of all admission types available, plus "Select All" and "No value"  options.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.
    * @param      i_flg_all            Y/N - if yes, returns extra options.
    * @param      o_list               Cursor with all admission types and translations
    * @param      o_error              If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   22-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_admission_type_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_flg_all IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list    OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.get_admission_type_list(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_flg_all => i_flg_all,
                                               o_list    => o_list,
                                               o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADMISSION_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_admission_type_list;

    /***************************************************************************************************************
    *
    * Returns a list of availability statuses and their descriptions
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      o_list              Cursor with all admission types and translations
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   23-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_availabilities_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.get_availabilities_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_AVAILABILITY_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_availabilities_list;

    /********************************************************************************************************************************************
    *
    * GET_DEPARTMENTS          Function that returns all departments for the current professional institution
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  O_DEPS           Department information cursor
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION get_departments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_deps  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DEPARTMENTS';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET DEPARTMENTS';
        IF NOT pk_bmng_core.get_departments(i_lang => i_lang, i_prof => i_prof, o_deps => o_deps, o_error => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_deps);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_departments;

    /********************************************************************************************************************************************
    * GET_ROOMS                Function that returns all rooms for the specified department
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT              Department ID
    * @param  I_FLG_TYPE                Bed type
    * @param  I_SHOW_OCCUPIED_BEDS      Number of beds show in current rooms should count with occupied beds ('Y' - Yes; 'N' - No)
    * @param  O_ROOMS                   Rooms information cursor
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE, --null - trás todos; P - só as permanetes; T - só as temporárias
        i_show_occupied_beds IN VARCHAR2,
        o_rooms              OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ROOMS';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET ROOMS';
        IF NOT pk_bmng_core.get_rooms(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_department         => i_department,
                                      i_flg_type           => i_flg_type,
                                      i_show_occupied_beds => i_show_occupied_beds,
                                      o_rooms              => o_rooms,
                                      o_error              => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_rooms);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rooms;

    /********************************************************************************************************************************************
    *
    * GET_BEDS                 Function that returns all beds for the specified room
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ROOM           Room ID
    * @param  I_FLG_TYPE       Bed type
    * @param  O_BEDS           Beds information cursor
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE       NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION get_beds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_room     IN room.id_room%TYPE,
        i_flg_type IN bed.flg_type%TYPE, --null - trás todos; P - só as permanetes; T - só as temporárias
        o_beds     OUT NOCOPY pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_BEDS';
        l_exception EXCEPTION;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET BEDS';
        IF NOT pk_bmng_core.get_beds(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     i_room     => i_room,
                                     i_flg_type => i_flg_type,
                                     o_beds     => o_beds,
                                     o_error    => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_beds;

    /********************************************************************************************************************************************
    *
    * GET_ROOMS_BEDS           Function that returns all rooms and beds for the specified department
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT              Department ID
    * @param  I_FLG_TYPE                Bed type
    * @param  I_SHOW_OCCUPIED_BEDS      Number of beds show in current rooms should count with occupied beds ('Y' - Yes; 'N' - No)
    * @param  O_ROOMS                   Rooms information cursor
    * @param  O_BEDS                    Beds information cursor
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    * @value  I_SHOW_OCCUPIED_BEDS      Y - Yes; N - No
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   25-Ago-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION get_rooms_beds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_rooms              OUT NOCOPY pk_types.cursor_type,
        o_beds               OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ROOMS_BEDS';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET ROOMS AND BEDS';
        IF NOT pk_bmng_core.get_rooms_beds(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_department         => i_department,
                                           i_flg_type           => i_flg_type,
                                           i_show_occupied_beds => i_show_occupied_beds,
                                           o_rooms              => o_rooms,
                                           o_beds               => o_beds,
                                           o_error              => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_rooms);
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rooms_beds;

    /********************************************************************************************************************************************
    * GET_REASONS              Function that returns all available reasons for a specific action that can be done in a bed/room/ward
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_SUBJECT        SUBJECT string that identifies the reasons for execute a determined action that should be returned to FLASH
    * @param  O_REASONS        information of available reasons for current institution and action (identified by SUBJECT string)
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @value  I_SUBJECT        {*} 'BLOCK_ACTION' {*} 'UPDATE_NCH_ACTION' {*} 'BLOCK_BED_ACTION' {*} 'RESERVE_BED_ACTION'
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION get_reasons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN bmng_reason_type.subject%TYPE,
        o_reasons OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --
        g_error := 'CALL PK_BMNG_CORE.GET_REASONS';
        IF NOT pk_bmng_core.get_reasons(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_subject => i_subject,
                                        o_reasons => o_reasons,
                                        o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REASONS',
                                              o_error);
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END get_reasons;

    /***************************************************************************************************************
    *
    * Returns the description of the provided bed
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed.
    * @param      o_desc_bt           Cursor with information regarding the type of the bed
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_bed     IN bed.id_bed%TYPE,
        o_desc_bt OUT pk_translation.t_desc_translation,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_admission_request.get_bed_type(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_bed     => i_bed,
                                                 o_desc_bt => o_desc_bt,
                                                 o_error   => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BED_TYPE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_bed_type;

    /***************************************************************************************************************
    *
    * Returns the description of the provided bed
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed.
    *
    *
    * @RETURN  VARCHAR2
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2 IS
        l_err  t_error_out;
        l_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT get_bed_type(i_lang => i_lang, i_prof => i_prof, i_bed => i_bed, o_desc_bt => l_desc, o_error => l_err)
        THEN
            RETURN '';
        ELSE
            RETURN l_desc;
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED_TYPE',
                                              l_err);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN '';
    END get_bed_type;

    /***************************************************************************************************************
    *
    * Returns the type description of the provided room 
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.
    * @param      o_desc_rt           Cursor with information regarding the type of the room 
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_room    IN room.id_room%TYPE,
        o_desc_rt OUT pk_translation.t_desc_translation,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_admission_request.get_room_type(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_room    => i_room,
                                                  o_desc_rt => o_desc_rt,
                                                  o_error   => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ROOM_TYPE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_room_type;

    /***************************************************************************************************************
    *
    * Returns the type description of the provided room 
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    *  @param      i_room               ID of the room.
    *
    *
    * @RETURN  VARCHAR2
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_room IN room.id_room%TYPE
    ) RETURN VARCHAR2 IS
        l_err  t_error_out;
        l_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT
            get_room_type(i_lang => i_lang, i_prof => i_prof, i_room => i_room, o_desc_rt => l_desc, o_error => l_err)
        THEN
            RETURN '';
        ELSE
            RETURN l_desc;
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOM_TYPE',
                                              l_err);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN '';
    END get_room_type;

    /***************************************************************************************************************
    *
    * Returns the specialties of a room; if not available, of its department.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room. 
    * @param      o_dcs              Cursor with information regarding the room's specialty
    * @param      o_error  
    *
    *
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_dcs   OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO MAIN FUNCTION';
        IF NOT pk_bmng.get_room_dep_clin_serv(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_room  => i_room,
                                              o_dcs   => o_dcs,
                                              o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ROOM_DEP_CLIN_SERV',
                                              o_error);
            pk_types.open_my_cursor(o_dcs);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    /***************************************************************************************************************
    *
    * Returns the specialties of a bed; if not available, of its room; if not available, of its department.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed              ID of the bed.   
    * @param      o_dcs              Cursor with information regarding the bed's specialty
    * @param      o_error
    *
    *
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_bed   IN bed.id_bed%TYPE,
        o_dcs   OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO MAIN FUNCTION';
        IF NOT pk_bmng.get_bed_dep_clin_serv(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_bed   => i_bed,
                                             o_dcs   => o_dcs,
                                             o_error => o_error)
        
        THEN
            RETURN FALSE;
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
                                              'GET_BED_DEP_CLIN_SERV',
                                              o_error);
            pk_types.open_my_cursor(o_dcs);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_bed_dep_clin_serv;

    /********************************************************************************************************************************************
    *
    * GET_PATIENT_ALLOCATION   Function that returns all allocated beds and their location for the specified episode
    *
    * @param  I_LANG                         Language associated to the professional executing the request
    * @param  I_PROF                         Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_EPISODE                      Episode ID
    * @param  O_ALLOCATIONS                  All allocated information cursor for the specified episode
    * @param  O_PAT_NAME                     Patient name
    * @param  o_nch_hours                    Value of the total NCH hours for the episode 
    * @param  o_nch_hours_num                Same as previous, but as a numeric value
    * @param  o_dt_discharge_schedule        Date of the scheduled discharge, if any
    * @param  o_nch_mod_reason               Nursing care hours modification reason, if any
    * @param  O_ERROR                        If an error occurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION get_patient_allocation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        o_allocations           OUT NOCOPY pk_types.cursor_type,
        o_pat_name              OUT patient.name%TYPE,
        o_nch_hours             OUT VARCHAR2,
        o_nch_hours_num         OUT epis_nch.nch_value%TYPE,
        o_dt_discharge_schedule OUT VARCHAR2,
        o_flg_hour_origin       OUT discharge_schedule.flg_hour_origin%TYPE,
        o_nch_mod_reason        OUT epis_nch.reason_notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PATIENT_ALLOCATION';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET PAT ALLOCATIONS';
    
        IF NOT pk_bmng.get_patient_allocation(i_lang                  => i_lang,
                                              i_prof                  => i_prof,
                                              i_episode               => i_episode,
                                              o_allocations           => o_allocations,
                                              o_pat_name              => o_pat_name,
                                              o_nch_hours             => o_nch_hours,
                                              o_nch_hours_num         => o_nch_hours_num,
                                              o_dt_discharge_schedule => o_dt_discharge_schedule,
                                              o_flg_hour_origin       => o_flg_hour_origin,
                                              o_nch_mod_reason        => o_nch_mod_reason,
                                              o_error                 => o_error)
        
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_allocations);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_patient_allocation;

    /********************************************************************************************************************************************
    * GET_NCH_GRID             Function that returns a list of all nursing care hours time frames
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_VIEW_OPT       View option
    * @param  O_NCH_LIST       Nursing care hours list
    * @param  O_TITLE          Grid title
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @value  I_VIEW_OPT       'ALL' - All; 'CANC' - Cancelled; 'FUT' - Future; 'PAST' - Past; 'CURR' - Current;
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   22-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_nch_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_view_opt IN view_option.screen_identifier%TYPE,
        o_nch_list OUT NOCOPY pk_types.cursor_type,
        o_title    OUT sys_message.desc_message%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_NCH_GRID';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET NCH GRID';
    
        IF NOT pk_bmng.get_nch_grid(i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    i_view_opt => i_view_opt,
                                    o_nch_list => o_nch_list,
                                    o_title    => o_title,
                                    o_error    => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_nch_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_nch_grid;

    /***************************************************************************************************************
    *
    * Checks if there is a blocking period for the provided bed after the provided date, and if so returns the 
    * starting day of said period.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed to check   
    * @param      i_date               Referential date to start checking for bed blockings.
    * @param      o_flg_show          Is there a conflict? (Y/N)           
    * @param      o_msg_title         Title to appear in the warning 
    * @param      o_msg_body          Message to be displayed in the warning
    * @param      o_error             If an error accurs, this parameter will have information about the error   
    *
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   24-07-2009
    *
    ****************************************************************************************************/
    FUNCTION check_dt_next_blocking
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_bed       IN bed.id_bed%TYPE,
        i_date      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT sys_message.desc_message%TYPE,
        o_msg_body  OUT sys_message.desc_message%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.check_dt_next_blocking(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_bed       => i_bed,
                                              i_date      => i_date,
                                              o_flg_show  => o_flg_show,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body,
                                              o_error     => o_error)
        THEN
            RETURN FALSE;
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
                                              'check_dt_next_blocking',
                                              o_error);
            RETURN FALSE;
        
    END check_dt_next_blocking;

    /***************************************************************************************************************
    *
    * Checks if there is a scheduled period for the provided bed after the provided date, and if so it displays 
    * a warning.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed to check   
    * @param      i_date              Referential date to start checking for bed schedulings.
    * @param      o_flg_show          Is there a conflict? (Y/N)           
    * @param      o_msg_title         Title to appear in the warning 
    * @param      o_msg_body          Message to be displayed in the warning
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   24-07-2009
    *
    ****************************************************************************************************/
    FUNCTION check_dt_next_scheduling
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_bed       IN bed.id_bed%TYPE,
        i_date      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT sys_message.desc_message%TYPE,
        o_msg_body  OUT sys_message.desc_message%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.check_dt_next_scheduling(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_bed       => i_bed,
                                                i_date      => i_date,
                                                o_flg_show  => o_flg_show,
                                                o_msg_title => o_msg_title,
                                                o_msg_body  => o_msg_body,
                                                o_error     => o_error)
        THEN
            RETURN FALSE;
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
                                              'check_dt_next_blocking',
                                              o_error);
            RETURN FALSE;
        
    END check_dt_next_scheduling;

    /***************************************************************************************************************
    *
    * Checks if the provided bed has an updatable, still bound to change NCH level. If so, it displays a warning.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed to check   
    * @param      o_flg_show          Returns Y (yes) if the bed has an updatable nch level which is not on its last phase, or N (no) otherwise.
    * @param      o_msg_title         Title to appear in the warning 
    * @param      o_msg_body          Message to be displayed in the warning
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   24-07-2009
    *
    ****************************************************************************************************/
    FUNCTION check_next_nch_level
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_bed       IN bed.id_bed%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT sys_message.desc_message%TYPE,
        o_msg_body  OUT sys_message.desc_message%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.check_next_nch_level(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_bed       => i_bed,
                                            o_flg_show  => o_flg_show,
                                            o_msg_title => o_msg_title,
                                            o_msg_body  => o_msg_body,
                                            o_error     => o_error)
        THEN
            RETURN FALSE;
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
                                              'check_dt_next_blocking',
                                              o_error);
            RETURN FALSE;
        
    END check_next_nch_level;

    /***************************************************************************************************************
    *
    * Returns all unsigned patients for a provided department. If none is provided returns all of them (INP departments only).
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_dep               ALERT Service/Ward/Department 
    * @param      o_pats              Cursor with unsigned patients
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   24-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_unassigned_patients
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN table_number,
        o_pats  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL MAIN FUNCTION';
        IF NOT pk_bmng.get_unassigned_patients_v2(i_lang  => i_lang,
                                                  i_prof  => i_prof,
                                                  i_dep   => i_dep,
                                                  o_pats  => o_pats,
                                                  o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'get_unassigned_patients',
                                              o_error);
            RETURN FALSE;
        
    END get_unassigned_patients;

    /********************************************************************************************
    * Returns the conflits for a given list of departments and time frame 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_dt_begin          Interval begin date (nullable)
    * @param IN   i_dt_end            Interval end date (nullable)
    * @param IN   i_nch             nch (nullable)
    *
    * @param OUT  o_grid              Output cursor containing the conflicts
    * @param OUT  o_conflict_found    Boolean variable indicating if an conflict was found
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  2.5.0.5
    * @since                    29/07/2009
    ********************************************************************************************/
    FUNCTION check_bmng_interval_conflict
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_department     IN table_number,
        i_begin_date     IN table_varchar,
        i_end_date       IN table_varchar,
        i_nch            IN table_number,
        o_grid           OUT NOCOPY pk_types.cursor_type,
        o_conflict_found OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CHECK_BMNG_INTERVAL_CONFLICT';
        IF NOT pk_bmng.check_bmng_interval_conflict(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_department     => i_department,
                                                    i_begin_date     => i_begin_date,
                                                    i_end_date       => i_end_date,
                                                    i_nch            => i_nch,
                                                    o_grid           => o_grid,
                                                    o_conflict_found => o_conflict_found,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
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
                                              'CHECK_BMNG_INTERVAL_CONFLICT',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END;

    /********************************************************************************************************************************************
    * GET_BLOCKING_GRID        Function that returns a list of all blocked beds
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_VIEW_OPT       View option
    * @param  O_BLOCK_LIST     Blocked beds list
    * @param  O_TITLE          Grid title
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @value  I_VIEW_OPT       'ALL' - All; 'CANC' - Cancelled; 'FUT' - Future; 'PAST' - Past; 'CURR' - Current;
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   18-Aug-2009
    *******************************************************************************************************************************************/
    FUNCTION get_blocking_grid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_view_opt   IN view_option.screen_identifier%TYPE,
        o_block_list OUT NOCOPY pk_types.cursor_type,
        o_title      OUT NOCOPY sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_BLOCKING_GRID';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET BLOCKING GRID';
    
        IF NOT pk_bmng.get_blocking_grid(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_view_opt   => i_view_opt,
                                         o_block_list => o_block_list,
                                         o_title      => o_title,
                                         o_error      => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_block_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_blocking_grid;

    /***************************************************************************************************************
    *
    * Provides the data to be displayed in the Auxiliar grid.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_dep               Array containing all departments to consider, when querying the database.
    * @param      o_beds              Cursor with all bed information for the departments provided.
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   19-08-2009
    *
    ****************************************************************************************************/
    FUNCTION get_aux_beds_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN table_number,
        o_beds  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_BMNG';
        IF NOT pk_bmng.get_aux_beds_grid(i_lang  => i_lang,
                                         i_prof  => i_prof,
                                         i_dep   => i_dep,
                                         o_beds  => o_beds,
                                         o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AUX_BEDS_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_beds);
            RETURN FALSE;
    END get_aux_beds_grid;

    /********************************************************************************************************************************************
    * ALLOCATE_SCHEDULE_BEDS   Function that returns all schedule beds for today.
    *                          This function is responsable for create allocations taking into consideration schedule beds.
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   24-Aug-2009
    *******************************************************************************************************************************************/
    PROCEDURE allocate_schedule_beds IS
    BEGIN
        g_error := 'CALL TO PK_BMNG.ALLOCATE_SCHEDULE_BEDS';
        pk_bmng.allocate_schedule_beds;
    END allocate_schedule_beds;

    /********************************************************************************************************************************************
    * BMNG_HOUSEKEEPING        Restarts the Easy Access 
    *
    *
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7.3
    * @since   23-Nov-2009
    *******************************************************************************************************************************************/
    PROCEDURE bmng_housekeeping IS
    BEGIN
        g_error := 'CALL TO PK_BMNG.BMNG_HOUSEKEEPING';
        pk_bmng.bmng_housekeeping;
    END bmng_housekeeping;

    /********************************************************************************************
    * Returns all blocked permanent beds to the inputed department.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID    
    * @param IN   i_department   Department ID
    * @param IN   i_start_date   Start Date
    * @param IN   i_end_date     End Date
    
    * @param OUT  o_beds    Output cursor containing the idbed
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Sofia Mendes
    * @version                  2.5.0.5
    * @since                    26/08/2009
    ********************************************************************************************/
    FUNCTION get_blocked_beds
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_start_date    IN bmng_bed_ea.dt_begin%TYPE,
        i_end_date      IN bmng_bed_ea.dt_end%TYPE,
        o_beds          OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_BMNG.GET_BLOCKED_BEDS';
        IF NOT pk_bmng.get_blocked_beds(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_id_department => i_id_department,
                                        i_start_date    => i_start_date,
                                        i_end_date      => i_end_date,
                                        o_beds          => o_beds,
                                        o_error         => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BLOCKED_BEDS',
                                              o_error);
            pk_types.open_my_cursor(o_beds);
            RETURN FALSE;
    END get_blocked_beds;

    /********************************************************************************************
    * Verify if a bed is occupied within the given period
    *
    * @param i_lang       language id
    * @param i_id_bed     bed id
    * @param i_dt_begin   start date
    * @param i_dt_end     end date
    * @param o_occupied   Y = available  N = not available
    * @param o_error      Error message if something goes wrong
    *
    * @author                   Sofia Mendes
    * @version                  2.5.0.5
    * @since                    28/08/2009
    ********************************************************************************************/
    FUNCTION is_bed_occupied
    (
        i_lang     IN language.id_language%TYPE,
        i_id_bed   IN bed.id_bed%TYPE,
        i_dt_begin IN schedule.dt_begin_tstz%TYPE,
        i_dt_end   IN schedule.dt_end_tstz%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_BMNG.IS_BED_OCCUPIED';
        IF NOT pk_bmng.is_bed_occupied(i_lang     => i_lang,
                                       i_id_bed   => i_id_bed,
                                       i_dt_begin => i_dt_begin,
                                       i_dt_end   => i_dt_end,
                                       o_avail    => o_avail,
                                       o_error    => o_error)
        THEN
            RETURN FALSE;
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
                                              'IS_BED_OCCUPIED',
                                              o_error);
            RETURN FALSE;
    END is_bed_occupied;

    /********************************************************************************************
    * Verify if a bed is available within the given period
    *
    * @param i_lang       language id
    * @param i_id_bed     bed id
    * @param i_dt_begin   start date
    * @param i_dt_end     end date
    * @param o_occupied   Y = available  N = not available
    * @param o_error      Error message if something goes wrong
    *
    * @author                   Sofia Mendes
    * @version                  2.5.0.5
    * @since                    28/08/2009
    ********************************************************************************************/
    FUNCTION is_bed_available
    (
        i_lang   IN language.id_language%TYPE,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    BEGIN
        g_error := 'CALL PK_BMNG.IS_BED_OCCUPIED';
        RETURN pk_bmng.is_bed_available(i_lang => i_lang, i_id_bed => i_id_bed);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'IS_BED_AVAILABLE',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END is_bed_available;

    /***************************************************************************************************************
    *
    * Check if there are bed allocations associated with the provided episode.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID_EPISODE to check
    * @param      o_result            Y/N : Yes for existing bed allocations, no for no available bed allocations
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.6.1
    * @since   02-10-2009
    *
    ****************************************************************************************************/
    FUNCTION check_epis_bed_allocation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_result  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_BMNG.check_epis_bed_allocation';
        IF NOT pk_bmng.check_epis_bed_allocation(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 o_result  => o_result,
                                                 
                                                 o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'CHECK_EPIS_BED_ALLOCATION',
                                              o_error);
            RETURN FALSE;
    END check_epis_bed_allocation;

    /***************************************************************************************************************
    *
    * Returns the data of the bed allocations associated with the provided episode.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID_EPISODE to check
    * @param      o_result            Y/N : Yes for existing bed allocations, no for no available bed allocations
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   13-10-2009
    *
    ****************************************************************************************************/
    FUNCTION get_epis_bed_allocation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BMNG.get_epis_bed_allocation';
        IF NOT pk_bmng.get_epis_bed_allocation(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_episode => i_episode,
                                               o_result  => o_result,
                                               
                                               o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_EPIS_BED_ALLOCATION',
                                              o_error);
            RETURN FALSE;
    END get_epis_bed_allocation;

    /***************************************************************************************************************
    *
    * CHANGES STATUS OF GIVEN BED AS VACANT/EMPTY OF EPISODE  
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             Professional calling this function.
    * @param      i_id_episode       ID_EPISODE to check for bed allocations.
    * @param      i_transaction_id   remote transaction identifier
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14-10-2009
    *
    ****************************************************************************************************/
    FUNCTION set_episode_bed_status_vacant
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_transaction_id        IN VARCHAR2,
        i_dt_discharge_schedule IN VARCHAR2 DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL PK_BMNG.SET_EPISODE_BED_STATUS_VACANT';
        IF NOT pk_bmng.set_episode_bed_status_vacant(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_id_episode            => i_id_episode,
                                                     i_transaction_id        => l_transaction_id,
                                                     i_dt_discharge_schedule => i_dt_discharge_schedule,
                                                     o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'SET_EPISODE_BED_STATUS_VACANT',
                                              o_error);
            RETURN FALSE;
    END set_episode_bed_status_vacant;

    /***************************************************************************************************************
    *
    * Provides the data to be displayed in the ancillary inside grid
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_epis              ID_EPIS
    * @param      o_beds              Cursor with all bed information for the episode provided.
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7.3
    * @since   11-11-2009
    *
    ****************************************************************************************************/
    FUNCTION get_anc_episode
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_beds  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL PK_BMNG.get_anc_episode';
        IF NOT pk_bmng.get_anc_episode(i_lang  => i_lang,
                                       i_prof  => i_prof,
                                       i_epis  => i_epis,
                                       o_beds  => o_beds,
                                       o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ANC_EPISODE',
                                              o_error);
            RETURN FALSE;
        
    END get_anc_episode;

    /***************************************************************************************************************
    *
    * Provides the bed description  of the active bed allocation
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_epis              ID_EPIS
    * @param      o_desc              Bed description (null if no allocation)
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7.3
    * @since   11-11-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_desc  OUT pk_translation.t_desc_translation,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_BMNG';
        IF NOT pk_bmng.get_bed_desc(i_lang  => i_lang,
                                    i_prof  => i_prof,
                                    i_epis  => i_epis,
                                    o_desc  => o_desc,
                                    o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BED_DESC',
                                              o_error);
            RETURN FALSE;
        
    END get_bed_desc;

    /********************************************************************************************************************************************
    * BMNG_RESET                        Cleans all data regarding beds and related info for the episodes provided. 
    *
    * @param      i_prof                RESET professional
    * @param      i_episodes            ID of the episodes to be freed
    * @param      i_allocation_commit   Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param      o_error               If an error accurs, this parameter will have information about the error
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7.6.1
    * @since   11-FEB-2010
    *******************************************************************************************************************************************/
    FUNCTION bmng_reset
    (
        i_prof              IN profissional,
        i_episodes          IN table_number,
        i_allocation_commit IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_BMNG_CORE.BMNG_RESET';
        IF NOT pk_bmng_core.bmng_reset(i_prof              => i_prof,
                                       i_episodes          => i_episodes,
                                       i_allocation_commit => i_allocation_commit,
                                       o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'BMNG_RESET',
                                              o_error);
        
            RETURN FALSE;
    END bmng_reset;

    /********************************************************************************************************************************************
    * SET_BED_ACTION                      This funciton intends to be an API to the interfaces team to perform the following action over a given bed:
    *                                     - block
    *                                     - unblock
    *                                     - clean
    *                                     - contamine
    *                                     - set as being cleaned
    *                                     - clean concluded                                      
	*									  - free		
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)    
    * @param  I_ID_BED                    Bed identifier. Mandatory field.
    * @param  I_FLG_ORIGIN_ACTION_UX      Type of action: FLAG defined in flash layer
    * @param  I_DT_BEGIN                  Date in which this action start counting. Can be used on block, dirty, contamined action
    * @param  I_DT_END                    Date in which this action became outdated. Can be used on block, dirty, contamined action
    * @param  I_ID_BMNG_REASON            Reason identifier associated with current action. Mandatory for block bed. 
    *                                     It is not shown in application in the other options    
    * @param  I_NOTES                     Notes written by professional when creating current registry . 
    *                                      Can be used on block, dirty, contamined actions 
	* @param  I_ID_EPISODE                     Episode identifier.
	* @param  I_ID_PATIENT                     Patient identifier.
	* @param  I_ID_BMNG_ALLOC_BED                     Bed Management Allocation Bed identifier.
    * @param  O_BED_ALLOCATION            Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)    
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_ORIGIN_ACTION_UX      {*} 'B'-  BLOCK
    *                                     {*} 'U'-  UNBLOCK                                    
    *                                     {*} 'D'-  DIRTY
    *                                     {*} 'C'-  CONTAMINED
    *                                     {*} 'I'-  CLEANING IN PROCESS
    *                                     {*} 'L'-  CLEANING CONCLUDED
	*                                     {*} 'V'-  FREE
    * 
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author                  Sofia Mendes
    * @version                 2.6.1.4
    * @since                   31-Oct-2011
    *******************************************************************************************************************************************/
    FUNCTION set_bed_action
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_bed             IN bed.id_bed%TYPE,
        i_flg_action         IN VARCHAR2,
        i_dt_begin           IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end             IN bmng_action.dt_end_action%TYPE,
        i_notes              IN bmng_action.action_notes%TYPE,
        i_id_bmng_reason     IN bmng_action.id_bmng_reason%TYPE,
        i_dt_creation        IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_transaction_id     IN VARCHAR2,
		i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_bmng_alloc_bed  IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_bed_action_allowed OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL TO FUNCTION PK_BMNG_CORE.SET_BED_ACTION';
        IF NOT pk_bmng_core.set_bed_action(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_id_bed             => i_id_bed,
                                           i_flg_action         => i_flg_action,
                                           i_dt_begin           => i_dt_begin,
                                           i_dt_end             => i_dt_end,
                                           i_notes              => i_notes,
                                           i_id_bmng_reason     => i_id_bmng_reason,
                                           i_dt_creation        => i_dt_creation,
                                           i_transaction_id     => i_transaction_id,
										   i_id_episode         => i_id_episode,
                                           i_id_patient         => i_id_patient,
                                           i_id_bmng_alloc_bed  => i_id_bmng_alloc_bed,
                                           o_bed_action_allowed => o_bed_action_allowed,
                                           o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_ACTION',
                                              o_error);
            RETURN FALSE;
    END set_bed_action;

    /* SCH-9645
    * bed detail function for the eye button
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)    
    * @param  I_ID_BED                    Bed identifier. Mandatory field.
    * @param  o_output                    html output, ready to consume
    * @param  o_error                     error data
    *
    * @return boolean
    *
    * @author                  Telmo
    * @version                 2.6.4
    * @since                   12-02-2015
    */
    FUNCTION get_bed_detail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE,
        o_output OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO FUNCTION PK_BMNG.GET_BED_DETAIL';
        IF NOT pk_bmng.get_bed_detail(i_lang   => i_lang,
                                      i_prof   => i_prof,
                                      i_id_bed => i_id_bed,
                                      o_output => o_output,
                                      o_error  => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_BED_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_bed_detail;
    --
    FUNCTION set_temporary_bed
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_department          IN table_number,
        i_id_room                IN table_number,
        i_id_bed                 IN table_number DEFAULT NULL,
        i_dt_begin_action        IN table_varchar,
        i_dt_end_action          IN table_varchar DEFAULT NULL,
        i_id_episode             IN table_number,
        i_id_patient             IN table_number,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_id_bed_type            IN table_number,
        i_dt_discharge_schedule  IN VARCHAR2 DEFAULT NULL,
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'CALL TO FUNCTION PK_BMNG.SET_BED_MANAGEMENT';
        IF NOT pk_bmng.set_bed_management(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_bmng_action         => NULL,
                                          i_id_department          => i_id_department,
                                          i_id_room                => i_id_room,
                                          i_id_bed                 => i_id_bed,
                                          i_id_bmng_reason         => NULL,
                                          i_id_bmng_allocation_bed => NULL,
                                          i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                          i_flg_status             => NULL,
                                          i_nch_capacity           => NULL,
                                          i_action_notes           => NULL,
                                          i_dt_begin_action        => i_dt_begin_action,
                                          i_dt_end_action          => i_dt_end_action,
                                          i_id_episode             => i_id_episode,
                                          i_id_patient             => i_id_patient,
                                          i_nch_hours              => NULL,
                                          i_flg_allocation_nch     => NULL,
                                          i_desc_bed               => i_desc_bed,
                                          i_id_bed_type            => i_id_bed_type,
                                          i_dt_discharge_schedule  => i_dt_discharge_schedule,
                                          --i_flg_hour_origin        => null,
                                          i_id_bed_dep_clin_serv => NULL,
                                          i_flg_origin_action_ux => pk_bmng_constant.g_bmng_flg_origin_ux_t, --NULL,
                                          i_reason_notes         => NULL,
                                          i_transaction_id       => l_transaction_id,
                                          --i_dt_creation            => null,
                                          o_id_bmng_allocation_bed => o_id_bmng_allocation_bed,
                                          o_id_bed                 => o_id_bed,
                                          o_bed_allocation         => o_bed_allocation,
                                          o_exception_info         => o_exception_info,
                                          o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (l_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TEMPORARY_BED',
                                              o_error);
            RETURN FALSE;
    END set_temporary_bed;



BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_bmng_pbl;
/
