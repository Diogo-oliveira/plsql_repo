/*-- Last Change Revision: $Rev: 2028752 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_hidrics_ux IS

    -- Author  : LUIS.MAIA
    -- Created : 17-11-2009 08:32:00
    -- Purpose : Compile all UX functions of Input and Outake functionality

    -- Local Variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_error VARCHAR2(2000);

    /*******************************************************************************************************************************************
    * get_hidrics_type_list           Function that returns the list of available hidrics
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_HIDRICS_LIST           Cursor that returns the list of hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Emilia Taborda
    * @version                        0.1
    * @since                          2006/11/21
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_type_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_hidrict_list OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_hidrics_type_list           Function that returns the list of available intervals
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_HIDRICS_INT            Cursor that returns the list of available intervals
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/18
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_interval
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_hidric_int OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        António Neto
    * @since                         17-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_count          Get number of all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a group (dates, hidric type, etc.)
    * @param O_NUM_EPIS_HIDRICS       Returns the number of records for the search criteria
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FILTER                 1 - Hidric Type  2 - Hidric Initial Date/Time  3 - Hidric State  0|NULL - All
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          16-Dec-2010
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_count
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_search           IN VARCHAR2,
        i_filter           IN NUMBER,
        o_num_epis_hidrics OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics                Get all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_SEARCH                 keyword to Search for
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_FILTER                 Filter by a group (dates, hidric type, etc.)
    * @param I_COLUMN_TO_ORDER        Column to be order
    * @param I_ORDER_BY               The way to be order, ascending (ASC) or descendig (DESC)
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param o_group_totals           Cursor that returns the groups totals
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FILTER                 1 - Hidric Type  2 - Hidric Initial Date/Time  3 - Hidric State  0|NULL - All
    * @value I_COLUMN_TO_ORDER        1 - Hidric Type  2 - Hidric Initial Date/Time  3 - Hidric State  4 - Hidric Interval Value  5 - Hidric End Date/Time  6 - Hidric Last Result  
    *                                 NULL - Balance Rank ASC and Hidric Creation Descending and ID Hidric Balance Episode Descending
    * @value I_ORDER_BY               1|NULL - Ascending Order  2 - Descending Order
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Emilia Taborda
    * @version                        0.1
    * @since                          2006/11/21
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/19
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_search          IN VARCHAR2,
        i_filter          IN NUMBER,
        i_column_to_order IN NUMBER,
        i_order_by        IN NUMBER,
        i_start_record    IN NUMBER,
        i_num_records     IN NUMBER,
        o_epis_hid        OUT NOCOPY pk_types.cursor_type,
        o_group_totals    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics                Get all hidrics associated with all episodes in current episode visit (to be compatible with reports)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.0.5.1.4
    * @since                          31-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * GET_EPIS_DT_BEGIN              Simple function to return an episode's start date. 
    *                                Used for validation of the beginning date of an intake/outtake balance.
    *  
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_episode          ID_EPISODE to check
    * @param      o_dt_begin         Date of the start of the provided episode
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN                        TRUE or FALSE
    * 
    * @author                        Luís Maia
    * @version                       2.5.0.7.3
    * @since                         2009/11/18
    ***************************************************************************************************************/
    FUNCTION get_epis_dt_begin
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_dt_begin OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_TASK_PARAMETERS                    Get task parameters needed to fill task edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_epis_hidrics            epis_hidrics ID
    * @param       i_epis_hidrics            Cursor that returns hidrics
    * @param       o_flg_show                  Y- should be shown an error popup
    * @param       o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_msg_template            message/pop-up template
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/19
    ********************************************************************************************/
    FUNCTION get_task_parameters
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_template OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * SET_HIDRICS                     Internal function responsable for registering hidrics requests
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE that should be associated with current request
    * @param I_PATIENT                ID_PATIENT that should be associated with current request
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_DT_INITIAL_STR         Begin date for this request
    * @param I_DT_END_STR             End date for this request
    * @param I_DT_NEXT_BALANCE        Date of next balance
    * @param I_HID_INTERV             ID of interval between hidrics registries
    * @param i_interval_minutes       Interval that was selected when ID_HIDCRICS_INTERVAL = 'Other'
    * @param I_NOTES                  Notes associated with current request
    * @param I_HID_TYPE               ID of current hidric type
    * @param I_UNIT_MEASURE           ID of unit measure associated 
    * @param I_FLG_TYPE               Type of action: N-New; U-Update
    * @param I_FLG_TASK_STATUS        Type of task: D-Draft; F-Final
    * @param I_FLG_RESTRICTED         Fluid restriction: Y - yes, N - No
    * @param I_MAX_INTAKE             Maximum intake
    * @param I_MIN_OUTPUT             Minimum output
    * @param O_ID_EPIS_HIDRICS        Cursor that returns created id_epis_hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_TYPE               {*} 'N' New {*} 'U' Update
    * @value I_FLG_TASK_STATUS        {*} 'D' Draft {*} 'F' Final
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/20
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/21
    *******************************************************************************************************************************************/
    FUNCTION set_hidrics
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_initial_str   IN VARCHAR2,
        i_dt_end_str       IN VARCHAR2,
        i_dt_next_balance  IN VARCHAR2,
        i_hid_interv       IN hidrics_interval.id_hidrics_interval%TYPE,
        i_interval_minutes IN epis_hidrics.interval_minutes%TYPE,
        i_notes            IN epis_hidrics.notes%TYPE,
        i_hid_type         IN hidrics_type.id_hidrics_type%TYPE,
        i_unit_measure     IN epis_hidrics_balance.id_unit_measure%TYPE,
        i_flg_type         IN VARCHAR2,
        i_flg_task_status  IN epis_hidrics.flg_status%TYPE,
        i_flg_restricted   IN epis_hidrics.flg_restricted%TYPE,
        i_max_intake       IN epis_hidrics.max_intake%TYPE,
        i_min_output       IN epis_hidrics.min_output%TYPE,
        o_id_epis_hidrics  OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets ways, locations, fluids ans characterization cursors used to fill multichoice lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hid                  Epis hidrics id
    * @param   i_hid_flg_type              Hidrics flg_type (Administration or Elimination)
    * @param   i_way                       Way id
    * @param   i_body_part                 Body part id
    * @param   i_body_side                 Body side id
    * @param   i_hidrics                   Hidric id
    * @param   i_hidrics_charact           Hidric charateristic id
    * @param   i_flg_bodypart_freetext     Y- the body part was defined by free text. N-otherwise
    * @param   i_old_hidrics               Id hidrics of the registry being edited.
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times              Y - the nr of occurrences has been filled by the user; N - otherwise
    * @param   o_ways                      ways cursor
    * @param   o_locations                 locations cursor
    * @param   o_hidrics                   hidrics cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   21-05-2010
    */
    FUNCTION get_multichoice_lists
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hid              IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_flg_type          IN hidrics.flg_type%TYPE,
        i_way                   IN way.id_way%TYPE DEFAULT NULL,
        i_body_part             IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side             IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics               IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact       IN table_number DEFAULT NULL,
        i_flg_bodypart_freetext IN VARCHAR2,
        i_device                IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics           IN hidrics.id_hidrics%TYPE,
        i_flg_nr_times          IN hidrics.flg_nr_times%TYPE DEFAULT NULL,
        o_ways                  OUT pk_types.cursor_type,
        o_body_parts            OUT pk_types.cursor_type,
        o_body_side             OUT pk_types.cursor_type,
        o_hidrics               OUT pk_types.cursor_type,
        o_hidrics_chars         OUT pk_types.cursor_type,
        o_hidrics_devices       OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_multichoice_lists
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hid              IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_flg_type          IN hidrics.flg_type%TYPE,
        i_way                   IN way.id_way%TYPE DEFAULT NULL,
        i_body_part             IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side             IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics               IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact       IN table_number DEFAULT NULL,
        i_flg_bodypart_freetext IN VARCHAR2,
        i_device                IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics           IN hidrics.id_hidrics%TYPE,
        o_ways                  OUT pk_types.cursor_type,
        o_body_parts            OUT pk_types.cursor_type,
        o_body_side             OUT pk_types.cursor_type,
        o_hidrics               OUT pk_types.cursor_type,
        o_hidrics_chars         OUT pk_types.cursor_type,
        o_hidrics_devices       OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the current episode already has an intake/output task
    * of the same type, in progress.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode ID
    * @param   i_acronym      Type of task being requested
    * @param   o_exists       Exists a task of the same type? (Y) Yes (N) No
    * @param   o_error        Error information
    *
    * @return  TRUE if successful, FALSE otherwise
    *
    * @author  JOSE.BRITO
    * @version 2.6
    * @since   25-05-2010
    */
    FUNCTION check_existing_hidrics_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_acronym    IN hidrics_type.acronym%TYPE,
        o_exists     OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the current episode already has an intake/output task
    * of the same type, in progress.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_hids    Epis_hidrics ids
    * @param   o_exists       Exists a draft task of the same type? (Y) Yes (N) No
    * @param   o_exists_draft Exists a task of the same type? (Y) Yes (N) No
    * @param   o_error        Error information
    *
    * @return  TRUE if successful, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6
    * @since   27-07-2010
    */
    FUNCTION check_exist_hids_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hids    IN table_number,
        o_exists_draft OUT VARCHAR2,
        o_exists       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets epis hidrics proposed list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   o_prop_hidrics              Proposed hidrics cursor
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   26-05-2010
    */
    FUNCTION get_epis_hidrics_prop_lst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_prop_hidrics OUT pk_types.cursor_type,
        o_msg_prop     OUT sys_message.desc_message%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_hidrics_graph_views         Get the hidrics views to be used in the graph
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param O_HIDRICS_VIEWS          Grid columns (one per date)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/06/21
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_graph_views
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_hidrics  IN epis_hidrics.id_epis_hidrics%TYPE,
        o_hidrics_views OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_grid          Get all hidric records associated episode hidrics ID (flowsheet)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_FLG_CONTEXT            Context in which the grid was loaded (null if the grid was loaded through the deepnav):
                                           R - New intake/output record. 
                                           B - End of balance
    * @param O_EPIS_HID_TIME          Grid columns (one per date)
    * @param O_EPIS_HID_PAR           Lines or series of values (one per hidrics)
    * @param O_MSG_TEXT               Warning pop-up text (if applicable)
    * @param O_MSG_TITLE              Warning pop-up title (if applicable)
    * @param o_title                  Flowsheet title description
    * @param o_perf_balance           Y-It is possible to perform a balance. N-Otherwise
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/06/11
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_grid
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_flg_context          IN VARCHAR2,
        o_epis_hid_time        OUT NOCOPY pk_types.cursor_type,
        o_epis_hid_par         OUT NOCOPY pk_types.cursor_type,
        o_msg_text             OUT NOCOPY VARCHAR2,
        o_msg_title            OUT NOCOPY VARCHAR2,
        o_id_balance_next      OUT NOCOPY epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_id_balance_before    OUT NOCOPY epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_min_date             OUT NOCOPY VARCHAR2,
        o_max_date             OUT NOCOPY VARCHAR2,
        o_title                OUT NOCOPY VARCHAR2,
        o_perf_balance         OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_grid          Get all hidric records associated episode hidrics ID (flowsheet)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param i_epis_hidrics_balance   EPIS_HIDRICS balance to load in the grid
    * @param i_flg_direction          I - initial load (actual balance)
    *                                 N-next balance (the next balance is sent on i_epis_hidrics_balance)
    *                                 B-previous balance (the previous balance is sent on i_epis_hidrics_balance)
    * @param O_EPIS_HID_TIME          Grid columns (one per date)
    * @param O_EPIS_HID_PAR           Lines or series of values (one per hidrics)
    * @param O_EPIS_HID_HOUR          Graph scale (in hours)
    * @param o_id_balance_next        next id_epis_hidrics_balance
    * @param o_id_balance_before      previous id_epis_hidrics_balance
    * @param o_title                  Flowsheet title description    
    * @param o_perf_balance           Y-It is possible to perform a balance. N-Otherwise
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_grid
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_epis_hid_time        OUT NOCOPY pk_types.cursor_type,
        o_epis_hid_par         OUT NOCOPY pk_types.cursor_type,
        o_id_balance_next      OUT NOCOPY epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_id_balance_before    OUT NOCOPY epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_min_date             OUT NOCOPY VARCHAR2,
        o_max_date             OUT NOCOPY VARCHAR2,
        o_title                OUT NOCOPY VARCHAR2,
        o_perf_balance         OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics                Get all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_FLG_INTERVAL           Interval type (used in the graph): H - Hour, I - interval
    * @param O_EPIS_HID_TIME          Grid columns (one per date)
    * @param O_EPIS_HID_PAR           Lines or series of values (one per hidrics)
    * @param O_EPIS_HID_HOUR          Graph scale (in hours)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/06/04
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_graph
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_hidrics  IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_interval  IN VARCHAR2,
        o_epis_hid_time OUT pk_types.cursor_type,
        o_epis_hid_par  OUT pk_types.cursor_type,
        o_epis_hid_hour OUT pk_types.cursor_type,
        o_max_scale     OUT NUMBER,
        o_label_ref     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_grid_new_column             Get the header for a new column inserted by the user
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_DT_EXEC                New date
    * @param i_id_epis_hidrics_balance EPIS_HIDRICS balance ID
    * @param O_EPIS_HID_TIME          New column
    * @param O_NEW_INDEX              Index where the date is positioned in the time array
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/06/04
    *******************************************************************************************************************************************/
    FUNCTION get_grid_new_column
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_exec              IN VARCHAR2,
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_epis_hid_time        OUT pk_types.cursor_type,
        o_new_index            OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the messages required for the modal window warning changes to the next balance date.
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_epis_hidrics     Intake/output task ID
    * @param   o_msg_title           Modal window title
    * @param   o_msg_body            Modal window body message
    * @param   o_msg_body_balance_dt Modal window body message with the date for next balance
    * @param   o_error               Error information
    *
    * @return  TRUE if successful, FALSE otherwise
    *
    * @author  JOSE.BRITO
    * @version 2.6
    * @since   31-05-2010
    */
    FUNCTION get_next_balance_message
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        o_msg_title           OUT sys_message.desc_message%TYPE,
        o_msg_body            OUT sys_message.desc_message%TYPE,
        o_msg_body_balance_dt OUT sys_message.desc_message%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add/Update detail information
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_data                      Epis hidrics det data
    * @param   o_epis_hid_det              Epis hidrics det id
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION set_epis_hidrics_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_data         IN CLOB,
        o_epis_hid_det OUT epis_hidrics_det.id_epis_hidrics_det%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add/Update detail information
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_data                      Epis hidrics det data
    * @param   o_epis_hid_det              Epis hidrics det id
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION set_epis_hidrics_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_data         IN table_clob,
        o_epis_hid_det OUT table_number,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_flowsheet_actions           Get all actions for the flowsheet screen
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param O_ACTIONS_CREATE         Actions for the create button
    * @param O_CREATE_CHILDS          Child actions for the 'Fluid type' option in the create button
    * @param O_ACTIONS                Actions for the action button
    * @param O_VIEWS                  Actions for the views button
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/31
    *******************************************************************************************************************************************/
    FUNCTION get_flowsheet_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_hidrics   IN epis_hidrics.id_epis_hidrics%TYPE,
        o_actions_create OUT pk_types.cursor_type,
        o_create_childs  OUT pk_types.cursor_type,
        o_actions        OUT pk_types.cursor_type,
        o_views          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get epis hidric detail data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hid_det              Epis hidrics det id
    * @param   o_epis_hid_det              Epis hidrics detail cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   01-06-2010
    */
    FUNCTION get_epis_hidrics_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hid_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        o_epis_hid_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Closes or recalculates the inputed balance and opens a new one (when applicable)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_flg_chg_bal_dt            Is to change the next balance data? Y - Yes; Otherwise N
    * @param   o_epis_hid_bal              New epis hidrics balance id
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   01-06-2010
    */
    FUNCTION set_balance
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_hidrics   IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_chg_bal_dt IN VARCHAR2,
        o_epis_hid_bal   OUT epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculate and closes the current balance and finish epis_hidrics
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   01-06-2010
    */
    FUNCTION set_finish
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the default unit measure used in intake and output amounts.
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   o_unit_measure        Unit measure data
    * @param   o_error               Error information
    *
    * @return  TRUE if successful, FALSE otherwise
    *
    * @author  JOSE.BRITO
    * @version 2.6
    * @since   02-06-2010
    */
    FUNCTION get_hidrics_um
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_unit_measure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * The purpose of this function is to give to flash the hidrics default values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_dft_values                Cursor with all deft values
    * @param   o_error                     error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   08-06-2010
    */
    FUNCTION get_hidrics_dft_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_dft_values OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * The purpose of this function is to give to flash the default interval and next balance date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_dt_initial_str            Start date
    * @param   o_dft_values                Cursor with all deft values
    * @param   o_error                     error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   08-06-2010
    */
    FUNCTION get_hidrics_dft_creation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_initial_str IN VARCHAR2,
        o_dft_values     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a epis_hidrics registry
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_cancel_reason             Reason for cancellation
    * @param   i_cancel_notes              Cancellation notes
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   10-06-2010
    */
    FUNCTION cancel_epis_hidrics
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_hidrics  IN epis_hidrics.id_epis_hidrics%TYPE,
        i_cancel_reason IN epis_hidrics.id_cancel_reason%TYPE,
        i_cancel_notes  IN epis_hidrics.notes_cancel%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a epis_hidrics_line registry
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics_line         Epis hidrics line id
    * @param   i_cancel_reason             Reason for cancellation
    * @param   i_cancel_notes              Cancellation notes
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   10-06-2010
    */
    FUNCTION cancel_epis_hidrics_line
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_cancel_reason     IN epis_hidrics.id_cancel_reason%TYPE,
        i_cancel_notes      IN epis_hidrics.notes_cancel%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a epis_hidrics_det registry
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics_det          Epis hidrics det id
    * @param   i_cancel_reason             Reason for cancellation
    * @param   i_cancel_notes              Cancellation notes
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   10-06-2010
    */
    FUNCTION cancel_epis_hidrics_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_cancel_reason    IN epis_hidrics_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_hidrics_det.notes_cancel%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets epis hidrics history data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_flg_screen                D- detail screen; H- History screen
    * @param   o_hist                      History cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    FUNCTION get_epis_hidrics_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_screen   IN VARCHAR2,
        o_hist         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets epis hidrics line history data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics_line         Epis hidrics line id
    * @param   i_flg_screen                D- detail screen; H- History screen
    * @param   o_line_hist                 Line History cursor
    * @param   o_execs_hist                Executions History cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    FUNCTION get_epis_hidrics_line_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_flg_screen        IN VARCHAR2,
        o_line_hist         OUT pk_types.cursor_type,
        o_execs_hist        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets epis hidrics result history data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics_det          Epis hidrics det id
    * @param   i_flg_screen                D- detail screen; H- History screen
    * @param   o_hist                      History cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    FUNCTION get_epis_hidrics_res_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_flg_screen       IN VARCHAR2,
        o_hist             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets collector data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics_line         Epis hidrics line id
    * @param   i_dt_execution              Execution date
    * @param   o_collector                 Collector cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   17-06-2010
    */
    FUNCTION get_collector
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_det.id_epis_hidrics_line%TYPE,
        i_dt_execution      IN VARCHAR2,
        o_collector         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets collector data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_hid_way                   Hidrics way id
    * @param   i_hid_way_ft                Hidrics way free text
    * @param   i_bdy_part                  Body part id
    * @param   i_bdy_side                  Body side id
    * @param   i_location_ft               Location free text
    * @param   i_hid                       Hidrics id
    * @param   i_hid_ft                    Hidrics free text
    * @param   i_dt_execution              Execution date
    * @param   o_collector                 Collector cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   17-06-2010
    */
    FUNCTION get_collector
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_way      IN way.id_way%TYPE DEFAULT NULL,
        i_hid_way_ft   IN epis_hidrics_det_ftxt.free_text%TYPE DEFAULT NULL,
        i_bdy_part     IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_bdy_side     IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_location_ft  IN epis_hidrics_det_ftxt.free_text%TYPE DEFAULT NULL,
        i_hid          IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hid_ft       IN epis_hidrics_det_ftxt.free_text%TYPE DEFAULT NULL,
        i_dt_execution IN VARCHAR2,
        o_collector    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets epis hidrics proposed to administered and Closes or recalculates the inputed balance and opens a new one (when applicable)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_prop_hidrics              Table with epis hidrics det id
    * @param   i_prop_hid_dt               Table with dates of execution
    * @param   i_prop_hid_val              Table with values
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_flg_chg_bal_dt            Is to change the next balance data? Y - Yes; Otherwise N
    * @param   o_epis_hid_bal              New epis hidrics balance id
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   29-06-2010
    */
    FUNCTION set_eh_prop_balance
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prop_hidrics   IN table_number,
        i_prop_hid_dt    IN table_varchar,
        i_prop_hid_val   IN table_number,
        i_epis_hidrics   IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_chg_bal_dt IN VARCHAR2,
        o_epis_hid_bal   OUT epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Check if balance hour
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_dt_start                Start date
    * @param       o_msg_title               Title message
    * @param       o_msg_text                Text message
    * @param       o_show_msg                'Y' - show message; Otherwise 'N'
    * @param       o_error                   Current total administrations
    *         
    * @return                                Returns TRUE if success, otherwise returns FALSE
    *
    * @author                                Alexandre Santos
    * @version                               2.6.0.3
    * @since                                 2010/07/02
    ********************************************************************************************/
    FUNCTION check_balance_hour
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_dt_start  IN VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_show_msg  OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_next_balance_date           Calculate the next balance date given a data and an interval (in minutes)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_date                   Date
    * @param i_interval_minutes       Interval: nr of minutes
    * @param o_next_bal_dt            Next balance calculation date
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error     
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          21-Mar-2011
    *******************************************************************************************************************************************/
    FUNCTION get_next_balance_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_date             IN VARCHAR2,
        i_interval_minutes IN hidrics_interval.interval_minutes%TYPE,
        o_next_bal_dt      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Gets the hidrics list and executions to feed the PDMS screen based in a timeline 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_FLG_SCOPE              Flag Type of Scope: P - Patient; E - episode; V - Visit
    * @param I_SCOPE                  Identifier to be filtered: id_patient - i_flg_scope = 'P', id_visit - i_flg_scope = 'V', id_episode - i_flg_scope = 'E'
    * @param I_START_DATE             Start date to be considered
    * @param I_END_DATE               End date to be considered
    * @param O_HIDRICS                Cursor that returns the intake and output requests that have executions (inputs or outputs)
    * @param O_HIDRICS_VALUE          Cursor that returns hidrics detail (the takes of each request)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          07-Jul-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_pdms
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN patient.id_patient%TYPE,
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        o_hidrics       OUT NOCOPY pk_types.cursor_type,
        o_hidrics_value OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /****************************************************************************************************************
    * Returns if it's possible to create/edit/cancel results and perform balance, it also returns the Execution Date
    *
    * @param       I_LANG                    Professional preferred language
    * @param       I_PROF                    Professional identification and its context (institution and software)
    * @param       I_ID_EPIS_HIDRICS         Hidric's Identifier
    * @param       O_FLG_RESULTS_CREATE      Flag gives permission to create/edit/cancel results and perform balance
    * @param       O_DT_EXEC_STR             Execution/Perform Balance Date
    * @param       O_ERROR                   Error information
    *
    * @value       I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value       O_FLG_RESULTS_CREATE     {*} 'Y' Yes {*} 'N' No
    *
    * @return                                true on success, false otherwise
    *
    * @author                                António Neto
    * @version                               2.6.1.5
    * @since                                 08-Nov-2011
    ****************************************************************************************************************/
    FUNCTION get_create_results_permiss
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_results_create OUT VARCHAR2,
        o_dt_exec_max_str    OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Get all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param I_FLG_SCOPE              Scope type
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * @param I_CANCELLED              Indicates whether the records should be returned canceled
    * @param I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param I_FLG_REPORT             Flag used to remove formatting
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_FLG_DRAFT              If it should return draft functions or not
    * @param I_SEARCH                 keyword to Search for
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_FILTER                 Filter by a group (dates, hidric type, etc.)
    * @param I_COLUMN_TO_ORDER        Column to be order
    * @param I_ORDER_BY               The way to be order, ascending (ASC) or descendig (DESC)
    * @param I_ID_EPIS_TYPE           Episode Type identifier
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    *
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * @value I_FLG_REPORT             {*} 'Y' Yes {*} 'N' No
    * @value I_FLG_DRAFT              {*} 'Y' YES {*} 'N' NO
    * @value I_FILTER                 {*} '1' Hidric Type {*} '2' Hidric Initial Date/Time {*} '3' Hidric State {*} '0' All {*} 'NULL' All
    * @value I_COLUMN_TO_ORDER        {*} '1' Hidric Type {*} '2' Hidric Initial Date/Time {*} '3' Hidric State {*} '4' Hidric Interval Value {*} '5' Hidric End Date/Time {*} '6' Hidric Last Result {*} 'NULL' Balance Rank ASC and Hidric Creation Descending and ID Hidric Balance Episode Descending
    * @value I_ORDER_BY               {*} '1' Ascending Order {*} 'NULL' Ascending Order {*} '2' Descending Order
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Emilia Taborda
    * @version                        0.1
    * @since                          2006/11/21
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/19
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          10-Nov-2011
    *
    * @dependencies                   REPORTS
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_flg_scope       IN VARCHAR2,
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_cancelled       IN VARCHAR2,
        i_crit_type       IN VARCHAR2,
        i_flg_report      IN VARCHAR2,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_draft       IN VARCHAR2,
        i_search          IN VARCHAR2,
        i_filter          IN NUMBER,
        i_column_to_order IN NUMBER,
        i_order_by        IN NUMBER,
        o_epis_hid        OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Get hidric detail information with timeframe ans scope
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param I_FLG_SCOPE              Scope type
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * @param I_CANCELLED              Indicates whether the records should be returned canceled
    * @param I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param I_FLG_REPORT             Flag used to remove formatting
    * @param I_EPIS_HIDRICS           Hidrics Episode identifier
    * @param I_ID_EPIS_TYPE           Episode Type identifier
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_EPIS_HID_D             Cursor that returns hidrics detail
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * @value I_FLG_REPORT             {*} 'Y' Yes {*} 'N' No
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          11-Nov-2011
    *
    * @dependencies                   REPORTS
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_det_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_scope        IN NUMBER,
        i_flg_scope    IN VARCHAR2,
        i_start_date   IN VARCHAR2,
        i_end_date     IN VARCHAR2,
        i_cancelled    IN VARCHAR2,
        i_crit_type    IN VARCHAR2,
        i_flg_report   IN VARCHAR2,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_epis_hid_d   OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets ways, locations, fluids ans characterization cursors used to fill multichoice lists for irrigation:
    * input parameter and output parameter
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hid                  Epis hidrics id
    * @param   i_hid_flg_type              Hidrics flg_type (Administration or Elimination)
    * Intake
    * @param   i_way_int                   Way id intake
    * @param   i_body_part_int             Body part id intake
    * @param   i_body_side_int             Body side id intake
    * @param   i_hidrics_int               Hidric id intake
    * @param   i_hidrics_charact_int       Hidric charateristic id intake
    * @param   i_flg_bodypart_ftxt_int     Y- the body part was defined by free text. N-otherwise intake
    * @param   i_old_hidrics_int           Id hidrics of the registry being edited intake
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times_int          Y - the nr of occurrences has been filled by the user; N - otherwise
    * Output
    * @param   i_way_out                   Way id output
    * @param   i_body_part_out             Body part id output
    * @param   i_body_side_out             Body side id output
    * @param   i_hidrics_out               Hidric id output
    * @param   i_hidrics_charact_out       Hidric charateristic id output
    * @param   i_flg_bodypart_ftxt_out     Y- the body part was defined by free text output. N-otherwise intake
    * @param   i_old_hidrics_out           Id hidrics of the registry being edited output
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times_out          Y - the nr of occurrences has been filled by the user; N - otherwise
    *
    * @param   o_ways_int                  ways cursor intake
    * @param   o_body_parts_int            body parts cursor intake
    * @param   o_body_side_int             body parts cursor intake
    * @param   o_hidrics_int               hidrics cursor intake
    * @param   o_hidrics_chars_int         hidrics cursor intake
    * @param   o_hidrics_devices_int       hidrics cursor intake
    *
    * @param   o_ways_out                  ways cursor output 
    * @param   o_body_parts_out            body parts cursor output
    * @param   o_body_side_out             body parts cursor output
    * @param   o_hidrics_out               hidrics cursor output
    * @param   o_hidrics_chars_out         hidrics cursor output
    * @param   o_hidrics_devices_out       hidrics cursor output
    *
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.3.8
    * @since   06-09-2013
    */
    FUNCTION get_lists_irrigations
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hid     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_flg_type IN hidrics.flg_type%TYPE,
        --intake
        i_way_int               IN way.id_way%TYPE DEFAULT NULL,
        i_body_part_int         IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side_int         IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics_int           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact_int   IN table_number DEFAULT NULL,
        i_flg_bodypart_ftxt_int IN VARCHAR2,
        i_device_int            IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics_int       IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        --output
        i_way_out               IN way.id_way%TYPE DEFAULT NULL,
        i_body_part_out         IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side_out         IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics_out           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact_out   IN table_number DEFAULT NULL,
        i_flg_bodypart_ftxt_out IN VARCHAR2,
        i_device_out            IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics_out       IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_flg_nr_times_out      IN hidrics.flg_nr_times%TYPE DEFAULT NULL,
        -- intake
        o_ways          OUT pk_types.cursor_type,
        o_body_parts    OUT pk_types.cursor_type,
        o_body_side     OUT pk_types.cursor_type,
        o_hidrics       OUT pk_types.cursor_type,
        o_hidrics_chars OUT pk_types.cursor_type,
        --output
        o_ways_output            OUT pk_types.cursor_type,
        o_body_parts_output      OUT pk_types.cursor_type,
        o_body_side_output       OUT pk_types.cursor_type,
        o_hidrics_output         OUT pk_types.cursor_type,
        o_hidrics_chars_output   OUT pk_types.cursor_type,
        o_hidrics_devices_output OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets ways, locations, fluids ans characterization cursors used to fill multichoice lists for irrigation:
    * input parameter and output parameter
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hid                  Epis hidrics id
    * @param   i_hid_flg_type              Hidrics flg_type (Administration or Elimination)
    * Intake
    * @param   i_way_int                   Way id intake
    * @param   i_body_part_int             Body part id intake
    * @param   i_body_side_int             Body side id intake
    * @param   i_hidrics_int               Hidric id intake
    * @param   i_hidrics_charact_int       Hidric charateristic id intake
    * @param   i_flg_bodypart_ftxt_int     Y- the body part was defined by free text. N-otherwise intake
    * @param   i_old_hidrics_int           Id hidrics of the registry being edited intake
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times_int          Y - the nr of occurrences has been filled by the user; N - otherwise
    * Output
    * @param   i_way_out                   Way id output
    * @param   i_body_part_out             Body part id output
    * @param   i_body_side_out             Body side id output
    * @param   i_hidrics_out               Hidric id output
    * @param   i_hidrics_charact_out       Hidric charateristic id output
    * @param   i_flg_bodypart_ftxt_out     Y- the body part was defined by free text output. N-otherwise intake
    * @param   i_old_hidrics_out           Id hidrics of the registry being edited output
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times_out          Y - the nr of occurrences has been filled by the user; N - otherwise
    *
    * @param   i_flg_irrigation_block      I-Intake (only the intake content should be calculate); O-Output (only the output content should be calculate)
    *                                      A-All. Null also returns all the intake and output contents
    *
    * @param   o_ways_int                  ways cursor intake
    * @param   o_body_parts_int            body parts cursor intake
    * @param   o_body_side_int             body parts cursor intake
    * @param   o_hidrics_int               hidrics cursor intake
    * @param   o_hidrics_chars_int         hidrics cursor intake
    * @param   o_hidrics_devices_int       hidrics cursor intake
    *
    * @param   o_ways_out                  ways cursor output 
    * @param   o_body_parts_out            body parts cursor output
    * @param   o_body_side_out             body parts cursor output
    * @param   o_hidrics_out               hidrics cursor output
    * @param   o_hidrics_chars_out         hidrics cursor output
    * @param   o_hidrics_devices_out       hidrics cursor output
    *
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.3.8
    * @since   06-09-2013
    */
    FUNCTION get_lists_irrigations
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hid     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_flg_type IN hidrics.flg_type%TYPE,
        --intake
        i_way_int               IN way.id_way%TYPE DEFAULT NULL,
        i_body_part_int         IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side_int         IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics_int           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact_int   IN table_number DEFAULT NULL,
        i_flg_bodypart_ftxt_int IN VARCHAR2,
        i_device_int            IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics_int       IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        --output
        i_way_out               IN way.id_way%TYPE DEFAULT NULL,
        i_body_part_out         IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side_out         IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics_out           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact_out   IN table_number DEFAULT NULL,
        i_flg_bodypart_ftxt_out IN VARCHAR2,
        i_device_out            IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics_out       IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_flg_nr_times_out      IN hidrics.flg_nr_times%TYPE DEFAULT NULL,
        --
        i_flg_irrigation_block IN VARCHAR2 DEFAULT NULL,
        -- intake
        o_ways          OUT pk_types.cursor_type,
        o_body_parts    OUT pk_types.cursor_type,
        o_body_side     OUT pk_types.cursor_type,
        o_hidrics       OUT pk_types.cursor_type,
        o_hidrics_chars OUT pk_types.cursor_type,
        --output
        o_ways_output            OUT pk_types.cursor_type,
        o_body_parts_output      OUT pk_types.cursor_type,
        o_body_side_output       OUT pk_types.cursor_type,
        o_hidrics_output         OUT pk_types.cursor_type,
        o_hidrics_chars_output   OUT pk_types.cursor_type,
        o_hidrics_devices_output OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

END pk_inp_hidrics_ux;
/
