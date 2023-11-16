/*-- Last Change Revision: $Rev: 2028797 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_medication_current IS

    -- Author  : CARLOS.VIEIRA
    -- Created : 10-10-2007 16:52:44
    -- Purpose : Current medication list
    /********************************************************************************************
    * Esta função calcula a quantidade de medicamentos que se devem pedir à farmácia.
    * A quantidade pode ser para todo o tratamento ou diária no caso unidose
    * @param i_lang          Id do idioma
    * @param i_qty         quantidade
    * @param i_frequency         frequência
    * @param i_unit_measure_freq         unidade de medida da frequência
    * @param i_dt_start_presc_tstz         data de inicio do tratamento
    * @param i_dt_end_presc_tstz         data da fim do tratamento
    * @param i_calculation_type         flag que indica se o calculo é diario (D) ou total (T)
    *
    * @return                number
    *  --Se a frequencia for omitida, assume-se que é 1 vez por dia
    *  -- se a unidade de frequencia for omitida assume-se que são segundos
    *   -- Se data inicio for omitida assume-se data actual
    *  --se data fim omitida assume-se 30 dias
    *  -- O resultado é expresso na unidade de medida da quantidade
    * @author                Carlos Vieira
    * @version               1.0
    * @since                 2007/12/09
    ********************************************************************************************/

    /********************************************************************************************
     * Get iv dose executed
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_drug_presc_plan        ID
     *
     * @return                         Dosage executed
     *
     * @author                         Nuno Antunes
     * @version                        0.1
     * @since                          2010/10/20
    **********************************************************************************************/
    FUNCTION get_iv_dose_executed
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_drug_presc_plan IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_dt_drip_change  IN VARCHAR2 DEFAULT NULL
    ) RETURN drug_presc_plan.dosage_exec%TYPE;

    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2;

    FUNCTION create_presc_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_type             IN VARCHAR2,
        i_begin_status     IN VARCHAR2,
        i_end_status       IN VARCHAR2,
        i_id_presc         IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_notes            IN VARCHAR2 DEFAULT NULL,
        i_flg_change       IN VARCHAR2 DEFAULT NULL,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_presc_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_begin_status IN VARCHAR2,
        i_end_status   IN VARCHAR2,
        i_id_presc     IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_notes        IN VARCHAR2 DEFAULT NULL,
        i_flg_change   IN VARCHAR2 DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_presc_hosp_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_begin_status IN VARCHAR2,
        i_end_status   IN VARCHAR2,
        i_id_presc     IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type         IN VARCHAR2,
        i_id_presc     IN NUMBER,
        i_notes_cancel IN VARCHAR2,
        i_commit       IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION change_local_presc_status
    (
        i_lang              IN language.id_language%TYPE,
        i_drug_prescription IN drug_prescription.id_drug_prescription%TYPE,
        i_from_status       IN drug_prescription.id_drug_prescription%TYPE,
        i_to_status         IN drug_prescription.id_drug_prescription%TYPE,
        i_prof              IN profissional,
        i_notes             IN drug_presc_det.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

  FUNCTION set_presc_det_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_presc_pharm    IN table_number,
        i_emb_drug       IN table_number,
        i_via            IN table_varchar,
        i_qty            IN table_number,
        i_qty_unit       IN table_number,
        i_dosage         IN table_varchar,
        i_generico       IN table_varchar,
        i_first_dose     IN table_varchar,
        i_package_number IN table_varchar,
        dt_expire_tstz   IN table_varchar,
        i_diploma        IN table_number,
        i_notes          IN table_varchar,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_test           IN VARCHAR2,
        i_refill         IN table_number,
        i_chronic_med    IN table_varchar,
        i_commit         IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_presc_det_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_presc_pharm    IN table_number,
        i_emb_drug       IN table_number,
        i_via            IN table_varchar,
        i_qty            IN table_number,
        i_qty_unit       IN table_number,
        i_dosage         IN table_varchar,
        i_generico       IN table_varchar,
        i_first_dose     IN table_varchar,
        i_package_number IN table_varchar,
        dt_expire_tstz   IN table_varchar,
        i_diploma        IN table_number,
        i_notes          IN table_varchar,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_test           IN VARCHAR2,
        i_refill         IN table_number,
        i_chronic_med    IN table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************
    - Developement 2.4.3
    **********************************/
    FUNCTION update_status
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        begin_status IN prescription.flg_status%TYPE,
        end_status   IN prescription.flg_status%TYPE,
        i_id_presc   IN NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_status
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        i_type             IN VARCHAR2,
        begin_status       IN prescription.flg_status%TYPE,
        end_status         IN prescription.flg_status%TYPE,
        i_id_presc         IN NUMBER,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_status_all
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_type       IN table_varchar,
        begin_status IN table_varchar,
        end_status   IN table_varchar,
        i_id_presc   IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_status_with_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        begin_status IN prescription.flg_status%TYPE,
        end_status   IN prescription.flg_status%TYPE,
        i_id_presc   IN NUMBER,
        i_commit     IN VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_status_with_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        i_type             IN VARCHAR2,
        begin_status       IN prescription.flg_status%TYPE,
        end_status         IN prescription.flg_status%TYPE,
        i_id_presc         IN NUMBER,
        i_commit           IN VARCHAR,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION create_presc_pharm_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_type              IN VARCHAR2,
        i_begin_status      IN VARCHAR2,
        i_end_status        IN VARCHAR2,
        i_id_presc          IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_flg_type_presc    IN pk_medication_types.pih_flg_type_presc_t,
        i_flg_subtype_presc IN pk_medication_types.pih_flg_subtype_presc_t,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_reported_drug_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_begin_status IN VARCHAR2,
        i_end_status   IN VARCHAR2,
        i_id_presc     IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_reported_drug_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_type             IN VARCHAR2,
        i_begin_status     IN VARCHAR2,
        i_end_status       IN VARCHAR2,
        i_id_presc         IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_status_all
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        i_type             IN table_varchar,
        begin_status       IN table_varchar,
        end_status         IN table_varchar,
        i_id_presc         IN table_number,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type         IN VARCHAR2,
        i_id_presc     IN NUMBER,
        i_notes_cancel IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------------------------------------

    g_sysdate           DATE := SYSDATE;
    g_sysdate_tstz      TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    g_error             VARCHAR2(2000);
    g_found             BOOLEAN;
    g_pend_found        BOOLEAN;
    g_sysdate_char      VARCHAR2(50);
    g_sysdate_tstz_char VARCHAR2(50);
    g_default_drip         CONSTANT drug_presc_det.id_unit_measure_drip%TYPE := 24; -- KVO
    g_other_prod           CONSTANT VARCHAR2(255) := 'OUTROS_PROD';
    g_previous_episode_flg CONSTANT VARCHAR2(50) := 'N';
    g_get_name             CONSTANT VARCHAR2(50) := 'GET_NAME';
    g_hour_unit            CONSTANT NUMBER(24) := 1041;

    -- SYS_DOMAIN
    g_prescription_type CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION.FLG_TYPE';

    -- TIPOS DE MEDICAÇÃO
    g_type_adm CONSTANT VARCHAR2(1) := 'A';
    g_type_int CONSTANT VARCHAR2(2) := 'I';
    g_type_ext CONSTANT VARCHAR2(1) := 'E';

    -- sys_config
    g_show_conversion_screen   CONSTANT sys_config.id_sys_config%TYPE := 'PRESC_SHOW_CONVERSION_SCREEN';
    g_prescription_usa         CONSTANT sys_config.id_sys_config%TYPE := 'PRESCRIPTION_USA';
    g_med_hist_grid_permission CONSTANT sys_config.id_sys_config%TYPE := 'MEDICATION_HIST_GRID_PERMISSION';

    -- sys_message
    g_presc_t_43            CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T043';
    g_presc_t_8             CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T008';
    g_presc_rec_t017        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T017';
    g_presc_rec_t061        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M013';
    prescription_mo_m005    CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_MO_M005';
    g_presc_mo_m006         CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_MO_M006';
    g_presc_rec_m029        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M029'; -- continue (continuar)
    g_presc_rec_m031        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M031'; -- emb.
    g_presc_manip_message   CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_MANIP_T007'; -- manipulados
    g_presc_dietary_message CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_DIETARY_T003'; -- dieteticos
    g_message_bolus         CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M042'; -- Bólus
    g_last_instructions     CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M043'; -- ULTIMAS INSTRUÇÕES
    g_presc_rec_m038        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M038'; -- Com notas
    g_search_crit_m003      CONSTANT sys_message.code_message%TYPE := 'SEARCH_CRITERIA_M003';
    g_presc_rec_t053        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T053';
    g_presc_mo_t005         CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_MO_T005';
    g_presc_rec_m044        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M044'; -- relatos não pertecnce à instituição
    g_presc_rec_m015        CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M015'; -- aviso

    -- translation
    g_code_unit_measure CONSTANT translation.code_translation%TYPE := 'UNIT_MEASURE.CODE_UNIT_MEASURE.';
    g_code_unit_abrv    CONSTANT translation.code_translation%TYPE := 'UNIT_MEASURE.CODE_UNIT_MEASURE_ABRV.';

    -- prescription_instr_hist
    g_flg_change_sta CONSTANT prescription_instr_hist.flg_change%TYPE := 'S'; -- change status
    g_flg_change_mod CONSTANT prescription_instr_hist.flg_change%TYPE := 'M'; -- change MODIFY ORDER
    g_flg_change_ref CONSTANT prescription_instr_hist.flg_change%TYPE := 'R'; -- change REFILL

    g_flg_status_int CONSTANT prescription_instr_hist.flg_status_new%TYPE := 'I'; -- interrompido

    g_pat_notify_unr CONSTANT issue.flg_status%TYPE := 'U';
    g_pat_notify_res CONSTANT issue.flg_status%TYPE := 'R';

    -- pat_medication_list
    g_pat_med_list_can  CONSTANT pat_medication_list.flg_status%TYPE := 'C'; -- cancelado
    g_pat_med_list_pas  CONSTANT pat_medication_list.flg_status%TYPE := 'P'; -- passivo
    g_pat_med_list_act  CONSTANT pat_medication_list.flg_status%TYPE := 'A'; -- activo
    g_pat_med_list_ina  CONSTANT pat_medication_list.flg_status%TYPE := 'I'; -- inactivo
    g_pat_med_list_del  CONSTANT pat_medication_list.flg_status%TYPE := 'D'; -- deleted
    g_pat_med_list_next CONSTANT pat_medication_list.flg_status%TYPE := 'N'; -- reported medication from previous episodes

    g_pat_med_list_con CONSTANT VARCHAR2(1) := 'C'; -- continue
    g_pat_med_list_int CONSTANT VARCHAR2(1) := 'I'; -- interrompido

    g_presc_pharm_table    CONSTANT prescription_instr_hist.prescription_table%TYPE := 'PRESCRIPTION_PHARM';
    g_drug_req_det_table   CONSTANT prescription_instr_hist.prescription_table%TYPE := 'DRUG_REQ_DET';
    g_drug_presc_det_table CONSTANT prescription_instr_hist.prescription_table%TYPE := 'DRUG_PRESC_DET';
    g_pat_med_list_table   CONSTANT prescription_instr_hist.prescription_table%TYPE := 'PAT_MEDICATION_LIST';

    g_presc_type_int drug_prescription.flg_type%TYPE;

    g_flg_type_reported CONSTANT prescription.flg_type%TYPE := 'R';

    g_presc_req  drug_prescription.flg_status%TYPE;
    g_presc_pend drug_prescription.flg_status%TYPE;
    g_presc_fin  drug_prescription.flg_status%TYPE;
    g_presc_can  drug_prescription.flg_status%TYPE;
    g_presc_par  drug_prescription.flg_status%TYPE;
    g_presc_intr drug_prescription.flg_status%TYPE;
    g_presc_exe  drug_prescription.flg_status%TYPE;

    g_presc_det_req  drug_presc_det.flg_status%TYPE;
    g_presc_det_pend drug_presc_det.flg_status%TYPE;
    g_presc_det_exe  drug_presc_det.flg_status%TYPE;
    g_presc_det_fin  drug_presc_det.flg_status%TYPE;
    g_presc_det_can  drug_presc_det.flg_status%TYPE;
    g_presc_det_intr drug_presc_det.flg_status%TYPE;
    g_presc_det_sus  drug_presc_det.flg_status%TYPE;

    g_flg_time_epis drug_prescription.flg_time%TYPE;
    g_flg_time_next drug_prescription.flg_time%TYPE;
    g_flg_time_betw drug_prescription.flg_time%TYPE;

    g_presc_take_sos  drug_presc_det.flg_take_type%TYPE;
    g_presc_take_nor  drug_presc_det.flg_take_type%TYPE;
    g_presc_take_uni  drug_presc_det.flg_take_type%TYPE;
    g_presc_take_cont drug_presc_det.flg_take_type%TYPE;
    g_presc_take_eter drug_presc_det.flg_take_type%TYPE;

    g_presc_plan_stat_adm  drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_nadm drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_can  drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_req  drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_pend drug_presc_plan.flg_status%TYPE;

    g_domain_take    sys_domain.code_domain%TYPE;
    g_domain_time    sys_domain.code_domain%TYPE;
    g_domain_relatos sys_domain.code_domain%TYPE := 'RELATOS'; -- relatos

    g_drug_justif drug.flg_justify%TYPE;
    g_drug_interv interv_drug.flg_type%TYPE;

    g_flg_doctor category.flg_type%TYPE;
    g_flg_phys   category.flg_type%TYPE;
    g_flg_tec    category.flg_type%TYPE;

    g_drug_det_status sys_domain.code_domain%TYPE;

    --NOVAS VARIÁVEIS GLOBAIS P FERRAMENTA DE PRESCRIÇÃO
    g_flg_freq VARCHAR2(1);
    g_flg_pesq VARCHAR2(1);
    g_no       VARCHAR2(1);
    g_yes      VARCHAR2(1);
    g_chnm     sys_config.value%TYPE;

    g_flg_ext      prescription.flg_type%TYPE;
    g_descr_ext    pk_translation.t_desc_translation;
    g_flg_int      prescription.flg_type%TYPE;
    g_descr_int    pk_translation.t_desc_translation;
    g_flg_other    prescription.flg_type%TYPE;
    g_flg_reported prescription.flg_type%TYPE;
    g_flg_adm      prescription.flg_type%TYPE;

    g_flg_manip_ext   prescription.flg_sub_type%TYPE;
    g_flg_manip_int   prescription.flg_sub_type%TYPE;
    g_flg_dietary_ext prescription.flg_sub_type%TYPE;
    g_flg_dietary_int prescription.flg_sub_type%TYPE;

    g_pharma_class_avail drug_pharma_class.flg_available%TYPE;
    g_drug_available     drug.flg_available%TYPE;

    g_descr_otc VARCHAR2(3);

    g_flg_temp  prescription.flg_status%TYPE;
    g_flg_print prescription.flg_status%TYPE;

    g_flg_first  VARCHAR2(1);
    g_flg_second VARCHAR2(1);

    g_domain_print_type   sys_domain.code_domain%TYPE;
    g_domain_reprint_type sys_domain.code_domain%TYPE;

    g_inst_type_cs institution.flg_type%TYPE;
    g_inst_type_hs institution.flg_type%TYPE;

    g_pharma_avail VARCHAR2(1);

    g_flg_req     prescription_pharm.flg_status%TYPE;
    g_flg_pend    prescription_pharm.flg_status%TYPE;
    g_flg_rejeita drug_req_det.flg_status%TYPE;

    g_att_yes  VARCHAR2(1);
    g_att_no   VARCHAR2(1);
    g_att_read VARCHAR2(1);

    g_price_pvp NUMBER;
    g_price_pr  NUMBER;
    g_price_prp NUMBER;

    g_flg_cancel   VARCHAR2(1);
    g_flg_active   VARCHAR2(1);
    g_flg_inactive VARCHAR2(1);

    g_flg_ci              VARCHAR2(2);
    g_flg_cheaper         VARCHAR2(1);
    g_flg_justif          VARCHAR2(1);
    g_flg_interac_med     VARCHAR2(2);
    g_flg_interac_allergy VARCHAR2(2);
    g_drug_req            VARCHAR2(1);

    g_flg_generico VARCHAR2(1);

    g_problem_ci    VARCHAR2(1);
    g_problem_assoc VARCHAR2(1);

    --VALORES DA BD INFARMED
    g_mnsrm           inf_class_disp.class_disp_id%TYPE;
    g_msrm_e          inf_class_disp.class_disp_id%TYPE;
    g_msrm_ra         inf_class_disp.class_disp_id%TYPE;
    g_msrm_rb         inf_class_disp.class_disp_id%TYPE;
    g_msrm_rc         inf_class_disp.class_disp_id%TYPE;
    g_msrm_rc_disable inf_class_disp.class_disp_id%TYPE;
    g_msrm_r_ea       inf_class_disp.class_disp_id%TYPE;
    g_msrm_r_ec       inf_class_disp.class_disp_id%TYPE;
    g_emb_hosp        inf_class_disp.class_disp_id%TYPE;
    g_disp_in_v       inf_class_disp.class_disp_id%TYPE;

    g_prod_diabetes inf_tipo_prod.tipo_prod_id%TYPE;
    g_grupo_0       inf_grupo_hom.grupo_hom_id%TYPE;

    g_drug drug.flg_type%TYPE;

    g_selected VARCHAR2(1);
    --Fluids
    g_stat_pend          drug_prescription.flg_status%TYPE;
    g_stat_req           drug_prescription.flg_status%TYPE;
    g_stat_intr          drug_prescription.flg_status%TYPE;
    g_stat_canc          drug_prescription.flg_status%TYPE;
    g_presc_det_bolus    drug_presc_det.flg_status%TYPE;
    g_stat_fin           drug_prescription.flg_status%TYPE;
    g_flg_new_fluid      drug_req.flg_status%TYPE;
    g_stat_exec          drug_prescription.flg_status%TYPE;
    g_flg_take_type_sos  drug_prescription.flg_status%TYPE;
    g_flg_take_type_cont drug_presc_det.flg_take_type%TYPE := 'C';
    l_co_sign            co_sign_obj := co_sign_obj(NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    g_flg_co_sign        VARCHAR2(1);
    g_stat_adm           drug_prescription.flg_status%TYPE;

    -- drug_req
    g_drug_req_req           drug_req.flg_status%TYPE;
    g_drug_req_pend          drug_req.flg_status%TYPE;
    g_drug_req_exe           drug_req.flg_status%TYPE;
    g_drug_req_rejeita       drug_req.flg_status%TYPE;
    g_drug_req_parc          drug_req.flg_status%TYPE;
    g_local_prescription     drug_req.flg_status%TYPE;
    g_directions_str         VARCHAR2(100);
    g_hosp_farm_prescription drug_req.flg_status%TYPE;
    g_hosp_farm_ext          drug_req.flg_status%TYPE;
    g_reported_med           drug_req.flg_status%TYPE;
    g_date_format            sys_config.value%TYPE;
    g_green_color            VARCHAR2(50);
    g_red_color              VARCHAR2(50);
    g_pat_med_list_domain    sys_domain.code_domain%TYPE;
    g_flg_relat_ext          VARCHAR2(2);
    g_log_object_name        VARCHAR2(50);
    g_active                 VARCHAR2(1);
    g_inactive               VARCHAR2(1);
    g_discontinue            VARCHAR2(1);
    g_drug_req_cancel        VARCHAR2(1);
    g_local                  VARCHAR2(100);
    g_hospital               VARCHAR2(100);
    g_dietetico              VARCHAR2(100);
    g_manipulados            VARCHAR2(100);
    g_exterior               VARCHAR2(100);
    g_relatos_ext            VARCHAR2(100);
    g_relatos_int            VARCHAR2(100);
    g_flg_relat_outros       VARCHAR2(2);
    g_outros                 VARCHAR2(100);
    g_outros_prod            VARCHAR2(100);
    g_soro                   VARCHAR2(100);
    g_compound               VARCHAR2(100);
    g_flg_d                  VARCHAR2(1);
    g_flg_r                  VARCHAR2(1);
    g_flg_s                  VARCHAR2(1);
    g_flg_z                  VARCHAR2(1);
    g_flg_i                  VARCHAR2(1); --Interromper
    g_flg_c                  VARCHAR2(1);
    g_flg_e                  VARCHAR2(1);
    g_flg_a                  VARCHAR2(1);
    g_flg_f                  VARCHAR2(1);
    g_flg_p                  VARCHAR2(1); -- PAT_MEDICATION_LIST, FLG_STATUS = 'P' - Não
    g_flg_b                  VARCHAR2(1);
    g_flg_m                  VARCHAR2(1); --Modified
    g_flg_o                  VARCHAR2(1); --Outros produtos
    g_flg_continue           VARCHAR2(2); --Retomar
    g_flg_type_presc         VARCHAR2(1);
    g_presc_type_desc_int    VARCHAR2(1);
    g_presc_type             VARCHAR2(100);
    g_prescription_version   VARCHAR2(100);
    version                  VARCHAR2(100);
    g_flg_relat_int          VARCHAR2(2);

    g_det_sus            drug_presc_det.flg_status%TYPE;
    g_det_temp           drug_presc_det.flg_status%TYPE;
    g_det_req            drug_presc_det.flg_status%TYPE;
    g_det_pend           drug_presc_det.flg_status%TYPE;
    g_det_exe            drug_presc_det.flg_status%TYPE;
    g_det_fin            drug_presc_det.flg_status%TYPE;
    g_det_can            drug_presc_det.flg_status%TYPE;
    g_det_intr           drug_presc_det.flg_status%TYPE;
    g_det_reject         drug_presc_det.flg_status%TYPE;
    g_drug_exec          drug_req.flg_status%TYPE;
    g_drug_canc          drug_req.flg_status%TYPE;
    g_drug_pend          drug_req.flg_status%TYPE;
    g_drug_res           drug_req.flg_status%TYPE;
    g_drug_part          drug_req.flg_status%TYPE;
    g_drug_rejeita       drug_req.flg_status%TYPE;
    g_presc_det_req_hosp drug_presc_det.flg_status%TYPE;
    g_debug_on           VARCHAR2(3);

    g_viewer_hp               VARCHAR2(2);
    g_viewer_ts               VARCHAR2(2);
    g_viewer_ex               VARCHAR2(2);
    g_viewer_ps               VARCHAR2(2);
    g_viewer_patient_notified VARCHAR2(16);

    g_presc_print CONSTANT prescription.flg_status%TYPE := 'P';

    -- Drug_req
    g_drug_req_temp CONSTANT drug_req.flg_status%TYPE := 'T';
    g_drug_req_can  CONSTANT drug_req.flg_status%TYPE := 'C';

    g_flg_type_adm CONSTANT prescription.flg_type%TYPE := 'A';
    g_flg_type_ext CONSTANT prescription.flg_type%TYPE := 'E';
    g_flg_type_int CONSTANT prescription.flg_type%TYPE := 'I';
    g_flg_qty_for_24_hours VARCHAR2(1);
    g_flg_total_qty        VARCHAR2(1);
    g_date_format_str      VARCHAR2(25);
    g_presc_det_par        drug_req.flg_status%TYPE;
    --label para apresentar na vista 1 da grelha de medicação para receitas para o exterior
    g_last_take_na CONSTANT VARCHAR2(3) := 'N/A';
    --g_usa          CONSTANT VARCHAR2(255) := 'USA';
    g_pt CONSTANT VARCHAR2(255) := 'PT';

    g_grid_color      CONSTANT VARCHAR2(50) := 'GRID_COLOR';
    g_presc_oris      CONSTANT VARCHAR2(50) := 'PRESC_ORIS_TYPE';
    g_presc_more3days CONSTANT VARCHAR2(50) := 'PRESC_MORE30DAYS';

    g_mec_session CONSTANT notes_config.notes_code%TYPE := 'MEC';

    g_doc_type_sns NUMBER(12);

    --Exception
    unespected_exception EXCEPTION;

    --inactive actions
    g_inactive_action VARCHAR2(50) := 'MEDICATION_INACTIVE_ACTION';

    g_drug_action_type_presc      prescription.flg_type%TYPE := 'R';
    g_drug_action_type_presc_rank NUMBER(1) := 1;
    g_drug_action_type_other_rank NUMBER(1) := 2;

    g_exterior_chronic       VARCHAR2(100);
    g_flg_chronic_medication VARCHAR2(2);

    g_cpoe_adm_extra_take VARCHAR2(20) := 'CPOE_EXTRA_TAKE';

    --Reconciliation labels
    g_last_reconcile_text      CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M076';
    g_partially_reconcile_text CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M092';
    g_reconcile_text           CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M093';
    g_not_reconcile_text       CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M094';

END pk_medication_current;
/
