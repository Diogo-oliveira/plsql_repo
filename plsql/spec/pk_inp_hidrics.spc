/*-- Last Change Revision: $Rev: 2028748 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_hidrics AS

    g_flg_task_status_d CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_flg_task_status_f CONSTANT VARCHAR2(1 CHAR) := 'F';

    TYPE rec_hidrics_charact IS RECORD(
        id_hidrics_charact hidrics_charact.id_hidrics_charact%TYPE,
        hidrics_charact_ft epis_hidrics_det_ftxt.free_text%TYPE);

    TYPE tab_hidrics_charact IS TABLE OF rec_hidrics_charact;

    TYPE rec_occurs_total IS RECORD(
        total_times epis_hidrics_balance.total_times%TYPE,
        desc_type   pk_translation.t_desc_translation);

    TYPE tab_occurs_total IS TABLE OF rec_occurs_total;

    TYPE rec_epis_hidrics_det IS RECORD(
        id_epis_hidrics_det     epis_hidrics_det.id_epis_hidrics_det%TYPE,
        id_epis_hidrics_line    epis_hidrics_line.id_epis_hidrics_line%TYPE,
        id_epis_hidrics         epis_hidrics.id_epis_hidrics%TYPE,
        id_epis_hidrics_balance epis_hidrics_det.id_epis_hidrics_balance%TYPE,
        id_way                  epis_hidrics_line.id_way%TYPE,
        way_ft                  epis_hidrics_det_ftxt.free_text%TYPE,
        id_body_part            hidrics_location.id_body_part%TYPE,
        id_body_side            hidrics_location.id_body_side%TYPE,
        location_ft             epis_hidrics_det_ftxt.free_text%TYPE,
        id_hidrics              epis_hidrics_line.id_hidrics%TYPE,
        hidrics_ft              epis_hidrics_det_ftxt.free_text%TYPE,
        dt_record               epis_hidrics_det.dt_creation_tstz%TYPE,
        value_hidrics           epis_hidrics_det.value_hidrics%TYPE,
        flg_type                epis_hidrics_det.flg_type%TYPE,
        notes                   epis_hidrics_det.notes%TYPE,
        flg_level_control       epis_hid_collector.flg_level_control%TYPE,
        curr_level              epis_hid_collector.curr_level%TYPE,
        restart_level           epis_hid_collector.flg_restart%TYPE, -- Y - Is to restart level, otherwise N
        flg_edit_type           VARCHAR2(1 CHAR), -- L - Set line data; O - Create/Set values
        nr_times                epis_hidrics_det.nr_times%TYPE,
        id_hidrics_device       epis_hidrics_det.id_hidrics_device%TYPE,
        device_ft               epis_hidrics_det_ftxt.free_text%TYPE);

    TYPE tab_epis_hidrics_det IS TABLE OF rec_epis_hidrics_det;

    TYPE rec_epis_hidrics IS RECORD(
        id_epis_hidrics       epis_hidrics.id_epis_hidrics%TYPE,
        epis_hidrics_det_list tab_epis_hidrics_det);

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
    );

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
        o_hidrict_list OUT pk_types.cursor_type,
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
    * @author                         Emilia Taborda
    * @version                        0.1
    * @since                          2006/11/21
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_interval
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_hidric_int OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Get the number of hours in a hidrics interval
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_interval_minutes        interval considered in the current hidrics record
    * @param       i_hidrics_view            current view: H - hour
                                                           I - interval
    *         
    * @return                                interval (number of hours)
    *
    * @author                                José Silva
    * @version                               2.6.0.3
    * @since                                 2010/06/21
    ********************************************************************************************/
    FUNCTION get_epis_hidrics_interval
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interval_minutes IN hidrics_interval.interval_minutes%TYPE,
        i_hidric_view      IN sys_domain.val%TYPE
    ) RETURN NUMBER;

    /******************************************************************************************** 
    * Check if this hidrics type is a hidrics balance
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_hidrics_type            Hidrics type ID
    *         
    * @return                                It is a hidrics balance (True or False)
    *
    * @author                                José Silva
    * @version                               2.6.0.3
    * @since                                 2010/06/14
    ********************************************************************************************/
    FUNCTION is_hidrics_balance
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE
    ) RETURN NUMBER;

    /******************************************************************************************** 
    * Checks if the hidrics is an elimination or administration based on the hidrics type ID
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_hidrics_type            Hidrics type ID
    *         
    * @return                                Hidrics type: A - administration, E - elimination
    *
    * @author                                José Silva
    * @version                               2.6.0.3
    * @since                                 2010/07/26
    ********************************************************************************************/
    FUNCTION get_hidrics_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************************** 
    * Gets the total administration for a specific balance
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_epis_hidrics            Episode hidrics ID
    * @param       i_total_admin             Total administrations
    * @param       i_dt_open                 Balance begin date
    * @param       i_dt_close                Balance end date
    *         
    * @return                                It is a hidrics balance (True or False)
    *
    * @author                                José Silva
    * @version                               2.6.0.3
    * @since                                 2010/06/30
    ********************************************************************************************/
    FUNCTION get_total_admin
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_total_admin  IN epis_hidrics_balance.total_admin%TYPE,
        i_dt_open      IN epis_hidrics_balance.dt_open_tstz%TYPE,
        i_dt_close     IN epis_hidrics_balance.dt_close_balance_tstz%TYPE
    ) RETURN NUMBER;

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

    /******************************************************************************************** 
    * Check if the current total value exceeds fluid restrictions
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_epis_hidrics            episode hidrics ID
    * @param       i_max_intake              Maximum intake
    * @param       i_min_output              Minimum output
    * @param       i_flg_type                Hidrics type: (A)dministration or (E)limination
    * @param       i_total_admin             Current total administrations
    * @param       i_total_elim              Current total eliminations
    * @param       i_flg_reg_type            Record type: N - regular values, T - balance values
    *         
    * @return                                Shows text in red color: Y - yes, N - No
    *
    * @author                                José Silva
    * @version                               2.6.0.3
    * @since                                 2010/06/10
    ********************************************************************************************/
    FUNCTION check_fluid_restrictions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_max_intake   IN epis_hidrics.max_intake%TYPE,
        i_min_output   IN epis_hidrics.min_output%TYPE,
        i_flg_type     IN hidrics.flg_type%TYPE,
        i_total_admin  IN epis_hidrics_balance.total_admin%TYPE,
        i_total_elim   IN epis_hidrics_balance.total_elim%TYPE,
        i_dt_open      IN epis_hidrics_balance.dt_open_tstz%TYPE,
        i_dt_close     IN epis_hidrics_balance.dt_close_balance_tstz%TYPE,
        i_flg_reg_type IN VARCHAR2 DEFAULT NULL,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

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
        i_flg_task_status IN epis_hidrics.flg_status%TYPE DEFAULT g_flg_task_status_f,
        o_id_epis_hidrics OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_error           OUT t_error_out
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
    * @author                         Luï¿½Maia
    * @version                        2.5.0.7.3
    * @since                          2009/11/20
    *
    * @author                         José “ilva
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
        i_flg_task_status  IN epis_hidrics.flg_status%TYPE DEFAULT g_flg_task_status_f,
        i_flg_restricted   IN epis_hidrics.flg_restricted%TYPE,
        i_max_intake       IN epis_hidrics.max_intake%TYPE,
        i_min_output       IN epis_hidrics.min_output%TYPE,
        o_id_epis_hidrics  OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_error            OUT t_error_out
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

    /********************************************************************************************
    * get_ult_result                 Get last result from Hidric
    *
    * @param I_FLG_STATUS            Hidric flag Status
    * @param I_MSG_HIDRICS_M002      Flag to begin
    * @param I_MSG_HIDRICS_M002      Flag ongoing
    *
    * @return                        Returns last result from Hidric
    *
    * @author                        António Neto
    * @since                         23-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_ult_result
    (
        i_flg_status       IN epis_hidrics.flg_status%TYPE,
        i_msg_hidrics_m002 IN sys_message.desc_message%TYPE,
        i_msg_hidrics_m003 IN sys_message.desc_message%TYPE
        
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get_total_result               Get Balance total result from Hidric
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_FLG_STATUS            Hidric flag Status
    * @param I_ID_EPIS_HIDRICS       ID Hidric Episode
    * @param I_TOTAL_ADMIN           Hidric Balance Total Intake
    * @param I_TOTAL_Elim            Hidric Balance Total Output
    * @param I_DT_OPEN_TSTZ          Hidric Balance Open Date/Time
    * @param I_DT_CLOSE_TSTZ         Hidric Balance Close Date/Time
    *
    * @return                        Returns Balance total result from Hidric
    *
    * @author                        António Neto
    * @since                         23-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_total_result
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN epis_hidrics.flg_status%TYPE,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_total_admin     IN epis_hidrics_balance.total_admin%TYPE,
        i_total_elim      IN epis_hidrics_balance.total_elim%TYPE,
        i_dt_open_tstz    IN epis_hidrics_balance.dt_open_tstz%TYPE,
        i_dt_close_tstz   IN epis_hidrics_balance.dt_close_balance_tstz%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get_hidric_last_result         Gets Hidric Last Result
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_FLG_STATUS            Hidric flag Status
    * @param I_ID_EPIS_HIDRICS       ID Hidric Episode
    * @param I_TOTAL_ADMIN           Hidric Balance Total Intake
    * @param I_TOTAL_Elim            Hidric Balance Total Output
    * @param I_DT_OPEN_TSTZ          Hidric Balance Open Date/Time
    * @param I_DT_CLOSE_TSTZ         Hidric Balance Close Date/Time
    * @param I_UNIT_MEASURE          Hidric Unit Measure
    *
    * @return                        Returns the Hidric Last Resul
    *
    * @author                        António Neto
    * @since                         23-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_hidric_last_result
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN epis_hidrics.flg_status%TYPE,
        i_id_epis_hidrics  IN epis_hidrics.id_epis_hidrics%TYPE,
        i_total_admin      IN epis_hidrics_balance.total_admin%TYPE,
        i_total_elim       IN epis_hidrics_balance.total_elim%TYPE,
        i_dt_open_tstz     IN epis_hidrics_balance.dt_open_tstz%TYPE,
        i_dt_close_tstz    IN epis_hidrics_balance.dt_close_balance_tstz%TYPE,
        i_msg_hidrics_m002 IN sys_message.desc_message%TYPE,
        i_msg_hidrics_m003 IN sys_message.desc_message%TYPE,
        i_unit_measure     IN pk_translation.t_desc_translation
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get_pdms_ways                  Gets Hidric ways
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_FLG_type              Hidric flag Type
    *
    * @return                        Returns the Hidric Last Resul
    *
    * @author                        Miguel Gomes
    * @since                         29-AGO-2013
    * @version                       2.6.3.9
    ********************************************************************************************/
    FUNCTION get_pdms_ways
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN way.flg_type%TYPE,
        o_hidric_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_hidric_status              Gets Hidric Status
    *
    * @param I_LANG                  Language ID for translations
    * @param I_FLG_STATUS            Hidric flag Status
    *
    * @return                        Returns the Hidric Status
    *
    * @author                        António Neto
    * @since                         23-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_hidric_status
    (
        i_lang       IN language.id_language%TYPE,
        i_flg_status IN epis_hidrics.flg_status%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Returns the hidrics interval description
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_HIDRICS_INTERVAL       Hidrics Interval identifier
    * @param I_INTERVAL_MINUTES       Interval in minutes
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Interval description
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          13-Jan-2011
    *
    * @author                         António Neto
    * @version                        2.6.1.6
    * @since                          20-Dec-2011
    *******************************************************************************************************************************************/
    FUNCTION get_hid_interval_desc_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_hidrics_interval IN hidrics_interval.id_hidrics_interval%TYPE,
        i_interval_minutes IN hidrics_interval.interval_minutes%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get_hidric_interval                   Gets Hidric Interval Description
    *
    * @param I_LANG                         Language ID for translations
    * @param i_interval_minutes               Interval Value
    * @param I_MSG_HOUR                     Mask format one hour
    * @param I_MSG_HOURS                    Mask format more than one hour
    * @param i_msg_minute                   Mask format one minute
    * @param i_msg_minutes                  Mask format more than one minute
    * @param I_CODE_HIDRICS_INTERVAL        Code Interval Value
    *
    * @return                               Returns the Hidric Interval Description
    *
    * @author                               António Neto
    * @since                                23-Dec-2010
    * @version                              2.6.0.5
    ********************************************************************************************/
    FUNCTION get_hidric_interval
    (
        i_lang                  IN language.id_language%TYPE,
        i_interval_minutes      IN epis_hidrics.interval_minutes%TYPE,
        i_msg_hour              IN sys_message.desc_message%TYPE,
        i_msg_hours             IN sys_message.desc_message%TYPE,
        i_msg_minute            IN sys_message.desc_message%TYPE,
        i_msg_minutes           IN sys_message.desc_message%TYPE,
        i_code_hidrics_interval IN hidrics_interval.code_hidrics_interval%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * to_char_hidric_datetime         Convert Hidric Date/Time to varchar
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_DATETIME              Date Time to be converted
    *
    * @return                        Returns the conversion of Hidric Date/Time to varchar
    *
    * @author                        António Neto
    * @since                         23-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION to_char_hidric_datetime
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_datetime IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * to_datetime_hidric             Convert Hidric to Date/Time
    *
    * @param I_INTERVAL              Interval in string format
    *
    * @return                        Returns the conversion of Hidric to Date/Time
    *
    * @author                        António Neto
    * @since                         24-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION to_datetime_hidric(i_interval IN VARCHAR2) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * get_hidric_bal_rank            Get Hidric Balance Rank
    *
    * @param I_LANG                  Language ID for translations
    * @param I_FLG_STATUS            Hidric Balance flag Status
    *
    * @return                        Returns Hidric Balance Rank
    *
    * @author                        António Neto
    * @since                         24-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_hidric_bal_rank
    (
        i_lang       IN language.id_language%TYPE,
        i_flg_status IN epis_hidrics_balance.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get_desc_hidric_type           Return description of the intake and outake with software where it was requested (if not actual software)
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_LINST_ID_EPIS_TYPE    ID Episode Type to be compared
    * @param I_ID_EPIS_TYPE          ID Episode Type to be used
    * @param I_ID_EPIS_HIDRICS       ID Hidric Episode
    * @param I_FLG_TI_TYPE           Flag TI_LOG
    * @param I_CODE_HIDRICS_TYPE     Code Hidric Type
    *
    * @return                        Returns the description of hidric type
    *
    * @author                        António Neto
    * @since                         23-Dec-2010
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_desc_hidric_type
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_linst_id_epis_type IN episode.id_epis_type%TYPE,
        i_epi_id_epis_type   IN episode.id_epis_type%TYPE,
        i_id_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_ti_type        IN hidrics_type.flg_ti_type%TYPE,
        i_code_hidrics_type  IN hidrics_type.code_hidrics_type%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * create_epis_hidrics             Get all hidrics associated with all episodes in current episode visit
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
        o_epis_hid        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics                Get all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_FLG_DRAFT              If it should return draft functions or not ('Y'- Yes; 'N'- No)
    * @param I_SEARCH                 keyword to Search for
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_FILTER                 Filter by a group (dates, hidric type, etc.)
    * @param I_COLUMN_TO_ORDER        Column to be order
    * @param I_ORDER_BY               The way to be order, ascending (ASC) or descendig (DESC)
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_DRAFT              {*} 'Y' YES {*} 'N' NO
    * @value I_FILTER                 1 - Hidric Type  2 - Hidric Initial Date/Time  3 - Hidric State  0|NULL - All
    * @value I_COLUMN_TO_ORDER        1 - Hidric Type  2 - Hidric Initial Date/Time  3 - Hidric State  4 - Hidric Interval Value  5 - Hidric End Date/Time  6 - Hidric Last Result  
    *                                 NULL - Balance Rank ASC and Hidric Creation Descending and ID Hidric Balance Episode Descending
    * @value I_ORDER_BY               1|NULL - Ascending Order  2 - Descending Order
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/04
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_draft       IN VARCHAR2,
        i_search          IN VARCHAR2,
        i_start_record    IN NUMBER,
        i_num_records     IN NUMBER,
        i_filter          IN NUMBER,
        i_column_to_order IN NUMBER,
        i_order_by        IN NUMBER,
        o_epis_hid        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics                Get all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_FLG_DRAFT              If it should return draft functions or not ('Y'- Yes; 'N'- No)
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
    * @value I_FLG_DRAFT              {*} 'Y' YES {*} 'N' NO
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
    FUNCTION get_epis_hidrics_with_totals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_draft       IN VARCHAR2,
        i_search          IN VARCHAR2,
        i_start_record    IN NUMBER,
        i_num_records     IN NUMBER,
        i_filter          IN NUMBER,
        i_column_to_order IN NUMBER,
        i_order_by        IN NUMBER,
        o_epis_hid        OUT pk_types.cursor_type,
        o_group_totals    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_count          Get number of all hidrics associated with all episodes in current episode visit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_FLG_DRAFT              If it should return draft functions or not ('Y'- Yes; 'N'- No)
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a group (dates, hidric type, etc.)
    * @param O_NUM_EPIS_HIDRICS       Returns the number of records for the search criteria
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_FLG_DRAFT              {*} 'Y' YES {*} 'N' NO
    * @value I_FILTER                 1 - Hidric Type  2 - Hidric Initial Date/Time  3 - Hidric State  0|NULL - All
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
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
        i_flg_draft        IN VARCHAR2,
        i_search           IN VARCHAR2,
        i_filter           IN NUMBER,
        o_num_epis_hidrics OUT NUMBER,
        o_error            OUT t_error_out
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
    * @return                         Returns TRUE if success, otherwise returns FALSE
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
    * create_epis_hidrics_det         Get hidric detail information
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           ID_EPIS_HIDRICS identifier
    * @param I_EPISODE                ID_EPISODE identifier
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_EPIS_HID_D             Cursor that returns hidrics detail
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
    FUNCTION get_epis_hidrics_reports
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_epis_hid     OUT pk_types.cursor_type,
        o_epis_hid_d   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
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
        o_epis_hid     OUT pk_types.cursor_type,
        o_epis_hid_d   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_reports         Get hidric detail information (AFTER 2.6.0.3 IT SHOULD ONLY BE USED IN REPORTS)
    *                                 To be removed when the new reports to the HIDRICS is created
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
    * @version                        0.1
    * @since                          2006/11/21
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_EPIS_HID_ACTIONS                   Get available actions for a requested task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_epis_hidrics            epis_hidrics id
    * @param       o_status                  list of available actions for the task request
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/19
    ********************************************************************************************/
    FUNCTION get_epis_hid_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_EPIS_HID_STATUS                    This function change Intake and Output status from:
    *                                             * Required to Interrupted
    *                                             * In execution to Interrupted
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_epis_hidrics                  epis_hidrics ID
    * @param i_flg_status                    FLG_STATUS of this registry 
    * @param i_notes                         notes
    * @param i_flg_reactivate                Y-reactivate mode-> only consider inactive ou cancelled registries
    * @param o_msg_error                     Message of error to display to user
    * @param o_error                         Error object
    *
    * @value I_FLG_TASK_STATUS               {*} 'C' Cancel {*} 'I' Interrupt
    * @value I_FLG_TASK_STATUS               {*} 'D' Draft {*} 'F' Final
    *
    * @return                                Success / fail
    *
    * @author                                Emilia Taborda
    * @version                               0.1
    * @since                                 2006/11/21
    *
    * @author                                Carlos Ferreira
    * @version                               0.2
    * @since                                 2007-03-21
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
        i_flg_task_status IN epis_hidrics.flg_status%TYPE DEFAULT g_flg_task_status_f,
        i_flg_reactivate  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_msg_error       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * CANCEL_HIDRIC_LIST                     Function responsable for cancel one hidric draft task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_epis_hid_list           list of epis_hidrics ids
    * @param       o_cancelled_drafts        List of drafts that were already cancelled
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    * 
    * @author                                Luís Maia
    * @version                               2.5.0.7.3
    * @since                                 2009/11/19
    ********************************************************************************************/
    FUNCTION cancel_hidric_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_epis_hid_list    IN table_number,
        o_cancelled_drafts OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * return the sum off all hidrics values (administration and elimination) for a determinate
    * interval date.
    *
    * @param i_lang        Id language
    * @param i_prof        id professional
    * @param i_episode     ID episode
    
    * @param o_hidrics     cursor with the sum hidrics values (administration and elimination)
    *                      and result of (administration minus elimination)
    * @param o_error       error
    *
    *
    * @author              Filipe Silva
    * @version             2.5.0.6
    * @since               2009/09/01
       ********************************************************************************************/
    FUNCTION get_last_hidrics_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_hidrics OUT pk_types.cursor_type,
        o_error   OUT t_error_out
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
    * @RETURN  TRUE or FALSE
    * 
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.6.1
    * @since   06-10-2009
    ****************************************************************************************************/
    FUNCTION get_epis_dt_begin
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_dt_begin OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    *  Actualize collumn hidrics in table GRID_TASK
    *
    * @param      i_lang           language ID
    * @param      i_prof           professional information
    * @param      i_patient        patient ID
    * @param      i_episode        episode ID
    * @param      i_task_request   array of task requests (if null, return all tasks as usual)
    * @param      i_filter_tstz    Date to filter only the records with "end dates" > i_filter_tstz
    * @param      i_filter_status  Array with task status to consider along with i_filter_tstz
    * @param      i_flg_report     Required in all get_task_list APIs
    * @param      o_grid           Cursor with all data
    * @param      o_error          error information
    *    
    * @author     Luís Maia
    * @version    2.5.0.7
    * @since      2009/10/26
    *
    * @dependencies    This function was developed to Content team
    ***********************************************************************************************************/
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
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_flg_conflict OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_actions_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * copy task to draft (from an existing active/inactive task)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id (current episode)
    * @param       i_epis_hidrics            epis hidrics id (used for active/inactive tasks)
    * @param       o_id_epis_hidrics         epis hidrics id
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
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_id_epis_hidrics      OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * activates a set of draft tasks (task goes from draft to active workflow)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_hidrics                 array of selected hidrics 
    * @param       o_error                   error message
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
        i_epis_hidrics  IN table_number,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN grid_task.hidrics_reg%TYPE;

    /**
    * Gets ways, locations, fluids ans characterization cursors used to fill multichoice lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode Id
    * @param   i_epis_hid                  Epis hidrics id
    * @param   i_hid_flg_type              Hidrics flg_type (Administration or Elimination)
    * @param   i_hidrics_type              Hidrics type ID
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
        i_episode               IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_hid              IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_flg_type          IN hidrics.flg_type%TYPE,
        i_hidrics_type          IN hidrics_type.id_hidrics_type%TYPE DEFAULT NULL,
        i_way                   IN way.id_way%TYPE DEFAULT NULL,
        i_body_part             IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side             IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics               IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact       IN table_number DEFAULT NULL,
        i_flg_bodypart_freetext IN VARCHAR2,
        i_device                IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_flg_nr_times          IN hidrics.flg_nr_times%TYPE DEFAULT NULL,
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
    FUNCTION check_existing_hidrics_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hids    IN table_number,
        o_exists_draft OUT VARCHAR2,
        o_exists       OUT VARCHAR2,
        o_error        OUT t_error_out
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
    * Gets hidrics description
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics_line         epis hidrics line id
    *
    * @return  Hidrics description
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   26-05-2010
    */
    FUNCTION get_hidrics_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics_line     IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_dt_epis_hid_line_hist IN epis_hidrics_line_hist.dt_epis_hid_line_hist%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Gets device description
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis_hidrics_det       epis hidrics det id
    *
    * @return  Hidrics description
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   14-Dez-2010
    */
    FUNCTION get_device_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_epis_hidrics_det  IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_dt_epis_hid_det_hist IN epis_hidrics_det_hist.dt_epis_hidrics_det_hist%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get hidric sign
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_hidrics                   hidrics id
    *
    * @return  Hidric sign (+, -, NULL)
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   26-05-2010
    */
    FUNCTION get_hidric_sign
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_hidrics IN hidrics.id_hidrics%TYPE
    ) RETURN VARCHAR2;

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

    /**
    * Sets epis hidrics proposed to administered
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_prop_hidrics              Table with epis hidrics det id
    * @param   i_prop_hid_dt               Table with dates of execution
    * @param   i_prop_hid_val              Table with values
    * @param   i_flg_chg_bal_dt            Is to change the next balance data? Y - Yes; Otherwise N
    * @param   o_epis_hid_bal              New epis hidrics balance id
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
    FUNCTION set_epis_hidrics_prop_lst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_hidrics   IN epis_hidrics.id_epis_hidrics%TYPE,
        i_prop_hidrics   IN table_number,
        i_prop_hid_dt    IN table_varchar,
        i_prop_hid_val   IN table_number,
        i_flg_chg_bal_dt IN VARCHAR2,
        o_epis_hid_bal   OUT epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Formats text for max. intake or min. output
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_label                     Text with label "Max. intake" or "Min. output"
    * @param   i_value                     Value of max. intake or min. output
    * @param   i_unit_measure_desc         Label for the unit
    *
    * @return  Formatted string
    *
    * @author  José Brito
    * @version v2.6.0.3
    * @since   26-05-2010
    */
    FUNCTION get_intake_output_text
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_label             IN sys_message.desc_message%TYPE,
        i_value             IN NUMBER,
        i_unit_measure_desc IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * get_hidrics_um_id               Get the unit measure that is used in this hidrics record
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * 
    * @return                         Unit measure ID
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_um_id
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics          IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_epis_hbalance_hist IN epis_hbalance_hist.dt_epis_hbalance_hist%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    /*******************************************************************************************************************************************
    * get_hidrics_um                  Get the unit measure that is used in this hidrics record
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * 
    * @return                         Unit measure description
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_um
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics          IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_epis_hbalance_hist IN epis_hbalance_hist.dt_epis_hbalance_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

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

    /*******************************************************************************************************************************************
    * get_hidrics_location            Get the location registered in this hidrics record
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS_LINE      EPIS_HIDRICS_LINE ID
    * 
    * @return                         Unit measure description
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_location
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics_line     IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_desc_body_part        IN VARCHAR2 DEFAULT '',
        i_desc_body_side        IN VARCHAR2 DEFAULT '',
        i_dt_epis_hid_line_hist IN epis_hidrics_line_hist.dt_epis_hid_line_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * get_hidrics_value               Get the location registered in this hidrics record
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_HIDRICS_VALUE          Registered value
    * @param I_HIDRICS_TYPE           Hidrics type (administration or elimination)
    * 
    * @return                         Formatted value
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_hidrics_value IN epis_hidrics_det.value_hidrics%TYPE,
        i_hidrics_type  IN hidrics.flg_type%TYPE
    ) RETURN VARCHAR2;

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
    * @param I_DT_INIT_BAL       Date where the current balance begins
    * @param i_epis_hidrics_group Epis hidrics group ID
    * @param i_dt_init_balance    Epis hidrics group ID
    * 
    * @return                         Formatted value
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/27
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_total_balance
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_hidrics       IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hidrics_balance    IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_hidrics            IN hidrics.id_hidrics%TYPE,
        i_hidrics_type       IN hidrics.flg_type%TYPE,
        i_epis_hidr_line     IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_drug_presc_det     IN pk_api_pfh_in.r_presc.id_presc%TYPE,
        i_dt_reg             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_reg_type       IN VARCHAR2,
        i_flg_real_value     IN VARCHAR2 DEFAULT 'N',
        i_epis_hidrics_group IN epis_hidrics_group.id_epis_hidrics_group%TYPE DEFAULT NULL,
        i_dt_init_balance    IN epis_hidrics_balance.dt_open_tstz%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * get_hidrics_total_properties  Get the properties for each value of the grid/graph
    * 
    * @param I_LANG              Language ID for translations
    * @param I_PROF              Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS      Episode hidrics ID
    * @param I_FLG_GRID_TYPE     Grid type: G - Graph, F - Flowsheet
    * @param I_FLG_TYPE          Hidrics type: A - administration, E - elimination
    * @param I_DT_REG            Record date
    * @param I_FLG_REG_TYPE      Record type when counting total values: N - regular values, T - balance values
    * @param I_DT_INIT           Date considered to be the start date for the graph
    * @param I_DT_INIT_BAL       Date where the current balance begins
    * @param i_max_intake        Maximum intake
    * @param i_min_output        Minimum output
    * @param i_epis_hidrics_group Epis hidrics group ID
    * @param i_flg_status         A-active; C-cancelled
    * 
    * @return                         Formatted value
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/06/07
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_total_properties
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_hidrics       IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_grid_type      IN VARCHAR2,
        i_flg_type           IN hidrics.flg_type%TYPE,
        i_dt_reg             IN epis_hidrics_balance.dt_close_balance_tstz%TYPE,
        i_flg_reg_type       IN VARCHAR2,
        i_dt_init            IN epis_hidrics.dt_initial_tstz%TYPE,
        i_dt_init_bal        IN epis_hidrics_det.dt_first_reg_balance%TYPE,
        i_max_intake         IN epis_hidrics.max_intake%TYPE,
        i_min_output         IN epis_hidrics.min_output%TYPE,
        i_hidrics_type       IN epis_hidrics.id_hidrics_type%TYPE,
        i_epis_hidrics_group IN epis_hidrics_group.id_epis_hidrics_group%TYPE DEFAULT NULL,
        i_flg_status         IN epis_hidrics_group.flg_status%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

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
    * @param i_epis_hidrics_balance   EPIS_HIDRICS balance to load in the grid
    * @param I_FLG_GRID_TYPE          Grid type: G - Graph, F - Flowsheet
    * @param I_FLG_INTERVAL           Interval type (used in the graph): H - Hour, I - interval
    * @param I_FLG_CONTEXT            Context in which the grid was loaded (null if the grid was loaded through the deepnav):
                                           R - New intake/output record. 
                                           B - End of balance
    * @param O_EPIS_HID_TIME          Grid columns (one per date)
    * @param O_EPIS_HID_PAR           Lines or series of values (one per hidrics)
    * @param O_EPIS_HID_HOUR          Graph scale (in hours)
    * @param o_id_balance_next        next id_epis_hidrics_balance
    * @param o_id_balance_before      previous id_epis_hidrics_balance
    * @param o_min_date               Minimun date to create columns in the grid
    * @param o_max_date               Maximun date to create columns in the grid
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
        i_flg_grid_type        IN VARCHAR2,
        i_flg_interval         IN VARCHAR2 DEFAULT NULL,
        i_flg_context          IN VARCHAR2 DEFAULT NULL,
        o_epis_hid_time        OUT NOCOPY pk_types.cursor_type,
        o_epis_hid_par         OUT NOCOPY pk_types.cursor_type,
        o_epis_hid_hour        OUT NOCOPY pk_types.cursor_type,
        o_max_scale            OUT NOCOPY NUMBER,
        o_label_ref            OUT NOCOPY VARCHAR2,
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
    * get_grid_new_column             Get the header for a new column inserted by the user
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param i_id_epis_hidrics_balance EPIS_HIDRICS balance ID
    * @param I_DT_EXEC                New date
    * @param O_EPIS_HID_TIME          New column
    * @param O_NEW_INDEX              Index where the date is positioned in the time array
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         José “ilva
    * @version                        2.6.0.3
    * @since                          2010/06/04
    *******************************************************************************************************************************************/
    FUNCTION get_grid_new_column
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_dt_exec              IN VARCHAR2,
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
    * Get epis_hidrics_balance for the given date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    * @param   i_dt_exec                   Date of execution
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION get_balance_id
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_exec      IN epis_hidrics_det.dt_execution_tstz%TYPE DEFAULT current_timestamp
    ) RETURN epis_hidrics_balance.id_epis_hidrics_balance%TYPE;

    /**
    * Add/Update detail information
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_data                      Epis hidrics det data
    * @param   o_epis_hid_det              Epis hidrics det id
    * @param   o_epis_hidrics_line         Epis hidrics line id
    * @param   o_epis_hidrics              Epis hidrics id
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
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_data              IN CLOB,
        o_epis_hid_det      OUT epis_hidrics_det.id_epis_hidrics_det%TYPE,
        o_epis_hidrics_line OUT epis_hidrics_line.id_epis_hidrics_line%TYPE,
        o_epis_hidrics      OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add/Update detail information for a list of records (intakes and /or outputs)
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
    * @author  Sofia Mendes
    * @version v2.6.3.8
    * @since   09-09-2013
    */
    FUNCTION set_epis_hid_det_list
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
    * Returns the hidrics type id given the acronym
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_acronym                hidrics type acronym
    * 
    * @return                         Returns hidrics type id
    *
    * @author                         Sofia Mendes
    * @version                        2.6.3.8
    * @since                          2013/09/05
    *******************************************************************************************************************************************/
    FUNCTION get_id_hidrics_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_acronym IN hidrics_type.acronym%TYPE
    ) RETURN hidrics_type.id_hidrics_type%TYPE;

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

    /*******************************************************************************************************************************************
    * get_hidrics_way                 Get the way registered in this hidrics record
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS_LINE      EPIS_HIDRICS_LINE ID
    * 
    * @return                         way description
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.3
    * @since                          2010/06/01
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_way
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics_line     IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_dt_epis_hid_line_hist IN epis_hidrics_line_hist.dt_epis_hid_line_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * get_hid_chars_ids               Get the characteristics ids in this hidrics record
    *
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS_DET       EPIS_HIDRICS ID
    * 
    * @return                         way description
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.3
    * @since                          2010/06/01
    *******************************************************************************************************************************************/
    FUNCTION get_hid_chars_ids
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE
    ) RETURN table_number;

    /**
    * get_hid_chars_descs             Get the characteristics descriptions in this hidrics record
    *
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS_DET       EPIS_HIDRICS ID
    * 
    * @return                         way description
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.3
    * @since                          2010/06/01
    *******************************************************************************************************************************************/
    FUNCTION get_hid_chars_descs
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_epis_hidrics_det         IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_dt_epis_hidrics_det_hist IN epis_hidrics_det_hist.dt_epis_hidrics_det_hist%TYPE DEFAULT NULL
    ) RETURN table_varchar;

    /**
    * get_characts_descs             Get a description with all the characteristics descriptions
    *
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS_DET       EPIS_HIDRICS_DET ID
    * 
    * @return                         way description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.3.5
    * @since                          15-Dez-2010
    *******************************************************************************************************************************************/
    FUNCTION get_characts_descs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE
    ) RETURN VARCHAR2;

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
    * @param   i_epis_hid_balance          Epis hidrics balance id (If null means current open balance)
    * @param   i_flg_chg_bal_dt            Is to change the next balance data? Y - Yes; Otherwise N
    * @param   i_flg_just_cal              Is to just calculate the balance? Y - Yes; Otherwise N (In case of current balance, when value is 'Y' the balance will not be close)
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hid_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE DEFAULT NULL,
        i_flg_chg_bal_dt   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_exec          IN epis_hidrics_det.dt_execution_tstz%TYPE DEFAULT NULL,
        i_flg_just_cal     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_epis_hid_bal     OUT epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_error            OUT t_error_out
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
    ) RETURN tf_tasks_list;

    /**
    * Closes or recalculates the inputed balance and opens a new one (when applicable)
    * NOTE: Used only when creating a auto_balance do not use for other purposes
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   01-06-2010
    */
    PROCEDURE set_balance;

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
    * @param   i_dt_begin                  Start date
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
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_dft_values OUT pk_types.cursor_type,
        o_error      OUT t_error_out
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_cancel_reason    IN epis_hidrics.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_hidrics.notes_cancel%TYPE,
        i_flg_status_force IN epis_hidrics.flg_status%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_error            OUT t_error_out
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
    * Saves hidrics history
    *
    * @param   i_epis_hidrics              epis_hidrics id
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_hist
    (
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE DEFAULT NULL,
        i_where        IN VARCHAR2 DEFAULT NULL,
        i_flg_status   IN VARCHAR2 DEFAULT NULL
    );

    /**
    * Saves hidrics values history
    *
    * @param   i_epis_hidrics_det              epis_hidrics_det id
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_det_hist
    (
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE DEFAULT NULL,
        i_where            IN VARCHAR2 DEFAULT NULL
    );

    /**
    * Saves balance history
    *
    * @param   i_epis_hidrics_balance              epis_hidrics_balance id
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_bal_hist
    (
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE DEFAULT NULL,
        i_where                IN VARCHAR2 DEFAULT NULL
    );

    /**
    * Saves hidrics characteristics history for a given hidrics value
    *
    * @param   i_epis_hidrics_det              epis_hidrics_det id
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_char_hist(i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE);

    /**
    * Saves hidrics line history
    *
    * @param   i_epis_hidrics_line              epis_hidrics_line id
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_line_hist
    (
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE DEFAULT NULL,
        i_where             IN VARCHAR2 DEFAULT NULL
    );

    /**
    * Saves hidrics collector history.
    *
    * @param   i_epis_hidrics_line              epis_hidrics_line id. If i_epis_hidrics_line is not null saves all collectors of this line
    * @param   i_epis_hid_collector             epis_hid_collector id. If i_epis_hid_collector is not null saves only this collector
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_col_hist
    (
        i_epis_hidrics_line  IN epis_hidrics_line.id_epis_hidrics_line%TYPE DEFAULT NULL,
        i_epis_hid_collector IN epis_hid_collector.id_epis_hid_collector%TYPE DEFAULT NULL
    );

    /**
    * Saves hidrics free text history.
    *
    * @param   i_epis_hidrics_det_ftxt          epis_hidrics_det_ftxt id
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE set_epis_hid_ftxt_hist
    (
        i_epis_hidrics_det_ftxt IN epis_hidrics_det_ftxt.id_epis_hidrics_det_ftxt%TYPE DEFAULT NULL,
        i_where                 IN VARCHAR2 DEFAULT NULL
    );

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
        i_epis_hidrics_det IN table_number,
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
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_det.id_epis_hidrics_line%TYPE DEFAULT NULL,
        i_epis_hidrics      IN epis_hidrics.id_epis_hidrics%TYPE DEFAULT NULL,
        i_hid_way           IN way.id_way%TYPE DEFAULT NULL,
        i_hid_way_ft        IN epis_hidrics_det_ftxt.free_text%TYPE DEFAULT NULL,
        i_bdy_part          IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_bdy_side          IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_location_ft       IN epis_hidrics_det_ftxt.free_text%TYPE DEFAULT NULL,
        i_hid               IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hid_ft            IN epis_hidrics_det_ftxt.free_text%TYPE DEFAULT NULL,
        i_dt_execution      IN epis_hidrics_det.dt_execution_tstz%TYPE,
        o_collector         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Is the flag level control of collector available
    *
    * @param   i_epis_hid_collector       Epis hidrics collector id
    *
    * @return  'Y' if is available, 'N' otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   17-06-2010
    */
    FUNCTION is_coll_flg_lvlc_avail(i_epis_hid_collector IN epis_hidrics_det.id_epis_hid_collector%TYPE) RETURN VARCHAR2;

    /**
    * Is the flag restart of collector available
    *
    * @param   i_epis_hid_line       Epis hidrics line id
    * @param   i_dt_execution        Execution date
    *
    * @return  'Y' if is available, 'N' otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   17-06-2010
    */
    FUNCTION is_coll_flg_rest_avail
    (
        i_epis_hid_line IN epis_hidrics_det.id_epis_hidrics_line%TYPE,
        i_dt_execution  IN epis_hidrics_det.dt_execution_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * Verifies if epis_hidrics has auto_balance
    *
    * @param   i_prof                Professional vector of information (professional ID, institution ID, software ID)
    * @param   i_epis_hidrics        Epis hidrics id
    *
    * @return  'Y' if it has auto_balance, 'N' otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   28-06-2010
    */
    FUNCTION has_auto_balance
    (
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN VARCHAR2;

    /**
    * Verifies if the collector is the last collector
    *
    * @param   i_epis_hid_line             Epis hidrics line id
    * @param   i_epis_hid_collector        Epis hidrics collector id
    *
    * @return  'Y' if it has auto_balance, 'N' otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   01-07-2010
    */
    FUNCTION is_last_collector
    (
        i_epis_hid_line      IN epis_hid_collector.id_epis_hidrics_line%TYPE,
        i_epis_hid_collector IN epis_hid_collector.id_epis_hid_collector%TYPE
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

    /**
    * Get next balance date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    *
    * @return  epis_hidrics next balance date
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   05-07-2010
    */
    FUNCTION get_dt_next_balance
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN epis_hidrics.dt_next_balance%TYPE;

    /**
    * Get next balance date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics id
    *
    * @return  epis_hidrics next balance date
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   05-07-2010
    */
    FUNCTION get_dt_next_balance
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        o_dt_next_balance OUT epis_hidrics.dt_next_balance%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_hidrics_location            Get the location registered in this hidrics record
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS_LINE      EPIS_HIDRICS_LINE ID
    * 
    * @return                         table_varchar with position 1 - description of location
    *                                                             2 - description of body_part
    *                                                             3 - description of body_side
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.3
    * @since                          2010/07/06
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_location_grid
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE
    ) RETURN table_varchar;

    FUNCTION get_table_val
    (
        i_table IN table_varchar,
        i_index IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_job_next_date(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION is_to_perform_balance
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get_epis_hidrics_descs                      Get the descriptions to be shown in the error popups.
    * To be used in the CPOE functions when different users are performing conflicting actions.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_epis_hidrics            list of epis hidrics
    * @param       i_code_msg                Code Message to be used
    * @param       o_flg_show                  Y- should be shown an error popup
    * @param       o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    * 
    * @author                               Sofia Mendes
    * @version                               2.6.0.3.4
    * @since                                 08-Nov-2010
    ********************************************************************************************/
    FUNCTION get_epis_hidrics_descs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_hidrics IN table_number,
        i_code_msg     IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if it is necessary to display an error popup when different user are performing conflicting 
    * actions at the same time.
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)   
    * @param   i_epis_hidrics              Epis hidrics identifier
    * @param   i_epis_hidrics_status       Epis hidrics status
    * @param   o_flg_show                  Y- should be shown an error popup
    * @param   o_msg_title                 Title to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_msg                       Message to be shown in the popup if the o_flg_show = 'Y'
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.0.3
    * @since   03-Nov-2010
    */
    FUNCTION check_show_conflict_pop
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_hidrics        IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_status IN epis_hidrics.flg_status%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_nr_occurs_by_type          Function that returns the nr of occurrences by ocurrence type for a given id_epis_hidrics
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_epis_hidrics           EPISDOE Hidric ID
    * @param i_id_epis_hid_balance    Epis hidrics balance
    * @param i_id_episode             Episode ID
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         List with the nr of occurcence ; Occurrence type descruption
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          13-Dez-2010
    *******************************************************************************************************************************************/
    FUNCTION get_nr_occurs_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_id_epis_hid_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_id_episode          IN episode.id_episode%TYPE
    ) RETURN table_varchar;

    /*******************************************************************************************************************************************
    * get_hidrics_total_times   Get the total nr of occurrences registered in the balance
    * 
    * @param I_LANG              Language ID for translations
    * @param I_PROF              Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS      Episode hidrics ID
    * @param I_HIDRICS_BALANCE   Balance ID
    * @param I_HIDRICS           Hidrics ID
    * @param I_HIDRICS_TYPE      Hidrics type ID
    * @param I_EPIS_HIDR_LINE    Hidrics line ID    
    * @param i_msg               Message to be used to format the value
    * 
    * @return                         Formatted value
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          15-Dec-2010
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_total_times
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_epis_hidr_line  IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_msg             IN sys_message.desc_message%TYPE
    ) RETURN VARCHAR2;

    /**
    * get_flowsheet_tooltip             Get a info to be shown in the flowsheet tooltip
    *
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           EPIS_HIDRICS ID
    * @param I_EPIS_HIDRICS_DET       EPIS_HIDRICS_DET ID
    * @param i_nr_times               Nr of occurrences
    * @param i_value_hidrics          Quantity
    * @param i_hidrics_device         Device ID
    * @param i_professional           Professional ID
    * @param i_hidrics_type           Hidrics type: A-administration; E-elimination
    * @param i_value_srt              Dose value of the iv fluids
    * 
    * @return                         description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.3.5
    * @since                          15-Dez-2010
    *******************************************************************************************************************************************/
    FUNCTION get_flowsheet_tooltip
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics     IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_nr_times         IN epis_hidrics_det.nr_times%TYPE,
        i_value_hidrics    IN epis_hidrics_det.value_hidrics%TYPE,
        i_hidrics_device   IN hidrics_device.id_hidrics_device%TYPE,
        i_professional     IN epis_hidrics_det.id_professional%TYPE,
        i_hidrics_type     IN hidrics.flg_type%TYPE DEFAULT NULL,
        i_value_srt        IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * check_match_characts         Check if the device corresponds to the 'Other' option.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_hid_characts           Characteristics Ids    
    * @param i_id_way                 Way Id
    * @param i_id_hidrics             Hidrics Id
    * 
    * @return                         Y- the i_id_hidrics_device corresponds to the 'Other' options; N-otherwise
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.3.5
    * @since                          15-Dez-2010
    *******************************************************************************************************************************************/
    FUNCTION check_match_characts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hid_characts IN table_number,
        i_id_way       IN way.id_way%TYPE,
        i_id_hidrics   IN hidrics.id_hidrics%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the hidrics type of the hidrics of one line.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_epis_hidrics_line    Epis hidrics line id     
    * @param       o_hidrics_flg_type        Hidrics flg type
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    * 
    * @author                               Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 14-Jan-2011
    ********************************************************************************************/
    FUNCTION get_hidrics_type
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        o_hidrics_flg_type     OUT hidrics.flg_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the episode associated to an epis_hidrics.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_epis_hidrics         Epis hidrics  id     
    * @param       o_id_episode              episode id
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    * 
    * @author                               Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 17-Jan-2011
    ********************************************************************************************/
    FUNCTION get_epis_hid_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_id_episode      OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the hidrics flg_type (administration, elimination) associated to a line.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_epis_hidrics_line       Epis hidrics line id     
    * @param       o_hid_flg_type            hidrics flg type
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false
    * 
    * @author                               Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 17-Jan-2011
    ********************************************************************************************/
    FUNCTION get_line_hidrics_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        o_hid_flg_type      OUT hidrics.flg_type%TYPE,
        o_error             OUT t_error_out
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

    /********************************************************************************************
    * get_interval_desc              Get the interval description in format: X hours Y minutes,
    *                                given the interval in minutes
    *
    * @param i_lang                  Language ID
    * @param i_interval_minutes      Interval in minutes
    * @param i_msg_hour              Hour message
    * @param i_msg_hours             Hours message
    * @param i_msg_minute            Minute message
    * @param i_msg_minutes           Minutes message
    *
    * @return                        Returns the conversion of Hidric to Date/Time
    *
    * @author                        Sofia Mendes
    * @since                         21-Mar-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_interval_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_interval_minutes IN hidrics_interval.interval_minutes%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if the i_prof.id is the professional that requested the intake/output or if he is a professional
    * that changed the request.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_balance              Balance id        
    *        
    * @return      pls_integer              1-The i_prof is the requesting profesional
    *                                       0-otherwise
    * 
    * @author                               Sofia Mendes
    * @version                               2.6.1
    * @since                                 18-Apr-2011
    ********************************************************************************************/
    FUNCTION check_prof_requested
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_balance IN epis_hidrics_balance.id_epis_hidrics%TYPE
    ) RETURN PLS_INTEGER;

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
        o_hidrics       OUT pk_types.cursor_type,
        o_hidrics_value OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_fluid_balance_takes_string
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_dose               IN VARCHAR2,
        i_dt_take            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_drug_presc_plan IN pk_api_pfh_in.r_presc_plan.id_presc_plan%TYPE,
        i_flg_total          IN VARCHAR2,
        i_unit_measure_desc  IN VARCHAR2,
        i_id_prof_exec       IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get IV fluids to an hidrics balance
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_filter_date            Filter date
    * @param o_pat_medication_list    Medication info 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author  Filipe Silva
    * @since   2011-09-26
    *
    ********************************************************************************************/
    FUNCTION get_fluid_balance_med
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN tf_fluid_balance_med;

    /*******************************************************************************************************************************************
    * Get IV Fluids for Hidrics timeline    
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_FLG_SCOPE              Scope: P -patient; E- episode; V-visit; S-session
    * @param I_SCOPE                  Identifier to be filtered: id_patient - i_flg_scope = 'P', id_visit - i_flg_scope = 'V', id_episode - i_flg_scope = 'E'
    * @param I_START_DATE             Start date to be considered
    * @param I_END_DATE               End date to be considered
    * @param I_EPIS_HIDRICS_IDS       Array of Hidrics Episode Identifiers
    * 
    * @return                         Returns an array type of all fluids beteween the date interval and for the Identifiers of Hidrics Episodes
    * 
    * @author                         Filipe Silva
    * @version                        2.6.1.2
    * @since                          27-September-2011
    * @Notes                         Merge the logic in pk_api_drug.get_fluid_balance_med_rep and pk_api_tr_med.get_fluid_balance_med_rep
    *******************************************************************************************************************************************/
    FUNCTION get_fluid_balance_med_rep
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_scope        IN VARCHAR2,
        i_scope            IN NUMBER,
        i_start_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_epis_hidrics_ids IN table_number
    ) RETURN tf_fluid_balance_med_rep;

    /**********************************************************************************************
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
    * @version                               2.6.1.5
    * @since                                 10-Nov-2011
    **********************************************************************************************/
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check the possibility to be recorded in the system an execution after the task was expired.
    * It was defined that it should be possible to record in the system the last execution made after the task expiration.
    * It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param       i_lang                    Professional preferred language
    * @param       i_prof                    Professional identification and its context (institution and software)
    * @param       i_episode                 Episode ID
    * @param       i_task_request            Task request ID (ID_EPIS_HIDRICS)
    * @param       o_error                   Error information
    *
    * @return                                'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author                                António Neto
    * @version                               2.6.1.5
    * @since                                 10-Nov-2011
    **********************************************************************************************/
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE
    ) RETURN VARCHAR;

    /**********************************************************************************************
    * Returns the "expired hidric" timestamp for a hidric's detail ID
    *
    * @param       i_lang                    Professional preferred language
    * @param       i_prof                    Professional identification and its context (institution and software)
    * @param       i_id_epis_hidrics         Hidric's detail ID
    *
    * @return                                Timestamp of an expired hidric, NULL otherwise.
    *
    * @author                                António Neto
    * @version                               2.6.1.5
    * @since                                 10-Nov-2011
    **********************************************************************************************/
    FUNCTION get_expired_timestamp
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN cpoe_process.dt_cpoe_expired%TYPE;

    /*******************************************************************************************************************************************
    * Checks if there is balances for a hidric episode within a range of dates
    * 
    * @param I_ID_EPIS_HIDRICS        HIDRICS EPISODE ID
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * @param I_CANCELLED              Indicates whether the records should be returned canceled
    * @param I_FLG_REPORT             Flag used to remove formatting
    * 
    * @return                         Returns 'Y' for existing balances otherwise 'N' is returned
    * 
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          10-Nov-2011
    *******************************************************************************************************************************************/
    FUNCTION check_has_balance
    (
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_start_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cancelled       IN VARCHAR2,
        i_flg_report      IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Checks if there is executions for a hidric episode within a range of dates
    * 
    * @param I_ID_EPIS_HIDRICS        HIDRICS EPISODE ID
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * @param I_CANCELLED              Indicates whether the records should be returned canceled
    * @param I_FLG_REPORT             Flag used to remove formatting
    * 
    * @return                         Returns 'Y' for existing executions otherwise 'N' is returned
    * 
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          10-Nov-2011
    *******************************************************************************************************************************************/
    FUNCTION check_has_executions
    (
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_start_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cancelled       IN VARCHAR2,
        i_flg_report      IN VARCHAR2
    ) RETURN VARCHAR2;

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
        o_epis_hid        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get cpoe end date timestamp for a given task type/request
    *
    * @param       I_LANG                    preferred language id for this professional
    * @param       I_PROF                    professional id structure
    * @param       I_ID_EPIS_HIDRICS         Hidrics Episode Identifier
    * @param       I_ACRONYM                 Acronym for the Hidric Type
    *
    * @return      DATE/TIME                 Returns the next expiration date  
    * 
    * @author                                António Neto
    * @version                               2.6.1.5
    * @since                                 10-NOV-2011
    ********************************************************************************************/
    FUNCTION get_cpoe_end_date_by_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_acronym         IN hidrics_type.acronym%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**
    * Get intake and output task description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_epis_hidrics intake and output record identifier
    * @param i_epis_type    current episode type identifier
    *
    * @return               intake and output task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/05/14
    */
    FUNCTION get_task_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics          IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_type             IN episode.id_epis_type%TYPE := NULL,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN CLOB;

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
    ) RETURN hidrics_type.id_hidrics_type%TYPE;

    /**
    * Get hidrics type acronym based on the hidrics type id.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_hidrics_type hidrics type id
    *
    * @return               Hidrics type Identifier
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                2012/05/18
    */
    FUNCTION get_hidric_type_acronym
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE
    ) RETURN hidrics_type.acronym%TYPE;

    /**
    * Returns the most recent ehb id for the same problem
    *
    * @param i_epis_hidrics epis_hidrics ID
    *
    * @return                number with the ehb id 
    *
    * @author                  Paulo Teixeira
    * @since                   2012-08-14
    * @version                 v2.6.2
    */
    FUNCTION get_most_recent_ehb_id(i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE) RETURN NUMBER;

    FUNCTION get_epis_hidrics_grid_value
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis_hidrics         IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_line    IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_hidrics              IN epis_hidrics_line.id_hidrics%TYPE,
        i_flg_type             IN hidrics.flg_type%TYPE,
        i_hidr_unit_measure    IN pk_translation.t_desc_translation,
        i_desc_canceled        IN pk_translation.t_desc_translation,
        i_desc_nr_times        IN pk_translation.t_desc_translation,
        i_desc_proposed        IN pk_translation.t_desc_translation,
        i_dt_begin             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_epis_hidrics_balance IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE
    ) RETURN table_varchar;

    ------
    FUNCTION get_multichoice_lists_pdms
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hid_flg_type IN hidrics.flg_type%TYPE,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE DEFAULT NULL,
        i_way          IN way.id_way%TYPE DEFAULT NULL,
        o_ways         OUT pk_types.cursor_type,
        o_hidrics      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Get the title description to the flowsheet screen.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_hidrics_type           Hidrics type ID
    * @param i_dt_begin               Balance dt begin
    * @param i_dt_end                 Balance dt end
    * @param o_desc                   Flowsheet title description
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.3.8
    * @since                          13/09/2013
    *******************************************************************************************************************************************/
    FUNCTION get_flowsheet_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_desc         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    * get_flowsheet_actions           Get all actions for the flowsheet screen
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_hidrics_type           Hidrics type ID
    * @param O_CREATE_CHILDS          Child actions for the 'Fluid type' option in the create button
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
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_hidrics_type  IN hidrics_type.id_hidrics_type%TYPE,
        o_create_childs OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_epis_status_string
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_hid IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get the last auto balance ID and DT_OPEN_TSTZ
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics ID
    * @param   o_id_epis_hidrics_balance   Last id_epis_hidrics_balance 
    * @param   o_dt_open_tstz              Last dt_open_tstz
    * @param   o_error                     error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Vanessa Barsottelli
    * @version v2.6.5
    * @since   07-04-2016
    */
    FUNCTION get_last_auto_balance_data
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_hidrics            IN epis_hidrics.id_epis_hidrics%TYPE,
        o_id_epis_hidrics_balance OUT epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        o_dt_open_tstz            OUT epis_hidrics_balance.dt_open_tstz%TYPE,
        o_dt_close_balance_tstz   OUT epis_hidrics_balance.dt_close_balance_tstz%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return the last auto balance dt_close_balance_tstz
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics ID
    *
    * @return  dt_close_balance_tstz
    *
    * @author  Vanessa Barsottelli
    * @version v2.6.5
    * @since   07-04-2016
    */
    FUNCTION get_last_auto_bal_dt_close
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN epis_hidrics_balance.dt_close_balance_tstz%TYPE;

    /**
    * Get an array of manual id_epis_hidrics_balance from the last auto balance
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hidrics              Epis hidrics ID
    * @param   i_epis_hidrics_balance      Epis hidrics balance ID
    * @param   i_flg_close_type            Flag of close type
    * @param   i_dt_close_balance_tstz     Close balance date
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Vanessa Barsottelli
    * @version v2.6.5
    * @since   07-04-2016
    */
    FUNCTION get_prev_manual_balances
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics          IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_balance  IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE,
        i_flg_close_type        IN epis_hidrics_balance.flg_close_type%TYPE DEFAULT NULL,
        i_dt_close_balance_tstz IN epis_hidrics_balance.dt_close_balance_tstz%TYPE DEFAULT NULL
    ) RETURN table_number;

    FUNCTION get_total_from_auto_bal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_type     IN hidrics.flg_type%TYPE
    ) RETURN NUMBER;

    FUNCTION get_tt_result_from_auto_bal
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN epis_hidrics.flg_status%TYPE,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_prev_auto_balance
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_bal IN epis_hidrics_balance.id_epis_hidrics_balance%TYPE
    ) RETURN NUMBER;

    FUNCTION get_hidrics_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_task_request_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hidric_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION set_hidric_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hidrics OUT epis_hidrics.id_epis_hidrics%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_hidric_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hidric_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_hidrics_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_hidrics_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN epis_hidrics.id_hidrics_type%TYPE;

    FUNCTION check_hidrics_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN epis_hidrics.id_epis_hidrics%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    * get_next_balance_date           Calculate the next balance date given a data and an interval (in minutes)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_date                   Date
    * @param i_interval_minutes       Interval: nr of minutes
    * 
    * @return                         Next balance calculation date
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
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_interval_minutes IN hidrics_interval.interval_minutes%TYPE
    ) RETURN epis_hidrics.dt_next_balance%TYPE;
    --
    FUNCTION get_oldest_hid(i_episode IN epis_hidrics.id_episode%TYPE) RETURN epis_hidrics_balance.id_epis_hidrics%TYPE;

    FUNCTION get_io_last_auto_balance
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_value   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_hidrics_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_epis_hidrics_ids
    (
        i_id_patient IN epis_hidrics.id_patient%TYPE DEFAULT NULL,
        i_id_visit   IN episode.id_visit%TYPE DEFAULT NULL,
        i_id_episode IN episode.id_episode%TYPE DEFAULT NULL,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN table_number;

    FUNCTION tf_get_epis_hid
    (
        i_id_patient       IN patient.id_patient%TYPE,
        i_epis_hidrics_ids IN table_number DEFAULT NULL,
        i_id_visit         IN episode.id_visit%TYPE DEFAULT NULL,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_start_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN table_t_epis_hid;

    FUNCTION tf_get_reg_hidrics
    (
        i_id_patient       IN epis_hidrics.id_patient%TYPE DEFAULT NULL,
        i_epis_hidrics_ids IN table_number DEFAULT NULL,
        i_id_visit         IN episode.id_visit%TYPE DEFAULT NULL,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL
    ) RETURN table_t_reg_hidrics;

    FUNCTION tf_get_epis_hid_det
    (
        i_id_patient       IN epis_hidrics.id_patient%TYPE,
        i_epis_hidrics_ids IN table_number DEFAULT NULL,
        i_id_visit         IN episode.id_visit%TYPE DEFAULT NULL,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_start_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN table_t_epis_hid_det;

    FUNCTION get_takes_and_outputs_pdms
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_scope        IN VARCHAR2,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_visit         IN visit.id_visit%TYPE,
        i_start_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_scope            IN patient.id_patient%TYPE,
        i_epis_hidrics_ids IN table_number,
        o_epis_hid_det     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hidrics_location_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics_line     IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        i_dt_epis_hid_line_hist IN epis_hidrics_line_hist.dt_epis_hid_line_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- -- -- -- --
    --  Globais --
    -- -- -- -- --
    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);
    --
    g_error        VARCHAR2(2000);
    g_ret          BOOLEAN;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_create_hidrics_action_update CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_create_hidrics_action_new    CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_inp_id_software              CONSTANT NUMBER(24) := 11;

    g_epis_active    CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_cancelled CONSTANT episode.flg_status%TYPE := 'C';

    g_exception EXCEPTION;

END pk_inp_hidrics;
/
