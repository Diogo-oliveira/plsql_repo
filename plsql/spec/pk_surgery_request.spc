/*-- Last Change Revision: $Rev: 2029000 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_surgery_request IS

    FUNCTION get_department
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * 
    *
    * @param i_lang         Id language
    * @param i_prof         professional/institution/software
    * @param o_dcs          cursor with all the disciplines/clinical services associated with the surgery room
    * @param o_error        
    *
    * @return               TRUE/FALSE
    *
    * @author    Pedro Santos
    * @version   2.5.0.2
    * @since     2009/04/21
    * 
    *********************************************************************************************/

    FUNCTION get_dep_clin_serv_ds
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_dept  IN department.id_department%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns all the surgeaons available for a certain speciality or from the surgery room department
    *
    * @param i_lang         Id language
    * @param i_prof         professional/institution/software
    * @param o_surgeons     cursor with all the professionals associated with a certain clinical service
    * @param o_error        
    *
    * @return               TRUE/FALSE
    *
    * @author    Pedro Santos
    * @version   2.5.0.2
    * @since     2009/04/21
    * 
    *********************************************************************************************/
    FUNCTION get_surgeons_by_dep_clin_serv
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_inst     IN institution.id_institution%TYPE,
        i_id_dcs   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_surgeons OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the sum of the average duration for all surgical procedures selected in
    * the Surgery Request screen.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_institution         ID institution/location
    * @param i_id_sr_intervention Array with ID's of the surgical procedures
    * @param o_duration           Sum of average duration of all procedures
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/04/21
    **********************************************************************************************/
    FUNCTION get_sr_expected_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_sr_intervention IN table_number,
        o_duration           OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Returns the available urgency levels in use
    * 
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_list               List of urgency levels
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Fábio Oliveira
    * @version           1.0  
    * @since             2009/04/24
    **********************************************************************************************/
    FUNCTION get_wtl_urg_level_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtl_urg_level_list_ds
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_lvl_urg IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List of all preferred time reasons
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_id_institution         ID institution/location 
    * @param o_list                   list of preferred time reasons from instituition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/04/24
    **********************************************************************************************/
    FUNCTION get_wtl_ptreason_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT NOCOPY pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List of all pre operative sreening decisions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_id_institution         ID institution/location
    * @param o_list                   list of all pos status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/04/24
    **********************************************************************************************/
    FUNCTION get_pos_decision_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT NOCOPY pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pos_decision
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_pos        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns POS decision 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        ID episode
    *
    *  @return                     boolean
    *
    *  @author                     Alexandre Santos
    *  @version                    2.5
    *  @since                      29-04-2009
    *
    *********************************************************************************************/
    FUNCTION get_pos_decision_string
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pos_autorization
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_pos_requested
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_DURATION                    Returns Surgery Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_DURATION               Surgery duration in minutes
    * 
    * @return                         Returns one string with duration in hours
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_duration
    (
        i_lang     IN language.id_language%TYPE,
        i_duration IN schedule_sr.duration%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * CHECK_PROF_PT_MARKET            Returns if one professional is a PT professional 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_PT_PROFESSIONAL        Current professional is a PT professional ('Y' - Yes, 'N' - No)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/30
    *******************************************************************************************************************************************/
    FUNCTION check_prof_pt_market
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_pt_professional OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_BEGIN_END_EPISODE           Get if current episode already begun and if it as already medical and administrative discharge 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_WAITING_LIST        Waiting list id
    * @param I_ID_EPIS_TYPE           Episode correspondent epis_type id
    * @param O_DT_BEGIN_NULL          ('Y' if episode.dt_begin IS NULL) or ('N' if episode.dt_begin IS NOT NULL - Episode is Undergoing)
    * @param O_DISCH_NULL             'Y' if episode has medical and administrative discharge, 'N' otherwise
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/29
    *******************************************************************************************************************************************/
    FUNCTION get_begin_end_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN wtl_epis.id_epis_type%TYPE,
        o_dt_begin_null   OUT VARCHAR2,
        o_disch_null      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_SR_POS_STATUS_STR           Returns Surgery Pre Operative Screening to the first state collumn in Surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_WAITING_LIST        Waiting list Id
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_sr_pos_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN sr_pos_schedule.flg_status%TYPE,
        i_sr_pos_status   IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_schedule_sr  IN schedule_sr.id_schedule_sr%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_EPIS_DONE_STATE             Returns if this episode has already medical and administrative discharge
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_WAITING_LIST        Waiting list id
    * @param I_ID_EPIS_TYPE           EPIS_TYPE id that we want to search
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns if this episode has already medical and administrative discharge
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/05/04
    *******************************************************************************************************************************************/
    FUNCTION get_epis_done_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN epis_type.id_epis_type%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_COMPLETWL_STATUS_STR        Returns status string for admission or cirurgical waiting list episode.
    *                                 (This is complete because it validates if that episode has state "Not needed") 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_WAITING_LIST        Waiting list id
    * @param I_SCH_SR_ADM_NEEDED      Information about if it is necessary exist one admission episode
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_EPIS_TYPE           EPIS_TYPE id that we want to search
    * @param I_WTL_FLG_TYPE           Waiting List flg_type
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_completwl_status_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_WL_STATUS               Returns status string for admission or cirurgical waiting list episode.
    *                             (This is not complete because is not validated if that episode has state "Not needed") 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_WAITING_LIST        Waiting list id
    * @param I_SCH_SR_ADM_NEEDED      Information about if it is necessary exist one admission episode
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_EPIS_TYPE           EPIS_TYPE id that we want to search
    * @param I_WTL_FLG_TYPE           Waiting List flg_type
    * @param O_DATE_BEGIN             Output begin date
    * @param O_AUX                    Auxiliary flag
    * @param O_DISPLAY_TYPE           Output display type
    * @param O_BACK_COLOR             Output back color
    * @param O_STATUS_FLG             Output status flag
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Sofia Mendes (adapted from get_wl_status_str function)
    * @version                        2.5.0.7.3
    * @since                          2009/11/25
    *******************************************************************************************************************************************/
    FUNCTION get_wl_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE,
        o_date_begin        OUT VARCHAR2,
        o_aux               OUT VARCHAR2,
        o_display_type      OUT VARCHAR2,
        o_back_color        OUT VARCHAR2,
        o_status_flg        OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_WL_STATUS_STR               Returns status string for admission or cirurgical waiting list episode.
    *                                 (This is not complete because is not validated if that episode has state "Not needed") 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_status_flg             Flg status
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.0.7.3
    * @since                          2009/11/25
    *******************************************************************************************************************************************/
    FUNCTION get_wl_status_msg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_status_flg IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_WL_STATUS_STR               Returns status string for admission or cirurgical waiting list episode.
    *                                 (This is not complete because is not validated if that episode has state "Not needed") 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_WAITING_LIST        Waiting list id
    * @param I_SCH_SR_ADM_NEEDED      Information about if it is necessary exist one admission episode
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_EPIS_TYPE           EPIS_TYPE id that we want to search
    * @param I_WTL_FLG_TYPE           Waiting List flg_type
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_wl_status_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_WL_STATUS_STR               Returns status string for admission or cirurgical waiting list episode.
    *                                 (This is not complete because is not validated if that episode has state "Not needed") 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_WAITING_LIST        Waiting list id
    * @param I_SCH_SR_ADM_NEEDED      Information about if it is necessary exist one admission episode
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_EPIS_TYPE           EPIS_TYPE id that we want to search
    * @param I_WTL_FLG_TYPE           Waiting List flg_type
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.0.7.3
    * @since                          2009/11/25
    *******************************************************************************************************************************************/
    FUNCTION get_wl_status_flg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        i_sch_sr_adm_needed IN schedule_sr.adm_needed%TYPE,
        i_sr_pos_flg_status IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_wtl_flg_type      IN waiting_list.flg_type%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_WL_STATUS_DATE_DTZ          Returns status string for admission or cirurgical waiting list episode.
    *                                 (This is not complete because is not validated if that episode has state "Not needed") 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)    
    * @param I_ID_EPISODE             Episode id    
    * @param I_ID_WAITING_LIST        Wwaiting List id
    * @param I_STATUS_FLG             Waiting List flg_type
    * 
    * @return                         Returns the Date information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.0.7.3
    * @since                          2009/11/25
    *******************************************************************************************************************************************/
    FUNCTION get_wl_status_date_dtz
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_status_flg      IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /*******************************************************************************************************************************************
    * CHECK_EDIT_PERMISSIONS          Returns if current professional is an anesthesiologist and if he/she can edit an surgery/admission request
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_TYPE_REQUEST           Type of request ('S' - Schedule request; 'A' - Admission request)
    * @param O_IS_ANESTHESIOLOGIST    Returns if logged professional is an anesthesiologist ('Y' - Yes, 'N' - No)
    * @param O_PROF_EDITABLE          Current professional can edit current request ('Y' - Yes, 'N' - No)
    * @param O_PROF_ACCESS_OK         Current professional have OK button active in main GRID ('Y' - Yes, 'N' - No)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/29
    *******************************************************************************************************************************************/
    FUNCTION check_edit_permissions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_type_request        IN VARCHAR2,
        o_is_anesthesiologist OUT VARCHAR2,
        o_prof_editable       OUT VARCHAR2,
        o_prof_access_ok      OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * CHECK_POS_PERMISSIONS          Returns if current professional is an anesthesiologist and if he/she can edit an POS
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_IS_EDIT                Returns if logged professional is an anesthesiologist ('Y' - Yes, 'N' - No)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @version                        1.0
    * @since                          2010/04/19
    *******************************************************************************************************************************************/
    FUNCTION check_pos_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        o_is_edit          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a new surgery request.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_flg_prof_cat       Professional category
    * @param i_id_episode         Episode ID (Current episode)
    * @param i_id_episode_sr      New surgical episode ID  (Context episode)    
    * @param i_id_patient         Patient ID
    * @param i_id_waiting_list    Waiting list ID
    * @param i_sysdate            Current date
    * @param i_professionals      Array of preferred surgeons
    * @param i_external_dcs       Array of external disciplines
    * @param i_dep_clin_serv      Array of specialities
    * @param i_flg_pref_time      Array for preferred time: (M) Morning (A) Afternoon (N) Night (O) Any
    * @param i_reason_pref_time   Array of reasons for preferred time
    * @param i_id_sr_intervention Array of surgical procedures ID
    * @param i_flg_laterality     Array of laterality for each procedure
    * @param i_duration           Expected duration of the surgical procedure
    * @param i_icu                Intensive care unit: (Y) Yes (N) No
    * @param i_notes              Scheduling notes
    * @param i_adm_needed         Admission needed: (Y) Yes (N) No
    * @param i_id_sr_pos_status   POS Decision
    * @param i_supply             Supply ID
    * @param i_supply_set         Parent supply set (if applicable)
    * @param i_supply_qty         Supply quantity
    * @param i_supply_loc         Supply location
    * @param i_dt_return          Estimated date of of return
    * @param i_supply_soft_inst   list
    * @param i_flg_cons_type      flag of consumption type
    * @param i_description_sp     Table varchar with surgical procedures' description
    * @param i_id_sr_epis_interv  Table number with id_sr_epis_interv
    * @param i_id_req_reason      Reasons for each supply
    * @param i_supply_notes       Supply Request notes
    * @param i_diagnosis_surg_proc       Surgical procedure diagnosis information
    * @param i_diagnosis_contam          Contamination danger diagnosis information
    * @param i_id_cdr_call           Rule event identifier.
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/04/21
    **********************************************************************************************/
    FUNCTION set_surgery_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_prof_cat    IN category.flg_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_episode_sr   IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_sysdate         IN TIMESTAMP WITH LOCAL TIME ZONE,
        -- Waiting list
        i_professionals    IN table_number,
        i_external_dcs     IN table_number,
        i_dep_clin_serv    IN table_number, -- (S) Specialty
        i_speciality       IN table_number,
        i_department       IN table_number,
        i_flg_pref_time    IN table_varchar, -- Preferred time
        i_reason_pref_time IN table_number, -- Reason for preferred time
        -- Interventions
        i_id_sr_intervention IN table_number,
        i_flg_type           IN table_varchar DEFAULT NULL,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_surgical_site      IN table_varchar,
        i_sp_notes           IN table_varchar, -- Surgical process notes
        -- Other data
        i_duration         IN schedule_sr.duration%TYPE,
        i_icu              IN schedule_sr.icu%TYPE,
        i_icu_pos          IN schedule_sr.icu_pos%TYPE,
        i_notes            IN schedule_sr.notes%TYPE,
        i_adm_needed       IN schedule_sr.adm_needed%TYPE, --20
        i_id_sr_pos_status IN sr_pos_status.id_sr_pos_status%TYPE, -- POS decision
        i_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE, -- POS decision
        i_dt_pos_suggested IN VARCHAR2, -- POS decision
        i_decision_notes   IN sr_pos_schedule.decision_notes%TYPE,
        i_pos_req_notes    IN sr_pos_schedule.req_notes%TYPE, -- POS decision
        -- Surgical supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number,
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar,
        --
        i_description_sp    IN table_varchar,
        i_id_sr_epis_interv IN table_number,
        i_id_req_reason     IN table_table_number,
        i_supply_notes      IN table_table_varchar,
        i_surgery_record    IN table_number DEFAULT NULL,
        i_prof_team         IN table_number DEFAULT NULL,
        i_tbl_prof          IN table_table_number DEFAULT NULL,
        i_tbl_catg          IN table_table_number DEFAULT NULL,
        i_tbl_status        IN table_table_varchar DEFAULT NULL,
        i_test              IN VARCHAR2 DEFAULT NULL,
        --Diagnosis information
        i_diagnosis_surg_proc IN pk_edis_types.table_in_epis_diagnosis,
        i_diagnosis_contam    IN pk_edis_types.rec_in_epis_diagnosis,
        -- clinical decision rules
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE,
        i_id_ct_io                IN table_table_varchar,
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_table_clob DEFAULT NULL,
        i_id_inst_dest            IN institution.id_institution%TYPE DEFAULT NULL,
        i_global_anesth           IN VARCHAR2 DEFAULT NULL,
        i_local_anesth            IN VARCHAR2 DEFAULT NULL,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get surgery intervention description
    *
    * @param    i_lang                preferred language ID
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_sr_intervention     surgery intervention ID
    *
    * @return   varchar2              surgery intervention description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_sr_interv_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_intervention IN intervention.id_intervention%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Saves surgical procedures for a requested surgery
    *
    * @param i_lang                 Language
    * @param i_episode              Episode ID (external software)
    * @param i_episode_context      Episode ID (ORIS)
    * @param i_sr_intervention      Array with chosen interventions
    * @param i_prof                 professional/institution/software
    * @param i_dt_interv_start      Intervention start date
    * @param i_dt_interv_end        Intervention end date
    * @param i_dt_req               Requeste date
    * @param i_flg_type             Intervention Type
    * @param i_flg_status           Intervention status
    * @param i_flg_surg_request     Surgery Request Flag
    * @param i_flg_add_problem      The surgical procedure's diagnosis should be associated with problems list? 
    * @param i_diag_desc_sp               Desc diagnosis from the diagnosis of the surgical procedures
    * @param o_id_sr_epis_interv    Created record ID    
    * @param o_error                
    *
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/04/29
    *********************************************************************************************/
    FUNCTION set_epis_surg_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_sr_intervention   IN table_number,
        i_codification      IN table_number,
        i_laterality        IN table_varchar,
        i_surgical_site     IN table_varchar,
        i_diagnosis         IN table_number,
        i_prof              IN profissional,
        i_sp_notes          IN table_varchar,
        i_diag_status       IN table_varchar,
        i_spec_notes        IN table_varchar,
        i_diag_notes        IN table_varchar,
        i_dt_interv_start   IN table_varchar DEFAULT NULL,
        i_dt_interv_end     IN table_varchar DEFAULT NULL,
        i_dt_req            IN table_varchar DEFAULT NULL,
        i_flg_type          IN table_varchar DEFAULT NULL,
        i_flg_status        IN table_varchar DEFAULT NULL,
        i_flg_surg_request  IN table_varchar DEFAULT NULL,
        i_flg_add_problem   IN table_varchar,
        i_diag_desc_sp      IN table_varchar, --desc diagnosis from surgical procedure
        o_id_sr_epis_interv OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns specific data about a Surgery Request
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/

    FUNCTION get_surgery_request_ds
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        --SPECIALITY  
        o_surg_date            OUT schedule_sr.dt_target_tstz%TYPE,
        o_surg_spec_id         OUT NUMBER,
        o_surg_spec_desc       OUT VARCHAR2,
        o_surg_speciality      OUT NUMBER,
        o_surg_speciality_desc OUT VARCHAR2,
        o_surg_department      OUT NUMBER,
        o_surg_department_desc OUT VARCHAR2,
        --SURG PREFERENTIAL
        o_surg_pref_id   OUT table_number,
        o_surg_pref_desc OUT table_varchar,
        --SURG PROCEDURE
        o_surg_proc OUT VARCHAR2,
        --EXTERNAL SPECIALITY
        o_surg_spec_ext_id   OUT table_number,
        o_surg_spec_ext_desc OUT table_varchar,
        --DANGER CONTAMINATION
        o_surg_danger_cont OUT VARCHAR2,
        --SURG_PREFERED_TIME
        o_surg_pref_time_id   OUT table_number,
        o_surg_pref_time_desc OUT table_varchar,
        o_surg_pref_time_flg  OUT table_varchar,
        --SURG_PREFERED_TIME_REASON
        o_surg_pref_reason_id   OUT NUMBER,
        o_surg_pref_reason_desc OUT VARCHAR2,
        -- DURATION
        o_surg_duration OUT NUMBER,
        --ICU
        o_surg_icu      OUT VARCHAR2,
        o_surg_desc_icu OUT VARCHAR2,
        --ICU_POS
        o_surg_icu_pos      OUT VARCHAR2,
        o_surg_desc_icu_pos OUT VARCHAR2,
        --NOTES
        o_surg_notes OUT VARCHAR2,
        --SURG NEED
        o_surg_need      OUT VARCHAR2,
        o_surg_need_desc OUT VARCHAR2,
        --SURG INSTITUTION
        o_surg_institution          OUT NUMBER,
        o_surg_institution_desc     OUT VARCHAR2,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        --ANESTHESIA
        o_global_anesth_desc OUT VARCHAR2,
        o_global_anesth_id   OUT VARCHAR2,
        o_local_anesth_desc  OUT VARCHAR2,
        o_local_anesth_id    OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surgery_request
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surg_request_by_oris_epis
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        o_prof_resp                 OUT professional.name%TYPE,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get surgery request description
    *
    * @param i_lang                 Language
    * @param i_prof                 professional/institution/software
    * @param i_id_schedule_sr       Schedule_sr identifier
    *
    * @return                       Returns the surgery request information
    *
    * @author    Vanessa Barsottelli
    * @version   2.6.5
    * @since     22/02/2016
    *********************************************************************************************/
    FUNCTION get_surgery_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_schedule_sr        IN schedule_sr.id_schedule_sr%TYPE,
        i_desc_type             IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION get_surg_proc_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_sr_epis_interv     IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_desc_type             IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION get_in_waiting_list_flg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_wl_flg_status   waiting_list.flg_status%TYPE,
        i_in_waiting_list VARCHAR2,
        i_disch_null      VARCHAR2,
        i_dt_begin_null   VARCHAR2
    ) RETURN VARCHAR2;

    /**************************************************************************
    * GET_WTL_STARTED_STATE           Returns if the waiting_list associated  *
    *                                 episodes are already started            *
    *                                                                         *
    * @param I_LANG                   Language ID for translations            *
    * @param I_ID_WAITING_LIST        Waiting list id                         *
    *                                                                         *
    * @return                         Returns if the waiting_list associated  *
    *                                 episodes are already started            *
    *                                                                         *
    * @raises                         PL/SQL generic error "OTHERS" and       *
    *                                 "wtl_exception"                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/03/05                              *
    **************************************************************************/
    FUNCTION get_wtl_started_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_running_oris_epis(i_id_episode IN schedule_sr.id_episode%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * Saves surgical procedures for a requested surgery
    *
    * @param i_lang                 Language
    * @param i_episode              Episode ID (external software)
    * @param i_episode_context      Episode ID (ORIS)
    * @param i_sr_intervention      Array with chosen interventions
    * @param i_prof                 professional/institution/software
    * @param i_dt_interv_start      Intervention start date
    * @param i_dt_interv_end        Intervention end date
    * @param i_dt_req               Requeste date
    * @param i_flg_type             Intervention Type
    * @param i_flg_status           Intervention status
    * @param i_flg_surg_request     Surgery Request Flag
    * @param i_flg_add_problem      The surgical procedure's diagnosis should be associated with problems list? 
    * @param i_diagnosis_surg_proc  Diagnosis information for the surgical procedure
    * @param i_id_cdr_call          Rule event identifier.
    * @param o_id_sr_epis_interv    Created record ID
    * @param o_error                
    *
    * @author    Sergio Dias
    * @since     2010/09/14
    *********************************************************************************************/
    FUNCTION set_epis_surg_interv_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_episode_context  IN episode.id_episode%TYPE,
        i_sr_intervention  IN table_number,
        i_codification     IN table_number,
        i_laterality       IN table_varchar,
        i_surgical_site    IN table_varchar,
        i_prof             IN profissional,
        i_sp_notes         IN table_varchar,
        i_dt_interv_start  IN table_varchar DEFAULT NULL,
        i_dt_interv_end    IN table_varchar DEFAULT NULL,
        i_dt_req           IN table_varchar DEFAULT NULL,
        i_flg_type         IN table_varchar DEFAULT NULL,
        i_flg_status       IN table_varchar DEFAULT NULL,
        i_flg_surg_request IN table_varchar DEFAULT NULL,
        -- team
        i_surgery_record          IN table_number DEFAULT NULL,
        i_prof_team               IN table_number DEFAULT NULL,
        i_tbl_prof                IN table_table_number DEFAULT NULL,
        i_tbl_catg                IN table_table_number DEFAULT NULL,
        i_tbl_status              IN table_table_varchar DEFAULT NULL,
        i_test                    IN VARCHAR2 DEFAULT NULL,
        i_diagnosis_surg_proc     IN pk_edis_types.rec_in_epis_diagnosis,
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        i_id_not_order_reason     IN not_order_reason.id_not_order_reason%TYPE,
        i_id_ct_io                IN table_table_varchar DEFAULT NULL,
        i_clinical_question       IN table_number DEFAULT NULL,
        i_response                IN table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_clob DEFAULT NULL,
        o_id_sr_epis_interv       OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    Cancel existing interventions that were removed from the current selection.
    * @param i_lang                   ID language
    * @param i_prof                   Profissional id
    * @param i_id_sr_epis_interv      Table number with id_sr_epis_interv has been removed in the current selection
    * @param i_id_episode             ORIS episode ID
    * @param i_sysdate                Timestamp
    *         
    * @param o_error                  Error
    *                                                                        
    * @author                         Filipe Silva                       
    * @version                        2.6.0.4                                     
    * @since                          2010/08/10 
    * @notes                          ONLY USE THIS FUNCTION FOR SURGERY REQUEST
                                      BECAUSE IS POSSIBLE TO REMOVE INTERVENTIONS
                                      FROM THE CURRENT SELECTION                                                                        *
    **************************************************************************/
    FUNCTION cancel_epis_surg_remov_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN table_number,
        i_id_episode        IN episode.id_episode%TYPE,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_SR_EPISODES                 Returns Surgery Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_PATIENT                Patient id that is soposed to retunr information
    * @param I_START_DT               Start date to be consider to filter data
    * @param I_END_DT                 End date to be consider to filter data
    * 
    * @return                         Returns a table function of Ongoing or Future Events of Surgery Request
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          02-Feb-2011
    *******************************************************************************************************************************************/
    FUNCTION get_sr_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_start_dt IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL
    ) RETURN t_tbl_sr_episodes;

    /*******************************************************************************************************************************************
    * Returns Surgery Request episodes for a specific id patient. 
    * 
    * @param  I_LANG                   Language ID for translations
    * @param  I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param  I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param  I_FLG_SCOPE              Scope type
    * @param  I_START_DATE             Start date for temporal filtering
    * @param  I_END_DATE               End date for temporal filtering
    * @param  I_CANCELLED              Indicates whether the records should be returned canceled
    * @param  I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param  I_FLG_REPORT             Flag used to remove formatting
    *
    * @value  I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value  I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value  I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value  I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * 
    * @return                         Returns a table function of Ongoing or Future Events of Surgery Request
    * 
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          08-Nov-2011
    *******************************************************************************************************************************************/
    FUNCTION get_sr_episodes_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH TIME ZONE,
        i_end_date   IN TIMESTAMP WITH TIME ZONE,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2
    ) RETURN t_tbl_sr_episodes;

    /*******************************************************************************************************************************************
    * Returns Surgery Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             Patient id that is supposed to return information
    * @param I_FLG_CONTEXT            Grid information aggregated or not ('A' - Aggregated, 'C' - Categorized)
    * @param O_GRID_PLANNED           Cursor that returns available information for current patient which admissions are planned
    * @param O_GRID_EMERGENT          Cursor that returns available information for current patient which admissions are emergent
    * @param O_IS_ANESTHESIOLOGIST    Returns if logged professional is an anesthesiologist ('Y' - Yes, 'N' - No)
    * @param O_PROF_EDITABLE          Current professional can edit current request ('Y' - Yes, 'N' - No)
    * @param O_PROF_ACCESS_OK         Current professional have OK button active in main GRID ('Y' - Yes, 'N' - No)
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS" and "user_exception"
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          20-May-2011
    *******************************************************************************************************************************************/
    FUNCTION get_surg_req_grid_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_flg_context         IN VARCHAR2,
        o_grid_planned        OUT pk_types.cursor_type,
        o_grid_emergent       OUT pk_types.cursor_type,
        o_is_anesthesiologist OUT VARCHAR2,
        o_prof_editable       OUT VARCHAR2,
        o_prof_access_ok      OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Returns Surgery Request episodes for a specific Scope - for Reports 
    * 
    * @param  I_LANG                   Language ID for translations
    * @param  I_PROF                   Professional vector of information (professional ID, institution ID, software ID)    
    * @param  I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param  I_FLG_SCOPE              Scope type
    * @param  I_START_DATE             Start date for temporal filtering
    * @param  I_END_DATE               End date for temporal filtering
    * @param  I_CANCELLED              Indicates whether the records should be returned canceled
    * @param  I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param  I_FLG_REPORT             Flag used to remove formatting
    * @param  O_GRID                   Cursor that returns available information for current Scope
    * @param  O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value  I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value  I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value  I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value  I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * @value  I_FLG_REPORT             {*} 'Y' Yes {*} 'N' No
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          20-May-2011
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          09-Nov-2011
    *
    * @dependencies                   REPORTS
    *******************************************************************************************************************************************/
    FUNCTION get_surg_req_grid_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get future events desc
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               future events description
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION get_fe_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get list of actions for a specified subject and state.
    * Based on get_actions function.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_subject                Subject
    * @param i_from_state             State     
    * @param i_id_episode_sr          id_episode_sr
    *
    * @return                         Table with actions info
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/15
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_subject       IN action.subject%TYPE,
        i_from_state    IN action.from_state%TYPE,
        i_id_episode_sr IN episode.id_episode%TYPE,
        o_actions       OUT pk_action.p_action_cur,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_anesthesiologist_prof CONSTANT profile_template.id_profile_template%TYPE := 105;
    g_grid_date_format      CONSTANT VARCHAR2(20) := 'DATE_FORMAT_M006';
    g_surgery_type_req      CONSTANT VARCHAR2(20) := 'S';
    g_admission_type_req    CONSTANT VARCHAR2(20) := 'A';
    g_profile_grp_non_clin  CONSTANT VARCHAR2(1) := 'N';
    g_schedule_emergency_ep CONSTANT VARCHAR2(2) := 'SS';

    g_flg_context_aggregated_a  CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_context_categorized_c CONSTANT VARCHAR2(1 CHAR) := 'C';

    --timeline for reports (ALERT-201937)
    g_sr_crit_type_exec_e CONSTANT VARCHAR2(1 CHAR) := 'E'; --executions
    g_sr_crit_type_all_a  CONSTANT VARCHAR2(1 CHAR) := 'A'; --All

END pk_surgery_request;
/
