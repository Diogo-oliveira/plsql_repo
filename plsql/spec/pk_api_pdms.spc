/*-- Last Change Revision: $Rev: 2028478 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pdms IS

    -- Author  : RUI.TEIXEIRA
    -- Created : 06-10-2010 10:07:38
    -- Purpose : Provide PFH services to PDMS Application

    /***********************************************************************
                            GLOBAL - Generic Functions
    ***********************************************************************/

    /********************************************************************************************
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area. -- 'EXM_CANCEL' - Exams; 'LAB_CANCEL' - Lab
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ********************************************************************************************/
    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN cancel_rea_area.intern_name%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get episodes for a visit
    *
    * @param      I_LANG                     Language identififer
    * @param      I_PROF                     Professional identifier
    * @param      I_VISIT                    Visit identifier
    * @param      I_DT_START                 Start date
    * @param      I_DT_END                   End date
    * @param      O_EPISODES                 Episode list
    * @param      O_ERROR                    Error object
    *
    * @return    TRUE on success or FALSE on error
    *
    * @author Tiago Lourenço
    * @version 2.6.0.4
    * @since 3-Nov-2010
    */
    FUNCTION get_visit_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN institution.id_institution%TYPE,
        i_dt_start IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_episodes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_episode_disposition_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN VARCHAR2;

    /***********************************************************************
                             Events
    ***********************************************************************/

    /*******************************************************************************************************************************************
    * GET_patient_tasks_pdms          Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                 for only one patient (episode and visit)
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_VISIT               ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param I_FLG_METHOD             'R' - Filter by requisition date / 'E' - Filter by execution date
    * @param I_DT_START               Date to filter (lower limit)
    * @param I_DT_END                 Date to filter (higher limit)
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_CUR_LAST_INFO          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    *******************************************************************************************************************************************/
    FUNCTION get_patient_tasks_pdms
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        i_id_visit      IN task_timeline_ea.id_visit%TYPE DEFAULT NULL,
        i_tl_task_list  IN table_number DEFAULT NULL,
        i_flg_method    IN VARCHAR2,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_date_server   OUT VARCHAR2,
        o_patient_tasks OUT pk_types.cursor_type,
        o_cur_last_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Positionings
    *************************************************************************/

    /********************************************************************************************
    * Cancels a positioning given by its epis_positioning id by setting 
    * an epis_positioning to interrupted
    *
    * @param i_lang language id
    * @param i_prof professional information
    * @param i_pos_status epis_positioning id
    * @param i_notes Status change notes
    * @param o_error error information
    *
    * @return boolean true on success, otherwise false
    *
    * @author João Reis
    * @version 2.6.0.4
    * @since 2010-Out-14
    ********************************************************************************************/
    FUNCTION cancel_positioning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Executes a positioning
    *
    * @param i_lang language ID
    * @param i_prof ALERT profissional
    * @param i_epis_pos ID_EPISODE to check
    * @param i_dt_exec_str date os positioning execution
    * @param i_notes execution notes
    * @param i_rot_interv rotation interval
    * @param o_error If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN TRUE or FALSE
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ****************************************************************************************************/
    FUNCTION execute_positioning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_pos    IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str IN VARCHAR2,
        i_notes       IN epis_positioning.notes%TYPE,
        i_rot_interv  IN epis_positioning.rot_interval%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Surgery
    ***********************************************************************/

    /********************************************************************************************
    * Get surgery time for a specific visit.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    *
    * @param o_surgery_time_def Cursor with all type of surgery times.
    * @param o_surgery_times    Cursor with surgery times by visit.
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ********************************************************************************************/

    FUNCTION get_op_times_between_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_dt_end           IN VARCHAR2 DEFAULT NULL,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set surgery times
    *
    * @param i_lang             ID language
    * @param i_prof             Professional, institution and software IDs
    * @param i_sr_surgery_time  List of ID Surgery time type
    * @param i_episode          ID episode
    * @param i_dt_surgery_time  List of Surgery time/date
    * @param i_dt_reg           Record date
    *
    * @param o_flg_show         Show message: Y/N
    * @param o_msg_result       Message to show
    * @param o_title            Message title
    * @param o_button           Buttons to show: NC - Yes/No button
    *                                            C - Read button
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ********************************************************************************************/

    FUNCTION set_operative_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_surgery_time IN table_number,
        i_episode         IN episode.id_episode%TYPE,
        i_dt_surgery_time IN table_varchar,
        o_flg_show        OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_title           OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_flg_refresh     OUT VARCHAR2,
        o_sr_surgery_time OUT sr_surgery_time.id_sr_surgery_time%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Operative Times for a given id Episode 
    *
    * @param i_lang             Language ID
    * @param i_prof             ALERT profissional
    * @param i_episode          Episode ID
    * 
    * @param o_surgery_time_def Definition values for the operative times got from db.
    * @param o_surgery_times    Operative time values cursor.
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   João Reis
    * @since                    2010/11/08
       ********************************************************************************************/
    FUNCTION get_op_times_by_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a default record date for a operative time category of a given episode.
    * The default data is obtained by the last active record, and in case of the lack of this value, returns the system date.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, institution ID and software id
    * @param i_sr_surgery_time  operative time id
    * @param i_episode          episode id
    * 
    * @param o_date             default time date for a given episode id and operative time id
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   João Reis
    * @since                    2010/11/08
       ********************************************************************************************/
    FUNCTION get_op_default_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_surgery_time IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_date            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                           TASKS
    ***********************************************************************/

    /*******************************************************************************************************************************************
    * Name:                           get_tasks_type
    * Description:                    Function that return the list of available tasks in table TL_TASK for current timeline and professional
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param O_TL_TASKS               Cursor with information about available tasks in selected task timeline for current professional
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         João Reis
    * @version                        2.6.0.4
    * @since                          2010-Out-14
    *******************************************************************************************************************************************/
    FUNCTION get_tasks_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_tl_tasks OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Movements
    ***********************************************************************/

    /*
    * Start movement or end movement based in the current status
    *
    * @param     i_lang            Language id
    * @param     i_movement        Moviment id
    * @param     i_prof            Professional
    * @param     o_error           Error message
    
    * @return    string on success or error
    *
    * @author Tiago Lourenço
    * @version 2.6.0.4
    * @since 20-Out-2010
    */
    FUNCTION set_movement
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Backoffice functions
    ***********************************************************************/

    /*
    * Get softwares available for institution
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      o_software                 Cursor com a lista de Perfis 
    * @param      O_ERROR                    Erro
    *
    * @return    string on success or error
    *
    * @author Rui Teixeira e João Reis
    * @version 2.6.0.4
    * @since 26-Out-2010
    */
    FUNCTION get_institution_software
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Severity Scores functions
    ***********************************************************************/

    /********************************************************************************************
    * Get Severit Scores for a given date period and visit id. 
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    *
    * @param o_sev_scoress      cursor with severity score values and definitions
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author João Reis
    * @version 2.6.0.4
    * @since 2010-DEZ-20
    ********************************************************************************************/

    FUNCTION get_sev_scores_between_dates
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_visit    IN visit.id_visit%TYPE,
        i_dt_begin    IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        o_sev_scoress OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Shortcuts functions
    ***********************************************************************/

    /********************************************************************************************
    * Get shortcuts available for a professional
    *
    * @param i_lang                 Id language
    * @param i_prof                 Professional, software and institution ids
    * @param i_list_shrtcut_id      Shortcuts identifiers
    *
    * @param o_shortcuts            Cursor with shortcut id's
    * @param o_error                Error message
    *
    * @return                       TRUE/FALSE
    *
    * @author Miguel Gomes
    * @version 2.6.4.3
    * @since 2014-Nov-06
    ********************************************************************************************/
    FUNCTION get_shortcuts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_list_shrtcut_id IN table_number,
        o_shortcuts       OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all episode related data that is need on PDMS
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_episode       Episode identifier
    *
    * @param o_data             Response with data from episode and visit
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Nov-19
    ********************************************************************************************/
    FUNCTION get_epis_data_for_pdms
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Cancel severity score
    *
    * @param   I_LANG - Professional language
    * @param   I_PROF - Profissional 
    * @param   I_ID_EPISODE - Episode
    * @param   I_EPIS_MTOS_SCORE - Severity score evaluation ID
    * @param   I_ID_CANCEL_REASON - Razão de cancelamento
    * @param   I_NOTES - Notas
    * @param   O_ERROR - error
    * 
    * @author                Rui Teixeira
    * @version               2.6.1.1
    * @since                 2011/05/26
    * *********************************************************************************/
    FUNCTION cancel_sev_score
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_epis_mtos_score  IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN epis_mtos_score.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient data to ALERT CAP from barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_institution         Institution identifier
     * @param i_barcode                Barcode
     * @param o_result                 Patient data
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
    *
    * @author                Rui Teixeira
    * @version               2.6.0.5
    * @since                 2011/02/23
    ********************************************************************************************/
    PROCEDURE get_cap_barcode_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof_id        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof_soft      IN software.id_software%TYPE,
        i_barcode        IN episode.barcode%TYPE,
        o_result         OUT pk_types.cursor_type
    );

    /********************************************************************************************
     * Get patient data to ALERT Gateway from barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_institution         Institution identifier
     * @param i_barcode                Barcode
     * @param o_result                 Patient data
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
    *
    * @author                Rui Teixeira
    * @version               2.6.3.8.3
    * @since                 2012/10/17
    ********************************************************************************************/
    PROCEDURE get_gw_barcode_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof_id        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof_soft      IN software.id_software%TYPE,
        i_barcode        IN episode.barcode%TYPE,
        o_result         OUT pk_types.cursor_type
    );

    /********************************************************************************************
     * Get patient data to ALERT Gateway from barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_institution         Institution identifier
     * @param i_barcode                Barcode
     * @param o_result                 Patient data
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
    *
    * @author                Rui Teixeira
    * @version               2.6.3.8.3
    * @since                 2012/10/17
    ********************************************************************************************/
    PROCEDURE get_gw_barcode_data2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof_id        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof_soft      IN software.id_software%TYPE,
        i_barcode        IN episode.barcode%TYPE,
        o_photo          OUT BLOB,
        o_result         OUT pk_types.cursor_type
    );
    /***********************************************************************
                            HIDRICS
    ***********************************************************************/

    /********************************************************************************************
    * Get hidrics values between dates for a specific visit.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    *
    * @param o_hidrics_def    cursor with the intake and output fluids for the given period
    * @param o_hidrics_values   cursor with the values of the intakes and outputs for the given period
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author João Reis
    * @version 2.6.1.2
    * @since 2011-Jun-13
    ********************************************************************************************/
    FUNCTION get_hidrics_between_dates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_visit       IN visit.id_visit%TYPE,
        i_dt_begin       IN VARCHAR2 DEFAULT NULL,
        i_dt_end         IN VARCHAR2 DEFAULT NULL,
        o_hidrics_def    OUT pk_types.cursor_type,
        o_hidrics_values OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get hidrics values.
    *
    * @param i_lang             Id language
    * @param i_par              Parent
    * @param i_flg_type         Hidrics flag type
    *
    * @param o_hidrics_val      Values of hidrics
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Miguel Gomes
    * @version 2.6.3.9
    * @since 2013-AGO-29
    ********************************************************************************************/
    FUNCTION get_hidric_ways
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN way.flg_type%TYPE,
        o_hidric_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the episode software
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_episode      Episode identifier
    *
    * @return  ID_SOFTWARE
    *
    * @author Rui Teixeira
    * @version 2.6.2.1.1
    * @since 2012-May-18
    ********************************************************************************************/
    FUNCTION get_software_by_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN software.id_software%TYPE;

    /**********************************************************************************************
    * Gets all event types 
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_events                 Selected event types.
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.9
    * @since        2013-08-28
    **********************************************************************************************/
    FUNCTION get_pdms_event_type_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_events OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets hidrics detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_episode                  Episode identifier
    * @param        i_epis_hidrics             
    * @param        o_epis_hid  
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_hidrics_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_flg_screen       IN VARCHAR2,
        o_hist             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets positioning detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_id_episode               Episode identifier
    * @param        i_id_epis_positioning      
    * @param        i_flg_screen  
    * @param        o_hist                     Historico
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_positioning_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_screen          IN VARCHAR2,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets severity score detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_id_episode               Episode identifier
    * @param        o_reg                      
    * @param        o_value                    
    * @param        o_cancel
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_sev_score_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_value           OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets transport (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_movement                 Transport identifier
    * @param        o_mov
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_transport_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_movement IN movement.id_movement%TYPE,
        o_mov      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************
                            Patient Location functions
    ***********************************************************************/
    /**********************************************************************************************
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
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   07-Jan-2014
    *
    **********************************************************************************************/
    FUNCTION get_departments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_deps  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *
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
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   07-Jan-2014
    *
    **********************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2,
        o_rooms              OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
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
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   07-Jan-2014
    *
    **********************************************************************************************/
    FUNCTION get_beds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_room     IN room.id_room%TYPE,
        i_flg_type IN bed.flg_type%TYPE,
        o_beds     OUT NOCOPY pk_types.cursor_type,
        o_error    OUT t_error_out
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
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   13-Fev-2014
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
    * Returns patient information by bed identifier.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_bed               bed identifier
    * @param      o_result            Y/N : Yes for existing bed associated to a patient, no for any bed associated
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   14-Fev-2014
    *
    ****************************************************************************************************/
    FUNCTION get_patient_by_bed
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_bed    IN bed.id_bed%TYPE,
        o_result OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE vital_signs__________________(i_lang IN language.id_language%TYPE);

    /************************************************************************************************************
    * get_pdms_module_vital_signs
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient identifier
    * @param      i_flg_view                  default view
    * @param      i_tb_vs                     vital sign identifier search table
    * @param      i_tb_view                   flag view search table  
    * @param      o_vs                        cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/20
    ***********************************************************************************************************/

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_tb_vs    IN table_number DEFAULT NULL,
        i_tb_view  IN table_varchar DEFAULT NULL,
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get Vital Signs Record for a visit between a date interval
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_visit               Visit id
    * @param        i_id_vs                  Vital sign ids to return
    * @param        i_dt_begin               
    * @param        i_dt_end                 
    * @param        o_vs                     Vital signs records output cursor
    * @param        o_vs_parent              Vital signs
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       João Reis
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/
    FUNCTION get_vs_between_dates
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_visit  IN visit.id_visit%TYPE,
        i_id_vs     IN table_number DEFAULT NULL,
        i_dt_begin  IN VARCHAR2 DEFAULT NULL,
        i_dt_end    IN VARCHAR2 DEFAULT NULL,
        o_vs        OUT pk_types.cursor_type,
        o_vs_parent OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set Vital Signs Record for a visit between a date interval with Attributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode ID
    * @param        i_id_vs                  table of param ids
    * @param        i_value_vs               table of vital signs values
    * @param        i_dt_vs                  table of vital signs date values                
    * @param        i_insert                 If is to insert values
    * @param        i_tbtb_attribute         List of attributes selected
    * @param        i_tbtb_free_text         List of free text for each attribute
    * @param        o_id_vs                  Vital signs values ids of the External System (ALERT)
    * 
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION set_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN vital_sign_read.id_episode%TYPE,
        i_id_vs          IN table_number,
        i_value_vs       IN table_number,
        i_id_um          IN table_number,
        i_dt_vs          IN table_varchar,
        i_id_scales      IN table_number,
        i_insert         IN VARCHAR,
        i_tbtb_attribute IN table_table_number,
        i_tbtb_free_text IN table_table_clob,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the vital sign attrributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign          Vital sign identifier
    * @param        i_id_vital_sign_read     Vital sign read identifier
    * @param        o_vs_options             
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attributes      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Edit Vital Signs Records with Attributes
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read        Date when vital sign was read
    * @param        i_tbtb_attribute          List of attributes selected
    * @param        i_tbtb_free_text          List of free text for each attribute
    * @param        o_error                   Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION edit_vital_signs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN table_number,
        i_value              IN table_number,
        i_id_unit_measure    IN table_number,
        i_dt_vital_sign_read IN VARCHAR2,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        o_id_vsr             OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel a Vital Sign Value
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_vital_sign_read        Id of Vital Sign value Read
    * 
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       João Reis
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/
    FUNCTION cancel_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        i_notes           IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the the most adquate vital sign to register
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient identifier
    * @param        i_vital_signs            Matrix with vital signs
    * @param        o_selected               Selected vital signs from matrix.
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-19
    **********************************************************************************************/
    FUNCTION get_pdms_vital_sign_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_vital_signs IN table_table_number,
        o_selected    OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
      * Gets the PFH vital signs by identifiers
      *
      * @param        i_lang                   Language id
      * @param        i_prof                   Professional, software and institution ids
      * @param        i_vs_ids                 Vital signs identifiers
      * @param        o_vital_s                Patient vital signs conf
      * @param        o_error                  Error information
      *
      * @return       TRUE if sucess, FALSE otherwise
      *                        
      * @author       Miguel Gomes
      * @version      2.6.3.12
      * @since        2014-03-17
    **********************************************************************************************/

    FUNCTION get_pdms_module_vs_by_ids
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vs_ids  IN table_number,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the all PFH vital signs views to PDMS
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_vital_s                Patient vital signs conf
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.2
    * @since        2012-11-19
    **********************************************************************************************/

    FUNCTION get_all_vital_signs_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the options for vital signs (multi-choice)
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_vital_s                Patient vital signs conf
    * @param        i_id_vs                  Vital sign ID
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.2
    * @since        2012-11-19
    **********************************************************************************************/
    FUNCTION get_vs_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vs   IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the vital sign attrributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign          Vital sign identifier
    * @param        o_vs_attribute           
    * @param        o_vs_options             
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-01
    **********************************************************************************************/
    FUNCTION get_vs_attribute
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attribute  OUT pk_types.cursor_type,
        o_vs_options    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the options for vital signs (multi-choice)
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Read identifier
    * @param        i_detail_type            D - Actual detail, H - History detail
    * @param        o_hist                   Histórico do valor
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-01
    **********************************************************************************************/
    FUNCTION get_vs_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_detail_type        IN VARCHAR2,
        o_hist               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE lab_tests___________________(i_lang IN language.id_language%TYPE);

    /*
    * Cancels a lab test request
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_notes              Cancellation notes
    * @param     i_cancel_reason      Cancel reason id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    João Reis
    * @version   2.6.0.4
    * @since     2010/10/22
    */

    FUNCTION cancel_lab_test
    (
        i_lang             IN language.id_language%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_prof             IN profissional,
        i_notes            IN analysis_req_det.notes_cancel%TYPE,
        i_cancel_reason    IN analysis_req_det.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of lab tests' results for a patient within a visit (results view)
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id
    * @param     i_visit              Visit id
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_flg_type           Flag that indicates which date is shown: H - Harvest date; R - Result date
    * @param     i_dt_min             Minimum date
    * @param     i_dt_max             Maximum date
    * @param     o_result_gridview    Cursor
    * @param     o_result_graphview   Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Rui Teixeira
    * @version   2.6.0.4
    * @since     2010/10/06
    */

    FUNCTION get_lab_test_results
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        o_result_gridview  OUT pk_types.cursor_type,
        o_result_graphview OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN; /*
    * Returns a lab test detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     i_detail_type                   Flag that indicates the detail type
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/20
    */

    FUNCTION get_lab_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_detail_type                 IN VARCHAR2,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_harvest                       Harvest id
    * @param     i_detail_type                   Flag that indicates the detail type
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/20
    */

    FUNCTION get_lab_harvest_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        i_detail_type                 IN VARCHAR2,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test result detail
    *
    * @param     i_lang                         Language id
    * @param     i_prof                         Professional
    * @param     i_analysis_result_par          Lab test parameter result id
    * @param     o_lab_test_result              Cursor
    * @param     o_lab_test_result_laboratory   Cursor
    * @param     o_lab_test_result_history      Cursor
    * @param     o_error                        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_result_detail
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_analysis_result_par        IN table_number,
        o_lab_test_result            OUT pk_types.cursor_type,
        o_lab_test_result_laboratory OUT pk_types.cursor_type,
        o_lab_test_result_history    OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_tests_by_type
    (
        i_type            IN VARCHAR2,
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_group  IN analysis_group.id_analysis_group%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_category_lab_tests
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sample_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_group_lab_tests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_order_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE exams_____________________(i_lang IN language.id_language%TYPE);

    /*
    * Cancels an exam detail order
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam_req_det    Exam detail order id
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_notes_cancel    Cancellation notes
    * @param     i_prof_order      Professional that ordered the exam cancelation (co-sign)
    * @param     i_dt_order        Date of the exam cancelation (co-sign)
    * @param     i_order_type      Type of cancelation (co-sign)  
    * @param     i_flg_schedule    Flag that indicates if there is an exam schedule to be cancelled
    * @param     o_error           Error message
    
    * @return    string on success or error
    *
    * @author    Miguel Gomes
    * @version   2.6.3.4
    * @since     2014/11/10
    */

    FUNCTION cancel_exams
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN table_number,
        i_cancel_reason IN table_number,
        i_notes_cancel  IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     i_detail_type               Flag that indicates the detail type
    * @param     o_exam_order                Cursor
    * @param     o_exam_co_sign              Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_exam_perform              Cursor
    * @param     o_exam_result               Cursor
    * @param     o_exam_result_images        Cursor
    * @param     o_exam_doc                  Cursor
    * @param     o_exam_review               Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Rui Teixeira
    * @version   2.6.3.8.4
    * @since     2013/11/04
    */

    FUNCTION get_exams_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_detail_type             IN VARCHAR2,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE procedures_________________(i_lang IN language.id_language%TYPE);

    /*
    * Cancels a procedure request.(PDMS)
    *
    * @param i_lang                 Language ID
    * @param i_interv_presc_det     Request ID
    * @param i_prof                 Professional
    * @param i_dt_cancel_str        Cancelling date (should only be not null if function is called from header's cancelling function)
    * @param i_notes_cancel         Cancelling notes
    * @param i_id_cancel_reason     Cancel reason
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author Fernando Cardoso
    * @version 2.6.1.6
    * @since 13-Dec-2011
    */

    FUNCTION cancel_interv_presc_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_dt_cancel_str    IN VARCHAR2,
        i_notes_cancel     IN interv_presc_det.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
     * Cancels a procedure's session.(PDMS)
     *
     * @param i_lang                 Language ID
     * @param i_interv_presc_plan    Plan ID
     * @param i_dt_plan              New planned date
     * @param i_prof                 Professional
     * @param i_notes                Notes
     * @param i_id_cancel_reason     Cancel reason
     * @param o_error                Error message
     *
     * @return                       True if success, false otherwise
     * 
     * @author                       Fernando Cardoso
     * @version                      2.6.1.6
     * @since                        2011/12/13
    */

    FUNCTION cancel_interv_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_plan           IN VARCHAR2,
        i_notes             IN epis_interv.notes%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get preview date for next procedure.
    *
    * @param   I_LANG      - Professional language
    * @param   I_PROF      - Profissional    
    * @param   I_PROCEDURE - ID of procedure
    * @param   O_TREAT     - cursor which has the preview treatment date
    * @param   O_ERROR     - error
    * 
    * @author                Fernando Cardoso
    * @version               2.6.1.6
    * @since                 2011/12/19
    */

    FUNCTION get_aux_cancel_take
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets procedures detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_patient                  Patient identifier
    * 
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    */

    FUNCTION get_interv_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_nurse_activity
    (
        i_lang             IN language.id_language%TYPE,
        i_req_det          IN nurse_activity_req.id_nurse_activity_req%TYPE,
        i_prof             IN profissional,
        i_notes            IN nurse_activity_req.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_wound_treat
    (
        i_lang             IN language.id_language%TYPE,
        i_wtreat           IN wound_treat.id_wound_treatment%TYPE,
        i_prof             IN profissional,
        i_notes            IN nurse_activity_req.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_next_str      IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_aux_cancel_treat
    (
        i_lang           IN language.id_language%TYPE,
        i_id_wound_treat IN wound_treat.id_wound_treatment%TYPE,
        i_prof           IN profissional,
        o_treat          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dressing_detail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN nurse_activity_req.id_episode%TYPE,
        i_req    IN nurse_actv_req_det.id_nurse_actv_req_det%TYPE,
        o_nactiv OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE medication_________________(i_lang IN language.id_language%TYPE);

    /*
    * Function for get all action for a prescription or administration
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)    
    * @param   i_id_patient                Patient Identifier
    * @param   i_id_episode                Episode Identifier
    * @param   i_id_presc                  Prescription Identifier
    * @param   i_id_presc_plan             Prescription Plan Identifier 
    * @param   i_id_presc_plan_task        Prescription Plan Task Identifier             
    * @param   i_id_print_group            Print Group Identifier
    * @param   i_flg_action_type           Flag action type
    * @param   o_action                    All Actions and availability
    * @param   o_error                     Error information
    *
    * @return  boolean                     True on sucess, otherwise false                    
    *
    * @author  miguel.gomes
    * @since   28-10-2014
    */

    FUNCTION get_med_actions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN presc.id_patient%TYPE,
        i_id_episode         IN presc.id_epis_create%TYPE,
        i_id_presc           IN table_number,
        i_id_presc_plan      IN table_number,
        i_id_presc_plan_task IN table_number,
        i_id_print_group     IN table_number,
        i_flg_action_type    IN VARCHAR2,
        o_action             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get Medication Prescriptions / Administrations between dates by visit id.
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient ID
    * @param        i_dt_begin               Begin date for administration records
    * @param        i_dt_end                 End date for administration records
    * @param        o_presc_info             Prescription data
    * @param        o_drug_info              Drug Administration data
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       João Reis
    * @version      2.6.0.4
    * @since        02-Dez-2010
    */

    FUNCTION get_med_between_dates
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_dt_begin     IN VARCHAR2 DEFAULT NULL,
        i_dt_end       IN VARCHAR2 DEFAULT NULL,
        i_filter_types IN table_number,
        i_filter_items IN table_number,
        o_presc_info   OUT pk_types.cursor_type,
        o_drug_info    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    /*
    * Gets the frequency units
    *
    * @ param i_lang                     Language
    * @ param i_prof                     Professional
    * @ param o_duration_units
    * @ param o_error                    Error message
    *
    * @return                            TRUE if success and FALSE otherwise
    *
    * @author                João Reis
    * @version               2.6.0.5
    * @since                 23-Dez-2010
    */

    FUNCTION get_med_freq_units
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_duration_units OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Hold local prescription
    *
    * @ param i_lang              language
    * @ param i_prof              professional    
    * @ param i_id_presc          prescription
    * @ param i_dt_hold_begin     i_dt_hold_begin
    * @ param i_dt_hold_end       i_dt_hold_end
    * @ param i_id_cancel_reason  i_id_cancel_reason
    * @ param i_cancel_reason     cancel reason
    * @ param i_notes             notes
    *   
    * @ return              boolean
    *
    * @author                João Reis
    * @version               2.6.0.5
    * @since                 2011/01/06
    */

    FUNCTION hold_med_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN table_number,
        i_dt_hold_begin    IN VARCHAR2,
        i_dt_hold_end      IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Hold local administration
    *
    * @ param i_lang              language
    * @ param i_prof              professional    
    * @ param i_id_presc          prescription
    * @ param i_id_presc_plan     prescription plan
    * @ param i_dt_suspend        suspend date
    * @ param i_id_cancel_reason  i_id_cancel_reason
    * @ param i_cancel_reason     cancel reason
    * @ param i_notes             notes
    *   
    * @ return              boolean
    *
    * @author                Rui Teixeira
    * @version               2.6.2
    * @since                 2011/10/26
    */

    FUNCTION hold_med_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_presc_plan    IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_dt_suspend       IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resume Local Prescription
    *
    * @ param i_lang              language
    * @ param i_prof              professional    
    * @ param i_id_presc          prescription
    * @ param i_dt_resume_begin   dt_resume_begin
    * @ param i_notes             notes
    *   
    * @ return              boolean
    *
    * @author                João Reis
    * @version               2.6.0.5
    * @since                 2011/01/06
    */

    FUNCTION resume_med_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN drug_presc_det.id_drug_presc_det%TYPE,
        i_dt_resume_begin IN VARCHAR2,
        i_notes           IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resume Local Administration
    *
    * @ param i_lang              language
    * @ param i_prof              professional    
    * @ param i_id_presc          prescription
    * @ param i_id_presc_plan     prescription
    *   
    * @ return              boolean
    *
    * @author                Miguel Gomes
    * @version               2.6.4
    * @since                 2014/05/27
    */

    FUNCTION resume_med_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_presc_plan    IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_id_resume_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_resume_reason    IN VARCHAR2,
        i_notes_resume     IN VARCHAR2,
        i_dt_resume        IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Discontinue local prescription
    *
    * @ param i_lang              language
    * @ param i_prof              professional    
    * @ param i_id_presc          prescription
    * @ param i_id_cancel_reason  i_id_cancel_reason
    * @ param i_cancel_reason     cancel reason
    * @ param i_notes             notes
    *   
    * @ return                    boolean
    *
    * @author                João Reis
    * @version               2.6.0.5
    * @since                 2011/01/06
    */

    FUNCTION discontinue_med_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel local prescription
    *
    * @param i_lang              language
    * @param i_prof              professional    
    * @param i_id_presc          prescription
    * @param i_id_cancel_reason  i_id_cancel_reason
    * @param i_cancel_reason     cancel reason
    * @param i_notes             notes
    * @param i_flg_commit        controls if do commit after execution or not    
    *   
    * @return              boolean
    *
    * @author                João Reis
    * @version               2.6.0.5
    * @since                 2011/01/06
    */

    FUNCTION cancel_med_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel an administration.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_presc               Prescription ID
    * @param i_id_presc_plan          Planned administration ID
    * @param i_id_cancel_reason       i_id_cancel_reason
    * @param i_cancel_reason          cancel reason
    * @param i_notes                  Cancel notes
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                João Reis
    * @version               2.6.0.5
    * @since                 2011/01/11
    */

    FUNCTION cancel_med_take
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_presc            IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_presc_plan       IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_id_cancel_reason    IN drug_presc_plan.id_cancel_reason%TYPE,
        i_cancel_reason_descr IN VARCHAR2,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets medication task detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * 
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    */

    FUNCTION get_med_task_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_detail_type        IN VARCHAR2,
        i_id_detail          IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_presc_plan      IN NUMBER, --presc_plan.id_presc_plan%type ( no grants)
        i_id_presc           IN table_number,
        i_id_presc_plan_task IN NUMBER, --presc_plan_task.id_presc_plan_task%type ( no grants)
        o_cur_data           OUT pk_types.cursor_type,
        o_cur_tables         OUT table_table_varchar,
        o_header_presc       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE events_________________(i_lang IN language.id_language%TYPE);

    FUNCTION get_pdms_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
        i_flg_report    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pdms_cases
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
        i_flg_report    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_episode_code_domain CONSTANT sys_domain.code_domain%TYPE := 'EPISODE.FLG_STATUS';

END pk_api_pdms;
/
