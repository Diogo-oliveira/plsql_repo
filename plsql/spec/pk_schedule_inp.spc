/*-- Last Change Revision: $Rev: 2028953 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:56 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_inp IS

    FUNCTION get_listview_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN VARCHAR2,
        i_location      IN institution.id_institution%TYPE,
        i_ward          IN department.id_department%TYPE,
        o_header_text   OUT VARCHAR2,
        o_listview_info OUT pk_types.cursor_type,
        o_colors        OUT pk_types.cursor_type,
        o_ward_name     OUT VARCHAR2,
        o_blocked_bed   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_status_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_clinical_service_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE,
        i_id_dcs IN schedule.id_dcs_requested%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bed_availability
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bed IN bed.id_bed%TYPE,
        i_type   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_schedule_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sch_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_header
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_viewtype  IN VARCHAR2,
        i_location_name IN VARCHAR2,
        i_ward_name     IN VARCHAR2,
        o_header_text   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_timetable_locations
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_locations_ids IN table_number,
        o_locations     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room_dep_clin_serv
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        i_id_room        IN room.id_room%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_timetable_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        i_locations_ids  IN table_number,
        o_header_text    OUT VARCHAR2,
        o_timetable_data OUT pk_types.cursor_type,
        o_colors         OUT pk_types.cursor_type,
        o_depart_info    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION init_sch_room_stats
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN TIMESTAMP WITH TIME ZONE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surgery_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION confirm_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_related_schedules
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ward    IN table_number,
        i_id_spec    IN table_number,
        i_id_adm_phy IN table_number,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_flg_wizard IN VARCHAR2,
        o_schedules  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_overview_legend
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_legend OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION init_bed_slot
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_slots
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_bed      IN bed.id_bed%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION send_to_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ward_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_date            IN VARCHAR2,
        i_location        IN institution.id_institution%TYPE,
        i_ward            IN department.id_department%TYPE,
        o_general_info    OUT pk_types.cursor_type,
        o_floors          OUT pk_types.cursor_type,
        o_rooms_beds      OUT pk_types.cursor_type,
        o_adm_indications OUT pk_types.cursor_type,
        o_free_with_dcs   OUT pk_types.cursor_type,
        o_total_nchs      OUT NUMBER,
        o_avail_nchs      OUT NUMBER,
        o_nch_capacity    OUT VARCHAR2,
        o_blocked         OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION validate_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_id_wl          IN schedule_sr.id_waiting_list%TYPE,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_surg_bef_adm   OUT VARCHAR2,
        o_nch_short      OUT VARCHAR2,
        o_nch_short_data OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_planned_schedulings
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_dt_begin_sch    IN VARCHAR2,
        i_dt_end_sch      IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        o_schedules       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_locations_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_locations OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_locations
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_locations OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_physicians
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_locations IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_services
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_locations IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_surg_bef_adm    OUT VARCHAR2,
        o_nch_short       OUT VARCHAR2,
        o_nch_short_data  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ins_schedule_bed
    (
        i_lang             IN language.id_language%TYPE,
        id_schedule_in     IN schedule_bed.id_schedule%TYPE DEFAULT NULL,
        id_bed_in          IN schedule_bed.id_bed%TYPE DEFAULT NULL,
        id_waiting_list_in IN schedule_bed.id_waiting_list%TYPE DEFAULT NULL,
        flg_temporary_in   IN schedule_bed.flg_temporary%TYPE DEFAULT NULL,
        flg_conflict_in    IN schedule_bed.flg_conflict%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_schedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_flg_tempor      IN VARCHAR2,
        i_id_wl           IN waiting_list.id_waiting_list%TYPE,
        i_id_bed          IN bed.id_bed%TYPE,
        i_id_schedule_ref IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_notes           IN schedule.schedule_notes%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_scheduling_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_old_id_schedule      IN schedule.id_schedule%TYPE,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_flg_temporary_status IN schedule_bed.flg_temporary%TYPE DEFAULT NULL,
        o_id_schedule          OUT schedule.id_schedule%TYPE,
        o_flg_proceed          OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_msg                  OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_old_id_schedule      IN schedule.id_schedule%TYPE,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_flg_temporary_status IN schedule_bed.flg_temporary%TYPE DEFAULT NULL,
        i_transaction_id       IN VARCHAR2,
        o_id_schedule          OUT schedule.id_schedule%TYPE,
        o_flg_proceed          OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_msg                  OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_conflicts
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_conflict   IN schedule_bed.flg_conflict%TYPE DEFAULT pk_alert_constant.g_yes,
        o_list_schedules OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_autopick_crit
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_schedule_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN wtl_epis.id_episode%TYPE,
        i_id_patient IN sch_group.id_patient%TYPE,
        i_date       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function alters the schedule end date. It is used when the discharge predicted date 
    * is changed.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode ID   
    * @param i_id_patient                    PAtient ID   
    * @param i_date                          New schedule end date    
    * @param i_transaction_id                Scheduler 3.0 transaction ID
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION set_schedule_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN wtl_epis.id_episode%TYPE,
        i_id_patient     IN sch_group.id_patient%TYPE,
        i_date           IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
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
        i_id_bed          IN bed.id_bed%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clin_servs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_id_room       IN room.id_room%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN table_number,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN table_number,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_request_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_wl               IN waiting_list.id_waiting_list%TYPE,
        i_unscheduled         IN VARCHAR2 DEFAULT 'Y',
        o_id_patient          OUT waiting_list.id_patient%TYPE,
        o_id_adm_indic        OUT adm_request.id_adm_indication%TYPE,
        o_id_prof_dest        OUT adm_request.id_dest_prof%TYPE,
        o_id_dest_inst        OUT adm_request.id_dest_inst%TYPE,
        o_id_department       OUT adm_request.id_department%TYPE,
        o_id_dcs              OUT adm_request.id_dep_clin_serv%TYPE,
        o_id_room_type        OUT adm_request.id_room_type%TYPE,
        o_id_pref_room        OUT adm_request.id_pref_room%TYPE,
        o_id_adm_type         OUT adm_request.id_admission_type%TYPE,
        o_flg_mix_nurs        OUT adm_request.flg_mixed_nursing%TYPE,
        o_id_bed_type         OUT adm_request.id_bed_type%TYPE,
        o_dt_admission        OUT adm_request.dt_admission%TYPE,
        o_id_episode          OUT adm_request.id_dest_episode%TYPE,
        o_exp_duration        OUT adm_request.expected_duration%TYPE,
        o_id_external_request OUT waiting_list.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sch_dt_begin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN schedule.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_conflicts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_location  IN institution.id_institution%TYPE,
        i_ward      IN department.id_department%TYPE,
        o_conflicts OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_sch_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE DEFAULT NULL,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_data   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_schedule_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE DEFAULT NULL,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_data   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /*
        FUNCTION calc_nchs_in_use
        (
            i_lang          IN LANGUAGE.id_language%TYPE,
            i_prof          IN profissional,
            i_id_department IN department.id_department%TYPE DEFAULT NULL,
            i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
            i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
            i_flg_between   IN VARCHAR2,
            o_nchs          OUT NUMBER,
            o_error         OUT t_error_out
        ) RETURN BOOLEAN;
    */
    FUNCTION calc_nchs_in_use
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_between   IN VARCHAR2,
        i_dep_nch       IN NUMBER,
        o_nchs          OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    FUNCTION calc_available_nchs
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_total_nchs    IN NUMBER,
        o_avail_nchs    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;*/

    FUNCTION calc_available_nchs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_avail_nchs    OUT NUMBER,
        o_total_nchs    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION calc_available_nchs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_total_nchs    IN NUMBER,
        i_dep_nch       NUMBER,
        o_avail_nchs    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION calc_nchs_capacity
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_total_nch  IN NUMBER,
        i_avail_nch  IN NUMBER,
        i_needed_nch IN NUMBER DEFAULT NULL,
        o_capacity   OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /*
        FUNCTION verify_conflict_sch_allocation
        (
            i_lang             IN LANGUAGE.id_language%TYPE,
            i_prof             IN profissional,
            i_start_allocation IN TIMESTAMP WITH LOCAL TIME ZONE,
            i_end_allocation   IN TIMESTAMP WITH LOCAL TIME ZONE,
            i_id_bed           IN schedule_bed.id_bed%TYPE,
            o_schs_conflict    OUT table_number,
            o_error            OUT t_error_out
        ) RETURN BOOLEAN;
    */
    FUNCTION verify_conflict_sch_allocation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_start_allocation IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_allocation   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bed           IN schedule_bed.id_bed%TYPE,
        i_sch_begin_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_schs_conflict    OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_bed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_id_bed      OUT schedule_bed.id_bed%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vac_oris_slot table
    *
    * @param i_id_sch_allocation             sch_allocation ID
    * @param i_id_schedule                   schedule ID
    * @param i_id_bmng_allocation_bed        bmng_allocation_bed ID    
    * @param o_id_sch_allocation             inserted sch_allocation id
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/08/26
    **********************************************************************************************/
    FUNCTION ins_sch_allocation
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_schedule            IN sch_allocation.id_schedule%TYPE,
        i_id_bmng_allocation_bed IN sch_allocation.id_bmng_allocation_bed%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - Delete record from SCH_ALLOCATION table
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule ID
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009-10-20
    **********************************************************************************************/
    FUNCTION del_sch_allocation
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_schedule            IN sch_allocation.id_schedule%TYPE,
        i_id_bmng_allocation_bed IN sch_allocation.id_bmng_allocation_bed%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the bed scheduled to an admission episode 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier    
    * @param o_id_bed                        Bed identifier    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/15
    **********************************************************************************************/
    FUNCTION get_sch_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_id_bed     OUT bed.id_bed%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*FUNCTION get_sch_bed
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN bed.id_bed%TYPE;*/

    /**********************************************************************************************
    * Returns the id schedule associated to an admission episode 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/20
    **********************************************************************************************/
    FUNCTION get_schedule_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN schedule.id_schedule%TYPE;

    /**********************************************************************************************
    * Returns the id schedule associated to an admission episode 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/20
    **********************************************************************************************/
    FUNCTION get_last_schedule_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN schedule.dt_begin_tstz%TYPE,
        i_dt_end     IN schedule.dt_end_tstz%TYPE
    ) RETURN schedule.id_schedule%TYPE;

    /**********************************************************************************************
    * Returns the schedule status associated to an episode
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/23
    **********************************************************************************************/
    FUNCTION get_schedule_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN schedule.flg_status%TYPE;

    /**********************************************************************************************
    * Returns the id professional that cancelled the schedule.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/27
    **********************************************************************************************/
    FUNCTION get_schedule_cancel_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN schedule.id_prof_cancel%TYPE;

    /**********************************************************************************************
    * Checks if a given sch cancel reason exists.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/27
    **********************************************************************************************/
    FUNCTION check_cancel_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_schedule_bed_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_id_dep  OUT department.id_department%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE;

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointments in the given date
    * - i_date is not null and i_id_bed is null -> returns all the bed appointments which begin date is greater than i_date
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
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.7.4
    * @since                                 2009/11/30
    **********************************************************************************************/
    FUNCTION get_conflict_sch_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_bed       IN bed.id_bed%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        i_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_has_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if the given id_schedule was rescheduled.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.1
    * @since                                 28-Jun-2011
    **********************************************************************************************/
    FUNCTION check_reschedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    g_exception EXCEPTION;

END pk_schedule_inp;
/
