/*-- Last Change Revision: $Rev: 2050146 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-14 15:41:11 +0000 (seg, 14 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_positioning AS

    TYPE t_code_messages IS TABLE OF VARCHAR2(800) INDEX BY sys_message.code_message%TYPE;

    /*******************************************************************************************************************************************
    * Name :                          GET_ROT_INTERV_FORMAT
    * Description:                    Function that returns an duration string in an incorrect format (ex: "01:2" or "2:23") in 
    *                                 the correct format (ex: "01:02" or "02:23")
    * 
    * @param I_ROT_INTERV             Duration of rotation interval in positioning functionality
    * 
    * @author                         Lu�s Maia
    * @version                        1.0
    * @since                          2009/07/09
    *******************************************************************************************************************************************/
    FUNCTION get_rot_interv_format(i_rot_interv IN epis_positioning.rot_interval%TYPE) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Name :                          GET_ROT_INTERV_FORMAT
    * Description:                    Function that returns an duration string in an incorrect format (ex: "01:2" or "2:23") in 
    *                                 the correct format (ex: "01:02" or "02:23")
    * 
    * @param I_ROT_INTERV             Duration of rotation interval in positioning functionality
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.1.1
    * @since                          22-Jun-2011
    *******************************************************************************************************************************************/
    FUNCTION get_fomatted_rot_interv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rot_interv IN epis_positioning.rot_interval%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_posit_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_post_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Register all the requests for positionings
    *
    * @param I_LANG          language id
    * @param I_PROF          professional, software and institution ids
    * @param I_EPISODE       episode id
    * @param I_POSIT         Array with the several positionings
    * @param I_ROT_INTERV    rotation interval duration
    * @param I_ID_ROT_INTERV rotation interval id
    * @param I_FLG_MASSAGE   massage included or not
    * @param I_NOTES         notes
    * @param I_POS_TYPE      type of positioning
    * @param I_FLG_TYPE      flag of positioning
    * @param O_ROWS          list of positionings for the current episode
    * @param O_ERROR         warning/error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Em�lio Taborda
    * @version               v1.0 
    * @since                 15-Nov-2006
    *********************************************************************************************/
    FUNCTION create_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_posit                IN table_number,
        i_rot_interv           IN rotation_interval.interval%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage          IN epis_positioning.flg_massage%TYPE,
        i_notes                IN epis_positioning.notes%TYPE,
        i_pos_type             IN positioning_type.id_positioning_type%TYPE DEFAULT NULL,
        i_flg_type             IN epis_positioning.flg_status%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_positioning  IN epis_positioning.id_epis_positioning%TYPE DEFAULT NULL,
        i_flg_origin           IN VARCHAR DEFAULT 'N',
        i_id_episode_sr        IN episode.id_episode%TYPE DEFAULT NULL,
        o_rows                 OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_id_epis_positioning  IN epis_positioning.id_epis_positioning%TYPE DEFAULT NULL,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_origin               IN VARCHAR2,
        i_id_episode_sr        IN episode.id_episode%TYPE DEFAULT NULL,
        i_filter_tab           IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Function that executes a positioning movement
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_epis_pos          ID_EPISODE to check
    * @param      i_dt_exec_str       date os positioning execution
    * @param      i_notes             execution notes
    * @param      i_rot_interv        rotation interval
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN                         TRUE or FALSE
    * @author                         Em�lia Taborda
    * @version                        2.3.6
    * @since                          2006-Nov-15
    * 
    ****************************************************************************************************/
    FUNCTION set_epis_positioning
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_pos     IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str  IN VARCHAR2,
        i_notes        IN epis_positioning.notes%TYPE,
        i_rot_interv   IN epis_positioning.rot_interval%TYPE DEFAULT NULL,
        i_dt_next_exec IN VARCHAR2 DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_epis_positioning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_positioning
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_epis_pos OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_positioning_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis_pos   IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos_d OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_positioning_concat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis_pos   IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_epis    IN epis_positioning.dt_epis_positioning%TYPE DEFAULT NULL,
        i_flg_report IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION get_epis_posit_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pos      IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos_plan OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_posit_plan_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pos      IN epis_positioning.id_epis_positioning%TYPE,
        i_epis_pos_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        o_epis_pos_pdet OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_posit_plan_rank
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_epis_pos                 IN epis_positioning.id_epis_positioning%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * SET_EPIS_POS_STATUS                    Set an epis_positioning to interrupted
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_pos_status              epis_positioning id
    * @param       i_flg_status              New status ('I' - Discontinued)
    * @param       i_notes                   Status change notes
    * @param       o_error                   error information
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Emilia Taborda                      
    * @version                               2.4.0                             
    * @since                                 2006/Nov/18       
    *
    * @change                                Lu�s Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22    
    ********************************************************************************************/
    FUNCTION set_epis_pos_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status       IN epis_positioning.flg_status%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Return positioning description including all positioning sequence
    *
    * @param      i_lang           language ID
    * @param      i_prof           professional information
    * @param      i_episode        episode ID
    *    
    * @author     Lu�s Maia
    * @version    2.5.0.7
    * @since      2009/11/02
    *
    * @dependencies    This function was developed to Content team
    ***********************************************************************************************************/
    FUNCTION get_all_posit_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Updates existing epis_positioning values                                *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    epis position id                    *
    * @param i_epis_positioning           epis positioning id                 *
    * @param i_posit                      posit id array                      *
    * @param i_rot_interv                 rotation interval value             *
    * @param i_id_rot_interv              rotation interval identifier        *
    * @param i_flg_massage                Massage needed flag                 *
    * @param i_notes                      Notes                               *
    * @param i_pos_type                   Position request type               *
    * @param i_flg_type                   Request identification type         *
    *                                                                         *
    * @param o_error                      Error object                        *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/11/17                              *
    **************************************************************************/
    FUNCTION edit_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_positioning     IN epis_positioning.id_epis_positioning%TYPE,
        i_posit                IN table_number,
        i_rot_interv           IN rotation_interval.interval%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage          IN epis_positioning.flg_massage%TYPE,
        i_notes                IN epis_positioning.notes%TYPE,
        i_pos_type             IN positioning_type.id_positioning_type%TYPE,
        i_flg_type             IN epis_positioning.flg_status%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * activates a set of draft tasks (task goes from draft to active workflow)
    *
    * @param I_LANG          language id
    * @param I_PROF          professional, software and institution ids
    * @param I_EPISODE       episode id
    * @param I_DRAFT         array of selected drafts
    * @param O_ERROR         warning/error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Gustavo Serrano
    * @version               1.0 
    * @since                 17-Nov-2009
    *********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set new episode when executing match functionality                      *
    *                                                                         *
    * @param       i_lang             preferred language id for this          *
    *                                 professional                            *
    * @param       i_prof             professional id structure               *
    * @param       i_current_episode  episode id                              *
    * @param       i_new_episode      array of selected drafts                *
    * @param       o_error            error message                           *
    *                                                                         *
    * @return      boolean            true on success, otherwise false        *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/11/17                              *
    **************************************************************************/
    FUNCTION set_new_match_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get detailed task information to be used in CPOE task history view
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    * @param       i_episode                 episode id
    * @param       i_task_request            task request id
    * @param       o_task_hist_info          cursor with task history info (status changes info)
    * @param       o_task_detail_info        cursor with detailed task info
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    ********************************************************************************************/
    FUNCTION get_task_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_positioning     IN cpoe_process_task.id_task_request%TYPE,
        o_epis_posit_hist_info OUT pk_types.cursor_type,
        o_epis_posit_info      OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_positioning_hist_concat
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_pos IN epis_positioning_det_hist.id_epis_positioning%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * GET_ONGOING_TASKS_POSIT                Get all tasks available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return       tf_tasks_list            table of tr_tasks_list
    *
    * @author                                Lu�s Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22       
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_posit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /**********************************************************************************************
    * get_therapeutic_status         Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status Y/N  N: not proceed with nursing intervention
    *                        
    * @author                        Ant�nio Neto
    * @version                       v2.6.0.5
    * @since                         28-Feb-2011
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

    /*********************************************************************************************
    * Saves the current state of a epis_positioning record to the history table.
    * 
    * @param    i_lang                              Language ID
    * @param    i_prof                              Professional
    * @param    i_id_epis_positioning               table number with epis positioning ID
    * 
    * @param    o_error                             error message
    *    
    * @author              Filipe Silva
    * @version             2.6.1
    * @since               2011/04/06
    **********************************************************************************************/

    FUNCTION set_epis_positioning_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the positioning  detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_positioning       Epis_positioning Id
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.1
    * @since                          11-Apr-2011
    **********************************************************************************************/
    FUNCTION get_epis_positioning_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_screen          IN VARCHAR2,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the fields data to be shown in the detail current information screen 
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning data current record
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_first_values_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN epis_positioning_hist%ROWTYPE,
        i_labels     IN t_code_messages,
        i_flg_screen IN VARCHAR2,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar,
        o_tbl_tags   OUT table_varchar
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the difference between the 
    * different steps performed by the user.
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning_plan data current record
    * @param       i_previous_row            Epis_positioning_plan data previous record 
    * @param       i_labels                  Structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_values_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_actual_row   IN epis_positioning_hist%ROWTYPE,
        i_previous_row IN epis_positioning_hist%ROWTYPE,
        i_labels       IN t_code_messages,
        o_tbl_labels   OUT table_varchar,
        o_tbl_values   OUT table_varchar,
        o_tbl_types    OUT table_varchar,
        o_tbl_tags     OUT table_varchar
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the fields data to be shown in detail current informatio screen 
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning_plan data current record
    * @param       i_counter                 Counter identifier execution plan
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_first_values_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_actual_row IN epis_posit_plan_hist%ROWTYPE,
        i_counter    IN NUMBER,
        i_labels     IN t_code_messages,
        i_flg_screen IN VARCHAR2,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar,
        o_tbl_tags   OUT table_varchar
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get positioning description
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_epis_positioning_det  Epis_positioning_det ID
    *
    * @return      positioning's description
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_positioning_description
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_positioning_det IN epis_positioning_det.id_epis_positioning_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the difference between the 
    * different steps performed by the user.
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning_plan data current record
    * @param       i_previous_row            Epis_positioning_plan data previous record 
    * @param       i_counter                 Counter identifier execution plan
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_values_plan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_actual_row   IN epis_posit_plan_hist%ROWTYPE,
        i_previous_row IN epis_posit_plan_hist%ROWTYPE,
        i_counter      IN NUMBER,
        i_labels       IN t_code_messages,
        o_tbl_labels   OUT table_varchar,
        o_tbl_values   OUT table_varchar,
        o_tbl_types    OUT table_varchar,
        o_tbl_tags     OUT table_varchar
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Saves the current state of a epis_positioning_plan record to the history table.
    * 
    * @param    i_lang                                  Language ID
    * @param    i_prof                                  Professional
    * @param    i_id_epis_positioning_plan              Table number with Epis positioning_plan ID
    *    
    * @author              Filipe Silva
    * @version             2.6.1
    * @since               2011/04/13
    **********************************************************************************************/

    FUNCTION set_epis_posit_plan_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_positioning_plan IN table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the positioning plan detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_positioning       Epis_positioning Id
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.1
    * @since                          13-Apr-2011
    **********************************************************************************************/
    FUNCTION get_epis_positioning_plan_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        i_flg_screen               IN VARCHAR2,
        o_hist                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_posit_plan_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        i_flg_screen               IN VARCHAR2,
        o_hist                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Saves the current state of a epis_positioning_plan record to the history table.
    * 
    * @param    i_lang                                  Language ID
    * @param    i_prof                                  Professional
    * @param    i_id_epis_positioning_det               Table number with Epis positioning_det ID
    *    
    * @author              Filipe Silva
    * @version             2.6.1
    * @since               2011/04/15
    **********************************************************************************************/

    FUNCTION set_epis_posit_det_hist
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_positioning_det IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets an id_epis_positioning interrupt, cancelled or cancelled drafts.
    * This function was merged : set_posit_cancel and set_posit_interrupt
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_epis_pos                epis_positioning id
    * @param       i_flg_status              Flag status
    * @param       i_notes                   Status change notes
    * @param       i_id_cancel_reason        Cancel reason ID
    *
    * @param       o_error                   error information
    *   
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION set_cancel_interrupt_posit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status       IN epis_positioning.flg_status%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get id_epis_positioning_det 
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_epis_positioning     epis_positioning id
    *  
    * @param       o_id_epis_positioning_det    table number with id_epis_positioning_det  
    * @param       o_error                   error information
    *   
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/19       
    ********************************************************************************************/
    FUNCTION get_id_epis_positioning_det
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_positioning     IN table_number,
        o_id_epis_positioning_det OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Synchronize last_update professional and record between epis_positioning and epis_positioning_det 
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_epis_positioning     table_number
    * @param       i_sysdate_tstz            timestamp
    *  
    * @param       o_error                   error information
    *   
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/19       
    ********************************************************************************************/
    FUNCTION sync_epis_positioning_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN table_number,
        i_sysdate_tstz        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author                                Ant�nio Neto
    * @version                               2.5.1.8
    * @since                                 15-Sep-2011
    */
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
    * @param       i_task_request            Task request ID (ID_EPIS_POSITIONING)
    * @param       o_error                   Error information
    *
    * @return                                'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author                                Ant�nio Neto
    * @version                               2.5.1.8
    * @since                                 13-Sep-2011
    **********************************************************************************************/
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
    * Gets the positionings list for reports with timeframe and scope
    *
    * @param   I_LANG                      Language associated to the professional executing the request
    * @param   I_PROF                      Professional Identification
    * @param   I_SCOPE                     Scope ID
    * @param   I_FLG_SCOPE                 Scope type
    * @param   I_START_DATE                Start date for temporal filtering
    * @param   I_END_DATE                  End date for temporal filtering
    * @param   I_CANCELLED                 Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param   I_CRIT_TYPE                 Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param   I_FLG_REPORT                Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param   O_POS                       Positioning list
    * @param   O_POS_EXEC                  Executions for Positioning list
    * @param   O_ERROR                     Error message
    *
    * @value   I_SCOPE                     {*} 'E' Episode ID {*} 'V' Visit ID {*} 'P' Patient ID
    * @value   I_FLG_SCOPE                 {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value   I_CANCELLED                 {*} 'Y' Yes {*} 'N' No
    * @value   I_CRIT_TYPE                 {*} 'A' All {*} 'E' Executions {*} 'R' requests
    * @value   I_FLG_REPORT                {*} 'Y' Yes {*} 'N' No
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              Ant�nio Neto
    * @version                             2.5.1.8.1
    * @since                               29-Sep-2011
    **********************************************************************************************/
    FUNCTION get_positioning_rep
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
        i_flg_status IN table_varchar DEFAULT NULL,
        o_pos        OUT pk_types.cursor_type,
        o_pos_exec   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Checks if there is executions for a positioning episode within a range of dates
    * 
    * @param I_ID_EPIS_POSITIONING    Positioning EPISODE ID
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * 
    * @return                         Returns 'Y' for existing executions otherwise 'N' is returned
    * 
    * @author                         Ant�nio Neto
    * @version                        2.5.1.8.1
    * @since                          29-Sep-2011
    *******************************************************************************************************************************************/
    FUNCTION check_has_executions
    (
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_start_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /**
    * Get positioning task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epis_positioning         diet request identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_description
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_desc_type           IN VARCHAR2
    ) RETURN CLOB;
    /**
    * Get positioning task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epis_positioning         diet request identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_positionings
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_desc_type           IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION inactivate_positioning_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_epis_posit_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN action.from_state%TYPE,
        id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_positioning_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_episode                  IN episode.id_episode%TYPE,
        i_flg_status               IN epis_positioning.flg_status%TYPE,
        i_flg_status_plan          IN epis_positioning_plan.flg_status%TYPE,
        i_dt_creation_tstz         IN epis_positioning.dt_creation_tstz%TYPE,
        i_dt_prev_plan_tstz        IN epis_positioning_plan.dt_prev_plan_tstz%TYPE,
        i_dt_epis_positioning_plan IN epis_positioning_plan.dt_epis_positioning_plan%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_positioning_request_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_positioning_exec_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_epis_positioning_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_positioning_detail_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_cancel_interrupt_posit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_positioning.id_episode%TYPE,
        o_action     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_positioning_rel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_posit_type IN positioning_instit_soft.posit_type%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_error         VARCHAR2(2000);
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char  VARCHAR2(20);
    g_flg_available speciality.flg_available%TYPE;
    g_found         BOOLEAN;
    g_ret           BOOLEAN;
    g_other_exception EXCEPTION;

    --
    g_separador VARCHAR2(500);
    --
    g_epis_active episode.flg_status%TYPE;
    --
    g_epis_posit_r CONSTANT epis_positioning.flg_status%TYPE := 'R';
    g_epis_posit_e CONSTANT epis_positioning.flg_status%TYPE := 'E';
    g_epis_posit_f CONSTANT epis_positioning.flg_status%TYPE := 'F';
    g_epis_posit_c CONSTANT epis_positioning.flg_status%TYPE := 'C';
    g_epis_posit_i CONSTANT epis_positioning.flg_status%TYPE := 'I';
    g_epis_posit_d CONSTANT epis_positioning.flg_status%TYPE := 'D';
    g_epis_posit_l CONSTANT epis_positioning.flg_status%TYPE := 'L';
    g_epis_posit_a CONSTANT epis_positioning.flg_status%TYPE := 'A';
    g_epis_posit_o CONSTANT epis_positioning.flg_status%TYPE := 'O';

    --flg_massage
    g_flg_massage_n CONSTANT epis_positioning.flg_massage%TYPE := 'N';
    g_flg_massage_y CONSTANT epis_positioning.flg_massage%TYPE := 'Y';

    g_yes_no          sys_domain.code_domain%TYPE;
    g_hour_sign       sys_message.code_message%TYPE;
    g_pos_type_s      positioning_type.id_positioning_type%TYPE;
    g_notes_y         VARCHAR2(20);
    g_notes_n         VARCHAR2(20);
    g_epis_pos_status sys_domain.code_domain%TYPE;
    g_flg_doctor      VARCHAR2(20);
    g_date            VARCHAR2(1);

    g_date_value CONSTANT VARCHAR2(1) := 'D';
    g_img_value  CONSTANT VARCHAR2(1) := 'I';
    g_color      CONSTANT VARCHAR2(1) := 'X';

    --Request
    g_id_cmpt_mkt_rel_position     CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3460;
    g_id_cmpt_mkt_rel_rot_interval CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3462;
    g_id_cmpt_mkt_rel_sr_position  CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3473;
    g_id_cmpt_mkt_rel_sr_rot_int   CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3475;
    g_id_cmpt_mkt_rel_sr_limb_pos  CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3478;
    g_id_cmpt_mkt_rel_sr_protec    CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3479;

    --Execution
    g_id_cmpt_mkt_rel_prof_exec  CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3467;
    g_id_cmpt_mkt_rel_start_date CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3468;
    g_id_cmpt_mkt_rel_next_exec  CONSTANT ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := 3469;

    --timeline for reports (ALERT-172572)
    g_posit_crit_type_exec_e CONSTANT VARCHAR2(1 CHAR) := 'E'; --executions
    g_posit_crit_type_req_r  CONSTANT VARCHAR2(1 CHAR) := 'R'; --requisitions
    g_posit_crit_type_all_a  CONSTANT VARCHAR2(1 CHAR) := 'A'; --All

    g_code_flg_status CONSTANT VARCHAR2(32 CHAR) := 'EPIS_POSITIONING_PLAN.FLG_STATUS';

    --DS_COMPONENTS internal names
    g_ds_positioning_list       CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_LIST';
    g_ds_positioning_start_date CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_START_DATE';
    g_ds_positioning_rotation   CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_ROTATION';
    g_ds_positioning_massage    CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_MASSAGE';
    g_ds_positioning_notes      CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_NOTES';
    g_ds_positioning_limb_list  CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_LIMB_LIST';
    g_ds_positioning_protection CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_PROTECTION_LIST';
    g_ds_execution_start_date   CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_EXECUTION_START_DATE';
    g_ds_next_exec              CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_EXECUTION_NEXT_EXEC';

    g_ds_sr_root        CONSTANT VARCHAR2(50 CHAR) := 'DS_SR_POSITIONING';
    g_ds_execution_root CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_EXECUTION_NODE';

    g_flg_origin_n  CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_origin_sr CONSTANT VARCHAR2(2 CHAR) := 'SR';

    g_flg_screen_detail  CONSTANT VARCHAR2(1) := 'D';
    g_flg_screen_history CONSTANT VARCHAR2(1) := 'H';

    g_flg_type_e CONSTANT sr_posit_rel.flg_type%TYPE := 'E';

    g_flg_validation_error CONSTANT VARCHAR2(1 CHAR) := 'E';

END pk_inp_positioning;
/
