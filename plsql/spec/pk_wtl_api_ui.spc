/*-- Last Change Revision: $Rev: 2015021 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-05-25 10:17:40 +0100 (qua, 25 mai 2022) $*/

CREATE OR REPLACE PACKAGE pk_wtl_api_ui IS

    FUNCTION get_wtlist_search_surgery
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_wtlist OUT pk_types.cursor_type,
        o_error  OUT t_error_out
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
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wtlist_summary_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN table_number,
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
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_adm_request               OUT pk_types.cursor_type,
        o_diag                      OUT pk_types.cursor_type,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_waiting_list              OUT pk_types.cursor_type,
        o_unavailabilities          OUT pk_types.cursor_type,
        o_sched_period              OUT pk_types.cursor_type,
        o_referral                  OUT pk_types.cursor_type,
        o_doc_area_register         OUT pk_types.cursor_type,
        o_doc_area_val              OUT pk_types.cursor_type,
        o_doc_scales                OUT pk_types.cursor_type,
        o_pos_validation            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
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
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_adm_request               OUT pk_types.cursor_type,
        o_diag                      OUT pk_types.cursor_type,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_waiting_list              OUT pk_types.cursor_type,
        o_unavailabilities          OUT pk_types.cursor_type,
        o_sched_period              OUT pk_types.cursor_type,
        o_referral                  OUT pk_types.cursor_type,
        o_doc_area_register         OUT pk_types.cursor_type,
        o_doc_area_val              OUT pk_types.cursor_type,
        o_doc_scales                OUT pk_types.cursor_type,
        o_pos_validation            OUT pk_types.cursor_type,
        o_cancel_info               OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
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
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_wtlist OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION undelete_wtlist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_wtl  IN waiting_list.id_waiting_list%TYPE,
        i_id_epis IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
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
    * @param io_id_waiting_list           Waiting list ID (if exists)     
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
    * @param i_dt_admission               Date of admission (final)
    * @param i_expect_duration            Admission's expected duration
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
    * @param i_flg_add_problem_sp         The surgical procedure's diagnosis should be associated with problems list? 
    * @param i_flg_add_problem_doc        The danger of contamination's diagnosis should be associated with problems list?
    * @param i_flg_add_problem            The diagnosis should be associated with problems list?
    * @param i_diagnosis_adm_req          Admission request diagnosis info
    * @param i_diagnosis_surg_proc        Surgical procedure diagnosis info
    * @param i_diagnosis_contam           Contamination diagnosis info
    * @param i_id_cdr_call                Rule event identifier.
    * @param o_error                     Error
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
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
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
        i_flg_pref_time      IN table_varchar,
        i_reason_pref_time   IN table_number, -- 20
        i_id_sr_intervention IN table_number,
        i_flg_principal      IN table_varchar,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_sp_notes           IN table_varchar, --25
        i_duration           IN schedule_sr.duration%TYPE,
        i_icu                IN schedule_sr.icu%TYPE,
        i_notes_surg         IN schedule_sr.notes%TYPE,
        i_adm_needed         IN schedule_sr.adm_needed%TYPE,
        i_id_sr_pos_status   IN sr_pos_status.id_sr_pos_status%TYPE, --30
        -- Admission Request
        i_surg_needed       IN VARCHAR2,
        i_adm_indication    IN adm_request.id_adm_indication%TYPE,
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
        i_profs_alert           IN table_number DEFAULT NULL,
        i_sr_pos_schedule       IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested      IN VARCHAR2,
        i_pos_req_notes         IN sr_pos_schedule.req_notes%TYPE,
        --supplies
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
        --Team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number,
        i_tbl_prof       IN table_table_number,
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar, --85
        i_test           IN VARCHAR2,
        --Diagnosis XMLs
        i_diagnosis_adm_req   IN CLOB,
        i_diagnosis_surg_proc IN table_clob,
        i_diagnosis_contam    IN CLOB,
        -- clinical decision rules
        i_id_cdr_call IN cdr_call.id_cdr_call%TYPE,
        i_id_ct_io    IN table_table_varchar, --90
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_adm_surg_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list IN OUT waiting_list.id_waiting_list%TYPE,
        i_data             CLOB,
        i_profs_alert      IN table_number DEFAULT NULL, --65
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set        IN VARCHAR2,
        o_adm_request      OUT adm_request.id_adm_request%TYPE,
        o_msg_error        OUT VARCHAR2,
        o_title_error      OUT VARCHAR2,
        o_error            OUT t_error_out
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
    *  updating and admission request.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier    
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      01-03-2010
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
        o_error      OUT t_error_out
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
    * @param   o_id_epis_scales_score   The epis_scales_score ID created  *    
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

    /********************************************************************************************
    *  Get waiting line ID of an episode
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
    *
    ********************************************************************************************/

    FUNCTION set_surgery_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        -- Logic
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list IN OUT waiting_list.id_waiting_list%TYPE,
        i_data             CLOB,
        i_profs_alert      IN table_number DEFAULT NULL, --65
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        o_msg_error        OUT VARCHAR2,
        o_title_error      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_surgery_request
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_inst_dest      IN institution.id_institution%TYPE,
        io_id_episode_sr IN OUT episode.id_episode%TYPE,
        -- Waiting List
        io_id_waiting_list IN OUT waiting_list.id_waiting_list%TYPE,
        --Scheduling period
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2,
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        --Unavailability period
        i_unav_period_start IN table_varchar,
        i_unav_period_end   IN table_varchar,
        -- Surgery Request
        i_pref_surgeons      IN table_number,
        i_external_dcs       IN table_number,
        i_dep_clin_serv_sr   IN table_number,
        i_flg_pref_time      IN table_varchar,
        i_reason_pref_time   IN table_number,
        i_id_sr_intervention IN table_number,
        i_flg_principal      IN table_varchar,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_sp_notes           IN table_varchar,
        i_duration           IN schedule_sr.duration%TYPE,
        i_icu                IN schedule_sr.icu%TYPE,
        i_notes_surg         IN schedule_sr.notes%TYPE,
        i_id_sr_pos_status   IN sr_pos_status.id_sr_pos_status%TYPE,
        --Barthel Index Template
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_flg_type          IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_wtl_change            IN VARCHAR2,
        --Profs alert WTL incomplete
        i_profs_alert IN table_number DEFAULT NULL,
        --POS Validation Request
        i_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested IN VARCHAR2,
        i_pos_req_notes    IN sr_pos_schedule.req_notes%TYPE,
        --supplies
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
        --Team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number,
        i_tbl_prof       IN table_table_number,
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar,
        i_test           IN VARCHAR2,
        --Diagnosis XMLs
        i_diagnosis_surg_proc IN table_clob,
        i_diagnosis_contam    IN CLOB,
        -- clinical decision rules
        i_id_cdr_call IN cdr_call.id_cdr_call%TYPE,
        i_id_ct_io    IN table_table_varchar,
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    g_xml_value           CONSTANT VARCHAR2(20 CHAR) := 'VALUE';
    g_xml_alt_value       CONSTANT VARCHAR2(20 CHAR) := 'ALT_VALUE';
    g_xml_epis_diagnoses  CONSTANT VARCHAR2(20 CHAR) := 'EPIS_DIAGNOSES';
    g_xml_component_leaf  CONSTANT VARCHAR2(20 CHAR) := 'COMPONENT_LEAF';
    g_xml_additional_info CONSTANT VARCHAR2(20 CHAR) := 'ADDITIONAL_INFO';
    g_xml_internal_name   CONSTANT VARCHAR2(20 CHAR) := 'INTERNAL_NAME';
    g_xml_desc_value      CONSTANT VARCHAR2(20 CHAR) := 'DESC_VALUE';

END pk_wtl_api_ui;
/
