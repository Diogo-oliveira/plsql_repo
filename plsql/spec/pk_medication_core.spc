/*-- Last Change Revision: $Rev: 2028795 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_medication_core IS

    SUBTYPE t_unconstrained_day_sec IS INTERVAL DAY(9) TO SECOND(9);

    TYPE t_rec_local_administrations IS RECORD(
        id_drug_presc_det  drug_presc_det.id_drug_presc_det%TYPE,
        id_drug_presc_plan drug_presc_plan.id_drug_presc_plan%TYPE,
        med_descr          mi_med.med_descr%TYPE,
        dt_adm             VARCHAR2(30),
        dt_end_bottle      VARCHAR2(30),
        flg_status         drug_presc_plan.flg_status%TYPE,
        descr_status       VARCHAR2(4000),
        prof_adm_name      VARCHAR2(800),
        prof_adm_abr       VARCHAR2(800),
        id_prof_adm        professional.id_professional%TYPE);

    TYPE t_cur_local_administrations IS REF CURSOR RETURN t_rec_local_administrations;
    TYPE t_coll_local_administrations IS TABLE OF t_rec_local_administrations;

    --Severity cursors objects >>>
    TYPE t_rec_modules_list IS RECORD(
        id_module     med_warning_modules.id_module%TYPE,
        module_desc   VARCHAR2(1000),
        flg_active    med_severity_clin_serv.flg_module_status%TYPE,
        flg_drillable med_warning_modules.flg_has_severities%TYPE);

    TYPE t_cur_modules_list IS REF CURSOR RETURN t_rec_modules_list;
    TYPE t_coll_modules_list IS TABLE OF t_rec_modules_list;

    --Severity detail
    TYPE t_rec_severity_list IS RECORD(
        id_severity         med_severity_clin_serv.id_severity%TYPE,
        severity_label      VARCHAR2(1000),
        severity_value      med_severity_clin_serv.flg_severity_status%TYPE,
        severity_value_desc VARCHAR2(1000));

    TYPE t_cur_severity_list IS REF CURSOR RETURN t_rec_severity_list;
    TYPE t_coll_severity_list IS TABLE OF t_rec_severity_list;

    ----Severity warnings for specific professional
    --TYPE t_rec_severity_warn_status IS RECORD(
    --    id_severity     med_severity_clin_serv.id_severity%TYPE,
    --    severity_value  med_severity_clin_serv.flg_severity_status%TYPE);
    --
    ----TYPE t_cur_severity_warn_status  IS REF CURSOR RETURN t_rec_severity_warn_status;
    --TYPE t_coll_severity_warn_status IS TABLE OF t_rec_severity_warn_status;

    --Severity cursors objects <<<

    /********************************************************************************************
    *  Convert any other drip unit to ml/hr
    *
    * @param    I_VAL_DRIP            Drip value
    * @param    I_UNIT_MEASURE_DRIP   Drip unit measure ID
    *
    * @return   NUMBER: Value of drip converted to "gota" unit measure
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/10/26
    ********************************************************************************************/
    FUNCTION convert2mlhr
    (
        i_val_drip          drug_presc_det.value_drip%TYPE,
        i_unit_measure_drip drug_presc_det.id_unit_measure_drip%TYPE
    ) RETURN drug_presc_det.value_drip%TYPE;

    FUNCTION get_version_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_medication_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_med       IN VARCHAR2,
        i_subject   IN VARCHAR2,
        i_type      IN VARCHAR2, -- GRID_SCREEN, SEARCH_SCREEN, REPORT_SCREEN, SEARCH_REPORT_SCREEN
        i_presc     IN NUMBER DEFAULT NULL,
        i_vers      IN VARCHAR2 DEFAULT NULL,
        i_vers_type IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR;

    FUNCTION create_alternative_units
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_drug         IN mi_med.id_drug%TYPE,
        i_unit_measure IN table_varchar,
        i_commit       IN VARCHAR2 DEFAULT NULL,
        i_chnm         IN mi_med.chnm_id%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_medication
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_drug_descr       IN mi_med.med_descr%TYPE,
        i_chnm             IN mi_med.chnm_id%TYPE,
        i_flg_type         IN mi_med.flg_type%TYPE,
        i_flg_mix_fluid    IN mi_med.flg_mix_fluid%TYPE,
        i_flg_justify      IN mi_med.flg_justify%TYPE,
        i_dci_id           IN mi_med.dci_id%TYPE,
        i_dci_descr        IN mi_med.dci_descr%TYPE,
        i_dosage           IN mi_med.dosagem%TYPE,
        i_form_farm_id     IN mi_med.form_farm_id%TYPE,
        i_form_farm_descr  IN mi_med.form_farm_descr%TYPE,
        i_form_farm_abrv   IN mi_med.form_farm_abrv%TYPE,
        i_route_id         IN mi_med.route_id%TYPE,
        i_route_descr      IN mi_med.route_descr%TYPE,
        i_route_abrv       IN mi_med.route_abrv%TYPE,
        i_qt_dos_comp      IN mi_med.qt_dos_comp%TYPE,
        i_id_unit_dos_comp IN unit_measure.id_unit_measure%TYPE,
        i_commit           IN VARCHAR2 DEFAULT NULL,
        o_id_medication    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_drug              IN mi_med.id_drug%TYPE,
        i_drug_descr        IN mi_med.med_descr%TYPE DEFAULT NULL,
        i_chnm              IN mi_med.chnm_id%TYPE DEFAULT NULL,
        i_flg_type          IN mi_med.flg_type%TYPE DEFAULT NULL,
        i_flg_mix_fluid     IN mi_med.flg_mix_fluid%TYPE DEFAULT NULL,
        i_med_flg_available IN mi_med.flg_available%TYPE DEFAULT NULL,
        i_flg_justify       IN mi_med.flg_justify%TYPE DEFAULT NULL,
        i_dci_id            IN mi_med.dci_id%TYPE DEFAULT NULL,
        i_dci_descr         IN mi_med.dci_descr%TYPE DEFAULT NULL,
        i_dosage            IN mi_med.dosagem%TYPE DEFAULT NULL,
        i_form_farm_id      IN mi_med.form_farm_id%TYPE DEFAULT NULL,
        i_form_farm_descr   IN mi_med.form_farm_descr%TYPE DEFAULT NULL,
        i_form_farm_abrv    IN mi_med.form_farm_abrv%TYPE DEFAULT NULL,
        i_route_id          IN mi_med.route_id%TYPE DEFAULT NULL,
        i_route_descr       IN mi_med.route_descr%TYPE DEFAULT NULL,
        i_route_abrv        IN mi_med.route_abrv%TYPE DEFAULT NULL,
        i_qt_dos_comp       IN mi_med.qt_dos_comp%TYPE DEFAULT NULL,
        i_id_unit_dos_comp  IN unit_measure.id_unit_measure%TYPE DEFAULT NULL,
        i_commit            IN VARCHAR2 DEFAULT NULL,
        o_info_iv_fluid     OUT pk_types.cursor_type,
        o_info_thp_protocol OUT pk_types.cursor_type,
        o_id_medication     OUT mi_med.id_drug%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_drug_dcs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_drug           IN mi_med.id_drug%TYPE,
        i_id_dep_clin_serv  IN drug_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_flg_type          IN drug_dep_clin_serv.flg_type%TYPE,
        i_flg_take_type     IN drug_dep_clin_serv.flg_take_type%TYPE DEFAULT NULL,
        i_takes             IN drug_dep_clin_serv.takes%TYPE DEFAULT NULL,
        i_interval          IN drug_dep_clin_serv.interval%TYPE DEFAULT NULL,
        i_dosage            IN drug_dep_clin_serv.dosage%TYPE DEFAULT NULL,
        i_qty               IN drug_dep_clin_serv.qty_inst%TYPE DEFAULT NULL,
        i_duration          IN drug_dep_clin_serv.duration%TYPE DEFAULT NULL,
        i_unit_measure_inst IN drug_dep_clin_serv.unit_measure_inst%TYPE DEFAULT NULL,
        i_unit_measure_freq IN drug_dep_clin_serv.unit_measure_freq%TYPE DEFAULT NULL,
        i_unit_measure_dur  IN drug_dep_clin_serv.unit_measure_dur%TYPE DEFAULT NULL,
        i_commit            IN VARCHAR2 DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE print_medication_logs
    (
        i_log_msg  IN VARCHAR2,
        i_log_type IN VARCHAR2 DEFAULT 'E'
    );

    FUNCTION get_software_by_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE,
        o_software_list  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_medication_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        --new alert identification
        i_id_record IN sys_alert_event.id_record%TYPE,
        i_dt_record IN sys_alert_event.dt_record%TYPE,
        --conditions for new alert
        i_dpd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_drd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dpp_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dr_flg_status  IN VARCHAR2 DEFAULT NULL,
        i_drs_flg_status IN VARCHAR2 DEFAULT NULL,
        i_med_type       IN VARCHAR2 DEFAULT NULL,
        --alert object description
        i_alert_message IN VARCHAR2,
        --
        i_institution IN sys_alert_event.id_institution%TYPE,
        i_software    IN sys_alert_event.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_medication_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        --new alert identification
        i_id_record IN sys_alert_event.id_record%TYPE,
        --conditions to delete alerts
        i_dpd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_drd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dpp_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dr_flg_status  IN VARCHAR2 DEFAULT NULL,
        i_drs_flg_status IN VARCHAR2 DEFAULT NULL,
        i_med_type       IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_visit_from_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN drug_prescription.id_episode%TYPE,
        o_id_visit     OUT visit.id_visit%TYPE,
        o_id_epis_type OUT episode.id_epis_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_medication_ins
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_drug_descr        IN mi_med.med_descr%TYPE,
        i_chnm              IN mi_med.chnm_id%TYPE,
        i_flg_type          IN mi_med.flg_type%TYPE,
        i_flg_mix_fluid     IN mi_med.flg_mix_fluid%TYPE,
        i_flg_justify       IN mi_med.flg_justify%TYPE,
        i_dci_id            IN mi_med.dci_id%TYPE,
        i_dci_descr         IN mi_med.dci_descr%TYPE,
        i_dosage            IN mi_med.dosagem%TYPE,
        i_form_farm_id      IN mi_med.form_farm_id%TYPE,
        i_form_farm_descr   IN mi_med.form_farm_descr%TYPE,
        i_form_farm_abrv    IN mi_med.form_farm_abrv%TYPE,
        i_route_id          IN mi_med.route_id%TYPE,
        i_route_descr       IN mi_med.route_descr%TYPE,
        i_route_abrv        IN mi_med.route_abrv%TYPE,
        i_qt_dos_comp       IN mi_med.qt_dos_comp%TYPE,
        i_id_unit_dos_comp  IN unit_measure.id_unit_measure%TYPE,
        i_commit            IN VARCHAR2 DEFAULT NULL,
        i_id_drug_replicat  IN mi_med.id_drug%TYPE DEFAULT NULL,
        i_med_flg_available IN mi_med.flg_available%TYPE DEFAULT NULL,
        o_id_medication     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Update table GRID_TASK.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2006/01/20
    **********************************************************************************************/

    FUNCTION update_drug_presc_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -----------------------------------------------------------------------------------------------
    -- PARAMETERS
    -----------------------------------------------------------------------------------------------
    g_error VARCHAR2(4000);
    g_found BOOLEAN;
    g_yes       CONSTANT VARCHAR2(1) := 'Y';
    g_no        CONSTANT VARCHAR2(1) := 'N';
    g_icon      CONSTANT VARCHAR2(1) := 'I';
    g_date_icon CONSTANT VARCHAR2(2) := 'DI';
    g_date      CONSTANT VARCHAR2(1) := 'D';
    g_text      CONSTANT VARCHAR2(1) := 'T';
    g_text_icon CONSTANT VARCHAR2(2) := 'TI';
    g_sysdate      DATE := SYSDATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    g_green_color          CONSTANT VARCHAR2(50) := '0x829664';
    g_red_color            CONSTANT VARCHAR2(50) := '0xC86464';
    g_brown_color          CONSTANT VARCHAR2(50) := ''; --'0xC3C3A5';
    g_state_color          CONSTANT VARCHAR2(50) := 'STATE_COLOR';
    g_grid_color           CONSTANT VARCHAR2(50) := 'GRID_COLOR';
    g_last_state           CONSTANT VARCHAR2(2) := 'LS';
    g_cell_state           CONSTANT VARCHAR2(2) := 'CS';
    g_cell_state_hist      CONSTANT VARCHAR2(3) := 'CSH';
    g_out_status           CONSTANT VARCHAR2(255) := 'OUT_STATUS';
    g_out_status_old       CONSTANT VARCHAR2(255) := 'OUT_STATUS_OLD';
    g_out_status_simple    CONSTANT VARCHAR2(255) := 'OUT_STATUS_SIMPLE';
    g_out_status_histgrid  CONSTANT VARCHAR2(255) := 'OUT_HIST_GRID';
    g_out_rank             CONSTANT VARCHAR2(255) := 'OUT_RANK';
    g_grid_screen          CONSTANT VARCHAR2(255) := 'GRID_SCREEN';
    g_search_screen        CONSTANT VARCHAR2(255) := 'SEARCH_SCREEN';
    g_chnm_screen          CONSTANT VARCHAR2(255) := 'CHNM_SCREEN';
    g_alerts_screen        CONSTANT VARCHAR2(255) := 'ALERTS_SCREEN';
    g_detail_screen        CONSTANT VARCHAR2(255) := 'DETAIL_SCREEN';
    g_drug                 CONSTANT VARCHAR2(1) := 'M';
    g_get_name             CONSTANT VARCHAR2(50) := 'GET_NAME';
    g_get_dci              CONSTANT VARCHAR2(50) := 'GET_DCI';
    g_previous_episode_flg CONSTANT VARCHAR2(50) := 'N';
    g_next_episode_flg     CONSTANT VARCHAR2(1) := 'N';
    g_adm_drug             CONSTANT VARCHAR2(1) := 'A';
    g_int_drug             CONSTANT VARCHAR2(1) := 'I';
    g_ext_drug             CONSTANT VARCHAR2(1) := 'E';
    g_vers_type_a          CONSTANT VARCHAR2(1) := 'A';
    g_vers_type_b          CONSTANT VARCHAR2(1) := 'B';

    -- MARKET
    g_usa    CONSTANT VARCHAR2(255) := 'USA';
    g_usa_ms CONSTANT VARCHAR2(255) := 'USA_MS';
    g_pt     CONSTANT VARCHAR2(255) := 'PT';
    g_br     CONSTANT VARCHAR2(255) := 'BR';
    g_nl     CONSTANT VARCHAR2(255) := 'NL';
    g_gb     CONSTANT VARCHAR2(255) := 'GB';

    --NOTES SCREENS TITLES IDS:
    g_pv_m_no_med_notes           CONSTANT VARCHAR2(50) := 'PREV_MEDICATION_NO_MED_NOTES';
    g_pv_m_no_med_notes_desc      CONSTANT VARCHAR2(50) := 'Title for: no current medication';
    g_pv_m_unknown_med_notes      CONSTANT VARCHAR2(50) := 'PREV_MEDICATION_UNKNOWN_MED_NOTES';
    g_pv_m_unknown_med_notes_desc CONSTANT VARCHAR2(50) := 'Title for: unknown medication';

    --Exceptions
    unexpected_error EXCEPTION;

    -- Translation
    g_code_unit_measure CONSTANT translation.code_translation%TYPE := 'UNIT_MEASURE.CODE_UNIT_MEASURE.';
    g_code_unit_abrv    CONSTANT translation.code_translation%TYPE := 'UNIT_MEASURE.CODE_UNIT_MEASURE_ABRV.';

    --Sys_domain
    g_domain_take_type        CONSTANT sys_domain.code_domain%TYPE := 'DRUG_PRESC_DET.FLG_TAKE_TYPE';
    g_prescr_status           CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION.FLG_STATUS';
    g_pat_notify_status       CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION_PHARM.PATIENT_NOTIFIED';
    g_drug_req_det_status     CONSTANT sys_domain.code_domain%TYPE := 'DRUG_REQ_DET.FLG_STATUS';
    g_drug_presc_det_status   CONSTANT sys_domain.code_domain%TYPE := 'DRUG_PRESC_DET.FLG_STATUS';
    g_domain_relatos          CONSTANT sys_domain.code_domain%TYPE := 'RELATOS'; -- ICONES CONSOANTE A LÍNGUA
    g_domain_relatos_continue CONSTANT sys_domain.code_domain%TYPE := 'PAT_MEDICATION_LIST.CONTINUE';
    g_domain_grid_icon_report CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION.FLG_TYPE';
    g_val_r                   CONSTANT sys_domain.val%TYPE := 'R';
    g_prescription_vers_typ   CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION_VERSION_TYPE';

    -- Sys_message
    g_message_inicio        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_T003'; --Início
    g_message_fim           CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_T004'; -- Fim
    g_presc_manip_message   CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_MANIP_T007'; -- manipulados
    g_presc_dietary_message CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_DIETARY_T003'; -- dieteticos
    g_presc_rec_t053        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T053';
    g_presc_mo_t005         CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_MO_T005'; -- refill
    g_presc_rec_t081        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T081'; -- emb

    -- Sys_config
    g_pres_show_adv_inp      CONSTANT sys_config.id_sys_config%TYPE := 'PRESCRIPTION_SHOW_ADV_INP';
    g_prescription_type      CONSTANT sys_config.id_sys_config%TYPE := 'PRESCRIPTION_TYPE';
    g_presc_short_to_sumpage CONSTANT sys_config.id_sys_config%TYPE := 'PRESC_SHORTCUT_TO_SUMMARYPAGE';

    -- SUBJECT
    g_local                 CONSTANT VARCHAR2(255) := 'LOCAL';
    g_other_prod            CONSTANT VARCHAR2(255) := 'OUTROS_PROD';
    g_hospital              CONSTANT VARCHAR2(255) := 'HOSPITAL';
    g_dietetico             CONSTANT VARCHAR2(255) := 'DIETETICOS';
    g_manipulados           CONSTANT VARCHAR2(255) := 'MANIPULADO';
    g_exterior              CONSTANT VARCHAR2(255) := 'EXTERIOR';
    g_relatos_ext           CONSTANT VARCHAR2(255) := 'RELATOS_EXT';
    g_outros                CONSTANT VARCHAR2(255) := 'OUTROS';
    g_relatos_int           CONSTANT VARCHAR2(255) := 'RELATOS_INT';
    g_soro                  CONSTANT VARCHAR2(255) := 'SORO';
    g_no_medication         CONSTANT VARCHAR2(255) := 'NO_MEDICATION';
    g_no_id_medication      CONSTANT VARCHAR2(255) := 'NO_ID_MEDICATION';
    g_exterior_refills      CONSTANT VARCHAR2(255) := 'EXTERIOR_REFILLS';
    g_relatos               CONSTANT VARCHAR2(255) := 'RELATOS';
    g_compound              CONSTANT VARCHAR2(255) := 'COMPOUND';
    g_exterior_report       CONSTANT VARCHAR2(255) := 'EXTERIOR_REPORT';
    g_unrelevant_medication CONSTANT VARCHAR2(255) := 'UNRELEVANT_MEDICATION';
    g_medication_unselected CONSTANT VARCHAR2(255) := 'MEDICATION_UNSELECTED';

    -- FLG_TYPE
    g_type_a         CONSTANT VARCHAR2(2) := 'A'; -- administrar neste local/soluções parentéricas
    g_type_i         CONSTANT VARCHAR2(2) := 'I'; -- farmácia da instituição
    g_type_e         CONSTANT VARCHAR2(2) := 'E'; -- exterior/dietéticos/manipulados
    g_type_r         CONSTANT VARCHAR2(2) := 'R'; -- relatos
    g_type_ri        CONSTANT VARCHAR2(2) := 'RI'; --
    g_type_re        CONSTANT VARCHAR2(2) := 'RE'; --
    g_type_manip     CONSTANT VARCHAR2(2) := 'ME'; --
    g_type_diet      CONSTANT VARCHAR2(2) := 'DE'; --
    g_type_dietmanip CONSTANT VARCHAR2(2) := 'P'; --
    g_type_o         CONSTANT VARCHAR2(2) := 'O'; -- outros produtos

    -- MI_MED
    g_flg_new_fluid CONSTANT mi_med.flg_type%TYPE := 'N'; -- Soros construídos
    g_fluids        CONSTANT mi_med.flg_type%TYPE := 'F'; -- Soros simples
    g_flg_new_freq  CONSTANT mi_med.flg_type%TYPE := 'C'; -- Soros mais  frequentemente construídos

    -- Prescription
    g_presc_ext_t prescription.flg_status%TYPE := 'T'; -- temporary
    g_presc_ext_p prescription.flg_status%TYPE := 'P'; -- printed
    g_presc_ext_c prescription.flg_status%TYPE := 'C'; -- deleted
    g_presc_ext_a prescription.flg_status%TYPE := 'A'; -- active
    g_presc_ext_y prescription.flg_status%TYPE := 'Y'; -- inactive

    -- prescription_instr_hist
    g_presc_pharm_table    CONSTANT prescription_instr_hist.prescription_table%TYPE := 'PRESCRIPTION_PHARM';
    g_drug_req_det_table   CONSTANT prescription_instr_hist.prescription_table%TYPE := 'DRUG_REQ_DET';
    g_drug_presc_det_table CONSTANT prescription_instr_hist.prescription_table%TYPE := 'DRUG_PRESC_DET';
    g_pat_med_lis_table    CONSTANT prescription_instr_hist.prescription_table%TYPE := 'PAT_MEDICATION_LIST';

    -- Drug_req_det
    g_drug_req_det_t CONSTANT drug_req_det.flg_status%TYPE := 'T'; -- temporary
    g_drug_req_det_r CONSTANT drug_req_det.flg_status%TYPE := 'R'; -- printed
    g_drug_req_det_c CONSTANT drug_req_det.flg_status%TYPE := 'C'; -- deleted
    g_drug_req_det_d CONSTANT drug_req_det.flg_status%TYPE := 'D'; -- partially dispensed by the pharmacist

    -- DRUG_REQ
    g_drug_req_c CONSTANT drug_req.flg_status%TYPE := 'C'; -- canceled
    g_drug_req_t CONSTANT drug_req.flg_status%TYPE := 'T'; -- temporary

    -- DRUG_PRESC_DET
    g_default_drip       CONSTANT drug_presc_det.id_unit_measure_drip%TYPE := 24; -- KVO
    g_drip_to_be_defined CONSTANT drug_presc_det.id_unit_measure_drip%TYPE := 26; -- to be defined
    g_default_rate       CONSTANT drug_presc_det.id_unit_measure_drip%TYPE := 20; -- ml/hr
    g_none_rate          CONSTANT drug_presc_det.id_unit_measure_drip%TYPE := 25; -- nenhuma
    g_dpd_flg_modify     CONSTANT drug_presc_det.flg_status%TYPE := 'M'; -- instructions modified
    g_drug_presc_det_c   CONSTANT drug_presc_det.flg_status%TYPE := 'C'; -- canceled

    -- DRUG_PRESC_PLAN
    g_drug_presc_plan_domain CONSTANT sys_domain.code_domain%TYPE := 'DRUG_PRESC_PLAN.FLG_STATUS';
    g_flg_status_a           CONSTANT drug_presc_plan.flg_status%TYPE := 'A'; -- Administrado
    g_flg_status_c           CONSTANT drug_presc_plan.flg_status%TYPE := 'C'; -- Cancelado
    g_flg_status_d           CONSTANT drug_presc_plan.flg_status%TYPE := 'D'; -- Não administrado
    g_flg_status_i           CONSTANT drug_presc_plan.flg_status%TYPE := 'I'; -- Descontinuado
    g_flg_status_n           CONSTANT drug_presc_plan.flg_status%TYPE := 'N'; -- Não administrado
    g_flg_status_r           CONSTANT drug_presc_plan.flg_status%TYPE := 'R'; -- Não administrado
    g_flg_status_b           CONSTANT drug_presc_plan.flg_status%TYPE := 'B'; -- Bolus Administrado     
    g_flg_status_s           CONSTANT drug_presc_plan.flg_status%TYPE := 'S'; -- Suspenso

    -- PAT_MEDICATION_LIST
    g_pml_c CONSTANT pat_medication_list.flg_status%TYPE := 'C'; -- cancelled
    g_pml_d CONSTANT pat_medication_list.flg_status%TYPE := 'D'; -- deleted
    g_pml_a CONSTANT pat_medication_list.flg_status%TYPE := 'A'; -- active
    g_pml_p CONSTANT pat_medication_list.flg_status%TYPE := 'P'; -- passive

    g_pml_continue_c CONSTANT pat_medication_list.flg_status%TYPE := 'C'; -- continue
    g_pml_continue_i CONSTANT pat_medication_list.flg_status%TYPE := 'I'; -- discontinue

    --Detail cursors
    c_drug_hold_detail          CONSTANT VARCHAR2(30) := 'o_drug_hold_detail';
    c_drug_cancel_detail        CONSTANT VARCHAR2(30) := 'o_drug_cancel_detail';
    c_drug_report_detail        CONSTANT VARCHAR2(30) := 'o_drug_report_detail';
    c_drug_local_presc_detail   CONSTANT VARCHAR2(30) := 'o_drug_local_presc_detail';
    c_drug_activate_detail      CONSTANT VARCHAR2(30) := 'o_drug_activate_detail';
    c_drug_administer_detail    CONSTANT VARCHAR2(30) := 'o_drug_administer_detail';
    c_drug_edit_instr_detail    CONSTANT VARCHAR2(30) := 'o_drug_edit_instr_detail';
    c_drug_edit_dose_detail     CONSTANT VARCHAR2(30) := 'o_drug_edit_dose_detail';
    c_drug_continued_detail     CONSTANT VARCHAR2(30) := 'o_drug_continued_detail';
    c_drug_discontinued_detail  CONSTANT VARCHAR2(30) := 'o_drug_discontinued_detail';
    c_drug_ext_presc_emb_detail CONSTANT VARCHAR2(30) := 'o_drug_ext_presc_emb_detail';
    c_drug_ext_presc_qtd_detail CONSTANT VARCHAR2(30) := 'o_drug_ext_presc_qtd_detail';
    c_drug_refills_detail       CONSTANT VARCHAR2(30) := 'o_drug_refills_detail';
    c_drug_int_presc_detail     CONSTANT VARCHAR2(30) := 'o_drug_int_presc_detail';
    c_drug_draft_detail         CONSTANT VARCHAR2(30) := 'o_drug_draft_detail';
    c_drug_expired_detail       CONSTANT VARCHAR2(30) := 'o_drug_expired_detail';

    -- PRESCRIPTION_TYPE
    g_presc_type_refill CONSTANT prescription_type.id_prescription_type%TYPE := 22;

    --str para apresentar no detalhe quando não existe informação para um campo
    c_no_detail_data CONSTANT VARCHAR2(2) := '--';

    --mandatory field
    c_mandatory_field CONSTANT VARCHAR2(2) := '*';

    --debug levels
    c_log_fatal CONSTANT VARCHAR2(1) := 'F';
    c_log_error CONSTANT VARCHAR2(1) := 'E';
    c_log_warn  CONSTANT VARCHAR2(1) := 'W';
    c_log_info  CONSTANT VARCHAR2(1) := 'I';
    c_log_debug CONSTANT VARCHAR2(1) := 'D';

    --
    c_flg_o CONSTANT VARCHAR2(1) := 'O'; --Outros produtos

    --
    g_pat_med_list_domain    CONSTANT sys_domain.code_domain%TYPE := 'PAT_MEDICATION_LIST.FLG_STATUS';
    g_pat_med_list_domain_ci CONSTANT sys_domain.code_domain%TYPE := 'PAT_MEDICATION_LIST.CONTINUE';

    g_not_applicable NUMBER(1) := 1;
    g_date_defined   NUMBER(1) := 2;
    g_not_defined    NUMBER(1) := 3;

    g_ti_log_me VARCHAR2(2) := 'ME'; -- receitas para o exterior (prescription_pharm)
    g_ti_log_ml VARCHAR2(2) := 'ML'; -- medicação para o local (drug_presc_det)
    g_ti_log_mh VARCHAR2(2) := 'MH'; -- receita para a farmácia do hospital (drug_req_det)
    g_ti_log_mr VARCHAR2(2) := 'MR'; -- relatos (pat_medication_list)

    g_report_act        VARCHAR2(2) := 'AX'; -- relatos com estado inicial activo
    g_report_inact      VARCHAR2(2) := 'PX'; -- relatos com estado inicial inactivo
    g_temp_prescription VARCHAR2(2) := 'TX'; -- receitas com estado inicial temporário
    g_medication_r      VARCHAR2(2) := 'RX'; -- medicação com estado inicial requisitado
    g_medication_d      VARCHAR2(2) := 'DX'; -- medicação com estado inicial a administrar no proximo episodio

    g_presc_take_irre CONSTANT VARCHAR2(1) := 'P'; -- Posologias irregulares

    --CPOE MED task states
    g_med_cpoe_a CONSTANT VARCHAR2(1) := 'A'; -- cpoe tasks in active state
    g_med_cpoe_i CONSTANT VARCHAR2(1) := 'I'; -- cpoe tasks in inactive state - cancelled, discontinued and finished tasks.
    g_med_cpoe_y CONSTANT VARCHAR2(1) := 'Y'; -- cpoe tasks in created state - draft created.
    g_med_cpoe_w CONSTANT VARCHAR2(1) := 'W'; -- cpoe tasks in expired state.
    g_med_cpoe_c CONSTANT VARCHAR2(1) := 'C'; -- cpoe tasks in canceled state.
    g_med_cpoe_f CONSTANT VARCHAR2(1) := 'F'; -- cpoe tasks in finalized state.
    g_med_cpoe_p CONSTANT VARCHAR2(1) := 'P'; -- cpoe tasks in not active state.
    g_med_cpoe_s CONSTANT VARCHAR2(1) := 'S'; -- cpoe tasks in suspended state.

    g_cancel_action CONSTANT VARCHAR2(1) := 'X';

    g_chron_med_active   CONSTANT VARCHAR2(1) := 'A'; -- chronic medication active
    g_chron_med_inactive CONSTANT VARCHAR2(1) := 'Y'; -- chronic medication inactive
    g_exterior_chronic VARCHAR2(100) := 'EXTERIOR_CHRONIC'; -- chronic medication subject

    g_euro_currency           VARCHAR2(4) := '€';
    g_presc_plan_stat_adm     drug_presc_plan.flg_status%TYPE := 'A';
    g_presc_plan_stat_nadm    drug_presc_plan.flg_status%TYPE := 'N';
    g_presc_plan_stat_can     drug_presc_plan.flg_status%TYPE := 'C';
    g_presc_plan_stat_req     drug_presc_plan.flg_status%TYPE := 'R';
    g_presc_plan_stat_pend    drug_presc_plan.flg_status%TYPE := 'D';
    g_presc_plan_stat_fin     drug_presc_plan.flg_status%TYPE := 'F';
    g_presc_det_req           drug_presc_det.flg_status%TYPE := 'R';
    g_presc_det_pend          drug_presc_det.flg_status%TYPE := 'D';
    g_presc_det_exe           drug_presc_det.flg_status%TYPE := 'E';
    g_presc_det_fin           drug_presc_det.flg_status%TYPE := 'F';
    g_presc_det_can           drug_presc_det.flg_status%TYPE := 'C';
    g_presc_det_intr          drug_presc_det.flg_status%TYPE := 'I';
    g_presc_det_sus           drug_presc_det.flg_status%TYPE := 'S';
    g_presc_det_exp           drug_presc_det.flg_status%TYPE := 'W';
    g_presc_det_draft         drug_presc_det.flg_status%TYPE := 'Y';
    g_flg_doctor              VARCHAR2(4) := 'D';
    g_presc_det_take_type_sos drug_presc_det.flg_take_type%TYPE := 'S';

    g_presc_det_inactive table_varchar := table_varchar(g_presc_det_sus,
                                                        g_presc_det_intr,
                                                        g_presc_det_exp,
                                                        g_presc_det_fin,
                                                        g_presc_det_can,
                                                        g_presc_det_draft,
                                                        g_presc_det_pend);
    --Warning modules: from table med_warning_modules                                               
    g_warn_module_allergy     NUMBER(24) := 1;
    g_warn_module_ci          NUMBER(24) := 2;
    g_warn_module_dosage      NUMBER(24) := 3;
    g_warn_module_interaction NUMBER(24) := 4;

    --Contra-indications available messages
    g_warn_ci_sev_nav_01_1     sys_message.code_message%TYPE := 'PRESCRIPTION_CONTRAINDICATION_M001';
    g_warn_ci_sev_nav_01_2     sys_message.code_message%TYPE := 'PRESCRIPTION_CONTRAINDICATION_M002';
    g_warn_ci_sev_nav_01_3     sys_message.code_message%TYPE := 'PRESCRIPTION_CONTRAINDICATION_M003';
    g_warn_ci_sev_nav_others_1 sys_message.code_message%TYPE := 'PRESCRIPTION_CONTRAINDICATION_M004';
    g_warn_ci_sev_nav_others_2 sys_message.code_message%TYPE := 'PRESCRIPTION_CONTRAINDICATION_M005';
    g_warn_ci_sev_nav_others_3 sys_message.code_message%TYPE := 'PRESCRIPTION_CONTRAINDICATION_M006';
    --severity status
    g_warn_severity_status sys_domain.code_domain%TYPE := 'MED_SEVERITY_CLIN_SERV.FLG_SEVERITY_STATUS';
    ----Replacement Messages
    --g_warn_diagnosis_label     sys_message.code_message%TYPE := 'PRESC_WARNING_T013';
    --Domain messages for interactions
    g_warn_interact_severity sys_domain.code_domain%TYPE := 'PRESC_INTERACTIONS.SEVERITY_LEVEL_ID';
END pk_medication_core;
/
