/*-- Last Change Revision: $Rev: 2026827 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_bmng IS

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
    * @param  i_allocation_commit         Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
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
        i_id_bed_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_origin_action_ux   IN VARCHAR2,
        i_reason_notes           IN epis_nch.reason_notes%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_allocation_commit      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_creation            IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_dt_begin_action TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_action   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_bmng_action         bmng_action.id_bmng_action%TYPE;
        l_id_bmng_reason         bmng_action.id_bmng_reason%TYPE;
        l_id_bmng_allocation_bed bmng_action.id_bmng_allocation_bed%TYPE;
        l_flg_target_action      bmng_action.flg_target_action%TYPE;
        l_flg_status             bmng_action.flg_status%TYPE;
        l_nch_capacity           bmng_action.nch_capacity%TYPE;
        l_action_notes           bmng_action.action_notes%TYPE;
        l_nch_hours              epis_nch.nch_value%TYPE;
        l_flg_allocation_nch     epis_nch.flg_type%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        FOR i IN 1 .. i_id_department.count
        LOOP
            g_error := 'LOOP I = ' || i;
            pk_alertlog.log_debug(g_error);
            --
            IF i_flg_origin_action_ux = 'NT'
               OR i_flg_origin_action_ux = 'NB'
            THEN
                l_dt_begin_action := to_date(i_dt_begin_action(i), 'YYYYMMDDHH24MiSS');
                l_dt_end_action   := to_date(i_dt_end_action(i), 'YYYYMMDDHH24MiSS');
            ELSE
                l_dt_begin_action := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_action(i), NULL);
                l_dt_end_action   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_action(i), NULL);
            
            END IF;
        
            IF i_id_bmng_action IS NOT NULL
               AND i_id_bmng_action.count > 0
            THEN
                l_id_bmng_action := i_id_bmng_action(i);
            ELSE
                l_id_bmng_action := NULL;
            END IF;
        
            IF i_id_bmng_reason IS NOT NULL
               AND i_id_bmng_reason.count > 0
            THEN
                l_id_bmng_reason := i_id_bmng_reason(i);
            ELSE
                l_id_bmng_reason := NULL;
            END IF;
        
            IF i_id_bmng_allocation_bed IS NOT NULL
               AND i_id_bmng_allocation_bed.count > 0
            THEN
                l_id_bmng_allocation_bed := i_id_bmng_allocation_bed(i);
            ELSE
                l_id_bmng_allocation_bed := NULL;
            END IF;
        
            IF i_nch_capacity IS NOT NULL
               AND i_nch_capacity.count > 0
            THEN
                l_nch_capacity := i_nch_capacity(i);
            ELSE
                l_nch_capacity := NULL;
            END IF;
        
            IF i_action_notes IS NOT NULL
               AND i_action_notes.count > 0
            THEN
                l_action_notes := i_action_notes(i);
            ELSE
                l_action_notes := NULL;
            END IF;
        
            --
            g_error := 'CALL TO PK_BMNG_CORE.SET_BED_MANAGEMENT(1) WITH i_id_bmng_action=' || l_id_bmng_action;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_bmng_core.set_bed_management(i_lang                   => i_lang,
                                                   i_prof                   => i_prof,
                                                   i_id_bmng_action         => i_id_bmng_action(i),
                                                   i_id_department          => i_id_department(i),
                                                   i_id_room                => i_id_room(i),
                                                   i_id_bed                 => i_id_bed(i),
                                                   i_id_bmng_reason         => i_id_bmng_reason(i),
                                                   i_id_bmng_allocation_bed => i_id_bmng_allocation_bed(i),
                                                   i_flg_target_action      => i_flg_target_action,
                                                   i_flg_status             => i_flg_status,
                                                   i_nch_capacity           => i_nch_capacity(i),
                                                   i_action_notes           => i_action_notes(i),
                                                   i_dt_begin_action        => l_dt_begin_action,
                                                   i_dt_end_action          => l_dt_end_action,
                                                   i_id_episode             => i_id_episode(i),
                                                   i_id_patient             => i_id_patient(i),
                                                   i_nch_hours              => i_nch_hours,
                                                   i_flg_allocation_nch     => i_flg_allocation_nch,
                                                   i_desc_bed               => i_desc_bed,
                                                   i_id_bed_type            => i_id_bed_type(i),
                                                   i_dt_discharge_schedule  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             i_dt_discharge_schedule,
                                                                                                             NULL),
                                                   i_flg_hour_origin        => i_flg_hour_origin,
                                                   i_id_bed_dep_clin_serv   => i_id_bed_dep_clin_serv,
                                                   i_flg_origin_action_ux   => i_flg_origin_action_ux,
                                                   i_reason_notes           => i_reason_notes,
                                                   i_transaction_id         => l_transaction_id,
                                                   i_allocation_commit      => i_allocation_commit,
                                                   i_dt_creation            => i_dt_creation,
                                                   o_id_bmng_allocation_bed => o_id_bmng_allocation_bed,
                                                   o_id_bed                 => o_id_bed,
                                                   o_bed_allocation         => o_bed_allocation,
                                                   o_exception_info         => o_exception_info,
                                                   o_error                  => o_error)
            THEN
                IF o_bed_allocation = pk_alert_constant.g_no
                THEN
                    NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
                ELSE
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
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
    FUNCTION set_bed_management
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_bmng_action         IN table_number,
        i_id_department          IN table_number,
        i_flg_target_action      IN bmng_action.flg_target_action%TYPE,
        i_flg_status             IN bmng_action.flg_status%TYPE,
        i_nch_capacity           IN table_number,
        i_action_notes           IN table_varchar,
        i_dt_begin_action        IN table_varchar,
        i_dt_end_action          IN table_varchar,
        i_flg_origin_action_ux   IN VARCHAR2,
        i_transaction_id         IN VARCHAR2,
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_bed_allocation VARCHAR2(1);
        l_exception_info sys_message.desc_message%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        FOR i IN 1 .. i_id_department.count
        LOOP
            --
            g_error := 'CALL TO PK_BMNG_CORE.SET_BED_MANAGEMENT(2) WITH i_id_bmng_action=' || i_id_bmng_action(i);
            pk_alertlog.log_debug(g_error);
            IF NOT pk_bmng_core.set_bed_management(i_lang                   => i_lang,
                                                   i_prof                   => i_prof,
                                                   i_id_bmng_action         => i_id_bmng_action(i),
                                                   i_id_department          => i_id_department(i),
                                                   i_id_room                => NULL,
                                                   i_id_bed                 => NULL,
                                                   i_id_bmng_reason         => NULL,
                                                   i_id_bmng_allocation_bed => NULL,
                                                   i_flg_target_action      => i_flg_target_action,
                                                   i_flg_status             => i_flg_status,
                                                   i_nch_capacity           => i_nch_capacity(i),
                                                   i_action_notes           => i_action_notes(i),
                                                   i_dt_begin_action        => pk_date_utils.date_send_tsz(i_lang,
                                                                                                           i_dt_begin_action(i),
                                                                                                           i_prof),
                                                   i_dt_end_action          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                           i_dt_end_action(i),
                                                                                                           i_prof),
                                                   i_id_episode             => NULL,
                                                   i_id_patient             => NULL,
                                                   i_nch_hours              => NULL,
                                                   i_flg_allocation_nch     => NULL,
                                                   i_desc_bed               => NULL,
                                                   i_id_bed_type            => NULL,
                                                   i_dt_discharge_schedule  => NULL,
                                                   i_id_bed_dep_clin_serv   => NULL,
                                                   i_flg_origin_action_ux   => i_flg_origin_action_ux,
                                                   i_reason_notes           => NULL,
                                                   i_transaction_id         => l_transaction_id,
                                                   i_allocation_commit      => pk_alert_constant.g_yes,
                                                   o_id_bmng_allocation_bed => o_id_bmng_allocation_bed,
                                                   o_id_bed                 => o_id_bed,
                                                   o_bed_allocation         => l_bed_allocation,
                                                   o_exception_info         => l_exception_info,
                                                   o_error                  => o_error)
            THEN
                IF l_bed_allocation = pk_alert_constant.g_no
                THEN
                    NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
                ELSE
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
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
        o_deps           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_val      PLS_INTEGER;
        l_deps     table_number := table_number();
        l_dep_nch  table_number := table_number();
        l_dep_ids  table_number := table_number();
        l_dep_bbs  table_number := table_number();
        l_dep_cap  table_number := table_number();
        l_null     VARCHAR2(3) := '---';
        l_dep_info pk_types.cursor_type;
    
    BEGIN
    
        --No Admission Types selected, all types must be considered. 
        --Note: Flash sends null variable, mw somehow instanciates an empty array instead. 
        --      In doubt, both cases are considered with this IF-ELSE.
        IF i_admission_type IS NULL
        THEN
            l_val := 0;
        ELSE
            l_val := i_admission_type.count;
        END IF;
    
        g_error := 'GET LIST OF DEPARTMENTS';
        pk_alertlog.log_debug(g_error);
    
        SELECT d.id_department
          BULK COLLECT
          INTO l_deps
          FROM bmng_department_ea bdea
         INNER JOIN department d
            ON (d.id_department = bdea.id_department AND instr(d.flg_type, 'I') > 0 AND
               d.flg_available = pk_alert_constant.g_yes)
         WHERE d.id_institution = i_prof.institution
           AND (l_val = 0 OR
               d.id_admission_type IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_admission_type) t));
    
        g_error := 'CALL GET_TOTAL_DEPARTMENT_INFO';
        pk_alertlog.log_debug(g_error);
    
        IF NOT get_total_department_info(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_department  => l_deps,
                                         i_institution => i_prof.institution,
                                         i_dt_request  => current_timestamp,
                                         o_dep_info    => l_dep_info,
                                         o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH GET_TOTAL_DEPARTMENT_INFO RESULTS';
        pk_alertlog.log_debug(g_error);
        FETCH l_dep_info BULK COLLECT
            INTO l_dep_ids, l_dep_bbs, l_dep_nch, l_dep_cap;
        CLOSE l_dep_info;
    
        g_error := 'OPEN O_DEPS';
        pk_alertlog.log_debug(g_error);
        OPEN o_deps FOR
            SELECT t.id_department,
                   t.desc_dep,
                   t.desc_specs,
                   t.id_adm_type,
                   t.beds_ocuppied,
                   t.beds_reserved,
                   t.beds_blocked,
                   t.total_unavailable_beds,
                   (t.general_beds) general_beds,
                   t.spec_beds,
                   t.spec_beds_desc,
                   (t.general_beds + t.spec_beds) total_available_beds,
                   t.nch_capacity,
                   t.nch_rate,
                   t.blocked_status,
                   t.nch_color
              FROM (SELECT bdea.id_department,
                           pk_translation.get_translation(i_lang, d.code_department) ||
                           decode(nvl(at.desc_admission_type, at.code_admission_type),
                                  NULL,
                                  '',
                                  ' (' || nvl(at.desc_admission_type,
                                              pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                           pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, bdea.id_department) desc_specs,
                           nvl(d.id_admission_type, 0) id_adm_type,
                           bdea.beds_ocuppied,
                           bdea.beds_reserved,
                           bdea.beds_blocked,
                           bdea.total_unavailable_beds,
                           (SELECT COUNT(b.id_bed)
                              FROM bed b
                             INNER JOIN room r
                                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
                              LEFT JOIN bed_dep_clin_serv bdcs
                                ON (bdcs.id_bed = b.id_bed AND bdcs.flg_available = pk_alert_constant.g_yes)
                             WHERE b.flg_available = pk_alert_constant.g_yes
                               AND b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
                               AND b.flg_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
                               AND bdcs.id_bed IS NULL
                               AND r.id_department = bdea.id_department) general_beds,
                           (SELECT COUNT(DISTINCT b.id_bed)
                              FROM bed b
                             INNER JOIN room r
                                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
                             INNER JOIN bed_dep_clin_serv bdcs
                                ON (bdcs.id_bed = b.id_bed AND bdcs.flg_available = pk_alert_constant.g_yes)
                             WHERE b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
                               AND b.flg_available = pk_alert_constant.g_yes
                               AND b.flg_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
                               AND r.id_department = bdea.id_department) spec_beds,
                           pk_bmng.get_available_spec_beds(i_lang, i_prof, bdea.id_department) spec_beds_desc,
                           --Total NHC available
                           decode(nvl(t_cap.value, 0),
                                  0,
                                  l_null,
                                  
                                  pk_nch_pbl.get_format_nch_info(i_lang, nvl(t_nch.value, 0)) || '/' ||
                                  pk_nch_pbl.get_format_nch_info(i_lang, t_cap.value)) nch_capacity,
                           decode(nvl(t_cap.value, 0),
                                  0,
                                  l_null,
                                  
                                  decode(t_nch.value,
                                         0,
                                         to_char(t_nch.value) || '%',
                                         TRIM(to_char(((t_nch.value / t_cap.value) * 100), '9999')) || '%')) nch_rate,
                           '' blocked_status, --FFR
                           decode(nvl(t_cap.value, 0),
                                   0,
                                   '',
                                   CASE
                                       WHEN ((t_nch.value / t_cap.value) * 100) <= 100 THEN
                                        ''
                                       WHEN ((t_nch.value / t_cap.value) * 100) > 110 THEN
                                        pk_alert_constant.g_color_red
                                       WHEN ((t_nch.value / t_cap.value) * 100) > 100 THEN
                                        pk_alert_constant.g_color_icon_light_yellow
                                   END) nch_color
                      FROM bmng_department_ea bdea
                     INNER JOIN department d
                        ON (d.id_department = bdea.id_department AND instr(d.flg_type, 'I') > 0 AND
                           d.flg_available = pk_alert_constant.g_yes)
                      LEFT JOIN admission_type at
                        ON at.id_admission_type = d.id_admission_type
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dep_ids) t) t_deps
                        ON t_deps.value = d.id_department
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dep_bbs) t) t_bbs
                        ON t_bbs.rnum = t_deps.rnum
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dep_nch) t) t_nch
                        ON t_nch.rnum = t_bbs.rnum
                      LEFT JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dep_cap) t) t_cap
                        ON t_cap.rnum = t_bbs.rnum
                     WHERE bdea.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                   t.column_value
                                                    FROM TABLE(l_deps) t)
                     ORDER BY d.rank, desc_dep) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADMISSION_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_deps);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_dashboard_serv_grid;

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
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_flg_all = pk_alert_constant.g_no
        THEN
            g_error := 'CALL MAIN FUNCTION';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_api_adm_request.get_admission_type_list(i_lang     => i_lang,
                                                              i_prof     => i_prof,
                                                              i_location => i_prof.institution,
                                                              o_list     => o_list,
                                                              o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'OPEN CURSOR';
            pk_alertlog.log_debug(g_error);
            OPEN o_list FOR
                SELECT -1 id_admission_type,
                       pk_message.get_message(i_lang, 'COMMON_M014') adm_type_desc,
                       NULL max_admission_time,
                       0 rank
                  FROM dual
                UNION ALL
                SELECT 0 id_admission_type,
                       pk_message.get_message(i_lang, 'BMNG_T112') adm_type_desc,
                       NULL max_admission_time,
                       2 rank
                  FROM dual
                UNION ALL
                SELECT at.id_admission_type,
                       nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) adm_type_desc,
                       at.max_admission_time,
                       1 rank
                  FROM admission_type at
                 WHERE EXISTS (SELECT 0
                          FROM department d
                         WHERE d.id_admission_type = at.id_admission_type
                           AND d.id_institution = i_prof.institution
                           AND d.flg_available = pk_alert_constant.g_yes)
                   AND at.id_institution IN (i_prof.institution, 0)
                 GROUP BY at.id_admission_type,
                          nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)),
                          at.max_admission_time
                 ORDER BY rank, adm_type_desc;
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
                                              'GET_ADMISSION_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_admission_type_list;

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
    
        l_spec table_varchar := table_varchar();
        l_err  t_error_out;
    
    BEGIN
        g_error := 'GET SPECIALTY DESC';
        pk_alertlog.log_debug(g_error);
    
        SELECT data.desc_spec
          BULK COLLECT
          INTO l_spec
          FROM (SELECT cs.abbreviation desc_spec, COUNT(bdcs.id_bed) beds_spec
                  FROM dep_clin_serv dcs
                 INNER JOIN bed_dep_clin_serv bdcs
                    ON bdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                 INNER JOIN clinical_service cs
                    ON cs.id_clinical_service = dcs.id_clinical_service
                 INNER JOIN bed b
                    ON (b.id_bed = bdcs.id_bed AND b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v)
                 WHERE dcs.id_department = i_dep
                   AND bdcs.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND cs.flg_available = pk_alert_constant.g_yes
                   AND b.flg_available = pk_alert_constant.g_yes
                 GROUP BY cs.abbreviation) data;
    
        IF (l_spec.count = 1)
        THEN
        
            RETURN l_spec(0);
        
        ELSE
            RETURN '';
        END IF;
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
            RETURN '';
    END get_available_spec_beds;

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
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_list FOR
            SELECT '-1' flg_status,
                   pk_message.get_message(i_lang, 'COMMON_M014') desc_status,
                   NULL img_name,
                   0 rank1,
                   0 rank
              FROM dual
            UNION ALL
            SELECT sd.val flg_status, sd.desc_val desc_status, sd.img_name, 1 rank1, sd.rank
              FROM sys_domain sd
             WHERE sd.code_domain IN ('BMNG_ACTION.FLG_BED_STATUS', 'BMNG_ACTION.FLG_BED_OCCUPANCY_STATUS')
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = pk_alert_constant.g_yes
               AND sd.val NOT IN (pk_bmng_constant.g_bmng_act_flg_bed_sta_n)
             ORDER BY rank1, desc_status DESC, rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAILABILITIES_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_availabilities_list;

    /***************************************************************************************************************
    *
    * Returns the specialties of a bed; if not available, of its room; if not available, of its department.
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_bed              ID of the bed.   
    * @param      o_dcs              Cursor containing information of a specialty.
    * @param      o_error            If an error accurs, this parameter will have information about the error
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
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2 IS
        l_err   t_error_out;
        l_tmp   pk_translation.t_desc_translation;
        l_dummy dep_clin_serv.id_dep_clin_serv%TYPE;
        l_desc  VARCHAR2(4000);
        l_dcs   pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL TO MAIN FUNCTION';
        pk_alertlog.log_debug(g_error);
        IF NOT
            get_bed_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_bed => i_bed, o_dcs => l_dcs, o_error => l_err)
        THEN
            RETURN '';
        END IF;
    
        g_error := 'CONCATENATE LIST';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_dcs
                INTO l_dummy, l_tmp;
            EXIT WHEN l_dcs%NOTFOUND;
            IF l_tmp IS NOT NULL
            THEN
                l_desc := l_desc || ', ' || l_tmp;
            END IF;
        END LOOP;
    
        CLOSE l_dcs;
        RETURN ltrim(l_desc, ', ');
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED_DEP_CLIN_SERV',
                                              l_err);
            pk_alert_exceptions.reset_error_state;
            RETURN '';
    END get_bed_dep_clin_serv;

    /***************************************************************************************************************
    *
    * Returns the specialties of a  room; if not available, of its department.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.   
    *
    *
    * @RETURN  VARCHAR2
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_dep_clin_serv
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_room IN room.id_room%TYPE
        
    ) RETURN VARCHAR2 IS
    
        l_err   t_error_out;
        l_tmp   pk_translation.t_desc_translation;
        l_dummy dep_clin_serv.id_dep_clin_serv%TYPE;
        l_desc  VARCHAR2(4000);
        l_dcs   pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL TO MAIN FUNCTION i_room=' || i_room;
        pk_alertlog.log_debug(g_error);
        IF NOT get_room_dep_clin_serv(i_lang  => i_lang,
                                      i_prof  => i_prof,
                                      i_room  => i_room,
                                      o_dcs   => l_dcs,
                                      o_error => l_err)
        THEN
            RETURN '';
        END IF;
    
        g_error := 'CONCATENATE LIST';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_dcs
                INTO l_dummy, l_tmp;
            EXIT WHEN l_dcs%NOTFOUND;
            IF l_tmp IS NOT NULL
            THEN
                l_desc := l_desc || ', ' || l_tmp;
            END IF;
        END LOOP;
    
        CLOSE l_dcs;
        RETURN ltrim(l_desc, ', ');
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOM_DEP_CLIN_SERV',
                                              l_err);
            pk_alert_exceptions.reset_error_state;
            RETURN '';
    END get_room_dep_clin_serv;

    /***************************************************************************************************************
    *
    * Returns the specialties of a room; if not available, of its department.
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_room             ID of the room.   
    * @param      o_dcs              Cursor containing information of a specialty.
    * @param      o_error            If an error accurs, this parameter will have information about the error
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
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_dep department.id_department%TYPE;
        l_dcs    table_number;
    BEGIN
    
        g_error := 'CALL GET_ROOM_SPECIALITIES WITH i_room=' || i_room;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng_core.get_room_specialties(i_lang  => i_lang,
                                                 i_prof  => i_prof,
                                                 i_room  => i_room,
                                                 o_dcs   => l_dcs,
                                                 o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_dcs.count = 0
        THEN
            g_error := 'GET DEPARTMENT';
            pk_alertlog.log_debug(g_error);
            SELECT r.id_department
              INTO l_id_dep
              FROM room r
             WHERE r.id_room = i_room;
        
            g_error := 'CALL GET_DEP_SPECIALITIES WITH l_id_dep=' || l_id_dep;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_bmng_core.get_dep_specialties(i_lang => i_lang,
                                                    i_prof => i_prof,
                                                    i_dep  => l_id_dep,
                                                    
                                                    o_dcs   => l_dcs,
                                                    o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_dcs.count > 0
        THEN
            g_error := 'GET DESCRIPTS';
            pk_alertlog.log_debug(g_error);
            OPEN o_dcs FOR
                SELECT dcs.id_dep_clin_serv, pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_cs
                  FROM dep_clin_serv dcs
                 INNER JOIN clinical_service cs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                 WHERE dcs.id_dep_clin_serv IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                 t.column_value
                                                  FROM TABLE(l_dcs) t)
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND cs.flg_available = pk_alert_constant.g_yes;
            --
        ELSE
            pk_types.open_my_cursor(o_dcs);
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
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_bed              ID of the bed.   
    *
    *
    * @RETURN  VARCHAR2 with description of the specialty
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
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_room room.id_room%TYPE;
        l_id_dep  department.id_department%TYPE;
        l_dcs     table_number;
    BEGIN
        g_error := 'CALL GET_BED_SPECIALITIES WITH i_bed=' || i_bed;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng_core.get_bed_specialties(i_lang  => i_lang,
                                                i_prof  => i_prof,
                                                i_bed   => i_bed,
                                                o_dcs   => l_dcs,
                                                o_error => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_dcs.count = 0
        THEN
            g_error := 'GET ROOM';
            pk_alertlog.log_debug(g_error);
            SELECT b.id_room
              INTO l_id_room
              FROM bed b
             WHERE b.id_bed = i_bed;
        
            g_error := 'CALL GET_ROOM_SPECIALITIES WITH i_room=' || l_id_room;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_bmng_core.get_room_specialties(i_lang  => i_lang,
                                                     i_prof  => i_prof,
                                                     i_room  => l_id_room,
                                                     o_dcs   => l_dcs,
                                                     o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_dcs.count = 0
        THEN
            g_error := 'GET DEPARTMENT';
            pk_alertlog.log_debug(g_error);
            SELECT r.id_department
              INTO l_id_dep
              FROM room r
             WHERE r.id_room = l_id_room;
        
            g_error := 'CALL GET_DEP_SPECIALITIES WITH=l_id_dep' || l_id_dep;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_bmng_core.get_dep_specialties(i_lang => i_lang,
                                                    i_prof => i_prof,
                                                    i_dep  => l_id_dep,
                                                    
                                                    o_dcs   => l_dcs,
                                                    o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_dcs.count > 0
        THEN
            g_error := 'GET DESCRIPTS';
            pk_alertlog.log_debug(g_error);
            OPEN o_dcs FOR
                SELECT dcs.id_dep_clin_serv, pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_cs
                  FROM dep_clin_serv dcs
                 INNER JOIN clinical_service cs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                 WHERE dcs.id_dep_clin_serv IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                 t.column_value
                                                  FROM TABLE(l_dcs) t)
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND cs.flg_available = pk_alert_constant.g_yes;
        
        ELSE
            pk_types.open_my_cursor(o_dcs);
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
        o_serv        OUT pk_types.cursor_type,
        o_un_beds     OUT pk_types.cursor_type,
        o_av_beds     OUT pk_types.cursor_type,
        o_cap         OUT pk_types.cursor_type,
        o_room_types  OUT pk_types.cursor_type,
        o_date_server OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dep_nch  table_number := table_number();
        l_dep_ids  table_number := table_number();
        l_dep_bbs  table_number := table_number();
        l_dep_cap  table_number := table_number();
        l_dep_info pk_types.cursor_type;
    
        l_deps table_number := table_number();
        l_acc  PLS_INTEGER := i_deps.count;
        l_null VARCHAR2(3) := '---';
        l_mask sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'DATE_FORMAT_M006');
    
        l_count_temp_beds sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_code_cf => 'BMNG_COUNT_TEMP_BEDS',
                                                                               i_prof    => i_prof),
                                                       pk_alert_constant.g_yes);
    
    BEGIN
        g_error := 'GET FORMATTED TIMESTAMP';
        pk_alertlog.log_debug(g_error);
    
        o_date_server := pk_date_utils.to_char_insttimezone(i_lang, i_prof, current_timestamp, l_mask);
    
        g_error := 'GET ALL SERVICES DATA';
        pk_alertlog.log_debug(g_error);
        SELECT DISTINCT bdea.id_department
          BULK COLLECT
          INTO l_deps
          FROM bmng_department_ea bdea
         INNER JOIN department d
            ON (d.id_department = bdea.id_department AND d.flg_available = pk_alert_constant.g_yes)
         WHERE instr(d.flg_type, 'I') > 0;
    
        IF i_deps.count = l_deps.count
        THEN
        
            g_error := 'GET ALL SERVICES';
            pk_alertlog.log_debug(g_error);
            OPEN o_serv FOR
                SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T002') title,
                       '' label,
                       '' data,
                       pk_alert_constant.g_no flg_total
                  FROM dual;
        
        ELSIF l_acc = 1
        THEN
            g_error := 'GET SERVICE DATA WITH i_deps(1)=' || i_deps(1);
            pk_alertlog.log_debug(g_error);
            l_deps := i_deps;
            --TO-DO: blocking reasons.
            --Not available on this version.
            OPEN o_serv FOR
                SELECT --i_dep id_department,
                 pk_translation.get_translation(i_lang, d.code_department) title,
                 '' label,
                 '' data,
                 pk_alert_constant.g_no flg_total
                  FROM department d
                 WHERE d.id_department = i_deps(1);
        
        ELSE
            g_error := 'GET SELECTED SERVICES DATA';
            pk_alertlog.log_debug(g_error);
            l_deps := i_deps;
            OPEN o_serv FOR
                SELECT REPLACE(pk_message.get_message(i_lang, 'BMNG_VIEWER_T031'), '@1', l_acc) title,
                       '' label,
                       '' data,
                       pk_alert_constant.g_no flg_total
                  FROM dual;
        
        END IF;
    
        g_error := 'CALL GET_TOTAL_DEPARTMENT_INFO';
        pk_alertlog.log_debug(g_error);
        IF NOT get_total_department_info(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_department  => l_deps,
                                         i_institution => i_prof.institution,
                                         i_dt_request  => current_timestamp,
                                         o_dep_info    => l_dep_info,
                                         o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH GET_TOTAL_DEPARTMENT_INFO RESULTS';
        pk_alertlog.log_debug(g_error);
        FETCH l_dep_info BULK COLLECT
            INTO l_dep_ids, l_dep_bbs, l_dep_nch, l_dep_cap;
    
        CLOSE l_dep_info;
    
        g_error := 'GET UNAVAILABLE BEDS';
        pk_alertlog.log_debug(g_error);
        OPEN o_un_beds FOR
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T003') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T027') || ':' label,
                   SUM(bdea.beds_ocuppied) data,
                   pk_alert_constant.g_no flg_total
              FROM bmng_department_ea bdea
             WHERE bdea.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(l_deps) t)
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T003') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T004') || ':' label,
                   SUM(bdea.beds_reserved) data,
                   pk_alert_constant.g_no flg_total
              FROM bmng_department_ea bdea
             WHERE bdea.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(l_deps) t)
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T003') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T005') || ':' label,
                   SUM(bdea.beds_blocked) data,
                   pk_alert_constant.g_no flg_total
              FROM bmng_department_ea bdea
             WHERE bdea.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(l_deps) t)
            
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T003') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T006') || ':' label,
                   SUM(bdea.total_unavailable_beds) data,
                   pk_alert_constant.g_yes flg_total
              FROM bmng_department_ea bdea
             WHERE bdea.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(l_deps) t);
    
        g_error := 'GET AVAILABLE BEDS';
        pk_alertlog.log_debug(g_error);
        OPEN o_av_beds FOR
        --General Beds
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T028') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T007') || ':' label,
                   COUNT(b.id_bed) data,
                   pk_alert_constant.g_no flg_total
              FROM bed b
             INNER JOIN room r
                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN bed_dep_clin_serv bdcs
                ON (bdcs.id_bed = b.id_bed AND bdcs.flg_available = pk_alert_constant.g_yes)
             WHERE b.flg_available = pk_alert_constant.g_yes
               AND b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
               AND b.flg_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
               AND bdcs.id_bed IS NULL
               AND r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(l_deps) t)
            UNION ALL
            --Specialty Beds                           
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T028') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T008') || ':' label,
                   COUNT(DISTINCT b.id_bed) data,
                   pk_alert_constant.g_no flg_total
              FROM bed b
             INNER JOIN room r
                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
             INNER JOIN bed_dep_clin_serv bdcs
                ON (bdcs.id_bed = b.id_bed AND bdcs.flg_available = pk_alert_constant.g_yes)
             WHERE b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
               AND b.flg_available = pk_alert_constant.g_yes
               AND b.flg_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
               AND r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(l_deps) t)
            UNION ALL
            --Total beds
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T028') title,
                   pk_message.get_message(i_lang, 'BMNG_VIEWER_T006') || ':' label,
                   COUNT(b.id_bed) data,
                   pk_alert_constant.g_yes flg_total
              FROM bed b
             INNER JOIN room r
                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
             WHERE b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
               AND b.flg_available = pk_alert_constant.g_yes
               AND b.flg_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
               AND r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(l_deps) t);
    
        g_error := 'GET CAPACITY';
        pk_alertlog.log_debug(g_error);
    
        IF i_deps.count > 1
        THEN
            OPEN o_cap FOR
                SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T029') title,
                       
                       pk_message.get_message(i_lang, 'BMNG_VIEWER_T009') || ':' label,
                       
                       l_null                 data,
                       pk_alert_constant.g_no flg_total
                  FROM dual;
        
        ELSE
        
            OPEN o_cap FOR
                SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T029') title,
                       pk_message.get_message(i_lang, 'BMNG_VIEWER_T009') || ':' label,
                       decode(nvl(data.total_av_nch_hours, 0),
                              0,
                              l_null,
                              pk_nch_pbl.get_format_nch_info(i_lang, data.total_ocuppied_nch_hours) || '/' ||
                              pk_nch_pbl.get_format_nch_info(i_lang, data.total_av_nch_hours) || ' (' || data.percentage || '%)') data,
                       pk_alert_constant.g_no flg_total
                  FROM (SELECT total_ocuppied_nch_hours,
                               total_av_nch_hours,
                               decode(nvl(total_av_nch_hours, 0),
                                      0,
                                      l_null,
                                      TRIM(to_char((total_ocuppied_nch_hours / total_av_nch_hours * 100), '9999'))) percentage
                          FROM (SELECT SUM(t_nch.value) total_ocuppied_nch_hours, SUM(t_cap.value) total_av_nch_hours
                                  FROM bmng_department_ea bdea
                                 INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                             rownum rnum, t.column_value VALUE
                                              FROM TABLE(l_dep_ids) t) t_deps
                                    ON t_deps.value = bdea.id_department
                                 INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                             rownum rnum, nvl(t.column_value, 0) VALUE
                                              FROM TABLE(l_dep_nch) t) t_nch
                                    ON t_nch.rnum = t_deps.rnum
                                  LEFT JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                             rownum rnum, t.column_value VALUE
                                              FROM TABLE(l_dep_cap) t) t_cap
                                    ON t_cap.rnum = t_nch.rnum)) data;
        END IF;
    
        g_error := 'GET ROOM TYPES';
        pk_alertlog.log_debug(g_error);
        OPEN o_room_types FOR
            SELECT pk_message.get_message(i_lang, 'BMNG_VIEWER_T028') title,
                   decode(rt.id_room_type,
                          0,
                          pk_message.get_message(i_lang, rt.code_room_type),
                          nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type))) || ': ' label,
                   nvl(data_o.total, 0) || '/' || nvl(data_t.total, 0) data,
                   pk_alert_constant.g_no flg_total
              FROM (SELECT r.id_room_type, r.code_room_type, r.desc_room_type
                      FROM room_type r
                     WHERE r.id_institution IN (0, i_prof.institution)
                       AND (r.flg_status IS NULL OR r.flg_status <> pk_alert_constant.g_flg_status_c)
                       AND r.flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT 0 id_room_type, 'BMNG_T112' code_room_type, NULL desc_room_type
                      FROM dual) rt
              LEFT JOIN (SELECT nvl(r.id_room_type, 0) id_room_type, COUNT(b.id_bed) total
                           FROM bed b
                          INNER JOIN room r
                             ON (b.id_room = r.id_room AND r.flg_available = pk_alert_constant.g_yes)
                          WHERE b.flg_available = pk_alert_constant.g_yes
                            AND b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                            AND b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
                            AND r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(l_deps) t)
                          GROUP BY r.id_room_type) data_o
                ON nvl(rt.id_room_type, 0) = data_o.id_room_type
              LEFT JOIN (SELECT nvl(r.id_room_type, 0) id_room_type, COUNT(b.id_bed) total
                           FROM room r
                          INNER JOIN bed b
                             ON (b.id_room = r.id_room AND b.flg_available = pk_alert_constant.g_yes)
                          WHERE r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(l_deps) t)
                            AND r.flg_available = pk_alert_constant.g_yes
                            AND ((l_count_temp_beds = pk_alert_constant.g_no AND
                                b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p) OR
                                l_count_temp_beds = pk_alert_constant.g_yes)
                          GROUP BY r.id_room_type) data_t
                ON nvl(rt.id_room_type, 0) = data_t.id_room_type
             ORDER BY regexp_substr(label, '^\D*') NULLS FIRST, to_number(regexp_substr(label, '\d+'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VIEWER_SUMMARY',
                                              o_error);
        
            pk_types.open_my_cursor(o_serv);
            pk_types.open_my_cursor(o_un_beds);
            pk_types.open_my_cursor(o_av_beds);
            pk_types.open_my_cursor(o_cap);
            pk_types.open_my_cursor(o_room_types);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_viewer_summary;

    FUNCTION get_unassigned_patients_v2
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN table_number,
        o_pats  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dep           table_number;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'GET DEPS';
        pk_alertlog.log_debug(g_error);
        IF (i_dep IS NULL)
        THEN
            SELECT bde.id_department
              BULK COLLECT
              INTO l_dep
              FROM bmng_department_ea bde
             INNER JOIN department d
                ON (d.id_department = bde.id_department AND d.flg_available = pk_alert_constant.g_yes)
             WHERE instr(d.flg_type, 'I') > 0;
        ELSE
            l_dep := i_dep;
        END IF;
    
        g_error := 'GET PATIENTS';
        pk_alertlog.log_debug(g_error);
        OPEN o_pats FOR
            SELECT data.id_bed,
                   data.id_room,
                   data.id_department,
                   data.desc_dep,
                   data.desc_dep_short desc_dep_short,
                   data.desc_specs,
                   data.id_episode,
                   data.id_patient,
                   data.dt_schedule,
                   data.room_desc_name,
                   data.bed_desc_name,
                   data.bed_desc_spec,
                   data.pat_photo,
                   data.pat_gender,
                   data.pat_age,
                   decode(data.flag_shed,
                          pk_alert_constant.g_yes,
                          pk_api_adm_request.get_adm_indication_desc(i_lang, i_prof, data.id_waiting_list),
                          pk_api_adm_request.get_all_diagnosis_str(i_lang, data.id_episode)) desc_adm_indic,
                   decode(data.nch_hours_num, NULL, '', pk_nch_pbl.get_format_nch_info(i_lang, data.nch_hours_num)) nch_hours,
                   to_char(data.nch_hours_num) nch_hours_num,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(data.flag_shed,
                                                      pk_alert_constant.g_yes,
                                                      data.sch_dt_begin,
                                                      
                                                      data.dt_begin_epis),
                                               i_prof) dt_begin,
                   decode(data.flag_shed,
                          pk_alert_constant.g_yes,
                          pk_date_utils.date_send_tsz(i_lang,
                                                      data.sch_dt_end,
                                                      
                                                      i_prof),
                          NULL) dt_discharge_schedule,
                   pk_discharge.g_disch_flg_hour_dh flg_hour_origin,
                   data.flag_shed,
                   pk_patient.get_pat_name(i_lang, i_prof, data.id_patient, data.id_episode) name_pat,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, data.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, data.id_patient) pat_nd_icon
              FROM (SELECT b.id_bed id_bed,
                           r.id_room,
                           d.id_department,
                           ei.id_department id_department_sch,
                           ei.ep_flg_status,
                           pk_translation.get_translation(i_lang, d.code_department) ||
                           decode(nvl(at.desc_admission_type, at.code_admission_type),
                                  NULL,
                                  '',
                                  ' (' || nvl(at.desc_admission_type,
                                              pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                           pk_translation.get_translation(i_lang, d.code_department) desc_dep_short,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specs,
                           ei.id_episode,
                           pat.id_patient,
                           '' dt_schedule,
                           decode(ei.id_department,
                                  ei.department_sched,
                                  decode(transf_count,
                                         0,
                                         nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)),
                                         NULL),
                                  NULL) room_desc_name,
                           decode(ei.id_department,
                                  ei.department_sched,
                                  decode(transf_count,
                                         0,
                                         nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)),
                                         NULL),
                                  NULL) bed_desc_name,
                           
                           get_bed_dep_clin_serv(i_lang, i_prof, b.id_bed) bed_desc_spec,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, we.id_episode, NULL) pat_photo,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_hand_off_type) resp_icons,
                           pk_patient.get_gender(i_lang, pat.gender) pat_gender,
                           pk_patient.get_pat_age(i_lang,
                                                  pat.dt_birth,
                                                  pat.dt_deceased,
                                                  pat.age,
                                                  i_prof.institution,
                                                  i_prof.software) pat_age,
                           pk_nch_pbl.get_nch_total(i_lang, i_prof, ei.id_episode, NULL) nch_hours_num,
                           decode(transf_count, 0, ei.dt_begin_tstz, NULL) sch_dt_begin,
                           decode(transf_count, 0, ei.dt_end_tstz, NULL) sch_dt_end,
                           decode(ei.id_bed, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flag_shed,
                           we.id_waiting_list,
                           ei.dt_begin_epis
                      FROM bmng_department_ea bde
                     INNER JOIN department d
                        ON d.id_department = bde.id_department
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND instr(d.flg_type, 'I') > 0
                     INNER JOIN (SELECT nei.id_episode,
                                       nvl(nei.id_bed, nsb.id_bed) id_bed,
                                       nbde.id_department,
                                       nei.id_dep_clin_serv,
                                       rs.id_department department_sched,
                                       decode(nd.id_department, rs.id_department, ns.id_schedule, NULL) id_schedule,
                                       decode(nd.id_department, rs.id_department, ns.dt_begin_tstz, NULL) dt_begin_tstz,
                                       decode(nd.id_department, rs.id_department, ns.dt_end_tstz, NULL) dt_end_tstz,
                                       nep.dt_begin_tstz dt_begin_epis,
                                       nep.id_patient,
                                       nep.flg_status ep_flg_status,
                                       (SELECT COUNT(1)
                                          FROM epis_prof_resp
                                         WHERE id_episode = nei.id_episode
                                           AND flg_transf_type = 'S'
                                           AND flg_status NOT IN ('C', 'R')) transf_count,
                                       pk_patient.get_pat_age(i_lang        => i_lang,
                                                              i_dt_birth    => NULL,
                                                              i_dt_deceased => NULL,
                                                              i_age         => NULL,
                                                              i_patient     => nep.id_patient) pat_age_n
                                  FROM epis_info nei
                                 INNER JOIN episode nep
                                    ON nep.id_episode = nei.id_episode
                                 INNER JOIN dep_clin_serv ndcs
                                    ON ndcs.id_dep_clin_serv = nei.id_dep_clin_serv
                                 INNER JOIN bmng_department_ea nbde
                                    ON ndcs.id_department = nbde.id_department
                                 INNER JOIN department nd
                                    ON nd.id_department = nbde.id_department
                                   AND nd.id_institution = i_prof.institution
                                   AND instr(nd.flg_type, 'I') > 0
                                  LEFT JOIN schedule ns
                                    ON nei.id_episode = ns.id_episode
                                   AND ns.flg_status <> pk_schedule.g_status_canceled
                                  LEFT JOIN schedule_bed nsb
                                    ON nsb.id_schedule = ns.id_schedule
                                  LEFT JOIN bed bs
                                    ON bs.id_bed = nsb.id_bed
                                  LEFT JOIN room rs
                                    ON rs.id_room = bs.id_room
                                 WHERE nei.id_bed IS NULL
                                   AND nei.id_episode NOT IN
                                       (SELECT id_episode
                                          FROM bmng_bed_ea bbe
                                         WHERE bbe.id_episode = nei.id_episode
                                           AND bbe.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_r)
                                   AND nep.flg_status = pk_alert_constant.g_epis_status_active
                                   AND nep.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                                   AND nep.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                                   AND nd.id_department IN
                                       (SELECT /*+ opt_estimate (table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(CAST(l_dep AS table_number)) t)
                                   AND NOT EXISTS
                                 (SELECT 1
                                          FROM discharge disch
                                         WHERE disch.id_episode = nei.id_episode
                                           AND disch.flg_status = pk_discharge.g_disch_flg_active)) ei
                        ON (ei.id_department = d.id_department)
                     INNER JOIN patient pat
                        ON ei.id_patient = pat.id_patient
                     INNER JOIN dep_clin_serv dcs
                        ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
                     INNER JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN admission_type at
                        ON at.id_admission_type = d.id_admission_type
                      LEFT JOIN wtl_epis we
                        ON (we.id_episode = ei.id_episode AND we.id_epis_type = pk_alert_constant.g_soft_inpatient)
                      LEFT JOIN bed b
                        ON (b.id_bed = ei.id_bed AND b.flg_available = pk_alert_constant.g_yes)
                      LEFT JOIN room r
                        ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
                     WHERE d.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_dep) t)
                       AND (d.adm_age_min IS NULL OR (d.adm_age_min IS NOT NULL AND d.adm_age_min <= ei.pat_age_n) OR
                           ei.pat_age_n IS NULL)
                       AND (d.adm_age_max IS NULL OR (d.adm_age_max IS NOT NULL AND d.adm_age_max >= ei.pat_age_n) OR
                           ei.pat_age_n IS NULL)
                       AND ((d.gender IS NOT NULL AND d.gender <> pat.gender) OR d.gender IS NULL)) data
             ORDER BY name_pat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_UNASSIGNED_PATIENTS_V2',
                                              o_error);
        
            pk_types.open_my_cursor(o_pats);
            RETURN FALSE;
    END get_unassigned_patients_v2;

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
        l_timestamp_str VARCHAR2(200) := nvl(i_date,
                                             pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_timestamp => current_timestamp,
                                                                                i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss));
    
    BEGIN
        g_error := 'GET MESSAGE';
        pk_alertlog.log_debug(g_error);
    
        o_msg_title := pk_message.get_message(i_lang, 'BMNG_M016');
        o_msg_body  := pk_message.get_message(i_lang, 'BMNG_M017');
        BEGIN
            g_error := 'CHECK BED';
            pk_alertlog.log_debug(g_error);
        
            --No need for replacements. 
            SELECT decode(COUNT(ba.id_bmng_action), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_show
              INTO o_flg_show
            
              FROM bmng_action ba
             WHERE ba.id_bed = i_bed
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND l_timestamp_str >= pk_date_utils.trunc_insttimezone(i_prof, ba.dt_begin_action)
               AND (l_timestamp_str <= pk_date_utils.trunc_insttimezone(i_prof, ba.dt_end_action) OR
                   ba.dt_end_action IS NOT NULL)
               AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'NO NEXT BLOCKINGS';
                pk_alertlog.log_debug(g_error);
                o_flg_show := pk_alert_constant.g_no;
            
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
        l_dt     TIMESTAMP WITH LOCAL TIME ZONE;
        l_int    PLS_INTEGER;
        l_dt_ref TIMESTAMP WITH LOCAL TIME ZONE := nvl(to_timestamp(i_date, pk_alert_constant.g_dt_yyyymmddhh24miss), current_timestamp);
    BEGIN
        --This bed is only available for @1 and the patient you selected has an admission duration of @2.
    
        g_error := 'GET NEXT SCHED';
        pk_alertlog.log_debug(g_error);
        l_dt := pk_bmng_core.get_next_schedule_date(i_lang, i_prof, i_bed, current_timestamp);
    
        IF l_dt IS NOT NULL
           AND l_dt_ref > l_dt
        THEN
            l_int      := pk_date_utils.diff_timestamp(l_dt_ref, current_timestamp);
            o_flg_show := pk_alert_constant.g_yes;
        
            g_error := 'GET MESSAGES';
            pk_alertlog.log_debug(g_error);
        
            o_msg_title := pk_message.get_message(i_lang, 'BMNG_M003');
            SELECT REPLACE(REPLACE(pk_message.get_message(i_lang, 'BMNG_M004'),
                                   '@1',
                                   trunc(pk_date_utils.get_timestamp_diff(l_dt, current_timestamp))),
                           '@2',
                           l_int)
            
              INTO o_msg_body
              FROM dual;
        
        ELSE
            o_flg_show := pk_alert_constant.g_no;
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
                                              'check_dt_next_scheduling',
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
        l_dur PLS_INTEGER;
        l_lvl PLS_INTEGER;
    BEGIN
    
        g_error := 'CHECK BED NCH LEVEL';
        pk_alertlog.log_debug(g_error);
        -- by the system after @1 to level @2. 
    
        BEGIN
            SELECT decode(COUNT(b.id_bmng_action), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_show,
                   nl.duration,
                   nl.value
            
              INTO o_flg_show, l_dur, l_lvl
            
              FROM bmng_bed_ea b
             INNER JOIN nch_level nl
                ON nl.id_nch_level = b.id_nch_level
              LEFT JOIN nch_level nln
                ON nln.id_previous = nl.id_nch_level
             WHERE b.id_bed = i_bed
               AND b.flg_allocation_nch = pk_bmng_constant.g_bmng_allocat_flg_nch_u
               AND nln.id_nch_level IS NOT NULL
             GROUP BY nl.duration, nl.value;
        
        EXCEPTION
        
            WHEN no_data_found THEN
                g_error := 'NO NEXT BLOCKINGS';
                pk_alertlog.log_debug(g_error);
                o_flg_show := pk_alert_constant.g_no;
            
        END;
    
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            g_error := 'GET MESSAGES';
            pk_alertlog.log_debug(g_error);
            o_msg_title := pk_message.get_message(i_lang, 'BMNG_M005');
            o_msg_body  := REPLACE(REPLACE(pk_message.get_message(i_lang, 'BMNG_M006'), '@1', l_dur), '@2', l_lvl);
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
                                              'CHECK_DT_NEXT_NCH_LEVEL',
                                              o_error);
            RETURN FALSE;
    END check_next_nch_level;

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
        o_deps  OUT pk_types.cursor_type,
        o_beds  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dep           table_number;
        l_dt            TIMESTAMP WITH LOCAL TIME ZONE;
        l_default_nch   PLS_INTEGER;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_default_nch := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_pat, i_prof);
        l_dt          := current_timestamp;
    
        g_error := 'GET DEPARTMENTS';
        IF (i_dep IS NULL)
           OR (i_dep.count = 0)
        THEN
            SELECT DISTINCT bde.id_department
              BULK COLLECT
              INTO l_dep
              FROM bmng_department_ea bde
             INNER JOIN dep_clin_serv dcs
                ON (dcs.id_department = bde.id_department AND dcs.flg_available = pk_alert_constant.g_yes)
             INNER JOIN prof_dep_clin_serv pdcs
                ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
             INNER JOIN department d
                ON (d.id_department = dcs.id_department AND d.flg_available = pk_alert_constant.g_yes)
               AND instr(d.flg_type, 'I') > 0
             WHERE pdcs.flg_status IN ('S', 'D')
               AND pdcs.id_professional = i_prof.id
               AND d.id_institution = i_prof.institution;
        
        ELSE
            l_dep := i_dep;
        END IF;
    
        g_error := 'OPEN AVAILABLE SERVICES';
        OPEN o_deps FOR
            SELECT data.id_department,
                   data.desc_dep,
                   data.rank,
                   data.desc_specs,
                   decode(data.nch_dif, NULL, NULL, pk_nch_pbl.get_format_nch_info(i_lang, data.nch_dif)) desc_available_nch,
                   data.nch_dif service_available_nch
              FROM (SELECT bdea.id_department,
                           pk_translation.get_translation(i_lang, d.code_department) ||
                           decode(nvl(at.desc_admission_type, at.code_admission_type),
                                  NULL,
                                  '',
                                  ' (' || nvl(at.desc_admission_type,
                                              pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                           d.rank,
                           pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, bdea.id_department) desc_specs,
                           pk_bmng_core.get_nch_service_level(i_lang, i_prof, bdea.id_department) nch_req,
                           ba.nch_capacity nch_cap,
                           CASE
                                WHEN ba.nch_capacity IS NULL THEN
                                 NULL
                                WHEN (ba.nch_capacity -
                                     pk_bmng_core.get_nch_service_level(i_lang, i_prof, bdea.id_department)) < 0 THEN
                                 0
                                ELSE
                                 (ba.nch_capacity - pk_bmng_core.get_nch_service_level(i_lang, i_prof, bdea.id_department))
                            END nch_dif
                      FROM bmng_department_ea bdea
                     INNER JOIN department d
                        ON d.id_department = bdea.id_department
                       AND instr(d.flg_type, 'I') > 0
                      LEFT JOIN bmng_action ba
                        ON ba.id_department = d.id_department
                       AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                       AND l_dt >=
                           pk_date_utils.trunc_insttimezone(i_prof.institution, i_prof.software, ba.dt_begin_action)
                       AND (l_dt <=
                           pk_date_utils.trunc_insttimezone(i_prof.institution, i_prof.software, ba.dt_end_action) OR
                           ba.dt_end_action IS NULL)
                       AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_s
                       AND ba.flg_origin_action IN (pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                                    pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                                    pk_bmng_constant.g_bmng_act_flg_origin_nd)
                      LEFT JOIN admission_type at
                        ON at.id_admission_type = d.id_admission_type
                     WHERE d.id_institution = i_prof.institution
                       AND d.flg_available = pk_alert_constant.g_yes) data
             ORDER BY data.rank, data.desc_dep;
    
        g_error := 'OPEN SELECTED SERVICE';
        OPEN o_beds FOR
            SELECT dd.id_bed,
                   dd.bed_flg_type,
                   dd.id_bed_type,
                   dd.id_bmng_action,
                   dd.id_bmng_allocation_bed,
                   dd.id_room,
                   dd.id_room_type,
                   dd.id_department,
                   dd.desc_dep,
                   dd.desc_dep_short,
                   dd.desc_specs,
                   dd.dt_begin,
                   dd.dt_end,
                   dd.allocation_notes,
                   dd.id_episode,
                   dd.id_patient,
                   dd.dt_schedule,
                   dd.room_desc_name,
                   dd.room_desc_type,
                   dd.bed_desc_name,
                   dd.bed_desc_type,
                   dd.bed_desc_spec,
                   dd.bed_status_avail,
                   dd.bed_status_conflict,
                   dd.pat_photo,
                   dd.pat_gender,
                   dd.pat_age,
                   dd.desc_adm_indic,
                   decode(dd.id_episode, NULL, '', pk_nch_pbl.get_format_nch_info(i_lang, dd.nch_hours_num)) nch_hours,
                   dd.nch_reason_notes,
                   dd.nch_hours_num,
                   dd.desc_status_time_left,
                   dd.bed_ocupacity_status,
                   dd.bed_ocupacity_icon,
                   dd.bed_cleaning_status,
                   dd.bed_cleaning_icon,
                   dd.dt_discharge_schedule,
                   dd.flg_bed_sts_toflash,
                   dd.flg_bed_clean_sts_toflash,
                   dd.days_availability,
                   dd.count_reservations,
                   dd.count_ocupation,
                   dd.flg_hour_origin,
                   pk_patient.get_pat_name(i_lang, i_prof, dd.id_patient, dd.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, dd.id_patient, dd.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, dd.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dd.id_patient) pat_nd_icon,
                   row_number() over(ORDER BY dd.room_rank, regexp_substr(upper(dd.room_desc_name), '^\D*') NULLS FIRST, to_number(regexp_substr(upper(dd.room_desc_name), '\d+')), dd.bed_rank, regexp_substr(upper(dd.bed_desc_name), '^\D*') NULLS FIRST, to_number(regexp_substr(upper(dd.bed_desc_name), '\d+'))) rank_ord
              FROM (SELECT b.id_bed,
                           b.flg_type bed_flg_type,
                           CASE
                                WHEN bt.id_bed_type = -1 THEN
                                 NULL
                                ELSE
                                 bt.id_bed_type
                            END id_bed_type,
                           bbea.id_bmng_action,
                           bbea.id_bmng_allocation_bed,
                           r.id_room,
                           rt.id_room_type,
                           r.id_department,
                           pk_translation.get_translation(i_lang, d.code_department) ||
                           decode(nvl(at.desc_admission_type, at.code_admission_type),
                                  NULL,
                                  '',
                                  ' (' || nvl(at.desc_admission_type,
                                              pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                           pk_translation.get_translation(i_lang, d.code_department) desc_dep_short,
                           pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specs,
                           pk_date_utils.date_send_tsz(i_lang, bbea.dt_begin, i_prof) dt_begin,
                           pk_date_utils.date_send_tsz(i_lang, bbea.dt_end, i_prof) dt_end,
                           pk_date_utils.date_send_tsz(i_lang, en.dt_begin, i_prof) dt_begin_nch,
                           pk_date_utils.date_send_tsz(i_lang, en.dt_end, i_prof) dt_end_nch,
                           bab.allocation_notes,
                           bbea.id_episode,
                           pat.id_patient,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       pk_bmng_core.get_next_schedule_date(i_lang,
                                                                                           i_prof,
                                                                                           b.id_bed,
                                                                                           current_timestamp),
                                                       i_prof) dt_schedule,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc_name,
                           nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc_type,
                           decode(b.flg_type,
                                  pk_bmng_constant.g_bmng_bed_flg_type_t,
                                  b.desc_bed,
                                  nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))) bed_desc_name,
                           CASE
                                WHEN bt.id_bed_type = -1 THEN
                                 NULL
                                ELSE
                                 nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type))
                            END bed_desc_type,
                           get_bed_dep_clin_serv(i_lang, i_prof, b.id_bed) bed_desc_spec,
                           icons.desc_availability bed_status_avail,
                           icons.flg_conflict bed_status_conflict,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, we.id_episode, NULL) pat_photo,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, bab.id_episode, l_hand_off_type) resp_icons,
                           pk_patient.get_gender(i_lang, pat.gender) pat_gender,
                           pk_patient.get_pat_age(i_lang,
                                                  pat.dt_birth,
                                                  pat.dt_deceased,
                                                  pat.age,
                                                  i_prof.institution,
                                                  i_prof.software) pat_age,
                           decode(we.id_waiting_list,
                                  NULL,
                                  pk_api_adm_request.get_all_diagnosis_str(i_lang, bbea.id_episode),
                                  pk_api_adm_request.get_adm_indication_desc(i_lang, i_prof, we.id_waiting_list)) desc_adm_indic,
                           decode(bbea.id_episode,
                                  NULL,
                                  NULL,
                                  nvl(pk_nch_pbl.get_nch_total(i_lang, i_prof, bbea.id_episode, l_dt), l_default_nch)) nch_hours_num,
                           decode(bbea.id_episode, NULL, NULL, en.reason_notes) nch_reason_notes,
                           decode(bbea.id_bmng_action,
                                  NULL,
                                  '',
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       'D',
                                                                       NULL,
                                                                       NULL,
                                                                       to_char(pk_inp_episode.get_disch_schedule_curr(i_lang,
                                                                                                                      i_prof,
                                                                                                                      bbea.id_episode),
                                                                               pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       current_timestamp)) desc_status_time_left,
                           icons.desc_bed_status bed_ocupacity_status,
                           icons.icon_bed_status bed_ocupacity_icon,
                           icons.desc_cleaning_status bed_cleaning_status,
                           icons.icon_bed_cleaning_status bed_cleaning_icon,
                           pk_date_utils.date_send_tsz(i_lang, bbea.dt_discharge_schedule, i_prof) dt_discharge_schedule,
                           icons.flg_bed_sts_toflash,
                           decode(icons.flg_bed_clean_sts_toflash,
                                  pk_alert_constant.get_no,
                                  NULL,
                                  icons.flg_bed_clean_sts_toflash) flg_bed_clean_sts_toflash,
                           icons.availability days_availability,
                           pk_bmng_core.get_count_bed_status(i_lang,
                                                             i_prof,
                                                             bbea.id_episode,
                                                             pk_bmng_constant.g_bmng_act_flg_bed_sta_r) count_reservations,
                           pk_bmng_core.get_count_bed_status(i_lang,
                                                             i_prof,
                                                             bbea.id_episode,
                                                             pk_bmng_constant.g_bmng_act_flg_bed_sta_n) count_ocupation,
                           r.rank room_rank,
                           b.rank bed_rank,
                           pk_discharge.get_dch_sch_flg_hour(i_lang, i_prof, bbea.id_episode) flg_hour_origin
                      FROM bed b
                     INNER JOIN room r
                        ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
                     INNER JOIN department d
                        ON (d.id_department = r.id_department AND d.flg_available = pk_alert_constant.g_yes)
                     INNER JOIN TABLE(pk_bmng_core.tf_get_bed_status(i_lang, i_prof, l_dep, NULL)) icons
                        ON icons.id_bed = b.id_bed
                      LEFT JOIN bmng_bed_ea bbea
                        ON bbea.id_bed = b.id_bed
                       AND bbea.dt_begin < l_dt
                       AND bbea.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o
                      LEFT JOIN bmng_allocation_bed bab
                        ON bab.id_bmng_allocation_bed = bbea.id_bmng_allocation_bed
                       AND bab.flg_outdated = pk_alert_constant.g_no
                      LEFT JOIN epis_nch en
                        ON en.id_epis_nch = bab.id_epis_nch
                       AND en.flg_status = pk_alert_constant.g_active
                      LEFT JOIN admission_type at
                        ON at.id_admission_type = d.id_admission_type
                      LEFT JOIN room_type rt
                        ON rt.id_room_type = r.id_room_type
                      LEFT JOIN bed_type bt
                        ON b.id_bed_type = bt.id_bed_type
                      LEFT JOIN wtl_epis we
                        ON we.id_episode = bbea.id_episode
                       AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                      LEFT JOIN patient pat
                        ON bbea.id_patient = pat.id_patient
                     WHERE r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_dep) t)
                       AND b.flg_available = pk_alert_constant.g_yes
                       AND NOT (b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_t AND
                            b.flg_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v)) dd
             ORDER BY rank_ord;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BEDS_SERVICE_GRID',
                                              o_error);
        
            pk_types.open_my_cursor(o_deps);
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_beds_service_grid;

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
        o_beds  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dep           table_number;
        l_dt            TIMESTAMP WITH LOCAL TIME ZONE;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_dt    := current_timestamp;
        g_error := 'GET DEPARTMENTS';
        pk_alertlog.log_debug(g_error);
        IF (i_dep IS NULL)
           OR (i_dep.count = 0)
        THEN
            SELECT DISTINCT bde.id_department
              BULK COLLECT
              INTO l_dep
              FROM bmng_department_ea bde
             INNER JOIN dep_clin_serv dcs
                ON (dcs.id_department = bde.id_department AND dcs.flg_available = pk_alert_constant.g_yes)
             INNER JOIN prof_dep_clin_serv pdcs
                ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
             INNER JOIN department d
                ON (d.id_department = dcs.id_department AND instr(d.flg_type, 'I') > 0 AND
                   d.flg_available = pk_alert_constant.g_yes)
             WHERE pdcs.flg_status IN ('S', 'D')
               AND pdcs.id_professional = i_prof.id
               AND d.id_institution = i_prof.institution;
        
        ELSE
            l_dep := i_dep;
        END IF;
    
        g_error := 'OPEN SELECTED SERVICE';
        pk_alertlog.log_debug(g_error);
        OPEN o_beds FOR
            SELECT b.id_bed,
                   b.flg_type bed_flg_type,
                   bt.id_bed_type,
                   bbea.id_bmng_action,
                   bbea.id_bmng_allocation_bed,
                   r.id_room,
                   rt.id_room_type,
                   r.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) ||
                   decode(nvl(at.desc_admission_type, at.code_admission_type),
                          NULL,
                          '',
                          ' (' ||
                          nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                   pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specs,
                   en.dt_begin,
                   en.dt_end,
                   bab.allocation_notes,
                   bbea.id_episode,
                   pat.id_patient,
                   pk_bmng_core.get_next_schedule_date(i_lang, i_prof, b.id_bed, bbea.dt_begin) dt_schedule,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc_name,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc_type,
                   decode(b.flg_type,
                          pk_bmng_constant.g_bmng_bed_flg_type_t,
                          b.desc_bed,
                          nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))) bed_desc_name,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_desc_type,
                   pk_bmng_core.get_all_bed_specs_int(i_lang, i_prof, b.id_bed) bed_desc_spec,
                   icons.desc_availability bed_status_avail,
                   icons.flg_conflict bed_status_conflict,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, we.id_episode, NULL) pat_photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, bbea.id_episode, l_hand_off_type) resp_icons,
                   pk_patient.get_gender(i_lang, pat.gender) pat_gender,
                   pk_patient.get_pat_age(i_lang,
                                          pat.dt_birth,
                                          pat.dt_deceased,
                                          pat.age,
                                          i_prof.institution,
                                          i_prof.software) pat_age,
                   decode(we.id_waiting_list,
                          NULL,
                          pk_api_adm_request.get_all_diagnosis_str(i_lang, bbea.id_episode),
                          pk_api_adm_request.get_adm_indication_desc(i_lang, i_prof, we.id_waiting_list)) desc_adm_indic,
                   decode(pat.id_patient,
                          NULL,
                          '',
                          pk_nch_pbl.get_format_nch_info(i_lang,
                                                         pk_nch_pbl.get_nch_total(i_lang, i_prof, bab.id_episode, l_dt))) nch_hours,
                   pk_nch_pbl.get_nch_total(i_lang, i_prof, bab.id_episode, l_dt) nch_hours_num,
                   icons.desc_bed_status bed_ocupacity_status,
                   icons.icon_bed_status bed_ocupacity_icon,
                   icons.desc_cleaning_status bed_cleaning_status,
                   icons.icon_bed_cleaning_status bed_cleaning_icon,
                   bbea.flg_bed_cleaning_status,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        decode(bbea.flg_bed_cleaning_status,
                                                               pk_bmng_constant.g_bmng_act_flg_cleani_d,
                                                               'DI',
                                                               pk_bmng_constant.g_bmng_act_flg_cleani_c,
                                                               'DI',
                                                               'I'),
                                                        bbea.flg_bed_cleaning_status,
                                                        NULL,
                                                        to_char(bbea.dt_begin, pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                        'BMNG_ACTION.FLG_BED_CLEANING_STATUS',
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        current_timestamp) bed_status_icon,
                   pk_date_utils.date_send_tsz(i_lang, bbea.dt_discharge_schedule, i_prof) dt_discharge_schedule,
                   pk_discharge.get_dch_sch_flg_hour(i_lang, i_prof, bab.id_episode) flg_hour_origin,
                   icons.flg_bed_sts_toflash,
                   icons.flg_bed_clean_sts_toflash,
                   icons.availability days_availability,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ba.id_prof_creation) prof_ordered,
                   pk_date_utils.to_char_timezone(i_lang,
                                                  ba.dt_creation,
                                                  pk_sysconfig.get_config('DATE_HOUR_FORMAT', i_prof)) dt_desc_ordered,
                   ba.dt_creation,
                   pk_patient.get_pat_name(i_lang, i_prof, bbea.id_patient, bbea.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, bbea.id_patient, bbea.id_episode) name_pat_to_sort,
                   
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, bbea.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, bbea.id_patient) pat_nd_icon
              FROM bed b
             INNER JOIN room r
                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
             INNER JOIN department d
                ON (d.id_department = r.id_department AND d.flg_available = pk_alert_constant.g_yes)
             INNER JOIN bmng_bed_ea bbea
                ON (bbea.id_bed = b.id_bed AND bbea.dt_begin < l_dt AND bbea.flg_bed_cleaning_status IS NOT NULL)
              LEFT JOIN bmng_action ba
                ON ba.id_bmng_action = bbea.id_bmng_action
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
              LEFT JOIN bmng_allocation_bed bab
                ON bab.id_bmng_allocation_bed = bbea.id_bmng_allocation_bed
               AND bab.flg_outdated = pk_alert_constant.g_no
              LEFT JOIN epis_nch en
                ON en.id_epis_nch = bab.id_epis_nch
              LEFT JOIN TABLE(pk_bmng_core.tf_get_bed_status(i_lang, i_prof, l_dep, table_number(bbea.id_bmng_action))) icons
                ON (icons.id_bed = b.id_bed)
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              LEFT JOIN room_type rt
                ON rt.id_room_type = r.id_room_type
              LEFT JOIN bed_type bt
                ON b.id_bed_type = bt.id_bed_type
              LEFT JOIN wtl_epis we
                ON we.id_episode = bbea.id_episode
              LEFT JOIN patient pat
                ON bbea.id_patient = pat.id_patient
             WHERE r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(l_dep) t)
               AND b.flg_available = pk_alert_constant.g_yes
             ORDER BY r.id_room, b.id_bed;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AUX_BEDS_GRID',
                                              o_error);
        
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_aux_beds_grid;

    /***************************************************************************************************************
    *
    * This function is called after a timeframe conflict is detected during a new timeframe insertion.
    * It receives information of the time frames already in the database and of the news ones to be inserted, 
    * then calculating reajustments to the old timeframes and providing the results to be displayed in the Timeframe conflict;
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    
    * The following 5 params must be synchronized between them
    * @param      i_dep               Array of id_departments of existing timeframes.    
    * @param      i_bed_action        Array of i_bed_action of existing timeframes.
    * @param      i_nch               Array of i_nch of existing timeframes.
    * @param      i_dt_begin          Array of i_dt_begin of existing timeframes.
    * @param      i_dt_end            Array of i_dt_end of existing timeframes.
    
    * The following 4 params must be synchronized between them
    * @param      i_dt_begin_new      Array of new timeframes' dt_begin.     
    * @param      i_dt_end_new        Array of new timeframes' dt_end.     
    * @param      i_nch_new           Array of new timeframes' nch.     
    * @param      i_dep_new           Array of new timeframes' dep.     
    
    * @param      o_grid              Cursor with information of existent timeframe conflicts as well as suggested solutions
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   22-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_conflicts_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dep          IN table_number,
        i_bed_action   IN table_number,
        i_nch          IN table_number,
        i_dt_begin     IN table_varchar,
        i_dt_end       IN table_varchar,
        i_dt_begin_new IN table_varchar,
        i_dt_end_new   IN table_varchar,
        i_nch_new      IN table_number,
        i_dep_new      IN table_number,
        o_grid         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_null VARCHAR2(3) := '---';
        l_mask sys_message.desc_message%TYPE := TRIM(pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'DATE_FORMAT_M006'));
    
        l_nch bmng_action.nch_capacity%TYPE;
        l_dep department.id_department%TYPE;
        l_ba  bmng_action.id_bmng_action%TYPE;
    
        l_dt_begin_new DATE;
        l_dt_end_new   DATE;
        l_dt_begin     DATE;
        l_dt_end       DATE;
    
        l_dep_new department.id_department%TYPE;
    
        l_ba_final       table_number := table_number();
        l_dt_begin_final table_varchar := table_varchar();
        l_dt_end_final   table_varchar := table_varchar();
        l_nch_final      table_number := table_number();
        l_dep_final      table_number := table_number();
    BEGIN
    
        FOR l_index_n IN i_dep_new.first .. i_dep_new.last
        LOOP
        
            g_error := 'CONVERT TO TIMESTAMP';
            pk_alertlog.log_debug(g_error);
            l_dt_begin_new := to_date(i_dt_begin_new(l_index_n), pk_alert_constant.g_dt_yyyymmddhh24miss);
            l_dt_end_new   := to_date(i_dt_end_new(l_index_n), pk_alert_constant.g_dt_yyyymmddhh24miss);
        
            l_dep_new := i_dep_new(l_index_n);
        
            g_error := 'GET CONFLICTS';
            pk_alertlog.log_debug(g_error);
        
            FOR l_index IN i_dt_begin.first .. i_dt_begin.last
            LOOP
            
                IF l_dep_new = i_dep(l_index)
                THEN
                
                    g_error := 'GET DATES FOR ' || l_index;
                    pk_alertlog.log_debug(g_error);
                
                    l_dt_begin := to_date(i_dt_begin(l_index));
                
                    IF i_dt_end(l_index) IS NULL
                    THEN
                        l_dt_end := NULL;
                    ELSE
                        l_dt_end := to_date(i_dt_end(l_index));
                    END IF;
                    l_nch := i_nch(l_index);
                    l_dep := i_dep(l_index);
                    l_ba  := i_bed_action(l_index);
                
                    l_dt_begin_final.extend;
                    l_dt_end_final.extend;
                    l_nch_final.extend;
                    l_dep_final.extend;
                    l_ba_final.extend;
                
                    IF l_dt_begin_new <= l_dt_begin
                       AND (l_dt_end_new IS NULL OR l_dt_end_new >= nvl(l_dt_end, l_dt_end_new))
                    THEN
                        g_error := 'OLD TIME FRAME OVERLAPED BY NEW ONE';
                        IF (l_dt_end_new IS NOT NULL AND l_dt_end IS NULL)
                        THEN
                            l_dt_begin := l_dt_end_new + 1;
                        ELSE
                            l_dt_begin := NULL;
                        END IF;
                    
                        l_dt_end := NULL;
                    
                    ELSIF l_dt_begin <= l_dt_begin_new
                          AND (l_dt_end IS NULL OR l_dt_end > nvl(l_dt_end_new, l_dt_end))
                    THEN
                        g_error := 'NEW TIME FRAME OVERLAPED BY OLD ONE';
                        g_error := 'OLD TIME FRAME DIVIDED IN TWO';
                    
                        --um intervalo (anterior ao novo) excepcionalmente criado agora. 
                        IF (l_dt_begin_new - 1) >= l_dt_begin
                        THEN
                            l_nch_final(l_nch_final.last) := l_nch;
                            l_dep_final(l_dep_final.last) := l_dep;
                            l_ba_final(l_ba_final.last) := l_ba;
                        
                            l_dt_begin_final(l_dt_begin_final.last) := pk_date_utils.to_char_timezone(i_lang,
                                                                                                      l_dt_begin,
                                                                                                      pk_alert_constant.g_dt_yyyymmddhh24miss);
                        
                            l_dt_end_final(l_dt_end_final.last) := pk_date_utils.to_char_timezone(i_lang,
                                                                                                  (l_dt_begin_new - 1),
                                                                                                  pk_alert_constant.g_dt_yyyymmddhh24miss);
                        
                        END IF;
                        --O restante vai no final do loop, sendo necessário apenas  preparar as vari?veis
                        IF l_dt_end_new IS NOT NULL
                        THEN
                            l_dt_begin := l_dt_end_new + 1;
                        ELSE
                            NULL;
                        END IF;
                    
                        l_dt_begin_final.extend;
                        l_dt_end_final.extend;
                        l_nch_final.extend;
                        l_dep_final.extend;
                        l_ba_final.extend;
                    
                    ELSIF l_dt_begin > l_dt_begin_new
                          AND l_dt_begin <= nvl(l_dt_end_new, l_dt_end)
                    THEN
                        g_error    := 'NEW TIME FRAME BEFORE OLD TIME FRAME';
                        l_dt_begin := l_dt_end_new + 1;
                    
                    ELSIF l_dt_begin <= l_dt_begin_new
                          AND nvl(l_dt_end, l_dt_begin_new) >= l_dt_begin_new
                    THEN
                        g_error  := 'OLD TIME FRAME BEFORE NEW TIME FRAME';
                        l_dt_end := l_dt_begin_new - 1;
                    
                    ELSE
                        g_error := 'IRRELEVANT';
                    END IF;
                
                    pk_alertlog.log_debug(g_error);
                
                    l_dep_final(l_dep_final.last) := l_dep;
                    l_dt_begin_final(l_dt_begin_final.last) := pk_date_utils.to_char_timezone(i_lang,
                                                                                              l_dt_begin,
                                                                                              pk_alert_constant.g_dt_yyyymmddhh24miss);
                    l_dt_end_final(l_dt_end_final.last) := pk_date_utils.to_char_timezone(i_lang,
                                                                                          l_dt_end,
                                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss);
                    l_ba_final(l_ba_final.last) := l_ba;
                    l_nch_final(l_nch_final.last) := l_nch;
                END IF;
            END LOOP;
        
            l_dt_begin_final.extend;
            l_dt_end_final.extend;
            l_nch_final.extend;
            l_dep_final.extend;
            l_ba_final.extend;
        
            l_dep_final(l_dep_final.last) := i_dep_new(l_index_n);
            l_dt_begin_final(l_dt_begin_final.last) := i_dt_begin_new(l_index_n);
            l_dt_end_final(l_dt_end_final.last) := i_dt_end_new(l_index_n);
            l_nch_final(l_nch_final.last) := i_nch_new(l_index_n);
            l_ba_final(l_ba_final.last) := NULL;
        
        END LOOP;
    
        g_error := 'GET O_GRID';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT d.id_department,
                   decode(at.id_admission_type,
                          NULL,
                          pk_translation.get_translation(i_lang, d.code_department),
                          pk_translation.get_translation(i_lang, d.code_department) || ' (' ||
                          nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_service,
                   pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specialties,
                   pk_inp_util.get_time_frame_desc(i_lang, i_prof, ba.dt_begin_action) crr_time_frame,
                   pk_inp_util.get_time_frame_rank(i_lang, i_prof, ba.dt_begin_action) crr_time_frame_rank,
                   pk_date_utils.to_char_timezone(i_lang, ba.dt_begin_action, pk_alert_constant.g_dt_yyyymmddhh24miss) crr_time_frame_start,
                   
                   pk_date_utils.to_char_timezone(i_lang, ba.dt_end_action, pk_alert_constant.g_dt_yyyymmddhh24miss) crr_time_frame_end,
                   
                   decode(ba.dt_begin_action,
                          NULL,
                          l_null,
                          pk_date_utils.to_char_timezone(i_lang, ba.dt_begin_action, l_mask)) desc_crr_time_frame_start,
                   decode(ba.dt_end_action,
                          NULL,
                          l_null,
                          pk_date_utils.to_char_timezone(i_lang, ba.dt_end_action, l_mask)) desc_crr_time_frame_end,
                   
                   pk_inp_util.get_time_frame_desc(i_lang,
                                                   i_prof,
                                                   to_timestamp(data.dt_begin, pk_alert_constant.g_dt_yyyymmddhh24miss)) prop_time_frame,
                   pk_inp_util.get_time_frame_rank(i_lang,
                                                   i_prof,
                                                   to_timestamp(data.dt_begin, pk_alert_constant.g_dt_yyyymmddhh24miss)) prop_time_frame_rank,
                   
                   data.dt_begin prop_time_frame_start,
                   data.dt_end   prop_time_frame_end,
                   
                   decode(data.dt_begin,
                          NULL,
                          l_null,
                          pk_date_utils.to_char_timezone(i_lang,
                                                         to_timestamp(data.dt_begin,
                                                                      pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                         l_mask)) desc_prop_time_frame_start,
                   decode(data.dt_end,
                          NULL,
                          l_null,
                          pk_date_utils.to_char_timezone(i_lang,
                                                         to_timestamp(data.dt_end,
                                                                      pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                         l_mask)) desc_prop_time_frame_end,
                   
                   pk_bmng_core.get_nch_day_int(i_lang, i_prof, data.nch) nch_day,
                   data.nch nch_capacity,
                   decode(data.nch, NULL, l_null, pk_nch_pbl.get_format_nch_info(i_lang, data.nch)) desc_nch_capacity,
                   decode(data.id_bmng_action, NULL, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_status,
                   data.id_bmng_action id_bmng_action
              FROM (SELECT DISTINCT t_dep.value   id_department,
                                    t_nch.value   nch,
                                    t_start.value dt_begin,
                                    t_end.value   dt_end,
                                    t_ba.value    id_bmng_action
                      FROM (SELECT /*+ opt_estimate (table t rows=1)*/
                             rownum rnum, t.column_value VALUE
                              FROM TABLE(l_nch_final) t) t_nch
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dt_end_final) t) t_end
                        ON t_nch.rnum = t_end.rnum
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dt_begin_final) t) t_start
                        ON t_start.rnum = t_end.rnum
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_dep_final) t) t_dep
                        ON t_start.rnum = t_dep.rnum
                     INNER JOIN (SELECT /*+ opt_estimate (table t rows=1)*/
                                 rownum rnum, t.column_value VALUE
                                  FROM TABLE(l_ba_final) t) t_ba
                        ON t_ba.rnum = t_end.rnum) data
             INNER JOIN department d
                ON (d.id_department = data.id_department AND d.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              LEFT JOIN bmng_action ba
                ON ba.id_bmng_action = data.id_bmng_action
               AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_s
               AND ba.flg_status IN (pk_bmng_constant.g_bmng_act_flg_status_a);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONFLICTS_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_conflicts_grid;

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
        o_grid           OUT pk_types.cursor_type,
        o_conflict_found OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_new_department table_number := table_number();
        i_new_begin_date table_varchar := table_varchar();
    
        l_index   PLS_INTEGER;
        l_index_2 PLS_INTEGER;
        l_num_reg PLS_INTEGER := 0;
    
        l_dummy_1 table_varchar := table_varchar();
        l_dummy_2 table_varchar := table_varchar();
        l_dummy_3 table_varchar := table_varchar();
        l_dummy_4 table_varchar := table_varchar();
    
        l_begin_date_str VARCHAR(200) := NULL;
        l_begin_date     bmng_action.dt_begin_action%TYPE;
        l_end_date       bmng_action.dt_end_action%TYPE;
    
        l_begin_str VARCHAR2(40);
        l_end_str   VARCHAR2(40);
    
        l_aux1 VARCHAR2(100);
        l_aux2 VARCHAR2(100);
        l_aux3 VARCHAR2(100);
        l_aux4 VARCHAR2(100);
    
        l_arr_dep    table_number := table_number();
        l_arr_act    table_number := table_number();
        l_arr_nch    table_number := table_number();
        l_arr_dt_beg table_varchar := table_varchar();
        l_arr_dt_end table_varchar := table_varchar();
    
        l_new_dep    table_number := table_number();
        l_new_nch    table_number := table_number();
        l_new_dt_beg table_varchar := table_varchar();
        l_new_dt_end table_varchar := table_varchar();
    
        l_grid  pk_types.cursor_type;
        g_found BOOLEAN;
    
    BEGIN
    
        o_conflict_found := pk_alert_constant.g_no; --FALSE;
    
        g_error := 'LOOP DEPARTMENTS LIST';
        pk_alertlog.log_debug(g_error);
        FOR l_index IN i_department.first .. i_department.last
        LOOP
            g_error := 'PROCESSING BEGIN DATE';
            pk_alertlog.log_debug(g_error);
            IF i_begin_date.exists(l_index)
            THEN
                IF i_begin_date(l_index) IS NOT NULL
                THEN
                    l_begin_date     := to_date(substr(i_begin_date(l_index), 1, 8), 'YYYYMMDD');
                    l_begin_date_str := to_char(l_begin_date);
                END IF;
            ELSE
                l_begin_date := NULL;
            END IF;
        
            g_error := 'PROCESSING END DATE';
            pk_alertlog.log_debug(g_error);
        
            IF i_end_date.exists(l_index)
            THEN
                IF i_end_date(l_index) IS NOT NULL
                THEN
                    l_end_date := to_date(substr(i_end_date(l_index), 1, 8), 'YYYYMMDD');
                END IF;
            ELSE
                l_end_date := NULL;
            END IF;
        
            g_error := 'CALL TO GET_BMNG_INTERVALS i_begin_date=' || l_begin_date;
            pk_alertlog.log_debug(g_error);
        
            pk_types.open_cursor_if_closed(l_grid);
            IF NOT pk_bmng_core.get_bmng_intervals(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_flg_target_action => pk_bmng_constant.g_bmng_act_flg_target_s,
                                                   i_department        => i_department(l_index),
                                                   i_request_type      => pk_bmng_constant.g_bmng_intervals_req_type_d,
                                                   i_begin_date        => l_begin_date,
                                                   i_end_date          => l_end_date,
                                                   i_origin_action     => pk_bmng_constant.g_bmng_intervals_orig_act_n,
                                                   o_intervals         => l_grid,
                                                   o_error             => o_error)
            THEN
            
                pk_types.open_my_cursor(l_grid);
            
                RETURN FALSE;
            END IF;
        
            g_error := 'FETCH O_GRID';
            FETCH l_grid BULK COLLECT
                INTO l_dummy_1, l_dummy_2, l_dummy_3, l_dummy_4;
            g_found := l_grid%FOUND;
            CLOSE l_grid;
        
            IF l_dummy_1.count != 0
            THEN
                FOR l_index_2 IN l_dummy_1.first .. l_dummy_1.last
                LOOP
                
                    g_error := 'VERIFY CONFLICTS: ' || l_dummy_3(l_index_2) || '-' || l_dummy_4(l_index_2);
                    pk_alertlog.log_debug(g_error);
                    l_aux1 := to_date(i_begin_date(l_index), pk_alert_constant.g_dt_yyyymmddhh24miss);
                    l_aux2 := to_date(l_dummy_3(l_index_2));
                    IF i_end_date(l_index) IS NULL
                    THEN
                        l_aux3 := '0';
                    ELSE
                        l_aux3 := to_date(i_end_date(l_index), pk_alert_constant.g_dt_yyyymmddhh24miss);
                    END IF;
                
                    IF l_dummy_4(l_index_2) IS NULL
                    THEN
                        l_aux4 := '0';
                    ELSE
                        l_aux4 := to_date(l_dummy_4(l_index_2));
                    END IF;
                
                    IF (l_dummy_1(l_index_2) IS NOT NULL)
                       AND NOT (
                        
                         l_aux1 = l_aux2 AND l_aux3 = l_aux4
                        
                        )
                    
                    THEN
                    
                        i_new_department.extend;
                        i_new_begin_date.extend;
                        l_new_nch.extend;
                        l_new_dep.extend;
                        l_new_dt_beg.extend;
                        l_new_dt_end.extend;
                    
                        l_num_reg := l_num_reg + 1;
                        i_new_department(l_num_reg) := i_department(l_index);
                        i_new_begin_date(l_num_reg) := l_begin_date_str;
                    
                        o_conflict_found := pk_alert_constant.g_yes; --TRUE;
                    
                        l_begin_str := i_begin_date(l_index);
                        l_end_str   := i_end_date(l_index);
                    
                        --duplicate records                   
                        l_arr_dep.extend;
                        l_arr_act.extend;
                        l_arr_nch.extend;
                        l_arr_dt_beg.extend;
                        l_arr_dt_end.extend;
                    
                        l_arr_dep(l_arr_dep.last) := i_department(l_index);
                        l_arr_act(l_arr_act.last) := l_dummy_1(l_index_2);
                        l_arr_nch(l_arr_nch.last) := l_dummy_2(l_index_2);
                        l_arr_dt_beg(l_arr_dt_beg.last) := l_dummy_3(l_index_2);
                        l_arr_dt_end(l_arr_dt_end.last) := l_dummy_4(l_index_2);
                    
                        l_new_dep(l_new_dep.last) := i_department(l_index);
                        l_new_nch(l_new_nch.last) := i_nch(l_index);
                        l_new_dt_beg(l_new_dt_beg.last) := l_begin_str;
                        l_new_dt_end(l_new_dt_end.last) := l_end_str;
                    
                        -- EXIT;
                    END IF;
                END LOOP;
            
            END IF;
        END LOOP;
    
        IF o_conflict_found = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL GET_CONFLICTS_GRID';
            pk_alertlog.log_debug(g_error);
        
            IF NOT pk_bmng.get_conflicts_grid(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dep          => l_arr_dep,
                                              i_bed_action   => l_arr_act,
                                              i_nch          => l_arr_nch,
                                              i_dt_begin     => l_arr_dt_beg,
                                              i_dt_end       => l_arr_dt_end,
                                              i_dt_begin_new => l_new_dt_beg,
                                              i_dt_end_new   => l_new_dt_end,
                                              i_nch_new      => l_new_nch,
                                              i_dep_new      => l_new_dep,
                                              o_grid         => o_grid,
                                              o_error        => o_error)
            THEN
                pk_types.open_my_cursor(o_grid);
                RETURN FALSE;
            END IF;
        
        ELSE
            pk_types.open_my_cursor(o_grid);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state();
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
    END check_bmng_interval_conflict;

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
        l_bmng_act            table_number;
        l_bmng_deps           table_number;
        l_bmng_beds           table_number;
        l_bmng_rooms          table_number;
        l_bmng_patient        table_number;
        l_bmng_allocation_bed table_number;
        --
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        l_bed_allocation         VARCHAR2(1);
        l_exception_info         sys_message.desc_message%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL set_bmng_discharge. i_episode: ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT set_bmng_discharge(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_epis             => i_epis,
                                  i_id_cancel_reason => NULL,
                                  i_transaction_id   => l_transaction_id,
                                  o_error            => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
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
                                              'SET_BMNG_DISCHARGE',
                                              o_error);
        
            RETURN FALSE;
    END set_bmng_discharge;

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
    *
    * @changed by               Sofia Mendes (inclusion of the cancel_reason)
    * @version                  2.6.1
    * @since                    18-Apr-2011
    ********************************************************************************************/
    FUNCTION set_bmng_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_id_cancel_reason IN bmng_action.id_cancel_reason%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bmng_act            table_number;
        l_bmng_deps           table_number;
        l_bmng_beds           table_number;
        l_bmng_rooms          table_number;
        l_bmng_patient        table_number;
        l_bmng_allocation_bed table_number;
        --
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        l_bed_allocation         VARCHAR2(1);
        l_exception_info         sys_message.desc_message%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'GET BMNG_ACTIONS';
        SELECT ba.id_bmng_action, ba.id_department, bab.id_room, bab.id_bed, bab.id_patient, bab.id_bmng_allocation_bed
          BULK COLLECT
          INTO l_bmng_act, l_bmng_deps, l_bmng_rooms, l_bmng_beds, l_bmng_patient, l_bmng_allocation_bed
          FROM bmng_action ba
         INNER JOIN bmng_allocation_bed bab
            ON bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
         WHERE bab.id_episode = i_epis
           AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
           AND bab.flg_outdated = pk_alert_constant.g_no;
    
        IF l_bmng_act.count = 0
        THEN
            RETURN TRUE;
        END IF;
    
        FOR i IN l_bmng_act.first .. l_bmng_act.last
        LOOP
            g_error := 'CALL SET_BED_MANAGEMENT';
            IF NOT pk_bmng_core.set_bed_management(i_lang                   => i_lang,
                                                   i_prof                   => i_prof,
                                                   i_id_bmng_action         => l_bmng_act(i),
                                                   i_id_department          => l_bmng_deps(i),
                                                   i_id_room                => l_bmng_rooms(i),
                                                   i_id_bed                 => l_bmng_beds(i),
                                                   i_id_bmng_reason         => i_id_cancel_reason,
                                                   i_id_bmng_allocation_bed => l_bmng_allocation_bed(i),
                                                   i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                                   i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a, -- TODO LMAIA: check
                                                   i_nch_capacity           => NULL,
                                                   i_action_notes           => NULL,
                                                   i_dt_begin_action        => current_timestamp,
                                                   i_dt_end_action          => NULL,
                                                   i_id_episode             => i_epis,
                                                   i_id_patient             => l_bmng_patient(i),
                                                   i_nch_hours              => NULL,
                                                   i_flg_allocation_nch     => NULL,
                                                   i_desc_bed               => NULL,
                                                   i_id_bed_type            => NULL,
                                                   i_dt_discharge_schedule  => NULL,
                                                   i_id_bed_dep_clin_serv   => NULL,
                                                   i_flg_origin_action_ux   => pk_bmng_constant.g_bmng_flg_origin_ux_v,
                                                   i_reason_notes           => NULL,
                                                   i_transaction_id         => l_transaction_id,
                                                   i_allocation_commit      => pk_alert_constant.g_yes,
                                                   o_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                   o_id_bed                 => l_id_bed,
                                                   o_bed_allocation         => l_bed_allocation,
                                                   o_exception_info         => l_exception_info,
                                                   o_error                  => o_error)
            THEN
                IF l_bed_allocation = pk_alert_constant.g_no
                THEN
                    NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
                ELSE
                    RETURN FALSE;
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
    
        g_error := 'CALL PK_BMNG_CORE.SET_MATCH_BMNG';
        IF NOT pk_bmng_core.set_match_bmng(i_lang           => i_lang,
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

    /********************************************************************************************
    * SET_BMNG_ALLOCATION             For a provided episode updates the allocation bed.
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_epis              ALERT ID of the episode to check
    * @param IN   i_id_bed            Bed identifier
    * @param IN   i_flg_type          Bed type ('P'-permanent; 'T'-temporary)
    * @param IN   i_desc_bed          Description associated with this bed
    * @param IN   i_transaction_id    remote transaction identifier
    * @param IN   i_allocation_commit Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param in   i_dt_disch_sched    Espected date for current episode discharge
    * @param in   i_dt_creation       Creation date
    * @param OUT  O_BED_ALLOCATION    Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param OUT  O_EXCEPTION_INFO    Error message to be displayed to the user. 
    *
    * @param OUT  o_error             
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Sofia Mendes
    * @version                  2.5.0.7
    * @since                    02/10/2009
    ********************************************************************************************/
    FUNCTION set_bmng_allocation
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_epis                         IN episode.id_episode%TYPE,
        i_id_bed                       IN bed.id_bed%TYPE,
        i_id_room                      IN room.id_room%TYPE,
        i_flg_type                     IN bed.flg_type%TYPE,
        i_desc_bed                     IN bed.desc_bed%TYPE,
        i_transaction_id               IN VARCHAR2,
        i_allocation_commit            IN VARCHAR2,
        i_dt_disch_sched               IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_creation                  IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_bed_allocation               OUT VARCHAR2,
        o_exception_info               OUT sys_message.desc_message%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_room                room.id_room%TYPE;
        l_id_department          department.id_department%TYPE;
        l_id_patient             patient.id_patient%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        l_bmng_ea_nch            bmng_bed_ea.flg_allocation_nch%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        g_error := 'GET BED INFO WITH ID_BED = ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        IF (i_id_bed IS NOT NULL)
        THEN
            SELECT r.id_room, r.id_department
              INTO l_id_room, l_id_department
              FROM bed b
              JOIN room r
                ON b.id_room = r.id_room
             WHERE b.id_bed = i_id_bed;
        ELSE
            SELECT r.id_room, r.id_department
              INTO l_id_room, l_id_department
              FROM room r
             WHERE r.id_room = i_id_room;
        END IF;
    
        g_error := 'GET PATIENT INFO WITH ID_EPISODE = ' || i_epis;
        pk_alertlog.log_debug(g_error);
    
        SELECT epi.id_patient, decode(nl.id_nch_level, NULL, NULL, pk_bmng_constant.g_bmng_bed_ea_flg_nch_u)
          INTO l_id_patient, l_bmng_ea_nch
          FROM episode epi
          LEFT JOIN adm_request ar
            ON ar.id_dest_episode = epi.id_episode
          LEFT JOIN adm_indication ai
            ON ai.id_adm_indication = ar.id_adm_indication
          LEFT JOIN nch_level nl
            ON nl.id_previous = ai.id_nch_level
         WHERE epi.id_episode = i_epis;
    
        g_error := 'CALL SET_BED_MANAGEMENT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng_core.set_bed_management(i_lang                         => i_lang,
                                          i_prof                         => i_prof,
                                          i_id_bmng_action               => NULL, --NULL inserts a new entry and outdates the existing ones
                                          i_id_department                => l_id_department,
                                          i_id_room                      => l_id_room,
                                          i_id_bed                       => i_id_bed,
                                          i_id_bmng_reason               => NULL,
                                          i_id_bmng_allocation_bed       => NULL,
                                          i_flg_target_action            => pk_bmng_constant.g_bmng_act_flg_target_b,
                                          i_flg_status                   => pk_bmng_constant.g_bmng_act_flg_status_a,
                                          i_nch_capacity                 => NULL,
                                          i_action_notes                 => NULL,
                                          i_dt_begin_action              => current_timestamp,
                                          i_dt_end_action                => NULL,
                                          i_id_episode                   => i_epis,
                                          i_id_patient                   => l_id_patient,
                                          i_nch_hours                    => NULL,
                                          i_flg_allocation_nch           => l_bmng_ea_nch,
                                          i_desc_bed                     => i_desc_bed,
                                          i_id_bed_type                  => NULL,
                                          i_dt_discharge_schedule        => i_dt_disch_sched,
                                          i_id_bed_dep_clin_serv         => NULL,
                                          i_flg_origin_action_ux         => CASE
                                                                                WHEN i_flg_type =
                                                                                     pk_bmng_constant.g_bmng_bed_flg_type_p THEN
                                                                                 pk_bmng_constant.g_bmng_flg_origin_ux_p
                                                                                ELSE
                                                                                 pk_bmng_constant.g_bmng_flg_origin_ux_t
                                                                            END,
                                          i_reason_notes                 => NULL,
                                          i_transaction_id               => l_transaction_id,
                                          i_allocation_commit            => i_allocation_commit,
                                          i_dt_creation                  => i_dt_creation,
                                          i_flg_allow_bed_alloc_inactive => i_flg_allow_bed_alloc_inactive,
                                          o_id_bmng_allocation_bed       => l_id_bmng_allocation_bed,
                                          o_id_bed                       => l_id_bed,
                                          o_bed_allocation               => o_bed_allocation,
                                          o_exception_info               => o_exception_info,
                                          o_error                        => o_error)
        THEN
            IF o_bed_allocation = pk_alert_constant.g_no
            THEN
                NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
            ELSE
                RETURN FALSE;
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
                                              'SET_BMNG_ALLOCATION',
                                              o_error);
        
            RETURN FALSE;
    END set_bmng_allocation;

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
        o_allocations           OUT pk_types.cursor_type,
        o_pat_name              OUT patient.name%TYPE,
        o_nch_hours             OUT VARCHAR2,
        o_nch_hours_num         OUT epis_nch.nch_value%TYPE,
        o_dt_discharge_schedule OUT VARCHAR2,
        o_flg_hour_origin       OUT discharge_schedule.flg_hour_origin%TYPE,
        o_nch_mod_reason        OUT epis_nch.reason_notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'GET_PATIENT_ALLOCATION';
        l_dt_begin       TIMESTAMP WITH LOCAL TIME ZONE;
        l_internal_error EXCEPTION;
        l_id_bmng_action table_number;
        l_notes_label    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M044');
    BEGIN
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
    
        g_error := 'GET ID_BMNG_ACTION FOR EPISODE : ' || i_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT ba.id_bmng_action
              BULK COLLECT
              INTO l_id_bmng_action
              FROM bmng_allocation_bed bab
             INNER JOIN bmng_action ba
                ON bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
             WHERE bab.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_bmng_action := table_number();
        END;
    
        g_error := 'GET PAT ALLOCATIONS';
        OPEN o_allocations FOR
            SELECT /*+ opt_estimate (table bed_status rows=1)*/
             ba.id_bmng_action,
             d.id_department,
             CASE
                  WHEN b.id_bed_type = -1 THEN
                   NULL
                  ELSE
                   b.id_bed_type
              END id_bed_type,
             decode(nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)),
                    NULL,
                    pk_translation.get_translation(i_lang, d.code_department),
                    pk_translation.get_translation(i_lang, d.code_department) || ' (' ||
                    nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
             pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specs,
             b.id_room,
             nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc_name,
             nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc_type,
             b.id_bed,
             nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_desc_name,
             CASE
                  WHEN bt.id_bed_type = -1 THEN
                   NULL
                  ELSE
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type))
              END bed_desc_type,
             --pk_translation.get_translation(i_lang, cs.code_clinical_service) bed_desc_spec,
             get_bed_dep_clin_serv(i_lang, i_prof, b.id_bed) bed_desc_spec,
             ba.id_bmng_allocation_bed id_bmng_allocation_bed,
             pk_date_utils.date_char_tsz(i_lang, bab.dt_creation, i_prof.institution, i_prof.software) dt_allocated_at,
             pk_prof_utils.get_name_signature(i_lang, i_prof, bab.id_prof_creation) allocated_by,
             bed_status.icon_bed_status,
             bed_status.desc_bed_status,
             bed_status.availability,
             bed_status.flg_conflict,
             bed_status.icon_bed_cleaning_status,
             bed_status.desc_cleaning_status,
             bed_status.flg_bed_sts_toflash,
             decode(bed_status.flg_bed_clean_sts_toflash,
                    pk_bmng_constant.g_bmng_act_flg_cleani_n,
                    NULL,
                    bed_status.flg_bed_clean_sts_toflash) flg_bed_clean_sts_toflash,
             b.flg_type,
             decode(ba.flg_status,
                    pk_bmng_constant.g_bmng_act_flg_status_o,
                    pk_alert_constant.g_outdated,
                    pk_alert_constant.g_active) flg_reg_status,
             pk_date_utils.date_send_tsz(i_lang,
                                         pk_bmng_core.get_next_schedule_date(i_lang,
                                                                             i_prof,
                                                                             ba.id_bed,
                                                                             current_timestamp),
                                         i_prof) dt_next_schedule,
             pk_nch_pbl.get_nch_total(i_lang, i_prof, i_episode, l_dt_begin) nch_hours_num,
             --
             ba.flg_bed_status,
             pk_bmng_core.get_count_bed_status(i_lang,
                                               i_prof,
                                               bab.id_episode,
                                               pk_bmng_constant.g_bmng_act_flg_bed_sta_r) count_reservations,
             pk_bmng_core.get_count_bed_status(i_lang,
                                               i_prof,
                                               bab.id_episode,
                                               pk_bmng_constant.g_bmng_act_flg_bed_sta_n) count_ocupation,
             l_notes_label || ' ' || ba.action_notes action_notes
              FROM bmng_allocation_bed bab
             INNER JOIN bmng_action ba
                ON bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
              JOIN bed b
                ON b.id_bed = ba.id_bed
              LEFT JOIN bed_type bt
                ON bt.id_bed_type = b.id_bed_type
              JOIN room r
                ON r.id_room = b.id_room
              JOIN department d
                ON d.id_department = r.id_department
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              LEFT JOIN room_type rt
                ON rt.id_room_type = r.id_room_type
              JOIN TABLE(pk_bmng_core.tf_get_all_bed_status(i_lang, i_prof, NULL, l_id_bmng_action)) bed_status
                ON bed_status.id_bmng_action = ba.id_bmng_action
             WHERE bab.id_episode = i_episode
             ORDER BY flg_reg_status, ba.flg_bed_status, bab.dt_creation DESC;
    
        BEGIN
            SELECT pk_patient.get_pat_short_name(p.id_patient)
              INTO o_pat_name
              FROM patient p
              JOIN episode e
                ON p.id_patient = e.id_patient
             WHERE e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                o_pat_name := NULL;
        END;
    
        o_nch_hours_num := pk_nch_pbl.get_nch_total(i_lang, i_prof, i_episode, l_dt_begin);
        IF (o_nch_hours_num IS NOT NULL)
        THEN
            o_nch_hours := pk_nch_pbl.get_format_nch_info(i_lang, o_nch_hours_num);
        END IF;
    
        g_error := 'CALL pk_discharge.get_discharge_schedule_date with id_episode=' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_discharge.get_discharge_schedule_date(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_episode      => i_episode,
                                                        o_discharge_date  => o_dt_discharge_schedule,
                                                        o_flg_hour_origin => o_flg_hour_origin,
                                                        o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_nch_pbl.get_nch_reason_notes with id_episode=' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_nch_pbl.get_nch_reason_notes(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               o_reason_notes => o_nch_mod_reason,
                                               o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_date_utils.date_send_tsz';
        pk_alertlog.log_debug(g_error);
        IF o_dt_discharge_schedule IS NULL
        THEN
            BEGIN
                SELECT s.dt_end_tstz
                  INTO o_dt_discharge_schedule
                  FROM schedule s
                 WHERE s.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    o_dt_discharge_schedule := NULL;
            END;
        END IF;
    
        o_dt_discharge_schedule := pk_date_utils.date_send_tsz(i_lang, o_dt_discharge_schedule, i_prof);
    
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
        o_nch_list OUT pk_types.cursor_type,
        o_title    OUT sys_message.desc_message%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_NCH_GRID';
    
        l_request_type VARCHAR2(1);
        l_msg_no_value sys_message.desc_message%TYPE;
        l_date_format  sys_message.desc_message%TYPE;
    
        l_wrong_view_opt EXCEPTION;
        l_code_msg       sys_message.code_message%TYPE;
        l_error_msg      sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_msg_no_value := pk_message.get_message(i_lang, 'BMNG_T090');
        l_date_format  := pk_message.get_message(i_lang, 'DATE_FORMAT_M006');
    
        CASE i_view_opt
            WHEN 'ALL' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T091');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_a;
            WHEN 'CANC' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T092');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_c;
            WHEN 'FUT' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T093');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_f;
            WHEN 'PAST' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T094');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_p;
            WHEN 'CURR' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T095');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_d;
            ELSE
                l_code_msg  := 'BMNG_E001';
                l_error_msg := pk_message.get_message(i_lang, i_prof, i_code_mess => l_code_msg);
                RAISE l_wrong_view_opt;
        END CASE;
    
        g_error := 'GET NCH LIST';
        OPEN o_nch_list FOR
            SELECT DISTINCT d.id_department,
                            nvl(pk_translation.get_translation(i_lang, d.code_department), d.id_department) ||
                            decode(nvl(nvl(at.desc_admission_type,
                                           pk_translation.get_translation(i_lang, at.code_admission_type)),
                                       'N'),
                                   'N',
                                   '',
                                   ' (' || nvl(at.desc_admission_type,
                                               pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_service,
                            pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specialties,
                            pk_inp_util.get_time_frame_desc(i_lang, i_prof, bint.dt_begin) time_frame,
                            pk_inp_util.get_time_frame_rank(i_lang, i_prof, bint.dt_begin) time_frame_rank,
                            pk_date_utils.to_char_timezone(i_lang,
                                                           
                                                           bint.dt_begin,
                                                           pk_alert_constant.g_dt_yyyymmddhh24miss) time_frame_start,
                            pk_date_utils.to_char_timezone(i_lang, bint.dt_end, pk_alert_constant.g_dt_yyyymmddhh24miss) time_frame_end,
                            pk_date_utils.to_char_insttimezone(i_lang, i_prof, bint.dt_begin, l_date_format) scr_time_frame_start,
                            pk_date_utils.to_char_insttimezone(i_lang, i_prof, bint.dt_end, l_date_format) scr_time_frame_end,
                            pk_bmng_core.get_nch_day_int(i_lang, i_prof, bint.nch) nch_day,
                            bint.nch nch_capacity,
                            decode(nvl(bint.nch, -1),
                                   -1,
                                   l_msg_no_value,
                                   pk_nch_pbl.get_format_nch_info(i_lang, bint.nch)) desc_nch_capacity,
                            decode(nvl(bint.nch, -1), -1, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_nch_isnull,
                            ba.flg_status flg_status,
                            ba.action_notes notes_desc,
                            ba.id_bmng_action
              FROM department d
              JOIN institution i
                ON i.id_institution = d.id_institution
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              JOIN dep_clin_serv dcs
                ON (dcs.id_department = d.id_department AND dcs.flg_available = pk_alert_constant.g_yes)
              JOIN TABLE(pk_bmng_core.tf_get_bmng_intervals(i_lang, i_prof, pk_bmng_constant.g_bmng_act_flg_target_s, d.id_department, l_request_type, NULL, pk_bmng_constant.g_bmng_intervals_orig_act_n)) bint
                ON bint.id_department = d.id_department
              LEFT JOIN bmng_action ba
                ON ba.id_bmng_action = bint.id_bmng_action
               AND ba.flg_status != pk_bmng_constant.g_bmng_act_flg_status_o
             WHERE i.id_institution = i_prof.institution
               AND ((i_view_opt = 'CANC' AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_c) OR
                   (i_view_opt != 'CANC'))
               AND instr(d.flg_type, 'I') > 0
               AND d.flg_available = pk_alert_constant.g_yes
             ORDER BY desc_service DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_wrong_view_opt THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_code_msg,
                                              l_error_msg,
                                              '',
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_types.open_my_cursor(o_nch_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
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
        o_dep_info    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dep_array table_number := table_number(); -- this variable is necessary to obtain the list of departments associated to an institution
        l_curr_time TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        l_curr_time := pk_date_utils.trunc_insttimezone(i_prof.institution, i_prof.software, current_timestamp);
    
        --------------------------------------------------------------------------------------------------
        IF i_department.count = 0
           AND i_institution IS NOT NULL -- institution not null then return department array based on the institution
        THEN
            g_error := 'GET PK_BMNG_CORE.GET_INSTITUTION_DEPARTMENTS';
            IF NOT pk_bmng_core.get_institution_departments(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_institution => i_institution,
                                                            o_deps        => l_dep_array,
                                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSIF i_department.count != 0
        THEN
            l_dep_array := i_department;
        END IF;
        --------------------------------------------------------------------------------------------------
        -- at this point this array needs to have values otherwise there's no base for data retrieval
        IF l_dep_array.count = 0
        THEN
            pk_types.open_my_cursor(o_dep_info);
            RETURN FALSE;
        END IF;
        --------------------------------------------------------------------------------------------------
    
        IF i_dt_request IS NULL -- requested date null: uses current information from bmng_department_ea
        THEN
            g_error := 'GET O_DEP_INFO - i_dt_request IS NULL';
            OPEN o_dep_info FOR
                SELECT bde.id_department            id_department,
                       bde.beds_blocked             beds_blocked,
                       bde.total_ocuppied_nch_hours nch_total,
                       bde.total_avail_nch_hours    nch_available
                  FROM bmng_department_ea bde
                 WHERE bde.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_dep_array) t);
        ELSE
            pk_date_utils.set_dst_time_check_off;
            g_error := 'GET O_DEP_INFO';
            OPEN o_dep_info FOR
                SELECT dep_list.column_value id_department,
                       nvl(res.beds_blocked, 0) beds_blocked,
                       pk_bmng_core.get_nch_service_level(i_lang, i_prof, dep_list.column_value) nch_total,
                       ba.nch_capacity nch_available
                  FROM (SELECT /*+ opt_estimate (table t rows=1)*/
                         t.column_value
                          FROM TABLE(l_dep_array) t) dep_list
                  LEFT JOIN (SELECT r.id_department id_department, COUNT(DISTINCT(ba.id_bed)) beds_blocked
                               FROM room r
                              INNER JOIN bmng_action ba
                                 ON (ba.id_department = r.id_department)
                              WHERE ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_b -- 'B' -- BED
                                AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b -- 'B' -- blocked
                                AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a -- 'A' -- ACTIVE
                                AND l_curr_time >= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                    i_prof.software,
                                                                                    ba.dt_begin_action)
                                AND (l_curr_time <= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                     i_prof.software,
                                                                                     ba.dt_end_action) OR
                                    ba.dt_end_action IS NULL)
                                AND r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                         t.column_value
                                                          FROM TABLE(l_dep_array) t)
                              GROUP BY r.id_department) res
                    ON (res.id_department = dep_list.column_value)
                  LEFT JOIN bmng_action ba
                    ON ba.id_department = dep_list.column_value
                   AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                   AND l_curr_time >=
                       pk_date_utils.trunc_insttimezone(i_prof.institution, i_prof.software, ba.dt_begin_action)
                   AND (l_curr_time <=
                       pk_date_utils.trunc_insttimezone(i_prof.institution, i_prof.software, ba.dt_end_action) OR
                       ba.dt_end_action IS NULL)
                   AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_s
                   AND ba.flg_origin_action IN (pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                                pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                                pk_bmng_constant.g_bmng_act_flg_origin_nd);
            pk_date_utils.set_dst_time_check_on;
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
        i_episode       IN table_number, -- either "i_episode" or "i_department" must be filled otherwise function returns FALSE        
        i_department    IN department.id_department%TYPE,
        i_dt_request    IN bmng_action.dt_begin_action%TYPE, -- not allowed nulls
        o_pat_info      OUT pk_types.cursor_type,
        o_def_nch_value OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_array table_number := table_number(); -- this variable is necessary to obtain the list of patients associated to a department
    BEGIN
        --
        o_def_nch_value := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_pat, i_prof);
    
        --------------------------------------------------------------------------------------------------
        -- there's no need to validate "if i_patient.COUNT = 0 AND i_department IS NULL" because
        -- after this "IF" clause it's checked if the patient array has records
        IF i_episode.count = 0
           AND i_department IS NOT NULL -- institution not null then return department array based on the institution
        THEN
            g_error := 'GET L_PAT_ARRAY';
            SELECT bab.id_episode
              BULK COLLECT
              INTO l_epis_array
              FROM department d, room r, bmng_allocation_bed bab
             WHERE d.id_department = i_department
               AND r.id_department = d.id_department
               AND bab.id_room = r.id_room
               AND d.flg_available = pk_alert_constant.g_yes
               AND r.flg_available = pk_alert_constant.g_yes
               AND bab.flg_outdated = pk_alert_constant.g_no;
        ELSIF i_episode.count != 0
        THEN
            l_epis_array := i_episode;
        END IF;
        --------------------------------------------------------------------------------------------------
        -- at this point this array needs to have values otherwise there's no base for data retrieval
        IF l_epis_array.count = 0
        THEN
            pk_types.open_my_cursor(o_pat_info);
            RETURN FALSE;
        END IF;
        --------------------------------------------------------------------------------------------------
    
        g_error := 'GET O_PAT_INFO';
        OPEN o_pat_info FOR
            SELECT bab.id_patient,
                   r.id_department id_department,
                   pk_nch_pbl.get_nch_total_past(i_lang,
                                                 i_prof,
                                                 bab.id_episode,
                                                 bab.id_bmng_allocation_bed,
                                                 i_dt_request) nch_hours_num
              FROM bmng_action ba, bmng_allocation_bed bab, room r
             WHERE ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
               AND ba.id_room = r.id_room
               AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_b -- 'B' -- bed
               AND bab.id_episode IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(l_epis_array) t)
               AND i_dt_request >= ba.dt_begin_action
               AND (i_dt_request <= ba.dt_end_action OR ba.dt_end_action IS NULL);
    
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
        o_alloc_list  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dep_array table_number := table_number(); -- this variable is necessary to obtain the list of departments associated to an institution
    
    BEGIN
    
        --------------------------------------------------------------------------------------------------
        IF i_department.count = 0
           AND i_institution IS NOT NULL -- institution not null then return department array based on the institution
        THEN
            g_error := 'GET PK_BMNG_CORE.GET_INSTITUTION_DEPARTMENTS';
            IF NOT pk_bmng_core.get_institution_departments(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_institution => i_institution,
                                                            o_deps        => l_dep_array,
                                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSIF i_department.count != 0
        THEN
            l_dep_array := i_department;
        END IF;
        --------------------------------------------------------------------------------------------------
        -- at this point this array needs to have values otherwise there's no base for data retrieval
        IF l_dep_array.count = 0
        THEN
            pk_types.open_my_cursor(o_alloc_list);
            RETURN FALSE;
        END IF;
        --------------------------------------------------------------------------------------------------
    
        g_error := 'GET O_ALLOC_LIST';
        OPEN o_alloc_list FOR
            SELECT bab.id_bed, bab.id_patient, en.dt_begin, bbe.dt_discharge_schedule -- en.dt_end
              FROM bmng_bed_ea bbe, bmng_action ba, bmng_allocation_bed bab, bed b, room r, epis_nch en
             WHERE ba.id_room = r.id_room
               AND r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(l_dep_array) t)
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND ba.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o
               AND bbe.id_bmng_action = ba.id_bmng_action
               AND ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
               AND bbe.id_bed = b.id_bed
               AND b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_o
               AND b.flg_available = pk_alert_constant.g_yes
               AND bab.id_epis_nch = en.id_epis_nch
               AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_b
               AND (bbe.dt_discharge_schedule >= i_dt_request OR bbe.dt_discharge_schedule IS NULL OR
                   bbe.dt_discharge_schedule < current_timestamp);
    
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
    * Returns all allocations for a specific department where discharge sched end date is greater
    * than requested date
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
        o_effective_alloc OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dep_array table_number := table_number(); -- this variable is necessary to obtain the list of departments associated to an institution
    BEGIN
    
        --------------------------------------------------------------------------------------------------
        IF i_department.count = 0
           AND i_institution IS NOT NULL -- institution not null then return department array based on the institution
        THEN
            g_error := 'GET PK_BMNG_CORE.GET_INSTITUTION_DEPARTMENTS';
            IF NOT pk_bmng_core.get_institution_departments(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_institution => i_institution,
                                                            o_deps        => l_dep_array,
                                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSIF i_department.count != 0
        THEN
            l_dep_array := i_department;
        END IF;
        --------------------------------------------------------------------------------------------------
        -- at this point this array needs to have values otherwise there's no base for data retrieval
        IF l_dep_array.count = 0
        THEN
            pk_types.open_my_cursor(o_effective_alloc);
            RETURN FALSE;
        END IF;
        --------------------------------------------------------------------------------------------------
    
        -- Reformuled to show all current and past allocations
        g_error := 'GET O_EFFECTIVE_ALLOC';
        OPEN o_effective_alloc FOR
            SELECT bab.id_bed,
                   bab.id_patient,
                   bab.dt_creation,
                   bab.id_bmng_allocation_bed,
                   ds.dt_discharge_schedule,
                   bab.id_episode,
                   ba.flg_bed_status
              FROM bmng_action ba
             INNER JOIN bmng_allocation_bed bab
                ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed)
             INNER JOIN bed b
                ON (b.id_bed = bab.id_bed AND b.flg_available = pk_alert_constant.g_yes)
             INNER JOIN room r
                ON (r.id_room = b.id_room AND r.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN discharge_schedule ds
                ON (ds.id_episode = bab.id_episode)
             WHERE r.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                        t.column_value
                                         FROM TABLE(l_dep_array) t)
               AND ba.flg_bed_status IN ('R', 'N')
               AND ds.flg_status = pk_alert_constant.g_yes
               AND bab.flg_outdated = pk_alert_constant.g_no
               AND ba.flg_status = pk_alert_constant.g_active
               AND ((i_dt_end IS NOT NULL AND
                   (ba.dt_begin_action < i_dt_end AND
                   (ba.dt_end_action > i_dt_begin OR (ds.dt_discharge_schedule > i_dt_begin) OR
                   (ds.dt_discharge_schedule < ba.dt_begin_action))))
                   --
                   OR
                   --
                   (i_dt_end IS NULL AND i_dt_begin >= ba.dt_begin_action AND
                   (i_dt_begin <= ba.dt_end_action OR (i_dt_begin < ds.dt_discharge_schedule) OR
                   (ds.dt_discharge_schedule < ba.dt_begin_action))
                   --
                   )
                   --
                   OR ds.dt_discharge_schedule < current_timestamp);
    
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
    END get_date_allocations;

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
        o_block_list OUT pk_types.cursor_type,
        o_title      OUT sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_BLOCKING_GRID';
        --
        l_request_type VARCHAR2(1);
        l_date_format  sys_message.desc_message%TYPE;
        --
        l_wrong_view_opt EXCEPTION;
        l_code_msg       sys_message.code_message%TYPE;
        l_error_msg      sys_message.desc_message%TYPE;
    BEGIN
        l_date_format := pk_message.get_message(i_lang, 'DATE_FORMAT_M006');
    
        CASE i_view_opt
            WHEN 'ALL' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T117');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_a;
            WHEN 'CANC' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T118');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_c;
            WHEN 'FUT' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T119');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_f;
            WHEN 'PAST' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T120');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_p;
            WHEN 'CURR' THEN
                o_title        := pk_message.get_message(i_lang, 'BMNG_T121');
                l_request_type := pk_bmng_constant.g_bmng_intervals_req_type_d;
            ELSE
                l_code_msg  := 'BMNG_E001';
                l_error_msg := pk_message.get_message(i_lang, i_prof, i_code_mess => l_code_msg);
                RAISE l_wrong_view_opt;
        END CASE;
    
        g_error := 'GET BLOCK LIST';
        OPEN o_block_list FOR
            SELECT DISTINCT d.id_department,
                            nvl(pk_translation.get_translation(i_lang, d.code_department), d.id_department) ||
                            decode(nvl(nvl(at.desc_admission_type,
                                           pk_translation.get_translation(i_lang, at.code_admission_type)),
                                       pk_alert_constant.g_no),
                                   pk_alert_constant.g_no,
                                   '',
                                   ' (' || nvl(at.desc_admission_type,
                                               pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_service,
                            pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specialties,
                            ba.id_room,
                            nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc_name,
                            nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc_type,
                            ba.id_bed,
                            nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_desc_name,
                            nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_desc_type,
                            pk_translation.get_translation(i_lang, cs2.code_clinical_service) bed_desc_spec,
                            bed_status.availability,
                            pk_inp_util.get_time_frame_desc(i_lang, i_prof, bint.dt_begin) time_frame,
                            pk_inp_util.get_time_frame_rank(i_lang, i_prof, bint.dt_begin) time_frame_rank,
                            pk_date_utils.date_send_tsz(i_lang, bint.dt_begin, i_prof) time_frame_start,
                            pk_date_utils.date_send_tsz(i_lang, bint.dt_end, i_prof) time_frame_end,
                            pk_date_utils.to_char_insttimezone(i_lang, i_prof, bint.dt_begin, l_date_format) scr_time_frame_start,
                            pk_date_utils.to_char_insttimezone(i_lang, i_prof, bint.dt_end, l_date_format) scr_time_frame_end,
                            ba.flg_status flg_status,
                            ba.action_notes notes_desc,
                            ba.id_bmng_action
              FROM department d
              JOIN institution i
                ON i.id_institution = d.id_institution
              JOIN dep_clin_serv dcs
                ON (dcs.id_department = d.id_department AND dcs.flg_available = pk_alert_constant.g_yes)
              JOIN TABLE(pk_bmng_core.tf_get_bmng_intervals(i_lang, i_prof, pk_bmng_constant.g_bmng_act_flg_target_s, d.id_department, l_request_type, NULL, pk_bmng_constant.g_bmng_intervals_orig_act_b)) bint
                ON bint.id_department = d.id_department
               AND bint.id_bmng_action IS NOT NULL
              JOIN bmng_action ba
                ON ba.id_bmng_action = bint.id_bmng_action
               AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              JOIN bed b
                ON (b.id_bed = ba.id_bed AND b.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN bed_type bt
                ON bt.id_bed_type = b.id_bed_type
              JOIN room r
                ON (r.id_room = ba.id_room AND r.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN room_type rt
                ON rt.id_room_type = r.id_room_type
              LEFT JOIN bed_dep_clin_serv bdcs
                ON (bdcs.id_bed = b.id_bed AND bdcs.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN dep_clin_serv dcs2
                ON (dcs2.id_dep_clin_serv = bdcs.id_dep_clin_serv AND dcs2.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN clinical_service cs2
                ON (cs2.id_clinical_service = dcs.id_clinical_service AND cs2.flg_available = pk_alert_constant.g_yes)
              JOIN TABLE(pk_bmng_core.tf_get_bed_status(i_lang, i_prof, NULL, table_number(ba.id_bmng_action))) bed_status
                ON bed_status.id_bmng_action = ba.id_bmng_action
             WHERE i.id_institution = i_prof.institution
               AND d.flg_available = pk_alert_constant.g_yes
             ORDER BY time_frame_start DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_wrong_view_opt THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_code_msg,
                                              l_error_msg,
                                              '',
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_types.open_my_cursor(o_block_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
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
        --
        l_id_bed               bed.id_bed%TYPE;
        l_date                 TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_patient           patient.id_patient%TYPE;
        l_id_episode           episode.id_episode%TYPE;
        l_id_room              room.id_room%TYPE;
        l_id_department        department.id_department%TYPE;
        l_bed_flg_type         bed.flg_type%TYPE;
        l_flg_origin_action_ux bmng_action.flg_action%TYPE;
        l_bed_flg_status       bed.flg_status%TYPE;
        l_id_professional      professional.id_professional%TYPE;
        l_id_software          software.id_software%TYPE;
        l_id_institution       institution.id_institution%TYPE;
        l_id_schedule          schedule.id_schedule%TYPE;
        l_bed_allocation       VARCHAR2(1);
        l_exception_info       sys_message.desc_message%TYPE;
        --
        l_lang                   language.id_language%TYPE := 2;
        l_prof                   profissional;
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_prof                PLS_INTEGER;
        --
        l_transaction_id VARCHAR2(4000);
        --
        c_data  pk_types.cursor_type;
        o_error t_error_out;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL,
                                                                           profissional(l_id_professional,
                                                                                        l_id_institution,
                                                                                        l_id_software));
    
        -- GET SCHEDULE BEDS FOR TODAY
        IF NOT pk_schedule_inp.get_next_sch_date(i_lang   => l_lang,
                                                 i_prof   => l_prof,
                                                 i_id_bed => NULL,
                                                 i_date   => NULL, -- NULL means CURRENT HOUR period
                                                 o_data   => c_data,
                                                 o_error  => o_error)
        THEN
        
            RETURN;
        END IF;
    
        -- Transform schedules into allocations
        LOOP
            FETCH c_data
                INTO l_id_bed,
                     l_date,
                     l_id_patient,
                     l_id_episode,
                     l_id_professional,
                     l_id_software,
                     l_id_institution,
                     l_id_schedule;
            EXIT WHEN c_data%NOTFOUND OR c_data%ROWCOUNT = 0;
        
            -- GET PROFESSIONAL ALERT!
            l_id_prof := pk_sysconfig.get_config('ID_PROF_ALERT', profissional(0, l_id_institution, 0));
            l_prof    := profissional(l_id_prof, l_id_institution, l_id_software);
        
            -- CODE for each returned information
            g_error := 'GET BED INFO';
            SELECT r.id_room, r.id_department, b.flg_type, b.flg_status
              INTO l_id_room, l_id_department, l_bed_flg_type, l_bed_flg_status
              FROM bed b
             INNER JOIN room r
                ON (r.id_room = b.id_room)
             WHERE b.id_bed = l_id_bed;
        
            -- There is created an new allocation only if BED is free
            IF l_bed_flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
            THEN
                -- Get bed type information
                IF l_bed_flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
                THEN
                    l_flg_origin_action_ux := pk_bmng_constant.g_bmng_bed_flg_type_p;
                ELSE
                    l_flg_origin_action_ux := pk_bmng_constant.g_bmng_bed_flg_type_t;
                END IF;
            
                g_error := 'CALL PK_BMNG_CORE.SET_BED_MANAGEMENT';
                IF NOT pk_bmng_core.set_bed_management(i_lang                   => l_lang,
                                                       i_prof                   => l_prof,
                                                       i_id_bmng_action         => NULL,
                                                       i_id_department          => l_id_department,
                                                       i_id_room                => l_id_room,
                                                       i_id_bed                 => l_id_bed,
                                                       i_id_bmng_reason         => NULL,
                                                       i_id_bmng_allocation_bed => NULL,
                                                       i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                                       i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                                       i_nch_capacity           => NULL,
                                                       i_action_notes           => NULL,
                                                       i_dt_begin_action        => current_timestamp,
                                                       i_dt_end_action          => NULL,
                                                       i_id_episode             => l_id_episode,
                                                       i_id_patient             => l_id_patient,
                                                       i_nch_hours              => NULL,
                                                       i_flg_allocation_nch     => NULL,
                                                       i_desc_bed               => NULL,
                                                       i_id_bed_type            => NULL,
                                                       i_dt_discharge_schedule  => NULL,
                                                       i_id_bed_dep_clin_serv   => NULL,
                                                       i_flg_origin_action_ux   => l_flg_origin_action_ux,
                                                       i_reason_notes           => NULL,
                                                       i_transaction_id         => l_transaction_id,
                                                       i_allocation_commit      => pk_alert_constant.g_yes,
                                                       o_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                       o_id_bed                 => l_id_bed,
                                                       o_bed_allocation         => l_bed_allocation,
                                                       o_exception_info         => l_exception_info,
                                                       o_error                  => o_error)
                THEN
                    IF l_bed_allocation = pk_alert_constant.g_no
                    THEN
                        NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
                    ELSE
                        RETURN;
                    END IF;
                END IF;
            
                IF l_bed_allocation = pk_alert_constant.g_yes
                THEN
                    g_error := 'CALL PK_SCHEDULE_INP.INS_SCH_ALLOCATION';
                    IF NOT pk_schedule_inp.ins_sch_allocation(i_lang                   => l_lang,
                                                              i_prof                   => l_prof,
                                                              i_id_schedule            => l_id_schedule,
                                                              i_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                              o_error                  => o_error)
                    THEN
                        RETURN;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, l_prof);
    
    END allocate_schedule_beds;

    /********************************************************************************************************************************************
    * Verify if a bed is occupied within the given period
    *
    * @param i_lang       language id
    * @param i_id_bed     bed id
    * @param i_dt_begin   start date
    * @param i_dt_end     end date
    * @param o_occupied   Y = available  N = not available
    * @param o_error      Error message if something goes wrong
    *
    * @author  Sofia Mendes
    * @date     28-08-2009
    * @version  2.5.0.5    
    *******************************************************************************************************************************************/
    FUNCTION is_bed_occupied
    (
        i_lang     IN language.id_language%TYPE,
        i_id_bed   IN bed.id_bed%TYPE,
        i_dt_begin IN schedule.dt_begin_tstz%TYPE,
        i_dt_end   IN schedule.dt_end_tstz%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'IS_BED_OCCUPIED';
    BEGIN
        g_error := 'IS BED OCCUPIED';
        SELECT pk_alert_constant.g_no
          INTO o_avail
          FROM bmng_bed_ea bbea
         WHERE bbea.id_bed = i_id_bed
           AND bbea.flg_bed_ocupacity_status = 'O'
           AND (bbea.dt_begin < i_dt_end OR i_dt_end IS NULL)
           AND (i_dt_begin IS NULL OR bbea.dt_end > i_dt_begin OR
               (bbea.dt_end IS NULL AND bbea.dt_discharge_schedule > i_dt_begin) OR
               (bbea.dt_end IS NULL AND bbea.dt_discharge_schedule < bbea.dt_begin))
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_avail := pk_alert_constant.g_yes;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END is_bed_occupied;

    /********************************************************************************************************************************************
    * Verify if a bed is occupied within the given period
    *
    * @param i_lang       language id
    * @param i_id_bed     bed id
    * @param i_dt_begin   start date
    * @param i_dt_end     end date
    * @param o_occupied   Y = available  N = not available
    * @param o_error      Error message if something goes wrong
    *
    * @author  Sofia Mendes
    * @date     28-08-2009
    * @version  2.5.0.5    
    *******************************************************************************************************************************************/
    FUNCTION is_bed_available
    (
        i_lang   IN language.id_language%TYPE,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(32) := 'is_bed_available';
        l_avail          VARCHAR2(1 CHAR);
        l_internal_error EXCEPTION;
        l_error          t_error_out;
    BEGIN
        IF NOT is_bed_occupied(i_lang     => i_lang,
                               i_id_bed   => i_id_bed,
                               i_dt_begin => NULL,
                               i_dt_end   => NULL,
                               o_avail    => l_avail,
                               o_error    => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN l_avail;
    EXCEPTION
        WHEN l_internal_error THEN
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END is_bed_available;

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
        o_beds          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET O_BEDS';
        OPEN o_beds FOR
            SELECT b.id_bed, bbea.dt_begin, bbea.dt_end, ba.dt_begin_action, ba.dt_end_action, ba.flg_action
              FROM bmng_bed_ea bbea
              JOIN bed b
                ON (b.id_bed = bbea.id_bed AND b.flg_available = pk_alert_constant.g_yes)
              JOIN room r
                ON (b.id_room = r.id_room AND r.flg_available = pk_alert_constant.g_yes)
              JOIN bmng_action ba
                ON ba.id_bed = bbea.id_bed
               AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b
               AND ba.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b
             WHERE bbea.flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_b
               AND bbea.flg_bed_type = pk_bmng_constant.g_bmng_bed_ea_flg_type_p
               AND r.id_department = i_id_department
               AND ((ba.dt_begin_action < i_end_date AND ba.dt_end_action > i_start_date) OR
                   (ba.dt_end_action <= current_timestamp AND
                   i_start_date >= pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)));
    
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
        l_num NUMBER;
    BEGIN
    
        g_error := 'OPEN CURSOR';
    
        SELECT COUNT(1)
          INTO l_num
          FROM bmng_allocation_bed bab
         WHERE bab.id_episode = i_episode
           AND bab.flg_outdated = pk_alert_constant.g_no;
        IF l_num = 0
        THEN
            o_result := pk_alert_constant.g_no;
        ELSE
            o_result := pk_alert_constant.g_yes;
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
    
        g_error := 'OPEN CURSOR';
        OPEN o_result FOR
            SELECT d.id_department id_service,
                   pk_translation.get_translation(i_lang, d.code_department) desc_service,
                   r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   b.id_bed,
                   decode(b.flg_type,
                          pk_bmng_constant.g_bmng_bed_flg_type_p,
                          nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)),
                          b.desc_bed) desc_bed,
                   b.flg_type,
                   icons.flg_bed_clean_sts_toflash flg_bed_cleaning_status,
                   b.id_bed_type
              FROM bmng_action ba
             INNER JOIN bed b
                ON b.id_bed = ba.id_bed
               AND b.flg_available = pk_alert_constant.g_yes
             INNER JOIN room r
                ON r.id_room = b.id_room
               AND r.flg_available = pk_alert_constant.g_yes
            
             INNER JOIN department d
                ON d.id_department = r.id_department
               AND d.flg_available = pk_alert_constant.g_yes
            
             INNER JOIN epis_info ei
                ON ei.id_bed = b.id_bed
            
              LEFT JOIN TABLE(pk_bmng_core.tf_get_bed_status(i_lang, i_prof, table_number(d.id_department), table_number(ba.id_bmng_action))) icons
                ON icons.id_bed = b.id_bed
            
             WHERE ei.id_episode = i_episode
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a;
    
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
            pk_types.open_my_cursor(o_result);
        
            RETURN FALSE;
    END get_epis_bed_allocation;

    /***************************************************************************************************************
    *
    * CHANGES STATUS OF GIVEN BED AS VACANT/EMPTY OF EPISODE  
    *  
    * 
    * @param      i_lang                language ID
    * @param      i_prof                Professional calling this function.
    * @param      i_id_episode          ID_EPISODE to check for bed allocations.
    * @param      i_transaction_id      remote transaction identifier
    * @param      i_allocation_commit   Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param      o_error               If an error accurs, this parameter will have information about the error
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
        i_allocation_commit     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_discharge_schedule IN VARCHAR2 DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_bed                bed.id_bed%TYPE;
        l_id_room               room.id_room%TYPE;
        l_id_dep                department.id_department%TYPE;
        l_id_pat                patient.id_patient%TYPE;
        l_id_bab                bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_ba                 bmng_action.id_bmng_action%TYPE;
        l_id_bed_type           bed_type.id_bed_type%TYPE;
        l_id_bdcs               bed_dep_clin_serv.id_dep_clin_serv%TYPE;
        l_bed_allocation        VARCHAR2(1);
        l_exception_info        sys_message.desc_message%TYPE;
        error_bed_status_vacant EXCEPTION;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'GET EPISODE BED:' || i_id_episode;
        SELECT ei.id_bed,
               r.id_department,
               ei.id_patient,
               b.id_bed_type,
               r.id_room,
               bdcs.id_dep_clin_serv,
               bab.id_bmng_allocation_bed,
               ba.id_bmng_action
          INTO l_id_bed, l_id_dep, l_id_pat, l_id_bed_type, l_id_room, l_id_bdcs, l_id_bab, l_id_ba
          FROM epis_info ei
          LEFT JOIN bmng_allocation_bed bab
            ON bab.id_episode = ei.id_episode
           AND bab.flg_outdated = pk_alert_constant.g_no
          LEFT JOIN bmng_action ba
            ON ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
           AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
          LEFT JOIN bed b
            ON b.id_bed = ei.id_bed
          LEFT JOIN room r
            ON r.id_room = b.id_room
          LEFT JOIN bed_dep_clin_serv bdcs
            ON bdcs.id_bed = b.id_bed
           AND bdcs.id_dep_clin_serv = ei.id_dep_clin_serv
         WHERE ei.id_episode = i_id_episode
           AND rownum = 1;
    
        IF (l_id_bed IS NOT NULL AND l_id_bab IS NOT NULL)
        THEN
            --Function below is BMNG
            g_error := 'SET BED VACANT:' || l_id_bed || ' ID_EPISODE:' || i_id_episode;
        
            IF NOT pk_bmng.set_bed_management(i_lang                   => i_lang,
                                              i_prof                   => i_prof,
                                              i_id_bmng_action         => table_number(l_id_ba),
                                              i_id_department          => table_number(l_id_dep),
                                              i_id_room                => table_number(l_id_room),
                                              i_id_bed                 => table_number(l_id_bed),
                                              i_id_bmng_reason         => table_number(NULL),
                                              i_id_bmng_allocation_bed => table_number(l_id_bab),
                                              i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                              i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                              i_nch_capacity           => table_number(NULL),
                                              i_action_notes           => table_varchar(NULL),
                                              i_dt_begin_action        => table_varchar(pk_date_utils.to_char_timezone(i_lang,
                                                                                                                       current_timestamp,
                                                                                                                       pk_alert_constant.g_dt_yyyymmddhh24miss)),
                                              i_dt_end_action          => table_varchar(NULL),
                                              i_id_episode             => table_number(i_id_episode),
                                              i_id_patient             => table_number(l_id_pat),
                                              i_nch_hours              => NULL,
                                              i_flg_allocation_nch     => NULL,
                                              i_desc_bed               => NULL,
                                              i_id_bed_type            => table_number(l_id_bed_type),
                                              i_dt_discharge_schedule  => i_dt_discharge_schedule,
                                              i_id_bed_dep_clin_serv   => l_id_bdcs,
                                              i_flg_origin_action_ux   => pk_bmng_constant.g_bmng_flg_origin_ux_v,
                                              i_reason_notes           => NULL,
                                              i_transaction_id         => l_transaction_id,
                                              i_allocation_commit      => i_allocation_commit,
                                              o_id_bmng_allocation_bed => l_id_bab,
                                              o_id_bed                 => l_id_bed,
                                              o_bed_allocation         => l_bed_allocation,
                                              o_exception_info         => l_exception_info,
                                              o_error                  => o_error)
            THEN
                RAISE error_bed_status_vacant;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN error_bed_status_vacant THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ERROR_BED_STATUS_VACANT');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_BED_STATUS_VACANT',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_EPISODE_BED_STATUS_VACANT');
                l_error_in.set_action(l_error_message, 'U');
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPISODE_BED_STATUS_VACANT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_episode_bed_status_vacant;

    /********************************************************************************************************************************************
    * Function that returns the bed scheduled to an episode. If a schedule exists the bed comes from scheduler, 
    * otherwise it comes from schedule_inp_bed table
    *
    * @param  I_LANG                     Language associated to the professional executing the request
    * @param  I_PROF                     Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE               Episode identifier
    * @param  I_ID_SCHEDULE              Schedule identifier
    * @param  O_ID_BED                   Bed identifier    
    * @param  O_ERROR                    If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   2009/10/21
    *
    *******************************************************************************************************************************************/
    FUNCTION get_bed_scheduled
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_id_bed      OUT bed.id_bed%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF (i_id_schedule IS NOT NULL)
        THEN
            g_error := 'CALL PK_SCHEDULE_INP.GET_SCH_BED WITH ID_EPISODE: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_schedule_inp.get_sch_bed(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_episode => i_id_episode,
                                               o_id_bed     => o_id_bed,
                                               o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            BEGIN
                g_error := 'SELECT ID_BED WITH ID_EPISODE: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                SELECT sib.id_bed
                  INTO o_id_bed
                  FROM schedule_inp_bed sib
                 WHERE sib.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_bed := NULL;
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
                                              'GET_BED_SCHEDULED',
                                              o_error);
            RETURN FALSE;
    END get_bed_scheduled;

    /***************************************************************************************************************
    *
    * Provides the data to be displayed in the ancillary insight grid - bed cleaning 
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
        l_margin    PLS_INTEGER;
        l_time_unit VARCHAR2(20) := 'HOUR';
        l_ba        table_number := table_number();
    
        l_tmp_bed bed.id_bed%TYPE;
        l_tmp_ba  bmng_action.id_bmng_action%TYPE;
    
        CURSOR c_bed_cleaning IS
            SELECT ba.id_bmng_action, bab.id_bed, ba.flg_bed_cleaning_status, ba.dt_begin_action
              FROM bmng_allocation_bed bab
             INNER JOIN bmng_action ba
                ON ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
             INNER JOIN bmng_reason_type brt
                ON ba.id_bmng_reason_type = brt.id_bmng_reason_type
               AND brt.subject IN ('DIRTY_BED_ACTION',
                                   'CONTAMINATED_BED_ACTION',
                                   'CLEANING_IN_PROCESS_BED_ACTION',
                                   'CLEANING_CONCLUDED_BED_ACTION')
             WHERE bab.id_episode = i_epis
               AND pk_date_utils.add_to_ltstz(ba.dt_begin_action, l_margin, l_time_unit) >= current_timestamp
            UNION
            SELECT ba.id_bmng_action, bab.id_bed, ba.flg_bed_cleaning_status, ba.dt_begin_action
              FROM bmng_allocation_bed bab
             INNER JOIN bmng_action ba
                ON ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
             WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND bab.id_episode = i_epis
             ORDER BY dt_begin_action;
    
    BEGIN
    
        g_error := 'GET SYS CONFIG';
        pk_alertlog.log_debug(g_error);
        l_margin := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_anc_limit, i_prof);
    
        g_error := 'OPEN C_BED_CLEANING';
        pk_alertlog.log_debug(g_error);
        FOR l_bc IN c_bed_cleaning
        LOOP
        
            IF l_tmp_bed IS NOT NULL
               AND (l_bc.id_bed != l_tmp_bed OR
               l_bc.flg_bed_cleaning_status IN
               (pk_bmng_constant.g_bmng_act_flg_cleani_d, pk_bmng_constant.g_bmng_act_flg_cleani_c))
            THEN
                l_ba.extend;
                l_ba(l_ba.last) := l_tmp_ba;
            END IF;
        
            l_tmp_bed := l_bc.id_bed;
            l_tmp_ba  := l_bc.id_bmng_action;
        END LOOP;
    
        g_error := 'PROCESS LAST RESULT';
        IF l_tmp_ba IS NOT NULL
        THEN
            l_ba.extend;
            l_ba(l_ba.last) := l_tmp_ba;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_beds FOR
            SELECT r.id_room,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc_type,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc_name,
                   b.id_bed,
                   decode(b.flg_type,
                          pk_bmng_constant.g_bmng_bed_flg_type_t,
                          b.desc_bed,
                          pk_bmng_constant.g_bmng_bed_flg_type_p,
                          nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))) bed_desc_name,
                   pk_date_utils.date_send_tsz(i_lang, ba.dt_begin_action, i_prof) num_desc_ordered,
                   pk_date_utils.to_char_timezone(i_lang,
                                                  ba.dt_creation,
                                                  pk_sysconfig.get_config('DATE_HOUR_FORMAT', i_prof)) dt_desc_ordered,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_desc_type,
                   pk_bmng_core.get_all_bed_specs_int(i_lang, i_prof, b.id_bed) bed_desc_spec,
                   pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specs,
                   pk_sysdomain.get_domain('BMNG_ACTION.FLG_BED_OCCUPANCY_STATUS', ba.flg_bed_ocupacity_status, i_lang) bed_ocupacity_status,
                   
                   pk_sysdomain.get_domain('BMNG_ACTION.FLG_BED_CLEANING_STATUS', ba.flg_bed_cleaning_status, i_lang) bed_cleaning_status,
                   
                   pk_translation.get_translation(i_lang, d.code_department) ||
                   decode(nvl(at.desc_admission_type, at.code_admission_type),
                          NULL,
                          '',
                          ' (' ||
                          nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ba.id_prof_creation) prof_ordered
              FROM bmng_action ba
             INNER JOIN bed b
                ON ba.id_bed = b.id_bed
               AND b.flg_available = pk_alert_constant.g_yes
             INNER JOIN room r
                ON r.id_room = b.id_room
               AND r.flg_available = pk_alert_constant.g_yes
             INNER JOIN department d
                ON d.id_department = r.id_department
               AND d.flg_available = pk_alert_constant.g_yes
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              LEFT JOIN bed_type bt
                ON bt.id_bed_type = b.id_bed_type
              LEFT JOIN room_type rt
                ON rt.id_room_type = r.id_room_type
             WHERE ba.id_bmng_action IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(l_ba) t)
             ORDER BY num_desc_ordered DESC;
    
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
    
        g_error := 'GET_BED_DESC';
        BEGIN
            SELECT decode(b.flg_type,
                          pk_bmng_constant.g_bmng_bed_flg_type_t,
                          b.desc_bed,
                          pk_bmng_constant.g_bmng_bed_flg_type_p,
                          nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)))
              INTO o_desc
              FROM epis_info ei
             INNER JOIN bed b
                ON b.id_bed = ei.id_bed
             WHERE ei.id_episode = i_epis;
        EXCEPTION
            WHEN no_data_found THEN
                o_desc := NULL;
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
                                              'GET_BED_DESC',
                                              o_error);
            RETURN FALSE;
        
    END get_bed_desc;

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
    
        g_error := 'CLEAR EAs';
        pk_alertlog.log_debug(g_error);
        --        DELETE FROM bmng_bed_ea;
        --        DELETE FROM bmng_department_ea;
        --      dbms_output.put_line(g_error || ' - Ok');
    
        g_error := 'admin_all_bmng_tables';
        pk_alertlog.log_debug(g_error);
        pk_data_gov_admin.admin_70_all_bmng_tables;
    
    END bmng_housekeeping;

    /*
    *   SCH-9704 changes in date mask format from expected discharge and blocked_until fields due to Flash restrictions
    */
    FUNCTION get_bed_detail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE,
        o_output OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'GET_BED_DETAIL';
        l_id_dep      room.id_department%TYPE;
        l_dt          TIMESTAMP WITH LOCAL TIME ZONE;
        l_default_nch PLS_INTEGER;
        l_str         VARCHAR2(32767);
    
        CURSOR c IS
            SELECT b.id_room,
                   ba.flg_bed_status,
                   ba.id_prof_creation,
                   ba.dt_creation,
                   pk_translation.get_translation(i_lang, d.code_department) ||
                   decode(nvl(at.desc_admission_type, at.code_admission_type),
                          NULL,
                          '',
                          ' (' ||
                          nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_dep,
                   pk_translation.get_translation(i_lang, d.code_department) desc_dep_short,
                   pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specs,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc_name,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc_type,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_desc_name,
                   CASE
                        WHEN bt.id_bed_type = -1 THEN
                         NULL
                        ELSE
                         nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type))
                    END bed_desc_type,
                   get_bed_dep_clin_serv(i_lang, i_prof, b.id_bed) bed_desc_spec,
                   icons.desc_availability bed_status_avail,
                   pk_sysdomain.get_domain('BMNG_ACTION.FLG_BED_STATUS', ba.flg_bed_status, i_lang) bed_status,
                   ba.action_notes action_notes,
                   icons.desc_bed_status bed_ocupacity_status,
                   icons.desc_cleaning_status bed_cleaning_status,
                   --pk_date_utils.date_send_tsz(i_lang, bbea.dt_discharge_schedule, i_prof) DT_DISCHARGE_SCHEDULE,
                   pk_date_utils.date_char_tsz(i_lang, bbea.dt_discharge_schedule, i_prof.institution, i_prof.software) dt_discharge_schedule,
                   pk_patient.get_pat_name(i_lang, i_prof, bbea.id_patient, bbea.id_episode) pat_name,
                   CASE
                        WHEN ba.flg_action = 'B' THEN -- latest action = bed Blocked
                         (SELECT pk_translation.get_translation(i_lang, code_bmng_reason)
                            FROM bmng_reason br
                           WHERE br.id_bmng_reason = ba.id_bmng_reason
                             AND br.id_bmng_reason_type = ba.id_bmng_reason_type
                             AND rownum = 1)
                        ELSE
                         ''
                    END blocking_reason,
                   CASE
                        WHEN ba.flg_action = 'B' THEN -- latest action = bed Blocked
                        --pk_date_utils.date_send_tsz(i_lang, ba.dt_end_action, i_prof)
                         pk_date_utils.date_char_tsz(i_lang, ba.dt_end_action, i_prof.institution, i_prof.software)
                        ELSE
                         ''
                    END blocked_until,
                   decode(bbea.id_episode,
                          NULL,
                          '',
                          pk_nch_pbl.get_format_nch_info(i_lang,
                                                         decode(bbea.id_episode,
                                                                NULL,
                                                                NULL,
                                                                nvl(pk_nch_pbl.get_nch_total(i_lang,
                                                                                             i_prof,
                                                                                             bbea.id_episode,
                                                                                             l_dt),
                                                                    l_default_nch)))) nch_hours
              FROM bed b
              JOIN room r
                ON b.id_room = r.id_room
              JOIN department d
                ON d.id_department = r.id_department
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
              LEFT JOIN room_type rt
                ON rt.id_room_type = r.id_room_type
              LEFT JOIN bed_type bt
                ON b.id_bed_type = bt.id_bed_type
              JOIN TABLE(pk_bmng_core.tf_get_bed_status(i_lang, i_prof, table_number(l_id_dep), NULL)) icons
                ON icons.id_bed = b.id_bed
              LEFT JOIN bmng_action ba
                ON b.id_bed = ba.id_bed
               AND ba.id_room = b.id_room
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_b
              LEFT JOIN bmng_bed_ea bbea
                ON bbea.id_bed = b.id_bed
               AND bbea.dt_begin < l_dt
               AND bbea.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o
             WHERE b.id_bed = i_id_bed;
    
        lc c%ROWTYPE;
    
    BEGIN
        -- get this room's department id
        g_error := l_func_name || ' - get l_id_dep';
        SELECT id_department
          INTO l_id_dep
          FROM bed b
          JOIN room r
            ON b.id_room = r.id_room
         WHERE b.id_bed = i_id_bed;
    
        -- init var
        l_dt          := current_timestamp;
        l_default_nch := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_pat, i_prof);
    
        -- get raw data
        g_error := l_func_name || ' - OPEN cursor c';
        OPEN c;
        FETCH c
            INTO lc;
    
        IF c%NOTFOUND
        THEN
            CLOSE c;
            raise_application_error(-20000, l_func_name || ' - no data found for id_bed ' || i_id_bed);
        END IF;
    
        CLOSE c;
    
        --Initialization of detail table
        g_error := l_func_name || ' - CALL pk_edis_hist.init_vars';
        pk_edis_hist.init_vars;
    
        -- line necessary
        g_error := l_func_name || ' - CALL pk_edis_hist.add_line';
        pk_edis_hist.add_line(i_history        => -1,
                              i_dt_hist        => pk_date_utils.get_string_tstz(i_lang     => i_lang,
                                                                                i_prof     => i_prof,
                                                                                i_timezone => NULL),
                              i_record_state   => lc.flg_bed_status,
                              i_desc_rec_state => lc.bed_status,
                              i_professional   => lc.id_prof_creation,
                              i_episode        => NULL);
    
        -- field: service
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_service),
                               i_value    => lc.desc_dep || ', ' || lc.desc_dep_short || ', ' || lc.desc_specs,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: room name
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_room_name),
                               i_value    => lc.room_desc_name,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: room type
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_room_type),
                               i_value    => lc.room_desc_type,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: bed name
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_bed_name),
                               i_value    => lc.bed_desc_name,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: bed type
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_bed_type),
                               i_value    => lc.bed_desc_type,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: bed specialties
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_bed_specs),
                               i_value    => lc.bed_desc_spec,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: expected discharge date
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_dt_discharge),
                               i_value    => lc.dt_discharge_schedule,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: nursing care hours
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_nch),
                               i_value    => lc.nch_hours,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: patient name
        IF lc.pat_name IS NOT NULL
        THEN
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_bmng_constant.g_bmng_label_pat_name),
                                   i_value    => lc.pat_name,
                                   i_type     => pk_edis_hist.g_type_content);
        END IF;
    
        -- field: bed status
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_bed_status),
                               i_value    => lc.bed_status,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: bed cleaning status
        IF lc.bed_cleaning_status IS NOT NULL
        THEN
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_bmng_constant.g_bmng_label_bed_cl_status),
                                   i_value    => lc.bed_cleaning_status,
                                   i_type     => pk_edis_hist.g_type_content);
        END IF;
    
        -- fields group: blocked bed fields                                                          
        IF lc.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b
        THEN
        
            -- field: blocking reason
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_bmng_constant.g_bmng_label_block_reason),
                                   i_value    => lc.blocking_reason,
                                   i_type     => pk_edis_hist.g_type_content);
        
            -- field: blocked until
            pk_edis_hist.add_value(i_lang     => i_lang,
                                   i_flg_call => pk_edis_hist.g_call_detail,
                                   i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => pk_bmng_constant.g_bmng_label_blocked_until),
                                   i_value    => lc.blocked_until,
                                   i_type     => pk_edis_hist.g_type_content);
        END IF;
    
        -- field: notes
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => pk_bmng_constant.g_bmng_label_action_notes),
                               i_value    => lc.action_notes,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: signature
        l_str := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                            i_id_episode             => NULL,
                                            i_prof                   => i_prof,
                                            i_date                   => lc.dt_creation,
                                            i_id_prof_last_change    => lc.id_prof_creation,
                                            i_has_historical_changes => pk_alert_constant.g_no);
    
        pk_edis_hist.add_value(i_label => NULL,
                               i_value => l_str,
                               i_type  => pk_edis_hist.g_type_signature,
                               i_code  => 'SIGNATURE');
    
        -- return output
        OPEN o_output FOR
            SELECT *
              FROM (SELECT t.id_history,
                           -- viewer fields
                           t.id_history viewer_category,
                           t.desc_cat_viewer viewer_category_desc,
                           t.id_professional viewer_id_prof,
                           t.id_episode viewer_id_epis,
                           pk_date_utils.date_send_tsz(i_lang, t.dt_history, i_prof) viewer_date,
                           --
                           t.dt_history,
                           t.tbl_labels,
                           t.tbl_values,
                           t.tbl_types,
                           t.tbl_info_labels,
                           t.tbl_info_values,
                           t.tbl_codes,
                           (SELECT COUNT(*)
                              FROM TABLE(t.tbl_types)) count_elems
                      FROM TABLE(pk_edis_hist.tf_hist) t)
            -- remove history entries that have no difference from the previous record
            -- this is necessary due to diagnosis replications in the same visit
             WHERE count_elems > 2;
    
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
    END get_bed_detail;

    /**********************************************************************************************
    * Check patient is in icu by room 
    *
    * @param i_episode               Episode ID
    * @param i_lang                  Language ID
    * @param i_prof                  profissional info
    *
    * @return                        true or false
    *
    * @author                        Amanda Lee
    * @version                       2.7.2.3
    * @since                         2018/01/02
    **********************************************************************************************/
    FUNCTION check_patient_firt_time_in_icu
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(30 CHAR) := 'CHECK_PATIENT_FIRT_TIME_IN_ICU';
        l_count     NUMBER(3) := 0;
        l_return    VARCHAR2(001 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        g_error := 'CALL CHECK_PATIENT_FIRT_TIME_IN_ICU';
    
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => l_func_name,
                             owner           => g_package_owner);
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT *
                  FROM (SELECT rownum rn, bab.*
                          FROM bmng_allocation_bed bab
                         WHERE bab.id_episode = i_episode
                         ORDER BY bab.dt_creation) xql
                 WHERE rn = 1) bm
          JOIN bed b
            ON b.id_bed = bm.id_bed
          JOIN room r
            ON r.id_room = b.id_room
         WHERE r.flg_icu = pk_alert_constant.g_yes;
    
        IF l_count > 0
        THEN
            l_return := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    END check_patient_firt_time_in_icu;

    FUNCTION tf_get_patient_transf_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf IS
        l_func_name       VARCHAR2(30) := 'TF_GET_PATIENT_TRANSF_BED';
        l_error           t_error_out;
        l_tbl_bmng_transf t_table_epis_transf;
        l_transf_bed      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'BMNG_T145');
        l_id_type_location CONSTANT NUMBER(24) := 2;
    
    BEGIN
        SELECT t_rec_epis_transf(bab.id_episode,
                                 l_id_type_location,
                                 bab.dt_creation,
                                 l_transf_bed,
                                 nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) || ' - ' ||
                                 nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)))
          BULK COLLECT
          INTO l_tbl_bmng_transf
          FROM bmng_allocation_bed bab
          JOIN bed b
            ON b.id_bed = bab.id_bed
          JOIN room r
            ON r.id_room = b.id_room
         WHERE bab.id_episode = i_id_episode
         ORDER BY bab.dt_creation ASC;
    
        RETURN l_tbl_bmng_transf;
    
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
    END tf_get_patient_transf_bed;

    FUNCTION get_pat_location_by_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_transf  IN bmng_allocation_bed.dt_creation%TYPE,
        i_admission  IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(30) := 'TF_GET_PATIENT_TRANSF_BED';
        l_error     t_error_out;
        l_location  VARCHAR2(4000 CHAR);
    
    BEGIN
    
        SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) || ' - ' ||
               nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))
          INTO l_location
          FROM (SELECT bab.id_episode,
                       bab.id_bed,
                       row_number() over(ORDER BY bab.dt_creation DESC) rn,
                       row_number() over(ORDER BY bab.dt_creation ASC) rna
                  FROM bmng_allocation_bed bab
                 WHERE bab.id_episode = i_id_episode
                   AND ((pk_date_utils.compare_dates_tsz(i_prof, bab.dt_creation, i_dt_transf) IN
                       (pk_alert_constant.g_date_lower, pk_alert_constant.g_date_equal) AND
                       i_admission = pk_alert_constant.g_no) OR
                       ((pk_date_utils.compare_dates_tsz(i_prof, bab.dt_creation, i_dt_transf) IN
                       (pk_alert_constant.g_date_equal) AND i_admission = pk_alert_constant.g_yes)))) bab
          JOIN bed b
            ON b.id_bed = bab.id_bed
          JOIN room r
            ON r.id_room = b.id_room
         WHERE (rn = 1 AND i_admission = pk_alert_constant.g_no)
            OR (rna = 1 AND i_admission = pk_alert_constant.g_yes);
    
        RETURN l_location;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_pat_location_by_date;

    /**********************************************************************************************
    * Check patient is in icu by room 
    *
    * @param i_episode               Episode ID
    * @param i_lang                  Language ID
    * @param i_prof                  profissional info
    *
    * @return                        true or false
    *
    * @author                        Lillian Lu
    * @version                       2.7.2.3
    * @since                         2018/01/19
    **********************************************************************************************/
    FUNCTION check_patient_in_icu
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(030 CHAR) := 'CHECK_PATIENT_IN_ICU';
        l_flg_icu   VARCHAR2(001 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        g_error := 'CALL CHECK_PATIENT_IN_ICU';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => l_func_name,
                             owner           => g_package_owner);
    
        SELECT decode(flg_icu, pk_alert_constant.g_yes, pk_alert_constant.g_yes, pk_alert_constant.g_no)
          INTO l_flg_icu
          FROM (SELECT r.flg_icu, rank() over(PARTITION BY bab.id_episode ORDER BY bab.dt_creation DESC) AS rank1
                  FROM bmng_allocation_bed bab
                  JOIN bed b
                    ON b.id_bed = bab.id_bed
                  JOIN room r
                    ON r.id_room = b.id_room
                 WHERE bab.id_episode = i_episode
                   AND bab.flg_outdated = pk_alert_constant.g_no) t
         WHERE t.rank1 = 1;
    
        RETURN l_flg_icu;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
    END check_patient_in_icu;

    /********************************************************************************************
    * Get the last n ICU service transfer in/out date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode          episode ID
    * @param   i_rank                last n value
    * @param   i_flg_in_out      {*} 'I'- IN {*} 'O'- OUT 
    *
    * @return  Last ICU service transfer date
    *
    * @author                         Lillian Lu
    * @version                        2.7.3.5
    * @since                          2018-05-30
    **********************************************************************************************/
    FUNCTION get_last_n_icu_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_rank         IN NUMBER DEFAULT 1,
        o_icu_in_date  OUT bmng_allocation_bed.dt_creation%TYPE,
        o_icu_out_date OUT bmng_allocation_bed.dt_release%TYPE
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(030 CHAR) := 'GET_LAST_N_ICU_DATE';
    
        l_tbl_bmng_bed_transf t_table_bmng_bed_transf;
    
    BEGIN
    
        g_error := 'CALL GET_LAST_N_ICU_DATE';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => l_func_name,
                             owner           => g_package_owner);
    
        l_tbl_bmng_bed_transf := pk_bmng.tf_get_patient_transf_icu(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_episode => i_episode);
    
        SELECT dt_creation
          INTO o_icu_in_date
          FROM (SELECT tt.dt_creation, rank() over(ORDER BY tt.rank DESC) rank2
                  FROM (SELECT t.dt_creation, t.rank, rank() over(PARTITION BY t.rank ORDER BY t.dt_creation) AS rank1
                          FROM TABLE(l_tbl_bmng_bed_transf) t
                         WHERE t.flg_icu = pk_alert_constant.g_yes
                         ORDER BY t.rank DESC) tt
                 WHERE tt.rank1 = 1)
         WHERE rank2 = i_rank;
    
        SELECT dt_release
          INTO o_icu_out_date
          FROM (SELECT tt.dt_release, rank() over(ORDER BY tt.rank DESC) rank2
                  FROM (SELECT t.dt_release,
                               t.rank,
                               rank() over(PARTITION BY t.rank ORDER BY t.dt_creation DESC) AS rank1
                          FROM TABLE(l_tbl_bmng_bed_transf) t
                         WHERE t.flg_icu = pk_alert_constant.g_yes
                         ORDER BY t.rank DESC) tt
                 WHERE tt.rank1 = 1)
         WHERE rank2 = i_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_last_n_icu_date;

    /********************************************************************************************
    * Get the last ICU service transfer date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Last ICU service transfer date
    *
    * @author                         Amanda Lee
    * @version                        2.7.3
    * @since                          16-01-2018
    **********************************************************************************************/
    FUNCTION get_last_icu_in_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN bmng_allocation_bed.dt_creation%TYPE IS
        l_func_name    VARCHAR2(030 CHAR) := 'GET_LAST_ICU_IN_DATE';
        l_icu_in_date  bmng_allocation_bed.dt_creation%TYPE;
        l_icu_out_date bmng_allocation_bed.dt_release%TYPE;
    BEGIN
    
        g_error := 'CALL GET_LAST_ICU_IN_DATE';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => l_func_name,
                             owner           => g_package_owner);
    
        IF NOT get_last_n_icu_date(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   i_rank         => 1,
                                   o_icu_in_date  => l_icu_in_date,
                                   o_icu_out_date => l_icu_out_date)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_icu_in_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_icu_in_date;

    /********************************************************************************************
    * Get the last ICU service transfer out date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Last ICU service transfer date
    *
    * @author                         Lillian Lu
    * @version                        2.7.3
    * @since                          16-01-2018
    **********************************************************************************************/
    FUNCTION get_last_icu_out_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN bmng_allocation_bed.dt_release%TYPE IS
        l_func_name    VARCHAR2(030 CHAR) := 'GET_LAST_ICU_OUT_DATE';
        l_icu_in_date  bmng_allocation_bed.dt_creation%TYPE;
        l_icu_out_date bmng_allocation_bed.dt_release%TYPE;
    BEGIN
    
        g_error := 'CALL GET_LAST_ICU_OUT_DATE';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => l_func_name,
                             owner           => g_package_owner);
    
        IF NOT get_last_n_icu_date(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   i_rank         => 1,
                                   o_icu_in_date  => l_icu_in_date,
                                   o_icu_out_date => l_icu_out_date)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_icu_out_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_icu_out_date;

    /********************************************************************************************
    * Get the last ICU service transfer out date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Last ICU service transfer date
    *
    * @author                         Lillian Lu
    * @version                        2.7.3
    * @since                          16-01-2018
    **********************************************************************************************/
    FUNCTION get_previous_icu_io_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_icu_in_date  OUT bmng_allocation_bed.dt_creation%TYPE,
        o_icu_out_date OUT bmng_allocation_bed.dt_creation%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(030 CHAR) := 'GET_PREVIOUS_ICU_IO_DATE';
    
        l_tbl_bmng_bed_transf t_table_bmng_bed_transf;
        l_reenter_icu         BOOLEAN;
    BEGIN
        l_reenter_icu := pk_bmng.check_reenter_icu(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        IF l_reenter_icu
        THEN
            RETURN get_last_n_icu_date(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => i_episode,
                                       i_rank         => 2,
                                       o_icu_in_date  => o_icu_in_date,
                                       o_icu_out_date => o_icu_out_date);
        ELSE
            o_icu_in_date  := NULL;
            o_icu_out_date := NULL;
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
            RETURN FALSE;
    END get_previous_icu_io_date;

    /**********************************************************************************************
    * Check patient is reenter to ICU
    *
    * @param i_episode               Episode ID
    * @param i_lang                  Language ID
    * @param i_prof                  profissional info
    *
    * @return                        Boolean
    *
    * @author                        Amanda Lee
    * @version                       2.7.2.3
    * @since                         2018/01/19
    **********************************************************************************************/
    FUNCTION check_reenter_icu
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(030 CHAR) := 'CHECK_REENTER_ICU';
        l_count     NUMBER(003) := 0;
    BEGIN
        g_error := 'CALL CHECK_PATIENT_IN_ICU';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => l_func_name,
                             owner           => g_package_owner);
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT rank() over(PARTITION BY t.rank ORDER BY t.dt_creation) rank1
                  FROM TABLE(pk_bmng.tf_get_patient_transf_icu(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_episode => i_episode)) t
                 WHERE t.flg_icu = pk_alert_constant.g_yes)
         WHERE rank1 = 1;
    
        IF (l_count > 1)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    END check_reenter_icu;

    /**********************************************************************************************
    *  get patient transfer bed info
    *
    * @param i_episode               Episode ID
    * @param i_lang                  Language ID
    * @param i_prof                  profissional info
    *
    * @return                        Boolean
    *
    * @author                        Lillian Lu
    * @version                       2.7.3.4
    * @since                         2018/05/25
    **********************************************************************************************/
    FUNCTION tf_get_patient_transf_icu
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_table_bmng_bed_transf IS
    
        l_tbl_out_bmng_bed_transf t_table_bmng_bed_transf := t_table_bmng_bed_transf();
    
        l_count_records PLS_INTEGER := 0;
        l_rank          PLS_INTEGER := 0;
    
    BEGIN
    
        FOR rec IN (SELECT r.id_room, b.id_bed, bab.dt_creation, bab.dt_release, r.flg_icu
                      FROM bmng_allocation_bed bab
                      JOIN bed b
                        ON b.id_bed = bab.id_bed
                      JOIN room r
                        ON r.id_room = b.id_room
                     WHERE bab.id_episode = i_episode
                     ORDER BY bab.dt_creation)
        LOOP
            IF ((l_count_records = 0) OR
               ((l_count_records > 0) AND (l_tbl_out_bmng_bed_transf(l_count_records).flg_icu <> rec.flg_icu)))
            THEN
                l_rank := l_rank + 1;
            END IF;
            l_tbl_out_bmng_bed_transf.extend();
            l_count_records := l_tbl_out_bmng_bed_transf.count;
            l_tbl_out_bmng_bed_transf(l_count_records) := t_rec_bmng_bed_transf(rec.id_room,
                                                                                rec.id_bed,
                                                                                rec.dt_creation,
                                                                                rec.dt_release,
                                                                                l_rank,
                                                                                rec.flg_icu);
        
        END LOOP;
    
        RETURN l_tbl_out_bmng_bed_transf;
    
    END tf_get_patient_transf_icu;

    FUNCTION check_bed_inp_department(i_id_bed IN epis_info.id_bed%TYPE) RETURN VARCHAR2 IS
        l_num NUMBER;
    BEGIN
    
        g_error := 'OPEN CURSOR';
    
        SELECT instr(d.flg_type, 'I')
          INTO l_num
          FROM bed b
          JOIN room r
            ON b.id_room = r.id_room
          JOIN department d
            ON r.id_department = d.id_department
         WHERE b.id_bed = i_id_bed;
    
        IF l_num = 0
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_bed_inp_department;

BEGIN
    -- Log initialization..
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_bmng;
/
