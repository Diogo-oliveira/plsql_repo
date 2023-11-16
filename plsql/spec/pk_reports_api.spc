/*-- Last Change Revision: $Rev: 2028930 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_reports_api AS

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    /********************************************************************************************
    * Invokation of pk_message.get_message_array.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        i_prof         IN profissional,
        o_desc_msg_arr OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_message.get_message_array.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_message_array_simple
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_patient.get_pat_habit.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_prof         IN profissional,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_inp_nurse.get_scales_summ_page.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_start_date         IN VARCHAR2,
        i_end_date           IN VARCHAR2,
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_groups             OUT pk_types.cursor_type,
        o_scores             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_summary_page.get_summary_page_sections
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_summary_page_sections_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_sysconfig.get_config
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_single_config
    (
        i_lang    IN language.id_language%TYPE,
        i_code_cf IN sys_config.id_sys_config%TYPE,
        i_prof    IN profissional,
        o_msg_cf  OUT sys_config.value%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_sysconfig.get_config
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_array_config
    (
        i_lang    IN language.id_language%TYPE,
        i_code_cf IN table_varchar,
        i_prof    IN profissional,
        o_msg_cf  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_sysconfig.get_config
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_array_config_inst_soft
    (
        i_lang      IN language.id_language%TYPE,
        i_code_cf   IN table_varchar,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_complaint.get_epis_complaint
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_epis_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_docum     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_medication_current.get_current_medication_int
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_current_medication_int
    (
        i_lang         IN language.id_language%TYPE,
        i_epis         IN drug_prescription.id_episode%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN presc.id_presc%TYPE,
        o_this_episode OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_medication_current.get_current_medication_ext
    
    * @author                                  daniel.albuquerque
    * @version                                 0.1
    * @since                                   2011/Dec/06
    ********************************************************************************************/
    FUNCTION get_current_medication_ext
    (
        i_lang              IN language.id_language%TYPE,
        i_epis              IN drug_prescription.id_episode%TYPE,
        i_prof              IN profissional,
        i_flg_only_not_disp IN VARCHAR2 DEFAULT pk_alert_constant.g_no, -- only not dispensed medication
        o_this_episode      OUT pk_types.cursor_type,
        o_print             OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_reports_api.get_prev_med_not_local  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    O_PREVIOUS_MEDICATION           OUT       REF CURSOR
    * @param    O_PREVIOUS_REVIEW               OUT       REF CURSOR
    * @param    O_ERROR                         OUT       T_ERROR_OUT
    *
    * @return   BOOLEAN
    *
    * @author   Rui Marante
    * @version    2.6.2
    * @since    2011-09-06
    *
    * @notes    
    *
    * @status   done
    *
    ********************************************************************************************/
    FUNCTION get_prev_med_not_local
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        o_previous_medication OUT pk_types.cursor_type,
        o_previous_review     OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_discharge.get_follow_up_with_list
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_follow_up_with_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_disch_notes IN discharge_notes.id_discharge_notes%TYPE,
        o_follow_up_with OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_rehab.get_rehab_treatment_plan_int
    
    * @author                                  Jorge Matos
    * @version                                 0.1
    * @since                                   2011/Mai/12
    ********************************************************************************************/
    FUNCTION get_rehab_treatment_plan_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN rehab_plan.id_episode_origin%TYPE,
        i_reports           IN VARCHAR2,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_sch_need          OUT pk_types.cursor_type,
        o_treat             OUT pk_types.cursor_type,
        o_notes             OUT pk_types.cursor_type,
        o_labels            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_treatment_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN rehab_plan.id_episode_origin%TYPE,
        o_treat      OUT pk_types.cursor_type,
        o_sch_need   OUT pk_types.cursor_type,
        o_notes      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_allergy
    
    * @author                                  Joaquim Rocha
    * @version                                 0.1
    * @since                                   2011/May/05
    ********************************************************************************************/
    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_hand_off.get_current_resp_grid
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2011/May/27
    ********************************************************************************************/
    FUNCTION get_current_resp_grid
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_show        IN VARCHAR2 DEFAULT 'A',
        o_grid            OUT pk_types.cursor_type,
        o_has_responsible OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_sr_visit.get_pat_surg_episodes
    
    * @author                                  daniel.albuquerque
    * @version                                 0.1
    * @since                                   2011/Jun/06
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_status   IN VARCHAR2,
        i_planned  IN VARCHAR2,
        o_grid     OUT pk_types.cursor_type,
        o_status   OUT pk_types.cursor_type,
        o_room     OUT pk_types.cursor_type,
        o_id_disch OUT disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_touch_option.get_formatted_value
    
    * @author                                  joaquim.rocha
    * @version                                 0.1
    * @since                                   2011/Jun/29
    ********************************************************************************************/
    FUNCTION get_formatted_value
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN doc_element.flg_type%TYPE,
        i_value IN epis_documentation_det.value%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Invocation of pk_header.get_header
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2011/Jul/14
    ********************************************************************************************/
    FUNCTION get_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_screen_mode IN header.flg_screen_mode%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        i_id_keys     IN table_varchar,
        i_id_values   IN table_varchar,
        o_id_header   OUT header.id_header%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_sr_tools.get_sr_prof_team_det
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2012/Jun/05
    ********************************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        o_id_prof_team OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name    OUT VARCHAR2,
        o_team_desc    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_adt.get_patient_name
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2012/Jun/05
    ********************************************************************************************/
    FUNCTION get_patient_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_name     OUT patient.name%TYPE,
        o_vip_name OUT patient.name%TYPE,
        o_alias    OUT patient.alias%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_reports_api.get_cur_med_reported_4report  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    O_cur                           OUT       REF CURSOR
    * @param    O_CUR_REVIEW                    OUT       REF CURSOR
    * @param    O_ERROR                         OUT       T_ERROR_OUT
    *
    * @return   BOOLEAN
    *
    * @author   Rui Marante
    * @version    2.6.2
    * @since    2011-09-06
    *
    * @notes    
    *
    * @status   done
    *
    ********************************************************************************************/
    FUNCTION get_cur_med_reported_4report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_cur_review OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get professional work phone
    *
    * @param i_lang              Language id (log)
    * @param i_id_professional   Professional identifier
    * @param o_work_phone        Professional work phone
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                    JTS
    * @version                   26371
    * @since                     2013/08/06
    ********************************************************************************************/
    FUNCTION get_prof_work_phone
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_work_phone      OUT professional.work_phone%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_cit.get_cit_report
    *
    * @author                   Jorge Silva
    * @since                    27/08/2013
    ********************************************************************************************/
    FUNCTION get_cit_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invocation of pk_complaint.get_complaint_report
    *
    * @author                   Jorge Silva
    * @since                    25/09/2013
    ********************************************************************************************/
    FUNCTION get_complaint
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_adt.get_health_plan.
    
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2013/Oct/08
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_hp_id_hp        OUT pat_health_plan.id_health_plan%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_hp_in_use       OUT VARCHAR2,
        o_nhn_id_hp       OUT pat_health_plan.id_health_plan%TYPE,
        o_nhn_number      OUT VARCHAR2,
        o_nhn_hp_entity   OUT VARCHAR2,
        o_nhn_hp_desc     OUT VARCHAR2,
        o_nhn_status      OUT VARCHAR2,
        o_nhn_desc_status OUT VARCHAR2,
        o_nhn_in_use      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_api_backoffice.get_inst_account_val.
    
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2013/Oct/29
    ********************************************************************************************/
    FUNCTION get_inst_account_val
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_account     IN accounts.id_account%TYPE,
        o_account_val OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_structure_acronyms
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return id Report and flg available (Y/N)
    *
    * @param i_lang              Language id (log)
    * @param i_prof              Professional identifier
    * @param o_id_report         Report id
    * @param o_flg_available     Flag available
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                   Jorge Silva
    * @since                    14/01/2014
    ********************************************************************************************/
    FUNCTION get_id_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_id_report     OUT reports.id_reports%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return id Report and flg available (Y/N)
    *
    * @param i_lang              Language id (log)
    * @param i_prof              Professional identifier
    * @param i_flg_type          Flag indicate the provenance
    * @param o_id_report         Report id
    * @param o_flg_available     Flag available
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                   Joel Lopes
    * @since                    28/01/2014
    ********************************************************************************************/
    FUNCTION get_epis_recomend_report
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_recomend.id_episode%TYPE,
        i_flg_type IN epis_recomend.flg_type%TYPE,
        i_prof     IN profissional,
        o_temp     OUT pk_types.cursor_type,
        o_def      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Service information for reports presentation (Phone and fax number, responsible physicians)
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_institution            Institution ID
    * @param i_id_department          Service ID
    * @param o_fax_number             Fax Number
    * @param o_phone_number           Phone Number
    * @param o_prof_id_list           List of professionals ids
    * @param o_prof_desc_list         list of professional names concatenated
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/12
    **********************************************************************************************/
    FUNCTION get_service_detail_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_department           IN department.id_department%TYPE,
        o_fax_number              OUT department.fax_number%TYPE,
        o_phone_number            OUT department.phone_number%TYPE,
        o_prof_id_list            OUT table_number,
        o_prof_name_list          OUT table_varchar,
        o_prof_desc_list          OUT VARCHAR2,
        o_prof_aff_list           OUT table_varchar,
        o_desc_prof_aff           OUT VARCHAR2,
        o_service_name            OUT VARCHAR2,
        o_prof_id_not_resp_list   OUT table_number,
        o_prof_name_not_resp_list OUT table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a header return a esi level or not (true/false)
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Professional identifier
    * @param i_id_episode             Episode Id
    * @param o_flg_level              Flag is level or epis_type (Y-level N-epis_type)
    * @param o_epis_type              Description of level or epis_type
    *
    * @return                         true or false
    *
    * @author                         JS
    * @version                        2.6.3
    * @since                          2014/02/24
    **********************************************************************************************/
    FUNCTION get_epis_esi_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_level  OUT VARCHAR2,
        o_epis_type  OUT VARCHAR2,
        o_acronym    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert records on the table rep_template_cfg (true/false)
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Professional identifier
    * @param i_doc_area               Doc area Id
    * @param i_report                 Report Id
    * @param i_concept                Concept Id
    * @param i_market                 Market Id
    * @param i_software               Software Id
    * @param i_institution            Institution Id                    
    * @param i_doc_template           Doc Template Id                        
    *
    * @return                         true or false
    *
    * @author                         Ricardo Pires
    * @version                        2.6.4
    * @since                          2014/07/04
    **********************************************************************************************/
    FUNCTION insert_into_rep_template_cfg
    (
        i_lang         IN language.id_language%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_reports      IN reports.id_reports%TYPE,
        i_concept      IN concept.id_concept%TYPE,
        i_market       IN market.id_market%TYPE,
        i_software     IN software.id_software%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_doc_template IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the id_doc_are and id_doc_template for a specific report
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_report                 Report Id
    * @param i_concept                Concept Id
    * @param i_market                 Market Id
    * @param i_software               Software Id
    * @param i_institution            Institution Id                                         
    *
    * @param o_rep_template_cfg       Array with id_doc_area and id_doc_template
    *    
    * @return                         true or false
    *
    * @author                         Ricardo Pires
    * @version                        2.6.4
    * @since                          2014/07/04
    **********************************************************************************************/
    FUNCTION get_rep_template_cfg
    (
        i_lang             IN language.id_language%TYPE,
        i_reports          IN reports.id_reports%TYPE,
        i_concept          IN concept.id_concept%TYPE,
        i_market           IN market.id_market%TYPE,
        i_software         IN software.id_software%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        o_rep_template_cfg OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institution FINESS identifier
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    *
    * @return                   Value
    *
    * @author                   Tiago Pereira
    * @version                  2.6.4.3
    * @since                    2014/12/29
    ********************************************************************************************/
    FUNCTION get_inst_finess
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Insert new logo for a report by config
    *
    *
    * @return                   Value
    *
    * @author                   Tiago Pereira
    * @version                  2.6.4.3.1
    * @since                    05/03/2015
    ********************************************************************************************/
    FUNCTION insert_logo_report_logos
    (
        i_id_reports         reports.id_reports%TYPE,
        i_internal_name      table_varchar,
        i_inst_owner         v_config.id_inst_owner%TYPE,
        i_id_config          v_config.id_config%TYPE,
        i_id_rep_group_logos rep_group_logos.id_rep_group_logos%TYPE,
        i_is_available       table_varchar,
        i_file_names         table_varchar
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert a new id report group to group logos for one report
    *
    *
    * @return                   Value
    *
    * @author                   Tiago Pereira
    * @version                  2.6.5.0
    * @since                    05/03/2015
    ********************************************************************************************/
    FUNCTION insert_report_group_logos(i_report_group_description rep_group_logos.rep_description%TYPE) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_pharm_validated
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_reports       IN NUMBER, -- JSON.ID_REPORTS
        i_filter_name      IN VARCHAR2, -- JSON.GENERIC_PARAMETER_1
        i_id_episode       presc.id_epis_create%TYPE, -- JSON.ID_EPISODE
        i_lov_id           IN NUMBER, -- JSON.GENERIC_PARAMETER_3,
        i_dt_begin         IN VARCHAR2, -- JSON.DT_BEGIN
        i_dt_end           IN VARCHAR2, -- JSON.DT_END
        i_id_custom_filter IN NUMBER, -- JSON.XXX
        o_pharm_val_info   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the last prescription printed for this patient, section "Last Ambulatory Prescription". 
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  i_id_patient                  The Patient ID
    
    * @param  o_info                        Output cursor with medication description, dosage, frequency 
    *
    * @author CRISTINA.OLIVEIRA
    * @since  2016-06-28
    ********************************************************************************************/
    FUNCTION get_presc_printed_by_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the informtaion of diagnosis by id_epis_diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
     *
    * @return                         diagnosis general info
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          16/11/2016
    **********************************************************************************************/
    FUNCTION get_epis_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN epis_diagnosis.flg_type%TYPE,
        i_epis_diag IN table_number,
        o_epis_diag OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the informtaion for hand-off 
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_patient                Patient ID
     *
    * @return                         information for hand-off
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.1
    * @since                          10/04/2017
    **********************************************************************************************/

    FUNCTION get_grid_hand_off_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_diag              OUT pk_types.cursor_type,
        o_sign_v            OUT pk_types.cursor_type,
        o_title_analy       OUT table_clob,
        o_analysis          OUT table_clob,
        o_title_ex_imag     OUT table_clob,
        o_exam_imag         OUT table_clob,
        o_title_exams       OUT table_clob,
        o_exams             OUT table_clob,
        o_title_drug        OUT table_clob,
        o_drug              OUT table_clob,
        o_title_interv      OUT table_clob,
        o_intervention      OUT table_clob,
        o_hidrics           OUT pk_types.cursor_type,
        o_allergies         OUT pk_types.cursor_type,
        o_diets             OUT pk_types.cursor_type,
        o_precautions       OUT pk_types.cursor_type,
        o_icnp_diag         OUT pk_types.cursor_type,
        --
        o_title_handoff OUT VARCHAR2,
        o_handoff       OUT pk_types.cursor_type,
        --
        o_patient    OUT patient.id_patient%TYPE,
        o_episode    OUT episode.id_episode%TYPE,
        o_sbar_note  OUT CLOB,
        o_title_sbar OUT VARCHAR2,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns patients that that went throught the prof prefered service.
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    *
    * @return                         information for hand-off
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.1
    * @since                          10/04/2017
    **********************************************************************************************/
    FUNCTION get_pats_from_pref_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /* *
    * Returns shifts summary notes for the 24h
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_start_date             initial date
    * @param i_end_date               final date
    * @param i_tbl_episode            list of episode
    *
    * @return                         description
    *
    * @author               Carlos FErreira
    * @version              2.7.1
    * @since                28-04-2017
    */
    FUNCTION get_rep_pn_24h
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_start_date  IN VARCHAR2,
        i_end_date    IN VARCHAR2,
        i_tbl_episode IN table_number,
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function to get the aih simple information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_simple_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function to get the aih special information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    * @param   i_id_epis_pn   Single Page note id
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_special_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_epis_pn    IN epis_pn.id_epis_pn%TYPE,
        o_data          OUT NOCOPY pk_types.cursor_type,
        o_repeated_data OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_patient Patient's id
    * @i_episode Current Episode
    * @o_list  list of all the supply requests and consumptions
    * @o_error Error info
    * 
    * @return  True on success, false on error
    *
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   9/11/09
    **********************************************************************************************/

    FUNCTION get_list_req_cons_no_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        i_flg_status     IN table_varchar,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_wf_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_sup_wf IN supply_workflow.id_supply_workflow%TYPE,
        o_register  OUT pk_types.cursor_type,
        o_req       OUT pk_types.cursor_type,
        o_canceled  OUT pk_types.cursor_type,
        o_rejected  OUT pk_types.cursor_type,
        o_consumed  OUT pk_types.cursor_type,
        o_others    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_list_req_cons_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN episode.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN supply.flg_type%TYPE,
        i_flg_status IN table_varchar,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get consumption and count supplies
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                Episode ID
    *
    * @param    o_sup_cons_count_v2         Cursor with list of supplies consumption and count
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/29
    **********************************************************************************************/
    FUNCTION get_supplies_consumed_counted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Detail of supply count
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_sr_supply_count        ID sr_supply_count
    *
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/12/06
    **********************************************************************************************/
    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_list_req_cons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN episode.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_prof
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
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
    * @author    Vítor Sá
    * @since     2018/08/09
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        o_adm_request       OUT pk_types.cursor_type,
        o_diag              OUT pk_types.cursor_type,
        o_surg_specs        OUT pk_types.cursor_type,
        o_pref_surg         OUT pk_types.cursor_type,
        o_procedures        OUT pk_types.cursor_type,
        o_ext_disc          OUT pk_types.cursor_type,
        o_danger_cont       OUT pk_types.cursor_type,
        o_preferred_time    OUT pk_types.cursor_type,
        o_pref_time_reason  OUT pk_types.cursor_type,
        o_pos               OUT pk_types.cursor_type,
        o_surg_request      OUT pk_types.cursor_type,
        o_waiting_list      OUT pk_types.cursor_type,
        o_unavailabilities  OUT pk_types.cursor_type,
        o_sched_period      OUT pk_types.cursor_type,
        o_referral          OUT pk_types.cursor_type,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_pos_validation    OUT pk_types.cursor_type,
        -- Clinical Questions
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient delivery information
    *
    * @param i_lang             The language ID
    * @param i_prof             Object (professional ID, institution ID, software ID)
    * @param i_patient          Patient ID
    * @param o_info             cursor with all information
    * @param o_error            Error message
    *
    * @return                   true or false on success or error
    *
    * @author                   Elisabete Bugalho
    * @version                  2.7.4.0
    * @since                    2018-09-10
    **********************************************************************************************/
    FUNCTION get_patient_delivery_info
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_task_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        i_scope     IN NUMBER,
        o_bp_list   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_adverse_reaction_rep
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        o_data_transfusion    OUT pk_types.cursor_type,
        o_data_vital_signs    OUT pk_types.cursor_type,
        o_data_clinical_sympt OUT VARCHAR2,
        o_data_medicine       OUT VARCHAR2,
        o_data_lab_tests_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surg_request_by_oris_epis
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        o_prof_resp                 OUT professional.id_professional%TYPE,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_report_cfg_adv_reaction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rep_section       IN rep_section.id_rep_section%TYPE,
        i_report            IN reports.id_reports%TYPE,
        i_task_type_context IN rep_section_cfg_inst_soft.id_task_type_context%TYPE,
        o_cursor            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_MAP_A_B - Returns the b value that matches all the other parameters passed
    *
    * @param i_a_system              IN MAPS.a_system%TYPE
    * @param i_a_definition          IN MAPS.a_def%TYPE
    * @param i_a_value               IN MAPS.a_value%TYPE
    * @param i_b_system              IN MAPS.b_system%TYPE
    * @param i_b_definition          IN MAPS.b_def%TYPE
    * @param i_b_value               IN MAPS.b_value%TYPE
    *
    * @return                The mapped value
    *
    * @author                filipe.f.pereira
    * @version               1.0
    * @since                 23/07/2019
    ********************************************************************************************/
    FUNCTION get_map_a_b
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_a_system     IN pk_translation.t_desc_translation,
        i_b_system     IN pk_translation.t_desc_translation,
        i_a_value      IN pk_translation.t_desc_translation,
        i_a_definition IN pk_translation.t_desc_translation,
        i_b_definition IN pk_translation.t_desc_translation,
        o_b_value      OUT NOCOPY VARCHAR2,
        o_error        OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN;

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

    --hhc_request
    FUNCTION get_hhc_req_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_hist   IN VARCHAR2,
        o_request    OUT pk_types.cursor_type,
        o_status     OUT pk_types.cursor_type,
        o_int_hhc    OUT pk_types.cursor_type,
        o_team       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_hhc_discharge_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_exception EXCEPTION;
    g_yes CONSTANT VARCHAR2(1) := 'Y';

    FUNCTION get_sev_scores_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_values          OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_sev_score_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN NUMBER,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_value           OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_bed_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pdms_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
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
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_pnv_flg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_vaccinated OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_adt.check_sus_health_plan.
    
    * @author                                  Anna Kurowska
    * @version                                 2.8
    * @since                                   2020/Dec/21
    ********************************************************************************************/
    FUNCTION check_sus_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_has_sus    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_img_logo_by_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_inst_logo   OUT institution_logo.img_logo%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the software of one episode
    *
    * @param i_lang                language
    * @param i_prof                profissional
    * @param i_id_episode          episode id
    * @param o_id_software         episode software
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luis Gaspar
    * @version                     1.0
    * @since                       2007/02/23
    **********************************************************************************************/
    FUNCTION get_episode_software
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_episode_software
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN software.id_software%TYPE;

    /**
    * Returns the visit ID associated to an episode.
    * This function can be invoked by Flash
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_episode      Episode ID
    *
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10
    */
    FUNCTION get_id_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_visit   OUT visit.id_visit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_visit(i_episode IN episode.id_episode%TYPE) RETURN episode.id_visit%TYPE;

    /********************************************************************************************
    * Return EPIS_TYPE
    *
    * @param i_lang              language id
    * @param i_id_epis           episode id
    * @param o_epis_type         episode type
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Rui Spratley
    * @version                   2.4.2
    * @since                     2008/02/07
    
    * @notes                     This function should not be used by the flash layer
    ********************************************************************************************/
    FUNCTION get_epis_type
    (
        i_lang      IN language.id_language%TYPE,
        i_id_epis   IN social_episode.id_social_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE
    ) RETURN NUMBER;

    /**
    * Gets intake time info
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_intake_time_register   Intake time registered info
    *
    * @param   o_error                  Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN epis_intake_time.id_episode%TYPE,
        o_intake_time_register OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    -------
    FUNCTION get_epis_institution_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN epis_type_soft_inst.id_epis_type%TYPE,
        i_institution IN epis_type_soft_inst.id_institution%TYPE
    ) RETURN NUMBER;

    --***************************************
    FUNCTION get_epis_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_sys     IN external_sys.id_external_sys%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_id_patient(i_episode IN episode.id_episode%TYPE) RETURN NUMBER;

    FUNCTION get_epis_department
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_department%TYPE;

    FUNCTION get_dt_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_admission_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_episode_info OUT pk_types.cursor_type,
        o_diag         OUT pk_types.cursor_type,
        o_surgical     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
END pk_reports_api;
/
