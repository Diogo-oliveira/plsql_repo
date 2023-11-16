/*-- Last Change Revision: $Rev: 2052330 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-12-06 15:30:48 +0000 (ter, 06 dez 2022) $*/

CREATE OR REPLACE PACKAGE pk_episode IS

    ------------------
    g_error        VARCHAR2(4000); -- Localização dos erros
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(30 CHAR);
    g_day_in_seconds CONSTANT NUMBER := 86399; -- 23:59:59 in seconds

    g_epis_consult epis_type.id_epis_type%TYPE;
    g_epis_cs      epis_type.id_epis_type%TYPE;
    g_epis_nurse   epis_type.id_epis_type%TYPE;

    g_months_sign VARCHAR2(200);
    g_days_sign   VARCHAR2(200);

    g_exception EXCEPTION;
    g_found BOOLEAN;

    g_documentation sys_config.value%TYPE;

    --

    g_flg_complaint CONSTANT VARCHAR2(1) := 'C';
    g_flg_anamnesis CONSTANT VARCHAR2(1) := 'A';
    g_flg_def       CONSTANT VARCHAR2(1) := 'D';
    g_flg_temp      CONSTANT VARCHAR2(1) := 'T';
    g_flg_fam       CONSTANT VARCHAR2(1) := 'F';
    g_flg_soc       CONSTANT VARCHAR2(1) := 'S';

    g_flg_aval CONSTANT epis_recomend.flg_type%TYPE := 'A';
    g_flg_plan CONSTANT epis_recomend.flg_type%TYPE := 'L';
    g_flg_subj CONSTANT epis_recomend.flg_type%TYPE := 'S';
    g_flg_obj  CONSTANT epis_recomend.flg_type%TYPE := 'B';

    --g_document_n             CONSTANT sys_config.VALUE%TYPE := 'N';
    g_document_d CONSTANT sys_config.value%TYPE := 'D';

    g_area_history           CONSTANT doc_area.id_doc_area%TYPE := 21;
    g_area_review            CONSTANT doc_area.id_doc_area%TYPE := 22;
    g_area_past_med_hist     CONSTANT doc_area.id_doc_area%TYPE := 24;
    g_area_past_med_hist_alt CONSTANT doc_area.id_doc_area%TYPE := 45;
    g_area_physical_exam     CONSTANT doc_area.id_doc_area%TYPE := 28;

    g_new_fluid CONSTANT VARCHAR2(1) := 'N';
    g_fluid     CONSTANT VARCHAR2(1) := 'F';

    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';

    g_epis_type_physiotherapy CONSTANT sys_config.value%TYPE := 'ID_EPIS_TYPE_TEHRAPIST';

    g_id_allergy_unawareness CONSTANT PLS_INTEGER := 3;

    g_owner_name CONSTANT VARCHAR2(5) := 'ALERT';
    g_pck_name   CONSTANT VARCHAR2(12) := 'PK_EPISODE';
    g_flg_type_a CONSTANT VARCHAR2(1) := 'A';
    g_flg_type_m CONSTANT VARCHAR2(1) := 'M';

    g_dictation_area_plan dictation_report.id_work_type%TYPE := 10;
    g_flg_sep            CONSTANT VARCHAR2(3 CHAR) := ' - ';
    g_flg_sep_slash      CONSTANT VARCHAR2(3 CHAR) := ' / ';
    g_flg_sep_colon      CONSTANT VARCHAR2(3 CHAR) := ': ';
    g_flg_sep_open_par   CONSTANT VARCHAR2(2 CHAR) := ' (';
    g_flg_sep_close_par  CONSTANT VARCHAR2(2 CHAR) := ')';
    g_flg_sep_semi_colon CONSTANT VARCHAR2(2 CHAR) := '; ';
    g_d                  CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_sd_dr sys_domain.code_domain%TYPE := 'DICTATION_REPORT.REPORT_STATUS';

    --SYS_CONFIG used in function get_prev_episodes to obtain report id
    g_prev_epis_config sys_config.id_sys_config%TYPE := 'PREV_EPIS_REPORT';

    --Previous appointments filter type
    g_prev_app_with_me_c    CONSTANT VARCHAR2(1 CHAR) := 'C'; -- Comigo, neste tipo de consulta
    g_prev_app_this_spec_t  CONSTANT VARCHAR2(1 CHAR) := 'T'; -- Neste tipo de consulta
    g_prev_app_other_spec_e CONSTANT VARCHAR2(1 CHAR) := 'E'; -- Doutra especialidade
    g_prev_app_all_specs_te CONSTANT VARCHAR2(2 CHAR) := 'TE'; --Todas as especialidades

    g_scope_visit   CONSTANT VARCHAR(1 CHAR) := 'V';
    g_scope_episode CONSTANT VARCHAR(1 CHAR) := 'E';
    g_scope_patient CONSTANT VARCHAR(1 CHAR) := 'P';

    k_exam                CONSTANT NUMBER(24) := 6;
    k_procedures          CONSTANT NUMBER(24) := 10;
    k_lab_test            CONSTANT NUMBER(24) := 11;
    k_diet                CONSTANT NUMBER(24) := 52;
    k_pat_educ            CONSTANT NUMBER(24) := 42;
    k_comm_orders         CONSTANT NUMBER(24) := 83;
    k_positioning         CONSTANT NUMBER(24) := 48;
    k_nnn                 CONSTANT NUMBER(24) := 70;
    k_monit               CONSTANT NUMBER(24) := 9;
    k_hidrics             CONSTANT NUMBER(24) := 105;
    k_icnp                CONSTANT NUMBER(24) := 37;
    k_medication          CONSTANT NUMBER(24) := 12;
    k_pharmacy            CONSTANT NUMBER(24) := 13;
    k_rehab               CONSTANT NUMBER(24) := 50;
    k_appoitments         CONSTANT NUMBER(24) := 1;
    k_opinion             CONSTANT NUMBER(24) := 4;
    k_inpatient_admission CONSTANT NUMBER(24) := 34;
    k_surgery_admission   CONSTANT NUMBER(24) := 35;

    -- sys config to get id_cancel_reason to use on job inactive_no_show
    g_inactive_no_show_creason CONSTANT VARCHAR2(100 CHAR) := 'INACTIVE_OUTP_NO_SHOW.ID_CANCEL_REASON';
    g_schdl_outp_state_domain  CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_STATE';
    g_schdl_outp_sched_domain  CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_SCHED';

    FUNCTION get_epis_header_reports
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat              IN patient.id_patient%TYPE,
        i_id_sched            IN schedule.id_schedule%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof_id             IN professional.id_professional%TYPE,
        i_prof_inst           IN institution.id_institution%TYPE,
        i_prof_sw             IN software.id_software%TYPE,
        o_name                OUT patient.name%TYPE,
        o_gender              OUT patient.gender%TYPE,
        o_age                 OUT VARCHAR2,
        o_health_plan         OUT VARCHAR2,
        o_compl_diag          OUT VARCHAR2,
        o_prof_name           OUT VARCHAR2,
        o_prof_spec           OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_episode             OUT pk_types.cursor_type,
        o_clin_rec            OUT pk_types.cursor_type,
        o_location            OUT pk_types.cursor_type,
        o_sched               OUT pk_types.cursor_type,
        o_efectiv             OUT pk_types.cursor_type,
        o_atend               OUT pk_types.cursor_type,
        o_wait                OUT pk_types.cursor_type,
        o_pat_photo           OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_shcut_habits        OUT VARCHAR2,
        o_shcut_allergies     OUT VARCHAR2,
        o_shcut_episodes      OUT VARCHAR2,
        o_shcut_bloodtype     OUT VARCHAR2,
        o_shcut_relevdiseases OUT VARCHAR2,
        o_shcut_relevnotes    OUT VARCHAR2,
        o_shcut_photo         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_header
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat              IN patient.id_patient%TYPE,
        i_id_sched            IN schedule.id_schedule%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        o_name                OUT patient.name%TYPE,
        o_gender              OUT patient.gender%TYPE,
        o_age                 OUT VARCHAR2,
        o_health_plan         OUT VARCHAR2,
        o_compl_diag          OUT VARCHAR2,
        o_prof_name           OUT VARCHAR2,
        o_prof_spec           OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_episode             OUT pk_types.cursor_type,
        o_clin_rec            OUT pk_types.cursor_type,
        o_location            OUT pk_types.cursor_type,
        o_sched               OUT pk_types.cursor_type,
        o_efectiv             OUT pk_types.cursor_type,
        o_atend               OUT pk_types.cursor_type,
        o_wait                OUT pk_types.cursor_type,
        o_pat_photo           OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_shcut_habits        OUT VARCHAR2,
        o_shcut_allergies     OUT VARCHAR2,
        o_shcut_episodes      OUT VARCHAR2,
        o_shcut_bloodtype     OUT VARCHAR2,
        o_shcut_relevdiseases OUT VARCHAR2,
        o_shcut_relevnotes    OUT VARCHAR2,
        o_shcut_photo         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_header_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_prof        IN profissional,
        o_desc_info   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_first_subsequent
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat       IN patient.id_patient%TYPE,
        i_id_clin_serv IN clinical_service.id_clinical_service%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_epis_type    IN episode.id_epis_type%TYPE,
        o_flg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_first_subseq
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat       IN patient.id_patient%TYPE,
        i_id_clin_serv IN clinical_service.id_clinical_service%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_epis_type    IN episode.id_epis_type%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the external episode ID 
    *
    * @param i_lang                   The id language
    * @param i_prof                   Professional, software and institution id
    * @param i_ext_sys                External system ID
    * @param i_episode                Episode ID         
    * @param i_institution            Institution ID
    *
    * @return                         External episode ID
    *
    * @author  José Silva
    * @date    29-12-2011
    * @version 2.5.1.11
    **********************************************************************************************/
    FUNCTION get_epis_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_sys     IN external_sys.id_external_sys%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN epis_ext_sys.value%TYPE;

    FUNCTION get_epis_ext
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_dt_efectiv OUT VARCHAR2,
        o_dt_atend   OUT VARCHAR2,
        o_episode    OUT epis_ext_sys.value%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prev_episode
    (
        i_lang  IN language.id_language%TYPE,
        i_pat   IN patient.id_patient%TYPE,
        i_type  IN episode.id_epis_type%TYPE,
        i_prof  IN profissional,
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_s
    (
        i_lang            IN NUMBER,
        i_pat             IN NUMBER,
        i_epis            IN table_number,
        i_prof            IN profissional,
        o_complaint       OUT pk_types.cursor_type,
        o_history_doc     OUT pk_types.cursor_type,
        o_history_ft      OUT pk_types.cursor_type,
        o_fam_hist        OUT pk_types.cursor_type,
        o_soc_hist        OUT pk_types.cursor_type,
        o_allergy         OUT pk_types.cursor_type,
        o_habit           OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_info10          OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_surgical_hist   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_s
    (
        i_lang            IN NUMBER,
        i_pat             IN NUMBER,
        i_epis            IN table_number,
        i_prof            IN profissional,
        i_review          IN BOOLEAN,
        o_complaint       OUT pk_types.cursor_type,
        o_history         OUT pk_types.cursor_type,
        o_review          OUT pk_types.cursor_type,
        o_fam_hist        OUT pk_types.cursor_type,
        o_soc_hist        OUT pk_types.cursor_type,
        o_allergy         OUT pk_types.cursor_type,
        o_habit           OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_info10          OUT pk_types.cursor_type,
        o_surgical_hist   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_o
    (
        i_lang           IN NUMBER,
        i_pat            IN NUMBER,
        i_epis           IN table_number,
        i_prof           IN profissional,
        o_vital_sign     OUT pk_types.cursor_type,
        o_biometric      OUT pk_types.cursor_type,
        o_phys_exam      OUT pk_types.cursor_type,
        o_monitorization OUT pk_types.cursor_type,
        o_problems       OUT pk_types.cursor_type,
        o_blood_group    OUT pk_types.cursor_type,
        o_info7          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_a
    (
        i_lang        IN NUMBER,
        i_pat         IN NUMBER,
        i_epis        IN table_number,
        i_prof        IN profissional,
        i_prev_visits IN sys_domain.val%TYPE DEFAULT pk_alert_constant.g_no,
        o_problems    OUT pk_types.cursor_type,
        o_ass_scales  OUT pk_types.cursor_type,
        o_body_diags  OUT pk_types.cursor_type,
        o_diag        OUT pk_types.cursor_type,
        o_impressions OUT pk_types.cursor_type,
        o_evaluation  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_p
    (
        i_lang                 IN NUMBER,
        i_pat                  IN NUMBER,
        i_epis                 IN table_number,
        i_prof                 IN profissional,
        o_analysis             OUT pk_types.cursor_type,
        o_exam                 OUT pk_types.cursor_type,
        o_presc_ext            OUT pk_types.cursor_type,
        o_dietary_ext          OUT pk_types.cursor_type,
        o_manip_ext            OUT pk_types.cursor_type,
        o_presc                OUT pk_types.cursor_type,
        o_interv               OUT pk_types.cursor_type,
        o_monitorization       OUT pk_types.cursor_type,
        o_nurse_act            OUT pk_types.cursor_type,
        o_nurse_teach          OUT pk_types.cursor_type,
        o_plan                 OUT pk_types.cursor_type,
        o_therapeutic_decision OUT pk_types.cursor_type,
        o_referrals            OUT pk_types.cursor_type,
        o_gp_notes             OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_estate_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_id_epis     IN estate.id_episode%TYPE,
        i_desc_estate IN estate.desc_estate%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_estate_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis     IN social_episode.id_social_episode%TYPE,
        o_estate_epis OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the episode type
    *
    * @param i_lang              language id
    * @param i_prof              professional
    * @param i_id_epis           episode id
    * @param o_epis_type         episode type
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Ana Matos
    * @version                   2.4.3
    * @since                     2008/10/27
    ********************************************************************************************/

    FUNCTION get_epis_type_new
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_epis   IN episode.id_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type
    (
        i_lang      IN language.id_language%TYPE,
        i_id_epis   IN social_episode.id_social_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
    ********************************************************************************************/

    FUNCTION get_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Return EPIS_TYPE
    *
    * @param i_lang              language id
    * @param i_id_epis           episode id
    
    * @return                    epis_type
    *
    * @author                    Rui Spratley
    * @version                   2.4.2
    * @since                     2008/02/07
    ********************************************************************************************/

    FUNCTION get_nkda_label
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        o_nkda   OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    --
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
    * @author                      Sofia Mendes
    * @version                     2.6.2
    * @since                       13-Jul-2012
    **********************************************************************************************/

    FUNCTION get_episode_software
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN software.id_software%TYPE;
    --
    /**********************************************************************************************
    * Actualizar o episódio de origem do espólio bem como as respectivas tabelas de relação.
      Utilizada aquando a passagem de Urgência para Internamento será necessário actualizar o ID_EPISODE no espólio
      com o novo episódio (INP) e o ID_EPISODE_ORIGIN ficará com o episódio de urgência (EDIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          categoty professional
    * @param i_episode                episode id
    * @param i_new_episode            new episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/04/10
    **********************************************************************************************/
    FUNCTION update_estate
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_new_episode   IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prev_epis_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_type             IN VARCHAR2,
        i_search               IN NUMBER,
        i_epis_type            IN epis_type.id_epis_type%TYPE,
        i_id_epis_hhc_req      IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_info                 OUT pk_types.cursor_type,
        o_doc_area_register    OUT NOCOPY pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val         OUT NOCOPY pk_touch_option.t_cur_doc_area_val,
        o_template_layouts     OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component   OUT NOCOPY pk_types.cursor_type,
        o_brief_desc           OUT pk_types.cursor_type,
        o_desc_doc_area        OUT pk_types.cursor_type,
        o_desc_doc_area_detail OUT pk_types.cursor_type,
        o_supp_list            OUT pk_types.cursor_type,
        o_nurse_teach          OUT pk_types.cursor_type,
        o_diag                 OUT pk_types.cursor_type,
        --    o_impressions           OUT pk_types.cursor_type,
        o_warning_msg OUT pk_translation.t_desc_translation,
        --     o_ass_scales            OUT pk_types.cursor_type,
        --     o_doc_area_register_obs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prev_epis_det
    (
        i_lang            IN language.id_language%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN table_number,
        i_prof            IN profissional,
        o_complaint       OUT pk_types.cursor_type,
        o_allergy         OUT pk_types.cursor_type,
        o_habit           OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_vital_sign      OUT pk_types.cursor_type,
        o_biometric       OUT pk_types.cursor_type,
        o_blood_group     OUT pk_types.cursor_type,
        o_info7           OUT pk_types.cursor_type,
        o_problems        OUT pk_types.cursor_type,
        o_ass_scales      OUT pk_types.cursor_type,
        o_body_diags      OUT pk_types.cursor_type,
        o_diag            OUT pk_types.cursor_type,
        o_impressions     OUT pk_types.cursor_type,
        o_evaluation      OUT pk_types.cursor_type,
        o_analysis        OUT pk_types.cursor_type,
        o_exam            OUT pk_types.cursor_type,
        o_presc_ext       OUT pk_types.cursor_type,
        o_dietary_ext     OUT pk_types.cursor_type,
        o_manip_ext       OUT pk_types.cursor_type,
        o_presc           OUT pk_types.cursor_type,
        o_interv          OUT pk_types.cursor_type,
        o_monitorization  OUT pk_types.cursor_type,
        o_nurse_act       OUT pk_types.cursor_type,
        o_nurse_teach     OUT pk_types.cursor_type,
        o_referrals       OUT pk_types.cursor_type,
        o_gp_notes        OUT pk_types.cursor_type,
        ---o_intervmfr              OUT pk_types.cursor_type,
        o_doc_area_register      OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val           OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_cits                   OUT pk_types.cursor_type,
        o_discharge_instructions OUT pk_types.cursor_type,
        o_discharge              OUT pk_types.cursor_type,
        o_surgical_hist          OUT pk_types.cursor_type,
        o_past_hist_ft           OUT pk_types.cursor_type,
        o_surgery_record         OUT pk_types.cursor_type,
        o_risk_factors           OUT pk_types.cursor_type,
        o_obstetric_history      OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Returns the status of an episode.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional information
    * @param i_id_episode      Episode ID
    * @param o_flg_status      Status of the episode
    * @param o_error           Error message
    * 
    * @return                  Status of the episode if succeeded, NULL otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-Apr-17
    *
    ******************************************************************************/
    FUNCTION get_flg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_status OUT episode.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Checks if an episode is temporary or definitive.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional information
    * @param i_id_episode      Episode ID
    * @param o_flg_unknown     Type of the episode
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-Apr-17
    *
    ******************************************************************************/
    FUNCTION get_flg_unknown
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_flg_unknown OUT episode.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
        * Procedimento para actualizar as mviews
        * mv_episode_act e mv_episode_act_pend por forma a poder utilizar os procedimentos update_mv_episodes
        * ou update_mv_episodes_no_timeout consoante o valor da sys_config REFRESH_MVIEWS_WITH_NO_TIMEOUT_PROCEDURE 
        * 
        * Solução temporária para resolver os problemas de efectivação dos softwares de ambulatório
    *
    * @author Sérgio Santos, 12-05-2009
    */
    PROCEDURE update_mv_episodes_temp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );
    /**
    * Procedimento para actualizar as mviews
    * mv_episode_act e mv_episode_act_pend
    *
    * @author João Eiras, 30-07-2007
    */
    PROCEDURE update_mv_episodes;

    /************************************************************************************************************
    * This function returns the visit id associated to a episode
    *
    * @param      i_episode         Episode Id
    *
    * @return     Visit Id
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/10/13
    ************************************************************************************************************/
    FUNCTION get_id_visit(i_episode IN episode.id_episode%TYPE) RETURN episode.id_visit%TYPE;

    /**
    * Returns the visit ID associated to an episode.
    * This function can be invoked by Flash.
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

    /********************************************************************************************
    * Returns id_patient associated to episode
    *                                                                                                                                          
    * @param i_episode                Episode ID                                                                                              
    * @return                         Patient ID                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2008/10/06                                                                                               
    ********************************************************************************************/
    FUNCTION get_id_patient(i_episode IN episode.id_episode%TYPE) RETURN patient.id_patient%TYPE;

    /********************************************************************************************
    * This function returns the id_software associated to a type of episode in an institution
    *                                                                                                                                          
    * @param i_epis_type              Type of episode
    * @param i_institution            Institution ID                                                                                              
    * @return                         Software ID                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2008/11/10                                                                                               
    ********************************************************************************************/
    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN epis_type_soft_inst.id_epis_type%TYPE,
        i_institution IN epis_type_soft_inst.id_institution%TYPE
        
    ) RETURN epis_type_soft_inst.id_software%TYPE;

    /*******************************************************************************************************************************************
    *GET_ORDERED_LIST Return a ordered episodes list                                                                                           *
    *                                                                                                                                          *
    * @param LANG                     Id language                                                                                              *
    * @param I_PROF                   Profissiona, institution and software identifiers                                                        *
    * @param I_EPISODE                Episode identifier                                                                                       *
    * @param O_COUNT                  Number of records                                                                                        *
    * @param O_FIRST                  First record description                                                                                 *    
    * @param O_CODE                   Code description                                                                                 *    
    * @param O_DATE                   First record date                                                                                        *    
    * @param O_FMT                    Format date indicator                                                                                    *    
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return false if any error ocurred and return true otherwise                                              *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/11/17                                                                                               *
    *******************************************************************************************************************************************/

    FUNCTION get_count_and_first
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_count   OUT NUMBER,
        o_first   OUT VARCHAR2,
        o_code    OUT VARCHAR2,
        o_date    OUT VARCHAR2,
        o_fmt     OUT VARCHAR2
        
    ) RETURN BOOLEAN;

    PROCEDURE upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get episode' clinical service description.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Pedro Carneiro
    * @version                         2.5.0.6.2
    * @since                          2009/10/12
    **********************************************************************************************/
    FUNCTION get_cs_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR;

    /**********************************************************************************************
    * Get episode' creation date.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param o_dt_creation            Episode creation date
    * @param o_error                  Error message
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.5.0.7
    * @since                          2009/10/23
    **********************************************************************************************/
    FUNCTION get_epis_dt_creation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_dt_creation OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if episode is temporary for match purposes
    *
    * %param i_lang            language identifier
    * %param i_prof            logged professional structure
    * %param i_episode         episode identifier
    * %param o_is_temporary    varchar2 checking if episode is temporary for match matters
    * %param o_error           Error object
    *
    * @return                  false if errors occur, true otherwise
    *
    * @author                  Fábio Oliveira
    * @version                 2.6.0.0
    * @since                   18-Feb-2010
    **********************************************************************************************/
    FUNCTION check_temporary_for_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_is_temporary OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get episode institution abbreviation.
    *
    * %param i_lang            language identifier
    * %param i_prof            logged professional structure
    * %param i_episode         episode identifier    
    *
    * @return                  Institution abbreviation
    *
    * @author                  Sofia Mendes
    * @version                 2.6.0.3
    * @since                   20-May-2010
    **********************************************************************************************/
    FUNCTION get_epis_institution
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN institution.abbreviation%TYPE;

    /**********************************************************************************************
    * Get episode institution id.
    *
    * %param i_lang            language identifier
    * %param i_prof            logged professional structure
    * %param i_episode         episode identifier    
    *
    * @return                  Institution id
    *
    * @author                  Rui Spratley
    * @version                 2.6.0.4
    * @since                   23-Sep-2010
    **********************************************************************************************/
    FUNCTION get_epis_institution_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN institution.id_institution%TYPE;

    /********************************************************************************************
    * Returns id_patient associated to an episode
    *  
    * @param i_lang            language identifier
    * @param i_prof            logged professional structure                                                                                                                                        
    * @param i_episode                Episode ID                                                                                              
    * @return                         Patient ID                                                        
    *                                                                                                                          
    * @author                         Sofia Mendes                                                                                 
    * @version                         2.6.0.3                                                                                                     
    * @since                          02-Jun-2010                                                                                              
    ********************************************************************************************/
    FUNCTION get_epis_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN patient.id_patient%TYPE;

    /******************************************************************************
    *  Returns id_task_dependency from an episode
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        episode identifier
    *
    *  @return                     id_task_identifier
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      02-07-2010
    *
    ******************************************************************************/
    FUNCTION get_task_dependency
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN episode.id_task_dependency%TYPE;

    /**********************************************************************************************
    * Update id_task_dependency from an episode
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_id_task_dependency     new id_task_dependency identifier
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    *  @author                        Luís Maia
    *  @version                       2.6.0.3
    *  @since                         02-07-2010
    **********************************************************************************************/
    FUNCTION set_task_dependency
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_task_dependency IN episode.id_episode%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get episode's begin date.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param o_dt_begin               Episode begin date
    * @param o_error                  Error message
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         João Martins
    * @version                        2.5.1.2
    * @since                          2010/10/27
    **********************************************************************************************/
    FUNCTION get_epis_dt_begin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_dt_begin   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get episode's begin date in timestamp with local time zone
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param o_dt_begin               Episode begin date
    * @param o_error                  Error message
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         João Martins
    * @version                        2.5.1.2
    * @since                          2010/10/27
    *
    * @author                         ANTONIO.NETO
    * @version                        2.6.2.1
    * @since                          30-Mar-2012
    **********************************************************************************************/
    FUNCTION get_epis_dt_begin_tstz
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_dt_begin_tstz OUT episode.dt_begin_tstz%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the last episode of a patient and checks if it can be reopened
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_patient      Patient ID
    *
    * @param o_last_episode Last episode ID
    * @param o_flg_reopen   Episode can be reopened: Y - yes, N - no
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  José Silva
    * @version 2.6.0.3
    * @since   21-Dec-2010
    **********************************************************************************************/
    FUNCTION get_last_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_flg_discharge IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_last_episode  OUT episode.id_episode%TYPE,
        o_flg_reopen    OUT VARCHAR2,
        o_epis_type     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets intake time
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_patient      Patient id
    * @param   i_intake_time  Intake time
    * @param   o_dt_register  Register date
    *
    * @param   o_error        Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION set_intake_time
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN epis_intake_time.id_episode%TYPE,
        i_patient     IN epis_intake_time.id_patient%TYPE,
        i_intake_time IN VARCHAR2,
        o_dt_register OUT epis_intake_time.dt_register%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

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

    /**
    * Gets the current intake time info
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
    FUNCTION get_intake_time_det
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN epis_intake_time.id_episode%TYPE,
        o_intake_time_register OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets intake time limits for a certain episode
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_intake_time_lim        Intake time limit cursor
    *
    * @param   o_error                  Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time_lim
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN epis_intake_time.id_episode%TYPE,
        o_intake_time_lim OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets intake time limits for a certain episode
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_dt_cur                 Current Date based on Begin Date
    * @param   o_dt_arrival             Last arrival date time
    * @param   o_dt_min                 Minimum Date
    * @param   o_dt_max                 Maximum Date
    * @param   o_error                  Error information
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author                           António Neto
    * @version                          2.6.2
    * @since                            13-Feb-2012
    */
    FUNCTION get_intake_time_lim
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN epis_intake_time.id_episode%TYPE,
        o_dt_cur     OUT epis_intake_time.dt_intake_time%TYPE,
        o_dt_arrival OUT epis_intake_time.dt_intake_time%TYPE,
        o_dt_min     OUT epis_intake_time.dt_intake_time%TYPE,
        o_dt_max     OUT epis_intake_time.dt_intake_time%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that matches two episodes with intake records
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 26-01-2010
    ********************************************************************************************/
    FUNCTION set_intake_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns episode dep_clin_serv
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_episode       Episode Id
    *
    * @return     Dep_clin_serv Id
    *
    * @author     Sofia Mendes
    * @version    2.6.0.5
    * @since      18-Mai-2011
    ************************************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_info.id_dep_clin_serv%TYPE;

    /**
    * Returns the notes according to the given type (evaluation notes, plan notes,...)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                episode identifier
    * @param i_flg_type               Type of notes
    * @param i_order_desc             Sort records from most recent to oldest? 'Y' or 'N'
    *
    * @return               notes
    *
    * @author               Sofia Mendes
    * @version               2.5
    * @since                20/03/2013
    */
    FUNCTION get_epis_recommend_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN epis_recomend.flg_type%TYPE,
        i_order_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /************************************************************************************************************
    * This function returns episode dep_clin_serv
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_episode              Episode Id
    * @param o_id_dep_clin_serv     Dep_clin_serv id
    * @param o_error                Error info
    *
    * @return     boolean
    *
    * @author     Sofia Mendes
    * @version    2.6.0.5
    * @since      18-Mai-2011
    ************************************************************************************************************/
    FUNCTION get_epis_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_id_dep_clin_serv OUT epis_info.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get episode's first observation date.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode             Episode ID
    * @param i_dt_first_obs           First observation date
    * @param i_has_stripes            Has stripes? (N) No (Y) Yes. Found in GRIDS_EA or TRACKING_BOARD_EA.
    *
    * @return                         String with serialized date
    *
    * @author                         José Brito
    * @version                        2.5.1
    * @since                          2011/05/12
    **********************************************************************************************/
    FUNCTION get_epis_dt_first_obs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_dt_first_obs IN epis_info.dt_first_obs_tstz%TYPE,
        i_has_stripes  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get episode's first observation date.
    *
    * @param i_id_episode             Episode ID
    * @param i_dt_first_obs           First observation date
    * @param i_has_stripes            Has stripes? (N) No (Y) Yes. Found in GRIDS_EA or TRACKING_BOARD_EA.
    * @param i_alert_query            Indicates if is called from an alert query: (Y) Yes (N) No - default.
    *
    * @return                         First observation date
    *
    * @author                         José Brito
    * @version                        2.5.1
    * @since                          2011/05/12
    **********************************************************************************************/
    FUNCTION get_epis_dt_first_obs
    (
        i_id_episode   IN episode.id_episode%TYPE,
        i_dt_first_obs IN epis_info.dt_first_obs_tstz%TYPE,
        i_has_stripes  IN VARCHAR2 DEFAULT NULL,
        i_alert_query  IN VARCHAR2 DEFAULT 'N'
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;
    --
    /**
     * This function returns the scope of episodes
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     * @param    IN  i_episode         Episode ID
     * @param    IN  i_flg_filter      Flag filter (P - Patient, V - Visit, E - Episode)
     *
     * @return   BOOLEAN
     *
     * @version  
     * @since    
     * @created  
    */

    FUNCTION get_scope
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2
    ) RETURN table_number;

    /************************************************************************************************************
    * This function returns the department associated to the episode dep_clin_serv
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_episode       Episode Id
    *
    * @return     Department Id
    *
    * @author     Sofia Mendes
    * @version    2.6.0.5
    * @since      29-Oct-2013
    ************************************************************************************************************/
    FUNCTION get_epis_department
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_department%TYPE;

    /************************************************************************************************************
    * This function returns episode information by episode, visit and patient identification
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_id_patient    Patient Id
    * @param i_scope         Function scope type: P- patient, E- episode, V- visit
    * @param i_id_scope      Corresponding scope identifier
    *
    * @return     Table type - t_table_episode_cda
    *
    * @author     Gisela Couto
    * @version    2.6.3.15
    * @since      10-April-2014
    ************************************************************************************************************/
    FUNCTION get_episode_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_scope      IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_table_episode_cda;
    /**
    * count visit episodes oris and inp
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               count visit episodes oris and inp
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION count_oris_inp_visit_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Gets the last episode of a patient by software
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_patient      Patient ID
    * @param i_software     Software ID
    *
    * @return  Last episode ID
    *
    * @author  Alexandre Santos
    * @version 2.6.4
    * @since   11-Nov-2014
    **********************************************************************************************/
    FUNCTION get_last_episode_by_soft
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_software IN software.id_software%TYPE DEFAULT NULL
    ) RETURN episode.id_episode%TYPE;

    PROCEDURE set_outp_no_show;

    FUNCTION get_episode_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat                  IN patient.id_patient%TYPE,
        i_epis                 IN table_number,
        i_review               IN BOOLEAN,
        o_complaint            OUT pk_types.cursor_type,
        o_info10               OUT pk_types.cursor_type,
        o_history              OUT pk_types.cursor_type,
        o_history_doc          OUT pk_types.cursor_type,
        o_history_ft           OUT pk_types.cursor_type,
        o_review               OUT pk_types.cursor_type,
        o_problems             OUT pk_types.cursor_type,
        o_relev_disease        OUT pk_types.cursor_type,
        o_surgical_hist        OUT pk_types.cursor_type,
        o_allergy              OUT pk_types.cursor_type,
        o_medication           OUT pk_types.cursor_type,
        o_home_med_review      OUT pk_types.cursor_type,
        o_pat_take             OUT pk_types.cursor_type,
        o_fam_hist             OUT pk_types.cursor_type,
        o_soc_hist             OUT pk_types.cursor_type,
        o_relev_notes          OUT pk_types.cursor_type,
        o_habit                OUT pk_types.cursor_type,
        o_info7                OUT pk_types.cursor_type,
        o_vital_sign           OUT pk_types.cursor_type,
        o_biometric            OUT pk_types.cursor_type,
        o_phys_exam            OUT pk_types.cursor_type,
        o_body_diags           OUT pk_types.cursor_type,
        o_ass_scales           OUT pk_types.cursor_type,
        o_blood_group          OUT pk_types.cursor_type,
        o_evaluation           OUT pk_types.cursor_type,
        o_diag                 OUT pk_types.cursor_type,
        o_impressions          OUT pk_types.cursor_type,
        o_plan                 OUT pk_types.cursor_type,
        o_therapeutic_decision OUT pk_types.cursor_type,
        o_analysis             OUT pk_types.cursor_type,
        o_exam                 OUT pk_types.cursor_type,
        o_presc_ext            OUT pk_types.cursor_type,
        o_dietary_ext          OUT pk_types.cursor_type,
        o_manip_ext            OUT pk_types.cursor_type,
        o_presc                OUT pk_types.cursor_type,
        o_interv               OUT pk_types.cursor_type,
        o_monitorization       OUT pk_types.cursor_type,
        o_nurse_act            OUT pk_types.cursor_type,
        o_nurse_teach          OUT pk_types.cursor_type,
        o_gp_notes             OUT pk_types.cursor_type,
        o_referrals            OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN; --

    /**********************************************************************************************
    * Get all active episodes by visit
    *
    * @param i_id_visit     Visit ID
    *
    * @return  Episode ID List
    *
    * @author  Vitor Reis
    * @version 2.6.5.1
    * @since   06-Nov-2015
    **********************************************************************************************/
    FUNCTION get_active_epis_by_visit(i_id_visit IN visit.id_visit%TYPE) RETURN table_number;

    FUNCTION get_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN CLOB;

    FUNCTION get_epis_clinical_serv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_id_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_info.id_room%TYPE;

    /********************************************************************************************
    * Get CHIEF COMPLAINT/ REASON FOR VISIT viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/

    FUNCTION get_complaint_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get Admission information
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_id_episode episode idenfier
    *
    * @return             Type with the admission information
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01-12
    **********************************************************************************************/

    FUNCTION tf_get_episode_admission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf;

    FUNCTION get_episode_transfer_sp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN CLOB;

    FUNCTION get_epis_clin_serv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_clin_serv OUT clinical_service.id_clinical_service%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE inactivate_epis_tasks;

    FUNCTION get_episode_summary_default_it
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_send_id_req IN BOOLEAN,
        o_default     OUT VARCHAR2,
        o_filter      OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns episode professional
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_episode       Episode Id
    *
    * @return     professional Id
    *
    * @author     Sofia Mendes
    * @version    2.6.7
    * @since      23-Mai-2018
    ************************************************************************************************************/
    FUNCTION get_epis_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_info.id_professional%TYPE;

    /************************************************************************************************************
    * This function returns the previous visit id associated to a episode and type of episode
    *
    * @param      i_episode         Episode Id
    * @param      i_id_epis_type    Type of episode Id (ex: inpatient=5)
    *
    * @return     Visit Id
    *
    * @author     CRISTINA.OLIVEIRA
    * @version    2.7
    * @since      2018/06/05
    ************************************************************************************************************/
    FUNCTION get_previous_visit
    (
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN episode.id_visit%TYPE;

    FUNCTION get_language_by_epis(i_epis episode.id_episode%TYPE) RETURN NUMBER;

    FUNCTION get_institution_by_epis(i_epis episode.id_episode%TYPE) RETURN NUMBER;

    PROCEDURE get_etsi_cfg_vars
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_inst OUT institution.id_institution%TYPE
    );

    FUNCTION get_epis_type_access
    (
        i_prof        IN profissional,
        i_include_all IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN table_number;

    FUNCTION get_episode_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_contact_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_dep_cs_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_episodes_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt       IN VARCHAR2,
        o_episodes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;


    FUNCTION get_desc_rehab_area
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2;


    FUNCTION get_appointment_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    
        FUNCTION get_epis_type_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    ------------------

    
END pk_episode;
/
