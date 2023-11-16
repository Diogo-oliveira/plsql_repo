/*-- Last Change Revision: $Rev: 2028544 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_bmng_ux IS

    -- Author  : LUIS.MAIA
    -- Created : 16-07-2009 16:53:27
    -- Purpose : Package that should contain all functions of Bed Management functionality called by FLASH using JAVA layer

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
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * SET_BED_MNG_REALOCATION
    * Function that performs a realocation, simply by setting the origin bed to a free status and setting the destination
    * bed to a occupied status. 
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
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
    FUNCTION set_bed_mng_realocation
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        -- OLD
        i_id_bmng_action_old         IN table_number,
        i_id_department_old          IN table_number,
        i_id_room_old                IN table_number,
        i_id_bed_old                 IN table_number,
        i_id_bmng_reason_old         IN table_number,
        i_id_bmng_allocation_bed_old IN table_number,
        i_flg_target_action_old      IN bmng_action.flg_target_action%TYPE,
        i_flg_status_old             IN bmng_action.flg_status%TYPE,
        i_nch_capacity_old           IN table_number,
        i_action_notes_old           IN table_varchar,
        i_dt_begin_action_old        IN table_varchar,
        i_dt_end_action_old          IN table_varchar,
        i_id_episode_old             IN table_number,
        i_id_patient_old             IN table_number,
        i_nch_hours_old              IN epis_nch.nch_value%TYPE,
        i_flg_allocation_nch_old     IN epis_nch.flg_type%TYPE,
        i_desc_bed_old               IN bed.desc_bed%TYPE,
        i_id_bed_type_old            IN table_number,
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
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                 OUT bed.id_bed%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        --
        o_error OUT t_error_out
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
        o_deps           OUT NOCOPY pk_types.cursor_type,
        o_error          OUT t_error_out
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
        o_serv        OUT NOCOPY pk_types.cursor_type,
        o_un_beds     OUT NOCOPY pk_types.cursor_type,
        o_av_beds     OUT NOCOPY pk_types.cursor_type,
        o_cap         OUT NOCOPY pk_types.cursor_type,
        o_room_types  OUT NOCOPY pk_types.cursor_type,
        o_date_server OUT VARCHAR2,
        o_error       OUT t_error_out
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
        o_list    OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_deps    OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        i_flg_type IN bed.flg_type%TYPE,
        o_beds     OUT NOCOPY pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        o_nch_list OUT NOCOPY pk_types.cursor_type,
        o_title    OUT sys_message.desc_message%TYPE,
        o_error    OUT t_error_out
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
        i_date      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT sys_message.desc_message%TYPE,
        o_msg_body  OUT sys_message.desc_message%TYPE,
        o_error     OUT t_error_out
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
        i_date      IN VARCHAR2,
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
        o_grid           OUT NOCOPY pk_types.cursor_type,
        o_conflict_found OUT VARCHAR2,
        o_error          OUT t_error_out
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
        o_block_list OUT NOCOPY pk_types.cursor_type,
        o_title      OUT NOCOPY sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
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
        o_beds  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
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

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    g_bed_status_n      CONSTANT VARCHAR2(1) := 'N'; --Normal
    g_bed_ocup_status_v CONSTANT VARCHAR2(1) := 'V'; --Vago

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_bmng_ux;
/
