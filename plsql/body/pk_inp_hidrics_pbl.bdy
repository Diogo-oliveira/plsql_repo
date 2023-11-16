/*-- Last Change Revision: $Rev: 2027267 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_hidrics_pbl IS

    -- -- -- -- --
    -- FUNCTIONS
    -- -- -- -- --

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status
    *                        
    * @author                        António Neto
    * @version                       v2.6.0.5
    * @since                         02-Mar-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    ) IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_THERAPEUTIC_STATUS';
        pk_alertlog.log_debug(g_error);
    
        pk_inp_hidrics.get_therapeutic_status(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_request   => i_id_request,
                                              o_description  => o_description,
                                              o_instructions => o_instructions,
                                              o_flg_status   => o_flg_status);
    END;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_HIDRICS_TYPE_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_hidrics_type_list(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    o_hidrict_list => o_hidrict_list,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_hidrics_type_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_HIDRICS_INTERVAL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_hidrics_interval(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   o_hidric_int => o_hidric_int,
                                                   o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_hidrics_interval;

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
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_inp_hidrics.get_num_page_records(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   o_num_records => o_num_records,
                                                   o_error       => o_error);
    END get_num_page_records;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_COUNT';
        pk_alertlog.log_debug(g_error);
        RETURN pk_inp_hidrics.get_epis_hidrics_count(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_episode          => i_episode,
                                                     i_epis_hidrics     => i_epis_hidrics,
                                                     i_flg_draft        => pk_alert_constant.get_no,
                                                     i_search           => i_search,
                                                     i_filter           => i_filter,
                                                     o_num_epis_hidrics => o_num_epis_hidrics,
                                                     o_error            => o_error);
    END get_epis_hidrics_count;

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
        i_start_record    IN NUMBER,
        i_num_records     IN NUMBER,
        i_filter          IN NUMBER,
        i_column_to_order IN NUMBER,
        i_order_by        IN NUMBER,
        o_epis_hid        OUT NOCOPY pk_types.cursor_type,
        o_group_totals    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS';
        pk_alertlog.log_debug(g_error);
    
        IF (i_episode IS NULL)
        THEN
            RETURN pk_inp_hidrics.get_epis_hidrics(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_episode         => i_episode,
                                                   i_epis_hidrics    => i_epis_hidrics,
                                                   i_flg_draft       => pk_alert_constant.get_no,
                                                   i_search          => i_search,
                                                   i_start_record    => i_start_record,
                                                   i_num_records     => i_num_records,
                                                   i_filter          => i_filter,
                                                   i_column_to_order => i_column_to_order,
                                                   i_order_by        => i_order_by,
                                                   o_epis_hid        => o_epis_hid,
                                                   o_error           => o_error);
        
        ELSE
            RETURN pk_inp_hidrics.get_epis_hidrics_with_totals(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_episode         => i_episode,
                                                               i_epis_hidrics    => i_epis_hidrics,
                                                               i_flg_draft       => pk_alert_constant.get_no,
                                                               i_search          => i_search,
                                                               i_start_record    => i_start_record,
                                                               i_num_records     => i_num_records,
                                                               i_filter          => i_filter,
                                                               i_column_to_order => i_column_to_order,
                                                               i_order_by        => i_order_by,
                                                               o_epis_hid        => o_epis_hid,
                                                               o_group_totals    => o_group_totals,
                                                               o_error           => o_error);
        END IF;
    END get_epis_hidrics;

    /*******************************************************************************************************************************************
    * create_epis_hidrics_det         Get hidric detail information
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           ID_EPIS_HIDRICS identifier
    * @param I_EPISODE                ID_EPISODE identifier
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_EPIS_HID_B             Cursor that returns hidrics
    * @param O_EPIS_HID_D             Cursor that returns hidrics detail
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
    FUNCTION get_epis_hidrics_reports
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_epis_hid_d   OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.get_epis_hidrics_reports';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics_reports(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_epis_hidrics => i_epis_hidrics,
                                                       i_episode      => i_episode,
                                                       o_epis_hid     => o_epis_hid,
                                                       o_epis_hid_d   => o_epis_hid_d,
                                                       o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_epis_hidrics_reports;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_reports         Get hidric detail information.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           ID_EPIS_HIDRICS identifier    
    * @param   i_flg_scope            Scope: P -patient; E- episode; V-visit
    * @param   i_scope                id_patient if i_flg_scope = 'P'
    *                                 id_visit if i_flg_scope = 'V'
    *                                 id_episode if i_flg_scope = 'E'
    * @param   i_flg_report_type      Report type: C-complete; D-detailed    
    * @param   i_start_date           Start date to be considered
    * @param   i_end_date             End date to be considered   
    * @param   i_show_balances        Y-The balances info (o_epis_hid_b cursor) is returned. N-otherwise.
    * @param O_EPIS_HID               Cursor that returns the intake and output requets  
    * @param O_EPIS_HID_D             Cursor that returns hidrics detail (the takes of each request)
    * @param O_EPIS_HID_B             Cursor that returns hidrics balances
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          12-Jan-2011
    *
    * @dependencies: REPORTS, PDMS
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_reports
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_scope       IN VARCHAR2, -- P -patient; E- episode; V-visit        
        i_scope           IN patient.id_patient%TYPE,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_show_balances   IN VARCHAR2,
        o_epis_hid        OUT pk_types.cursor_type,
        o_epis_hid_d      OUT pk_types.cursor_type,
        o_epis_hid_b      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.get_epis_hidrics_reports';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics_reports(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_epis_hidrics    => i_epis_hidrics,
                                                       i_flg_scope       => i_flg_scope,
                                                       i_scope           => i_scope,
                                                       i_flg_report_type => i_flg_report_type,
                                                       i_start_date      => i_start_date,
                                                       i_end_date        => i_end_date,
                                                       i_show_balances   => i_show_balances,
                                                       o_epis_hid        => o_epis_hid,
                                                       o_epis_hid_d      => o_epis_hid_d,
                                                       o_epis_hid_b      => o_epis_hid_b,
                                                       o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_epis_hidrics_reports;

    /********************************************************************************************
      * return the sum off all hidrics values (administration and elimination) for a determinate
      * interval date.
      *
      * @param i_lang        Id language
      * @param i_episode     ID episode
    * @param i_prof        Id professional
      
      * @param o_hidrics     cursor with the sum hidrics values (administration and elimination)
      *                      and result of (administration minus elimination)
      * @param o_error       error
      *
      *
      * @author                         Luís Maia
      * @version                        2.5.0.7.3
      * @since                          2009/11/18
         ********************************************************************************************/
    FUNCTION get_last_hidrics_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_hidrics OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_LAST_HIDRICS_REPORT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_last_hidrics_report(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_episode => i_episode,
                                                      o_hidrics => o_hidrics,
                                                      o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_last_hidrics_report;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_DT_BEGIN';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_dt_begin(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_episode  => i_episode,
                                                o_dt_begin => o_dt_begin,
                                                o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END;

    /*******************************************************************************************************************************************
    * create_epis_hidrics             Internal function responsable for registering hidrics requests
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE that should be associated with current request
    * @param I_DT_INITIAL_STR         Begin date for this request
    * @param I_DT_END_STR             End date for this request
    * @param I_HID_INTERV             ID of interval between hidrics registries
    * @param I_NOTES                  Notes associated with current request
    * @param I_HID_TYPE               ID of current hidric type
    * @param I_UNIT_MEASURE           ID of unit measure associated 
    * @param I_FLG_TYPE               Type of action: N-New; U-Update
    * @param I_FLG_TASK_STATUS        Type of task: D-Draft; F-Final
    * @param O_ID_EPIS_HIDRICS        Cursor that returns created id_epis_hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_TYPE               {*} 'N' New {*} 'U' Update
    * @value I_FLG_TASK_STATUS        {*} 'D' Draft {*} 'F' Final
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/16
    *******************************************************************************************************************************************/
    FUNCTION create_epis_hidrics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_dt_initial_str  IN VARCHAR2,
        i_dt_end_str      IN VARCHAR2,
        i_hid_interv      IN hidrics_interval.id_hidrics_interval%TYPE,
        i_notes           IN epis_hidrics.notes%TYPE,
        i_hid_type        IN hidrics_type.id_hidrics_type%TYPE,
        i_unit_measure    IN epis_hidrics_balance.id_unit_measure%TYPE,
        i_flg_type        IN VARCHAR2,
        i_flg_task_status IN epis_hidrics.flg_status%TYPE,
        o_id_epis_hidrics OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.CREATE_EPIS_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.create_epis_hidrics(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_dt_initial_str  => i_dt_initial_str,
                                                  i_dt_end_str      => i_dt_end_str,
                                                  i_hid_interv      => i_hid_interv,
                                                  i_notes           => i_notes,
                                                  i_hid_type        => i_hid_type,
                                                  i_unit_measure    => i_unit_measure,
                                                  i_flg_type        => i_flg_type,
                                                  i_flg_task_status => i_flg_task_status,
                                                  o_id_epis_hidrics => o_id_epis_hidrics,
                                                  o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END create_epis_hidrics;

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
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_TYPE               {*} 'N' New {*} 'U' Update
    * @value I_FLG_TASK_STATUS        {*} 'D' Draft {*} 'F' Final
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.SET_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.set_hidrics(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_episode          => i_episode,
                                          i_patient          => i_patient,
                                          i_epis_hidrics     => i_epis_hidrics,
                                          i_dt_initial_str   => i_dt_initial_str,
                                          i_dt_end_str       => i_dt_end_str,
                                          i_dt_next_balance  => i_dt_next_balance,
                                          i_hid_interv       => i_hid_interv,
                                          i_interval_minutes => i_interval_minutes,
                                          i_notes            => i_notes,
                                          i_hid_type         => i_hid_type,
                                          i_unit_measure     => i_unit_measure,
                                          i_flg_type         => i_flg_type,
                                          i_flg_task_status  => i_flg_task_status,
                                          i_flg_restricted   => i_flg_restricted,
                                          i_max_intake       => i_max_intake,
                                          i_min_output       => i_min_output,
                                          o_id_epis_hidrics  => o_id_epis_hidrics,
                                          o_flg_show         => o_flg_show,
                                          o_msg_title        => o_msg_title,
                                          o_msg              => o_msg,
                                          o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END set_hidrics;

    /**********************************************************************************************
    * SET_EPIS_HID_STATUS                    This function change Intake and Output status from:
    *                                             * Required to Interrupted
    *                                             * In execution to Interrupted
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_epis_hidrics                  epis_hidrics ID
    * @param i_epis_hid_bal                  epis_hidrics_balance ID
    * @param i_flg_status                    FLG_STATUS of this registry 
    * @param i_notes                         notes
    * @param I_FLG_TASK_STATUS               Type of task: D-Draft; F-Final
    * @param o_msg_error                     Message of error to display to user                         
    * @param o_error                         Error object
    *
    * @value I_FLG_TASK_STATUS               {*} 'C' Cancel {*} 'I' Interrupt
    * @value I_FLG_TASK_STATUS               {*} 'D' Draft {*} 'F' Final
    *
    * @return                                Success / fail
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/17
    **********************************************************************************************/
    FUNCTION set_epis_hid_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_status      IN epis_hidrics.flg_status%TYPE,
        i_notes           IN epis_hidrics.notes%TYPE,
        i_flg_task_status IN epis_hidrics.flg_status%TYPE,
        o_msg_error       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --
        g_error := 'CALL PK_INP_HIDRICS.SET_EPIS_HID_STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.set_epis_hid_status(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_epis_hidrics    => i_epis_hidrics,
                                                  i_flg_status      => i_flg_status,
                                                  i_notes           => i_notes,
                                                  i_flg_task_status => i_flg_task_status,
                                                  o_msg_error       => o_msg_error,
                                                  o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END;

    /**********************************************************************************************
    * SET_MATCH_HIDRICS                      This function make "match" of Intake and Output tasks between episodes
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/17
    **********************************************************************************************/
    FUNCTION set_match_hidrics
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.SET_MATCH_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.set_match_hidrics(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode_temp => i_episode_temp,
                                                i_episode      => i_episode,
                                                i_patient      => i_patient,
                                                i_patient_temp => i_patient_temp,
                                                o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END set_match_hidrics;

    /********************************************************************************************
    * get all tasks information to show in CPOE grid
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    * @param       i_episode                 episode id
    * @param       i_task_request            array of task requests (if null, return all tasks as usual)
    * @param       i_filter_tstz             Date to filter only the records with "end dates" > i_filter_tstz
    * @param       i_filter_status           Array with task status to consider along with i_filter_tstz
    * @param       i_flg_report              Required in all get_task_list APIs
    * @param       o_grid                    cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/18
    ********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_grid          OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_TASK_LIST';
        IF NOT pk_inp_hidrics.get_task_list(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_patient       => i_patient,
                                            i_episode       => i_episode,
                                            i_task_request  => i_task_request,
                                            i_filter_tstz   => i_filter_tstz,
                                            i_filter_status => i_filter_status,
                                            i_flg_report    => i_flg_report,
                                            i_dt_begin      => i_dt_begin,
                                            i_dt_end        => i_dt_end,
                                            o_plan_list     => o_plan_list,
                                            o_grid          => o_grid,
                                            o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_task_list;

    /********************************************************************************************
    * GET_TASK_ACTIONS                       get available actions for a requested task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_request            task request id (also used for drafts)
    * @param       o_actions_list            list of available actions for the task request
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/19
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_actions_list OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_TASK_ACTIONS';
        IF NOT pk_inp_hidrics.get_task_actions(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               i_epis_hidrics => i_task_request,
                                               o_actions_list => o_actions_list,
                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_task_actions;

    /********************************************************************************************
    * GET_TASK_PARAMETERS                    Get task parameters needed to fill task edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_epis_hidrics            epis_hidrics ID
    * @param       i_epis_hidrics            Cursor that returns hidrics
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
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
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_records PLS_INTEGER;
    BEGIN
        IF (i_epis_hidrics IS NOT NULL)
        THEN
            g_error := 'check_show_conflict_pop for id_epis_hidrics: ' || i_epis_hidrics;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => 'GET_TASK_PARAMETERS');
            IF NOT pk_inp_hidrics.check_show_conflict_pop(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_epis_hidrics        => i_epis_hidrics,
                                                          i_epis_hidrics_status => NULL,
                                                          o_flg_show            => o_flg_show,
                                                          o_msg_title           => o_msg_title,
                                                          o_msg                 => o_msg,
                                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF (o_flg_show = pk_alert_constant.get_yes)
            THEN
                pk_types.open_my_cursor(o_epis_hid);
                RETURN TRUE;
            END IF;
        END IF;
    
        g_error := 'CALL TO GET_NUM_PAGE_RECORDS';
        IF NOT
            get_num_page_records(i_lang => i_lang, i_prof => i_prof, o_num_records => l_num_records, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_episode         => i_episode,
                                               i_epis_hidrics    => i_epis_hidrics,
                                               i_flg_draft       => pk_alert_constant.g_yes,
                                               i_search          => NULL,
                                               i_start_record    => pk_inp_hidrics_constant.g_init_record,
                                               i_num_records     => l_num_records,
                                               i_filter          => NULL,
                                               i_column_to_order => NULL,
                                               i_order_by        => NULL,
                                               o_epis_hid        => o_epis_hid,
                                               o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_task_parameters;

    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators
    * @param       o_msg_template            array of message/pop-up templates
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_body                array of message bodies
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_msg_template            {*} ' WARNING_READ' Warning Read
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
    * @return                                True on success, false otherwise
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/25
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT NOCOPY table_varchar,
        o_msg_template OUT NOCOPY table_varchar,
        o_msg_title    OUT NOCOPY table_varchar,
        o_msg_body     OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.CHECK_DRAFTS_CONFLICTS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.check_drafts_conflicts(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_draft        => i_draft,
                                                     o_flg_conflict => o_flg_conflict,
                                                     o_msg_template => o_msg_template,
                                                     o_msg_title    => o_msg_title,
                                                     o_msg_body     => o_msg_body,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END check_drafts_conflicts;

    /*******************************************************************************************************************************************
    * create_draft_task               Internal function responsable for registering hidrics requests
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE that should be associated with current request
    * @param I_DT_INITIAL_STR         Begin date for this request
    * @param I_DT_END_STR             End date for this request
    * @param I_HID_INTERV             ID of interval between hidrics registries
    * @param I_NOTES                  Notes associated with current request
    * @param I_HID_TYPE               ID of current hidric type
    * @param I_UNIT_MEASURE           ID of unit measure associated 
    * @param I_FLG_TYPE               Type of action: N-New; U-Update
    * @param O_DRAFT                  Table Number with created id_epis_hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_TYPE               {*} 'N' New {*} 'U' Update
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/16
    *******************************************************************************************************************************************/
    FUNCTION create_draft
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_hid_interv     IN hidrics_interval.id_hidrics_interval%TYPE,
        i_notes          IN epis_hidrics.notes%TYPE,
        i_hid_type       IN hidrics_type.id_hidrics_type%TYPE,
        i_unit_measure   IN epis_hidrics_balance.id_unit_measure%TYPE,
        i_flg_type       IN VARCHAR2,
        o_draft          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_hidrics epis_hidrics.id_epis_hidrics%TYPE;
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.CREATE_EPIS_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.create_epis_hidrics(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_dt_initial_str  => i_dt_initial_str,
                                                  i_dt_end_str      => i_dt_end_str,
                                                  i_hid_interv      => i_hid_interv,
                                                  i_notes           => i_notes,
                                                  i_hid_type        => i_hid_type,
                                                  i_unit_measure    => i_unit_measure,
                                                  i_flg_type        => i_flg_type,
                                                  i_flg_task_status => pk_inp_hidrics_constant.g_flg_task_status_d,
                                                  o_id_epis_hidrics => l_id_epis_hidrics,
                                                  o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_draft := table_number(l_id_epis_hidrics);
        --
        RETURN TRUE;
    END create_draft;

    /********************************************************************************************
    * cancel_draft_task                      Function responsable for cancel one hidric draft task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_draft                   list of draft ids
    * @param       o_flg_show                  Y- should be shown an error popup
    * @param       o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    * 
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/19
    ********************************************************************************************/
    FUNCTION cancel_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_draft     IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cancelled_drafts table_number := table_number();
    
    BEGIN
        --
        g_error := 'CALL PK_INP_HIDRICS.CANCEL_HIDRIC_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.cancel_hidric_list(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_episode          => i_episode,
                                                 i_epis_hid_list    => i_draft,
                                                 o_cancelled_drafts => l_cancelled_drafts,
                                                 o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_inp_hidrics.get_epis_hidrics_descs';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics_descs(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_epis_hidrics => l_cancelled_drafts,
                                                     i_code_msg     => 'INP_HIDRICS_M003',
                                                     o_flg_show     => o_flg_show,
                                                     o_msg_title    => o_msg_title,
                                                     o_msg          => o_msg,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    END cancel_draft;

    /********************************************************************************************
    * activates a set of draft tasks (task goes from draft to active workflow)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_draft                   array of selected drafts 
    * @param       i_flg_commit              transaction control
    * @param       o_created_tasks        array of created taksk requests    
    * @param       o_error                   error message
    *
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction
    *                                        {*} 'N' transaction control is done outside
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/23
    ********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.SET_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.activate_drafts(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_epis_hidrics  => i_draft,
                                              o_created_tasks => o_created_tasks,
                                              o_error         => o_error)
        THEN
            -- IF necessary rollback's operation
            IF i_flg_commit = pk_alert_constant.g_yes
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        END IF;
    
        -- IF necessary commit's operation
        IF i_flg_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
        --
    
        --
        RETURN TRUE;
    END activate_drafts;

    /********************************************************************************************
    * copy task to draft (from an existing active/inactive task)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id (current episode)
    * @param       i_task_request            task request id (used for active/inactive tasks)
    * @param       o_draft                   draft id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/23
    ********************************************************************************************/
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.COPY_TO_DRAFT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.copy_to_draft(i_lang                 => i_lang,
                                            i_prof                 => i_prof,
                                            i_episode              => i_episode,
                                            i_epis_hidrics         => i_task_request,
                                            i_task_start_timestamp => i_task_start_timestamp,
                                            i_task_end_timestamp   => i_task_end_timestamp,
                                            o_id_epis_hidrics      => o_draft,
                                            o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    END copy_to_draft;

    /***************************************************************************************************************
    * GET_HIDRICS_REG              Returng the grid_task hidrics_reg associated to a visit
    *  
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_id_visit         Visit identifier   
    *
    *
    * @RETURN  grid_task.hidrics_reg%TYPE
    * 
    * @author  Sofia Mendes
    * @version 2.5.0.7.7
    * @since   18-02-2010
    ****************************************************************************************************/
    FUNCTION get_hidrics_reg
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_visit IN visit.id_visit%TYPE
    ) RETURN grid_task.hidrics_reg%TYPE IS
    BEGIN
        g_error := 'CALL TO pk_inp_hidrics.get_hidrics_reg';
        pk_alertlog.log_debug(g_error);
        RETURN pk_inp_hidrics.get_hidrics_reg(i_lang => i_lang, i_prof => i_prof, i_id_visit => i_id_visit);
    
    END get_hidrics_reg;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_inp_hidrics.get_flowsheet_actions(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => i_episode,
                                                    i_epis_hidrics   => i_epis_hidrics,
                                                    o_actions_create => o_actions_create,
                                                    o_create_childs  => o_create_childs,
                                                    o_actions        => o_actions,
                                                    o_views          => o_views,
                                                    o_error          => o_error);
    
    END get_flowsheet_actions;

    /*******************************************************************************************************************************************
    * get_hidrics_total_balance  Get the total amount registered in the balance
    * 
    * @param I_LANG              Language ID for translations
    * @param I_PROF              Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS      Episode hidrics ID
    * @param I_HIDRICS_BALANCE   Balance ID
    * @param I_HIDRICS           Hidrics ID
    * @param I_HIDRICS_TYPE      Hidrics type ID
    * @param I_EPIS_HIDR_LINE    Hidrics line ID
    * @param I_DRUG_PRESC_DET    IV fluid prescription ID
    * @param I_DT_REG            Record date
    * @param I_FLG_REG_TYPE      Record type when counting total values: N - regular values, T - balance values
    * @param I_FLG_REAL_VALUE    Returns real value: Y - Yes, N - No
    * 
    * @return                         Formatted value
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_total_balance
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_hidrics         IN hidrics.id_hidrics%TYPE,
        i_hidrics_type    IN hidrics.flg_type%TYPE,
        i_epis_hidr_line  IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_drug_presc_det  IN pk_api_pfh_in.r_presc.id_presc%TYPE,
        i_dt_reg          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_reg_type    IN VARCHAR2,
        i_flg_real_value  IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_inp_hidrics.get_hidrics_total_balance(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_epis_hidrics       => i_epis_hidrics,
                                                        i_hidrics_balance    => i_hidrics_balance,
                                                        i_hidrics            => i_hidrics,
                                                        i_hidrics_type       => i_hidrics_type,
                                                        i_epis_hidr_line     => i_epis_hidr_line,
                                                        i_drug_presc_det     => i_drug_presc_det,
                                                        i_dt_reg             => i_dt_reg,
                                                        i_flg_reg_type       => i_flg_reg_type,
                                                        i_flg_real_value     => i_flg_real_value,
                                                        i_epis_hidrics_group => NULL,
                                                        i_dt_init_balance    => NULL);
    
    END get_hidrics_total_balance;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.get_hidrics_graph_views';
        IF NOT pk_inp_hidrics.get_hidrics_graph_views(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_episode       => i_episode,
                                                      i_epis_hidrics  => i_epis_hidrics,
                                                      o_hidrics_views => o_hidrics_views,
                                                      o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_hidrics_graph_views;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_grid          Get all hidric records associated episode hidrics ID (flowsheet)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param i_epis_hidrics_balance   EPIS_HIDRICS balance to load in the grid
    * @param I_FLG_CONTEXT            Context in which the grid was loaded (null if the grid was loaded through the deepnav):
                                           R - New intake/output record. 
                                           B - End of balance
    * @param O_EPIS_HID_TIME          Grid columns (one per date)
    * @param O_EPIS_HID_PAR           Lines or series of values (one per hidrics)
    * @param O_MSG_TEXT               Warning pop-up text (if applicable)
    * @param O_MSG_TITLE              Warning pop-up title (if applicable)
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
    * @since                          2010/06/11
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_grid
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_flg_context          IN VARCHAR2 DEFAULT NULL,
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
    ) RETURN BOOLEAN IS
    
        l_epis_hid_hour pk_types.cursor_type;
        l_max_scale     NUMBER;
        l_label_ref     VARCHAR2(50);
    
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_GRID';
        IF NOT pk_inp_hidrics.get_epis_hidrics_grid(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_episode              => i_episode,
                                                    i_epis_hidrics         => i_epis_hidrics,
                                                    i_epis_hidrics_balance => i_epis_hidrics_balance,
                                                    i_flg_grid_type        => pk_inp_hidrics_constant.g_grid_type_f,
                                                    i_flg_context          => i_flg_context,
                                                    o_epis_hid_time        => o_epis_hid_time,
                                                    o_epis_hid_par         => o_epis_hid_par,
                                                    o_epis_hid_hour        => l_epis_hid_hour,
                                                    o_max_scale            => l_max_scale,
                                                    o_label_ref            => l_label_ref,
                                                    o_msg_text             => o_msg_text,
                                                    o_msg_title            => o_msg_title,
                                                    o_id_balance_next      => o_id_balance_next,
                                                    o_id_balance_before    => o_id_balance_before,
                                                    o_min_date             => o_min_date,
                                                    o_max_date             => o_max_date,
                                                    o_title                => o_title,
                                                    o_perf_balance         => o_perf_balance,
                                                    o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    END get_epis_hidrics_grid;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_grid          Get all hidric records associated episode hidrics ID (flowsheet)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param i_epis_hidrics_balance   EPIS_HIDRICS balance to load in the grid
    * @param O_EPIS_HID_TIME          Grid columns (one per date)
    * @param O_EPIS_HID_PAR           Lines or series of values (one per hidrics)
    * @param O_EPIS_HID_HOUR          Graph scale (in hours)
    * @param o_id_balance_next        next id_epis_hidrics_balance
    * @param o_id_balance_before      previous id_epis_hidrics_balance
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
    ) RETURN BOOLEAN IS
    
        l_epis_hid_hour pk_types.cursor_type;
        l_msg_title     sys_message.desc_message%TYPE;
        l_msg_text      sys_message.desc_message%TYPE;
        l_max_scale     NUMBER;
        l_label_ref     VARCHAR2(50);
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    
        l_internal_error EXCEPTION;
    
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_GRID';
        IF NOT pk_inp_hidrics.get_epis_hidrics_grid(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_episode              => i_episode,
                                                    i_epis_hidrics         => i_epis_hidrics,
                                                    i_flg_grid_type        => pk_inp_hidrics_constant.g_grid_type_f,
                                                    i_epis_hidrics_balance => i_epis_hidrics_balance,
                                                    o_epis_hid_time        => o_epis_hid_time,
                                                    o_epis_hid_par         => o_epis_hid_par,
                                                    o_epis_hid_hour        => l_epis_hid_hour,
                                                    o_max_scale            => l_max_scale,
                                                    o_label_ref            => l_label_ref,
                                                    o_msg_title            => l_msg_title,
                                                    o_msg_text             => l_msg_text,
                                                    o_id_balance_next      => o_id_balance_next,
                                                    o_id_balance_before    => o_id_balance_before,
                                                    o_min_date             => o_min_date,
                                                    o_max_date             => o_max_date,
                                                    o_title                => o_title,
                                                    o_perf_balance         => o_perf_balance,
                                                    o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_epis_hidrics_grid;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_graph          Get all hidric records associated episode hidrics ID (graph)
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
    ) RETURN BOOLEAN IS
    
        l_msg_title sys_message.desc_message%TYPE;
        l_msg_text  sys_message.desc_message%TYPE;
    
        l_id_balance_next   epis_hidrics_balance.id_epis_hidrics_balance%TYPE;
        l_id_balance_before epis_hidrics_balance.id_epis_hidrics_balance%TYPE;
        l_min_date          pk_translation.t_desc_translation;
        l_max_date          pk_translation.t_desc_translation;
        l_title             pk_translation.t_desc_translation;
        l_perf_balance      VARCHAR2(1char);
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_GRID';
        IF NOT pk_inp_hidrics.get_epis_hidrics_grid(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_episode              => i_episode,
                                                    i_epis_hidrics         => i_epis_hidrics,
                                                    i_flg_grid_type        => pk_inp_hidrics_constant.g_grid_type_g,
                                                    i_flg_interval         => i_flg_interval,
                                                    i_epis_hidrics_balance => NULL,
                                                    o_epis_hid_time        => o_epis_hid_time,
                                                    o_epis_hid_par         => o_epis_hid_par,
                                                    o_epis_hid_hour        => o_epis_hid_hour,
                                                    o_max_scale            => o_max_scale,
                                                    o_label_ref            => o_label_ref,
                                                    o_msg_title            => l_msg_title,
                                                    o_msg_text             => l_msg_text,
                                                    o_id_balance_next      => l_id_balance_next,
                                                    o_id_balance_before    => l_id_balance_before,
                                                    o_min_date             => l_min_date,
                                                    o_max_date             => l_max_date,
                                                    o_title                => l_title,
                                                    o_perf_balance         => l_perf_balance,
                                                    o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_epis_hidrics_graph;

    /********************************************************************************************
    * GET_ONGOING_TASKS_HIDRIC               Get all tasks available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return       tf_tasks_list            table of tr_tasks_list
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/Jun/07
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_hidric
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    BEGIN
        g_error := 'CALL PK_INP_POSITIONING.GET_ONGOING_TASKS_POSIT';
        RETURN pk_inp_hidrics.get_ongoing_tasks_hidric(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ongoing_tasks_hidric;

    /********************************************************************************************
    * SUSPEND_TASK_HIDRIC                    Function that should suspend (cancel or interrupt) ongoing task
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       i_flg_reason              Reason for the WF suspension: 'D' (Death)
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.6.0.3
    * @since                                 2010/Jun/07
    ********************************************************************************************/
    FUNCTION suspend_task_hidric
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note epis_positioning.notes_cancel%TYPE;
        l_internal_error EXCEPTION;
        --
        l_flg_show         VARCHAR2(1);
        l_msg_title        sys_message.desc_message%TYPE;
        l_msg              sys_message.desc_message%TYPE;
        l_id_cancel_reason epis_hidrics.id_cancel_reason%TYPE;
    
    BEGIN
        IF i_flg_reason = pk_death_registry.c_flg_reason_death
        THEN
            l_note             := pk_message.get_message(i_lang      => i_lang,
                                                         i_code_mess => pk_death_registry.c_code_msg_death);
            l_id_cancel_reason := pk_cancel_reason.c_reason_patient_death;
        ELSE
            l_note             := NULL;
            l_id_cancel_reason := NULL;
        END IF;
    
        g_error := 'CALL PK_INP_HIDRICS.cancel_epis_hidrics with id_task: ' || i_id_task;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.cancel_epis_hidrics(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_epis_hidrics  => i_id_task,
                                                  i_cancel_reason => l_id_cancel_reason,
                                                  i_cancel_notes  => l_note,
                                                  o_flg_show      => l_flg_show,
                                                  o_msg_title     => l_msg_title,
                                                  o_msg           => l_msg,
                                                  o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --
        -- There is none situation that makes this cancel impossible        
        o_msg_error := NULL;
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
                                              'SUSPEND_TASK_HIDRIC',
                                              o_error);
            RETURN FALSE;
    END suspend_task_hidric;

    /********************************************************************************************
    * REACTIVATE_TASK_HIDRIC                 Function that should reactivate cancelled or interrupted task
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.6.0.3
    * @since                                 2010/Jun/07
    ********************************************************************************************/
    FUNCTION reactivate_task_hidric
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN epis_positioning.id_epis_positioning%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_INP_HIDRICS.SET_EPIS_HID_STATUS';
        IF NOT pk_inp_hidrics.set_epis_hid_status(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_epis_hidrics   => i_id_task,
                                                  i_flg_status     => pk_inp_hidrics_constant.g_epis_hidric_a,
                                                  i_notes          => NULL,
                                                  i_flg_reactivate => pk_alert_constant.g_yes,
                                                  o_msg_error      => o_msg_error,
                                                  o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        -- There is none situation that makes this reactivation impossible
        o_msg_error := NULL;
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
                                              'REACTIVATE_TASK_HIDRIC',
                                              o_error);
            RETURN FALSE;
    END reactivate_task_hidric;

    /**********************************************************************************************
    * SET_MATCH_PAT_HIDRICS                  This function updates id_patient of tabel epis_hidrics
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_patient                       Patient
    * @param i_patient_temp                  Temporary patient 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Alexandre Santos
    * @version                               2.6.0.3
    * @since                                 2010/07/03
    **********************************************************************************************/
    FUNCTION set_match_pat_hidrics
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.SET_MATCH_PAT_HIDRICS';
        IF NOT pk_inp_hidrics.set_match_pat_hidrics(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_patient_temp => i_patient_temp,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END set_match_pat_hidrics;

    /**********************************************************************************************
    * SET_ACTION                  Performs a task action.
    *                             To be used in cpoe when no screen is associated to an action.
    *                             In the hidrics case, only the 'couclusion' is in this condition, therefore
    *                             it is the only action performed in this function.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_patient                       Patient
    * @param i_patient_temp                  Temporary patient 
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.3
    * @since                                 19-Jul-2010
    *
    * @dependencies    This function was developed to Content team
    **********************************************************************************************/
    FUNCTION set_action
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_action       IN action.id_action%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.SET_MATCH_PAT_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.set_finish(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_epis_hidrics => i_task_request,
                                         o_flg_show     => o_flg_show,
                                         o_msg_title    => o_msg_title,
                                         o_msg          => o_msg,
                                         o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    END set_action;

    /********************************************************************************************
    * get tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of requests that identifies the tasks
    * @param       o_task_status          cursor with all requested task status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.5.1.x
    * @since      02-Sep-2010
    *
    * @dependencies    This function was developed to Content team
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_TASK_LIST';
        IF NOT pk_inp_hidrics.get_task_status(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_episode      => i_episode,
                                              i_task_request => i_task_request,
                                              o_task_status  => o_task_status,
                                              o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_task_status;

    /********************************************************************************************
    * cancel all draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    * 
    * @author                                Sofia Mendes
    * @version                               2.5.1.x
    * @since                                 02-Sep-2010
    ********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_visit         episode.id_visit%TYPE;
        l_drafts           table_number;
        l_cancelled_drafts table_number := table_number();
    BEGIN
        -- GET ID_VISIT: the hidrics are associated to the visit              
        g_error := 'CALL pk_episode.get_id_visit with id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_id_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        -- GET the drafts in this visit
        g_error := 'GET ID_EPIS_HIDRICS identifiers';
        pk_alertlog.log_debug(g_error);
        SELECT DISTINCT eh.id_epis_hidrics
          BULK COLLECT
          INTO l_drafts
          FROM epis_hidrics eh
         WHERE eh.id_episode IN (SELECT DISTINCT (epi.id_episode)
                                   FROM episode epi
                                  WHERE epi.id_visit = l_id_visit)
           AND eh.flg_status = pk_inp_hidrics_constant.g_epis_hidric_d;
        --
        g_error := 'CALL PK_INP_HIDRICS.CANCEL_HIDRIC_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.cancel_hidric_list(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_episode          => i_episode,
                                                 i_epis_hid_list    => l_drafts,
                                                 o_cancelled_drafts => l_cancelled_drafts,
                                                 o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END cancel_all_drafts;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_PDMS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics_pdms(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_flg_scope     => i_flg_scope,
                                                    i_scope         => i_scope,
                                                    i_start_date    => i_start_date,
                                                    i_end_date      => i_end_date,
                                                    o_hidrics       => o_hidrics,
                                                    o_hidrics_value => o_hidrics_value,
                                                    o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_epis_hidrics_pdms;

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_requests           array of task request ids to expire
    * @param       o_error                   error message structure
    *
    * @return                                true on success, false otherwise
    * 
    * @author                                António Neto
    * @version                               2.6.1.4
    * @since                                 27-Oct-2011
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_INP_HIDRICS.EXPIRE_TASK';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.expire_task(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_task_requests => i_task_requests,
                                          o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END expire_task;

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
    FUNCTION get_create_results_perm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_results_create OUT VARCHAR2,
        o_dt_exec_str        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_INP_HIDRICS.EXPIRE_TASK';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_create_results_perm(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_epis_hidrics    => i_id_epis_hidrics,
                                                      o_flg_results_create => o_flg_results_create,
                                                      o_dt_exec_str        => o_dt_exec_str,
                                                      o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_create_results_perm;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_REP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics_rep(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_scope           => i_scope,
                                                   i_flg_scope       => i_flg_scope,
                                                   i_start_date      => i_start_date,
                                                   i_end_date        => i_end_date,
                                                   i_cancelled       => i_cancelled,
                                                   i_crit_type       => i_crit_type,
                                                   i_flg_report      => i_flg_report,
                                                   i_epis_hidrics    => i_epis_hidrics,
                                                   i_flg_draft       => i_flg_draft,
                                                   i_search          => i_search,
                                                   i_filter          => i_filter,
                                                   i_column_to_order => i_column_to_order,
                                                   i_order_by        => i_order_by,
                                                   o_epis_hid        => o_epis_hid,
                                                   o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_epis_hidrics_rep;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_INP_HIDRICS.GET_EPIS_HIDRICS_DET_REP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_epis_hidrics_det_rep(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_scope        => i_scope,
                                                       i_flg_scope    => i_flg_scope,
                                                       i_start_date   => i_start_date,
                                                       i_end_date     => i_end_date,
                                                       i_cancelled    => i_cancelled,
                                                       i_crit_type    => i_crit_type,
                                                       i_flg_report   => i_flg_report,
                                                       i_epis_hidrics => i_epis_hidrics,
                                                       i_id_epis_type => i_id_epis_type,
                                                       o_epis_hid     => o_epis_hid,
                                                       o_epis_hid_d   => o_epis_hid_d,
                                                       o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_epis_hidrics_det_rep;

    /**
    * Get intake and output hidrics type based on the acronym.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_acronym      hidrics type acronym
    *
    * @return               Hidrics type Identifier
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                2012/05/14
    */
    FUNCTION get_hidric_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_acronym IN hidrics_type.acronym%TYPE
    ) RETURN hidrics_type.id_hidrics_type%TYPE IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_HIDRIC_TYPE';
        pk_alertlog.log_debug(g_error);
        RETURN pk_inp_hidrics.get_hidric_type(i_lang => i_lang, i_prof => i_prof, i_acronym => i_acronym);
    
    END get_hidric_type;

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
        o_ways_int          OUT pk_types.cursor_type,
        o_body_parts_int    OUT pk_types.cursor_type,
        o_body_side_int     OUT pk_types.cursor_type,
        o_hidrics_int       OUT pk_types.cursor_type,
        o_hidrics_chars_int OUT pk_types.cursor_type,
        --output
        o_ways_out            OUT pk_types.cursor_type,
        o_body_parts_out      OUT pk_types.cursor_type,
        o_body_side_out       OUT pk_types.cursor_type,
        o_hidrics_out         OUT pk_types.cursor_type,
        o_hidrics_chars_out   OUT pk_types.cursor_type,
        o_hidrics_devices_out OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_INP_HIDRICS_PBL.GET_EPIS_HIDRICS_DET_REP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics_groups.get_lists_irrigations(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_epis_hid     => i_epis_hid,
                                                           i_hid_flg_type => i_hid_flg_type,
                                                           --intake
                                                           i_way_int               => i_way_int,
                                                           i_body_part_int         => i_body_part_int,
                                                           i_body_side_int         => i_body_side_int,
                                                           i_hidrics_int           => i_hidrics_int,
                                                           i_hidrics_charact_int   => i_hidrics_charact_int,
                                                           i_flg_bodypart_ftxt_int => i_flg_bodypart_ftxt_int,
                                                           i_device_int            => i_device_int,
                                                           i_old_hidrics_int       => i_old_hidrics_int,
                                                           --output
                                                           i_way_out               => i_way_out,
                                                           i_body_part_out         => i_body_part_out,
                                                           i_body_side_out         => i_body_side_out,
                                                           i_hidrics_out           => i_hidrics_out,
                                                           i_hidrics_charact_out   => i_hidrics_charact_out,
                                                           i_flg_bodypart_ftxt_out => i_flg_bodypart_ftxt_out,
                                                           i_device_out            => i_device_out,
                                                           i_old_hidrics_out       => i_old_hidrics_out,
                                                           i_flg_nr_times_out      => i_flg_nr_times_out,
                                                           i_flg_irrigation_block  => i_flg_irrigation_block,
                                                           --
                                                           o_ways_int          => o_ways_int,
                                                           o_body_parts_int    => o_body_parts_int,
                                                           o_body_side_int     => o_body_side_int,
                                                           o_hidrics_int       => o_hidrics_int,
                                                           o_hidrics_chars_int => o_hidrics_chars_int,
                                                           
                                                           o_ways_out            => o_ways_out,
                                                           o_body_parts_out      => o_body_parts_out,
                                                           o_body_side_out       => o_body_side_out,
                                                           o_hidrics_out         => o_hidrics_out,
                                                           o_hidrics_chars_out   => o_hidrics_chars_out,
                                                           o_hidrics_devices_out => o_hidrics_devices_out,
                                                           o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_lists_irrigations;

    FUNCTION get_odst_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_task_request_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_TITLE';
        IF NOT pk_inp_hidrics.get_hidrics_task_title(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_task_request     => i_task_request,
                                                     i_task_request_det => i_task_request_det,
                                                     o_task_desc        => o_task_desc,
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
                                              'GET_EXAM_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_odst_task_title;

    FUNCTION get_hidric_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_TITLE';
        IF NOT pk_inp_hidrics.get_hidric_status(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_task_request  => i_task_request,
                                                o_flg_status    => o_flg_status,
                                                o_status_string => o_status_string,
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
                                              'GET_EXAM_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_hidric_status;

    FUNCTION cancel_epis_hidrics
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_hidrics  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN epis_hidrics.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
        o_flg_show  VARCHAR2(200 CHAR);
        o_msg_title VARCHAR2(200 CHAR);
        o_msg       VARCHAR2(200 CHAR);
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_TITLE';
    
        FOR i IN 1 .. i_epis_hidrics.count
        LOOP
        
            IF NOT pk_inp_hidrics.cancel_epis_hidrics(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_epis_hidrics  => i_epis_hidrics(i),
                                                      i_cancel_reason => i_cancel_reason,
                                                      i_cancel_notes  => i_cancel_notes,
                                                      o_flg_show      => o_flg_show,
                                                      o_msg_title     => o_msg_title,
                                                      o_msg           => o_msg,
                                                      o_error         => o_error)
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
                                              'GET_EXAM_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END cancel_epis_hidrics;

    FUNCTION set_hidrics_request_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_request    IN table_number,
        i_hd_task_type    IN hidrics_type.id_hidrics_type%TYPE,
        i_prof_order      IN table_number,
        i_dt_order        IN table_varchar,
        i_order_type      IN table_number,
        o_hidrics_req     OUT table_number,
        o_hidrics_req_det OUT table_table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_inp_hidrics.set_hidrics_request_task(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_task_request    => i_task_request,
                                                       i_hd_task_type    => i_hd_task_type,
                                                       i_prof_order      => i_prof_order,
                                                       i_dt_order        => i_dt_order,
                                                       i_order_type      => i_order_type,
                                                       o_hidrics_req     => o_hidrics_req,
                                                       o_hidrics_req_det => o_hidrics_req_det,
                                                       o_error           => o_error)
        THEN
            g_error := 'error found while calling pk_inp_hidrics_pbl.set.set_hidrics_request_task function';
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
                                              'GET_EXAM_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
        
    END set_hidrics_request_task;

    FUNCTION set_hidric_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hidrics OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_COPY_TASK';
        IF NOT pk_inp_hidrics.set_hidric_copy_task(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_patient      => i_patient,
                                                   i_episode      => i_episode,
                                                   i_task_request => i_task_request,
                                                   o_epis_hidrics => o_epis_hidrics,
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
                                              'SET_PROCEDURE_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_hidric_copy_task;

    FUNCTION set_hidric_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL pk_inp_hidrics.set_hidric_delete_task';
        IF NOT pk_inp_hidrics.set_hidric_delete_task(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_task_request => i_task_request,
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
                                              'set_hidric_delete_task',
                                              o_error);
            RETURN FALSE;
    END set_hidric_delete_task;

    FUNCTION get_hidric_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_DATE_LIMITS';
        IF NOT pk_inp_hidrics.get_hidric_date_limits(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_task_request => i_task_request,
                                                     o_list         => o_list,
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
                                              'GET_PROCEDURE_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_hidric_date_limits;

    FUNCTION get_epis_hidrics_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_inp_hidrics.get_epis_hidrics_task(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_epis_hidrics => i_epis_hidrics,
                                                    o_epis_hid     => o_epis_hid,
                                                    o_error        => o_error);
    END get_epis_hidrics_task;

    FUNCTION check_hidrics_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL PK_inp_hidrics_pbl.check_hidrics_cancel';
        IF NOT pk_inp_hidrics.check_hidrics_cancel(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   i_task_request => i_task_request,
                                                   o_flg_cancel   => o_flg_cancel,
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
                                              'check_hidrics_cancel',
                                              o_error);
            RETURN FALSE;
    END check_hidrics_cancel;

    FUNCTION inactivate_hidrics_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_other_exception EXCEPTION;
    
        l_tbl_ids table_number := table_number();
    BEGIN
    
        IF NOT pk_inp_hidrics.inactivate_hidrics_tasks(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_inst        => i_inst,
                                                       i_ids_exclude => l_tbl_ids,
                                                       o_has_error   => o_has_error,
                                                       o_error       => o_error)
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
                                              'INACTIVATE_HIDRICS_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_hidrics_tasks;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_inp_hidrics_pbl;
/
