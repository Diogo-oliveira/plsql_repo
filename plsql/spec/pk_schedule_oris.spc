/*-- Last Change Revision: $Rev: 2028958 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_oris IS

    /**********************************************************************************************
    * This function converts days on hour:min format
    *
    * @param i_lang                          Language ID
    * @param i_days                          number of days
    *
    * @return                                formated HH24:MI
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION days_to_hourmin
    (
        i_lang IN language.id_language%TYPE,
        i_days IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns a value from 1 to 7 identifying the day of the week, where
    * Monday is 1 and Sunday is 7.
    * Note: In Oracle, depending on the NLS_Territory setting, different days of the week are 1.
    * Examples:
    *   U.S., Canada, Monday = 2;  Most European countries, Monday = 1;
    *   Most Middle-Eastern countries, Monday = 3.
    *   For Bangladesh, Monday = 4.
    *
    * @param i_date          Input date parameter
    *
    * @return                Return the day of the week
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION week_day_standard(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER;

    FUNCTION get_dep_clin_serv_name
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_dep_clin_serv       dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_month_abrev
    (
        i_lang        IN language.id_language%TYPE,
        i_month_index IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_total_slothours
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION round_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION create_slots
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Function to return the color for use in sessions / schedules
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_id_dcs                    Dep_clin_serv ID
    * @param i_flg_urgency               Flag urgency
    * @param i_flg_sch                   Flag Schedule (Y or N)
    * @param i_date                      Date
    *
    * @return                                table number - UNION result
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_color
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_dcs      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_urgency VARCHAR2,
        i_flg_sch     VARCHAR2,
        i_date        TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_sr_dep_list
    (
        i_lang     IN language.id_language%TYPE,
        i_id_inst  IN institution.id_institution%TYPE,
        o_dep_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_rooms
    (
        i_lang      IN language.id_language%TYPE,
        i_id_dep    IN department.id_department%TYPE,
        o_room_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_scheduling_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_timetable_layout
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_date         IN VARCHAR2,
        i_dept_ids     IN table_number,
        i_room_ids     IN table_number,
        i_flg_interval IN VARCHAR2,
        o_rooms        OUT pk_types.cursor_type,
        o_begin_hour   OUT VARCHAR2,
        o_scale_cursor OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_timetable_daily_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_date        IN VARCHAR2,
        i_dept_ids    IN table_number,
        i_room_ids    IN table_number,
        o_header_text OUT VARCHAR2,
        o_daily_info  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_timetable_weekly_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        i_dept_ids       IN table_number,
        i_room_ids       IN table_number,
        o_header_text    OUT VARCHAR2,
        o_scale_cursor   OUT pk_types.cursor_type,
        o_cursor_weekend OUT pk_types.cursor_type,
        o_weekly_info    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_dep_from_room(i_id_room IN room.id_room%TYPE) RETURN NUMBER;

    FUNCTION get_dep_name_from_room
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_session_status(i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE) RETURN VARCHAR;

    FUNCTION get_listview_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN VARCHAR2,
        i_dept_ids      IN table_number,
        i_room_ids      IN table_number,
        i_flg_interval  IN VARCHAR2,
        o_header_text   OUT VARCHAR2,
        o_listview_info OUT pk_types.cursor_type,
        o_colors        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ins_schedule_sr
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        id_schedule_sr_in         IN schedule_sr.id_schedule_sr%TYPE DEFAULT NULL,
        id_sched_sr_parent_in     IN schedule_sr.id_sched_sr_parent%TYPE DEFAULT NULL,
        id_schedule_in            IN schedule_sr.id_schedule%TYPE DEFAULT NULL,
        id_episode_in             IN schedule_sr.id_episode%TYPE DEFAULT NULL,
        id_patient_in             IN schedule_sr.id_patient%TYPE DEFAULT NULL,
        duration_in               IN schedule_sr.duration%TYPE DEFAULT NULL,
        id_diagnosis_in           IN schedule_sr.id_diagnosis%TYPE DEFAULT NULL,
        id_speciality_in          IN schedule_sr.id_speciality%TYPE DEFAULT NULL,
        flg_status_in             IN schedule_sr.flg_status%TYPE DEFAULT NULL,
        flg_sched_in              IN schedule_sr.flg_sched%TYPE DEFAULT NULL,
        id_dept_dest_in           IN schedule_sr.id_dept_dest%TYPE DEFAULT NULL,
        prev_recovery_time_in     IN schedule_sr.prev_recovery_time%TYPE DEFAULT NULL,
        id_sr_cancel_reason_in    IN schedule_sr.id_sr_cancel_reason%TYPE DEFAULT NULL,
        id_prof_cancel_in         IN schedule_sr.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in           IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
        id_prof_reg_in            IN schedule_sr.id_prof_reg%TYPE DEFAULT NULL,
        id_institution_in         IN schedule_sr.id_institution%TYPE DEFAULT NULL,
        adw_last_update_in        IN schedule_sr.adw_last_update%TYPE DEFAULT NULL,
        dt_target_tstz_in         IN schedule_sr.dt_target_tstz%TYPE DEFAULT NULL,
        dt_interv_preview_tstz_in IN schedule_sr.dt_interv_preview_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_in         IN schedule_sr.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_waiting_list_in        IN schedule_sr.id_waiting_list%TYPE DEFAULT NULL,
        flg_temporary_in          IN schedule_sr.flg_temporary%TYPE DEFAULT NULL,
        icu_in                    IN schedule_sr.icu%TYPE DEFAULT NULL,
        --id_pos_status_in          IN schedule_sr.id_sr_pos_status%TYPE DEFAULT NULL,
        notes_in IN schedule_sr.notes%TYPE DEFAULT NULL,
        --admission_need_in         IN schedule_sr.admission_need%TYPE DEFAULT NULL,
        --cont_danger_in            IN schedule_sr.cont_danger%TYPE DEFAULT NULL,
        --ext_discipline_in         IN schedule_sr.ext_discipline%TYPE DEFAULT NULL,
        id_schedule_sr_out OUT schedule_sr.id_schedule_sr%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_schedule_sr
    (
        i_lang                     IN language.id_language%TYPE,
        id_schedule_sr_in          IN schedule_sr.id_schedule_sr%TYPE DEFAULT NULL,
        id_sched_sr_parent_in      IN schedule_sr.id_sched_sr_parent%TYPE DEFAULT NULL,
        id_sched_sr_parent_nin     IN BOOLEAN := TRUE,
        id_schedule_in             IN schedule_sr.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin            IN BOOLEAN := TRUE,
        id_episode_in              IN schedule_sr.id_episode%TYPE DEFAULT NULL,
        id_episode_nin             IN BOOLEAN := TRUE,
        id_patient_in              IN schedule_sr.id_patient%TYPE DEFAULT NULL,
        id_patient_nin             IN BOOLEAN := TRUE,
        duration_in                IN schedule_sr.duration%TYPE DEFAULT NULL,
        duration_nin               IN BOOLEAN := TRUE,
        id_diagnosis_in            IN schedule_sr.id_diagnosis%TYPE DEFAULT NULL,
        id_diagnosis_nin           IN BOOLEAN := TRUE,
        id_speciality_in           IN schedule_sr.id_speciality%TYPE DEFAULT NULL,
        id_speciality_nin          IN BOOLEAN := TRUE,
        flg_status_in              IN schedule_sr.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        flg_sched_in               IN schedule_sr.flg_sched%TYPE DEFAULT NULL,
        flg_sched_nin              IN BOOLEAN := TRUE,
        id_dept_dest_in            IN schedule_sr.id_dept_dest%TYPE DEFAULT NULL,
        id_dept_dest_nin           IN BOOLEAN := TRUE,
        prev_recovery_time_in      IN schedule_sr.prev_recovery_time%TYPE DEFAULT NULL,
        prev_recovery_time_nin     IN BOOLEAN := TRUE,
        id_sr_cancel_reason_in     IN schedule_sr.id_sr_cancel_reason%TYPE DEFAULT NULL,
        id_sr_cancel_reason_nin    IN BOOLEAN := TRUE,
        id_prof_cancel_in          IN schedule_sr.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin         IN BOOLEAN := TRUE,
        notes_cancel_in            IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin           IN BOOLEAN := TRUE,
        id_prof_reg_in             IN schedule_sr.id_prof_reg%TYPE DEFAULT NULL,
        id_prof_reg_nin            IN BOOLEAN := TRUE,
        id_institution_in          IN schedule_sr.id_institution%TYPE DEFAULT NULL,
        id_institution_nin         IN BOOLEAN := TRUE,
        adw_last_update_in         IN schedule_sr.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin        IN BOOLEAN := TRUE,
        dt_target_tstz_in          IN schedule_sr.dt_target_tstz%TYPE DEFAULT NULL,
        dt_target_tstz_nin         IN BOOLEAN := TRUE,
        dt_interv_preview_tstz_in  IN schedule_sr.dt_interv_preview_tstz%TYPE DEFAULT NULL,
        dt_interv_preview_tstz_nin IN BOOLEAN := TRUE,
        dt_cancel_tstz_in          IN schedule_sr.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin         IN BOOLEAN := TRUE,
        id_waiting_list_in         IN schedule_sr.id_waiting_list%TYPE DEFAULT NULL,
        id_waiting_list_nin        IN BOOLEAN := TRUE,
        flg_temporary_in           IN schedule_sr.flg_temporary%TYPE DEFAULT NULL,
        flg_temporary_nin          IN BOOLEAN := TRUE,
        icu_in                     IN schedule_sr.icu%TYPE DEFAULT NULL,
        icu_nin                    IN BOOLEAN := TRUE,
        notes_in                   IN schedule_sr.notes%TYPE DEFAULT NULL,
        notes_nin                  IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surgeons
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_vacancy           IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_waiting_list      IN waiting_list.id_waiting_list%TYPE,
        o_surgeons             OUT pk_types.cursor_type,
        o_default_surgeon_name OUT VARCHAR2,
        o_default_surgeon_id   OUT professional.id_professional%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surgeons
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        o_surgeons             OUT pk_types.cursor_type,
        o_default_surgeon_name OUT VARCHAR2,
        o_default_surgeon_id   OUT professional.id_professional%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_scheduling_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacancies
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room_ids    IN table_number,
        i_begin_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_vacancy_ids OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a set of ORIS schedules.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_department                Department ID
    * @param i_id_room                      Room ID
    * @param i_id_dcs                       Dep_clin_serv ID
    * @param i_id_prof                      Professional ID
    * @param i_start_date                   Begin date
    * @param i_end_date                     End date
    * @param i_flg_wizard                   Type of wizard (CA - Cancel, CO - Confirm)
    * @param o_schedules                    Schedules 
    * @param o_error                        Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    */
    FUNCTION get_related_schedules
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN table_number,
        i_id_room       IN table_number,
        i_id_dcs        IN table_number,
        i_id_prof       IN table_number,
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_flg_wizard    IN VARCHAR2,
        o_schedules     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION validate_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dcs_list      IN table_number,
        i_id_profs_list IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_id_wl         IN schedule_sr.id_waiting_list%TYPE,
        i_id_slot       IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        i_id_session    IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dcs_list      IN table_number,
        i_id_profs_list IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_flg_tempor    IN schedule_sr.flg_temporary%TYPE DEFAULT 'Y',
        i_id_wl         IN NUMBER,
        i_id_slot       IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        i_id_session    IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
        i_id_room       IN schedule.id_room%TYPE DEFAULT NULL,
        o_id_schedule   OUT schedule.id_schedule%TYPE,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * returns the department clinical services
    *
    * @param i_lang                   Language id   
    * @param i_prof                   Profissional    
    * @param o_dep_clin_servs         Cursor with the clinical service names    
    * @param o_error                  Error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    14-04-2009
    */
    FUNCTION get_dep_clin_servs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_dep_clin_servs OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * returns the list of surgeons
    *
    * @param i_lang       language id 
    * @param i_prof       Professional Identification  
    * @param o_fst_msg    First option to be shown in the multichoice 
    * @param o_surgeons   Cursor with the surgeons info    
    * @param o_error      error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_all_surgeons
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_fst_msg  OUT sys_message.desc_message%TYPE,
        o_surgeons OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_slot         IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE DEFAULT NULL,
        i_id_session      IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_slot         IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
        i_id_session      IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_id_profs_list   IN table_number,
        i_flg_tempor      IN schedule_sr.flg_temporary%TYPE DEFAULT 'Y',
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Insert a schedule in clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule ID
    * @param o_msg                           Message body to be displayed in flash
    * @param o_msg_title                     Message title
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    **********************************************************************************************/
    FUNCTION send_to_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Remove a schedule from clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule IDs
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    **********************************************************************************************/
    FUNCTION remove_from_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule IDs
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    **********************************************************************************************/
    FUNCTION send_clipboard_to_wl
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets schedules from clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param o_schedules                     Schedules
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/17
    **********************************************************************************************/
    FUNCTION get_sch_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the number of schedules on clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param o_sch_num                       Number of schedules
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/17
    **********************************************************************************************/
    FUNCTION get_sch_clipboard_num
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_sch_num OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_old_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_prof              IN sch_resource.id_professional%TYPE,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_flg_temporary_status IN schedule_sr.flg_temporary%TYPE DEFAULT NULL,
        i_flg_vacancy          IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_id_episode           IN consult_req.id_episode%TYPE DEFAULT NULL,
        o_id_schedule          OUT schedule.id_schedule%TYPE,
        o_flg_proceed          OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_msg                  OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * returns the surgery scheduling status
    *
    * @param i_lang     language id    
    * @param o_status   Cursor with the requisition status    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    09-04-2009
    */
    FUNCTION get_requisition_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a set of ORIS schedules.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_schedule                  Schedule ID
    * @param i_id_cancel_reason             Cancel reason
    * @param i_cancel_notes                 Cancel notes
    * @param o_error                        Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    */
    FUNCTION cancel_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN table_number,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Confirm temporary to permanent schedules
    *
    * @i_lang                                Language ID
    * @i_prof                                Profissional array
    * @i_tab_id_schedule                     Schedule IDs Table to confirm
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION confirm_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cria uma vaga para a agenda do ORIS
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification        
    * @param i_dt_begin                 Initial date
    * @param i_dt_end                   End Date
    * @param i_id_room                  Room id
    * @param i_id_sch_event             Event id (SURGERY event from sch_event table)
    * @param i_id_inst                  Institution ID
    * @param i_id_prof                  Vacancy professional 
    * @param i_id_dcs                   Vacancy Dep_clin_serv
    * @param o_id_slot                  Slot id that match the given parameters       
    * @param o_id_session               Session id that match the given parameters 
    * @param o_error                    Error stuff
    *   
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @date    07-05-2009
    */

    FUNCTION create_oris_scheduler_vacancy
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_begin       IN sch_consult_vac_oris_slot.dt_begin%TYPE,
        i_dt_end         IN sch_consult_vac_oris_slot.dt_end%TYPE,
        i_id_room        IN sch_consult_vacancy.id_room%TYPE,
        i_id_sch_event   IN sch_event.id_sch_event%TYPE,
        i_id_inst        IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof        IN sch_consult_vacancy.id_prof%TYPE,
        i_flg_urgent_mod IN BOOLEAN,
        i_flg_urgent     IN sch_consult_vac_oris.flg_urgency%TYPE,
        i_id_dcs         IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        o_id_slot        OUT sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        o_id_session     OUT sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Procura uma vaga existente de acordo com os critérios definidos através dos parâmetros de entrada
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification        
    * @param i_dt_begin                 Initial date
    * @param i_dt_end                   End Date
    * @param i_id_room                  Room id
    * @param i_id_eve                   Event id (SURGERY event from sch_event table)
    * @param i_id_inst                  Institution ID
    * @param i_id_prof                  Vacancy professional 
    * @param i_id_dcs                   Vacancy Dep_clin_serv
    * @param o_id_slot                  Slot id that match the given parameters       
    * @param o_id_session               Session id that match the given parameters 
    * @param o_error                    Error stuff
    *   
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @date    07-05-2009
    */

    FUNCTION search_oris_scheduler_vacancy
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dt_begin   IN sch_consult_vac_oris_slot.dt_begin%TYPE,
        i_dt_end     IN sch_consult_vac_oris_slot.dt_end%TYPE,
        i_id_room    IN sch_consult_vacancy.id_room%TYPE,
        i_id_eve     IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_inst    IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof    IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs     IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        o_id_slot    OUT sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        o_id_session OUT sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_stuff
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_wl    IN schedule_sr.id_waiting_list%TYPE,
        o_dcs_list OUT table_number,
        o_id_sch   OUT schedule.id_schedule%TYPE,
        o_id_epis  OUT episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * insert or update in table room_scheduled.
    * Adapted from pk_sr_visit.upd_surg_proc_preview_room. Didn't use that one because it's got a commit inside.
    * @author Telmo
    */
    FUNCTION upd_room_scheduled
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_room     IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    g_active           CONSTANT VARCHAR2(1) := 'A';
    g_inactive         CONSTANT VARCHAR2(1) := 'I';
    g_scheduled        CONSTANT VARCHAR2(1) := 'A';
    g_notscheduled     CONSTANT VARCHAR2(1) := 'N';
    g_color_flg_type_n CONSTANT VARCHAR2(1) := 'N';
    g_color_flg_type_d CONSTANT VARCHAR2(1) := 'D';

END pk_schedule_oris;
/
