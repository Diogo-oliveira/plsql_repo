/*-- Last Change Revision: $Rev: 2028542 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_bmng_core IS

    -- Author  : LUIS.MAIA
    -- Created : 17-07-2009 18:54:58
    -- Purpose : Package that should contain all core functions of Bed Management functionality

    ----------------------------------------   FUNCTIONS   ----------------------------------------------

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
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * GET_BED_STATUS           Function that returns a specific bed status
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED         Bed identifier
    * @param  O_BED_FLG_STATUS Current bed status
    * @param  O_BED_FLG_STATUS Current bed type
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.7
    * @since   2009/10/02
    *
    *******************************************************************************************************************************************/
    FUNCTION get_bed_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_bed         IN bed.id_bed%TYPE,
        o_bed_flg_status OUT bed.flg_status%TYPE,
        o_bed_flg_type   OUT bed.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * SET_BED_MANAGEMENT                  Function that update an bed allocation information if that allocation exists, otherwise create one new bed allocation
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BMNG_ACTION            Bed management action identifier
    * @param  I_ID_DEPARTMENT             Department identifier
    * @param  I_ID_ROOM                   Room identifier
    * @param  I_ID_BED                    Bed identifier
    * @param  I_ID_BMNG_REASON            Reason identifier associated with current action
    * @param  I_ID_BMNG_ALLOCATION_BED    Bed management allocation identifier that should be updated or created in this function
    * @param  I_FLG_TARGET_ACTION         Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS                Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_NCH_CAPACITY              NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES              Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION           Date in which this action start counting
    * @param  I_DT_END_ACTION             Date in which this action became outdated
    * @param  I_ID_EPISODE                Episode identifier
    * @param  I_ID_PATIENT                Patient identifier
    * @param  I_NCH_HOURS                 Number of NCH associated with current allocation
    * @param  I_FLG_ALLOCATION_NCH        Is this NCH information definitive or automatically updated with NCH_LEVEL information (''D''- Definitive; ''U''- Updatable)
    * @param  I_DESC_BED                  Description associated with this bed
    * @param  I_ID_BED_TYPE               Bed type identifier of this bed
    * @param  I_DT_DICHARGE_SCHEDULE      Episode expected discharge
    * @param  I_FLG_ORIGIN_ACTION_UX      Type of action: FLAG defined in flash layer
    * @param  i_transaction_id            remote transaction identifier
    * @param  i_allocation_commit         Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param  O_ID_BMNG_ALLOCATION_BED    Return allocation identifier if one patient is allocated to a new bed
    * @param  O_ID_BED                    Return bed identifier
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
    * @author                  Luís Maia
    * @version                 2.5.0.5
    * @since                   2009/07/22
    *******************************************************************************************************************************************/
    FUNCTION set_bed_management
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_bmng_action               IN bmng_action.id_bmng_action%TYPE,
        i_id_department                IN bmng_action.id_department%TYPE,
        i_id_room                      IN bmng_action.id_room%TYPE,
        i_id_bed                       IN bmng_action.id_bed%TYPE,
        i_id_bmng_reason               IN bmng_action.id_bmng_reason%TYPE,
        i_id_bmng_allocation_bed       IN bmng_action.id_bmng_allocation_bed%TYPE,
        i_flg_target_action            IN bmng_action.flg_target_action%TYPE,
        i_flg_status                   IN bmng_action.flg_status%TYPE, --10
        i_nch_capacity                 IN bmng_action.nch_capacity%TYPE,
        i_action_notes                 IN bmng_action.action_notes%TYPE,
        i_dt_begin_action              IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end_action                IN bmng_action.dt_end_action%TYPE,
        i_id_episode                   IN bmng_allocation_bed.id_episode%TYPE,
        i_id_patient                   IN bmng_allocation_bed.id_patient%TYPE,
        i_nch_hours                    IN epis_nch.nch_value%TYPE,
        i_flg_allocation_nch           IN epis_nch.flg_type%TYPE,
        i_desc_bed                     IN bed.desc_bed%TYPE,
        i_id_bed_type                  IN bed.id_bed_type%TYPE, --20
        i_dt_discharge_schedule        IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_flg_hour_origin              IN VARCHAR2 DEFAULT 'DH',
        i_id_bed_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_origin_action_ux         IN VARCHAR2,
        i_reason_notes                 IN epis_nch.reason_notes%TYPE,
        i_transaction_id               IN VARCHAR2,
        i_allocation_commit            IN VARCHAR2,
        i_dt_creation                  IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_id_bmng_allocation_bed       OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                       OUT bed.id_bed%TYPE,
        o_bed_allocation               OUT VARCHAR2,
        o_exception_info               OUT sys_message.desc_message%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns nch_level for a specific department considering the requested date if not null
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_department   Department ID
    * @param IN   i_dt_requested Request date - should in the range of a specific BMNG_ACTION
    * @param OUT  o_nch_level    NCH hours for a specific department and date
    *                            (if date is null, then uses current information from bmng_department_ea
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_dt_request IN bmng_action.dt_begin_action%TYPE,
        o_nch_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_dt_request IN bmng_action.dt_begin_action%TYPE
    ) RETURN NUMBER;

    --different approach.
    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_nch_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************************************************************
    * GET_ALL_CLIN_SERVICES_INT   Function that returns all clinical services for given department
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT        Department ID
    * @param  O_ERROR             If an error occurs, this parameter will have information about the error
    *
    * @return                     Returns a string with all clinical services concatenated for the given department
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_all_clin_services_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************************************************************
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
    *******************************************************************************************************************************************/
    FUNCTION get_departments
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        o_deps    OUT pk_types.cursor_type,
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
    * @value  I_SHOW_OCCUPIED_BEDS      Y - Yes; N - No
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
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_rooms              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * GET_BMNG_ACTION_DT                Function that returns start and end date of the active bed action
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED                  Bed identifier
    * @param  O_BMNG_ACTION_START_DATE  Bed management action start date
    * @param  O_BMNG_ACTION_END_DATE    Bed management action end date
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author                           Luís Maia
    * @version                          2.6.0.3
    * @since                            26-Oct-2010
    *******************************************************************************************************************************************/
    FUNCTION get_bmng_action_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_bed                 IN bed.id_bed%TYPE,
        o_bmng_action_start_date OUT bmng_action.dt_begin_action%TYPE,
        o_bmng_action_end_date   OUT bmng_action.dt_begin_action%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
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
    *******************************************************************************************************************************************/
    FUNCTION get_beds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_room     IN room.id_room%TYPE,
        i_flg_type IN bed.flg_type%TYPE,
        o_beds     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
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
    *******************************************************************************************************************************************/
    FUNCTION get_rooms_beds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_rooms              OUT pk_types.cursor_type,
        o_beds               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Returns the ALERT IDs of the DEP_CLIN_SERVs associated to a bed.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the BED.
    * @param      o_dcs               Array of DEP_CLIN_SERVs
    * @param      o_error
    *
    * @RETURN  BOOLEAN 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_specialties
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_bed   IN bed.id_bed%TYPE,
        o_dcs   OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Returns the ALERT IDs of the DEP_CLIN_SERVs associated to a room.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.
    * @param      o_dcs               Array of DEP_CLIN_SERVs
    * @param      o_error
    *
    * @RETURN  BOOLEAN 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_specialties
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_dcs   OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Returns the ALERT IDs of the DEP_CLIN_SERVs associated to a department.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_dep               ID of the department.
    * @param      o_dcs               Array of DEP_CLIN_SERVs
    * @param      o_error
    *
    * @RETURN  BOOLEAN 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_dep_specialties
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_dcs   OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * GET_AVAILABILITY_INT        Function that returns the number of days left to the next bed schedule date
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BED               Bed ID
    *
    * @return                     Returns the number of days left to the next bed schedule date
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   23-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_availability_int
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************************************************************
    * TF_GET_BED_STATUS           Table function that returns all the necessary bed status information to be used by flash
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BMNG_ACTION       Bed action identifier
    *
    * @return                     Returns table function with one record with the following information:
    *                             - icon_bed_status         
    *                             - icon_bed_cleaning_status
    *                             - desc_bed_status         
    *                             - desc_cleaning_status    
    *                             - availability            
    *                             - flg_conflict            
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   21-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION tf_get_bed_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_depart_arr      IN table_number DEFAULT NULL,
        i_bmng_action_arr IN table_number DEFAULT NULL
    ) RETURN t_table_bmng_bed_status;

    /********************************************************************************************************************************************
    * TF_GET_BED_STATUS           Table function that returns all the necessary bed status information to be used by flash
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BMNG_ACTION       Bed action identifier
    *
    * @return                     Returns table function with one record with the following information:
    *                             - icon_bed_status         
    *                             - icon_bed_cleaning_status
    *                             - desc_bed_status         
    *                             - desc_cleaning_status    
    *                             - availability            
    *                             - flg_conflict            
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   24-Ago-2009
    *******************************************************************************************************************************************/
    FUNCTION tf_get_all_bed_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_depart_arr      IN table_number DEFAULT NULL,
        i_bmng_action_arr IN table_number DEFAULT NULL
    ) RETURN t_table_bmng_bed_status;

    /***************************************************************************************************************
    *
    * Returns the number of active actions in the same bed that have a provided status.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID of the episode.
    * @param      i_flg_bed_status    FLG status to count.
    *
    * @RETURN  NUMBER 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   24-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_count_bed_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_bed_status IN bmng_action.flg_status%TYPE
        
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_request_type      'A': All, 'P': Past, 'F': Future, 'D': Specific date
    * @param IN   i_request_date      request date when i_request_type = 'D'
    * @param IN   i_origin_action     ['N': 'NB', 'NT', 'ND'], ['B': 'BT', 'BD']
    *
    * @param OUT  o_intervals         Output cursor containing the intervals
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_bmng_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN department.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_request_date      IN bmng_action.dt_begin_action%TYPE,
        i_origin_action     IN bmng_action.flg_origin_action%TYPE,
        o_intervals         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_request_type      'A': All, 'P': Past, 'F': Future, 'D': Specific date
    * @param IN   i_begin_date        request begin date when i_request_type = 'D'
    * @param IN   i_end_date          request end date when i_request_type = 'D'
    * @param IN   i_origin_action     ['N': 'NB', 'NT', 'ND'], ['B': 'BT', 'BD']
    *
    * @param OUT  o_intervals         Output cursor containing the intervals
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version                  1.0
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_bmng_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN department.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_begin_date        IN bmng_action.dt_begin_action%TYPE,
        i_end_date          IN bmng_action.dt_end_action%TYPE,
        i_origin_action     IN bmng_action.flg_origin_action%TYPE,
        o_intervals         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns an array of departments (not cursor) belonging to an institution
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_institution  Institution ID
    
    * @param OUT  o_deps         Departments array (table_number)
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    27/07/2009
    ********************************************************************************************/
    FUNCTION get_institution_departments
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_deps        OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * GET_TIME_FRAME_INT       Function that returns the NCH/day group
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_NCH_CAPACITY   NCH capacity
    *
    * @return                  Returns the NCH/day group
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   24-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_nch_day_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nch_capacity bmng_action.nch_capacity%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointment in the given date
    * - i_date is null and i_id_bed is null -> returns all the future bed appointments
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_bed                        Bed identiifcation
    * @param o_next_sch_dt                   Next schedule date
    * @param o_id_patient                    Patient id of the next schedule    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Ricardo Almeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_next_schedule_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE DEFAULT NULL,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_request_type      'A': All, 'P': Past, 'F': Future, 'D': Specific date
    * @param IN   i_request_date      request date when i_request_type = 'D'
    * @param IN   i_origin_action     ['N': 'NB', 'NT', 'ND'], ['B': 'BT', 'BD']
    *
    * @return  Returns table containing the intervals
    *
    * @author                   Alexandre Santos
    * @version 2.5.0.5
    * @since                    27/07/2009
    ********************************************************************************************/
    FUNCTION tf_get_bmng_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN bmng_action.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_request_date      IN bmng_action.dt_begin_action%TYPE,
        i_origin_action     IN bmng_action.flg_origin_action%TYPE
    ) RETURN t_table_bmng_interval;

    /**********************************************************************************************
    * Returns the needed nch in a given day( nr of the day in the scheduling interval) 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule identifier
    * @param o_id_bed                        Bed identifier    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_schedule_bed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
        
    ) RETURN NUMBER;

    FUNCTION get_schedule_bed_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
        
    ) RETURN NUMBER;

    /********************************************************************************************************************************************
    * get_all_bed_specs_int   Function that returns all clinical services for given bed
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BED                Bed ID
    *
    * @return                     Returns a string with all clinical services concatenated for the given bed
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   30-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_all_bed_specs_int
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * SET_MATCH_BMNG                          upates tables: bmng_allocation_bed and epis_info
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  temporary episode identifier
    * @param i_episode                       definitive episode identifier
    * @param i_patient                       definitive patient identifier
    * @param i_patient_temp                  temporary patient identifier
    * @param i_transaction_id                remote transaction identifier
    * @param o_id_bed                        Bed identifier    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
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

    /********************************************************************************************************************************************
    * GET_BMNG_ACTION           Function that returns the bmng_action and bmng_allocation_bed associated to the given episode.
    *
    * @param  I_LANG                     Language associated to the professional executing the request
    * @param  I_PROF                     Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE               Episode identifier
    * @param  O_BMNG_ACTION              Current bmng action identifier
    * @param  O_BMG_ALLOCATION_BED       Current bmng allocation bed identifier
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
    FUNCTION get_bmng_action
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_bmng_action         OUT bmng_action.id_bmng_action%TYPE,
        o_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed              OUT bmng_allocation_bed.id_bed%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * get_episode_clin_servs   Function that returns the clinical services associated to an episode
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPSIODE        Episode identifier
    *
    * @return                     Returns a string with then clinical service
    *
    * @author  Sofia Mendes
    * @version 2.5.0.7.2
    * @since    16-Nov-2009
    *******************************************************************************************************************************************/
    FUNCTION get_episode_clin_serv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * Checks if the discharge schedule date is null or prior the allocation start date. 
    * If so, consider the allocation end date as the start date plus a configured period of time.
    *
    * @param  I_LANG                Language associated to the professional executing the request
    * @param  I_PROF                Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DT_BEGIN            Allocation start date
    * @param  I_DT_END              Discharge Schedule Date
    * @param  O_DT_END              Allocation end date to be send to the scheduler
    * @param  O_ERROR               If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   01-Jul-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION check_allocation_dates
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end   IN bmng_action.dt_end_action%TYPE,
        o_dt_end   OUT bmng_action.dt_end_action%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * Overload para ser possivel usar em queries
    *
    * @param  I_LANG                Language associated to the professional executing the request
    * @param  I_PROF                Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DT_BEGIN            Allocation start date
    * @param  I_DT_END              Discharge Schedule Date
    * @param  O_DT_END              Allocation end date to be send to the scheduler
    * @param  O_ERROR               If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Telmo 
    * @version 2.6.1.3.1
    * @since   12-10-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION check_allocation_dates
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end   IN bmng_action.dt_end_action%TYPE
    ) RETURN bmng_action.dt_end_action%TYPE;

    /********************************************************************************************************************************************
      * SET_BED_ACTION                      This funciton intends to be an API to the interfaces team to perform the following action over a given bed:
      *                                     - block
      *                                     - unblock
      *                                     - clean
      *                                     - contamine
      *                                     - set as being cleaned
      *                                     - clean concluded  
    *                   - free  
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
    ) RETURN BOOLEAN;

    /* ALERT-306959
    * returns the total amount of beds for the supplied room id.
    * Beds in all manner of status are considered.
    * To be used as a scalar subquery (select clause) in pk_list.get_room_list.
    * That's why it doesn't have o_error or return a boolean.
    *
    * @param  I_ID_ROOM                   Room id. Mandatory
    *
    * @return                             Number
    *
    * @author                  Telmo
    * @version                 2.6.4
    * @since                   04-02-2015
    */
    FUNCTION get_room_beds_qty
    (
        i_id_room IN bed.id_room%TYPE,
        i_prof    IN profissional
    ) RETURN INTEGER;

    /* ALERT-306959
    * returns the number of available beds for the supplied room id.
    * the definition of available bed was extracted from pk_ea_logic_bmng.set_bmng_department_ea.
    * To be used as a scalar subquery (select clause) in pk_list.get_room_list.
    * That's why it doesn't have o_error or return a boolean.
    *
    * @param  I_ID_ROOM                   Room id. Mandatory
    *
    * @return                             Number
    *
    * @author                  Telmo
    * @version                 2.6.4
    * @since                   04-02-2015
    */
    FUNCTION get_room_avail_beds_qty(i_id_room IN bed.id_room%TYPE) RETURN INTEGER;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_bmng_core;
/
