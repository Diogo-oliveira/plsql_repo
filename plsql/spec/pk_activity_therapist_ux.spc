/*-- Last Change Revision: $Rev: 2028437 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_activity_therapist_ux IS

    -- Author  : SOFIA.MENDES
    -- Created : 06-05-2010 14:02:07
    -- Purpose : Activity Therapist UX functions

    /********************************************************************************************
    * Get data for the activity therapist 'my patients' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_grid_my_patients
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get data for the activity therapist 'my specialties' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_grid_my_specialties
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get an episode's follow up notes list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  20-May-2010
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_notes          follow up notes
    * @param i_start_dt       start date
    * @param i_time_spent     time spent
    * @param i_unit_time      time spent unit measure
    * @param i_next_dt        next date
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  20-May-2010
    */
    FUNCTION set_followup_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode      IN management_follow_up.id_episode%TYPE,
        i_notes        IN management_follow_up.notes%TYPE,
        i_start_dt     IN VARCHAR2,
        i_time_spent   IN management_follow_up.time_spent%TYPE,
        i_unit_time    IN management_follow_up.id_unit_time%TYPE,
        i_next_dt      IN VARCHAR2,
        o_mng_followup OUT management_follow_up.id_management_follow_up%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancellation reason
    * @param i_notes          cancellation notes
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  20-May-2010
    */
    FUNCTION set_cancel_followup_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_mng_followup  IN management_follow_up.id_management_follow_up%TYPE,
        i_episode       IN management_follow_up.id_episode%TYPE,
        i_cancel_reason IN management_follow_up.id_cancel_reason%TYPE,
        i_notes         IN management_follow_up.notes_cancel%TYPE,
        o_mng_followup  OUT management_follow_up.id_management_follow_up%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get follow up notes data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up      follow up notes
    * @param o_time_units     time units
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  21-May-2010
    */
    FUNCTION get_followup_notes_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up    OUT pk_types.cursor_type,
        o_time_units   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get data for the activity therapist 'supplies' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param o_grid           output cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_supplies_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the patients that has loaned supplies of a given supply.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param o_grid           output cursor
    * @param o_header         Header text separated by '|'
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  21-Mai-2010
    */
    FUNCTION get_supply_patients
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE,
        o_grid      OUT pk_types.cursor_type,
        o_header    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get inactive activity therapist episodes info.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param i_id_patient     Patient identifier    
    * @param o_epis_inact     output cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  24-Mai-2010
    */
    FUNCTION get_epis_pat_inactive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_epis_inact OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get history detail info of the loans and deliveries of supplies.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure     
    * @param i_id_episode            Episode identifier  
    * @param i_id_supply_workflow    Supply workflow identifier
    * @param i_id_supply             Supply identifier    
    * @param o_sup_workflow_prof     Professional data
    * @param o_sup_workflow     Professional data
    * @param o_error                 error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-Mai-2010
    */
    FUNCTION get_workflow_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply          IN supply.id_supply%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        o_sup_workflow_prof  OUT pk_types.cursor_type,
        o_sup_workflow       OUT pk_types.cursor_type,
        o_header             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get history detail info of the loans and deliveries of supplies.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure     
    * @param i_id_episode            Episode identifier  
    * @param i_id_supply_workflow    Supply workflow identifier
    * @param i_status                Status of the supply_workflow to be used
    * @param o_data                  output cursor
    * @param o_error                 error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-Mai-2010
    */
    /*
    FUNCTION get_history_detail
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_supply  IN supply.id_supply%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;*/

    /**********************************************************************************************
    * List the inactive activity therapy episodes.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Search criteria identifiers.             
    * @param i_crit_val               Search criteria values
    * @param i_dt                     Date to search. If null is passed it is considered the system date
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_inact             Inactive episodes list
    * @param o_mess_no_result         Message to be shown when the search does not produce results  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          26-Mai-2010
    **********************************************************************************************/
    FUNCTION get_epis_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_inact      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates the activity therapy request and the corresponding episode.
    * It is used in the patient search area.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure 
    * @param i_episode        Episode identifier of the parent episode
    * @param i_patient        Patient identifier
    * @param o_opinion        created opinion identifier
    * @param o_opinion_hist   created opinion history identifier    
    * @param o_opinion        opinion identifier
    * @param o_opinion_prof   opinion prof identifier
    * @param o_episode        episode identifier
    * @param o_epis_encounter episode encounter dentifier  
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  27-Mai-2010
    */
    FUNCTION set_request_and_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_opinion        OUT opinion.id_opinion%TYPE,
        o_opinion_hist   OUT opinion_hist.id_opinion_hist%TYPE,
        o_opinion_prof   OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode        OUT episode.id_episode%TYPE,
        o_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if it is necessary to reopen the episode qhen recording loaned supplies, that is, check
    * if the episode is inactive. Is yes, returns a message to be displayed to the user. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode id   
    * @param o_flg_show               Flag: Y - exists message to be shown; N -  otherwise
    * @param o_msg                    Message to be shown
    * @param o_msg_title              Message title      
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          31-Mai-2010 
    **********************************************************************************************/
    FUNCTION check_epis_to_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the discharge schedule date of the parent episode of the activity therapy episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure       
    * @param i_id_episode            Activity Therapy episode identifier
    * @param o_discharge_date        Discharge date    
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  28-Mai-2010
    */
    /*FUNCTION get_discharge_date
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_discharge_date OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;*/

    /*
    * Check if the CREATE button must be enabled
    * in the discharge screen.
    *
    * @param i_lang           language identifier
    * @param i_prof                   professional, software and institution ids
    * @param i_episode        episode identifier
    * @param o_create         'Y' to enable create, 'N' otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION get_discharge_create
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION get_discharge
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get discharge data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharge
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION get_discharge_edit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date    
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  06/Jul/2010
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get time units domains for discharge registration.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param o_time_unit      time units
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  23-Jun-2010
    */
    FUNCTION get_discharge_domains
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_time_unit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the message to be shown in the popup that appears when the Activity Therapist starts 
    * a new Activity Therapy episode (if he has permissions to create requests without approval)
    * or a request to be approved by other professional. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param o_msg_title              Popup title      
    * @param o_msg                    Popup messsage
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          15-Jun-2010 
    **********************************************************************************************/
    FUNCTION get_start_ther_pop_msgs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the discharge schedule date of the parent episode of the activity therapy episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure       
    * @param i_id_episode            Activity Therapy episode identifier
    * @param o_discharge_date        Discharge date (YYYYMMDDHH24MISS)
    * @param o_discharge_date_desc   Discharge date description
    * @param o_discharge_hour_desc   Discharge hour description
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  18-Jun-2010
    */
    FUNCTION get_discharge_date
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_discharge_date_desc OUT VARCHAR2,
        o_discharge_hour_desc OUT VARCHAR2,
        o_discharge_date      OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's EHR Activity Therapy Summary. This includes information of:
    *    - Activity Therapy requests
    *    - Follow up notes
    *    - Supplies
    *    - Activity Therapy end   
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * @param i_scale                  Info of the time interval to be considered: All, Year, Month, Week
    * 
    * @ param o_screen_labels         Labels
    * @ param o_episodes_det          List of patient's episodes
    * @ param o_at_request            Activity Therapy requests   
    * @ param o_follow_up             Follow up notes list
    * @ param o_supplies              Supplies info
    * @ param o_discharge             Activity Therapy dicharge info
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.3
    * @since                           19-Jun-2010
    **********************************************************************************************/
    FUNCTION get_at_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_scale   IN VARCHAR2,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --request
        o_at_request OUT pk_types.cursor_type,
        --followup notes
        o_follow_up OUT pk_types.cursor_type,
        --diets
        o_supplies OUT pk_types.cursor_type,
        --discharge info
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get episode start date.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure       
    * @param i_id_episode            Activity Therapy episode identifier
    * @param o_date                  Episode start date    
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  12-Oct-2010
    */
    FUNCTION get_epis_dt_creation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_date       OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_activity_therapist_ux;
/
