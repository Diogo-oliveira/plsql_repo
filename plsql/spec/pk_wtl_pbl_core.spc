/*-- Last Change Revision: $Rev: 2029062 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wtl_pbl_core IS

    g_wtl_dcs_type_specialty CONSTANT wtl_dep_clin_serv.flg_type%TYPE := 'S';
    g_wtl_dcs_type_ext_disc  CONSTANT wtl_dep_clin_serv.flg_type%TYPE := 'D';

    g_wtl_prof_type_surgeon  CONSTANT wtl_prof.flg_type%TYPE := 'S';
    g_wtl_prof_type_adm_phys CONSTANT wtl_prof.flg_type%TYPE := 'A';

    g_wtl_search_st_all           CONSTANT VARCHAR2(1) := 'A';
    g_wtl_search_st_schedule      CONSTANT VARCHAR2(1) := 'S';
    g_wtl_search_st_not_schedule  CONSTANT VARCHAR2(1) := 'N';
    g_wtl_search_st_schedule_temp CONSTANT VARCHAR2(1) := 'T';
    g_wtl_search_st_no_surgery    CONSTANT VARCHAR2(1) := 'B';

    g_wtl_sk_rel_urg   CONSTANT wtl_sort_key.id_wtl_sort_key%TYPE := 1;
    g_wtl_sk_abs_urg   CONSTANT wtl_sort_key.id_wtl_sort_key%TYPE := 2;
    g_wtl_sk_wtime     CONSTANT wtl_sort_key.id_wtl_sort_key%TYPE := 3;
    g_wtl_sk_urg_level CONSTANT wtl_sort_key.id_wtl_sort_key%TYPE := 4;
    g_wtl_sk_barthel   CONSTANT wtl_sort_key.id_wtl_sort_key%TYPE := 5;
    g_wtl_sk_gender    CONSTANT wtl_sort_key.id_wtl_sort_key%TYPE := 6;

    g_wtl_chk_ind_adm CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 1;
    g_wtl_chk_adm_loc CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 2;
    g_wtl_chk_adm_srv CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 3;
    g_wtl_chk_adm_spc CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 4;
    g_wtl_chk_adm_dur CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 5;
    g_wtl_chk_srg_spc CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 6;
    g_wtl_chk_srg_prc CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 7;
    g_wtl_chk_srg_dur CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 8;
    g_wtl_chk_pos_aut CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 9;
    g_wtl_chk_sch_str CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 10;
    g_wtl_chk_sch_end CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 11;
    g_wtl_chk_urg_lvl CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 12;
    g_wtl_chk_barthel CONSTANT wtl_checklist.id_wtl_checklist%TYPE := 13;

    g_wtl_sysconfig CONSTANT VARCHAR2(50) := 'WTL_FUNC_EVAL';

    g_wtl_doc_flg_barthel_idx CONSTANT VARCHAR2(1) := 'B';
    g_wtl_doc_flg_active      CONSTANT VARCHAR2(1) := 'A';
    g_wtl_doc_flg_inactive    CONSTANT VARCHAR2(1) := 'I';

    /* Action that indicates the creation/update of the Barthel Index (when the user presses the '+' button)*/
    g_barthel_index_a CONSTANT VARCHAR2(1) := 'A';
    /* Action that indicates the cancellation of the Barthel Index (when the user presses the 'X' button)*/
    g_barthel_index_c CONSTANT VARCHAR2(1) := 'C';
    /* Action that indicates the recording of the Barthel Index (when the user presses the 'OK' button)*/
    g_barthel_index_o CONSTANT VARCHAR2(1) := 'O';

    --popup types: to be used in the Barthel Index validation popups
    g_action_popup  CONSTANT VARCHAR2(1) := 'A';
    g_warning_popup CONSTANT VARCHAR2(1) := 'W';

    /* Popup messages */
    g_msg_pop_title CONSTANT VARCHAR2(30) := 'INP_WL_MNGM_T013';

    TYPE t_rec_episode IS RECORD(
        id_episode   wtl_epis.id_episode%TYPE,
        id_epis_type wtl_epis.id_epis_type%TYPE,
        id_schedule  wtl_epis.id_schedule%TYPE);

    TYPE t_rec_episodes IS TABLE OF t_rec_episode;

    TYPE t_rec_unavailability IS RECORD(
        dt_unav_start wtl_unav.dt_unav_start%TYPE,
        dt_unav_end   wtl_unav.dt_unav_end%TYPE);

    TYPE t_rec_unavailabilities IS TABLE OF t_rec_unavailability;

    TYPE t_rec_professional IS RECORD(
        id_prof  wtl_prof.id_prof%TYPE,
        flg_type wtl_prof.flg_type%TYPE);

    TYPE t_rec_professionals IS TABLE OF t_rec_professional;

    TYPE t_rec_dcs IS RECORD(
        id_dep_clin_serv wtl_dep_clin_serv.id_dep_clin_serv%TYPE,
        flg_type         wtl_dep_clin_serv.flg_type%TYPE,
        id_episode       wtl_dep_clin_serv.id_episode%TYPE);

    TYPE t_rec_dcss IS TABLE OF t_rec_dcs;

    TYPE dict_number IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);

    TYPE dict_varchar IS TABLE OF VARCHAR2(32767) INDEX BY VARCHAR2(200 CHAR);

    /********** public functions  *************/
    FUNCTION get_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN epis_type.id_epis_type%TYPE,
        o_episodes        OUT t_rec_episodes,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN epis_type.id_epis_type%TYPE,
        i_flg_status      IN wtl_epis.flg_status%TYPE,
        o_episodes        OUT t_rec_episodes,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Returns true if episode exists on waiting list. Returns false otherwise.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_episodes          episode identifier
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.5.1.2
    *  @since                      12-11-2010
    *
    ******************************************************************************/
    FUNCTION check_episode_in_wtl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************
    *  Returns true if episode exists on waiting list and is schedule. 
    *  Returns false otherwise.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_episodes          episode identifier
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.5.1.2
    *  @since                      12-11-2010
    *
    ******************************************************************************/
    FUNCTION check_episode_sched_wtl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_unavailability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE,
        i_all              IN VARCHAR2 DEFAULT 'Y',
        o_unavailabilities OUT t_rec_unavailabilities,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professionals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN epis_prof_rec.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_prof.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_professionals   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professionals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN epis_prof_rec.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_prof.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_professionals   OUT t_rec_professionals,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN epis_prof_rec.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_prof.flg_type%TYPE DEFAULT NULL
        
    ) RETURN VARCHAR2;

    FUNCTION get_dep_clin_servs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_dcs             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_dep_clin_servs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_dcs             OUT t_rec_dcss,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_clin_servs_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_dep_clin_serv.flg_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;
    FUNCTION get_surgical_procedures
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_wtlist                 IN table_number,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_surg_proc_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sr_proc_id_content_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_preferred_time
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_wtlist      IN table_number,
        i_flg_status     IN VARCHAR2 DEFAULT 'A',
        o_preferred_time OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_pref_time_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_ptime_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_wtlist        IN waiting_list.id_waiting_list%TYPE,
        i_flg_status       IN VARCHAR2 DEFAULT 'A',
        o_pref_time_reason OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_ptime_reason_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN waiting_list.id_waiting_list%TYPE,
        o_id_patient          OUT waiting_list.id_patient%TYPE,
        o_flg_type            OUT waiting_list.flg_type%TYPE,
        o_flg_status          OUT waiting_list.flg_status%TYPE,
        o_dpb                 OUT waiting_list.dt_dpb%TYPE,
        o_dpa                 OUT waiting_list.dt_dpa%TYPE,
        o_dt_surgery          OUT waiting_list.dt_surgery%TYPE,
        o_min_inform_time     OUT waiting_list.min_inform_time%TYPE,
        o_id_urgency_lev      OUT waiting_list.id_wtl_urg_level%TYPE,
        o_id_external_request OUT waiting_list.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_placement_date
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_wtlist_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_wtlist  IN waiting_list.id_waiting_list%TYPE,
        i_adm_needed IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_wtlist   IN waiting_list.id_waiting_list%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_wtlist   IN waiting_list.id_waiting_list%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION search_patient
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_bsn           IN v_patient_all_markets.bsn%TYPE,
        i_ssn           IN v_patient_all_markets.social_security_number%TYPE,
        i_nhn           IN v_patient_all_markets.social_security_number%TYPE,
        i_recnum        IN v_patient_all_markets.alert_process_number%TYPE,
        i_birthdate     IN VARCHAR2,
        i_gender        IN v_patient_all_markets.gender%TYPE,
        i_surnameprefix IN v_patient_all_markets.surname_prefix%TYPE,
        i_surnamemaiden IN v_patient_all_markets.surname_maiden%TYPE,
        i_names         IN v_patient_all_markets.name%TYPE,
        i_initials      IN v_patient_all_markets.initials%TYPE,
        i_min_age       IN NUMBER DEFAULT NULL,
        i_max_age       IN NUMBER DEFAULT NULL,
        o_list          OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION search_patient_nl
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN alert_adtcod.patient.id_patient%TYPE,
        i_bsn           IN alert_adtcod.patient.bsn%TYPE,
        i_ssn           IN alert_adtcod.person.social_security_number%TYPE,
        i_recnum        IN alert_adtcod.pat_identifier.alert_process_number%TYPE,
        i_birthdate     IN VARCHAR2, -- alert_adtcod.patient.dt_birth%TYPE,
        i_gender        IN alert_adtcod.patient.gender%TYPE,
        i_surnameprefix IN alert_adtcod.patient.surname_prefix%TYPE,
        i_surnamemaiden IN alert_adtcod.person.surname_maiden%TYPE,
        i_names         IN alert_adtcod.patient.name%TYPE,
        i_initials      IN alert_adtcod.patient.initials%TYPE,
        o_list          OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtlist_search
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_args    IN table_varchar,
        i_wl_type IN VARCHAR2,
        o_wtlist  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtlist_search_surgery
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_wtlist OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_danger_cont
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        o_danger_cont     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_danger_cont_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_clinical_questions_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_wtlist_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_viewer_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_screen       IN VARCHAR2 DEFAULT 'I',
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * 
    * If all required conditions are met, the provided WTList is cancelled, and so are all of its related 
    * episodes and schedules.
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to cancel.
    * @param      i_id_cancel_reason  code of CANCEL_REASON.
    * @param      i_notes_cancel      Free text
    * @param      i_flg_rollback      This function makes rollback ('Y' - This function makes rollback; 'N' - This function only return false)
    * @param      o_msg_error         error message if this cancelation is not possible
    * @param      o_error             output in case of error
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-04-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_wtlist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_wtl_id           IN waiting_list.id_waiting_list%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN waiting_list.notes_cancel%TYPE,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        i_flg_rolback      IN VARCHAR2,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION undelete_wtlist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_wtl         IN waiting_list.id_waiting_list%TYPE,
        i_id_epis        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtlist_is_cancel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE,
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtlist_is_cancel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_wtlist_is_undel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE,
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtlist_is_undel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sch_periods
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_episode_sr      IN episode.id_episode%TYPE,
        i_episode_inp     IN episode.id_episode%TYPE,
        o_sched_period    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_waiting_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        id_patient_in       IN waiting_list.id_patient%TYPE DEFAULT NULL,
        id_prof_req_in      IN waiting_list.id_prof_req%TYPE DEFAULT NULL,
        dt_placement_in     IN waiting_list.dt_placement%TYPE DEFAULT NULL,
        flg_type_in         IN waiting_list.flg_type%TYPE DEFAULT NULL,
        flg_status_in       IN waiting_list.flg_status%TYPE DEFAULT NULL,
        dt_dpb_in           IN waiting_list.dt_dpb%TYPE DEFAULT NULL,
        dt_dpa_in           IN waiting_list.dt_dpa%TYPE DEFAULT NULL,
        dt_surgery_in       IN waiting_list.dt_surgery%TYPE DEFAULT NULL,
        dt_admission_in     IN waiting_list.dt_admission%TYPE DEFAULT NULL,
        min_inform_time_in  IN waiting_list.min_inform_time%TYPE DEFAULT NULL,
        id_wtl_urg_level_in IN waiting_list.id_wtl_urg_level%TYPE DEFAULT NULL,
        id_prof_reg_in      IN waiting_list.id_prof_reg%TYPE DEFAULT NULL,
        dt_reg_in           IN waiting_list.dt_reg%TYPE DEFAULT NULL,
        id_cancel_reason_in IN waiting_list.id_cancel_reason%TYPE DEFAULT NULL,
        notes_cancel_in     IN waiting_list.notes_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_in   IN waiting_list.id_prof_cancel%TYPE DEFAULT NULL,
        dt_cancel_in        IN waiting_list.dt_cancel%TYPE DEFAULT NULL,
        id_external_request IN waiting_list.id_external_request%TYPE DEFAULT NULL,
        func_eval_score     IN waiting_list.func_eval_score%TYPE DEFAULT NULL,
        notes_edit          IN waiting_list.notes_edit%TYPE DEFAULT NULL,
        i_order_set         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        id_waiting_list_io  IN OUT waiting_list.id_waiting_list%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all data for Admission and Surgery Request for a given waiting list.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_adm_request      Admission request data       
    * @param o_diag             Diagnoses
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_waiting_list     Remaining info. about the waiting list
    * @param o_unavailabilities List of unavailability periods
    * @param o_sched_period     Scheduling period
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        -- Admission Request
        o_adm_request OUT pk_types.cursor_type,
        o_diag        OUT pk_types.cursor_type,
        -- Surgery Request
        o_surg_specs       OUT pk_types.cursor_type,
        o_pref_surg        OUT pk_types.cursor_type,
        o_procedures       OUT pk_types.cursor_type,
        o_ext_disc         OUT pk_types.cursor_type,
        o_danger_cont      OUT pk_types.cursor_type,
        o_preferred_time   OUT pk_types.cursor_type,
        o_pref_time_reason OUT pk_types.cursor_type,
        o_pos              OUT pk_types.cursor_type,
        o_surg_request     OUT pk_types.cursor_type,
        -- Common
        o_waiting_list     OUT pk_types.cursor_type,
        o_unavailabilities OUT pk_types.cursor_type,
        o_sched_period     OUT pk_types.cursor_type,
        o_referral         OUT pk_types.cursor_type,
        -- Summ_page
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        -- POS Request
        o_pos_validation            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all data for Admission and Surgery Request for a given waiting list.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_adm_request      Admission request data       
    * @param o_diag             Diagnoses
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_waiting_list     Remaining info. about the waiting list
    * @param o_unavailabilities List of unavailability periods
    * @param o_sched_period     Scheduling period
    * @param o_cancel_info      Cancelation Info
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        -- Admission Request
        o_adm_request OUT pk_types.cursor_type,
        o_diag        OUT pk_types.cursor_type,
        -- Surgery Request
        o_surg_specs       OUT pk_types.cursor_type,
        o_pref_surg        OUT pk_types.cursor_type,
        o_procedures       OUT pk_types.cursor_type,
        o_ext_disc         OUT pk_types.cursor_type,
        o_danger_cont      OUT pk_types.cursor_type,
        o_preferred_time   OUT pk_types.cursor_type,
        o_pref_time_reason OUT pk_types.cursor_type,
        o_pos              OUT pk_types.cursor_type,
        o_surg_request     OUT pk_types.cursor_type,
        -- Common
        o_waiting_list     OUT pk_types.cursor_type,
        o_unavailabilities OUT pk_types.cursor_type,
        o_sched_period     OUT pk_types.cursor_type,
        o_referral         OUT pk_types.cursor_type,
        -- Summ_page
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        -- POS Request
        o_pos_validation OUT pk_types.cursor_type,
        --Cancelation Info
        o_cancel_info               OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the patient's order in the waiting list may be changed, and returns a message.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_flg_show         Show message: (Y) Yes (N) No
    * @param o_msg_title        Message title
    * @param o_msg_text         Message text
    * @param o_button           Button type
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/06
    *********************************************************************************************/
    FUNCTION check_waiting_list_order
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN waiting_list.id_waiting_list%TYPE,
        i_dt_sched_period_end IN VARCHAR2,
        i_wtl_urg_level       IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_func_eval_modified  IN VARCHAR2,
        i_id_patient          IN patient.id_patient%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg_text            OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            output
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Sérgio Cunha
    *  @version                    2.5.0.3
    *  @since                      22-05-2009
    ******************************************************************************/
    FUNCTION get_wtlist_search_inpatient
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_args_inp IN table_varchar,
        o_wtlist   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Get a list of admission indications for a specific ward
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_ward              ward ID
    *  @param  o_adm_indication    Adm Indication ID
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Sérgio Cunha
    *  @version                    2.5.0.3
    *  @since                      22-05-2009
    ******************************************************************************/
    FUNCTION get_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ward           IN department.id_department%TYPE,
        o_adm_indication OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Returns the Waiting List summary for multiple entries. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting List IDs
    *  @param  o_data              data
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      27-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_summary_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Adds Admission or Surgery Requests to the Waiting List.
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional ID/Institution ID/Software ID
    * @param i_id_patient                Patient ID
    * @param i_id_episode                Current episode ID
    * @param io_id_episode_sr             Surgical episode ID (if exists)
    * @param io_id_episode_inp            Inpatient episode ID (if exists)
    * @param i_id_waiting_list           Waiting list ID (if exists)     
    * @param i_flg_type                  Type of request: (B) Bed - admission request (S) Surgery request (A) All
    * @param i_id_wtl_urg_level          Urgency level ID
    * @param i_dt_sched_period_start     Scheduling period start date
    * @param i_dt_sched_period_end       Scheduling period end date
    * @param i_min_inform_time           Minimum time to inform
    * @param i_dt_surgery                Suggested surgery date
    * @param i_unav_period_start         Unavailability period: start date(s)
    * @param i_unav_period_end           Unavailability period: end date(s)    
    * @param i_pref_surgeons              Array of preferred surgeons
    * @param i_external_dcs               Array of external disciplines
    * @param i_dep_clin_serv_sr           Array of specialities (for the surgical procedure)
    * @param i_flg_pref_time              Array for preferred time: (M) Morning (A) Afternoon (N) Night (O) Any
    * @param i_reason_pref_time           Array of reasons for preferred time
    * @param i_id_sr_intervention         Array of surgical procedures ID
    * @param i_flg_laterality             Array of laterality for each procedure
    * @param i_id_diagnosis_proc          Array of diagnosis ID associated with surgical procedures
    * @param i_duration                   Expected duration of the surgical procedure
    * @param i_icu                        Intensive care unit: (Y) Yes (N) No
    * @param i_notes_surg                 Scheduling notes
    * @param i_adm_needed                 Admission needed: (Y) Yes (N) No
    * @param i_id_sr_pos_status           POS Decision   
    * @param i_surg_needed                Surgery needed: (Y) Yes (N) No
    * @param i_adm_indication             Indication for admission ID
    * @param i_dest_inst                  Location requested
    * @param i_adm_type                   Admission type
    * @param i_department                 Department requested
    * @param i_room_type                  Room type
    * @param i_dep_clin_serv              Specialty requested
    * @param i_pref_room                  Preferred room
    * @param i_mixed_nursing              Mixed nursing preference
    * @param i_bed_type                   Bed type
    * @param i_dest_prof                  Professional requested to take the admission
    * @param i_adm_preparation            Admission preparation
    * @param i_expect_duration            Admission's expected duration
    * @param i_dt_admission               Date of admission (final)
    * @param i_notes                      Entered notes
    * @param i_nit_flg                    Flag indicating need for a nurse intake
    * @param i_nit_dt_suggested           Date suggested for the nurse intake
    * @param i_nit_dcs                    Dep_clin_serv for nurse intake
    * @param i_supply                     Supply ID
    * @param i_supply_set                 Parent supply set (if applicable)
    * @param i_supply_qty                 Supply quantity
    * @param i_supply_loc                 Supply location
    * @param i_dt_return                  Estimated date of of return
    * @param i_supply_soft_inst           list
    * @param i_flg_cons_type              flag of consumption type
    * @param i_description_sp             Table varchar with surgical procedures' description
    * @param i_id_sr_epis_interv          Table number with id_sr_epis_interv
    * @param i_id_req_reason              Reasons for each supply
    * @param i_supply_notes               Supply Request notes
    * @param i_diagnosis_adm_req          Admission request diagnosis info
    * @param i_diagnosis_surg_proc        Surgical procedure diagnosis info
    * @param i_diagnosis_contam           Contamination diagnosis info
    * @param i_id_cdr_call                Rule event identifier.
    * @param o_error                      Error
    *
    *  @return                     TRUE if successful, FALSE otherwise
    *
    *  @author                     José Brito
    *  @version                    1.0
    *  @since                      2009/05/04
    *
    ******************************************************************************/
    FUNCTION set_adm_surg_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        -- Logic
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list      IN OUT waiting_list.id_waiting_list%TYPE,
        i_flg_type              IN waiting_list.flg_type%TYPE,
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2, -- 10
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        i_unav_period_start     IN table_varchar,
        i_unav_period_end       IN table_varchar, -- 15
        -- Surgery Request
        i_pref_surgeons      IN table_number,
        i_external_dcs       IN table_number,
        i_dep_clin_serv_sr   IN table_number,
        i_speciality_sr      IN table_number,
        i_department_sr      IN table_number,
        i_flg_pref_time      IN table_varchar,
        i_reason_pref_time   IN table_number, -- 20
        i_id_sr_intervention IN table_number,
        i_flg_principal      IN table_varchar,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_surgical_site      IN table_varchar,
        i_sp_notes           IN table_varchar, --25
        i_duration           IN schedule_sr.duration%TYPE,
        i_icu                IN schedule_sr.icu%TYPE,
        i_icu_pos            IN schedule_sr.icu_pos%TYPE,
        i_notes_surg         IN schedule_sr.notes%TYPE,
        i_adm_needed         IN schedule_sr.adm_needed%TYPE,
        i_id_sr_pos_status   IN sr_pos_status.id_sr_pos_status%TYPE, --30
        -- Admission Request
        i_surg_needed       IN VARCHAR2,
        i_adm_indication    IN adm_request.id_adm_indication%TYPE,
        i_adm_ind_desc      IN adm_request.adm_indication_ft%TYPE DEFAULT NULL,
        i_dest_inst         IN adm_request.id_dest_inst%TYPE,
        i_adm_type          IN adm_request.id_admission_type%TYPE,
        i_department        IN adm_request.id_department%TYPE, --35
        i_room_type         IN adm_request.id_room_type%TYPE,
        i_dep_clin_serv_adm IN adm_request.id_dep_clin_serv%TYPE,
        i_pref_room         IN adm_request.id_pref_room%TYPE,
        i_mixed_nursing     IN adm_request.flg_mixed_nursing%TYPE,
        i_bed_type          IN adm_request.id_bed_type%TYPE, --40
        i_dest_prof         IN adm_request.id_dest_prof%TYPE,
        i_adm_preparation   IN adm_request.id_adm_preparation%TYPE,
        i_dt_admission      IN VARCHAR2,
        i_expect_duration   IN adm_request.expected_duration%TYPE,
        i_notes_adm         IN adm_request.notes%TYPE, --45
        i_nit_flg           IN adm_request.flg_nit%TYPE,
        i_nit_dt_suggested  IN VARCHAR2,
        i_nit_dcs           IN adm_request.id_nit_dcs%TYPE,
        i_external_request  IN p1_external_request.id_external_request%TYPE,
        i_func_eval_score   IN waiting_list.func_eval_score%TYPE DEFAULT NULL, --50
        i_notes_edit        IN waiting_list.notes_edit%TYPE DEFAULT NULL,
        --Barthel Index Template
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE, --55
        i_doc_flg_type          IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar, --60
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_wtl_change            IN VARCHAR2, --65
        --SYS_ALERT 64
        i_profs_alert IN table_number DEFAULT NULL,
        --ALERT-14505 - POS Validation Request
        i_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested IN VARCHAR2,
        i_pos_req_notes    IN sr_pos_schedule.req_notes%TYPE,
        i_decision_notes   IN sr_pos_schedule.decision_notes%TYPE,
        -- Surgical supplies
        i_supply           IN table_table_number, --70
        i_supply_set       IN table_table_number,
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number, --75
        i_flg_cons_type    IN table_table_varchar,
        --
        i_description_sp    IN table_varchar,
        i_id_sr_epis_interv IN table_number,
        i_id_req_reason     IN table_table_number,
        i_supply_notes      IN table_table_varchar, --80
        i_surgery_record    IN table_number,
        i_prof_team         IN table_number,
        i_tbl_prof          IN table_table_number,
        i_tbl_catg          IN table_table_number,
        i_tbl_status        IN table_table_varchar, --85
        i_test              IN VARCHAR2,
        --Diagnosis information
        i_diagnosis_adm_req   IN pk_edis_types.rec_in_epis_diagnosis,
        i_diagnosis_surg_proc IN pk_edis_types.table_in_epis_diagnosis,
        i_diagnosis_contam    IN pk_edis_types.rec_in_epis_diagnosis,
        -- clinical decision rules 
        i_id_cdr_call IN cdr_call.id_cdr_call%TYPE, --90
        i_id_ct_io    IN table_table_varchar DEFAULT NULL,
        --Chile Market
        i_regimen                 IN VARCHAR2 DEFAULT NULL,
        i_beneficiario            IN VARCHAR2 DEFAULT NULL,
        i_precauciones            IN VARCHAR2 DEFAULT NULL,
        i_contactado              IN VARCHAR2 DEFAULT NULL, --95
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_table_clob DEFAULT NULL,
        i_id_inst_dest            IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set               IN VARCHAR2, --100
        i_global_anesth           IN VARCHAR2 DEFAULT NULL,
        i_local_anesth            IN VARCHAR2 DEFAULT NULL,
        i_id_mrp                  IN NUMBER DEFAULT NULL,
        i_id_written_by           IN NUMBER DEFAULT NULL,
        i_ri_prof_spec            IN NUMBER DEFAULT NULL, --105
        i_flg_compulsory          IN VARCHAR2 DEFAULT NULL,
        i_id_compulsory_reason    IN adm_request.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason       IN adm_request.compulsory_reason%TYPE DEFAULT NULL,
        o_adm_request             OUT adm_request.id_adm_request%TYPE,
        o_msg_error               OUT VARCHAR2,
        o_title_error             OUT VARCHAR2,
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Checks if an id_epis_documentation is associated to an admission request*
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_epis_documentation       epis documentation id                 *
    *                                                                         *
    * @param o_error                    Error message                         *
    * @param o_flg_val                  Y - Associated; N - No association    *
    * @param o_waiting_list             Id_waiting_list (if applicable)       *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/08                            *
    **************************************************************************/
    FUNCTION check_wtl_func_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN wtl_documentation.id_epis_documentation%TYPE,
        o_flg_val            OUT VARCHAR2,
        o_waiting_list       OUT wtl_documentation.id_waiting_list%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a popup, when creating, 
    *  updating or cancelling the Barthel Index.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier
    *  @param  i_action                   Action that is being taken (A- Add, E-Edit, C-cancel, O-OK)
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION check_wtl_func_eval_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_action                IN VARCHAR2,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_pop_msgs              OUT table_table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a popup, when creating, 
    *  updating an admission requests.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier    
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_last_epis_doc            Last epis documentation ID (last BI evaluation)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      26-02-2010
    ******************************************************************************/
    FUNCTION check_adm_req_feval_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_pop_msgs              OUT table_table_varchar,
        o_last_epis_doc         OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Indica se um profissional fez registos numa dada doc_area num dado      *
    * episódio no caso afirmativo, devolve a última documentation             *
    * IMP: This function is cloned on PK_TOUCH_OPTION.get_prof_doc_area_exists*
    *                                                                         *
    * @param i_lang                id da lingua                               *
    * @param i_prof                utilizador autenticado                     *
    * @param i_episode             id do episódio                             *
    * @param i_doc_area            id da doc_area da qual se verificam se     *
    *                              foram feitos registos                      *
    * @param o_last_prof_epis_doc  Last documentation epis ID to profissional *
    * @param o_date_last_epis      Data do último episódio                    *
    * @param o_flg_data            Y if there are data, F when no date found  *
    * @param o_error               Error message                              *
    *                                                                         *
    * @return                      true or false on success or error          *
    *                                                                         *
    * @autor                                                                  *
    * @version                     1.0                                        *
    * @since                                                                  *
    **************************************************************************/
    FUNCTION get_prof_doc_area_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis     OUT epis_documentation.dt_creation_tstz%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Saves epis_documentation data with wtl_documentation logic (based on    *
    * the PK_TOUCH_OPTION.SET_EPIS_DOCUMENTATION function)                    *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_prof_cat_type                                                  *
    * @param i_epis                                                           *
    * @param i_doc_area                                                       *
    * @param i_doc_template                                                   *
    * @param i_epis_documentation                                             *
    * @param i_flg_type                                                       *
    * @param i_id_documentation                                               *
    * @param i_id_doc_element                                                 *
    * @param i_id_doc_element_crit                                            *
    * @param i_value                                                          *
    * @param i_notes                                                          *
    * @param i_id_doc_element_qualif                                          *
    * @param i_epis_context                                                   *
    * @param i_summary_and_notes                                              *
    * @param i_episode_context                                                *
    * @param i_wtl_change               Flag that states if the new docum.    *
    *                                   will affect waiting list              *
    * @param   i_flags                  List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                    List of ids: Scale, Documentation, Group
    * @param   i_scores                 List of calculated scores    
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    *                                                                         *
    * @param o_epis_documentation       Generated id_epis_documentation       *
    * @param   o_id_epis_scales_score       The epis_scales_score ID created
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/02/22                            *
    **************************************************************************/
    FUNCTION set_wtl_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT pk_touch_option.g_flg_tab_origin_epis_doc,
        i_wtl_change            IN VARCHAR2,
        i_notes_wtl             IN VARCHAR2,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels epis_documentation data with wtl_documentation logic (based on    *
    * the PK_TOUCH_OPTION.CANCEL_EPIS_DOCUMENTATION function)                    *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_id_episode                                                     *
    * @param i_doc_area                                                       *
    * @param i_id_epis_doc                                                    *
    * @param i_wtl_change                                                     *
    * @param i_id_cancel_reason                                               * 
    * @param i_notes                                                          *
    * @param o_flg_show                                                       *
    * @param o_msg_title                                                      *
    * @param o_msg_text                                                       *
    * @param o_button                                                         *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/02/22                            *
    **************************************************************************/
    FUNCTION cancel_wtl_scale_epis_doc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_wtl_change       IN VARCHAR2,
        i_notes_wtl        IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Function that creates the sys_alert for the planner profiles, in case of an edition to a barthel index
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_patient               Episode identifier
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0
    *  @since                      23-02-2010
    ******************************************************************************/
    FUNCTION set_wtl_func_eval_alert
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_epis_doc   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_id_wtlist  IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************
    *  Returns the summary page values for the scale evaluation summary page.  *
    *                                                                          *
    * @param i_lang                    language id                             *
    * @param i_prof                    professional, software and institution  *
    *                                  ids                                     *
    * @param i_doc_area                documentation area ID                   *
    * @param i_id_episode              the episode id                          *
    * @param i_id_patient              the patient id                          *
    * @param o_doc_area_register       Cursor with the doc area info register  *
    * @param o_doc_area_val            Cursor containing the completed info for* 
    *                                  episode                                 *
    * @param o_doc_scales              Cursor containing the association       *
    *                                  between documentation elements and      *
    *                                  scale values                            *
    * @param o_error                   Error message                           *
    * @return                          true (sucess), false (error)            *
    *                                                                          *
    * @author                          Gustavo Serrano                         *
    * @version                         1.0                                     *
    * @since                           24-02-2010                              *
    ***************************************************************************/
    FUNCTION get_wtl_scales_summ_page
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_doc_area          IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Checks if a patient has a valid epis_documentation associated           *
    * to an admission request                                                 *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_patient                  epis documentation id                 *
    *                                                                         *
    * @param o_error                    Error message                         *
    * @param o_flg_val                  Y - Associated; N - No association    *
    * @param o_last_epis_doc            Id_epis_documentation (if applicable) *
    * @param o_last_date_epis_doc       epis_documentation date(if applicable)*
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/08                            *
    **************************************************************************/
    FUNCTION check_wtl_func_eval_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE DEFAULT pk_summary_page.g_doc_area_barthel,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        o_flg_val            OUT VARCHAR2,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_epis_doc_count     OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Function that creates the sys_alert message for the planner profiles, in case of an edition to a barthel index
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_wtl               Waiting List
    *  @param  o_msg                  Message 
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0
    *  @since                      23-02-2010
    ******************************************************************************/
    FUNCTION get_wtl_func_eval_alert_msg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_wtl IN waiting_list.id_waiting_list%TYPE,
        o_msg    OUT sys_message.desc_message%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtl_func_eval_alert_msg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_wtl IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    /***************************************************************************************************************
    *
    * Inserts a new sorting criteria for the provided institution, if no active requests exist
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_inst              Institution ID 
    * @param      i_wtl_sk            WTL sorting key ID
    * @param      o_error                         
    *
    *
    * @RETURN  TRUE or FALSE, 
    * @author  RicardoNunoAlmeida
    * @version 2.6.0
    * @since   01-03-2010
    *
    ****************************************************************************************************/
    FUNCTION ins_sort_key
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        i_wtl_sk    IN wtl_sort_key.id_wtl_sort_key%TYPE,
        i_rank      IN wtl_sort_key_inst_soft.rank%TYPE,
        i_available IN wtl_sort_key_inst_soft.flg_available%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Deletes an existing sorting criteria for the provided institution, if no active requests exist.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_inst              Institution ID 
    * @param      i_wtl_sk            WTL sorting key ID
    * @param      o_error                         
    *
    *
    * @RETURN  TRUE or FALSE, 
    * @author  RicardoNunoAlmeida
    * @version 2.6.0
    * @since   01-03-2010
    *
    ****************************************************************************************************/
    FUNCTION del_sort_key
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_inst   IN institution.id_institution%TYPE,
        i_wtl_sk IN wtl_sort_key.id_wtl_sort_key%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent.
    *  Note that this function only returns the ids of the waiting list entries to be returned; the info to be displayed
    *  is retrieved independently on function get_wtlist_search_inpatient.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            table_number containing the IDs of all WTL keys to be presented.
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0.1
    *  @since                      03-03-2010
    ******************************************************************************/
    FUNCTION get_wtlist_search_inp_core
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_args_inp IN table_varchar,
        o_wtlist   OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /* returns list of suitable professionals to perform a search with search_waiting_list.
    * These are all the professionals that are either the admission physician or preferred surgeon 
    * in a wl entry not yet scheduled.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data
    * @param i_wl_type           can be S-surgery, B-bed, A-all, null-all
    * @param i_dpb              if not null only wl entries over this date are considered
    * @param i_dpa              if not null only wl entries under this date are considered
    * @param i_ids_dcs            list of dcs to filter profs. NUll = all profs
    * @param o_result            output collection 
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      28-01-2010 
    */
    FUNCTION get_wl_profs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_wl_type IN VARCHAR2,
        i_dt_dpb  IN waiting_list.dt_dpb%TYPE,
        i_dt_dpa  IN waiting_list.dt_dpa%TYPE,
        i_ids_dcs IN table_number,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        patient identifier
    *  @param  i_id_adm_indication Indication for admission identifier
    *  @param  i_flg_schedule      If this function should return scheduled episodes ('Y' - Return scheduled episodes; 'N' - Do not return scheduled episodes)
    *  @param  o_epis_data         output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      01-07-2010
    *
    ******************************************************************************/
    FUNCTION get_episode_like_inp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_flg_schedule      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_epis_data         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        patient identifier
    *  @param  i_id_sr_intervention table_number of surgery interventions identifier's
    *  @param  i_flg_schedule      If this function should return scheduled episodes ('Y' - Return scheduled episodes; 'N' - Do not return scheduled episodes)
    *  @param  o_epis_data         output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      01-07-2010
    *
    ******************************************************************************/
    FUNCTION get_episode_like_oris
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_sr_intervention IN table_number,
        i_flg_schedule       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_epis_data          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        patient identifier
    *  @param  i_id_adm_indication Indication for admission identifier
    *  @param  i_id_sr_intervention table_number of surgery interventions identifier's
    *  @param  i_flg_schedule      If this function should return scheduled episodes ('Y' - Return scheduled episodes; 'N' - Do not return scheduled episodes)
    *  @param  o_epis_data         output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      01-07-2010
    *
    ******************************************************************************/
    FUNCTION get_episode_like_inp_oris
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_adm_indication  IN adm_indication.id_adm_indication%TYPE,
        i_id_sr_intervention IN table_number,
        i_flg_schedule       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_epis_data          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get waiting list ID of an episode
    *
    * @param    I_LANG          Preferred language ID
    * @param    I_PROF          Object (ID of professional, ID of institution, ID of software)
    * @param    I_EPISODE       Episode ID
    * @param    O_WTL           Waiting list ID
    * @param    O_ERROR         Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Tiago Silva
    * @since    2010/08/12
    ********************************************************************************************/
    FUNCTION get_episode_wtl
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_wtl     OUT waiting_list.id_waiting_list%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Clear waiting list data for a group of episodes
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_TABLE_ID_EPISODES  Table containing episodes to remove from the waiting list tables
    * @param    O_ERROR              Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Sergio Dias
    * @since    2010/09/1
    ********************************************************************************************/
    FUNCTION clear_waiting_list_reset
    (
        i_lang              IN NUMBER,
        i_table_id_episodes IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Clear waiting list data in ORIS tables
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_ID_WAITING_LIST    Waiting List ID
    * @param    O_ERROR              Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Sergio Dias
    * @since    2010/09/1
    ********************************************************************************************/
    FUNCTION clear_waiting_list_oris
    (
        i_lang            IN NUMBER,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Clear waiting list data in INPATIENT tables
    *
    * @param    I_LANG          Preferred language ID
    * @param    I_ID_EPISODE    Episode ID
    * @param    O_ERROR         Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Sergio Dias
    * @since    2010/09/1
    ********************************************************************************************/
    FUNCTION clear_waiting_list_inpatient
    (
        i_lang       IN NUMBER,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  universal waiting list search for surgery entries. Market independent
    *
    *  @param  i_lang                            Language ID
    *  @param  i_prof                            Professional ID/Institution ID/Software ID
    *  @param  i_idsInstitutions -> i_idPatient  search criteria
    *  @param  i_page                            pagination info. page is a relative number to the rows per page value
    *  @param  i_rows_per_page                   pagination info. page size
    *  @param  o_result                          output. its a collection of t_wl_search_row
    *  @param  o_rowcount                        absolute row count. Indepedent of pagination
    *  @param  o_error                           error info  
    *
    *  @return                     boolean
    *  @author                     Telmo
    *  @version                    2.6.1.2
    *  @since                      13-01-2012
    ******************************************************************************/
    FUNCTION search_wl_surg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_idsinstitutions     IN table_number,
        i_iddepartment        IN NUMBER,
        i_idclinicalservice   IN NUMBER,
        i_idsprocedures       IN table_number,
        i_idsprefsurgeons     IN table_number,
        i_dtbeginmin          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dtbeginmax          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_idscancelreason     IN table_number,
        i_flgsstatus          IN table_varchar,
        i_minexpectedduration IN NUMBER,
        i_maxexpectedduration IN NUMBER,
        i_flgpos              IN VARCHAR2,
        i_patminage           IN NUMBER,
        i_patmaxage           IN NUMBER,
        i_patgender           IN VARCHAR2,
        i_idpatient           IN NUMBER,
        i_page                IN NUMBER DEFAULT 1,
        i_rows_per_page       IN NUMBER DEFAULT 20,
        o_result              OUT t_wl_search_row_coll,
        o_rowcount            OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_idsInstitutions -> i_PatName    search criteria
    *  @param i_page               pagination info. page is a relative number to the rows per page value
    *  @param i_rows_per_page      pagination info. page size
    *  @param  o_result            output. its a collection of t_wl_search_row
    *  @param  o_rowcount          absolute row count. Indepedent of pagination
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Telmo Castro
    *  @version                    2.6.1.2
    *  @since                      13-01-2012
    ******************************************************************************/
    FUNCTION search_wl_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_idsinstitutions     IN table_number,
        i_iddepartment        IN NUMBER,
        i_idclinicalservice   IN NUMBER,
        i_idsadmphys          IN table_number,
        i_dtbeginmin          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dtbeginmax          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_idscancelreason     IN table_number,
        i_flgsstatus          IN table_varchar,
        i_idsindicadm         IN table_number,
        i_minexpectedduration IN NUMBER,
        i_maxexpectedduration IN NUMBER,
        i_patminage           IN NUMBER,
        i_patmaxage           IN NUMBER,
        i_patgender           IN VARCHAR2,
        i_idpatient           IN NUMBER,
        i_page                IN NUMBER DEFAULT 1,
        i_rows_per_page       IN NUMBER DEFAULT 20,
        o_result              OUT t_wl_search_row_coll,
        o_rowcount            OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * slave function for use by get_wtlist_search_* functions.
    * It is public because it is also used by pk_Schedule_api_downstream.get_wl_req_data.
    * returns search results in the final specification, wich is a collection of t_wl_search_row. 
    */
    FUNCTION get_output_bfs
    (
        i_wl_type      IN VARCHAR2,
        i_ids          IN table_number,
        i_order_clause IN VARCHAR2
    ) RETURN t_wl_search_row_coll;

    FUNCTION get_procedure_diagnosis_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_proc_main_surgeon_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

END pk_wtl_pbl_core;
/
