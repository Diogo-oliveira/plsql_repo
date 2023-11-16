/*-- Last Change Revision: $Rev: 2028540 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_bmng IS

    -- Author  : LUIS.MAIA
    -- Created : 23-07-2009 09:19:02
    -- Purpose : Package that should contain all public functions of Bed Management functionality

    ----------------------------------------   FUNCTIONS   ----------------------------------------------

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
        i_date      IN VARCHAR2 DEFAULT current_timestamp,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT sys_message.desc_message%TYPE,
        o_msg_body  OUT sys_message.desc_message%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_bed   IN bed.id_bed%TYPE,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @RETURN  BOOLEAN
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   19-11-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_dep_clin_serv
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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

    FUNCTION get_unassigned_patients_v2
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN table_number,
        o_pats  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_date      IN VARCHAR2 DEFAULT current_timestamp,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT sys_message.desc_message%TYPE,
        o_msg_body  OUT sys_message.desc_message%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * SET_BMNG_ALLOCATION             For a provided episode updates the allocation bed.
      *
      * @param IN   i_lang              Language ID
      * @param IN   i_prof              Professional ID
      * @param IN   i_epis              ALERT ID of the episode to check
      * @param IN   i_id_bed            Bed identifier
      * @param IN   i_id_room           Room identifier
      * @param IN   i_flg_type          Bed type ('P'-permanent; 'T'-temporary)
      * @param IN   i_desc_bed          Description associated with this bed
      * @param IN   i_transaction_id    remote transaction identifier
      * @param IN   i_allocation_commit Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param in   i_dt_disch_sched    Espected date for current episode discharge
      * @param OUT  O_BED_ALLOCATION    Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
      * @param OUT  O_EXCEPTION_INFO    Error message to be displayed to the user.
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
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        o_pat_info      OUT pk_types.cursor_type,
        o_def_nch_value OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    PROCEDURE allocate_schedule_beds;

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
    PROCEDURE bmng_housekeeping;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    * @since   2009/10/22
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get all transfer bed in a episode
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_id_episode episode idenfier
    *
    * @return             Type with the transfer bed information
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01-12
    **********************************************************************************************/
    FUNCTION tf_get_patient_transf_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf;

    /********************************************************************************************
    * Gets thge patient location in a date
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_dt_transf  date
    * @param i_admission  in on admission (Y/N) 
    *
    * @return             Room and ben on that time
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01-12
    **********************************************************************************************/
    FUNCTION get_pat_location_by_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_transf  IN bmng_allocation_bed.dt_creation%TYPE,
        i_admission  IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the last ICU service transfer in date on an episode.
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
    ) RETURN bmng_allocation_bed.dt_creation%TYPE;

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
    ) RETURN bmng_allocation_bed.dt_release%TYPE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN t_table_bmng_bed_transf;

    FUNCTION check_bed_inp_department(i_id_bed IN epis_info.id_bed%TYPE) RETURN VARCHAR2;
    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_bmng;
/
